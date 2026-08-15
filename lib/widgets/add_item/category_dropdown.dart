import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../utils/item_categories.dart';

class CategoryDropdown extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const CategoryDropdown({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final catColor = AppTheme.categoryColor(selected);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: catColor, width: 1.5),
        borderRadius: BorderRadius.circular(12),
        color: catColor.withValues(alpha: 0.06),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: DropdownButton<String>(
        value: selected,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        icon: Icon(Icons.expand_more_rounded, color: catColor),
        dropdownColor: cs.surface,
        borderRadius: BorderRadius.circular(12),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
        selectedItemBuilder: (context) {
          return ItemCategory.all.map((cat) {
            final color = AppTheme.categoryColor(cat);
            return Row(
              children: [
                Icon(AppTheme.categoryIcon(cat), size: 20, color: color),
                const SizedBox(width: 10),
                Text(
                  cat,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            );
          }).toList();
        },
        items: ItemCategory.all.map((cat) {
          final color = AppTheme.categoryColor(cat);
          return DropdownMenuItem<String>(
            value: cat,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(AppTheme.categoryIcon(cat), size: 18, color: color),
                ),
                const SizedBox(width: 12),
                Text(
                  cat,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: cat == selected ? FontWeight.w600 : FontWeight.w400,
                    color: cat == selected ? color : cs.onSurface,
                  ),
                ),
                if (cat == selected) ...[
                  const Spacer(),
                  Icon(Icons.check_rounded, size: 16, color: color),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
