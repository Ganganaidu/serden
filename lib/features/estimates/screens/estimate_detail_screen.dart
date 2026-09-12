import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_error_widget.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/main_shell.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../shared/widgets/paper_document.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../clients/models/client_model.dart';
import '../../more/models/company_profile_model.dart';
import '../cubit/estimate_detail_cubit.dart';
import '../models/estimate_model.dart';

/// Estimate document preview — the multi-page "paper" layout with a
/// Desktop / Mobile view toggle, driven by the API (`GET /api/Estimates/{id}`),
/// the pro's company profile, and the client record.
class EstimateDetailScreen extends StatefulWidget {
  final String id;
  const EstimateDetailScreen({super.key, required this.id});

  @override
  State<EstimateDetailScreen> createState() => _EstimateDetailScreenState();
}

class _EstimateDetailScreenState extends State<EstimateDetailScreen> {
  bool _mobileMode = false;
  CompanyProfile? _company;
  Client? _client;

  int get _estimateId => int.tryParse(widget.id) ?? 0;

  int? get _userId {
    final s = context.read<AuthBloc>().state;
    return s is AuthAuthenticated ? s.user.userId : null;
  }

  @override
  void initState() {
    super.initState();
    context
        .read<EstimateDetailCubit>()
        .fetch(_estimateId, userId: _userId);
  }

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

  String _statusKey(Estimate e) => switch (e.docStatus) {
        DocumentStatus.approved => 'approved',
        DocumentStatus.declined => 'declined',
        _ => 'pending',
      };

  Future<void> _handleEdit(Estimate estimate) async {
    final result = await context.push<Map<String, dynamic>>(
      AppRoutes.newEstimate,
      extra: {'estimateToEdit': estimate},
    );
    if (!mounted) return;
    if (result?['estimate'] is Estimate) {
      context
          .read<EstimateDetailCubit>()
          .applyUpdate(result!['estimate'] as Estimate);
    }
    context.read<EstimateDetailCubit>().fetch(_estimateId, userId: _userId);
  }

