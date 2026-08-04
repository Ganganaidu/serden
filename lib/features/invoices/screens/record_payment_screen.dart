import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/form_nav_bar.dart';
import '../../../core/widgets/loading_overlay.dart';

class _Payment {
  final double amount;
  final String method;
  final String date;
  final String note;

  const _Payment({
    required this.amount,
    required this.method,
    required this.date,
    required this.note,
  });
}

/// Record payment form for an invoice, with balance summary
/// and payment history (serden-record-payment design).
class RecordPaymentScreen extends StatefulWidget {
  final String invoiceId;
  const RecordPaymentScreen({super.key, required this.invoiceId});

  @override
  State<RecordPaymentScreen> createState() => _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends State<RecordPaymentScreen> {
  static const _total = 2500.0;
  static const _methods = [
    'Cash',
    'Check',
    'Card',
    'Bank transfer',
    'PayPal / Venmo',
    'Other',
  ];

  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final List<_Payment> _payments = [];
  String _method = 'Card';
  String _date = 'Today';

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _paid => _payments.fold(0, (sum, p) => sum + p.amount);
  double get _balance => (_total - _paid).clamp(0, double.infinity);
  bool get _paidInFull => _balance <= 0.004;
  double get _entered => double.tryParse(_amountController.text) ?? 0;

  void _setPercent(int pct) {
    final v = _balance * pct / 100;
    _amountController.text = v.toStringAsFixed(2);
  }

  void _record() {
    var amount = _entered;
    if (amount <= 0) return;
    amount = amount > _balance ? _balance : amount;
    setState(() {
      _payments.insert(
        0,
        _Payment(
          amount: amount,
          method: _method,
          date: _date == 'Today'
              ? 'Today · ${Formatters.dateShort(DateTime.now())}'
              : _date,
          note: _noteController.text.trim(),
        ),
      );
      _amountController.clear();
      _noteController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FormNavBar(
        title: 'Record payment',
        subtitle: 'Invoice #${widget.invoiceId} · Zachary Bosma',
        leadingLabel: 'Close',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _summaryCard(),
          if (!_paidInFull) ...[
            const SectionHeader(title: 'Add a payment'),
            _formCard(),
          ],
          const SectionHeader(title: 'Payment history'),
          _historyCard(),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _paidInFull ? AppColors.greenDeep : AppColors.green800,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _paidInFull ? 'Invoice total' : 'Balance due',
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xA6FFFFFF),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            Formatters.currency(_paidInFull ? _total : _balance),
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_paid / _total).clamp(0, 1),
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              color: _paidInFull ? Colors.white : AppColors.orange500,
            ),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              text: 'Paid ',
              children: [
                TextSpan(
                  text: Formatters.currency(_paid),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700),
                ),
                const TextSpan(text: ' of '),
                TextSpan(
                  text: Formatters.currency(_total),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Color(0xBFFFFFFF),
            ),
          ),
          if (_paidInFull) ...[
            const SizedBox(height: 12),
            Row(
              children: const [
                Icon(Icons.check, size: 18, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Paid in full — nice work',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _formCard() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Amount',
              style: AppTextStyles.labelMedium
                  .copyWith(color: AppColors.inkSoft, fontSize: 12.5)),
          const SizedBox(height: 6),
          TextField(
            controller: _amountController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
            decoration: InputDecoration(
              hintText: '0.00',
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 14, right: 6, top: 10),
                child: Text(
                  '\$',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkFaint,
                  ),
                ),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
              filled: true,
              fillColor: AppColors.page,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _quickChip('Full balance', 100),
              const SizedBox(width: 8),
              _quickChip('Half', 50),
              const SizedBox(width: 8),
              _quickChip('25%', 25),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _pickerField(
                  label: 'Method',
                  value: _method,
                  onTap: () async {
                    final choice =
                        await _showOptions('Method', _methods, _method);
                    if (choice != null) setState(() => _method = choice);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _pickerField(
                  label: 'Date',
                  value: _date,
                  onTap: () async {
                    final choice = await _showOptions(
                        'Date', ['Today', 'Yesterday', 'Pick a date…'], _date);
                    if (choice != null) setState(() => _date = choice);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _noteController,
            style: AppTextStyles.bodyMedium
                .copyWith(fontWeight: FontWeight.w600, height: 1.2),
            decoration: const InputDecoration(
              hintText: 'Note (optional) — e.g. deposit, final payment',
              filled: true,
              fillColor: AppColors.page,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _entered > 0 ? _record : null,
            child: Text(
              _entered > 0
                  ? 'Record ${Formatters.currency(_entered > _balance ? _balance : _entered)}'
                  : 'Record payment',
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickChip(String label, int pct) {
    return Expanded(
      child: Material(
        color: AppColors.card,
        shape: const StadiumBorder(
          side: BorderSide(color: AppColors.line),
        ),
        child: InkWell(
          onTap: () => _setPercent(pct),
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.inkSoft,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pickerField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.labelMedium
                .copyWith(color: AppColors.inkSoft, fontSize: 12.5)),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.page,
              border: Border.all(color: AppColors.line, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelMedium.copyWith(fontSize: 14),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down,
                    size: 16, color: AppColors.inkFaint),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<String?> _showOptions(
      String title, List<String> options, String selected) {
    return showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
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
                onTap: () => Navigator.of(sheetContext).pop(option),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _historyCard() {
    if (_payments.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
        child: Center(
          child: Text(
            'Nothing recorded yet. Payments you add appear here and count toward the balance.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.inkFaint, height: 1.5),
          ),
        ),
      );
    }

    return AppCard(
      child: Column(
        children: [
          for (var i = 0; i < _payments.length; i++)
            _historyRow(_payments[i], i, showDivider: i < _payments.length - 1),
        ],
      ),
    );
  }

  Widget _historyRow(_Payment payment, int index,
      {required bool showDivider}) {
    return Container(
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.line))
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.greenTint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_methodIcon(payment.method),
                size: 16, color: AppColors.greenDeep),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.note.isEmpty
                      ? payment.method
                      : '${payment.method} · ${payment.note}',
                  style: AppTextStyles.rowTitle.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 1),
                Text(payment.date,
                    style: AppTextStyles.caption.copyWith(fontSize: 12)),
              ],
            ),
          ),
          Text(
            '+${Formatters.currency(payment.amount)}',
            style: AppTextStyles.rowAmount
                .copyWith(fontSize: 14.5, color: AppColors.greenDeep),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => setState(() => _payments.removeAt(index)),
            borderRadius: BorderRadius.circular(6),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.delete_outline,
                  size: 15, color: AppColors.inkFaint),
            ),
          ),
        ],
      ),
    );
  }

  IconData _methodIcon(String method) => switch (method) {
        'Cash' => Icons.payments_outlined,
        'Check' => Icons.fact_check_outlined,
        'Card' => Icons.credit_card_outlined,
        'Bank transfer' => Icons.account_balance_outlined,
        'PayPal / Venmo' => Icons.account_balance_wallet_outlined,
        _ => Icons.help_outline,
      };
}
