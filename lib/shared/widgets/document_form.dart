import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/form_nav_bar.dart';
import '../../core/widgets/loading_overlay.dart';

/// Editable line item on the new estimate / invoice form.
class LineItemDraft {
  String name;
  int qty;
  double price;

  LineItemDraft({this.name = '', this.qty = 1, this.price = 0});

  double get total => qty * price;
}

/// Shared "New estimate" / "New invoice" form. The two designs are
/// identical except for the document-details block and a couple of
/// payment toggles, switched by [isInvoice].
class DocumentForm extends StatefulWidget {
  final bool isInvoice;
  final int documentNumber;

  const DocumentForm({
    super.key,
    required this.isInvoice,
    required this.documentNumber,
  });

  @override
  State<DocumentForm> createState() => _DocumentFormState();
}

class _DocumentFormState extends State<DocumentForm> {
  final List<LineItemDraft> _items = [LineItemDraft()];
  final Set<String> _openBlocks = {};

  // Optional adjustment rows (visible after tapping a chip).
  final Set<String> _activeAdjustments = {};
  double _discount = 0;
  double _markup = 0;
  double _taxPct = 0;
  double _depositPct = 25;

  bool _groupSections = false;
  bool _paypalEnabled = true;
  bool _coverFee = false;
  bool _autoInvoice = false;
  bool _financing = true;
  bool _clientSignature = true;
  bool _mySignature = false;
  bool _allowExpire = false;
  int _validDays = 30;
  String _paymentTerms = 'Due on receipt';

  String get _docWord => widget.isInvoice ? 'invoice' : 'estimate';

  double get _subtotal =>
      _items.fold(0, (sum, item) => sum + item.total);

  double get _total {
    final discount = _activeAdjustments.contains('discount') ? _discount : 0;
    final markup = _activeAdjustments.contains('markup') ? _markup : 0;
    final taxPct = _activeAdjustments.contains('tax') ? _taxPct : 0;
    final base = (_subtotal - discount + markup).clamp(0, double.infinity);
    return base * (1 + taxPct / 100);
  }

