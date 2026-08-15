import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class RenameListDialog extends StatefulWidget {
  final String currentName;
  final String listType; // 'shared' or 'personal'

  const RenameListDialog({
    super.key,
    required this.currentName,
    required this.listType,
  });

  static Future<String?> show({
    required BuildContext context,
    required String currentName,
    required String listType,
  }) async {
    return showDialog<String>(
      context: context,
      builder: (context) => RenameListDialog(
        currentName: currentName,
        listType: listType,
      ),
    );
  }

  @override
  State<RenameListDialog> createState() => _RenameListDialogState();
}

class _RenameListDialogState extends State<RenameListDialog> {
  late final TextEditingController _controller;
  String? _errorText;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
    // Select all text for easy editing
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final rawName = _controller.text;
    final error = Validators.validateListName(rawName);

    if (error != null) {
      setState(() => _errorText = error);
      return;
    }

    // Convert spaces to underscores (same as create flow)
    final processedName = rawName.trim().replaceAll(' ', '_');

    // Don't close if name unchanged
    if (processedName == widget.currentName) {
      Navigator.pop(context); // No changes
      return;
    }

    Navigator.pop(context, processedName);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Rename ${widget.listType == 'personal' ? 'Personal' : 'Shared'} List',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: AppConstants.maxListNameLength,
        decoration: InputDecoration(
          labelText: 'List Name',
          errorText: _errorText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          counterText: '', // Hide character counter
        ),
        onSubmitted: (_) => _submit(),
        onChanged: (_) {
          // Clear error on typing
          if (_errorText != null) {
            setState(() => _errorText = null);
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Rename'),
        ),
      ],
    );
  }
}
