import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/shopping_item.dart';
import '../providers/shopping_provider.dart';
import '../shared/dialogs/destructive_dialog.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';

class ItemCardWidget extends StatelessWidget {
  final ShoppingItem item;

  /// Toggle item completion (tap the leading checkbox).
  final VoidCallback? onToggle;

  /// Called by swipe-to-delete dismissible.
  final VoidCallback? onDelete;

  /// Selection state – driven by the home screen.
  final bool isSelected;

  /// Called when the user taps the trailing select checkbox.
  final VoidCallback? onSelectToggle;

  // Legacy selection-mode params (kept for API compatibility).
  final bool selectionMode;
  final VoidCallback? onTapSelect;
  final VoidCallback? onLongPress;

  /// When true, shows "Added by" attribution (relevant on shared lists).
  /// On personal lists the owner is always the same person — hide it.
  final bool isSharedList;

  const ItemCardWidget({
    super.key,
    required this.item,
    this.onToggle,
    this.onDelete,
    this.isSelected = false,
    this.onSelectToggle,
    this.selectionMode = false,
    this.onTapSelect,
    this.onLongPress,
    this.isSharedList = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryColor = AppTheme.categoryColor(item.category);
    const selColor = AppTheme.primaryPurple;

    Widget card = Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? selColor.withValues(alpha: 0.08)
            : (isDark ? colorScheme.surface : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? selColor.withValues(alpha: 0.5)
              : (item.completed
                  ? Colors.grey.withValues(alpha: 0.15)
                  : categoryColor.withValues(alpha: 0.2)),
          width: isSelected ? 1.8 : 1.2,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: selColor.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        // ── Leading: completion indicator / selection checkbox ─────────
        leading: GestureDetector(
          onTap: () {
            if (selectionMode) {
              onTapSelect?.call();
            } else {
              onToggle?.call();
            }
          },
          child: SizedBox(
            width: 36,
            height: 36,
            child: selectionMode
                ? Checkbox(
                    value: isSelected,
                    onChanged: (_) => onTapSelect?.call(),
                    activeColor: selColor,
                    checkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? selColor
                          : colorScheme.outline.withValues(alpha: 0.5),
                      width: 2,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  )
                : Center(
                    child: Icon(
                      item.completed
                          ? Icons.task_alt_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 28,
                      color: item.completed
                          ? categoryColor
                          : categoryColor.withValues(alpha: 0.45),
                    ),
                  ),
          ),
        ),
        title: Text(
          item.name,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: item.completed && !selectionMode
                ? colorScheme.onSurface.withValues(alpha: 0.45)
                : colorScheme.onSurface,
            decoration: item.completed && !selectionMode
                ? TextDecoration.lineThrough
                : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            // Category badge removed per user feedback
            if (item.quantity != null)
              Row(
                children: [
                  _InfoChip(
                    label: item.unit != null
                        ? '${item.quantity} ${item.unit}'
                        : 'x${item.quantity}',
                    icon: Icons.format_list_numbered_rounded,
                    onTap: () => _showQuantityEditSheet(context, item),
                  ),
                ],
              ),
            // Footer: show completion info or "Added by" on shared lists.
            // Date is already shown in the timeline header — skip it here.
            if (item.completed && item.completedByName != null) ...[
              const SizedBox(height: 4),
              Text(
                '✓ ${item.completedByName}',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ] else if (isSharedList) ...[
              const SizedBox(height: 4),
              Text(
                'Added by ${item.addedByName}',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ],
            if (item.notes != null && item.notes!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                item.notes!,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.55),
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        // ── Trailing: selection checkbox ──────────────────────────────
        trailing: selectionMode
            ? null
            : SizedBox(
                width: 36,
                height: 36,
                child: Checkbox(
                  value: isSelected,
                  onChanged: (_) => onSelectToggle?.call(),
                  activeColor: selColor,
                  checkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? selColor
                        : colorScheme.onSurface.withValues(alpha: 0.28),
                    width: 2,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
        onTap: selectionMode ? onTapSelect : null,
        onLongPress: selectionMode ? null : onLongPress,
      ),
    );

    // Wrap in Dismissible only in normal mode
    if (!selectionMode) {
      card = Dismissible(
        key: Key('${item.id}_dismissible'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red.shade400,
            borderRadius: BorderRadius.circular(16),
          ),
          child:
              const Icon(Icons.delete_rounded, color: Colors.white, size: 26),
        ),
        confirmDismiss: (_) async {
          return await DestructiveDialog.show(
            context: context,
            title: 'Delete item?',
            message:
                '1 item will be permanently removed from the list.\nThis action cannot be undone.',
            confirmText: 'Delete',
          );
        },
        onDismissed: (_) => onDelete?.call(),
        child: card,
      );
    }

    return card.animate().fadeIn(duration: 300.ms).slideX(begin: -0.05, end: 0);
  }

}

void _showQuantityEditSheet(BuildContext context, ShoppingItem item) {
  final provider = context.read<ShoppingProvider>();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _QuantityEditSheet(item: item, provider: provider),
  );
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _InfoChip({required this.label, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEditable = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: isEditable
              ? cs.primaryContainer.withValues(alpha: 0.35)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: isEditable
              ? Border.all(
                  color: cs.primary.withValues(alpha: 0.25), width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 10,
                color: isEditable ? cs.primary : Colors.grey.shade600),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                  fontSize: 11,
                  color: isEditable ? cs.primary : Colors.grey.shade600,
                  fontWeight:
                      isEditable ? FontWeight.w600 : FontWeight.normal),
            ),
            if (isEditable) ...[
              const SizedBox(width: 3),
              Icon(Icons.edit_rounded,
                  size: 9, color: cs.primary.withValues(alpha: 0.7)),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Quantity edit bottom sheet ────────────────────────────────────────────────

class _QuantityEditSheet extends StatefulWidget {
  final ShoppingItem item;
  final ShoppingProvider provider;
  const _QuantityEditSheet({required this.item, required this.provider});

  @override
  State<_QuantityEditSheet> createState() => _QuantityEditSheetState();
}

class _QuantityEditSheetState extends State<_QuantityEditSheet> {
  late final TextEditingController _qtyCtrl;
  late String _unit;
  bool _saving = false;

  // Unit list shared via AppConstants.itemUnits — single source of truth

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController(
      text: '${widget.item.quantity ?? 1}',
    );
    _unit = widget.item.unit ?? 'pcs';
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final n = int.tryParse(_qtyCtrl.text.trim());
    if (n == null || n <= 0) return;
    setState(() => _saving = true);
    await widget.provider.updateItemQuantity(widget.item, n, _unit);
    if (mounted) Navigator.of(context).pop();
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
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                widget.item.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Update quantity & unit',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.55),
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  // Number input
                  SizedBox(
                    width: 90,
                    child: TextField(
                      controller: _qtyCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: false),
                      textAlign: TextAlign.center,
                      autofocus: true,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        labelText: 'Qty',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Unit dropdown
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: cs.outline, width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _unit,
                          isExpanded: true,
                          icon: Icon(Icons.expand_more_rounded,
                              color: cs.primary),
                          dropdownColor: cs.surface,
                          borderRadius: BorderRadius.circular(12),
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                          onChanged: (v) {
                            if (v != null) setState(() => _unit = v);
                          },
                          items: AppConstants.itemUnits
                              .map((u) => DropdownMenuItem<String>(
                                    value: u,
                                    child: Text(u),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Save icon button
                  _saving
                      ? const SizedBox(
                          width: 48,
                          height: 48,
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      : FilledButton(
                          onPressed: _save,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 24,
                          ),
                        ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