  String get _footerLabel {
    if (_activeAdjustments.contains('deposit') && _depositPct > 0) {
      final deposit = _total * _depositPct / 100;
      return 'Total (USD) · ${Formatters.currency(deposit)} deposit due';
    }
    return 'Total (USD)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FormNavBar(
        title: widget.isInvoice ? 'New invoice' : 'New estimate',
        subtitle: '#${widget.documentNumber} · Draft saved',
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
              children: [
                const SectionHeader(
                    title: 'Client',
                    padding: EdgeInsets.fromLTRB(4, 2, 4, 8)),
                AppCard(
                  child: _AddRow(
                    icon: Icons.person_outline,
                    label: 'Add client',
                    showChevron: true,
                    onTap: () {},
                  ),
                ),
                const SectionHeader(title: 'Line items'),
                _lineItemsCard(),
                _adjustChips(),
                const SizedBox(height: 12),
                _totalsCard(),
                const SectionHeader(title: 'More options'),
                _moreOptionsCard(),
              ],
            ),
          ),
          _footer(),
        ],
      ),
    );
  }

  // ---- Line items -----------------------------------------------------

  Widget _lineItemsCard() {
    return AppCard(
      child: Column(
        children: [
          if (_groupSections)
            Container(
              color: AppColors.page,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: TextField(
                style: AppTextStyles.labelMedium.copyWith(fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Section name — e.g. Kitchen remodel',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 9),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: const BorderSide(color: AppColors.inkFaint),
                  ),
                ),
              ),
            ),
          for (var i = 0; i < _items.length; i++) _lineItemRow(i),
          _AddRow(
            icon: Icons.add,
            label: 'Add line item',
            showBottomBorder: true,
            onTap: () => setState(() => _items.add(LineItemDraft())),
          ),
          _InnerToggleRow(
            title: 'Group items into sections',
            pill: const PlanPill.elite(),
            subtitle: 'Organize big jobs into labeled phases.',
            value: _groupSections,
            onChanged: (v) => setState(() => _groupSections = v),
          ),
        ],
      ),
    );
  }

  Widget _lineItemRow(int index) {
    final item = _items[index];
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  initialValue: item.name,
                  onChanged: (v) => item.name = v,
                  style: AppTextStyles.rowTitle.copyWith(fontSize: 14.5),
                  decoration: const InputDecoration(
                    hintText: 'Item or service name',
                    isDense: true,
                    filled: false,
                    contentPadding: EdgeInsets.symmetric(vertical: 2),
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _numField(
                      initial: item.qty.toString(),
                      onChanged: (v) => setState(
                          () => item.qty = int.tryParse(v)?.abs() ?? 0),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Text('×', style: AppTextStyles.caption),
                    ),
                    _numField(
                      initial: item.price == 0 ? '0' : item.price.toString(),
                      onChanged: (v) => setState(
                          () => item.price = double.tryParse(v)?.abs() ?? 0),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(Formatters.currency(item.total),
                  style: AppTextStyles.rowAmount.copyWith(fontSize: 14.5)),
              const SizedBox(height: 4),
              InkWell(
                onTap: () => setState(() => _items.removeAt(index)),
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.delete_outline,
                      size: 16, color: AppColors.inkFaint),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _numField({
    required String initial,
    required ValueChanged<String> onChanged,
  }) {
    return SizedBox(
      width: 64,
      child: TextFormField(
        initialValue: initial,
        onChanged: onChanged,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: AppTextStyles.bodySmall,
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: AppColors.page,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.greenDeep),
          ),
        ),
      ),
    );
  }

  // ---- Adjustments ----------------------------------------------------

  static const _adjustments = [
    ('discount', 'Discount'),
    ('tax', 'Tax'),
    ('markup', 'Markup'),
    ('deposit', 'Request deposit'),
    ('schedule', 'Payment schedule'),
  ];

  Widget _adjustChips() {
    final available =
        _adjustments.where((a) => !_activeAdjustments.contains(a.$1));
    if (available.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final adj in available)
            _ChipButton(
              label: adj.$2,
              onTap: () => setState(() => _activeAdjustments.add(adj.$1)),
            ),
        ],
      ),
    );
  }

  Widget _totalsCard() {
    return AppCard(
      child: Column(
        children: [
          _totalRow(
            'Subtotal',
            value: Text(Formatters.currency(_subtotal),
                style: AppTextStyles.labelMedium.copyWith(fontSize: 14)),
            showDivider: _activeAdjustments.isNotEmpty,
          ),
          if (_activeAdjustments.contains('discount'))
            _adjustInputRow(
              'Discount',
              key: 'discount',
              prefix: '−\$',
              initial: _discount,
              onChanged: (v) => _discount = v,
            ),
          if (_activeAdjustments.contains('markup'))
            _adjustInputRow(
              'Markup',
              key: 'markup',
              prefix: '+\$',
              initial: _markup,
              onChanged: (v) => _markup = v,
            ),
          if (_activeAdjustments.contains('tax'))
            _adjustInputRow(
              'Tax',
              key: 'tax',
              suffix: '%',
              initial: _taxPct,
              onChanged: (v) => _taxPct = v,
            ),
          if (_activeAdjustments.contains('deposit'))
            _adjustInputRow(
              'Deposit due upfront',
              key: 'deposit',
              suffix: '%',
              initial: _depositPct,
              onChanged: (v) => _depositPct = v.clamp(0, 100),
            ),
          if (_activeAdjustments.contains('schedule'))
            _totalRow(
              'Payment schedule',
              value: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('50% start · 50% done',
                      style:
                          AppTextStyles.labelMedium.copyWith(fontSize: 13)),
                  _removeAdjustment('schedule'),
                ],
              ),
              showDivider: false,
            ),
        ],
      ),
    );
  }

  Widget _totalRow(String label,
      {required Widget value, bool showDivider = true}) {
    return Container(
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.line))
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.inkSoft, height: 1.2)),
          value,
        ],
      ),
    );
  }

  Widget _adjustInputRow(
    String label, {
    required String key,
    required double initial,
    required ValueChanged<double> onChanged,
    String? prefix,
    String? suffix,
  }) {
    final isLast = key == _activeAdjustments.last;
    return _totalRow(
      label,
      showDivider: !isLast,
      value: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (prefix != null)
            Text(prefix, style: AppTextStyles.labelMedium),
          const SizedBox(width: 6),
          SizedBox(
            width: 72,
            child: TextFormField(
              initialValue:
                  initial == initial.roundToDouble() && initial != 0
                      ? initial.toInt().toString()
                      : (initial == 0 ? '0' : initial.toString()),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              style: AppTextStyles.labelMedium.copyWith(fontSize: 13.5),
              onChanged: (v) =>
                  setState(() => onChanged(double.tryParse(v)?.abs() ?? 0)),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: AppColors.page,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.greenDeep),
                ),
              ),
            ),
          ),
          if (suffix != null) ...[
            const SizedBox(width: 4),
            Text(suffix, style: AppTextStyles.labelMedium),
          ],
          _removeAdjustment(key),
        ],
      ),
    );
  }

  Widget _removeAdjustment(String key) {
    return InkWell(
      onTap: () => setState(() => _activeAdjustments.remove(key)),
      borderRadius: BorderRadius.circular(6),
      child: const Padding(
        padding: EdgeInsets.all(4),
        child: Icon(Icons.close, size: 13, color: AppColors.inkFaint),
      ),
    );
  }

  // ---- More options ---------------------------------------------------

  Widget _moreOptionsCard() {
    final dateLabel = Formatters.dateMedium(DateTime.now());
    final expireLabel =
        _allowExpire ? 'Valid $_validDays days' : 'No expiration';
    final docSub = widget.isInvoice
        ? '#${widget.documentNumber} · $dateLabel · $_paymentTerms'
        : '#${widget.documentNumber} · $dateLabel · $expireLabel';

    return AppCard(
      child: Column(
        children: [
          _ExpandableBlock(
            id: 'payments',
            icon: Icons.credit_card_outlined,
            warn: true,
            title: 'Online payments',
            subtitle: 'Finish payout setup to get paid online',
            open: _openBlocks.contains('payments'),
            onToggle: _toggleBlock,
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Material(
                    color: AppColors.orangeTint,
                    borderRadius: BorderRadius.circular(11),
                    child: InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(11),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 13, vertical: 11),
                        child: Row(
                          children: const [
                            Icon(Icons.error_outline,
                                size: 16, color: AppColors.orangeDeep),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Additional information required — takes about 2 minutes',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.orangeDeep,
                                ),
                              ),
                            ),
                            Icon(Icons.chevron_right,
                                size: 16, color: AppColors.orangeDeep),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                _InnerToggleRow(
                  title: 'PayPal',
                  subtitle:
                      'Credit and debit cards, Apple Pay, Google Pay, PayPal, and Venmo.',
                  value: _paypalEnabled,
                  onChanged: (v) => setState(() => _paypalEnabled = v),
                ),
                _InnerToggleRow(
                  title: 'Cover processing fee',
                  subtitle:
                      "Adds a markup that covers your fee. Clients don't see this.",
                  value: _coverFee,
                  onChanged: (v) => setState(() => _coverFee = v),
                ),
                if (!widget.isInvoice) ...[
                  _InnerToggleRow(
                    title: 'Auto-generate invoice',
                    pill: const PlanPill.newFeature(),
                    subtitle:
                        'Sends the client an invoice automatically the moment they approve.',
                    value: _autoInvoice,
                    onChanged: (v) => setState(() => _autoInvoice = v),
                  ),
                  _InnerToggleRow(
                    title: 'Show financing options',
                    subtitle:
                        'Lets clients see monthly payment plans — helps close bigger jobs.',
                    value: _financing,
                    onChanged: (v) => setState(() => _financing = v),
                  ),
                ],
              ],
            ),
          ),
          _ExpandableBlock(
            id: 'attachments',
            icon: Icons.attachment,
            title: 'Photos and attachments',
            pill: const PlanPill.pro(),
            subtitle: 'None added',
            open: _openBlocks.contains('attachments'),
            onToggle: _toggleBlock,
            body: Column(
              children: [
                _InnerValueRow(label: 'Photos', value: '0', onTap: () {}),
                _InnerValueRow(label: 'Files', value: '0', onTap: () {}),
              ],
            ),
          ),
          _ExpandableBlock(
            id: 'contract',
            icon: Icons.history_edu_outlined,
            title: 'Contract and signatures',
            subtitle: 'Generic contract · client signs',
            open: _openBlocks.contains('contract'),
            onToggle: _toggleBlock,
            body: Column(
              children: [
                _InnerValueRow(
                  label: 'Contract',
                  pill: const PlanPill.pro(),
                  value: 'Generic contract',
                  onTap: () {},
                ),
                _InnerToggleRow(
                  title: 'Client signature',
                  value: _clientSignature,
                  onChanged: (v) => setState(() => _clientSignature = v),
                ),
                _InnerToggleRow(
                  title: 'My signature',
                  value: _mySignature,
                  onChanged: (v) => setState(() => _mySignature = v),
                ),
              ],
            ),
          ),
          _ExpandableBlock(
            id: 'notes',
            icon: Icons.chat_bubble_outline,
            title: 'Notes',
            subtitle: 'None added',
            open: _openBlocks.contains('notes'),
            onToggle: _toggleBlock,
            body: Column(
              children: [
                _InnerValueRow(
                    label: 'Notes for client', value: 'Add', onTap: () {}),
                _InnerValueRow(
                  label: 'Private notes',
                  pill: const PlanPill.pro(),
                  value: 'Add',
                  onTap: () {},
                ),
              ],
            ),
          ),
          _ExpandableBlock(
            id: 'details',
            icon: Icons.list_alt_outlined,
            title: 'Document details',
            subtitle: docSub,
            showDivider: false,
            open: _openBlocks.contains('details'),
            onToggle: _toggleBlock,
            body: Column(
              children: [
                _InnerValueRow(
                  label:
                      widget.isInvoice ? 'Invoice number' : 'Estimate number',
                  value: '#${widget.documentNumber}',
                  onTap: () {},
                ),
                _InnerValueRow(label: 'Date', value: dateLabel, onTap: () {}),
                if (widget.isInvoice)
                  _InnerValueRow(
                    label: 'Payment terms',
                    value: _paymentTerms,
                    onTap: _pickPaymentTerms,
                  )
                else ...[
                  _InnerToggleRow(
                    title: 'Allow document to expire',
                    pill: const PlanPill.newFeature(),
                    subtitle:
                        'Locks the price until the expiry date — a gentle nudge to approve.',
                    value: _allowExpire,
                    onChanged: (v) => setState(() => _allowExpire = v),
                  ),
                  if (_allowExpire)
                    _InnerValueRow(
                      label: 'Valid for',
                      value: '$_validDays days',
                      onTap: _pickValidDays,
                    ),
                ],
                _InnerValueRow(
                    label: 'PO number', value: 'Optional', onTap: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleBlock(String id) {
    setState(() {
      _openBlocks.contains(id) ? _openBlocks.remove(id) : _openBlocks.add(id);
    });
  }

  Future<void> _pickPaymentTerms() async {
    const options = ['Due on receipt', 'Net 15', 'Net 30', 'Net 60'];
    final choice = await _showOptions('Payment terms', options, _paymentTerms);
    if (choice != null) setState(() => _paymentTerms = choice);
  }

  Future<void> _pickValidDays() async {
    final choice = await _showOptions(
        'Valid for', ['14 days', '30 days', '60 days'], '$_validDays days');
    if (choice != null) {
      setState(() => _validDays = int.parse(choice.split(' ').first));
    }
  }

  Future<String?> _showOptions(
      String title, List<String> options, String selected) {
    return showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.grabber,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(title,
                style: AppTextStyles.headingSmall.copyWith(fontSize: 17)),
            const SizedBox(height: 6),
            for (final option in options)
              ListTile(
                title: Text(option, style: AppTextStyles.rowTitle),
                trailing: option == selected
                    ? const Icon(Icons.check, color: AppColors.greenDeep)
                    : null,
                onTap: () => Navigator.of(context).pop(option),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ---- Footer ---------------------------------------------------------

  Widget _footer() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _footerLabel,
                      style: AppTextStyles.caption
                          .copyWith(fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      Formatters.currency(_total),
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Sending ${_docWord}s will be wired to the API.')),
                  );
                  context.pop();
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 14),
                  textStyle: AppTextStyles.buttonText.copyWith(fontSize: 15),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('Preview and send'),
                    SizedBox(width: 7),
                    Icon(Icons.arrow_forward, size: 15),
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

// ---- Small pieces ------------------------------------------------------

/// PRO / ELITE / NEW plan pill shown next to gated features.
class PlanPill extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const PlanPill.pro({super.key})
      : label = 'PRO',
        background = AppColors.greenTint,
        foreground = AppColors.greenDeep;

  const PlanPill.elite({super.key})
      : label = 'ELITE',
        background = AppColors.orangeTint,
        foreground = AppColors.orangeDeep;

  const PlanPill.newFeature({super.key})
      : label = 'NEW',
        background = AppColors.greenDeep,
        foreground = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: foreground,
        ),
      ),
    );
  }
}

class _AddRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool showChevron;
  final bool showBottomBorder;
  final VoidCallback onTap;

  const _AddRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.showChevron = false,
    this.showBottomBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: showBottomBorder
              ? const Border(bottom: BorderSide(color: AppColors.line))
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.greenTint,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 16, color: AppColors.greenDeep),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(label,
                  style: AppTextStyles.rowTitle.copyWith(fontSize: 14.5)),
            ),
            if (showChevron)
              const Icon(Icons.chevron_right,
                  size: 18, color: AppColors.inkFaint),
          ],
        ),
      ),
    );
  }
}

