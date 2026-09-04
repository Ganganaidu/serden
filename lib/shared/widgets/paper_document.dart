import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Letter-size layout constants for the "Desktop" document preview.
const double kPaperWidth = 816;
const double kPaperHeight = 1056;

/// Serif-free document font stack (distinct from the app's Manrope).
const List<String> _docFontFallback = ['Helvetica Neue', 'Roboto', 'Arial'];

TextStyle docStyle({
  double size = 13.5,
  FontWeight weight = FontWeight.w400,
  Color color = AppColors.docSoft,
  double height = 1.65,
  double letterSpacing = 0,
}) =>
    TextStyle(
      fontFamilyFallback: _docFontFallback,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );

/// One page of the estimate/invoice document.
/// Desktop mode renders at real letter width scaled down to fit;
/// mobile mode reflows the same content at natural width.
/// [footer] (the "Page x of y" note) is pinned to the bottom edge
/// of the letter page in desktop mode.
class PaperPage extends StatelessWidget {
  final bool mobile;
  final Widget child;
  final Widget? footer;

  const PaperPage({
    super.key,
    required this.mobile,
    required this.child,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.line),
      borderRadius: BorderRadius.circular(mobile ? 14 : 6),
      boxShadow: const [
        BoxShadow(
          color: Color(0x14000000),
          blurRadius: 12,
          offset: Offset(0, 2),
        ),
      ],
    );

    if (mobile) {
      return Container(
        width: double.infinity,
        decoration: decoration,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [child, if (footer != null) footer!],
        ),
      );
    }

    // Letter width, min letter height; grows if content runs long
    // (real pagination happens in the PDF renderer later).
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: decoration,
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Container(
          width: kPaperWidth,
          constraints: const BoxConstraints(minHeight: kPaperHeight),
          padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 58),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [child, if (footer != null) footer!],
          ),
        ),
      ),
    );
  }
}

/// Faded "ESTIMATE" / "INVOICE" watermark centered at the top (desktop only).
class DocWatermark extends StatelessWidget {
  final String text;
  const DocWatermark(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Text(
          text,
          style: docStyle(
            size: 15,
            weight: FontWeight.w600,
            color: const Color(0xFFC7CAC7),
            letterSpacing: 2.4,
            height: 1,
          ),
        ),
      ),
    );
  }
}

/// Company logo block. Shows the pro's uploaded logo when [logoUrl] is set;
/// otherwise a lettermark box + company name (falls back to the Serden
/// wordmark when no [companyName] is given, for the not-yet-wired invoice
/// preview).
class DocLogoBlock extends StatelessWidget {
  final bool mobile;
  final String? logoUrl;
  final String? companyName;

  const DocLogoBlock({
    super.key,
    required this.mobile,
    this.logoUrl,
    this.companyName,
  });

  @override
  Widget build(BuildContext context) {
    final markSize = mobile ? 52.0 : 66.0;

    if (logoUrl != null && logoUrl!.isNotEmpty) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: markSize + 20,
          maxWidth: mobile ? 200 : 240,
        ),
        child: Image.network(
          logoUrl!,
          alignment: Alignment.centerLeft,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _lettermark(markSize),
        ),
      );
    }
    return _lettermark(markSize);
  }

  Widget _lettermark(double markSize) {
    final name = (companyName ?? '').trim();
    final letter = name.isNotEmpty ? name[0].toUpperCase() : 'S';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: markSize,
          height: markSize,
          alignment: Alignment.center,
          color: AppColors.docNavy,
          child: Text(
            letter,
            style: docStyle(
              size: markSize * 0.62,
              weight: FontWeight.w700,
              color: Colors.white,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 6),
        if (name.isEmpty) ...[
          Text(
            'SERDEN',
            style: docStyle(
              size: 19,
              weight: FontWeight.w700,
              color: AppColors.docNavy,
              letterSpacing: 0.8,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'GROUP',
            style: docStyle(
              size: 9.5,
              weight: FontWeight.w700,
              color: AppColors.docNavy,
              letterSpacing: 4,
              height: 1,
            ),
          ),
        ] else
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: mobile ? 200 : 240),
            child: Text(
              name,
              style: docStyle(
                size: mobile ? 16 : 15,
                weight: FontWeight.w700,
                color: AppColors.docNavy,
                letterSpacing: 0.4,
                height: 1.2,
              ),
            ),
          ),
      ],
    );
  }
}

/// "Prepared For" / "Bill To" block.
class DocPreparedBlock extends StatelessWidget {
  final bool mobile;
  final String label;
  final String detail;

