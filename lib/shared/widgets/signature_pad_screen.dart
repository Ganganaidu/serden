import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/form_nav_bar.dart';

const Color _kInk = Color(0xFF1B2A4A);
const double _kExportScale = 3;

/// Opens the pad and resolves with the signature PNG, or null if cancelled.
Future<Uint8List?> captureSignature(
  BuildContext context, {
  required String title,
  required String subtitle,
  required String name,
  required String consent,
}) =>
    context.push<Uint8List>(AppRoutes.signaturePad, extra: {
      'title': title,
      'subtitle': subtitle,
      'name': name,
      'consent': consent,
    });

/// Full-screen signature capture (Draw / Type). Pops with the signature as a
/// transparent PNG ([Uint8List]) on Save and with nothing on Cancel.
class SignaturePadScreen extends StatefulWidget {
  /// e.g. "Client signature".
  final String title;

  /// e.g. "Estimate #1006 · $30.30".
  final String subtitle;
  final String initialName;

  /// Legal line under the pad, e.g. "…accepts estimate #1006 and its terms…".
  /// `{name}` is replaced with the signer name as typed.
  final String consentTemplate;

  const SignaturePadScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.initialName,
    required this.consentTemplate,
  });

  @override
  State<SignaturePadScreen> createState() => _SignaturePadScreenState();
}

class _SignaturePadScreenState extends State<SignaturePadScreen> {
  late final TextEditingController _name;
  final _typed = TextEditingController();
  final List<_Stroke> _strokes = [];
  bool _typeMode = false;
  bool _expanded = false;