class _ChipButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ChipButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: StadiumBorder(
        side: const BorderSide(color: AppColors.line),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, size: 13, color: AppColors.inkSoft),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTextStyles.bodySmall
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpandableBlock extends StatelessWidget {
  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget body;
  final bool open;
  final bool warn;
  final bool showDivider;
  final PlanPill? pill;
  final ValueChanged<String> onToggle;

  const _ExpandableBlock({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.open,
    required this.onToggle,
    this.warn = false,
    this.showDivider = true,
    this.pill,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: showDivider || open
            ? const Border(bottom: BorderSide(color: AppColors.line))
            : null,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => onToggle(id),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: warn ? AppColors.orangeTint : AppColors.grayTint,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      icon,
                      size: 16,
                      color:
                          warn ? AppColors.orangeDeep : AppColors.inkSoft,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(title,
                                  style: AppTextStyles.rowTitle
                                      .copyWith(fontSize: 14)),
                            ),
                            if (pill != null) pill!,
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 12,
                            fontWeight:
                                warn ? FontWeight.w600 : FontWeight.w500,
                            color: warn
                                ? AppColors.orangeDeep
                                : AppColors.inkFaint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: open ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.chevron_right,
                        size: 18, color: AppColors.inkFaint),
                  ),
                ],
              ),
            ),
          ),
          if (open)
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.rowHover,
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: body,
            ),
        ],
      ),
    );
  }
}

class _InnerToggleRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final PlanPill? pill;
  final ValueChanged<bool> onChanged;

  const _InnerToggleRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.pill,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(title,
                          style:
                              AppTextStyles.rowTitle.copyWith(fontSize: 14)),
                    ),
                    if (pill != null) pill!,
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTextStyles.caption
                        .copyWith(fontSize: 12, height: 1.45),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _InnerValueRow extends StatelessWidget {
  final String label;
  final String value;
  final PlanPill? pill;
  final VoidCallback onTap;

  const _InnerValueRow({
    required this.label,
    required this.value,
    required this.onTap,
    this.pill,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(label,
                        style: AppTextStyles.labelMedium
                            .copyWith(fontSize: 13.5)),
                  ),
                  if (pill != null) pill!,
                ],
              ),
            ),
            Text(
              value,
              style: AppTextStyles.labelMedium.copyWith(
                fontSize: 13.5,
                color: AppColors.inkFaint,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right,
                size: 15, color: AppColors.inkFaint),
          ],
        ),
      ),
    );
  }
}