  const DocPreparedBlock({
    super.key,
    required this.mobile,
    required this.label,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          mobile ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: docStyle(
            size: mobile ? 15 : 14,
            weight: FontWeight.w700,
            color: AppColors.docInk,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          detail,
          textAlign: mobile ? TextAlign.left : TextAlign.right,
          style: docStyle(size: mobile ? 15 : 13.5, height: 1.65),
        ),
      ],
    );
  }
}

class DocCompanyBlock extends StatelessWidget {
  final bool mobile;
  final String? name;
  final String? details;

  const DocCompanyBlock({
    super.key,
    required this.mobile,
    this.name,
    this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          (name ?? '').trim().isNotEmpty ? name!.trim() : 'Serden Group LLC',
          style: docStyle(
            size: mobile ? 15.5 : 13.5,
            weight: FontWeight.w700,
            color: AppColors.docInk,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          (details ?? '').trim().isNotEmpty
              ? details!.trim()
              : '1104 Main St, Ste 610\n'
                  'Vancouver, WA 98660\n'
                  'Phone: (360) 836-7775\n'
                  'Email: serdengroup@gmail.com',
          style: docStyle(size: mobile ? 15 : 13.5, height: 1.7),
        ),
      ],
    );
  }
}

class DocMetaRow extends StatelessWidget {
  final String label;
  final String value;

  const DocMetaRow(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: docStyle(height: 1.3)),
          Text(
            value,
            style: docStyle(color: AppColors.docInk, height: 1.3),
          ),
        ],
      ),
    );
  }
}

/// "Description" label with the heavy underline.
class DocDescriptionLabel extends StatelessWidget {
  final bool mobile;
  const DocDescriptionLabel({super.key, required this.mobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: mobile ? 26 : 34),
      padding: const EdgeInsets.only(bottom: 9),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.docInk)),
      ),
      child: Text(
        'Description',
        style: docStyle(
          size: mobile ? 17 : 14,
          weight: FontWeight.w700,
          color: AppColors.docInk,
          height: 1.2,
        ),
      ),
    );
  }
}

/// Grey section header row ("Bathroom — $10,600.00") plus bordered body.
class DocSection extends StatelessWidget {
  final bool mobile;
  final String title;
  final String amount;
  final List<Widget> body;
  final double topMargin;

  const DocSection({
    super.key,
    required this.mobile,
    required this.title,
    required this.amount,
    required this.body,
    this.topMargin = 14,
  });

  @override
  Widget build(BuildContext context) {
    final headRadius = mobile
        ? const BorderRadius.vertical(top: Radius.circular(10))
        : BorderRadius.zero;
    final bodyRadius = mobile
        ? const BorderRadius.vertical(bottom: Radius.circular(10))
        : BorderRadius.zero;
    final headStyle = docStyle(
      size: mobile ? 15.5 : 14,
      weight: FontWeight.w700,
      color: AppColors.docInk,
      height: 1.3,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          margin: EdgeInsets.only(top: topMargin),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: AppColors.docSectionBg,
            borderRadius: headRadius,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(title, style: headStyle)),
              const SizedBox(width: 10),
              Text(amount, style: headStyle),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 15, 14, 17),
          decoration: BoxDecoration(
            border: const Border(
              left: BorderSide(color: AppColors.docLine),
              right: BorderSide(color: AppColors.docLine),
              bottom: BorderSide(color: AppColors.docLine),
            ),
            borderRadius: bodyRadius,
          ),
          child: DefaultTextStyle.merge(
            style: docStyle(size: mobile ? 15 : 13.5, height: 1.7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: body,
            ),
          ),
        ),
      ],
    );
  }
}

class DocTotalRow extends StatelessWidget {
  final bool mobile;
  final String label;
  final String value;
  final bool underlined;
  final bool boldValue;

  const DocTotalRow({
    super.key,
    required this.mobile,
    required this.label,
    required this.value,
    this.underlined = false,
    this.boldValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: underlined
          ? const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.docInk, width: 1.5),
              ),
            )
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: docStyle(
              size: mobile ? 15.5 : 14,
              weight: FontWeight.w700,
              color: AppColors.docInk,
              height: 1.3,
            ),
          ),
          Text(
            value,
            style: docStyle(
              size: mobile ? 15.5 : 14,
              weight: boldValue ? FontWeight.w700 : FontWeight.w400,
              color: AppColors.docInk,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class DocPageNote extends StatelessWidget {
  final String text;
  const DocPageNote(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 30),
        child: Text(
          text,
          style: docStyle(
            size: 11,
            color: const Color(0xFFAEAEB2),
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

class DocTermsTitle extends StatelessWidget {
  final bool mobile;
  final String text;
  final double topMargin;

  const DocTermsTitle(this.text,
      {super.key, required this.mobile, this.topMargin = 22});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topMargin, bottom: 9),
      child: Text(
        text,
        style: docStyle(
          size: mobile ? 16 : 15,
          weight: FontWeight.w700,
          color: AppColors.docInk,
          height: 1.2,
        ),
      ),
    );
  }
}

class DocParagraph extends StatelessWidget {
  final bool mobile;
  final String text;

  const DocParagraph(this.text, {super.key, required this.mobile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: docStyle(size: mobile ? 15 : 13.5, height: 1.75),
      ),
    );
  }
}

class DocSignatureLine extends StatelessWidget {
  final String label;
  const DocSignatureLine({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 52,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.docInk, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(label, style: docStyle(size: 12.5, height: 1.3)),
      ],
    );
  }
}

