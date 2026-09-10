import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/liquid_glass.dart';
import '../../quran/data/quran_api_repository.dart';
import '../../quran/domain/surah.dart';
import '../data/tafsir_repository.dart';
import '../domain/tafsir_ayah.dart';

class TafsirPage extends StatefulWidget {
  const TafsirPage({super.key});

  @override
  State<TafsirPage> createState() => _TafsirPageState();
}

class _TafsirPageState extends State<TafsirPage> {
  final _searchController = TextEditingController();
  final _quranRepository = QuranApiRepository();
  final _tafsirRepository = TafsirRepository();
  List<Surah> _surahs = const [];
  List<Surah> _filtered = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filter);
    _loadSurahs();
  }

  Future<void> _loadSurahs() async {
    try {
      final surahs = await _quranRepository.getSurahs();
      if (!mounted) return;
      setState(() {
        _surahs = surahs;
        _filtered = surahs;
        _loading = false;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is QuranApiException
            ? error.message
            : 'تعذر تحميل قائمة السور.';
        _loading = false;
      });
    }
  }

  void _filter() {
    final query = _searchController.text.trim();
    setState(() {
      _filtered = query.isEmpty
          ? _surahs
          : _surahs
                .where(
                  (surah) =>
                      surah.displayName.contains(query) ||
                      surah.englishName.toLowerCase().contains(
                        query.toLowerCase(),
                      ),
                )
                .toList();
    });
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_filter)
      ..dispose();
    super.dispose();
  }

  Future<void> _openTafsir(Surah surah) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _TafsirSurahPage(
          surah: surah,
          repository: _tafsirRepository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppDimensions.pagePadding),
        children: [
          Text('تفسير القرآن', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 8),
          Text(
            'تدبر معاني الآيات من تفسير الميسر الموثوق.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'ابحث عن سورة للتفسير',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            _TafsirError(message: _error!, onRetry: _loadSurahs)
          else
            ..._filtered.map(
              (surah) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: LiquidGlass(
                  borderRadius: AppDimensions.cardRadius,
                  child: ListTile(
                    onTap: () => _openTafsir(surah),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.mint,
                      foregroundColor: AppColors.greenDark,
                      child: Text('${surah.number}'),
                    ),
                    title: Text(surah.displayName),
                    subtitle: Text(
                      '${surah.revelationPlace} • ${surah.versesCount} آيات  •  تفسير الميسر',
                    ),
                    trailing: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TafsirSurahPage extends StatefulWidget {
  const _TafsirSurahPage({required this.surah, required this.repository});

  final Surah surah;
  final TafsirRepository repository;

  @override
  State<_TafsirSurahPage> createState() => _TafsirSurahPageState();
}

class _TafsirSurahPageState extends State<_TafsirSurahPage> {
  List<TafsirAyah> _ayahs = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final ayahs = await widget.repository.getSurahTafsir(widget.surah.number);
      if (!mounted) return;
      setState(() {
        _ayahs = ayahs;
        _loading = false;
      });
    } on TafsirException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          AppDialogs.showError(
            context,
            title: 'تعذر تحميل التفسير',
            message: error.message,
            onRetry: _load,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text('تفسير ${widget.surah.displayName}')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _TafsirError(message: _error!, onRetry: _load)
            : ListView.separated(
                padding: const EdgeInsets.all(AppDimensions.pagePadding),
                itemCount: _ayahs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final ayah = _ayahs[index];
                  return LiquidGlass(
                    padding: const EdgeInsets.all(18),
                    borderRadius: 22,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الآية ${ayah.numberInSurah}',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: AppColors.green,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ayah.text,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(height: 1.9),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _TafsirError extends StatelessWidget {
  const _TafsirError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.gold, size: 48),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    ),
  );
}
