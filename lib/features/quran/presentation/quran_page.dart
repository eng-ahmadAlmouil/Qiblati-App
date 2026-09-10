import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/liquid_glass.dart';
import '../data/quran_reader_repository.dart';
import '../domain/surah.dart';
import 'quran_reader_page.dart';
import 'quran_controller.dart';

class QuranPage extends StatefulWidget {
  const QuranPage({super.key});

  @override
  State<QuranPage> createState() => _QuranPageState();
}

class _QuranPageState extends State<QuranPage> {
  final _searchController = TextEditingController();
  late final QuranController _controller;
  final _readerRepository = const QuranReaderRepository();
  List<Surah> _filteredSurahs = const [];
  String? _shownError;
  int _completedSurahs = 0;
  Set<int> _completedSurahNumbers = <int>{};

  @override
  void initState() {
    super.initState();
    _controller = QuranController()..addListener(_refresh);
    _controller.load();
    _loadProgress();
    _searchController.addListener(_filterSurahs);
  }

  Future<void> _loadProgress() async {
    final completed = await _readerRepository.getCompletedSurahCount();
    final completedNumbers = await _readerRepository.getCompletedSurahs();
    if (!mounted) return;
    setState(() {
      _completedSurahs = completed;
      _completedSurahNumbers = completedNumbers;
    });
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {
      _filteredSurahs = _filter(_searchController.text);
    });
    final error = _controller.errorMessage;
    if (_controller.status == QuranStatus.error &&
        error != null &&
        error != _shownError) {
      _shownError = error;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          AppDialogs.showError(
            context,
            title: 'تعذر تحميل القرآن',
            message: error,
            onRetry: _controller.load,
          );
        }
      });
    }
  }

  void _filterSurahs() {
    setState(() => _filteredSurahs = _filter(_searchController.text));
  }

  List<Surah> _filter(String value) {
    final query = _withoutDiacritics(value.trim().toLowerCase());
    if (query.isEmpty) return _controller.surahs;
    return _controller.surahs
        .where(
          (surah) =>
              _withoutDiacritics(surah.displayName).contains(query) ||
              surah.englishName.toLowerCase().contains(query),
        )
        .toList();
  }

  String _withoutDiacritics(String value) => value
      .replaceAll(
        RegExp(r'[\u0617-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]'),
        '',
      )
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا')
      .replaceAll('ى', 'ي');

  @override
  void dispose() {
    _searchController
      ..removeListener(_filterSurahs)
      ..dispose();
    _controller
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.pagePadding,
          AppDimensions.pagePadding,
          AppDimensions.pagePadding,
          20,
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'القرآن الكريم',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ),
              IconButton.filledTonal(
                onPressed: () {},
                tooltip: 'الإشارات المرجعية',
                icon: const Icon(Icons.bookmark_outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'اقرأ، تدبر، وكن أقرب إلى كلام الله.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppDimensions.sectionGap),
          _ReadingProgress(
            completedSurahs: _completedSurahs,
            onReset: () async {
              final confirmed = await AppDialogs.confirm(
                context,
                title: 'إعادة التقدم؟',
                message: 'سيتم حذف السور المكتملة وآخر موضع قراءة.',
                confirmLabel: 'إعادة',
              );
              if (confirmed) {
                await _readerRepository.resetProgress();
                await _loadProgress();
              }
            },
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'ابحث عن سورة',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: _searchController.clear,
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Text('السور', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              Text(
                '${_filteredSurahs.length} سورة',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_controller.status == QuranStatus.loading)
            const _LoadingQuranState()
          else if (_controller.status == QuranStatus.error)
            _ErrorQuranState(
              message: _controller.errorMessage ?? 'تعذر تحميل القرآن.',
              onRetry: _controller.load,
            )
          else if (_filteredSurahs.isEmpty)
            const _EmptySearchState()
          else
            ..._filteredSurahs.map(
              (surah) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SurahCard(
                  surah: surah,
                  completed: _completedSurahNumbers.contains(surah.number),
                  onOpen: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => QuranReaderPage(surah: surah),
                      ),
                    );
                    _loadProgress();
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LoadingQuranState extends StatelessWidget {
  const _LoadingQuranState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(36),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorQuranState extends StatelessWidget {
  const _ErrorQuranState({required this.message, required this.onRetry});

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

class _ReadingProgress extends StatelessWidget {
  const _ReadingProgress({
    required this.completedSurahs,
    required this.onReset,
  });

  final int completedSurahs;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final progress = completedSurahs / 114;
    final percentage = (progress * 100).clamp(0, 100).toStringAsFixed(1);

    return LiquidGlass(
      padding: const EdgeInsets.all(20),
      borderRadius: AppDimensions.cardRadius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تقدّمك في القراءة',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(fontSize: 17),
                    ),
                    Text(
                      '$completedSurahs من 114 سورة',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Text(
                    '$percentage%',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: AppColors.green),
                  ),
                  IconButton(
                    onPressed: onReset,
                    tooltip: 'إعادة التقدم',
                    icon: const Icon(Icons.restart_alt_rounded),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: AppColors.mint,
              valueColor: const AlwaysStoppedAnimation(AppColors.green),
            ),
          ),
        ],
      ),
    );
  }
}

class _SurahCard extends StatelessWidget {
  const _SurahCard({
    required this.surah,
    required this.onOpen,
    required this.completed,
  });

  final Surah surah;
  final VoidCallback onOpen;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      borderRadius: AppDimensions.cardRadius,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${surah.number}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.greenDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surah.displayName,
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(fontSize: 17),
                    ),
                    Text(
                      '${surah.revelationPlace} • ${surah.versesCount} آيات',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (completed)
                const Icon(Icons.check_circle_rounded, color: AppColors.green)
              else
                Text(
                  surah.englishName,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontSize: 11),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.search_off, size: 48, color: AppColors.muted),
          const SizedBox(height: 12),
          Text(
            'لم نجد سورة بهذا الاسم',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