  /// Size of the inline (portrait) pad — the reference frame for export.
  Size _padSize = const Size(343, 250);
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName)
      ..addListener(() => setState(() {}));
    _typed.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    if (_expanded) _setLandscape(false);
    _name.dispose();
    _typed.dispose();
    super.dispose();
  }

  bool get _canSave =>
      !_saving && (_typeMode ? _typed.text.trim().isNotEmpty : _strokes.isNotEmpty);

  Future<void> _save() async {
    setState(() => _saving = true);
    final png = _typeMode ? await _renderTyped() : await _renderStrokes();
    if (!mounted) return;
    if (png == null) {
      setState(() => _saving = false);
      return;
    }
    context.pop(png);
  }

  Future<Uint8List?> _renderStrokes() async {
    // Map every stroke into the inline pad's frame, then crop to the ink.
    final mapped = [for (final st in _strokes) st.mapTo(_padSize)];
    Rect? bounds;
    for (final pts in mapped) {
      for (final p in pts) {
        final r = Rect.fromLTWH(p.dx, p.dy, 0, 0);
        bounds = bounds == null ? r : bounds.expandToInclude(r);
      }
    }
    if (bounds == null) return null;
    final box = bounds.inflate(10);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)
      ..scale(_kExportScale)
      ..translate(-box.left, -box.top);
    _paintStrokes(canvas, mapped);
    final image = await recorder.endRecording().toImage(
        (box.width * _kExportScale).round(),
        (box.height * _kExportScale).round());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }

  void _setLandscape(bool on) {
    SystemChrome.setPreferredOrientations(on
        ? [
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]
        : [
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
          ]);
  }

  void _toggleExpanded(bool on) {
    _setLandscape(on);
    setState(() => _expanded = on);
  }

  Future<Uint8List?> _renderTyped() async {
    final painter = TextPainter(
      text: TextSpan(text: _typed.text.trim(), style: _typedStyle(48)),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    const pad = 12.0;
    final w = painter.width + pad * 2, h = painter.height + pad * 2;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(_kExportScale);
    painter.paint(canvas, const Offset(pad, pad));
    final image = await recorder
        .endRecording()
        .toImage((w * _kExportScale).round(), (h * _kExportScale).round());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }

  static TextStyle _typedStyle(double size) => TextStyle(
        fontSize: size,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w500,
        color: _kInk,
        fontFamily: 'Manrope',
        fontFamilyFallback: const ['Snell Roundhand', 'cursive'],
      );

  @override
  Widget build(BuildContext context) {
    if (_expanded) return _expandedPad();
    final name = _name.text.trim();
    final consent = widget.consentTemplate
        .replaceAll('{name}', name.isEmpty ? 'the signer' : name);
    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: FormNavBar(
        title: widget.title,
        subtitle: widget.subtitle,
        onLeading: () => context.pop(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => FocusScope.of(context).unfocus(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: _Field(
                            label: 'Signer name',
                            child: TextField(
                              controller: _name,
                              textCapitalization: TextCapitalization.words,
                              style: AppTextStyles.bodyLarge,
                              decoration: _fieldDecoration(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 4,
                          child: _Field(
                            label: 'Date',
                            child: Container(
                              height: 48,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              decoration: _boxDecoration(),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      DateFormat.yMMMd().format(DateTime.now()),
                                      style: AppTextStyles.bodyLarge,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(Icons.calendar_today_outlined,
                                      size: 16, color: AppColors.primary),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _ModeToggle(
                      typeMode: _typeMode,
                      onChanged: (v) => setState(() => _typeMode = v),
                    ),
                    const SizedBox(height: 14),
                    _typeMode ? _typePad() : _drawPad(),
                    const SizedBox(height: 16),
                    Text(consent,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.inkSoft, height: 1.5)),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: AppColors.card,
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _canSave ? _save : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.grayTint,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text('Save signature', style: AppTextStyles.buttonText),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawPad() {
    return Column(
      children: [
        Container(
          height: 250,
          decoration: _boxDecoration(radius: 16),
          child: _padSurface(),
        ),
        const SizedBox(height: 14),
        TextButton.icon(
          onPressed: () => _toggleExpanded(true),
          icon: const Icon(Icons.screen_rotation_outlined,
              size: 18, color: AppColors.primary),
          label: Text('Rotate for a bigger pad',
              style: AppTextStyles.labelLarge
                  .copyWith(color: AppColors.primary)),
        ),
      ],
    );
  }

  /// The ink surface plus its line, hint and undo/clear buttons. Shared by the
  /// inline pad and the landscape one; strokes remember the size they were
  /// drawn on and are scaled to fit whichever pad is showing.
  Widget _padSurface({bool expanded = false}) {
    return LayoutBuilder(builder: (context, c) {
      final size = Size(c.maxWidth, c.maxHeight);
      if (!expanded) _padSize = size;
      return Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: GestureDetector(
                onPanStart: (d) => setState(
                    () => _strokes.add(_Stroke([d.localPosition], size))),
                onPanUpdate: (d) =>
                    setState(() => _strokes.last.points.add(d.localPosition)),
                child: CustomPaint(
                  painter: _PadPainter(_strokes),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 44,
            child: const IgnorePointer(child: _SignLine()),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 14,
            child: IgnorePointer(
              child: Text('Sign above the line',
                  textAlign: TextAlign.center,
                  style:
                      AppTextStyles.caption.copyWith(color: AppColors.inkSoft)),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Row(
              children: [
                _PadButton(
                  icon: Icons.undo,
                  onTap: _strokes.isEmpty
                      ? null
                      : () => setState(_strokes.removeLast),
                ),
                const SizedBox(width: 8),
                _PadButton(
                  label: 'Clear',
                  onTap: _strokes.isEmpty
                      ? null
                      : () => setState(_strokes.clear),
                ),
                if (expanded) ...[
                  const SizedBox(width: 8),
                  _PadButton(
                    label: 'Done',
                    onTap: () => _toggleExpanded(false),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _expandedPad() {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _toggleExpanded(false);
      },
      child: Scaffold(
        backgroundColor: AppColors.page,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              decoration: _boxDecoration(radius: 16),
              child: _padSurface(expanded: true),
            ),
          ),
        ),
      ),
    );
  }

  Widget _typePad() {
    return Container(
      height: 250,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
      decoration: _boxDecoration(radius: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextField(
            controller: _typed,
            textAlign: TextAlign.center,
            style: _typedStyle(38),
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Type your name',
            ),
          ),
          const _SignLine(),
          const SizedBox(height: 10),
          Text('Type your signature above the line',
              style: AppTextStyles.caption.copyWith(color: AppColors.inkSoft)),
        ],
      ),
    );
  }

  static BoxDecoration _boxDecoration({double radius = 12}) => BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(radius),
      );

  static InputDecoration _fieldDecoration() => InputDecoration(
        isDense: false,
        filled: true,
        fillColor: AppColors.card,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      );
}

class _Field extends StatelessWidget {
  final String label;
  final Widget child;
  const _Field({required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.labelMedium
                  .copyWith(color: AppColors.inkSoft)),
          const SizedBox(height: 6),
          child,
        ],
      );
}

class _ModeToggle extends StatelessWidget {
  final bool typeMode;
  final ValueChanged<bool> onChanged;
  const _ModeToggle({required this.typeMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget seg(String label, bool selected, VoidCallback onTap) => Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.card : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(
                    color: selected ? AppColors.primary : AppColors.inkSoft),
              ),
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.grayTint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        seg('Draw', !typeMode, () => onChanged(false)),
        seg('Type', typeMode, () => onChanged(true)),
      ]),
    );
  }
}

class _PadButton extends StatelessWidget {
  final IconData? icon;
  final String? label;
  final VoidCallback? onTap;
  const _PadButton({this.icon, this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = onTap == null ? AppColors.inkFaint : AppColors.ink;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        constraints: const BoxConstraints(minWidth: 36),
        padding: EdgeInsets.symmetric(horizontal: label != null ? 14 : 0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(18),
        ),
        child: icon != null
            ? Icon(icon, size: 18, color: color)
            : Text(label!,
                style: AppTextStyles.labelMedium.copyWith(color: color)),
      ),
    );
  }
}

class _SignLine extends StatelessWidget {
  const _SignLine();

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 6, bottom: 2),
            child: Text('×',
                style: TextStyle(fontSize: 16, color: AppColors.inkFaint)),
          ),
          Expanded(
              child: Container(height: 1, color: AppColors.inkFaint)),
        ],
      );
}

class _PadPainter extends CustomPainter {
  final List<_Stroke> strokes;
  _PadPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) =>
      _paintStrokes(canvas, [for (final s in strokes) s.mapTo(size)]);

  // The strokes list is mutated in place, so always repaint.
  @override
  bool shouldRepaint(covariant _PadPainter old) => true;
}

