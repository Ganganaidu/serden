import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/main_shell.dart';
import '../../../shared/widgets/paper_document.dart';

/// Invoice document preview (#96 in the mockups): toolbar,
/// status band, desktop/mobile toggle, and three paper pages.
class InvoiceDetailScreen extends StatefulWidget {
  final String id;
  const InvoiceDetailScreen({super.key, required this.id});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  bool _mobileMode = false;
  String _status = 'unpaid';

  static const _statusOptions = [
    StatusBandOption(
      key: 'unpaid',
      bandLabel: 'Unpaid · Due upon receipt',
      menuLabel: 'Unpaid',
      kind: StatusBandKind.pending,
    ),
    StatusBandOption(
      key: 'paid',
      bandLabel: 'Paid in full',
      menuLabel: 'Mark as paid',
      kind: StatusBandKind.positive,
    ),
    StatusBandOption(
      key: 'overdue',
      bandLabel: 'Overdue',
      menuLabel: 'Mark as overdue',
      kind: StatusBandKind.negative,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          DetailHeader(
            backLabel: 'Invoices',
            title: '#${widget.id}',
            actions: [
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: const Text('Edit'),
              ),
            ],
          ),
          DocumentToolbar(
            actions: [
              ToolbarAction(Icons.send_outlined, 'Send', onTap: () {}),
              ToolbarAction(Icons.tap_and_play, 'Tap to pay', onTap: () {}),
              ToolbarAction(
                Icons.payments_outlined,
                'Payments',
                onTap: () =>
                    context.push('/invoices/${widget.id}/record-payment'),
              ),
              ToolbarAction(Icons.more_horiz, 'More', onTap: () {}),
            ],
          ),
          StatusBand(
            options: _statusOptions,
            currentKey: _status,
            onChanged: (s) => setState(() => _status = s),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: ViewToggle(
              mobileMode: _mobileMode,
              onChanged: (m) => setState(() => _mobileMode = m),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                PaperPage(mobile: _mobileMode, footer: const DocPageNote('Page 1 of 3'), child: _pageOne()),
                const SizedBox(height: 14),
                PaperPage(mobile: _mobileMode, footer: const DocPageNote('Page 2 of 3'), child: _pageTwo()),
                const SizedBox(height: 14),
                PaperPage(mobile: _mobileMode, footer: const DocPageNote('Page 3 of 3'), child: _pageThree()),
                const DocNotesCard(
                  text:
                      '50% deposit collected at project start. Balance due upon receipt.\n\n'
                      'Serden Group LLC (Insured | Licensed | Bonded)\n'
                      'LICENSE # SERDEGL826PD\n'
                      'serdenco.com',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageOne() {
    final m = _mobileMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!m) const DocWatermark('INVOICE'),
        if (m)
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Invoice #${widget.id}',
                    style: docStyle(
                        size: 24,
                        weight: FontWeight.w700,
                        color: const Color(0xFF1C1C1E),
                        height: 1.2)),
                const SizedBox(height: 5),
                Text('Date: 06/30/2026', style: docStyle(size: 14)),
              ],
            ),
          ),
        if (m)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DocLogoBlock(mobile: m),
              const SizedBox(height: 18),
              DocPreparedBlock(
                mobile: m,
                label: 'Bill To',
                detail: 'Praveen Kumar\n'
                    '12801 SE 24th St\n'
                    'Vancouver, WA 98683\n'
                    '(360) 980-0168',
              ),
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DocLogoBlock(mobile: m),
              const Spacer(),
              DocPreparedBlock(
                mobile: m,
                label: 'Bill To',
                detail: 'Praveen Kumar\n'
                    '12801 SE 24th St\n'
                    'Vancouver, WA 98683\n'
                    '(360) 980-0168',
              ),
            ],
          ),
        SizedBox(height: m ? 20 : 30),
        if (m)
          DocCompanyBlock(mobile: m)
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DocCompanyBlock(mobile: m),
              const Spacer(),
              SizedBox(
                width: 240,
                child: Column(
                  children: const [
                    DocMetaRow('Payment terms', 'Due upon receipt'),
                    DocMetaRow('Invoice #', '96'),
                    DocMetaRow('Date', '06/30/2026'),
                  ],
                ),
              ),
            ],
          ),
        DocDescriptionLabel(mobile: m),
        DocSection(
          mobile: m,
          title: 'Addition',
          amount: '\$163,200.23',
          body: [
            Text(
              'HARD COSTS: Construction Phase',
              style: docStyle(
                size: m ? 15.5 : 14,
                color: const Color(0xFF1C1C1E),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
                'Proposed Address:\n12801 SE 24th St\nVancouver, WA 98683'),
            const SizedBox(height: 14),
            const Text('SCOPE: ADDING 2 story addition 22x28 w/ 2 bathrooms'),
            const SizedBox(height: 14),
            const Text('Whats Included in quote:\n'
                'Demolition of existing Structure & Create opening\n'
                'Site Prep & Excavation Work\n'
                'Foundation\n'
                'Framing & Sheeting & Trusse Install\n'
                'Electrical Work - (wiring for Can lights, Light Fixtures, Switches, plugs etc)\n'
                'Plumbing Work - (connections for new layout)\n'
                'Install Roof to match (Match Existing roofline)\n'
                'Siding & trim (Match to Existing)\n'
                'Insulation (all exterior walls of the addition)\n'
                'Drywall/Mudding/Texture\n'
                'Install 13 Standard Vinyl Window (Standard Milgard builder grade)\n'
                'Install exterior patio door\n'
                'Haul away all job related debris\n'
                'Final Clean up & inspection'),
            const SizedBox(height: 14),
            const Text(
                'Materials Included: foundation (concrete rebar), lumber package, '
                'all frame materials and hardware, roofing materials, drywall '
                'materials, insulation, plumbing rough in, electrical rough in, '
                'windows, patio door'),
          ],
        ),
        DocSection(
          mobile: m,
          title: 'Other items "NOT" included (can be added)',
          amount: '\$0.00',
          topMargin: 22,
          body: const [
            Text('Daikin Mini Splits x 3 units - \$16,900\n'
                'Flooring allowance (customer selection)\n'
                'Interior paint\n'
                'Cabinets & countertops'),
          ],
        ),
      ],
    );
  }

  Widget _pageTwo() {
    final m = _mobileMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: m ? double.infinity : 300,
            child: Column(
              children: [
                DocTotalRow(
                    mobile: m, label: 'Subtotal', value: '\$163,200.23'),
                DocTotalRow(
                    mobile: m,
                    label: 'Deposit received',
                    value: '-\$81,600.11'),
                DocTotalRow(
                    mobile: m,
                    label: 'Total',
                    value: '\$163,200.23',
                    underlined: true),
                DocTotalRow(
                    mobile: m,
                    label: 'Balance due',
                    value: '\$81,600.12',
                    boldValue: true),
              ],
            ),
          ),
        ),
        DocTermsTitle('Payment schedule', mobile: m, topMargin: 44),
        DocParagraph(
          mobile: m,
          'A 50% deposit was collected at project start. The remaining balance '
          'of \$81,600.12 is due upon receipt of this invoice. Accepted methods: '
          'card, bank transfer, check, and cash. Tap "Tap to pay" or "Payments" '
          'above to collect on site.',
        ),
        DocTermsTitle('Late payment', mobile: m),
        DocParagraph(
          mobile: m,
          'Balances unpaid 15 days past the due date may accrue a service charge '
          'of 1.5% per month on the outstanding amount, as permitted by state law.',
        ),
      ],
    );
  }

  Widget _pageThree() {
    final m = _mobileMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        DocTermsTitle('Remittance', mobile: m, topMargin: 0),
        DocParagraph(
          mobile: m,
          'Please make payment to Serden Group LLC. Include the invoice number '
          '(#96) with any check or transfer so we can apply it correctly.',
        ),
        const SizedBox(height: 18),
        Column(
          children: [
            DocTotalRow(mobile: m, label: 'Invoice #', value: '96'),
            DocTotalRow(mobile: m, label: 'Bill to', value: 'Praveen Kumar'),
            DocTotalRow(
                mobile: m,
                label: 'Amount due',
                value: '\$81,600.12',
                underlined: true),
            DocTotalRow(
                mobile: m,
                label: 'Due date',
                value: 'Upon receipt',
                boldValue: true),
          ],
        ),
        const SizedBox(height: 44),
        DocParagraph(
          mobile: m,
          'Thank you for your business. Serden Group LLC is insured, licensed, '
          'and bonded — LICENSE # SERDEGL826PD.',
        ),
      ],
    );
  }
}
