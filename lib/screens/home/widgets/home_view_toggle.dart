import 'package:flutter/material.dart';

import '../../../providers/home_screen_provider.dart';

class HomeViewToggle extends StatelessWidget {
  final ViewMode viewMode;
  final ValueChanged<ViewMode> onChanged;

  const HomeViewToggle({
    super.key,
    required this.viewMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Center(
          child: _ViewToggleRow(viewMode: viewMode, onChanged: onChanged),
        ),
      ),
    );
  }
}

// ── View mode toggle ──────────────────────────────────────────────────────────

class _ViewToggleRow extends StatelessWidget {
  final ViewMode viewMode;
  final ValueChanged<ViewMode> onChanged;

  const _ViewToggleRow({required this.viewMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ViewBtn(
          icon: Icons.list_rounded,
          label: 'List',
          selected: viewMode == ViewMode.list,
          onTap: () => onChanged(ViewMode.list),
          cs: cs,
        ),
        const SizedBox(width: 4),
        _ViewBtn(
          icon: Icons.category_rounded,
          label: 'Category',
          selected: viewMode == ViewMode.categorised,
          onTap: () => onChanged(ViewMode.categorised),
          cs: cs,
        ),
        const SizedBox(width: 4),
        _ViewBtn(
          icon: Icons.timeline_rounded,
          label: 'Timeline',
          selected: viewMode == ViewMode.timeline,
          onTap: () => onChanged(ViewMode.timeline),
          cs: cs,
        ),
      ],
    );
  }
}

class _ViewBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme cs;

  const _ViewBtn({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected
              ? cs.primaryContainer
              : cs.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? cs.primary.withValues(alpha: 0.5)
                : cs.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: selected ? cs.onPrimaryContainer : cs.onSurface),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? cs.onPrimaryContainer : cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
