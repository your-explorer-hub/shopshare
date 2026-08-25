import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/custom_category.dart';
import '../models/category_item.dart';
import '../providers/auth_provider.dart';
import '../providers/custom_categories_provider.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../utils/subscription_limits.dart';
import 'manage_categories/widgets/copy_to_list_dialog.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final categoriesProvider = context.read<CustomCategoriesProvider>();

      if (auth.userProfile != null) {
        categoriesProvider.initForUser(
          auth.userProfile!.id,
          auth.userProfile!.subscriptionTier,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage Categories',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Consumer<CustomCategoriesProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading categories',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.error!,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (provider.categories.isEmpty) {
            return _buildEmptyState(context);
          }

          return Column(
            children: [
              _buildInfoBanner(context),
              _buildLimitIndicator(context, provider),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.categories.length,
                  itemBuilder: (context, index) {
                    final category = provider.categories[index];
                    return _CategoryTile(
                      category: category,
                      items: provider.itemsForCategory(category.id),
                      canAddMoreItems: provider.canAddMoreItems(category.id),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<CustomCategoriesProvider>(
        builder: (context, provider, _) {
          final canCreate = provider.canCreateMore;
          return FloatingActionButton.extended(
            onPressed: canCreate ? () => _showAddCategoryDialog(context) : null,
            icon: const Icon(Icons.add_rounded),
            label: const Text('New Category'),
            backgroundColor: canCreate ? AppTheme.accentTeal : Colors.grey,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No Custom Categories',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create reusable shopping templates for events like Christmas, Diwali, or Birthday parties.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showAddCategoryDialog(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Your First Category'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentTeal.withOpacity(0.1),
            AppTheme.accentTeal.withOpacity(0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.accentTeal.withOpacity(0.3),
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppTheme.accentTeal,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Create reusable shopping templates for recurring events. Items you add here remain permanently as templates - when you copy items to a shopping list, the originals stay here for next time.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.accentTeal.withOpacity(0.9),
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitIndicator(BuildContext context, CustomCategoriesProvider provider) {
    final current = provider.categories.length;
    final max = provider.maxCategories;
    final tierName = SubscriptionLimits.tierDisplayName(provider.tier);
    final isNearLimit = current >= (max * 0.8);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isNearLimit
            ? Colors.orange.shade50.withOpacity(0.3)
            : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isNearLimit ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
            size: 20,
            color: isNearLimit ? Colors.orange.shade700 : AppTheme.accentTeal,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$current/$max categories ($tierName tier)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isNearLimit ? Colors.orange.shade700 : null,
                  ),
            ),
          ),
          if (current >= max)
            TextButton(
              onPressed: () {
                // TODO: Navigate to subscription upgrade screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Upgrade to add more categories'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Upgrade'),
            ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New Category'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  hintText: 'e.g., Christmas, Diwali, Birthday Party',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                autofocus: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a category name';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Text(
                'Color and emoji will be auto-assigned from theme',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final name = nameController.text.trim();
                Navigator.pop(dialogContext);

                try {
                  await context.read<CustomCategoriesProvider>().createCategory(name);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Created "$name"')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to create category: $e'),
                        backgroundColor: Colors.red.shade700,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatefulWidget {
  final CustomCategory category;
  final List<CategoryItem> items;
  final bool canAddMoreItems;

  const _CategoryTile({
    required this.category,
    required this.items,
    required this.canAddMoreItems,
  });

  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<CustomCategoriesProvider>();
    final maxItems = provider.maxItemsPerCategory;
    final itemCount = widget.items.length;
    final isNearLimit = itemCount >= (maxItems * 0.8);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _parseColor(widget.category.colorHex).withOpacity(0.2),
          child: Text(
            widget.category.emoji,
            style: const TextStyle(fontSize: 24),
          ),
        ),
        title: Text(
          widget.category.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '$itemCount/$maxItems items',
          style: TextStyle(
            fontSize: 12,
            color: isNearLimit ? Colors.orange.shade700 : null,
            fontWeight: isNearLimit ? FontWeight.w600 : null,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              color: Colors.red.shade400,
              tooltip: 'Delete Category',
              onPressed: () => _confirmDeleteCategory(context),
            ),
            Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              size: 24,
            ),
          ],
        ),
        tilePadding: const EdgeInsets.only(left: 16, right: 4),
        onExpansionChanged: (expanded) {
          setState(() => _isExpanded = expanded);
        },
        controlAffinity: ListTileControlAffinity.trailing,
        children: [
          if (widget.items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No items yet. Add your first item below.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...widget.items.map((item) => _ItemTile(item: item)),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: widget.canAddMoreItems
                      ? () => _showAddItemDialog(context)
                      : null,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Item'),
                ),
                if (widget.items.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _showCopyToListDialog(context),
                    icon: const Icon(Icons.copy_all_rounded, size: 18),
                    label: const Text('Copy to List'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.accentTeal,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppTheme.primaryPurple;
    }
  }

  void _confirmDeleteCategory(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text(
          'This will permanently delete "${widget.category.name}" and all ${widget.items.length} items.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await context.read<CustomCategoriesProvider>().deleteCategory(widget.category.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Category deleted')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete: $e'),
                      backgroundColor: Colors.red.shade700,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog(BuildContext context) {
    final nameController = TextEditingController();
    final quantityController = TextEditingController();
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? selectedUnit;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Item'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Item Name',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  autofocus: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter item name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Quantity (optional)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        value: selectedUnit,
                        decoration: const InputDecoration(
                          labelText: 'Unit (optional)',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('None')),
                          ...AppConstants.itemUnits.map((unit) =>
                            DropdownMenuItem(value: unit, child: Text(unit)),
                          ),
                        ],
                        onChanged: (value) => selectedUnit = value,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final name = nameController.text.trim();
                final quantityText = quantityController.text.trim();
                final quantity = quantityText.isEmpty ? null : int.tryParse(quantityText);
                final notes = notesController.text.trim();

                Navigator.pop(dialogContext);

                try {
                  await context.read<CustomCategoriesProvider>().addItem(
                        categoryId: widget.category.id,
                        name: name,
                        quantity: quantity,
                        unit: selectedUnit,
                        notes: notes.isEmpty ? null : notes,
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Added "$name"')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to add item: $e'),
                        backgroundColor: Colors.red.shade700,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showCopyToListDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => CopyToListDialog(
        items: widget.items,
        categoryName: widget.category.name,
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final CategoryItem item;

  const _ItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final quantityText = item.quantity != null
        ? '${item.quantity}${item.unit != null ? ' ${item.unit}' : ''}'
        : null;

    return ListTile(
      leading: const Icon(Icons.shopping_basket_outlined, size: 20),
      title: Text(item.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (quantityText != null)
            Text(
              quantityText,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          if (item.notes != null)
            Text(
              item.notes!,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            tooltip: 'Edit',
            onPressed: () => _showEditDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            color: Colors.red.shade400,
            tooltip: 'Delete',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _EditItemSheet(item: item),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Item?'),
        content: Text('Remove "${item.name}" from this category?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await context.read<CustomCategoriesProvider>().deleteItem(
                      item.id,
                      item.categoryId,
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Item deleted')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete: $e'),
                      backgroundColor: Colors.red.shade700,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Edit Item Bottom Sheet ────────────────────────────────────────────────

class _EditItemSheet extends StatefulWidget {
  final CategoryItem item;

  const _EditItemSheet({required this.item});

  @override
  State<_EditItemSheet> createState() => _EditItemSheetState();
}

class _EditItemSheetState extends State<_EditItemSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _notesController;
  String? _selectedUnit;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _quantityController = TextEditingController(
      text: widget.item.quantity?.toString() ?? '',
    );
    _notesController = TextEditingController(text: widget.item.notes ?? '');
    _selectedUnit = widget.item.unit;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);

    try {
      final quantityText = _quantityController.text.trim();
      final quantity = quantityText.isEmpty ? null : int.tryParse(quantityText);
      final notes = _notesController.text.trim();

      final updatedItem = widget.item.copyWith(
        name: name,
        quantity: quantity,
        unit: _selectedUnit,
        notes: notes.isEmpty ? null : notes,
      );

      await context.read<CustomCategoriesProvider>().updateItem(updatedItem);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Updated "$name"')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Edit Item',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Update item details',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.6),
                      ),
                ),
                const SizedBox(height: 20),

                // Item name
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Item Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.edit_rounded),
                  ),
                  textCapitalization: TextCapitalization.words,
                  autofocus: true,
                ),
                const SizedBox(height: 16),

                // Quantity and Unit row
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _quantityController,
                        decoration: InputDecoration(
                          labelText: 'Quantity',
                          hintText: 'Optional',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.format_list_numbered_rounded),
                        ),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: cs.outline, width: 1.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: _selectedUnit,
                            isExpanded: true,
                            hint: const Text('Unit'),
                            icon: Icon(Icons.expand_more_rounded, color: cs.primary),
                            dropdownColor: cs.surface,
                            borderRadius: BorderRadius.circular(12),
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                            onChanged: (v) => setState(() => _selectedUnit = v),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('None')),
                              ...AppConstants.itemUnits.map((unit) =>
                                DropdownMenuItem(value: unit, child: Text(unit)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Notes
                TextField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Optional',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.notes_rounded),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded),
                    label: Text(_saving ? 'Saving...' : 'Save Changes'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accentTeal,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
