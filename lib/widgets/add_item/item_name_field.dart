import 'package:flutter/material.dart';

import '../../data/item_catalog.dart';
import '../../theme/app_theme.dart';

class ItemNameField extends StatelessWidget {
  final ColorScheme cs;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onSuggestionSelected;

  const ItemNameField({
    super.key,
    required this.cs,
    required this.onNameChanged,
    required this.onSuggestionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.length < 3) {
          return const Iterable<String>.empty();
        }
        return ItemSuggestions.getSuggestions(textEditingValue.text);
      },
      onSelected: (String selection) {
        onSuggestionSelected(selection);
      },
      fieldViewBuilder: (
        BuildContext context,
        TextEditingController fieldController,
        FocusNode fieldFocusNode,
        VoidCallback onFieldSubmitted,
      ) {
        return TextFormField(
          controller: fieldController,
          focusNode: fieldFocusNode,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'e.g. Atta, Headphones, Kurta…',
            suffixIcon: fieldController.text.length >= 3
                ? Icon(Icons.lightbulb_outline_rounded,
                    size: 18, color: cs.primary.withValues(alpha: 0.7))
                : null,
          ),
          onChanged: onNameChanged,
        );
      },
      optionsViewBuilder: (
        BuildContext context,
        AutocompleteOnSelected<String> onSelected,
        Iterable<String> options,
      ) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(14),
            shadowColor: Colors.black26,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280, maxWidth: 420),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 56),
                  itemBuilder: (context, index) {
                    final option = options.elementAt(index);
                    final category = ItemSuggestions.detectCategory(option);
                    final catColor = AppTheme.categoryColor(category);
                    return InkWell(
                      onTap: () => onSelected(option),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: catColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                AppTheme.categoryIcon(category),
                                size: 18,
                                color: catColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    option,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    category,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: catColor,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.north_west_rounded,
                                size: 14, color: Colors.grey.shade400),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
