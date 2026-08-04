import 'package:flutter/material.dart';

import '../../../core/widgets/main_shell.dart';
import '../../../shared/widgets/paper_document.dart';

/// Estimate document preview (#1172 in the mockups): toolbar,
/// status band, desktop/mobile toggle, and three paper pages.
class EstimateDetailScreen extends StatefulWidget {
  final String id;
  const EstimateDetailScreen({super.key, required this.id});

  @override
  State<EstimateDetailScreen> createState() => _EstimateDetailScreenState();
}

class _EstimateDetailScreenState extends State<EstimateDetailScreen> {
  bool _mobileMode = false;
  String _status = 'pending';

  static const _statusOptions = [
    StatusBandOption(
      key: 'pending',
      bandLabel: 'Pending',
      menuLabel: 'Pending',
      kind: StatusBandKind.pending,
    ),
    StatusBandOption(
      key: 'approved',
      bandLabel: 'Approved',
      menuLabel: 'Mark as approved',
      kind: StatusBandKind.positive,
    ),
    StatusBandOption(
      key: 'declined',
      bandLabel: 'Declined',
      menuLabel: 'Mark as declined',
      kind: StatusBandKind.negative,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          DetailHeader(
            backLabel: 'Estimates',
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
              ToolbarAction(Icons.print_outlined, 'Print', onTap: () {}),
              ToolbarAction(Icons.receipt_long_outlined, 'Invoice',
                  onTap: () {}),
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
                  text: 'Serden Group LLC (Insured | Licensed | Bonded)\n'
                      'LICENSE # SERDEGL826PD',
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
        if (!m) const DocWatermark('ESTIMATE'),
        if (m) ...[
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Estimate #${widget.id}',
                    style: docStyle(
                        size: 24,
                        weight: FontWeight.w700,
                        color: const Color(0xFF1C1C1E),
                        height: 1.2)),
                const SizedBox(height: 5),
                Text('Date: 04/04/2026', style: docStyle(size: 14)),
              ],
            ),
          ),
        ],
        if (m)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DocLogoBlock(mobile: m),
              const SizedBox(height: 18),
              DocPreparedBlock(
                mobile: m,
                label: 'Prepared For',
                detail: 'Joseph Ulrich\n'
                    '4401 NW Lavina St\n'
                    'Vancouver, WA 98660\n'
                    '(503) 730-9144',
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
                label: 'Prepared For',
                detail: 'Joseph Ulrich\n'
                    '4401 NW Lavina St\n'
                    'Vancouver, WA 98660\n'
                    '(503) 730-9144',
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
                width: 220,
                child: Column(
                  children: const [
                    DocMetaRow('Estimate #', '1172'),
                    DocMetaRow('Date', '04/04/2026'),
                  ],
                ),
              ),
            ],
          ),
        DocDescriptionLabel(mobile: m),
        DocSection(
          mobile: m,
          title: 'Bathroom',
          amount: '\$10,600.00',
          body: [
            Text(
              'Shower Remodel',
              style: docStyle(
                size: m ? 15.5 : 14,
                color: const Color(0xFF1C1C1E),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            const Text("What's Included in quote:\n"
                '-Demolition of existing shower\n'
                '-Prep existing shower for tile install\n'
                '-Build out new shower pan with curb (w/ sloppage by code)\n'
                '-Buildout 1 recessed shelf & bench (match existing)\n'
                '-Install tile in shower walls\n'
                '-Install tile in shower pan\n'
                '-Remove all job related debris\n'
                '-Final clean up and inspection'),
            const SizedBox(height: 14),
            const Text(
                'Materials included in quote: thin-set, hardiebacker, red-guard, '
                'plumbing rough-in, shower pan buildout materials'),
            const SizedBox(height: 14),
            const Text(
                'Materials customer to buy: Tile, Grout, shower faucets'),
            const SizedBox(height: 14),
            const Text('salvage & reinstall existing glass'),
          ],
        ),
        SizedBox(height: m ? 22 : 34),
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: m ? double.infinity : 300,
            child: Column(
              children: [
                DocTotalRow(
                    mobile: m,
                    label: 'Subtotal',
                    value: '\$10,600.00',
                    underlined: true),
                DocTotalRow(
                    mobile: m,
                    label: 'Total',
                    value: '\$10,600.00',
                    boldValue: true),
              ],
            ),
          ),
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
        DocTermsTitle('Terms and conditions', mobile: m, topMargin: 0),
        DocParagraph(
          mobile: m,
          'This estimate covers the scope of work described on page 1. Any work '
          'outside that scope will be documented in a written change order and '
          'approved by the client before it begins.',
        ),
        DocParagraph(
          mobile: m,
          'Pricing is valid for 30 days from the estimate date. Materials listed '
          'as included are supplied by Serden Group LLC; materials listed as '
          'customer-provided must be on site before the scheduled start date.',
        ),
        DocTermsTitle('Payment', mobile: m),
        DocParagraph(
          mobile: m,
          'Unless otherwise agreed in writing, a deposit is due upon acceptance '
          'and the remaining balance is due upon completion. Accepted payment '
          'methods include card, bank transfer, check, and cash.',
        ),
        DocTermsTitle('Workmanship', mobile: m),
        DocParagraph(
          mobile: m,
          'All labor is warranted for one (1) year from the date of completion. '
          'Manufacturer warranties apply to materials. Serden Group LLC is '
          'insured, licensed, and bonded — LICENSE # SERDEGL826PD.',
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
        DocTermsTitle('Acceptance', mobile: m, topMargin: 0),
        DocParagraph(
          mobile: m,
          'By signing below, the client accepts this estimate and the terms on '
          'page 2, and authorizes Serden Group LLC to schedule and perform the '
          'work described.',
        ),
        const SizedBox(height: 44),
        const DocSignatureLine(label: 'Client signature — Joseph Ulrich'),
        const SizedBox(height: 34),
        Row(
          children: const [
            Expanded(child: DocSignatureLine(label: 'Date')),
            SizedBox(width: 28),
            Expanded(child: DocSignatureLine(label: 'Serden Group LLC')),
          ],
        ),
      ],
    );
  }
}
