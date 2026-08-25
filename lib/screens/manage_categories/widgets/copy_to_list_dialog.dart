import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/category_item.dart';
import '../../../models/shopping_list.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/custom_categories_provider.dart';
import '../../../providers/shopping_provider.dart';
import '../../../theme/app_theme.dart';

class CopyToListDialog extends StatefulWidget {
  final List<CategoryItem> items;
  final String categoryName;

  const CopyToListDialog({
    super.key,
    required this.items,
    required this.categoryName,
  });

  @override
  State<CopyToListDialog> createState() => _CopyToListDialogState();
}

class _CopyToListDialogState extends State<CopyToListDialog> {
  String? _selectedListId;
  final Set<String> _selectedItemIds = {};
  bool _isCopying = false;

  @override
  void initState() {
    super.initState();
    // Select all items by default
    _selectedItemIds.addAll(widget.items.map((item) => item.id));
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final shoppingProvider = context.watch<ShoppingProvider>();
    final userProfile = authProvider.userProfile;

    if (userProfile == null) {
      return AlertDialog(
        title: const Text('Error'),
        content: const Text('User profile not available'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      );
    }

    // Build list of available shopping lists
    final availableLists = shoppingProvider.availableLists;

    // Set default selection to My List
    _selectedListId ??= userProfile.listId;

    return AlertDialog(
      title: Text('Copy from "${widget.categoryName}"'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // List selector
            Text(
              'Select target list:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            if (availableLists.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('No shopping lists available'),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<String>(
                value: _selectedListId,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  prefixIcon: Icon(
                    Icons.list_alt_rounded,
                    color: AppTheme.accentTeal,
                  ),
                ),
                isExpanded: true,
                items: availableLists.map((list) {
                  final isMyList = list.id == userProfile.listId;
                  return DropdownMenuItem<String>(
                    value: list.id,
                    child: Row(
                      children: [
                        Icon(
                          isMyList ? Icons.person_rounded : Icons.group_rounded,
                          size: 18,
                          color: AppTheme.primaryPurple,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            list.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isMyList ? 'My List' : '${list.memberIds.length} members',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedListId = value);
                },
              ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Item selector
            Text(
              'Select items to copy:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedItemIds.addAll(widget.items.map((item) => item.id));
                    });
                  },
                  icon: const Icon(Icons.check_box_rounded, size: 18),
                  label: const Text('Select All'),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() => _selectedItemIds.clear());
                  },
                  icon: const Icon(Icons.check_box_outline_blank_rounded, size: 18),
                  label: const Text('Clear'),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Items list
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = widget.items[index];
                    final isSelected = _selectedItemIds.contains(item.id);
                    final quantityText = item.quantity != null
                        ? '${item.quantity}${item.unit != null ? ' ${item.unit}' : ''}'
                        : null;

                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            _selectedItemIds.add(item.id);
                          } else {
                            _selectedItemIds.remove(item.id);
                          }
                        });
                      },
                      title: Text(
                        item.name,
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: quantityText != null
                          ? Text(
                              quantityText,
                              style: const TextStyle(fontSize: 12),
                            )
                          : null,
                      activeColor: AppTheme.accentTeal,
                      dense: true,
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: AppTheme.accentTeal,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_selectedItemIds.length} item(s) will be copied. Originals remain in category.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.accentTeal,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCopying ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: (_isCopying ||
                      _selectedListId == null ||
                      _selectedItemIds.isEmpty ||
                      availableLists.isEmpty)
              ? null
              : () => _copyItems(context, userProfile.displayName),
          icon: _isCopying
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.copy_all_rounded, size: 18),
          label: Text(_isCopying ? 'Copying...' : 'Copy'),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.accentTeal,
          ),
        ),
      ],
    );
  }

  Future<void> _copyItems(BuildContext context, String displayName) async {
    if (_selectedListId == null || _selectedItemIds.isEmpty) return;

    setState(() => _isCopying = true);

    try {
      final selectedItems = widget.items
          .where((item) => _selectedItemIds.contains(item.id))
          .toList();

      final count = await context.read<CustomCategoriesProvider>().copyItemsToList(
            items: selectedItems,
            targetListId: _selectedListId!,
            displayName: displayName,
          );

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied $count item(s) to list'),
            backgroundColor: AppTheme.accentTeal,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        setState(() => _isCopying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy items: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }
}
