import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/analytics_models.dart';

/// Standard dark-navy card container for analytics and prediction sections,
/// supporting optional individual collapse/expand controls on chart cards.
class SectionCard extends StatefulWidget {
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
    this.collapsible = false,
    this.initiallyExpanded = true,
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
  final bool collapsible;
  final bool initiallyExpanded;

  @override
  State<SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<SectionCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final badgeFill = widget.accentColor == AppColors.teal
        ? AppColors.tealTint
        : AppColors.navyTint;

    final bodyContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.filterWidget != null) ...[
          const SizedBox(height: 10),
          Align(alignment: Alignment.centerLeft, child: widget.filterWidget!),
        ],
        if (widget.controlsRow != null) ...[
          const SizedBox(height: 10),
          widget.controlsRow!,
        ],
        const SizedBox(height: 14),
        widget.child,
        if (widget.footerNote != null) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.subtleFill,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.borderStrong.withValues(alpha: 0.75),
              ),
            ),
            child: Text.rich(
              TextSpan(
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 12,
                  height: 1.4,
                ),
                children: [
                  const WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(
                      padding: EdgeInsets.only(right: 5),
                      child: Icon(
                        Icons.info_rounded,
                        size: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const TextSpan(
                    text: 'Insight: ',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(
                    text: widget.footerNote!.replaceFirst(
                      RegExp(r'^Insight:\s*'),
                      '',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );

    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.hairline, width: 1.1),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 12,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: badgeFill,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.accentColor.withValues(alpha: 0.48),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(widget.icon, size: 14, color: widget.accentColor),
                      const SizedBox(width: 4),
                      Text(
                        widget.stepNumber,
                        style: TextStyle(
                          color: widget.accentColor,
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
                        widget.title,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.collapsible) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: _expanded ? 'Collapse chart' : 'Expand chart',
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () => setState(() => _expanded = !_expanded),
                    icon: Icon(
                      _expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                ],
              ],
            ),
            if (widget.collapsible)
              AnimatedCrossFade(
                firstChild: const SizedBox(width: double.infinity),
                secondChild: bodyContent,
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 220),
                sizeCurve: Curves.easeOutCubic,
              )
            else
              bodyContent,
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
          dropdownColor: AppColors.surface,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: AppColors.teal,
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
    FocusManager.instance.primaryFocus?.unfocus();
    final chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) =>
          _CohortSearchSheet(selectedKey: selectedKey, bundle: bundle),
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
        constraints: const BoxConstraints(maxWidth: 260),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.subtleFill,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderStrong),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.search_rounded,
                size: 13.5,
                color: AppColors.teal,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  selectedKey,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 15,
                color: AppColors.teal,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CohortSearchSheet extends StatefulWidget {
  const _CohortSearchSheet({required this.selectedKey, required this.bundle});

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
      final matchesQuery =
          query.isEmpty ||
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
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                    ),
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
                    color: AppColors.teal,
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
                          tileColor: selected
                              ? AppColors.navyTint
                              : Colors.transparent,
                          title: Text(
                            item.key,
                            style: TextStyle(
                              color: selected ? AppColors.teal : AppColors.ink,
                              fontWeight: selected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
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
                                  color: AppColors.teal,
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