  void _showMoreSheet(Estimate estimate) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              decoration: BoxDecoration(
                color: AppColors.grabber,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: AppColors.ink),
              title: Text('Edit estimate', style: AppTextStyles.rowTitle),
              onTap: () {
                Navigator.pop(sheetContext);
                _handleEdit(estimate);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: AppColors.redDeep),
              title: Text('Delete estimate',
                  style: AppTextStyles.rowTitle
                      .copyWith(color: AppColors.redDeep)),
              onTap: () {
                Navigator.pop(sheetContext);
                _confirmDelete();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete estimate?'),
        content: const Text('This permanently removes the estimate.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<EstimateDetailCubit>().delete(_estimateId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _soon(String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$what is coming soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EstimateDetailCubit, EstimateDetailState>(
      listener: (context, state) {
        if (state is EstimateDetailLoaded) {
          _company = state.company ?? _company;
          _client = state.client ?? _client;
        } else if (state is EstimateDetailDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Estimate deleted'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          if (context.canPop()) context.pop();
        } else if (state is EstimateDetailActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state is EstimateDetailActionFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.orangeDeep,
            ),
          );
        }
      },
      builder: (context, state) {
        final estimate = switch (state) {
          EstimateDetailLoaded(:final estimate) => estimate,
          EstimateDetailLoading(:final preview) => preview,
          EstimateDetailError(:final stale) => stale,
          EstimateDetailBusy(:final estimate) => estimate,
          EstimateDetailActionSuccess(:final estimate) => estimate,
          EstimateDetailActionFailure(:final estimate) => estimate,
          _ => null,
        };
        final isLoading = state is EstimateDetailLoading;
        final isBusy = state is EstimateDetailBusy;
        final errorMessage =
            state is EstimateDetailError ? state.message : null;

        return LoadingOverlay(
          isLoading: isBusy,
          child: Scaffold(
            body: Column(
              children: [
                DetailHeader(
                  backLabel: 'Estimates',
                  title: estimate != null
                      ? '#${estimate.number}'
                      : '#${widget.id}',
                  actions: [
                    if (estimate != null)
                      TextButton(
                        onPressed: () => _handleEdit(estimate),
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.white),
                        child: const Text('Edit'),
                      ),
                  ],
                ),
                if (estimate != null) ...[
                  DocumentToolbar(
                    actions: [
                      ToolbarAction(Icons.send_outlined, 'Send',
                          onTap: () => context
                              .read<EstimateDetailCubit>()
                              .send(_estimateId)),
                      ToolbarAction(Icons.print_outlined, 'Print',
                          onTap: () => _soon('Printing')),
                      ToolbarAction(Icons.receipt_long_outlined, 'Invoice',
                          onTap: () => _soon('Converting to an invoice')),
                      ToolbarAction(Icons.more_horiz, 'More',
                          onTap: () => _showMoreSheet(estimate)),
                    ],
                  ),
                  StatusBand(
                    options: _statusOptions,
                    currentKey: _statusKey(estimate),
                    onChanged: (key) => context
                        .read<EstimateDetailCubit>()
                        .setStatus(_estimateId, key),
                  ),
                ],
                Expanded(
                  child: isLoading && estimate == null
                      ? const Center(child: CircularProgressIndicator())
                      : errorMessage != null && estimate == null
                          ? AppErrorWidget(
                              message: errorMessage,
                              onRetry: () => context
                                  .read<EstimateDetailCubit>()
                                  .fetch(_estimateId, userId: _userId),
                            )
                          : _PaperDoc(
                              estimate: estimate!,
                              company: _company,
                              client: _client,
                              mobileMode: _mobileMode,
                              onViewChanged: (m) =>
                                  setState(() => _mobileMode = m),
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Paper document ──────────────────────────────────────────────────────────

class _PaperDoc extends StatelessWidget {
  final Estimate estimate;
  final CompanyProfile? company;
  final Client? client;
  final bool mobileMode;
  final ValueChanged<bool> onViewChanged;

  const _PaperDoc({
    required this.estimate,
    required this.company,
    required this.client,
    required this.mobileMode,
    required this.onViewChanged,
  });

  String _fmtDate(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.day.toString().padLeft(2, '0')}/${d.year}';

  String get _companyName {
    final n = company?.proName?.trim();
    if (n != null && n.isNotEmpty) return n;
    final e = estimate.proName?.trim();
    return e != null && e.isNotEmpty ? e : 'My Company';
  }

  String get _companyDetails {
    final lines = <String>[];
    final street = (company?.streetAddress ?? estimate.proAddress)?.trim();
    if (street != null && street.isNotEmpty) lines.add(street);

    final city = (company?.city ?? estimate.proCity)?.trim() ?? '';
    final st = (company?.state ?? estimate.proState)?.trim() ?? '';
    final zip = (company?.zipCode ?? estimate.proZipCode)?.trim() ?? '';
    final cityLine = [
      if (city.isNotEmpty) city,
      [st, zip].where((s) => s.isNotEmpty).join(' '),
    ].where((s) => s.isNotEmpty).join(', ');
    if (cityLine.isNotEmpty) lines.add(cityLine);

    final phone = company?.phone?.trim();
    if (phone != null && phone.isNotEmpty) lines.add('Phone: $phone');
    final email = (company?.email ?? estimate.proEmail)?.trim();
    if (email != null && email.isNotEmpty) lines.add('Email: $email');
    return lines.join('\n');
  }

  String? get _logoUrl {
    final f = company?.proLogo?.trim();
    if (f == null || f.isEmpty) return null;
    return f.startsWith('http') ? f : AppConstants.proLogoUrl(f);
  }

  String get _preparedFor {
    final lines = <String>[];
    final name = (client?.name ?? estimate.clientName)?.trim();
    lines.add(name != null && name.isNotEmpty ? name : 'No client selected');
    if (client != null) {
      if ((client!.address ?? '').trim().isNotEmpty) {
        lines.add(client!.address!.trim());
      }
      if ((client!.address2 ?? '').trim().isNotEmpty) {
        lines.add(client!.address2!.trim());
      }
      final cityLine = [
        if ((client!.city ?? '').trim().isNotEmpty) client!.city!.trim(),
        [
          (client!.state ?? '').trim(),
          (client!.zipCode ?? '').trim(),
        ].where((s) => s.isNotEmpty).join(' '),
      ].where((s) => s.isNotEmpty).join(', ');
      if (cityLine.isNotEmpty) lines.add(cityLine);
      final phone = (client!.phoneMobile ?? client!.phoneOther ?? '').trim();
      if (phone.isNotEmpty) lines.add(phone);
    }
    return lines.join('\n');
  }

  /// The API returns every line item in the top-level `lineItems` array
  /// (each carrying a `sectionId`); `section.lineItems` is usually empty.
  /// Regroup the flat list under its sections here.
  List<({String title, double amount, List<EstimateLineItem> items})>
      get _sections {
    final flat = estimate.lineItems;
    final result = <({String title, double amount, List<EstimateLineItem> items})>[];
    final consumed = <int>{};

    for (final s in estimate.sections) {
      final items = s.lineItems.isNotEmpty
          ? s.lineItems
          : flat
              .where((li) => li.sectionId != null && li.sectionId == s.sectionId)
              .toList();
      for (final li in items) {
        if (li.lineItemId != 0) consumed.add(li.lineItemId);
      }
      final amount = s.subtotal > 0
          ? s.subtotal
          : items.fold<double>(0, (t, li) => t + li.lineTotal);
      result.add((
        title: s.name.trim().isEmpty ? 'Section' : s.name.trim(),
        amount: amount,
        items: items,
      ));
    }

    final sectionIds = estimate.sections.map((s) => s.sectionId).toSet();
    final leftover = flat
        .where((li) =>
            !consumed.contains(li.lineItemId) &&
            (li.sectionId == null || !sectionIds.contains(li.sectionId)))
        .toList();
    if (leftover.isNotEmpty) {
      result.add((
        title: estimate.sections.isEmpty ? 'Services' : 'Additional items',
        amount: leftover.fold<double>(0, (t, li) => t + li.lineTotal),
        items: leftover,
      ));
    }
    return result;
  }

  String? get _license =>
      company?.licenseNumber?.trim().isNotEmpty == true
          ? company!.licenseNumber!.trim()
          : null;

  String get _notesText {
    final n = (estimate.notes ?? '').trim();
    if (n.isNotEmpty) return n;
    final lines = <String>[
      '$_companyName (Insured | Licensed | Bonded)',
      if (_license != null) 'LICENSE # $_license',
    ];
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: ViewToggle(mobileMode: mobileMode, onChanged: onViewChanged),
        ),
        PaperPage(
          mobile: mobileMode,
          footer: const DocPageNote('Page 1 of 3'),
          child: _pageOne(),
        ),
        const SizedBox(height: 14),
        PaperPage(
          mobile: mobileMode,
          footer: const DocPageNote('Page 2 of 3'),
          child: _pageTwo(),
        ),
        const SizedBox(height: 14),
        PaperPage(
          mobile: mobileMode,
          footer: const DocPageNote('Page 3 of 3'),
          child: _pageThree(),
        ),
        DocNotesCard(text: _notesText),
      ],
    );
  }

  Widget _pageOne() {
    final m = mobileMode;
    final dateStr = _fmtDate(estimate.estimateDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!m) const DocWatermark('ESTIMATE'),
        if (m)
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Estimate #${estimate.number}',
                    style: docStyle(
                        size: 24,
                        weight: FontWeight.w700,
                        color: AppColors.docInk,
                        height: 1.2)),
                const SizedBox(height: 5),
                Text('Date: $dateStr', style: docStyle(size: 14)),
              ],
            ),
          ),
        if (m) ...[
          DocLogoBlock(
              mobile: m, logoUrl: _logoUrl, companyName: _companyName),
          const SizedBox(height: 18),
          DocPreparedBlock(
              mobile: m, label: 'Prepared For', detail: _preparedFor),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DocLogoBlock(
                  mobile: m, logoUrl: _logoUrl, companyName: _companyName),
              const Spacer(),
              Flexible(
                child: DocPreparedBlock(
                    mobile: m, label: 'Prepared For', detail: _preparedFor),
              ),
            ],
          ),
        SizedBox(height: m ? 20 : 30),
        if (m)
          DocCompanyBlock(mobile: m, name: _companyName, details: _companyDetails)
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DocCompanyBlock(
                  mobile: m, name: _companyName, details: _companyDetails),
              const Spacer(),
              SizedBox(
                width: 220,
                child: Column(
                  children: [
                    DocMetaRow('Estimate #', '${estimate.number}'),
                    DocMetaRow('Date', dateStr),
                  ],
                ),
              ),
            ],
          ),
        DocDescriptionLabel(mobile: m),
        if (_sections.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text('No line items on this estimate yet.',
                style: docStyle(size: m ? 15 : 13.5)),
          )
        else
          for (final s in _sections)
            DocSection(
              mobile: m,
              title: s.title,
              amount: estimate.showSectionTotals
                  ? Formatters.currency(s.amount)
                  : '',
              body: _sectionBody(s.items, m),
            ),
        SizedBox(height: m ? 22 : 34),
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: m ? double.infinity : 300,
            child: Column(children: _totalRows(m)),
          ),
        ),
        if (estimate.photos.isNotEmpty) ...[
          SizedBox(height: m ? 24 : 34),
          Text('Photos',
              style: docStyle(
                  size: m ? 15.5 : 14,
                  weight: FontWeight.w700,
                  color: AppColors.docInk,
                  height: 1.2)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final p in _sorted(estimate.photos))
                _PhotoThumb(photo: p, size: m ? 76 : 88),
            ],
          ),
        ],
      ],
    );
  }

  List<EstimatePhoto> _sorted(List<EstimatePhoto> photos) {
    final list = [...photos]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list.where((p) => p.url != null).toList();
  }

  List<Widget> _sectionBody(List<EstimateLineItem> items, bool m) {
    if (items.isEmpty) {
      return [Text('—', style: docStyle(size: m ? 15 : 13.5))];
    }

    // Respect the estimate's client-facing display toggles.
    final showQtyRate = estimate.showQuantity || estimate.showRate;
    final showItemTotal = estimate.showItemTotals;

    final out = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      final li = items[i];
      if (i > 0) out.add(const SizedBox(height: 16));

      String? meta;
      if (showQtyRate) {
        final parts = <String>[];
        if (estimate.showQuantity) parts.add('${li.quantity}');
        if (estimate.showRate) {
          parts.add(parts.isEmpty
              ? Formatters.currency(li.unitPrice)
              : '× ${Formatters.currency(li.unitPrice)}');
        }
        meta = parts.join(' ');
      }

      out.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              li.description.trim().isEmpty ? 'Item' : li.description.trim(),
              style: docStyle(
                size: m ? 15.5 : 14,
                weight: FontWeight.w600,
                color: AppColors.docInk,
                height: 1.4,
              ),
            ),
          ),
          if (meta != null) ...[
            const SizedBox(width: 10),
            Text(meta, style: docStyle(size: m ? 14 : 12.5)),
          ],
          if (showItemTotal) ...[
            const SizedBox(width: 12),
            Text(Formatters.currency(li.lineTotal),
                style: docStyle(size: m ? 15 : 13.5, color: AppColors.docInk)),
          ],
        ],
      ));
      if ((li.notes ?? '').trim().isNotEmpty) {
        out.add(Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(li.notes!.trim(),
              style: docStyle(size: m ? 14.5 : 13, height: 1.6)),
        ));
      }
      final photos = _sorted(li.photos);
      if (photos.isNotEmpty) {
        out.add(Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in photos) _PhotoThumb(photo: p, size: m ? 60 : 64),
            ],
          ),
        ));
      }
    }
    return out;
  }

  List<Widget> _totalRows(bool m) {
    final rows = <Widget>[
      DocTotalRow(
          mobile: m,
          label: 'Subtotal',
          value: Formatters.currency(estimate.subtotal),
          underlined: true),
    ];
    if ((estimate.discountValue ?? 0) > 0) {
      rows.add(DocTotalRow(
          mobile: m,
          label: 'Discount',
          value: '−${_modifier(estimate.discountType, estimate.discountValue!)}'));
    }
    if ((estimate.markupValue ?? 0) > 0) {
      rows.add(DocTotalRow(
          mobile: m,
          label: 'Markup',
          value: '+${_modifier(estimate.markupType, estimate.markupValue!)}'));
    }
    if ((estimate.taxRate ?? 0) > 0) {
      rows.add(DocTotalRow(
          mobile: m,
          label: estimate.taxName?.trim().isNotEmpty == true
              ? 'Tax (${estimate.taxName!.trim()})'
              : 'Tax',
          value: '${estimate.taxRate!.toStringAsFixed(2)}%'));
    }
    rows.add(DocTotalRow(
        mobile: m,
        label: 'Total',
        value: Formatters.currency(estimate.total),
        boldValue: true));
    if (estimate.depositAmount > 0) {
      rows.add(DocTotalRow(
          mobile: m,
          label: 'Deposit due',
          value: Formatters.currency(estimate.depositAmount)));
    }
    return rows;
  }

  String _modifier(String? type, double value) =>
      AmountType.fromApi(type) == AmountType.percent
          ? '${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2)}%'
          : Formatters.currency(value);

  Widget _pageTwo() {
    final m = mobileMode;
    final licenseLine = _license != null
        ? '$_companyName is insured, licensed, and bonded — LICENSE # $_license.'
        : '$_companyName is insured, licensed, and bonded.';
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
          'as included are supplied by $_companyName; materials listed as '
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
          'Manufacturer warranties apply to materials. $licenseLine',
        ),
      ],
    );
  }

  Widget _pageThree() {
    final m = mobileMode;
    final clientName = (client?.name ?? estimate.clientName)?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        DocTermsTitle('Acceptance', mobile: m, topMargin: 0),
        DocParagraph(
          mobile: m,
          'By signing below, the client accepts this estimate and the terms on '
          'page 2, and authorizes $_companyName to schedule and perform the '
          'work described.',
        ),
        const SizedBox(height: 44),
        DocSignatureLine(
          label: clientName != null && clientName.isNotEmpty
              ? 'Client signature — $clientName'
              : 'Client signature',
        ),
        const SizedBox(height: 34),
        Row(
          children: [
            const Expanded(child: DocSignatureLine(label: 'Date')),
            const SizedBox(width: 28),
            Expanded(child: DocSignatureLine(label: _companyName)),
          ],
        ),
      ],
    );
  }
}

/// Small rounded photo thumbnail; tap opens a full-screen zoomable view.
class _PhotoThumb extends StatelessWidget {
  final EstimatePhoto photo;
  final double size;
  const _PhotoThumb({required this.photo, required this.size});

  @override
  Widget build(BuildContext context) {
    final url = photo.url;
    if (url == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => showDialog<void>(
        context: context,
        barrierColor: Colors.black87,
        builder: (dialogContext) => GestureDetector(
          onTap: () => Navigator.pop(dialogContext),
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Center(
                    child: Image.network(url,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white54,
                            size: 48)),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(dialogContext),
                ),
              ),
              if ((photo.caption ?? '').trim().isNotEmpty)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                  child: Text(
                    photo.caption!.trim(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
            ],
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) => progress == null
              ? child
              : Container(
                  width: size,
                  height: size,
                  color: AppColors.grayTint,
                  child: const Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
          errorBuilder: (_, __, ___) => Container(
            width: size,
            height: size,
            color: AppColors.grayTint,
            child: const Icon(Icons.broken_image_outlined,
                size: 18, color: AppColors.inkFaint),
          ),
        ),
      ),
    );
  }
}