/// A stroke in the coordinates of the pad it was drawn on.
class _Stroke {
  final List<Offset> points;
  final Size origin;
  _Stroke(this.points, this.origin);

  /// Points scaled uniformly (and centered) to fit [target].
  List<Offset> mapTo(Size target) {
    if (origin.isEmpty || target == origin) return points;
    final k = target.width / origin.width < target.height / origin.height
        ? target.width / origin.width
        : target.height / origin.height;
    final dx = (target.width - origin.width * k) / 2;
    final dy = (target.height - origin.height * k) / 2;
    return [for (final p in points) Offset(p.dx * k + dx, p.dy * k + dy)];
  }
}

void _paintStrokes(Canvas canvas, List<List<Offset>> strokes) {
  final paint = Paint()
    ..color = _kInk
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.6
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;
  for (final s in strokes) {
    if (s.length == 1) {
      canvas.drawCircle(s.first, 1.3, paint..style = PaintingStyle.fill);
      paint.style = PaintingStyle.stroke;
      continue;
    }
    final path = Path()..moveTo(s.first.dx, s.first.dy);
    for (var i = 1; i < s.length - 1; i++) {
      final mid = (s[i] + s[i + 1]) / 2;
      path.quadraticBezierTo(s[i].dx, s[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(s.last.dx, s.last.dy);
    canvas.drawPath(path, paint);
  }
}
