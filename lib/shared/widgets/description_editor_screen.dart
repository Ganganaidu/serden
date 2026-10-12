import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

const int kMaxDescriptionLength = 20000;

/// Full-screen editor for a long line-item description. Pops with the edited
/// text on Done and with nothing on Cancel.
class DescriptionEditorScreen extends StatefulWidget {
  final String itemName;
  final String initialText;

  /// "estimate" or "invoice" — used in the footer note.
  final String documentLabel;

  const DescriptionEditorScreen({
    super.key,
    required this.itemName,
    required this.initialText,
    required this.documentLabel,
  });

  @override
  State<DescriptionEditorScreen> createState() =>
      _DescriptionEditorScreenState();
}

class _DescriptionEditorScreenState extends State<DescriptionEditorScreen> {
  late final TextEditingController _controller;
  final _scroll = ScrollController();
  final _focus = FocusNode();
  bool _showJump = false;

  bool get _changed => _controller.text != widget.initialText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _controller.addListener(() => setState(() {}));
    _scroll.addListener(_updateJump);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateJump());
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _updateJump() {
    if (!_scroll.hasClients) return;
    final show = _scroll.position.maxScrollExtent - _scroll.offset > 160;
    if (show != _showJump) setState(() => _showJump = show);
  }

  int get _lineCount =>
      _controller.text.isEmpty ? 0 : '\n'.allMatches(_controller.text).length + 1;

  Future<void> _cancel() async {
    if (!_changed) {
      context.pop();
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your edits to this description will be lost.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Keep editing')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Discard')),
        ],
      ),
    );
    if (discard == true && mounted) context.pop();
  }

  // ---- List formatting ----------------------------------------------------

  static final _bullet = RegExp(r'^• ');
  static final _numbered = RegExp(r'^\d+\. ');

  /// Applies [transform] to every line touched by the selection.
  void _editLines(String Function(String line, int index) transform) {
    final text = _controller.text;
    final sel = _controller.selection;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;
    final from = start == 0 ? 0 : text.lastIndexOf('\n', start - 1) + 1;
    var to = text.indexOf('\n', end);
    if (to == -1) to = text.length;
    final lines = text.substring(from, to).split('\n');
    final out = [for (var i = 0; i < lines.length; i++) transform(lines[i], i)];
    final replaced = out.join('\n');
    _controller.value = TextEditingValue(
      text: text.replaceRange(from, to, replaced),
      selection: TextSelection(
          baseOffset: from, extentOffset: from + replaced.length),
    );
    _focus.requestFocus();
  }

  void _toggleBullets() {
    final allBulleted = _selectedLines().every((l) => _bullet.hasMatch(l));
    _editLines((line, _) {
      final plain = line.replaceFirst(_bullet, '').replaceFirst(_numbered, '');
      return allBulleted ? plain : '• $plain';
    });
  }

  void _toggleNumbers() {
    final allNumbered = _selectedLines().every((l) => _numbered.hasMatch(l));
    _editLines((line, i) {
      final plain = line.replaceFirst(_bullet, '').replaceFirst(_numbered, '');
      return allNumbered ? plain : '${i + 1}. $plain';
    });
  }

  List<String> _selectedLines() {
    final text = _controller.text;
    final sel = _controller.selection;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;
    final from = start == 0 ? 0 : text.lastIndexOf('\n', start - 1) + 1;
    var to = text.indexOf('\n', end);
    if (to == -1) to = text.length;
    return text.substring(from, to).split('\n');
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final clip = data?.text;
    if (clip == null || clip.isEmpty) return;
    final text = _controller.text;
    final sel = _controller.selection;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;
    var next = text.replaceRange(start, end, clip);
    if (next.length > kMaxDescriptionLength) {
      next = next.substring(0, kMaxDescriptionLength);
    }
    final caret = (start + clip.length).clamp(0, next.length);
    _controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: caret),
    );
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.itemName.trim().isEmpty ? 'Line item' : widget.itemName.trim();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        backgroundColor: AppColors.card,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: _cancel,
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.inkSoft),
                      child: const Text('Cancel'),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const Text('Description',
                              style: AppTextStyles.headingMedium),
                          Text(
                            '$name · ${_changed ? 'Edited' : 'No changes'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.pop(_controller.text),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.green800,
                          textStyle: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontWeight: FontWeight.w800,
                              fontSize: 16)),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.line),
              Expanded(
                child: Stack(
                  children: [
                    TextField(
                      controller: _controller,
                      focusNode: _focus,
                      scrollController: _scroll,
                      autofocus: true,
                      expands: true,
                      maxLines: null,
                      minLines: null,
                      maxLength: kMaxDescriptionLength,
                      textAlignVertical: TextAlignVertical.top,
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.multiline,
                      inputFormatters: [_ListContinuationFormatter()],
                      style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 17, height: 1.5, color: AppColors.ink),
                      decoration: const InputDecoration(
                        hintText: 'Describe the work in detail…',
                        counterText: '',
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.fromLTRB(20, 18, 20, 18),
                      ),
                    ),
                    if (_showJump)
                      Positioned(
                        right: 16,
                        bottom: 12,
                        child: Material(
                          color: AppColors.ink,
                          borderRadius: BorderRadius.circular(24),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () => _scroll.animateTo(
                              _scroll.position.maxScrollExtent,
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOut,
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 11),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.arrow_downward,
                                      size: 16, color: Colors.white),
                                  SizedBox(width: 6),
                                  Text('Jump to end',
                                      style: TextStyle(
                                          fontFamily:
                                              AppTextStyles.fontFamily,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.page,
                  border: Border(top: BorderSide(color: AppColors.line)),
                ),
                padding: const EdgeInsets.fromLTRB(12, 6, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _ToolButton(
                            icon: Icons.format_list_bulleted,
                            tooltip: 'Bulleted list',
                            onTap: _toggleBullets),
                        _ToolButton(
                            icon: Icons.format_list_numbered,
                            tooltip: 'Numbered list',
                            onTap: _toggleNumbers),
                        _ToolButton(
                            icon: Icons.content_paste,
                            tooltip: 'Paste',
                            onTap: _paste),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('$_lineCount lines',
                                style: AppTextStyles.caption.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.inkSoft)),
                            Text(
                                '${_controller.text.length} / $kMaxDescriptionLength',
                                style: AppTextStyles.caption),
                          ],
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 4, top: 2),
                      child: Text(
                        'Prints in full under this item on the ${widget.documentLabel} PDF.',
                        style: AppTextStyles.caption,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _ToolButton(
      {required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        icon: Icon(icon, color: AppColors.inkSoft),
      );
}

/// Pressing Enter on a "• " or "1. " line continues the list on the next
/// line; pressing it on an empty list line ends the list.
class _ListContinuationFormatter extends TextInputFormatter {
  static final _bullet = RegExp(r'^• ');
  static final _numbered = RegExp(r'^(\d+)\. ');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final added = newValue.text.length - oldValue.text.length;
    final caret = newValue.selection.baseOffset;
    if (added != 1 ||
        !newValue.selection.isCollapsed ||
        caret < 1 ||
        newValue.text[caret - 1] != '\n') {
      return newValue;
    }
    final lineStart = caret - 1 == 0
        ? 0
        : newValue.text.lastIndexOf('\n', caret - 2) + 1;
    final prev = newValue.text.substring(lineStart, caret - 1);

    String? prefix;
    if (_bullet.hasMatch(prev)) {
      prefix = '• ';
    } else {
      final m = _numbered.firstMatch(prev);
      if (m != null) prefix = '${int.parse(m.group(1)!) + 1}. ';
    }
    if (prefix == null) return newValue;

    final marker = _bullet.hasMatch(prev) ? '• ' : _numbered.firstMatch(prev)!.group(0)!;
    if (prev == marker) {
      // Empty list item → remove the marker and the newline just typed.
      final text = newValue.text.replaceRange(lineStart, caret, '');
      return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: lineStart),
      );
    }
    final text = newValue.text.replaceRange(caret, caret, prefix);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: caret + prefix.length),
    );
  }
}
