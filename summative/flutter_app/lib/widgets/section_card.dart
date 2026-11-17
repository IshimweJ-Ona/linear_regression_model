import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/analytics_models.dart';

/// Standard light-card wrapper used for each analytics & prediction section.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.stepNumber,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.child,
    this.filterWidget,
    this.controlsRow,
    this.footerNote,
  });

  final String stepNumber;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Widget child;
  final Widget? filterWidget;
  final Widget? controlsRow;
  final String? footerNote;

  @override
  Widget build(BuildContext context) {
    final badgeFill = accentColor == AppColors.teal
        ? AppColors.tealTint
        : AppColors.navyTint;

    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.hairline, width: 1.1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: badgeFill,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accentColor.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 14, color: accentColor),
                      const SizedBox(width: 4),
                      Text(
                        stepNumber,
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (filterWidget != null) ...[
                  const SizedBox(width: 8),
                  filterWidget!,
                ],
              ],
            ),
            if (controlsRow != null) ...[
              const SizedBox(height: 10),
              controlsRow!,
            ],
            const SizedBox(height: 14),
            child,
            if (footerNote != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.hairline),
                ),
                child: Text(
                  footerNote!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SectionFilterPill extends StatelessWidget {
  const SectionFilterPill({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.subtleFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: options.contains(value) ? value : options.first,
          isDense: true,
          dropdownColor: AppColors.paper,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: AppColors.navy,
          ),
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
          items: options
              .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
              .toList(),
          onChanged: (next) {
            if (next != null) onChanged(next);
          },
        ),
      ),
    );
  }
}

/// Interactive cohort filter button opening a searchable modal across all provinces,
/// sexes (Female & Male), urban/rural, education tracks, and sectors.
class SearchableCohortButton extends StatelessWidget {
  const SearchableCohortButton({
    super.key,
    required this.selectedKey,
    required this.bundle,
    required this.onSelected,
    this.buttonKey,
  });

  final String selectedKey;
  final AnalyticsBundle bundle;
  final ValueChanged<String> onSelected;
  final Key? buttonKey;

  Future<void> _openPicker(BuildContext context) async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => _CohortSearchSheet(
        selectedKey: selectedKey,
        bundle: bundle,
      ),
    );
    if (chosen != null) {
      onSelected(chosen);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: buttonKey,
      onTap: () => _openPicker(context),
      borderRadius: BorderRadius.circular(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 146),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.navyTint,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.navy.withValues(alpha: 0.28)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_rounded, size: 13.5, color: AppColors.navy),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  selectedKey,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 15,
                color: AppColors.navy,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CohortSearchSheet extends StatefulWidget {
  const _CohortSearchSheet({
    required this.selectedKey,
    required this.bundle,
  });

  final String selectedKey;
  final AnalyticsBundle bundle;

  @override
  State<_CohortSearchSheet> createState() => _CohortSearchSheetState();
}

class _CohortSearchSheetState extends State<_CohortSearchSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchCtrl.text.trim().toLowerCase();
    final categories = <String>['All'];
    for (final c in widget.bundle.cohorts) {
      if (!categories.contains(c.group)) {
        categories.add(c.group);
      }
    }

    final filtered = widget.bundle.cohorts.where((c) {
      final matchesCat =
          _selectedCategory == 'All' || c.group == _selectedCategory;
      final matchesQuery = query.isEmpty ||
          c.key.toLowerCase().contains(query) ||
          c.group.toLowerCase().contains(query);
      return matchesCat && matchesQuery;
    }).toList();

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final availH = MediaQuery.of(context).size.height - bottomInset;
    final sheetH = (availH * 0.78).clamp(240.0, 560.0);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: sheetH,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filter Analytics Cohort',
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Search Female, Male, any of Rwanda’s 5 provinces, TVET, or sector',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                key: const Key('cohort_search_input'),
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: AppColors.ink, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Search e.g. Female, Southern, Western, Northern, TVET...',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.navy,
                    size: 20,
                  ),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 34,
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (context, i) {
                  final cat = categories[i];
                  final active = cat == _selectedCategory;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: active,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                    showCheckmark: false,
                    backgroundColor: AppColors.subtleFill,
                    selectedColor: AppColors.navy,
                    side: BorderSide(
                      color: active ? AppColors.navy : AppColors.hairline,
                    ),
                    labelStyle: TextStyle(
                      color: active ? AppColors.paper : AppColors.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                    visualDensity: VisualDensity.compact,
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: AppColors.hairline),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'No matching cohort found.',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    )
                  : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, color: AppColors.hairline),
                      itemBuilder: (context, i) {
                        final item = filtered[i];
                        final stats = widget.bundle.overview[item.key];
                        final selected = item.key == widget.selectedKey;
                        return ListTile(
                          dense: true,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          tileColor:
                              selected ? AppColors.navyTint : Colors.transparent,
                          title: Text(
                            item.key,
                            style: TextStyle(
                              color: selected ? AppColors.navy : AppColors.ink,
                              fontWeight:
                                  selected ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 13.5,
                            ),
                          ),
                          subtitle: Text(
                            stats == null
                                ? '${item.group} • n = ${item.count}'
                                : '${item.group} • n = ${stats.count} • avg ${stats.meanK.toStringAsFixed(1)}k RWF',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11.5,
                            ),
                          ),
                          trailing: selected
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.navy,
                                  size: 20,
                                )
                              : const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.textMuted,
                                  size: 18,
                                ),
                          onTap: () => Navigator.of(context).pop(item.key),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
