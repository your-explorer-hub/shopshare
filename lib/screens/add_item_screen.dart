import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/item_catalog.dart';
import '../utils/item_categories.dart';
import '../providers/auth_provider.dart';
import '../providers/shopping_provider.dart';
import '../providers/add_item_screen_provider.dart';
import '../widgets/add_item/category_dropdown.dart';
import '../widgets/add_item/item_name_field.dart';
import '../widgets/add_item/section_label.dart';
import '../widgets/add_item/unit_dropdown.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _notesController = TextEditingController();
  late final TextEditingController _quantityController =
      TextEditingController(text: '1');

  @override
  void dispose() {
    _notesController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _autoDetectCategory(String name) {
    final formState = context.read<AddItemScreenProvider>();
    final detected = ItemSuggestions.detectCategory(name);
    if (detected != ItemCategory.other) {
      formState.setCategory(detected, autoDetected: true);
    }
  }

  Future<void> _submit() async {
    final formState = context.read<AddItemScreenProvider>();
    if (formState.itemName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an item name.')),
      );
      return;
    }

    formState.setSubmitting(true);

    final shopping = context.read<ShoppingProvider>();
    final auth = context.read<AuthProvider>();
    final user = auth.userProfile;
    if (user == null) return;

    final success = await shopping.addItem(
      name: _toTitleCase(formState.itemName.trim()),
      category: formState.selectedCategory,
      addedBy: user.id,
      addedByName: user.displayName,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      quantity: formState.quantity,
      unit: formState.selectedUnit,
      inputMethod: 'manual',
    );

    if (!mounted) return;
    formState.setSubmitting(false);

    if (success) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add item. Please try again.')),
      );
    }
  }

  String _toTitleCase(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final formState = context.watch<AddItemScreenProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Item'),
        actions: [
          TextButton(
            onPressed: formState.isSubmitting ? null : _submit,
            child: formState.isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Add'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Item name with autocomplete ─────────────────────────────
          const SectionLabel(label: 'Item name'),
          ItemNameField(
            cs: cs,
            onNameChanged: (name) {
              formState.setItemName(name);
              if (name.length >= 3) _autoDetectCategory(name);
            },
            onSuggestionSelected: (name) {
              formState.setItemName(name);
              _autoDetectCategory(name);
            },
          ),
          const SizedBox(height: 20),

          // ── Category dropdown ───────────────────────────────────────
          Row(
            children: [
              const SectionLabel(label: 'Category'),
              if (formState.categoryAutoDetected) ...[
                const SizedBox(width: 6),
                Tooltip(
                  message:
                      'Category was auto-detected based on the item name.\nYou can change it using the dropdown.',
                  triggerMode: TooltipTriggerMode.tap,
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: cs.primary,
                  ),
                ),
              ],
            ],
          ),
          CategoryDropdown(
            selected: formState.selectedCategory,
            onChanged: (c) => formState.setCategory(c, autoDetected: false),
          ),
          const SizedBox(height: 20),

          // ── Quantity & Unit ─────────────────────────────────────────
          const SectionLabel(label: 'Quantity & Unit'),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 72,
                height: 44,
                child: TextFormField(
                  controller: _quantityController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: false),
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (v) {
                    final n = int.tryParse(v);
                    if (n != null && n > 0) {
                      formState.setQuantity(n);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              UnitDropdown(
                selected: formState.selectedUnit,
                onChanged: formState.setUnit,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Notes ───────────────────────────────────────────────────
          const SectionLabel(label: 'Notes (optional)'),
          TextFormField(
            controller: _notesController,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Add any extra details…',
            ),
          ),
          const SizedBox(height: 32),

          // ── Submit ──────────────────────────────────────────────────
          FilledButton(
            onPressed: formState.isSubmitting ? null : _submit,
            child: formState.isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Add to list'),
          ),
        ],
      ),
    );
  }
}
