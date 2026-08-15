import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../data/item_catalog.dart' show ItemSuggestions;
import '../theme/app_theme.dart';
import '../utils/constants.dart';

enum VoiceState {
  initializing,
  ready,
  awaitingAction,
  listening,
  done,
  error,
}

class _ParsedItem {
  final String name;
  final int quantity;
  const _ParsedItem({required this.name, required this.quantity});
}

class VoiceInputSheet extends StatefulWidget {
  final void Function(String name, String category, int quantity) onItemConfirmed;
  const VoiceInputSheet({super.key, required this.onItemConfirmed});

  @override
  State<VoiceInputSheet> createState() => _VoiceInputSheetState();
}

class _VoiceInputSheetState extends State<VoiceInputSheet> {
  final stt.SpeechToText _speech = stt.SpeechToText();

  VoiceState _state = VoiceState.ready;
  String _liveText = '';
  String _confirmedText = '';
  String _phaseHint = '';
  int _parsedQty = 1;
  late TextEditingController _nameCtrl;

  static const _actionVariants = [
    'add', 'add item', 'add to list', 'please add', 'at', 'had',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _speech.stop();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _initAndStartListening() async {
    // Always stop any active session before restarting
    // (isAvailable may return true but recognizer can be in bad state)
    if (_speech.isListening) {
      await _speech.stop();
      await Future.delayed(const Duration(milliseconds: 200));
    }
    if (_speech.isAvailable) {
      await _startAwaitingAction();
      return;
    }
    setState(() => _state = VoiceState.initializing);
    bool ok = false;
    try {
      ok = await _speech.initialize(
        onError: (e) {
          if (!mounted) return;
          if (e.errorMsg == 'error_no_match' || e.errorMsg == 'error_speech_timeout') {
            _handleSpeechDone();
          } else {
            setState(() => _state = VoiceState.error);
          }
        },
        onStatus: (status) {
          if (!mounted) return;
          if (status == 'done' || status == 'notListening') _handleSpeechDone();
        },
      ).timeout(const Duration(seconds: 8), onTimeout: () => false);
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    if (!ok) { setState(() => _state = VoiceState.error); return; }
    await _startAwaitingAction();
  }

  void _handleSpeechDone() {
    if (!mounted) return;
    switch (_state) {
      case VoiceState.awaitingAction:
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _state == VoiceState.awaitingAction) _startAwaitingAction();
        });
        break;
      case VoiceState.listening:
        if (_confirmedText.isEmpty) setState(() => _state = VoiceState.ready);
        break;
      default:
        break;
    }
  }

  // ── Action word helper ───────────────────────────────────────────────────────

  /// Returns the text AFTER the action word in [raw], or null if no action word found.
  /// Returns an empty string if the action word was the entire utterance.
  String? _textAfterActionWord(String raw) {
    // Sort longest first to avoid partial-match issues (e.g. "add item" vs "add")
    final sorted = [..._actionVariants]..sort((a, b) => b.length.compareTo(a.length));
    for (final v in sorted) {
      if (raw == v) return '';
      if (raw.startsWith('$v ')) return raw.substring(v.length + 1).trim();
    }
    // Fuzzy single short word starting with 'a'
    final words = raw.split(' ');
    if (words.isNotEmpty && words.first.startsWith('a') && words.first.length <= 4) {
      return words.skip(1).join(' ').trim();
    }
    return null;
  }

  // ── Phase 1: await action word ──────────────────────────────────────────────
  Future<void> _startAwaitingAction() async {
    setState(() {
      _state = VoiceState.awaitingAction;
      _phaseHint = '';
      _liveText = '';
    });
    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        final raw = result.recognizedWords.toLowerCase().trim();
        setState(() => _phaseHint = result.recognizedWords);

        final afterAction = _textAfterActionWord(raw);
        if (afterAction != null) {
          _speech.stop();
          if (afterAction.isNotEmpty) {
            // "Add Milk" spoken together in Phase 2 → jump straight to done
            final parsed = _parse(afterAction);
            Future.delayed(const Duration(milliseconds: 200), () {
              if (!mounted) return;
              setState(() {
                _state = VoiceState.done;
                _confirmedText = parsed.name;
                _parsedQty = parsed.quantity;
                _liveText = parsed.name;
                _nameCtrl.text = parsed.name;
                _phaseHint = '';
              });
            });
          } else {
            // Just "Add" → proceed to Phase 3
            Future.delayed(const Duration(milliseconds: 200), () {
              if (mounted) _startListening();
            });
          }
        } else if (result.finalResult && raw.isNotEmpty) {
          setState(() => _phaseHint = '');
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted && _state == VoiceState.awaitingAction) _startAwaitingAction();
          });
        }
      },
      // dictation + onDevice for lower audio threshold at distance (mobile only)
      listenFor: const Duration(seconds: 45),
      pauseFor: const Duration(seconds: 5),
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
        onDevice: !kIsWeb,
        listenMode: stt.ListenMode.dictation,
      ),
    );
  }

  // ── Phase 3: listen for item name ───────────────────────────────────────────
  Future<void> _startListening() async {
    setState(() {
      _state = VoiceState.listening;
      _liveText = '';
      _phaseHint = '';
      _confirmedText = '';
      _parsedQty = 1;
      _nameCtrl.text = '';
    });
    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        final parsed = _parse(result.recognizedWords);
        setState(() {
          _liveText = parsed.name;
          _parsedQty = parsed.quantity;
          if (result.finalResult) {
            _confirmedText = parsed.name;
            _nameCtrl.text = parsed.name;
            _state = VoiceState.done;
          }
        });
      },
      // dictation + onDevice for lower audio threshold at distance (mobile only)
      // cancelOnError: false — temporary no-match won't abort the session
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 6),
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
        onDevice: !kIsWeb,
        listenMode: stt.ListenMode.dictation,
      ),
    );
  }

  // ── Speech recognition correction ─────────────────────────────────────────
  /// Maps common speech misrecognitions to correct shopping item names.
  static const _speechCorrections = <String, String>{
    'ben': 'Pen', 'bens': 'Pens', 'band': 'Pan',
    'cancel': 'Pencil', 'cancelled': 'Pencil', 'council': 'Pencil',
    'stencil': 'Pencil', 'principle': 'Pencil', 'principal': 'Pencil',
    'flower': 'Flour', 'floor': 'Flour',
    'meet': 'Meat', 'mead': 'Meat', 'meta': 'Meat',
    'piece': 'Peas', 'pees': 'Peas', 'fees': 'Peas',
    'keys': 'Ghee', 'gee': 'Ghee', 'knee': 'Ghee',
    'dye': 'Dal', 'dull': 'Dal', 'tall': 'Dal',
    'opinion': 'Onion', 'minion': 'Onion',
    'carat': 'Carrot', 'care it': 'Carrot',
    'salary': 'Celery', 'gallery': 'Celery',
    'butter milk': 'Buttermilk', 'to do': 'Tofu',
    'calendar': 'Coriander', 'colander': 'Coriander',
    'champagne': 'Shampoo', 'champu': 'Shampoo',
    'deterrent': 'Detergent', 'determine': 'Detergent',
    'refrigerate her': 'Refrigerator',
    'tooth rush': 'Toothbrush', 'tooth pace': 'Toothpaste',
    'head phones': 'Headphones', 'ear phones': 'Earphones',
    'lab top': 'Laptop', 'key board': 'Keyboard', 'note book': 'Notebook',
    'blue stick': 'Glue stick', 'sellotape': 'Cello tape',
    'jinger': 'Ginger', 'carlic': 'Garlic', 'kitchen': 'Chicken',
    'pioneer': 'Paneer', 'jaguary': 'Jaggery', 'swagger': 'Sugar',
    'spin edge': 'Spinach', 'garbage': 'Cabbage',
    'call flower': 'Cauliflower', 'store berry': 'Strawberry',
    'blue berry': 'Blueberry', 'razz berry': 'Raspberry',
    'pine apple': 'Pineapple', 'water melon': 'Watermelon',
    'poem granite': 'Pomegranate', 'poem grant': 'Pomegranate',
    'oliver oil': 'Olive oil', 'coco not oil': 'Coconut oil',
    'muscle oil': 'Mustard oil', 'sun flour oil': 'Sunflower oil',
    'most key to': 'Mosquito repellent',
    'san ties her': 'Hand sanitizer',
    'microphone': 'Macaroni', 'sprinter': 'Printer',
    'churger': 'Charger', 'demo': 'Dahi', 'darhi': 'Dahi',
    'rice vice': 'Rice', 'advice': 'Rice', 'mice': 'Rice',
    'icing': 'Icing sugar', 'cap see come': 'Capsicum',
    'half': 'Atta', 'odd': 'Oats', 'lemon grass': 'Lemongrass',
  };

  /// Corrects speech recognition errors using a correction map and fuzzy matching.
  static String _correctSpeech(String input) {
    if (input.isEmpty) return input;
    final lower = input.toLowerCase().trim();
    // 1. Exact correction map match
    if (_speechCorrections.containsKey(lower)) {
      return _speechCorrections[lower]!;
    }
    // 2. Already an exact catalog match — return as-is (well recognized)
    final catalog = ItemSuggestions.allKeys;
    for (final key in catalog) {
      if (key.toLowerCase() == lower) return key;
    }
    // 3. Fuzzy matching for short inputs (1–2 words)
    final wordCount = lower.trim().split(RegExp(r'\s+')).length;
    if (wordCount <= 2 && lower.length >= 3) {
      String? bestMatch;
      int bestDist = 999;
      final maxDist = lower.length <= 4 ? 1 : (lower.length <= 7 ? 2 : 3);
      for (final key in catalog) {
        if ((key.length - lower.length).abs() > maxDist + 1) continue;
        final d = _levenshtein(lower, key.toLowerCase());
        if (d <= maxDist && d < bestDist) {
          bestDist = d;
          bestMatch = key;
        }
      }
      if (bestMatch != null) return bestMatch;
    }
    return input;
  }

  /// Computes Levenshtein edit distance between two strings.
  static int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    final prev = List<int>.generate(b.length + 1, (i) => i);
    final curr = List<int>.filled(b.length + 1, 0);
    for (int i = 0; i < a.length; i++) {
      curr[0] = i + 1;
      for (int j = 0; j < b.length; j++) {
        final cost = a[i] == b[j] ? 0 : 1;
        curr[j + 1] = [curr[j] + 1, prev[j + 1] + 1, prev[j] + cost]
            .reduce((a, b) => a < b ? a : b);
      }
      prev.setAll(0, curr);
    }
    return prev[b.length];
  }

  _ParsedItem _parse(String raw) {
    String s = raw.toLowerCase().trim();
    const fillers = [
      'please add', 'please buy', 'please get', 'add to list',
      'add ', 'buy ', 'get ', 'i need ', 'we need ', 'put ',
    ];
    for (final f in fillers) {
      if (s.startsWith(f)) { s = s.substring(f.length); break; }
    }
    int qty = 1;
    final numMatch = RegExp(r'^(\d+)\s+').firstMatch(s);
    if (numMatch != null) {
      qty = int.tryParse(numMatch.group(1)!) ?? 1;
      s = s.substring(numMatch.end);
    }
    const units = [
      'kg ', 'gm ', 'gram ', 'grams ', 'litre ', 'liter ', 'ml ',
      'packet ', 'packs ', 'pack ', 'bottle ', 'bottles ',
      'piece ', 'pieces ', 'dozen ', 'of ',
    ];
    for (final u in units) {
      if (s.startsWith(u)) { s = s.substring(u.length); break; }
    }
    s = s.trim();
    if (s.isNotEmpty) s = s[0].toUpperCase() + s.substring(1);
    // Apply speech correction to improve recognition accuracy
    s = _correctSpeech(s);
    return _ParsedItem(name: s, quantity: qty);
  }

  void _confirmAdd() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final category = ItemSuggestions.detectCategory(name);
    widget.onItemConfirmed(name, category, _parsedQty);
    Navigator.pop(context);
  }

  void _onMicTap() {
    switch (_state) {
      case VoiceState.awaitingAction:
      case VoiceState.listening:
        _speech.stop();
        setState(() {
          _state = _confirmedText.isEmpty ? VoiceState.ready : VoiceState.done;
          _phaseHint = '';
        });
        break;
      case VoiceState.ready:
      case VoiceState.done:
        _initAndStartListening();
        break;
      case VoiceState.initializing:
        break;
      default:
        break;
    }
  }

  String get _statusText {
    switch (_state) {
      case VoiceState.initializing:
        return 'Starting microphone…';
      case VoiceState.ready:
        return 'Tap the mic to start';
      case VoiceState.awaitingAction:
        return _phaseHint.isEmpty ? 'Say  "Add"…' : '"$_phaseHint"';
      case VoiceState.listening:
        return 'Listening… say your item name';
      case VoiceState.done:
        return 'Got it! Edit if needed, then add.';
      case VoiceState.error:
        return 'Microphone unavailable';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final displayName = (_state == VoiceState.done || _state == VoiceState.listening)
        ? (_state == VoiceState.listening ? _liveText : _confirmedText)
        : '';
    final catName = displayName.isNotEmpty ? ItemSuggestions.detectCategory(displayName) : '';
    final catColor = catName.isNotEmpty ? AppTheme.categoryColor(catName) : cs.primary;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Add by Voice',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface),
            ),
            const SizedBox(height: 14),

            // Phase step indicator (only during active phases)
            if (_state == VoiceState.awaitingAction ||
                _state == VoiceState.listening)
              _PhaseStepRow(state: _state, cs: cs)
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: -0.1, end: 0, duration: 300.ms),

            const SizedBox(height: 10),

            // Status text
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                _statusText,
                key: ValueKey(_state.name + _phaseHint),
                style: TextStyle(
                  fontSize: 13,
                  color: _state == VoiceState.awaitingAction
                      ? cs.primary
                      : cs.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 28),

            // Mic button
            _MicAnimWidget(state: _state, cs: cs, onTap: _onMicTap),
            const SizedBox(height: 28),

            // Live transcription / editable result (Phase 3 + done)
            if (_state == VoiceState.listening || _state == VoiceState.done) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 60),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _state == VoiceState.done
                        ? cs.primary.withValues(alpha: 0.5)
                        : cs.outlineVariant,
                    width: 1.5,
                  ),
                ),
                child: _state == VoiceState.done
                    ? TextField(
                        controller: _nameCtrl,
                        autofocus: false,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                        decoration: InputDecoration.collapsed(
                          hintText: 'Item name',
                          hintStyle: TextStyle(color: cs.onSurfaceVariant),
                        ),
                        onChanged: (v) => setState(() => _confirmedText = v),
                      )
                    : Text(
                        _liveText.isEmpty ? '…' : _liveText,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: _liveText.isEmpty ? cs.onSurfaceVariant : cs.onSurface,
                        ),
                      ),
              )
                  .animate()
                  .fadeIn(duration: 250.ms)
                  .slideY(begin: 0.1, end: 0, duration: 250.ms),
              const SizedBox(height: 10),

              // Category + quantity badges
              if (displayName.isNotEmpty)
                Row(
                  children: [
                    if (catName.isNotEmpty && catName != ItemCategory.other)
                      _Badge(label: catName, color: catColor),
                    if (_parsedQty > 1) ...[
                      const SizedBox(width: 8),
                      _Badge(label: 'Qty: $_parsedQty', color: cs.secondary),
                    ],
                  ],
                ),
              const SizedBox(height: 24),
            ],

            // Action buttons (done state)
            if (_state == VoiceState.done)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.replay_rounded, size: 18),
                      label: const Text('Retry'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _initAndStartListening,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text(
                        'Add to List',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _nameCtrl.text.trim().isNotEmpty ? _confirmAdd : null,
                    ),
                  ),
                ],
              )
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.15, end: 0, duration: 300.ms),

            // Error state
            if (_state == VoiceState.error) ...[
              Icon(Icons.mic_off_rounded, size: 56, color: Colors.red.shade300),
              const SizedBox(height: 12),
              Text(
                'Microphone not available.\nPlease allow microphone access and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant, height: 1.5),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Close'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Phase step indicator row ───────────────────────────────────────────────────

class _PhaseStepRow extends StatelessWidget {
  final VoiceState state;
  final ColorScheme cs;

  const _PhaseStepRow({required this.state, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StepDot(
          label: '1',
          title: 'Add',
          active: state == VoiceState.awaitingAction,
          done: state == VoiceState.listening,
          cs: cs,
        ),
        _StepLine(
          active: state == VoiceState.listening,
          cs: cs,
        ),
        _StepDot(
          label: '2',
          title: 'Item name',
          active: state == VoiceState.listening,
          done: false,
          cs: cs,
        ),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  final String label;
  final String title;
  final bool active;
  final bool done;
  final ColorScheme cs;

  const _StepDot({
    required this.label,
    required this.title,
    required this.active,
    required this.done,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final color = done
        ? Colors.green.shade500
        : active
            ? cs.primary
            : cs.outlineVariant;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: active ? 32 : 26,
          height: active ? 32 : 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done
                ? Colors.green.shade500
                : active
                    ? cs.primary
                    : cs.surfaceContainerHighest,
            border: Border.all(color: color, width: 1.5),
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                : Text(
                    label,
                    style: TextStyle(
                      fontSize: active ? 13 : 11,
                      fontWeight: FontWeight.w700,
                      color: active ? Colors.white : cs.onSurfaceVariant,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            color: active ? cs.primary : cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool active;
  final ColorScheme cs;

  const _StepLine({required this.active, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 36,
        height: 2,
        color: active ? cs.primary : cs.outlineVariant,
      ),
    );
  }
}

// ── Animated mic button ───────────────────────────────────────────────────────

class _MicAnimWidget extends StatelessWidget {
  final VoiceState state;
  final ColorScheme cs;
  final VoidCallback onTap;

  const _MicAnimWidget({
    required this.state,
    required this.cs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isAwaitingAction   = state == VoiceState.awaitingAction;
    final isListening        = state == VoiceState.listening;
    final isLoading          = state == VoiceState.initializing;
    final isError            = state == VoiceState.error;
    final isAnyActive        = isAwaitingAction || isListening;

    // Choose mic ring / button colour per phase
    final Color activeColor = isAwaitingAction
        ? const Color(0xFF06B6D4) // cyan for phase 1 (action)
        : cs.primary;             // primary for phase 2 (item name)

    final bgColor  = isAnyActive ? activeColor : cs.primaryContainer;
    final iconColor = isAnyActive ? Colors.white : cs.onPrimaryContainer;

    Widget coreButton = GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: activeColor.withValues(alpha: isAnyActive ? 0.35 : 0.12),
              blurRadius: isAnyActive ? 20 : 8,
              spreadRadius: isAnyActive ? 6 : 0,
            ),
          ],
        ),
        child: isLoading
            ? Padding(
                padding: const EdgeInsets.all(22),
                child: CircularProgressIndicator(
                  color: cs.onPrimaryContainer,
                  strokeWidth: 2.5,
                ),
              )
            : Icon(
                isError
                    ? Icons.mic_off_rounded
                    : isAnyActive
                        ? Icons.mic_rounded
                        : Icons.mic_none_rounded,
                size: 38,
                color: iconColor,
              ),
      ),
    );

    if (isAnyActive) {
      return Stack(
        alignment: Alignment.center,
        children: [
          // Ring 1
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: activeColor.withValues(alpha: 0.15),
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(2.0, 2.0),
                duration: 1100.ms,
                curve: Curves.easeOut,
              )
              .fade(begin: 0.7, end: 0, duration: 1100.ms),

          // Ring 2
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: activeColor.withValues(alpha: 0.10),
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(2.6, 2.6),
                duration: 1100.ms,
                curve: Curves.easeOut,
                delay: 400.ms,
              )
              .fade(begin: 0.5, end: 0, duration: 1100.ms),

          // Core button breathing
          coreButton
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 1.0, end: 1.06, duration: 500.ms),
        ],
      );
    }

    return coreButton;
  }
}

// ── Small category / quantity badge ──────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
