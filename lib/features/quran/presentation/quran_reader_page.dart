import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/liquid_glass.dart';
import '../data/quran_api_repository.dart';
import '../data/quran_reader_repository.dart';
import '../domain/ayah.dart';
import '../domain/surah.dart';

class QuranReaderPage extends StatefulWidget {
  const QuranReaderPage({super.key, required this.surah});

  final Surah surah;

  @override
  State<QuranReaderPage> createState() => _QuranReaderPageState();
}

class _QuranReaderPageState extends State<QuranReaderPage> {
  late final QuranApiRepository _repository;
  final _readerRepository = const QuranReaderRepository();
  bool _loading = true;
  String? _errorMessage;
  double _fontSize = 27;
  int _currentPage = 0;
  List<List<Ayah>> _pageGroups = const [];
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _repository = QuranApiRepository();
    _pageController = PageController();
    _loadAyahs();
  }

  List<List<Ayah>> get _pages => _pageGroups;

  List<List<Ayah>> _buildPages(List<Ayah> source) {
    final ayahs = source
        .asMap()
        .entries
        .where((entry) => !_isStandaloneBasmala(entry.key, entry.value))
        .map((entry) => _withoutInlineBasmala(entry.key, entry.value))
        .toList();
    final pages = <List<Ayah>>[];
    for (final ayah in ayahs) {
      final page = ayah.page;
      if (page == null) {
        if (pages.isEmpty || pages.last.length >= 8) pages.add([]);
        pages.last.add(ayah);
        continue;
      }
      final pageIndex = ayahs.indexWhere((item) => item.page == page);
      if (pageIndex == ayahs.indexOf(ayah)) {
        pages.add(ayahs.where((item) => item.page == page).toList());
      }
    }
    return pages;
  }

  bool _isStandaloneBasmala(int index, Ayah ayah) =>
      index == 0 && _compact(ayah.text) == _compact(_basmala);

  Ayah _withoutInlineBasmala(int index, Ayah ayah) {
    if (index != 0) return ayah;
    final source = ayah.text;
    final target = _compact(_basmala);
    final normalized = StringBuffer();
    final endOffsets = <int>[];
    var offset = 0;
    for (final rune in source.runes) {
      final character = String.fromCharCode(rune);
      offset += character.length;
      final normalizedCharacter = _compact(character);
      if (normalizedCharacter.isEmpty) continue;
      normalized.write(normalizedCharacter);
      endOffsets.add(offset);
    }
    final compactSource = normalized.toString();
    if (!compactSource.startsWith(target)) return ayah;
    final prefixLength = endOffsets[target.length - 1];
    final remainder = source
        .substring(prefixLength)
        .replaceFirst(
          RegExp(r'^[\s\u0617-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]+'),
          '',
        )
        .trim();
    if (remainder.isEmpty) return ayah;
    return Ayah(number: ayah.number, page: ayah.page, text: remainder);
  }

  String _compact(String value) => _normalize(
    value,
  ).replaceAll(RegExp(r'\s+'), '').replaceAll(RegExp(r'[ۖۗۘۙۚۛۜ۝۞،؛]'), '');

  String _normalize(String value) => value
      .replaceAll(
        RegExp(r'[\u0617-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]'),
        '',
      )
      .replaceAll('ٱ', 'ا')
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا');

  static const _basmala = 'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ';

  Future<void> _loadAyahs() async {
    try {
      final ayahs = await _repository.getAyahs(widget.surah);
      final lastRead = await _readerRepository.getLastRead();
      if (!mounted) return;
      setState(() {
        _pageGroups = _buildPages(ayahs);
        _loading = false;
      });
      final savedAyah = lastRead.ayahNumber;
      if (lastRead.surahNumber == widget.surah.number && savedAyah != null) {
        final savedIndex = _pages.indexWhere(
          (page) => page.any((ayah) => ayah.number == savedAyah),
        );
        if (savedIndex >= 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _pageController.hasClients) {
              _pageController.jumpToPage(savedIndex);
              setState(() => _currentPage = savedIndex);
            }
          });
        }
      }
    } on QuranApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _loading = false;
      });
      _showLoadError(error.message);
    } on FormatException {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'بيانات الآيات غير صالحة حالياً.';
        _loading = false;
      });
      _showLoadError('بيانات الآيات غير صالحة حالياً.');
    }
  }

  void _showLoadError(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppDialogs.showError(
        context,
        title: 'تعذر تحميل الآيات',
        message: message,
        onRetry: _loadAyahs,
      );
    });
  }

  Future<void> _markComplete() async {
    await _readerRepository.markSurahCompleted(widget.surah.number);
    if (!mounted) return;
    await AppDialogs.showInfo(
      context,
      title: 'أحسنت',
      message: 'تم تسجيل سورة ${widget.surah.displayName} ضمن تقدمك.',
    );
  }

  void _showFontSizeSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('حجم خط القراءة',
                  style: Theme.of(context).textTheme.titleLarge),
              Slider(
                value: _fontSize,
                min: 20,
                max: 38,
                divisions: 9,
                label: '${_fontSize.round()}',
                activeColor: AppColors.green,
                onChanged: (value) {
                  setSheetState(() {});
                  setState(() => _fontSize = value);
                },
              ),
              Text('اجعل القراءة مريحة لعينيك',
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.surah.displayName),
          actions: [
            IconButton(
              onPressed: _markComplete,
              tooltip: 'تمت القراءة',
              icon: const Icon(Icons.check_circle_outline_rounded),
            ),
            IconButton(
              onPressed: () => _showFontSizeSheet(context),
              tooltip: 'حجم الخط',
              icon: const Icon(Icons.text_fields_rounded),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            children: [
              _ReaderHeader(surah: widget.surah),
              const SizedBox(height: 14),
              if (!_loading && _errorMessage == null && _pages.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.swipe_rounded, color: AppColors.green),
                      const SizedBox(width: 8),
                      Text(
                        'اسحب يميناً أو يساراً للتنقل  •  ${_currentPage + 1}/${_pages.length}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              if (_loading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null)
                Expanded(
                  child: _ReaderError(
                    message: _errorMessage!,
                    onRetry: _loadAyahs,
                  ),
                )
              else
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (page) =>
                        setState(() => _currentPage = page),
                    itemBuilder: (context, pageIndex) => ListView(
                      padding: const EdgeInsets.only(bottom: 20),
                      children: [
                        const SizedBox(height: 10),
                        _MushafPage(
                          ayahs: _pages[pageIndex],
                          showBasmala: pageIndex == 0,
                          fontSize: _fontSize,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

}

class _ReaderError extends StatelessWidget {
  const _ReaderError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: AppColors.gold,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReaderHeader extends StatelessWidget {
  const _ReaderHeader({required this.surah});

  final Surah surah;

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      padding: const EdgeInsets.all(22),
      color: AppColors.greenDark.withValues(alpha: 0.82),
      borderRadius: AppDimensions.cardRadius,
      child: Column(
        children: [
          Text(
            'سُورَةُ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            surah.displayName,
            style: GoogleFonts.amiriQuran(
              color: AppColors.white,
              fontSize: 32,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${surah.revelationPlace} • ${surah.versesCount} آيات',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}

class _MushafPage extends StatelessWidget {
  const _MushafPage({
    required this.ayahs,
    required this.showBasmala,
    required this.fontSize,
  });

  final List<Ayah> ayahs;
  final bool showBasmala;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      color: AppColors.sand,
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 32),
      child: Column(
        children: [
          if (showBasmala)
            Text(
              _QuranReaderPageState._basmala,
              textAlign: TextAlign.center,
              style: GoogleFonts.amiriQuran(
                color: AppColors.greenDark,
                fontSize: fontSize * 0.9,
                height: 1.8,
              ),
            ),
          Text.rich(
            TextSpan(
              children: [
                for (final ayah in ayahs) ...[
                  TextSpan(
                    text: '${ayah.text} ',
                    style: GoogleFonts.amiriQuran(
                      color: AppColors.ink,
                      fontSize: fontSize,
                      height: 2,
                    ),
                  ),
                  TextSpan(
                    text: '۝ ',
                    style: GoogleFonts.amiriQuran(
                      color: AppColors.greenDark,
                      fontSize: fontSize * 0.65,
                    ),
                  ),
                ],
              ],
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}