/// Notes card under the document pages.
class DocNotesCard extends StatelessWidget {
  final String text;
  const DocNotesCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 1, color: AppColors.docLine),
          const SizedBox(height: 16),
          Text(
            'Notes:',
            style: docStyle(
              size: 13,
              weight: FontWeight.w700,
              color: AppColors.docInk,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(text, style: docStyle(size: 12.5, height: 1.7)),
        ],
      ),
    );
  }
}

// ---- Detail chrome (toolbar, status band, view toggle) -----------------

class ToolbarAction {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const ToolbarAction(this.icon, this.label, {this.onTap});
}

/// Row of uppercase tool buttons under the detail header.
class DocumentToolbar extends StatelessWidget {
  final List<ToolbarAction> actions;

  const DocumentToolbar({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < actions.length; i++)
            Expanded(
              child: InkWell(
                onTap: actions[i].onTap,
                child: Container(
                  decoration: BoxDecoration(
                    border: i < actions.length - 1
                        ? const Border(
                            right: BorderSide(color: AppColors.line))
                        : null,
                  ),
                  padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
                  child: Column(
                    children: [
                      Icon(actions[i].icon,
                          size: 19, color: AppColors.inkSoft),
                      const SizedBox(height: 5),
                      Text(
                        actions[i].label.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum StatusBandKind { pending, positive, negative }

class StatusBandOption {
  final String key;

  /// Label on the band ("Unpaid · Due upon receipt").
  final String bandLabel;

  /// Label in the picker menu ("Mark as paid").
  final String menuLabel;
  final StatusBandKind kind;

  const StatusBandOption({
    required this.key,
    required this.bandLabel,
    required this.menuLabel,
    required this.kind,
  });
}

/// Full-width tinted status band with a bottom-sheet status picker.
class StatusBand extends StatelessWidget {
  final List<StatusBandOption> options;
  final String currentKey;
  final ValueChanged<String> onChanged;

  const StatusBand({
    super.key,
    required this.options,
    required this.currentKey,
    required this.onChanged,
  });

  StatusBandOption get _current =>
      options.firstWhere((o) => o.key == currentKey);

  (Color, Color) _colors(StatusBandKind kind) => switch (kind) {
        StatusBandKind.pending => (AppColors.orangeTint, AppColors.orangeDeep),
        StatusBandKind.positive => (AppColors.greenTint, AppColors.greenDeep),
        StatusBandKind.negative => (AppColors.redTint, AppColors.redDeep),
      };

  Color _dotColor(StatusBandKind kind) => switch (kind) {
        StatusBandKind.pending => AppColors.orange500,
        StatusBandKind.positive => AppColors.greenDeep,
        StatusBandKind.negative => AppColors.redDeep,
      };

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors(_current.kind);
    return Material(
      color: bg,
      child: InkWell(
        onTap: () => _showPicker(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _current.bandLabel.toUpperCase(),
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: fg,
                ),
              ),
              const SizedBox(width: 7),
              Icon(Icons.keyboard_arrow_down, size: 16, color: fg),
            ],
          ),
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.grabber,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            for (final option in options)
              ListTile(
                leading: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: _dotColor(option.kind),
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(option.menuLabel,
                    style: AppTextStyles.labelMedium.copyWith(fontSize: 14)),
                trailing: option.key == currentKey
                    ? const Icon(Icons.check,
                        size: 18, color: AppColors.greenDeep)
                    : null,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onChanged(option.key);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Desktop / Mobile segmented toggle for the document preview.
class ViewToggle extends StatelessWidget {
  final bool mobileMode;
  final ValueChanged<bool> onChanged;

  const ViewToggle({
    super.key,
    required this.mobileMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.grayTint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _segment('Desktop', !mobileMode, () => onChanged(false)),
          const SizedBox(width: 3),
          _segment('Mobile', mobileMode, () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _segment(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: active ? AppColors.card : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        elevation: active ? 1 : 0,
        shadowColor: Colors.black26,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: active ? AppColors.ink : AppColors.inkSoft,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
