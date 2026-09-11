import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/main_shell.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../shared/widgets/paper_document.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../cubit/invoice_detail_cubit.dart';
import '../models/invoice_model.dart';

/// Invoice document preview — toolbar, status band, desktop/mobile toggle,
/// and paper pages. Driven by the API (`GET /api/Invoices/{id}`).
class InvoiceDetailScreen extends StatefulWidget {
  final String id;
  const InvoiceDetailScreen({super.key, required this.id});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  bool _mobileMode = false;

  int get _invoiceId => int.tryParse(widget.id) ?? 0;

  int? get _userId {
    final s = context.read<AuthBloc>().state;
    return s is AuthAuthenticated ? s.user.userId : null;
  }

  @override
  void initState() {
    super.initState();
    context.read<InvoiceDetailCubit>().fetch(_invoiceId, userId: _userId);
  }

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
      menuLabel: 'Overdue',
      kind: StatusBandKind.negative,
    ),
  ];

  String _statusKey(Invoice invoice) {
    switch (invoice.docStatus) {
      case DocumentStatus.paid:
        return 'paid';
      case DocumentStatus.overdue:
        return 'overdue';
      default:
        return 'unpaid';
    }
  }

  String _dueBandLabel(Invoice invoice) {
    final d = invoice.dueDate;
    if (invoice.docStatus == DocumentStatus.paid) return 'Paid in full';
    if (invoice.docStatus == DocumentStatus.overdue) return 'Overdue';
    if (d != null) return 'Due ${Formatters.dateShort(d)}';
    return 'Due upon receipt';
  }

  Future<void> _handleSend(Invoice invoice) async {
    await context.read<InvoiceDetailCubit>().send(invoice.invoiceId);
  }

  Future<void> _handleMarkPaid(Invoice invoice) async {
    final publicId = invoice.publicId;
    if (publicId == null) return;
    await context.read<InvoiceDetailCubit>().markPaid(publicId);
  }

  Future<void> _handleDelete(Invoice invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete invoice?'),
        content: const Text(
            'This invoice will be permanently deleted and cannot be recovered.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: AppColors.redDeep))),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<InvoiceDetailCubit>().delete(invoice.invoiceId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InvoiceDetailCubit, InvoiceDetailState>(
      listener: (context, state) {
        if (state is InvoiceDetailDeleted) {
          context.go('/invoices');
        }
        if (state is InvoiceDetailActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.greenDeep,
            ),
          );
        }
        if (state is InvoiceDetailActionFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.redDeep,
            ),
          );
        }
      },
      builder: (context, state) {
        final invoice = switch (state) {
          InvoiceDetailLoaded(:final invoice) => invoice,
          InvoiceDetailLoading(:final preview) => preview,
          InvoiceDetailError(:final stale) => stale,
          InvoiceDetailBusy(:final invoice) => invoice,
          InvoiceDetailActionSuccess(:final invoice) => invoice,
          InvoiceDetailActionFailure(:final invoice) => invoice,
          _ => null,
        };

        final isLoading = state is InvoiceDetailLoading;
        final isBusy = state is InvoiceDetailBusy;
        final errorMessage =
            state is InvoiceDetailError ? state.message : null;

        return LoadingOverlay(
          isLoading: isBusy,
          child: Scaffold(
            body: Column(
              children: [
                DetailHeader(
                  backLabel: 'Invoices',
                  title: invoice != null
                      ? '#${invoice.number}'
                      : '#${widget.id}',
                  actions: [
                    if (invoice != null)
                      TextButton(
                        onPressed: isBusy ? null : () {},
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.white),
                        child: const Text('Edit'),
                      ),
                  ],
                ),
                if (invoice != null) ...[
                  DocumentToolbar(
                    actions: [
                      ToolbarAction(
                        Icons.send_outlined,
                        'Send',
                        onTap: isBusy ? null : () => _handleSend(invoice),
                      ),
                      ToolbarAction(
                        Icons.payments_outlined,
                        'Payments',
                        onTap: () => context
                            .push('/invoices/${widget.id}/record-payment'),
                      ),
                      ToolbarAction(
                        Icons.check_circle_outline,
                        'Mark paid',
                        onTap: (isBusy ||
                                invoice.docStatus == DocumentStatus.paid)
                            ? null
                            : () => _handleMarkPaid(invoice),
                      ),
                      ToolbarAction(
                        Icons.more_horiz,
                        'More',
                        onTap: isBusy
                            ? null
                            : () => _showMoreSheet(context, invoice),
                      ),
                    ],
                  ),
                  StatusBand(
                    options: [
                      StatusBandOption(
                        key: 'unpaid',
                        bandLabel: _dueBandLabel(invoice),
                        menuLabel: 'Unpaid',
                        kind: StatusBandKind.pending,
                      ),
                      ..._statusOptions.skip(1),
                    ],
                    currentKey: _statusKey(invoice),
                    onChanged: (key) {
                      if (key == 'paid' && !isBusy) _handleMarkPaid(invoice);
                    },
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: ViewToggle(
                    mobileMode: _mobileMode,
                    onChanged: (m) => setState(() => _mobileMode = m),
                  ),
                ),
                Expanded(
                  child: isLoading && invoice == null
                      ? const Center(child: CircularProgressIndicator())
                      : errorMessage != null && invoice == null
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(errorMessage,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color: AppColors.inkSoft)),
                              ),
                            )
                          : invoice == null
                              ? const SizedBox.shrink()
                              : ListView(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 14, 16, 24),
                                  children: [
                                    PaperPage(
                                        mobile: _mobileMode,
                                        footer:
                                            const DocPageNote('Page 1 of 3'),
                                        child: _pageOne(invoice)),
                                    const SizedBox(height: 14),
                                    PaperPage(
                                        mobile: _mobileMode,
                                        footer:
                                            const DocPageNote('Page 2 of 3'),
                                        child: _pageTwo(invoice)),
                                    const SizedBox(height: 14),
                                    PaperPage(
                                        mobile: _mobileMode,
                                        footer:
                                            const DocPageNote('Page 3 of 3'),
                                        child: _pageThree(invoice)),
                                    if (invoice.notes?.isNotEmpty == true)
                                      DocNotesCard(text: invoice.notes!),
                                  ],
                                ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMoreSheet(BuildContext context, Invoice invoice) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.redDeep),
              title: const Text('Delete invoice',
                  style: TextStyle(color: AppColors.redDeep)),
              onTap: () {
                Navigator.pop(context);
                _handleDelete(invoice);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageOne(Invoice invoice) {
    final m = _mobileMode;
    final clientDetail = [
      if (invoice.clientName?.isNotEmpty == true) invoice.clientName!,
    ].join('\n');

    final proDetails = [
      if (invoice.proAddress?.isNotEmpty == true) invoice.proAddress!,
      if (invoice.proEmail?.isNotEmpty == true) invoice.proEmail!,
    ].join('\n');

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
                Text('Invoice #${invoice.number}',
                    style: docStyle(
                        size: 24,
                        weight: FontWeight.w700,
                        color: const Color(0xFF1C1C1E),
                        height: 1.2)),
                const SizedBox(height: 5),
                Text(
                    'Date: ${Formatters.dateShort(invoice.invoiceDate)}',
                    style: docStyle(size: 14)),
              ],
            ),
          ),
        if (m)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DocLogoBlock(mobile: m, companyName: invoice.proName),
              const SizedBox(height: 18),
              DocPreparedBlock(
                mobile: m,
                label: 'Bill To',
                detail: clientDetail,
              ),
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DocLogoBlock(mobile: m, companyName: invoice.proName),
              const Spacer(),
              DocPreparedBlock(
                mobile: m,
                label: 'Bill To',
                detail: clientDetail,
              ),
            ],
          ),
        SizedBox(height: m ? 20 : 30),
        if (m)
          DocCompanyBlock(mobile: m, name: invoice.proName, details: proDetails)
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DocCompanyBlock(
                  mobile: m, name: invoice.proName, details: proDetails),
              const Spacer(),
              SizedBox(
                width: 240,
                child: Column(
                  children: [
                    DocMetaRow(
                        'Payment terms',
                        invoice.daysToPay != null
                            ? 'Net ${invoice.daysToPay}'
                            : 'Due upon receipt'),
                    DocMetaRow('Invoice #', invoice.number.toString()),
                    DocMetaRow('Date',
                        Formatters.dateShort(invoice.invoiceDate)),
                    if (invoice.dueDate != null)
                      DocMetaRow('Due date',
                          Formatters.dateShort(invoice.dueDate!)),
                  ],
                ),
              ),
            ],
          ),
        DocDescriptionLabel(mobile: m),
        ...invoice.allLineItems.map((item) => DocSection(
              mobile: m,
              title: item.description,
              amount: Formatters.currency(item.lineTotal),
              body: item.notes != null ? [Text(item.notes!)] : [],
            )),
        if (invoice.allLineItems.isEmpty)
          DocSection(
            mobile: m,
            title: 'No line items',
            amount: Formatters.currency(invoice.total),
            body: const [],
          ),
      ],
    );
  }

  Widget _pageTwo(Invoice invoice) {
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
                    mobile: m,
                    label: 'Subtotal',
                    value: Formatters.currency(invoice.subtotal)),
                if (invoice.markupValue != null)
                  DocTotalRow(
                      mobile: m,
                      label: 'Markup',
                      value: Formatters.currency(invoice.markupValue!)),
                if (invoice.discountValue != null)
                  DocTotalRow(
                      mobile: m,
                      label: 'Discount',
                      value: '-${Formatters.currency(invoice.discountValue!)}'),
                if (invoice.taxRate != null)
                  DocTotalRow(
                      mobile: m,
                      label: invoice.taxName ?? 'Tax',
                      value: '${invoice.taxRate!.toStringAsFixed(2)}%'),
                DocTotalRow(
                    mobile: m,
                    label: 'Total',
                    value: Formatters.currency(invoice.total),
                    underlined: true),
                if (invoice.depositValue != null && invoice.depositValue! > 0)
                  DocTotalRow(
                      mobile: m,
                      label: 'Deposit received',
                      value:
                          '-${Formatters.currency(invoice.depositValue!)}'),
                DocTotalRow(
                    mobile: m,
                    label: 'Balance due',
                    value: Formatters.currency(invoice.total),
                    boldValue: true),
              ],
            ),
          ),
        ),
        if (invoice.notes?.isNotEmpty == true) ...[
          DocTermsTitle('Notes', mobile: m, topMargin: 44),
          DocParagraph(invoice.notes!, mobile: m),
        ],
      ],
    );
  }

  Widget _pageThree(Invoice invoice) {
    final m = _mobileMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        DocTermsTitle('Remittance', mobile: m, topMargin: 0),
        DocParagraph(
          'Please make payment to ${invoice.proName ?? 'the company'}. '
          'Include the invoice number (#${invoice.number}) with any check '
          'or transfer so we can apply it correctly.',
          mobile: m,
        ),
        const SizedBox(height: 18),
        Column(
          children: [
            DocTotalRow(
                mobile: m,
                label: 'Invoice #',
                value: invoice.number.toString()),
            DocTotalRow(
                mobile: m,
                label: 'Bill to',
                value: invoice.clientName ?? ''),
            DocTotalRow(
                mobile: m,
                label: 'Amount due',
                value: Formatters.currency(invoice.total),
                underlined: true),
            DocTotalRow(
                mobile: m,
                label: 'Due date',
                value: invoice.dueDate != null
                    ? Formatters.dateShort(invoice.dueDate!)
                    : 'Upon receipt',
                boldValue: true),
          ],
        ),
        const SizedBox(height: 44),
        DocParagraph(
          'Thank you for your business.',
          mobile: m,
        ),
      ],
    );
  }
}
