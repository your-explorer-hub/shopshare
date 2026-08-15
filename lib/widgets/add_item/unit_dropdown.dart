import 'package:flutter/material.dart';

import '../../utils/constants.dart';

class UnitDropdown extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const UnitDropdown({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outline, width: 1.5),
        borderRadius: BorderRadius.circular(10),
        color: cs.surfaceContainerHighest,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isDense: true,
          icon: Icon(Icons.expand_more_rounded,
              size: 16, color: cs.onSurfaceVariant),
          dropdownColor: cs.surface,
          borderRadius: BorderRadius.circular(10),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          items: AppConstants.itemUnits
              .map((u) => DropdownMenuItem<String>(
                    value: u,
                    child: Text(u),
                  ))
              .toList(),
        ),
      ),
    );
  }
}
