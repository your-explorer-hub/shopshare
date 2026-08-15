import 'package:flutter/material.dart';

import '../../../services/firestore_service.dart';
import '../../../theme/app_theme.dart';

class FeedbackTile extends StatefulWidget {
  final dynamic userProfile;
  const FeedbackTile({super.key, required this.userProfile});

  @override
  State<FeedbackTile> createState() => _FeedbackTileState();
}

class _FeedbackTileState extends State<FeedbackTile> {
  final _controller = TextEditingController();
  bool _expanded = false;
  bool _submitting = false;
  static const int _maxChars = 300;

  String? _selectedCategory;
  int _rating = 0;

  static const _categories = [
    ('items', 'Items'),
    ('invitations', 'Invitations'),
    ('limits', 'Limits'),
    ('ui', 'UI'),
    ('user_flow', 'User Flow'),
    ('other', 'Other'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final msg = _controller.text.trim();
    if (msg.isEmpty) return;
    final user = widget.userProfile;
    if (user == null) return;

    setState(() => _submitting = true);
    try {
      await FirestoreService.instance.submitFeedback(
        userId: user.id,
        userName: user.displayName ?? '',
        userEmail: user.email ?? '',
        feedback: msg,
        category: _selectedCategory ?? 'General',
        rating: _rating > 0 ? _rating : null,
      );
      _controller.clear();
      setState(() {
        _expanded = false;
        _selectedCategory = null;
        _rating = 0;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Thank you! Your feedback has been submitted.'),
            ]),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 20),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to submit. Please try again.'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 20),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final charCount = _controller.text.length;
    final atLimit = charCount >= _maxChars;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.blue.shade600.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.feedback_rounded,
                  size: 19, color: Colors.blue.shade600),
            ),
            title: const Text('Feedback / Report Issue',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text(
              _expanded
                  ? 'Describe your issue or suggestion below'
                  : 'Tap to send feedback or report a problem',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white60
                      : const Color(0xFF555555)),
            ),
            trailing: Icon(
              _expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: cs.onSurface.withValues(alpha: 0.4),
            ),
            onTap: () => setState(() => _expanded = !_expanded),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Category chips
                  Text('Category',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : const Color(0xFF444444))),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _categories.map((cat) {
                      final (value, label) = cat;
                      final isSelected = _selectedCategory == value;
                      return GestureDetector(
                        onTap: () => setState(() =>
                            _selectedCategory = isSelected ? null : value),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryPurple
                                    .withValues(alpha: 0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryPurple
                                  : cs.outline.withValues(alpha: 0.35),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Text(label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: isSelected
                                    ? AppTheme.primaryPurple
                                    : cs.onSurface.withValues(alpha: 0.65),
                              )),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  // Star rating
                  Text('Rating',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : const Color(0xFF444444))),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (i) {
                        final star = i + 1;
                        return GestureDetector(
                          onTap: () => setState(
                              () => _rating = _rating == star ? 0 : star),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              star <= _rating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 28,
                              color: star <= _rating
                                  ? Colors.amber.shade600
                                  : cs.onSurface.withValues(alpha: 0.3),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _controller,
                    maxLength: _maxChars,
                    maxLines: 4,
                    minLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Describe your issue or suggestion…',
                      hintStyle: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface.withValues(alpha: 0.4)),
                      filled: true,
                      fillColor: cs.surface,
                      counterStyle: TextStyle(
                        fontSize: 11,
                        color: atLimit
                            ? Colors.red.shade600
                            : cs.onSurface.withValues(alpha: 0.4),
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: AppTheme.primaryPurple, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: (_submitting ||
                            _controller.text.trim().isEmpty)
                        ? null
                        : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryPurple,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      minimumSize: const Size.fromHeight(44),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Submit Feedback',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
