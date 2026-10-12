import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/di/injection.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/form_nav_bar.dart';
import '../../core/widgets/loading_overlay.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/clients/models/client_model.dart';
import '../../features/estimates/bloc/estimate_bloc.dart';
import '../../features/estimates/models/estimate_model.dart';
import '../../features/invoices/bloc/invoice_bloc.dart';
import '../../features/invoices/models/invoice_model.dart';
import '../../features/items/models/item_model.dart';
import '../../features/items/models/markup_template.dart';
import '../../features/taxes/models/tax_model.dart';
import '../models/doc_attachment.dart';
import 'attachment_preview.dart';
import 'subscription_limit_dialog.dart';

/// Sentinel id returned by the tax/markup picker sheets' "Custom amount"
/// row — picking it just reveals the manually-editable totals row instead
/// of applying a saved preset.
const int kCustomPickId = -1;

/// Sentinel from the line-item markup sheet's "Remove markup" row.
const int kRemoveMarkupId = -2;

/// File types accepted by the "Files" attachment picker, and the per-file
/// size cap — mirrors what the API accepts for estimate/invoice attachments.
const List<String> kAttachmentExtensions = [
  'pdf',
  'doc',
  'docx',
  'xls',
  'xlsx',
  'jpg',
  'jpeg',
  'png',
  'gif',
  'cad',
  'csv',
];
const int kMaxAttachmentBytes = 25 * 1024 * 1024;

String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

IconData iconForFileExtension(String? extension) {
  switch (extension?.toLowerCase()) {
    case 'pdf':
      return Icons.picture_as_pdf_outlined;
    case 'doc':
    case 'docx':
      return Icons.description_outlined;
    case 'xls':
    case 'xlsx':
    case 'csv':
      return Icons.table_chart_outlined;
    case 'jpg':
    case 'jpeg':
    case 'png':
    case 'gif':
      return Icons.image_outlined;
    case 'cad':
      return Icons.architecture_outlined;
    default:
      return Icons.insert_drive_file_outlined;
  }
}

/// Editable line item on the new estimate / invoice form.
/// A named group of line items (estimate / invoice "section").
class SectionDraft {
  final TextEditingController name;

  /// Id of the existing API section, when editing. 0 for new sections.
  int existingId;

  /// UI only: collapsed sections show a one-line summary.
  bool collapsed = false;

  SectionDraft({String name = '', this.existingId = 0})
      : name = TextEditingController(text: name);
}

class LineItemDraft {
  static int _nextUid = 0;

  /// Stable identity for widget keys (rows can be reordered).
  final int uid = _nextUid++;

  /// The section this row belongs to; null means the first section.
  SectionDraft? section;

  /// Long description / notes shown under this item on the document.
  String notes;

  /// Photos picked this session — uploaded after the document is saved.
  final List<XFile> photos = [];

  /// Photo URLs already saved on the API (edit mode; read-only here).
  List<String> existingPhotoUrls;

  String name;
  int qty;
  double price;

  /// Id of the existing API line item, when editing. 0 for new rows.
  int existingId;

  /// Id of the catalog item this row was populated from, if any.
  int? catalogItemId;

  /// Bumped whenever this row is populated programmatically (e.g. from the
  /// catalog picker) so the name/price fields rebuild with the new value —
  /// otherwise their [TextFormField]s ignore `initialValue` after first
  /// build and keep whatever the user last typed.
  int rev = 0;

  LineItemDraft({
    this.name = '',
    this.qty = 1,
    this.price = 0,
    this.existingId = 0,
    this.catalogItemId,
    this.section,
    this.notes = '',
    this.existingPhotoUrls = const [],
  });

  static const int maxPhotos = 4;
  int get photoCount => existingPhotoUrls.length + photos.length;

  /// This row's markup (from the catalog or a custom one). All row markups
  /// add up into the Markup line of the totals section.
  ItemMarkup markup = ItemMarkup.none;

  double get baseTotal => qty * price;

  double get markupAmount => !markup.hasMarkup
      ? 0
      : markup.type == MarkupType.percent
          ? baseTotal * markup.rate / 100
          : markup.rate;

  /// Line amount before markup — markups are added up in the totals section.
  double get total => baseTotal;
}

/// Shared "New estimate" / "New invoice" form. The two designs are
/// identical except for the document-details block and a couple of
/// payment toggles, switched by [isInvoice].
class DocumentForm extends StatefulWidget {
  final bool isInvoice;
  final int documentNumber;

  /// When set, the form opens in edit mode for this estimate and Save
  /// dispatches [EstimateUpdateRequested] instead of create. Estimates only.
  final Estimate? estimateToEdit;

  /// Invoice counterpart of [estimateToEdit] (invoices only).
  final Invoice? invoiceToEdit;

  const DocumentForm({
    super.key,
    required this.isInvoice,
    required this.documentNumber,
    this.estimateToEdit,
    this.invoiceToEdit,
  });

  @override
  State<DocumentForm> createState() => _DocumentFormState();
}

class _DocumentFormState extends State<DocumentForm> {
  final List<LineItemDraft> _items = [LineItemDraft()];
  final Set<String> _openBlocks = {};

  Client? _selectedClient;
  bool _submitting = false;

  // Staged locally; uploaded to the API after the estimate is created/
  // updated (it has no id to upload against beforehand).
  final List<XFile> _photos = [];
  final List<PlatformFile> _files = [];
  final _imagePicker = ImagePicker();

  // Already uploaded to the document being edited (read-only preview).
  List<DocPhotoRef> _existingPhotos = const [];
  List<DocAttachment> _existingFiles = const [];

  bool get _isEdit =>
      widget.estimateToEdit != null || widget.invoiceToEdit != null;

  // Optional adjustment rows (visible after tapping a chip).
  final Set<String> _activeAdjustments = {};
  double _discount = 0;
  AmountType _discountType = AmountType.fixed;
  double _taxPct = 0;
  double _depositValue = 25;
  AmountType _depositType = AmountType.percent;

  // Tax picker selection (replaces on each pick).
  int? _taxId;
  String? _taxName;

  /// Document-level markup saved by older versions of the form (before
  /// markups moved onto line items), as a fixed amount. Only kept while no
  /// line item carries its own markup.
  double _legacyMarkup = 0;

  // Bumped on each pick so the totals-row TextFormField (which only reads
  // `initialValue` on first build) rebuilds with the new value — see the
  // same gotcha/fix noted on LineItemDraft.rev.
  int _taxRev = 0;

  bool _groupSections = true;

  /// Sections shown when "Group items into sections" is on. There is always
  /// at least one; each line item points at one via [LineItemDraft.section].
  final List<SectionDraft> _sections = [SectionDraft()];
  bool _paypalEnabled = true;
  bool _coverFee = false;
  bool _autoInvoice = false;
  bool _financing = true;
  bool _clientSignature = true;
  bool _mySignature = false;
  bool _allowExpire = false;
  int _validDays = 30;
  String _paymentTerms = 'Due on receipt';

  String? _notes;
  String? _privateNotes;

  @override
  void initState() {
    super.initState();
    final inv = widget.invoiceToEdit;
    if (inv != null) {
      _initFromInvoice(inv);
      return;
    }
    final e = widget.estimateToEdit;
    if (e == null) return;

    _existingPhotos = [
      for (final p in e.photos)
        if (p.url != null) DocPhotoRef(p.url!, caption: p.caption),
    ];
    _existingFiles = e.attachments;

    if (e.clientId != null) {
      _selectedClient = Client(
        clientId: e.clientId!,
        proId: e.proId,
        name: e.clientName?.trim().isNotEmpty == true
            ? e.clientName!
            : 'Client',
      );
    }

    _loadSections(
      [for (final sec in e.sections) (sec.sectionId, sec.name, sec.sortOrder)],
      {
        for (final sec in e.sections)
          for (final li in sec.lineItems)
            if (li.lineItemId != 0) li.lineItemId: sec.sectionId,
      },
    );
    final items = e.allLineItems..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    if (items.isNotEmpty) {
      _items
        ..clear()
        ..addAll(items.map((li) => LineItemDraft(
              name: li.description,
              qty: li.quantity,
              price: li.unitPrice,
              existingId: li.lineItemId,
              catalogItemId: li.catalogLineItemId,
              section: _sectionFor(li.sectionId, li.lineItemId),
              notes: li.notes ?? '',
              existingPhotoUrls: [
                for (final p in li.photos)
                  if (p.url != null) p.url!,
              ],
            )..markup = ItemMarkup.fromApi(null, li.markupType, li.markupValue)));
    }

    _groupSections = e.groupItemsIntoSections ||
        e.sections.any((sec) => sec.name.trim().isNotEmpty);
    _clientSignature = e.showClientSignature;
    _mySignature = e.showMySignature;
    _notes = e.notes;
    _privateNotes = e.privateNotes;

    if ((e.discountValue ?? 0) > 0) {
      _activeAdjustments.add('discount');
      _discount = e.discountValue!;
      _discountType = AmountType.fromApi(e.discountType);
    }
    _loadLegacyMarkup(e.markupType, e.markupValue);
    if ((e.taxRate ?? 0) > 0) {
      _activeAdjustments.add('tax');
      _taxPct = e.taxRate!;
      _taxName = e.taxName;
    }
    if ((e.depositValue ?? 0) > 0) {
      _activeAdjustments.add('deposit');
      _depositValue = e.depositValue!;
      _depositType = AmountType.fromApi(e.depositType);
    }
    if (e.expirationDate != null) {
      _allowExpire = true;
      _validDays = e.expirationDate!.difference(e.estimateDate).inDays.abs();
      if (_validDays == 0) _validDays = 30;
    }
  }

  // lineItemId → sectionId for items nested inside a section.
  Map<int, int> _nestedSectionOf = {};
  SectionDraft? _looseSection;

  /// Draft → sortOrder it was saved with; used to find the created line-item
  /// ids when uploading per-item photos.
  final Map<LineItemDraft, int> _savedOrder = {};

  /// Replaces [_sections] with the document's saved sections (id, name,
  /// sortOrder), ordered. [nestedItemSection] maps line-item ids that came
  /// nested inside a section to that section's id.
  void _loadSections(
    List<(int, String, int)> saved,
    Map<int, int> nestedItemSection,
  ) {
    _nestedSectionOf = nestedItemSection;
    _looseSection = null;
    for (final sec in _sections) {
      sec.name.dispose();
    }
    _sections.clear();
    final ordered = [...saved]..sort((a, b) => a.$3.compareTo(b.$3));
    for (final (id, name, _) in ordered) {
      _sections.add(SectionDraft(name: name, existingId: id));
    }
    if (_sections.isEmpty) _sections.add(SectionDraft());
  }

  /// Which section a loaded line item belongs to. Items with no section while
  /// named sections exist go to a trailing unnamed group (saved as loose).
  SectionDraft? _sectionFor(int? sectionId, int lineItemId) {
    final id = _nestedSectionOf[lineItemId] ?? sectionId;
    if (id != null) {
      for (final sec in _sections) {
        if (sec.existingId == id) return sec;
      }
    }
    if (!_sections.any((sec) => sec.existingId != 0)) return null;
    if (_looseSection == null) {
      _looseSection = SectionDraft();
      _sections.add(_looseSection!);
    }
    return _looseSection;
  }

  void _initFromInvoice(Invoice inv) {
    _existingPhotos = [
      for (final p in inv.photos)
        if (p.url != null) DocPhotoRef(p.url!, caption: p.caption),
    ];
    _existingFiles = inv.attachments;
    if (inv.clientId != null) {
      _selectedClient = Client(
        clientId: inv.clientId!,
        proId: inv.proId,
        name: inv.clientName?.trim().isNotEmpty == true
            ? inv.clientName!
            : 'Client',
      );
    }

    _loadSections(
      [for (final sec in inv.sections) (sec.sectionId, sec.name, sec.sortOrder)],
      {
        for (final sec in inv.sections)
          for (final li in sec.lineItems)
            if (li.lineItemId != 0) li.lineItemId: sec.sectionId,
      },
    );
    final items = inv.allLineItems
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    if (items.isNotEmpty) {
      _items
        ..clear()
        ..addAll(items.map((li) => LineItemDraft(
              name: li.description,
              qty: li.quantity,
              price: li.unitPrice,
              existingId: li.lineItemId,
              section: _sectionFor(li.sectionId, li.lineItemId),
              notes: li.notes ?? '',
              existingPhotoUrls: [
                for (final p in li.photos)
                  if (p.url != null) p.url!,
              ],
            )..markup = ItemMarkup.fromApi(null, li.markupType, li.markupValue)));
    }

    _groupSections = inv.groupItemsIntoSections ||
        inv.sections.any((sec) => sec.name.trim().isNotEmpty);
    _clientSignature = inv.showClientSignature;
    _mySignature = inv.showMySignature;
    _notes = inv.notes;
    _privateNotes = inv.privateNotes;

    final days = inv.daysToPay;
    if (days != null) _paymentTerms = days == 0 ? 'Due on receipt' : 'Net $days';

    if ((inv.discountValue ?? 0) > 0) {
      _activeAdjustments.add('discount');
      _discount = inv.discountValue!;
      _discountType = AmountType.fromApi(inv.discountType);
    }
    _loadLegacyMarkup(inv.markupType, inv.markupValue);
    if ((inv.taxRate ?? 0) > 0) {
      _activeAdjustments.add('tax');
      _taxPct = inv.taxRate!;
      _taxName = inv.taxName;
    }
    if ((inv.depositValue ?? 0) > 0) {
      _activeAdjustments.add('deposit');
      _depositValue = inv.depositValue!;
      _depositType = AmountType.fromApi(inv.depositType);
    }
  }

  double get _subtotal =>
      _items.fold(0, (sum, item) => sum + item.total);

  /// Older documents stored one document-level markup; keep it (as a fixed
  /// amount) only while no line item has its own.
  void _loadLegacyMarkup(String? type, double? value) {
    if ((value ?? 0) <= 0 || _items.any((it) => it.markup.hasMarkup)) return;
    _legacyMarkup = type == 'F' ? value! : _subtotal * value! / 100;
  }

  /// Sum of every line item's markup (plus any legacy document markup).
  double get _markupTotal =>
      _items.fold<double>(0, (sum, it) => sum + it.markupAmount) +
      (_items.any((it) => it.markup.hasMarkup) ? 0 : _legacyMarkup);

  double get _total {
    final discountRaw =
        _activeAdjustments.contains('discount') ? _discount : 0.0;
    final discount = _discountType == AmountType.percent
        ? _subtotal * discountRaw / 100
        : discountRaw;
    final markup = _markupTotal;
    final taxPct = _activeAdjustments.contains('tax') ? _taxPct : 0.0;
    final base = (_subtotal - discount + markup).clamp(0, double.infinity);
    return base * (1 + taxPct / 100);
  }

  /// Money value of the tax: the total minus the same total before tax.
  double get _taxAmount {
    if (!_activeAdjustments.contains('tax') || _taxPct <= 0) return 0;
    return _total - _total / (1 + _taxPct / 100);
  }

  String get _footerLabel {
    if (_activeAdjustments.contains('deposit') && _depositValue > 0) {
      final deposit = _depositType == AmountType.percent
          ? _total * _depositValue / 100
          : _depositValue;
      return 'Total (USD) · ${Formatters.currency(deposit)} deposit due';
    }
    return 'Total (USD)';
  }

  @override
  void dispose() {
    for (final sec in _sections) {
      sec.name.dispose();
    }
    super.dispose();
  }

  String get _navTitle {
    if (widget.isInvoice) return _isEdit ? 'Edit invoice' : 'New invoice';
    return _isEdit ? 'Edit estimate' : 'New estimate';
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<EstimateBloc, EstimatesState>(
          listenWhen: (_, __) => _submitting && !widget.isInvoice,
          listener: _onEstimateState,
        ),
        BlocListener<InvoiceBloc, InvoicesState>(
          listenWhen: (_, __) => _submitting && widget.isInvoice,
          listener: _onInvoiceState,
        ),
      ],
      child: LoadingOverlay(
        isLoading: _submitting,
        child: _buildScaffold(context),
      ),
    );
  }

  Future<void> _onInvoiceState(
      BuildContext context, InvoicesState state) async {
    if (state is InvoiceMutateSuccess) {
      final invoice = state.invoice;
      var failedUploads = 0;
      if (invoice?.publicId != null &&
          (_photos.isNotEmpty || _files.isNotEmpty)) {
        failedUploads = await _uploadStagedAttachments(invoice!.publicId!);
      }
      if (invoice?.publicId != null) {
        failedUploads +=
            await _uploadLineItemPhotos(invoice!.publicId!, invoice.invoiceId);
      }
      if (!context.mounted) return;
      setState(() => _submitting = false);
      if (failedUploads > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '$failedUploads attachment${failedUploads == 1 ? '' : 's'} '
                'failed to upload.'),
            backgroundColor: AppColors.orangeDeep,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      if (invoice != null && _isEdit) {
        context.pop({'invoice': invoice});
      } else {
        context.pop();
      }
    } else if (state is InvoiceMutateFailure) {
      setState(() => _submitting = false);
      if (state.limitReached) {
        showSubscriptionLimitDialog(context);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: AppColors.orangeDeep,
        ),
      );
    }
  }

  Future<void> _onEstimateState(
      BuildContext context, EstimatesState state) async {
    if (state is EstimateMutateSuccess) {
      final estimate = state.estimate;
      var failedUploads = 0;
      if (estimate?.publicId != null &&
          (_photos.isNotEmpty || _files.isNotEmpty)) {
        failedUploads = await _uploadStagedAttachments(estimate!.publicId!);
      }
      if (estimate?.publicId != null) {
        failedUploads += await _uploadLineItemPhotos(
            estimate!.publicId!, estimate.estimateId);
      }
      if (!context.mounted) return;
      setState(() => _submitting = false);
      if (failedUploads > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '$failedUploads attachment${failedUploads == 1 ? '' : 's'} '
                "failed to upload — you can retry from the estimate's Edit screen."),
            backgroundColor: AppColors.orangeDeep,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      if (estimate != null) {
        context.pop({'estimate': estimate});
      } else {
        context.pop();
      }
    } else if (state is EstimateMutateFailure) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: AppColors.orangeDeep,
        ),
      );
    }
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      appBar: FormNavBar(
        title: _navTitle,
        subtitle: '#${widget.documentNumber} · ${_isEdit ? 'Editing' : 'Draft saved'}',
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
                    label: _selectedClient?.name ?? 'Add client',
                    showChevron: true,
                    onTap: _pickClient,
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

  SectionDraft _sectionOf(LineItemDraft item) => item.section ?? _sections.first;

  List<LineItemDraft> _itemsOf(SectionDraft section) =>
      [for (final it in _items) if (_sectionOf(it) == section) it];

  static const _sectionBg = Color(0xFFF1EFEA);

  Widget _lineItemsCard() {
    return Column(
      children: [
        AppCard(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Group items into sections',
                          style: AppTextStyles.rowTitle.copyWith(fontSize: 14.5)),
                      const SizedBox(height: 2),
                      Text('Organize big jobs into labeled phases.',
                          style: AppTextStyles.caption
                              .copyWith(fontSize: 12, height: 1.45)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Switch(
                  value: _groupSections,
                  onChanged: (v) => setState(() => _groupSections = v),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_groupSections) ...[
          for (final section in _sections)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _sectionCard(section),
            ),
          AppCard(
            child: _AddRow(
              icon: Icons.segment,
              label: 'Add section',
              onTap: () => setState(() => _sections.add(SectionDraft())),
            ),
          ),
        ] else
          AppCard(
            child: Column(
              children: [
                _reorderableItems(_items),
                _AddRow(
                  icon: Icons.add,
                  label: 'Add line item',
                  onTap: () => setState(() => _items.add(LineItemDraft())),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _sectionCard(SectionDraft section) {
    final items = _itemsOf(section);
    final total = items.fold<double>(0, (t, i) => t + i.total);
    final count = items.length;
    final countLabel =
        count == 0 ? 'No items yet' : '$count item${count == 1 ? '' : 's'}';
    final name = section.name.text.trim();
    final firstName =
        items.map((i) => i.name.trim()).firstWhere((n) => n.isNotEmpty, orElse: () => '');

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: _sectionBg,
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            child: Row(
              children: [
                IconButton(
                  tooltip: section.collapsed ? 'Expand' : 'Collapse',
                  onPressed: () =>
                      setState(() => section.collapsed = !section.collapsed),
                  icon: AnimatedRotation(
                    turns: section.collapsed ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: const Icon(Icons.keyboard_arrow_up,
                        color: AppColors.ink),
                  ),
                ),
                Expanded(
                  child: section.collapsed
                      ? InkWell(
                          onTap: () => setState(() => section.collapsed = false),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name.isEmpty ? 'Untitled section' : name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.headingMedium
                                      .copyWith(fontSize: 18)),
                              Text(
                                  firstName.isEmpty
                                      ? countLabel
                                      : '$countLabel · $firstName',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.caption),
                            ],
                          ),
                        )
                      : TextField(
                          controller: section.name,
                          onChanged: (_) => setState(() {}),
                          textCapitalization: TextCapitalization.sentences,
                          style: AppTextStyles.headingMedium
                              .copyWith(fontSize: 17),
                          decoration: InputDecoration(
                            hintText: 'Section name — e.g. Kitchen',
                            isDense: true,
                            filled: true,
                            fillColor: AppColors.card,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: AppColors.line),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                  color: AppColors.greenDeep, width: 1.5),
                            ),
                          ),
                        ),
                ),
                if (section.collapsed)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(Formatters.currency(total),
                        style: AppTextStyles.rowAmount.copyWith(fontSize: 16)),
                  ),
                if (_sections.length > 1)
                  PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, color: AppColors.ink),
                  onSelected: (v) {
                    final i = _sections.indexOf(section);
                    setState(() {
                      if (v == 'up' && i > 0) {
                        _sections.removeAt(i);
                        _sections.insert(i - 1, section);
                      } else if (v == 'down' && i < _sections.length - 1) {
                        _sections.removeAt(i);
                        _sections.insert(i + 1, section);
                      } else if (v == 'remove') {
                        _items.removeWhere((it) => _sectionOf(it) == section);
                        _sections.remove(section);
                        if (_items.isEmpty) _items.add(LineItemDraft());
                      }
                    });
                  },
                  itemBuilder: (_) => [
                    if (_sections.indexOf(section) > 0)
                      const PopupMenuItem(value: 'up', child: Text('Move up')),
                    if (_sections.indexOf(section) < _sections.length - 1)
                      const PopupMenuItem(
                          value: 'down', child: Text('Move down')),
                    if (_sections.length > 1)
                      const PopupMenuItem(
                          value: 'remove', child: Text('Remove section')),
                  ],
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: section.collapsed
                ? const SizedBox(width: double.infinity)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        color: AppColors.page,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 9),
                        decoration: null,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(countLabel, style: AppTextStyles.caption),
                            Text('Section total ${Formatters.currency(total)}',
                                style: AppTextStyles.caption.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.inkSoft)),
                          ],
                        ),
                      ),
                      _reorderableItems(items),
                      InkWell(
                        onTap: () => setState(
                            () => _items.add(LineItemDraft(section: section))),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.greenTint,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: const Icon(Icons.add,
                                    size: 16, color: AppColors.greenDeep),
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Text(
                                  name.isEmpty
                                      ? 'Add line item'
                                      : 'Add line item to $name',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.rowTitle.copyWith(
                                      fontSize: 14.5,
                                      color: AppColors.greenDeep),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  /// Line-item rows for [group] with drag-to-reorder (within the group).
  Widget _reorderableItems(List<LineItemDraft> group) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: group.length,
      onReorderItem: (oldIndex, newIndex) {
        setState(() {
          // Reorder the group, then write it back into the same slots of the
          // flat list so other sections are unaffected.
          final slots = [for (final it in group) _items.indexOf(it)]..sort();
          final reordered = [...group];
          reordered.insert(newIndex, reordered.removeAt(oldIndex));
          for (var k = 0; k < slots.length; k++) {
            _items[slots[k]] = reordered[k];
          }
        });
      },
      itemBuilder: (context, k) => KeyedSubtree(
        key: ValueKey('row-${group[k].uid}'),
        child: _lineItemRow(group[k], k),
      ),
    );
  }

  Widget _lineItemRow(LineItemDraft item, int dragIndex) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ReorderableDragStartListener(
                index: dragIndex,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Icon(Icons.drag_indicator,
                      size: 20, color: AppColors.inkFaint),
                ),
              ),
              Expanded(
                child: TextFormField(
                  key: ValueKey('name-${item.uid}-${item.rev}'),
                  initialValue: item.name,
                  onChanged: (v) => setState(() => item.name = v),
                  textCapitalization: TextCapitalization.sentences,
                  style: AppTextStyles.rowTitle
                      .copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(
                    hintText: 'Item or service name',
                    isDense: true,
                    filled: false,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(Formatters.currency(item.total),
                  style: AppTextStyles.rowAmount.copyWith(fontSize: 16)),
              const SizedBox(width: 6),
              InkWell(
                onTap: () => setState(() => _items.remove(item)),
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.delete_outline,
                      size: 18, color: AppColors.inkSoft),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                _notesBlock(item),
                const SizedBox(height: 12),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.end,
                  runSpacing: 8,
                  children: [
                    _labeled(
                      'QTY',
                      _numField(
                        initial: item.qty.toString(),
                        onChanged: (v) => setState(
                            () => item.qty = int.tryParse(v)?.abs() ?? 0),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(8, 0, 8, 8),
                      child: Text('×', style: AppTextStyles.caption),
                    ),
                    _labeled(
                      'RATE',
                      _numField(
                        key: ValueKey('price-${item.uid}-${item.rev}'),
                        initial: item.price == 0 ? '' : item.price.toString(),
                        hintText: '\$0.00',
                        prefixText: '\$',
                        onChanged: (v) => setState(
                            () => item.price = double.tryParse(v)?.abs() ?? 0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ChipButton(
                      icon: Icons.list_alt_outlined,
                      label: 'Item list',
                      onTap: () => _pickCatalogItem(_items.indexOf(item)),
                    ),
                    _ChipButton(
                      icon: Icons.trending_up,
                      label: item.markup.hasMarkup
                          ? 'Markup ${item.markup.displayRate}'
                          : 'Markup',
                      active: item.markup.hasMarkup,
                      onTap: () => _pickItemMarkup(item),
                    ),
                    _ChipButton(
                      icon: Icons.photo_camera_outlined,
                      label: 'Photos ${item.photoCount}/${LineItemDraft.maxPhotos}',
                      active: item.photoCount > 0,
                      onTap: () => _addLineItemPhoto(item),
                    ),
                  ],
                ),
                if (item.photoCount > 0) ...[
                  const SizedBox(height: 12),
                  _photosBlock(item),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _labeled(String label, Widget field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.caption.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: AppColors.inkSoft)),
          const SizedBox(height: 4),
          field,
        ],
      );

  // ---- Line-item description ------------------------------------------

  Future<void> _editNotes(LineItemDraft item) async {
    final result = await context.push<String>(
      AppRoutes.descriptionEditor,
      extra: {
        'itemName': item.name,
        'text': item.notes,
        'documentLabel': widget.isInvoice ? 'invoice' : 'estimate',
      },
    );
    if (result != null && mounted) setState(() => item.notes = result);
  }

  Widget _notesBlock(LineItemDraft item) {
    final text = item.notes.trim();
    if (text.isEmpty) {
      return InkWell(
        onTap: () => _editNotes(item),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.page,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              const Icon(Icons.notes, size: 18, color: AppColors.inkSoft),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Add description or notes (optional)',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.inkSoft)),
              ),
              const Icon(Icons.open_in_full,
                  size: 16, color: AppColors.inkSoft),
            ],
          ),
        ),
      );
    }
    final lines = '\n'.allMatches(text).length + 1;
    final long = lines > 3 || text.length > 170;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _editNotes(item),
          child: Text(
            text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium
                .copyWith(fontSize: 14.5, height: 1.45, color: AppColors.inkSoft),
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: AppColors.greenTint,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _editNotes(item),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(long ? 'Read all · $lines lines' : 'Edit description',
                      style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.greenDeep)),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right,
                      size: 16, color: AppColors.greenDeep),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---- Line-item photos -------------------------------------------------

  Future<void> _addLineItemPhoto(LineItemDraft item) async {
    if (item.photoCount >= LineItemDraft.maxPhotos) return;
    final source = await _showPhotoSourceSheet();
    if (source == null) return;
    final file = await _imagePicker.pickImage(source: source, imageQuality: 85);
    if (file == null || !mounted) return;
    setState(() => item.photos.add(file));
  }

  Widget _photosBlock(LineItemDraft item) {
    Widget thumb(Widget image, {VoidCallback? onRemove}) => Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(width: 72, height: 72, child: image),
            ),
            if (onRemove != null)
              Positioned(
                top: -6,
                right: -6,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                        color: AppColors.ink, shape: BoxShape.circle),
                    child: const Icon(Icons.close,
                        size: 13, color: Colors.white),
                  ),
                ),
              ),
          ],
        );

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final url in item.existingPhotoUrls)
          thumb(Image.network(url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                  color: AppColors.grayTint,
                  child: const Icon(Icons.image_outlined,
                      color: AppColors.inkSoft)))),
        for (final file in item.photos)
          thumb(
            Image.file(File(file.path),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                    color: AppColors.grayTint,
                    child: const Icon(Icons.image_outlined,
                        color: AppColors.inkSoft))),
            onRemove: () => setState(() => item.photos.remove(file)),
          ),
      ],
    );
  }

  Widget _numField({
    Key? key,
    required String initial,
    required ValueChanged<String> onChanged,
    String? hintText,
    String? prefixText,
  }) {
    return SizedBox(
      width: prefixText != null ? 78 : 64,
      child: TextFormField(
        key: key,
        initialValue: initial,
        onChanged: onChanged,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: AppTextStyles.bodySmall,
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: AppColors.page,
          hintText: hintText,
          prefixText: prefixText,
          prefixStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.inkFaint),
          hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.inkFaint),
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
  ];

  // Discount, Tax, Markup and Request deposit stay visible after being added —
  // tapping them again reopens the picker to change the selection.
  static const _alwaysShownAdjustments = {
    'discount',
    'tax',
    'markup',
    'deposit',
  };

  Widget _adjustChips() {
    final available = _adjustments.where((a) =>
        _alwaysShownAdjustments.contains(a.$1) ||
        !_activeAdjustments.contains(a.$1));
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
              active: _adjustmentActive(adj.$1),
              icon: _adjustmentActive(adj.$1) ? Icons.check : Icons.add,
              onTap: () => _handleAdjustmentTap(adj.$1),
            ),
        ],
      ),
    );
  }

  /// Markup isn't stored in [_activeAdjustments] — it lives on the line items
  /// — so it counts as applied whenever the rows carry any markup.
  bool _adjustmentActive(String key) => key == 'markup'
      ? _markupTotal > 0
      : _activeAdjustments.contains(key);

  void _handleAdjustmentTap(String key) {
    switch (key) {
      case 'discount':
        _pickDiscount();
      case 'tax':
        _pickTax();
      case 'markup':
        _pickDocMarkup();
      case 'deposit':
        _pickDeposit();
      default:
        setState(() => _activeAdjustments.add(key));
    }
  }

  Future<void> _pickDiscount() async {
    final result = await showModalBottomSheet<(AmountType, double)>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _AmountPickerSheet(
        title: 'Discount',
        amountLabel: 'Discount Amount',
        initialType: _discountType,
        initialValue: _discount,
      ),
    );
    if (result == null) return;
    setState(() {
      _discountType = result.$1;
      _discount = result.$2;
      _activeAdjustments.add('discount');
    });
  }

  Future<void> _pickDeposit() async {
    final result = await showModalBottomSheet<(AmountType, double)>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _AmountPickerSheet(
        title: 'Request Deposit',
        amountLabel: 'Deposit Amount',
        initialType: _depositType,
        initialValue: _depositValue,
      ),
    );
    if (result == null) return;
    setState(() {
      _depositType = result.$1;
      _depositValue = result.$2;
      _activeAdjustments.add('deposit');
    });
  }

  Future<void> _pickTax() async {
    final proId = _proId;
    if (proId == null) return;
    final picked = await showModalBottomSheet<TaxRate>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) =>
          _TaxPickerSheet(proId: proId, selectedId: _taxId),
    );
    if (picked == null) return;
    setState(() {
      if (picked.id == kCustomPickId) {
        // "Custom amount" — detach from any preset, keep the current rate
        // (or 0 on first activation) so the row is just manually editable.
        _taxId = null;
        _taxName = null;
      } else {
        _taxId = picked.id;
        _taxName = picked.name;
        _taxPct = picked.rate;
      }
      _taxRev++;
      _activeAdjustments.add('tax');
    });
  }

  /// Document markup: always an amount (percentage or fixed). It isn't kept
  /// as its own value — it's split equally across every line item's markup,
  /// replacing whatever markups the rows had.
  Future<void> _pickDocMarkup() async {
    final current = _markupTotal;
    final result = await showModalBottomSheet<(AmountType, double)>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _AmountPickerSheet(
        title: 'Markup',
        amountLabel: 'Markup Amount',
        initialType: AmountType.fixed,
        initialValue: double.parse(current.toStringAsFixed(2)),
      ),
    );
    if (result == null || !mounted) return;
    final amount = result.$1 == AmountType.percent
        ? _subtotal * result.$2 / 100
        : result.$2;
    setState(() => _splitMarkup(amount));
  }

  /// Gives every line item an equal fixed share of [amount] (cents-rounded,
  /// the last row absorbing the remainder). Zero clears all markups.
  void _splitMarkup(double amount) {
    _legacyMarkup = 0;
    final n = _items.length;
    if (amount <= 0 || n == 0) {
      for (final it in _items) {
        it.markup = ItemMarkup.none;
      }
      return;
    }
    final total = double.parse(amount.toStringAsFixed(2));
    final share = double.parse((total / n).toStringAsFixed(2));
    var assigned = 0.0;
    for (var i = 0; i < n; i++) {
      final value = i == n - 1
          ? double.parse((total - assigned).toStringAsFixed(2))
          : share;
      assigned += value;
      _items[i].markup = value > 0
          ? ItemMarkup(name: 'Markup', type: MarkupType.flat, rate: value)
          : ItemMarkup.none;
    }
  }

  Future<void> _pickItemMarkup(LineItemDraft item) async {
    final proId = _proId;
    if (proId == null) return;
    final picked = await showModalBottomSheet<MarkupTemplate>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _MarkupPickerSheet(
        proId: proId,
        allowRemove: item.markup.hasMarkup,
      ),
    );
    if (picked == null || !mounted) return;
    if (picked.id == kRemoveMarkupId) {
      setState(() => item.markup = ItemMarkup.none);
    } else if (picked.id == kCustomPickId) {
      final custom = await _askCustomMarkup(item.markup);
      if (custom != null && mounted) setState(() => item.markup = custom);
    } else {
      setState(() => item.markup = ItemMarkup(
          name: picked.name, type: picked.type, rate: picked.rate));
    }
  }

  /// One-off markup for a single line item: percentage or fixed amount.
  Future<ItemMarkup?> _askCustomMarkup(ItemMarkup current) {
    var type = current.hasMarkup ? current.type : MarkupType.percent;
    final controller = TextEditingController(
        text: current.hasMarkup ? _trimmed(current.rate) : '');
    return showDialog<ItemMarkup>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Custom markup'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<MarkupType>(
                segments: const [
                  ButtonSegment(
                      value: MarkupType.percent, label: Text('Percentage')),
                  ButtonSegment(value: MarkupType.flat, label: Text('Fixed')),
                ],
                selected: {type},
                onSelectionChanged: (v) =>
                    setDialogState(() => type = v.first),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  prefixText: type == MarkupType.flat ? '\$ ' : null,
                  suffixText: type == MarkupType.percent ? '%' : null,
                  hintText: '0',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                final v = double.tryParse(controller.text) ?? 0;
                Navigator.of(ctx).pop(v > 0
                    ? ItemMarkup(name: 'Markup', type: type, rate: v)
                    : ItemMarkup.none);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    ).whenComplete(controller.dispose);
  }

  Widget _totalsCard() {
    return AppCard(
      child: Column(
        children: [
          _totalRow(
            'Subtotal',
            value: Text(Formatters.currency(_subtotal),
                style: AppTextStyles.labelMedium.copyWith(fontSize: 14)),
            showDivider: _activeAdjustments.isNotEmpty || _markupTotal > 0,
          ),
          if (_markupTotal > 0)
            _totalRow(
              'Markup',
              showDivider: _activeAdjustments.isNotEmpty,
              value: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('+${Formatters.currency(_markupTotal)}',
                      style:
                          AppTextStyles.labelMedium.copyWith(fontSize: 13.5)),
                  // Removing it clears the markup from every line item.
                  InkWell(
                    onTap: () => setState(() {
                      for (final it in _items) {
                        it.markup = ItemMarkup.none;
                      }
                      _legacyMarkup = 0;
                    }),
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close,
                          size: 13, color: AppColors.inkFaint),
                    ),
                  ),
                ],
              ),
            ),
          if (_activeAdjustments.contains('discount'))
            _totalRow(
              'Discount',
              showDivider: 'discount' != _activeAdjustments.last,
              value: InkWell(
                onTap: _pickDiscount,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _discountType == AmountType.percent
                            ? '−${_trimmed(_discount)}%'
                            : '−${Formatters.currency(_discount)}',
                        style: AppTextStyles.labelMedium
                            .copyWith(fontSize: 13.5),
                      ),
                      _removeAdjustment('discount'),
                    ],
                  ),
                ),
              ),
            ),
          if (_activeAdjustments.contains('tax'))
            _adjustInputRow(
              _taxName != null ? 'Tax ($_taxName)' : 'Tax',
              key: 'tax',
              subLabel: _taxAmount > 0
                  ? '= ${Formatters.currency(_taxAmount)} on this total'
                  : null,
              fieldKey: ValueKey('tax-field-$_taxRev'),
              suffix: '%',
              initial: _taxPct,
              onChanged: (v) => _taxPct = v,
            ),
          if (_activeAdjustments.contains('deposit'))
            _totalRow(
              'Deposit due upfront',
              showDivider: 'deposit' != _activeAdjustments.last,
              value: InkWell(
                onTap: _pickDeposit,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _depositType == AmountType.percent
                            ? '${_trimmed(_depositValue)}%'
                            : Formatters.currency(_depositValue),
                        style: AppTextStyles.labelMedium
                            .copyWith(fontSize: 13.5),
                      ),
                      _removeAdjustment('deposit'),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _trimmed(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  Widget _totalRow(String label,
      {required Widget value, bool showDivider = true, String? subLabel}) {
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
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.inkSoft, height: 1.2)),
                if (subLabel != null)
                  Text(subLabel,
                      style: AppTextStyles.caption
                          .copyWith(fontSize: 12, color: AppColors.greenDeep)),
              ],
            ),
          ),
          const SizedBox(width: 8),
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
    Key? fieldKey,
    String? subLabel,
  }) {
    final isLast = key == _activeAdjustments.last;
    return _totalRow(
      label,
      subLabel: subLabel,
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
              key: fieldKey,
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
      onTap: () => setState(() {
        _activeAdjustments.remove(key);
        if (key == 'discount') {
          _discountType = AmountType.fixed;
          _discount = 0;
        } else if (key == 'tax') {
          _taxId = null;
          _taxName = null;
          _taxPct = 0;
        } else if (key == 'deposit') {
          _depositType = AmountType.percent;
          _depositValue = 25;
        }
      }),
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
            subtitle: _attachmentsSummary,
            open: _openBlocks.contains('attachments'),
            onToggle: _toggleBlock,
            body: Column(
              children: [
                _InnerValueRow(
                  label: 'Photos',
                  value: _photos.isEmpty && _existingPhotos.isEmpty
                      ? 'Add'
                      : '${_existingPhotos.length + _photos.length}',
                  onTap: _openPhotosSheet,
                ),
                _InnerValueRow(
                  label: 'Files',
                  value: _files.isEmpty && _existingFiles.isEmpty
                      ? 'Add'
                      : '${_existingFiles.length + _files.length}',
                  onTap: _openFilesSheet,
                ),
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
            subtitle: _notesSummary,
            open: _openBlocks.contains('notes'),
            onToggle: _toggleBlock,
            body: Column(
              children: [
                _NoteEntryRow(
                  label: 'Notes for client',
                  text: _notes,
                  onTap: () => _pickNotes(isPrivate: false),
                ),
                _NoteEntryRow(
                  label: 'Private notes',
                  text: _privateNotes,
                  onTap: () => _pickNotes(isPrivate: true),
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

  // ---- Photos and attachments ------------------------------------------

  String get _attachmentsSummary {
    final photoCount = _existingPhotos.length + _photos.length;
    final fileCount = _existingFiles.length + _files.length;
    if (photoCount == 0 && fileCount == 0) return 'None added';
    final parts = <String>[
      if (photoCount > 0) '$photoCount photo${photoCount == 1 ? '' : 's'}',
      if (fileCount > 0) '$fileCount file${fileCount == 1 ? '' : 's'}',
    ];
    return parts.join(' · ');
  }

  Future<ImageSource?> _showPhotoSourceSheet() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 36),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: AppColors.greenDeep),
              title: Text('Take photo', style: AppTextStyles.rowTitle),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.greenDeep),
              title: Text('Choose from library', style: AppTextStyles.rowTitle),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPhotosSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          Future<void> addPhoto() async {
            final source = await _showPhotoSourceSheet();
            if (source == null) return;
            final file =
                await _imagePicker.pickImage(source: source, imageQuality: 85);
            if (file == null) return;
            setSheetState(() => _photos.add(file));
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.grabber,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text('Photos',
                      style: AppTextStyles.headingSmall.copyWith(fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(
                    'Add jobsite photos so your client can see the work.',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final p in _existingPhotos)
                        UploadedPhotoThumb(photo: p),
                      for (var i = 0; i < _photos.length; i++)
                        _StagedPhotoThumb(
                          file: _photos[i],
                          onRemove: () =>
                              setSheetState(() => _photos.removeAt(i)),
                        ),
                      _AddAttachmentTile(
                        icon: Icons.add_a_photo_outlined,
                        onTap: addPhoto,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (mounted) setState(() {});
  }

  Future<List<PlatformFile>> _pickFiles() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: kAttachmentExtensions,
    );
    if (result == null) return const [];

    final accepted = <PlatformFile>[];
    final tooLarge = <String>[];
    for (final f in result.files) {
      if (f.size > kMaxAttachmentBytes) {
        tooLarge.add(f.name);
      } else {
        accepted.add(f);
      }
    }
    if (tooLarge.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${tooLarge.join(', ')} '
            '${tooLarge.length == 1 ? 'is' : 'are'} over the 25MB limit and '
            '${tooLarge.length == 1 ? 'was' : 'were'} skipped.',
          ),
          backgroundColor: AppColors.orangeDeep,
        ),
      );
    }
    return accepted;
  }

  Future<void> _openFilesSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.grabber,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text('Files',
                        style:
                            AppTextStyles.headingSmall.copyWith(fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(
                      'PDF, Word, Excel, CSV, CAD, or image files — up to 25MB each.',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: _files.isEmpty && _existingFiles.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Text('No files added yet.',
                                  style: AppTextStyles.caption),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: _existingFiles.length + _files.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1, color: AppColors.line),
                              itemBuilder: (context, idx) {
                                if (idx < _existingFiles.length) {
                                  return UploadedFileRow(
                                      file: _existingFiles[idx]);
                                }
                                final i = idx - _existingFiles.length;
                                final f = _files[i];
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  child: Row(
                                    children: [
                                      Icon(iconForFileExtension(f.extension),
                                          size: 20, color: AppColors.inkSoft),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              f.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTextStyles.rowTitle
                                                  .copyWith(fontSize: 14),
                                            ),
                                            Text(formatFileSize(f.size),
                                                style: AppTextStyles.caption),
                                          ],
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () => setSheetState(
                                            () => _files.removeAt(i)),
                                        borderRadius: BorderRadius.circular(6),
                                        child: const Padding(
                                          padding: EdgeInsets.all(4),
                                          child: Icon(Icons.close,
                                              size: 16,
                                              color: AppColors.inkFaint),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await _pickFiles();
                        if (picked.isNotEmpty) {
                          setSheetState(() => _files.addAll(picked));
                        }
                      },
                      icon: const Icon(Icons.attach_file, size: 17),
                      label: const Text('Add file'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    if (mounted) setState(() {});
  }

  /// Best-effort: the estimate/invoice itself is already saved by the time
  /// this runs, so a failed attachment upload doesn't block navigating away
  /// — it's just logged and surfaced as a warning.
  Future<int> _uploadStagedAttachments(String documentPublicId) async {
    var failures = 0;
    for (final photo in _photos) {
      final result = widget.isInvoice
          ? await Injection.invoiceRepository
              .uploadPhoto(documentPublicId, photo.path)
          : await Injection.estimateRepository
              .uploadPhoto(documentPublicId, photo.path);
      result.fold((_) => failures++, (_) {});
    }
    for (final file in _files) {
      final path = file.path;
      if (path == null) {
        failures++;
        continue;
      }
      final result = widget.isInvoice
          ? await Injection.invoiceRepository
              .uploadFile(documentPublicId, path)
          : await Injection.estimateRepository
              .uploadFile(documentPublicId, path);
      result.fold((_) => failures++, (_) {});
    }
    return failures;
  }

  /// Uploads staged per-line-item photos. The save response doesn't reliably
  /// carry line-item ids, so the document is re-fetched and items matched by
  /// the sortOrder they were saved with.
  Future<int> _uploadLineItemPhotos(String publicId, int docId) async {
    final pending = [
      for (final it in _items)
        if (it.photos.isNotEmpty && _savedOrder.containsKey(it)) it,
    ];
    if (pending.isEmpty) return 0;

    final saved = <int, int>{}; // sortOrder → lineItemId
    if (widget.isInvoice) {
      final r = await Injection.invoiceRepository.fetchInvoiceDetail(docId);
      r.fold((_) {}, (inv) {
        for (final li in inv.allLineItems) {
          saved[li.sortOrder] = li.lineItemId;
        }
      });
    } else {
      final r = await Injection.estimateRepository.fetchEstimateDetail(docId);
      r.fold((_) {}, (est) {
        for (final li in est.allLineItems) {
          saved[li.sortOrder] = li.lineItemId;
        }
      });
    }

    var failures = 0;
    for (final it in pending) {
      final lineItemId = saved[_savedOrder[it]];
      if (lineItemId == null) {
        failures += it.photos.length;
        continue;
      }
      for (final photo in it.photos) {
        final r = widget.isInvoice
            ? await Injection.invoiceRepository
                .uploadLineItemPhoto(publicId, lineItemId, photo.path)
            : await Injection.estimateRepository
                .uploadLineItemPhoto(publicId, lineItemId, photo.path);
        r.fold((_) => failures++, (_) {});
      }
    }
    return failures;
  }

  // ---- Notes ------------------------------------------------------------

  String get _notesSummary {
    final hasNotes = (_notes ?? '').trim().isNotEmpty;
    final hasPrivate = (_privateNotes ?? '').trim().isNotEmpty;
    if (!hasNotes && !hasPrivate) return 'None added';
    final parts = <String>[
      if (hasNotes) 'Client note added',
      if (hasPrivate) 'Private note added',
    ];
    return parts.join(' · ');
  }

  Future<void> _pickNotes({required bool isPrivate}) async {
    final current = isPrivate ? _privateNotes : _notes;
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _NotesSheet(
        title: isPrivate ? 'Private Notes' : 'Notes for Client',
        hint: isPrivate
            ? 'Only visible to you — reminders, job details, anything you don\'t want the client to see.'
            : 'Shown on the document — payment instructions, scope clarifications, a thank-you note.',
        initialText: current ?? '',
      ),
    );
    if (result == null) return;
    setState(() {
      final trimmed = result.trim();
      if (isPrivate) {
        _privateNotes = trimmed.isEmpty ? null : trimmed;
      } else {
        _notes = trimmed.isEmpty ? null : trimmed;
      }
    });
  }

  // ---- Client picker -------------------------------------------------

  int? get _proId {
    final authState = context.read<AuthBloc>().state;
    return authState is AuthAuthenticated ? authState.user.proId : null;
  }

  Future<void> _pickClient() async {
    final proId = _proId;
    if (proId == null) return;
    final picked = await showModalBottomSheet<Client>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _ClientPickerSheet(proId: proId),
    );
    if (picked != null) setState(() => _selectedClient = picked);
  }

  // ---- Catalog item picker --------------------------------------------

  Future<void> _pickCatalogItem(int index) async {
    final proId = _proId;
    if (proId == null) return;
    final picked = await showModalBottomSheet<Item>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _ItemPickerSheet(proId: proId),
    );
    if (picked == null) return;
    setState(() {
      final draft = _items[index];
      draft.name = picked.name;
      if (picked.unitPrice != null) draft.price = picked.unitPrice!;
      draft.catalogItemId = picked.itemId;
      // The catalog item's own description and markup win over what the row
      // already had; without them the row keeps its notes and has no markup.
      if ((picked.description ?? '').trim().isNotEmpty) {
        draft.notes = picked.description!.trim();
      }
      draft.markup = picked.markup;
      draft.rev++;
    });
  }

  // ---- Submit -------------------------------------------------------

  void _submit() {
    final proId = _proId;
    if (proId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in again.')),
      );
      return;
    }
    if (_selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a client before saving.')),
      );
      return;
    }

    final base = widget.estimateToEdit;
    final estimateDate = base?.estimateDate ?? DateTime.now();

    // Group the rows by section. A named section (grouping on) becomes an
    // API section; unnamed groups are sent as loose line items. A section
    // that already exists on the API is referenced by id (flat line items
    // carry `sectionId`, matching the GET shape); a new one has its line items
    // nested inside it.
    var order = 0;
    _savedOrder.clear();
    final lineItems = <EstimateLineItem>[]; // top-level line items
    final sections = <EstimateSection>[];
    for (final sec in _sections) {
      final name = _groupSections ? sec.name.text.trim() : '';
      final rows = [
        for (final it in _items)
          if (_sectionOf(it) == sec &&
              !(it.name.trim().isEmpty && it.price == 0))
            it,
      ];
      if (rows.isEmpty) continue;
      final named = name.isNotEmpty;
      final existing = named && sec.existingId != 0;
      final built = [
        for (final it in rows)
          EstimateLineItem(
            lineItemId: it.existingId,
            sectionId: existing ? sec.existingId : null,
            catalogLineItemId: it.catalogItemId,
            description: it.name.trim(),
            // Clearing the text on a saved item sends '' so the API drops it.
            notes: it.notes.trim().isNotEmpty
                ? it.notes
                : (it.existingId != 0 ? '' : null),
            unitPrice: it.price,
            quantity: it.qty,
            total: it.total,
            sortOrder: _savedOrder[it] = order++,
            isTaxable: _activeAdjustments.contains('tax'),
            markupType: it.markup.hasMarkup ? it.markup.apiType : null,
            markupValue: it.markup.hasMarkup ? it.markup.rate : null,
          ),
      ];
      final nest = named && !existing;
      if (named) {
        sections.add(EstimateSection(
          sectionId: sec.existingId,
          name: name,
          sortOrder: sections.length,
          subtotal: built.fold<double>(0, (t, li) => t + li.total),
          lineItems: nest ? built : const [],
        ));
      }
      if (!nest) lineItems.addAll(built);
    }

    final markupTotal = _markupTotal;
    final discountActive =
        _activeAdjustments.contains('discount') && _discount > 0;
    final taxActive = _activeAdjustments.contains('tax') && _taxPct > 0;
    final depositActive =
        _activeAdjustments.contains('deposit') && _depositValue > 0;

    if (widget.isInvoice) {
      _submitInvoice(
        proId: proId,
        lineItems: lineItems,
        sections: sections,
        markupTotal: markupTotal,
        discountActive: discountActive,
        taxActive: taxActive,
        depositActive: depositActive,
      );
      return;
    }

    final estimate = Estimate(
      estimateId: base?.estimateId ?? 0,
      publicId: base?.publicId,
      proId: proId,
      clientId: _selectedClient!.clientId,
      clientName: _selectedClient!.name,
      estimateNumber: base?.estimateNumber ??
          (widget.documentNumber > 0
              ? widget.documentNumber.toString()
              : null),
      estimateDate: estimateDate,
      expirationDate: _allowExpire
          ? estimateDate.add(Duration(days: _validDays))
          : base?.expirationDate,
      groupItemsIntoSections: _groupSections,
      subtotal: _subtotal,
      // Row markups added up, as one fixed amount for the totals section.
      markupType: markupTotal > 0 ? AmountType.fixed.apiValue : null,
      markupValue: markupTotal > 0 ? markupTotal : null,
      discountType: discountActive ? _discountType.apiValue : null,
      discountValue: discountActive ? _discount : null,
      depositType: depositActive ? _depositType.apiValue : null,
      depositValue: depositActive ? _depositValue : null,
      taxName: taxActive ? (_taxName ?? base?.taxName ?? 'Tax') : null,
      taxRate: taxActive ? _taxPct : null,
      total: _total,
      showClientSignature: _clientSignature,
      showMySignature: _mySignature,
      notes: _notes,
      privateNotes: _privateNotes,
      status: base?.status,
      isApproved: base?.isApproved,
      isActive: true,
      lineItems: lineItems,
      sections: sections,
    );

    setState(() => _submitting = true);
    final bloc = context.read<EstimateBloc>();
    bloc.add(base != null
        ? EstimateUpdateRequested(estimate)
        : EstimateCreateRequested(estimate));
  }

  /// "Due on receipt" → 0, "Net 30" → 30.
  int get _daysToPay =>
      int.tryParse(_paymentTerms.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  void _submitInvoice({
    required int proId,
    required List<EstimateLineItem> lineItems,
    required List<EstimateSection> sections,
    required double markupTotal,
    required bool discountActive,
    required bool taxActive,
    required bool depositActive,
  }) {
    final base = widget.invoiceToEdit;
    InvoiceLineItem toItem(EstimateLineItem li) => InvoiceLineItem(
          lineItemId: li.lineItemId,
          sectionId: li.sectionId,
          description: li.description,
          notes: li.notes,
          markupType: li.markupType,
          markupValue: li.markupValue,
          unitPrice: li.unitPrice,
          quantity: li.quantity,
          total: li.total,
          sortOrder: li.sortOrder,
          isTaxable: li.isTaxable,
        );
    final invoice = Invoice(
      invoiceId: base?.invoiceId ?? 0,
      publicId: base?.publicId,
      status: base?.status,
      sentDate: base?.sentDate,
      viewedDate: base?.viewedDate,
      paidDate: base?.paidDate,
      poNumber: base?.poNumber,
      proId: proId,
      clientId: _selectedClient!.clientId,
      clientName: _selectedClient!.name,
      invoiceNumber: base?.invoiceNumber ??
          (widget.documentNumber > 0 ? widget.documentNumber.toString() : null),
      invoiceDate: base?.invoiceDate ?? DateTime.now(),
      daysToPay: _daysToPay,
      groupItemsIntoSections: _groupSections,
      subtotal: _subtotal,
      // Row markups added up, as one fixed amount for the totals section.
      markupType: markupTotal > 0 ? AmountType.fixed.apiValue : null,
      markupValue: markupTotal > 0 ? markupTotal : null,
      discountType: discountActive ? _discountType.apiValue : null,
      discountValue: discountActive ? _discount : null,
      depositType: depositActive ? _depositType.apiValue : null,
      depositValue: depositActive ? _depositValue : null,
      taxName: taxActive ? (_taxName ?? 'Tax') : null,
      taxRate: taxActive ? _taxPct : null,
      total: _total,
      showClientSignature: _clientSignature,
      showMySignature: _mySignature,
      notes: _notes,
      privateNotes: _privateNotes,
      lineItems: lineItems.map(toItem).toList(),
      sections: [
        for (final sec in sections)
          InvoiceSection(
            sectionId: sec.sectionId,
            name: sec.name,
            sortOrder: sec.sortOrder,
            subtotal: sec.subtotal,
            lineItems: sec.lineItems.map(toItem).toList(),
          ),
      ],
    );

    setState(() => _submitting = true);
    final bloc = context.read<InvoiceBloc>();
    bloc.add(base != null
        ? InvoiceUpdateRequested(invoice)
        : InvoiceCreateRequested(invoice));
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
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 14),
                  textStyle: AppTextStyles.buttonText.copyWith(fontSize: 15),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_isEdit ? 'Save changes' : 'Preview and send'),
                    const SizedBox(width: 7),
                    const Icon(Icons.arrow_forward, size: 15),
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

/// NEW plan pill shown next to new features.
class PlanPill extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

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
  final VoidCallback onTap;

  const _AddRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.showChevron = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
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
  final IconData icon;

  /// Tints the chip green when the adjustment it represents is already
  /// applied — it stays tappable (to change/increment the selection).
  final bool active;

  const _ChipButton({
    required this.label,
    required this.onTap,
    this.icon = Icons.add,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = active ? AppColors.greenDeep : AppColors.inkSoft;
    return Material(
      color: active ? AppColors.greenTint : AppColors.card,
      shape: StadiumBorder(
        side: BorderSide(color: active ? AppColors.greenDeep : AppColors.line),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: fg),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTextStyles.bodySmall
                    .copyWith(fontWeight: FontWeight.w600, color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thumbnail for a staged local photo (not yet uploaded), with a remove
/// badge.
class _StagedPhotoThumb extends StatelessWidget {
  final XFile file;
  final VoidCallback onRemove;

  const _StagedPhotoThumb({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            File(file.path),
            width: 76,
            height: 76,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 76,
              height: 76,
              color: AppColors.grayTint,
              child: const Icon(Icons.broken_image_outlined,
                  size: 18, color: AppColors.inkFaint),
            ),
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: AppColors.ink,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 13, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

/// Dashed-style tile that opens the add-photo flow, matched to
/// [_StagedPhotoThumb]'s size so it sits inline in the same [Wrap].
class _AddAttachmentTile extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _AddAttachmentTile({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          color: AppColors.page,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.line),
        ),
        child: Icon(icon, size: 22, color: AppColors.greenDeep),
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
  final VoidCallback onTap;

  const _InnerValueRow({
    required this.label,
    required this.value,
    required this.onTap,
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

/// Like [_InnerValueRow], but for a note field: shows the note's own text
/// inline (so expanding the block is enough to read it — no extra sheet
/// needed) instead of just a generic "Add"/value label.
class _NoteEntryRow extends StatelessWidget {
  final String label;
  final String? text;
  final VoidCallback onTap;

  const _NoteEntryRow({
    required this.label,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasText = (text ?? '').trim().isNotEmpty;
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(label,
                            style: AppTextStyles.labelMedium
                                .copyWith(fontSize: 13.5)),
                      ),
                    ],
                  ),
                ),
                Text(
                  hasText ? 'Edit' : 'Add',
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
            if (hasText) ...[
              const SizedBox(height: 6),
              Text(
                text!.trim(),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.inkSoft, height: 1.4),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet that loads the pro's clients and returns the picked one.
class _ClientPickerSheet extends StatefulWidget {
  final int proId;
  const _ClientPickerSheet({required this.proId});

  @override
  State<_ClientPickerSheet> createState() => _ClientPickerSheetState();
}

class _ClientPickerSheetState extends State<_ClientPickerSheet> {
  late Future<List<Client>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Client>> _load() async {
    final result =
        await Injection.clientRepository.fetchClients(widget.proId);
    return result.fold((f) => throw f.message, (clients) => clients);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.grabber,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text('Select client',
                style: AppTextStyles.headingSmall.copyWith(fontSize: 17)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                autofocus: false,
                onChanged: (v) => setState(() => _query = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search clients',
                  isDense: true,
                  prefixIcon: const Icon(Icons.search, size: 18),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.line),
                  ),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Client>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          '${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.inkSoft),
                        ),
                      ),
                    );
                  }
                  final clients = (snapshot.data ?? [])
                      .where((c) =>
                          _query.isEmpty ||
                          c.name.toLowerCase().contains(_query))
                      .toList()
                    ..sort((a, b) => a.name.compareTo(b.name));
                  if (clients.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No clients found.',
                            style: AppTextStyles.caption),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: clients.length,
                    itemBuilder: (context, i) {
                      final c = clients[i];
                      return ListTile(
                        title: Text(c.name, style: AppTextStyles.rowTitle),
                        subtitle: c.place.isEmpty
                            ? null
                            : Text(c.place, style: AppTextStyles.caption),
                        onTap: () => Navigator.of(context).pop(c),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet that loads the pro's saved catalog items (see
/// `more/screens/items_screen.dart` for the full-screen management view)
/// and returns the picked one to fill a line item's name + price.
class _ItemPickerSheet extends StatefulWidget {
  final int proId;
  const _ItemPickerSheet({required this.proId});

  @override
  State<_ItemPickerSheet> createState() => _ItemPickerSheetState();
}

class _ItemPickerSheetState extends State<_ItemPickerSheet> {
  late Future<List<Item>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Item>> _load() async {
    final result = await Injection.itemRepository.fetchItems(widget.proId);
    return result.fold((f) => throw f.message, (items) => items);
  }

  String _money(double value) {
    final hasCents = value != value.roundToDouble();
    return '\$${value.toStringAsFixed(hasCents ? 2 : 0)}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.grabber,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text('Select item',
                style: AppTextStyles.headingSmall.copyWith(fontSize: 17)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                autofocus: false,
                onChanged: (v) => setState(() => _query = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search your saved items',
                  isDense: true,
                  prefixIcon: const Icon(Icons.search, size: 18),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.line),
                  ),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Item>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          '${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.inkSoft),
                        ),
                      ),
                    );
                  }
                  final items = (snapshot.data ?? [])
                      .where((i) =>
                          _query.isEmpty ||
                          i.name.toLowerCase().contains(_query) ||
                          (i.description ?? '').toLowerCase().contains(_query))
                      .toList()
                    ..sort((a, b) => a.name.compareTo(b.name));
                  if (items.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _query.isEmpty
                              ? 'No saved items yet — add some from '
                                  'More > Items.'
                              : 'No items found.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final it = items[i];
                      return ListTile(
                        title: Text(it.name, style: AppTextStyles.rowTitle),
                        subtitle: (it.description ?? '').isNotEmpty
                            ? Text(it.description!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.caption)
                            : null,
                        trailing: it.unitPrice != null
                            ? Text(_money(it.unitPrice!),
                                style: AppTextStyles.rowAmount
                                    .copyWith(fontSize: 14))
                            : Text('Price varies',
                                style: AppTextStyles.caption.copyWith(
                                    fontSize: 12, fontWeight: FontWeight.w700)),
                        onTap: () => Navigator.of(context).pop(it),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet listing the pro's saved tax rates (see
/// `taxes/screens/taxes_screen.dart`). Picking one always replaces the
/// estimate's current tax.
class _TaxPickerSheet extends StatefulWidget {
  final int proId;
  final int? selectedId;
  const _TaxPickerSheet({required this.proId, this.selectedId});

  @override
  State<_TaxPickerSheet> createState() => _TaxPickerSheetState();
}

class _TaxPickerSheetState extends State<_TaxPickerSheet> {
  late Future<List<TaxRate>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<TaxRate>> _load() async {
    final result = await Injection.taxRepository.fetchTaxes(widget.proId);
    return result.fold((f) => throw f.message, (taxes) => taxes);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.5,
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.grabber,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text('Select tax rate',
                style: AppTextStyles.headingSmall.copyWith(fontSize: 17)),
            const SizedBox(height: 4),
            ListTile(
              leading: const Icon(Icons.edit_outlined,
                  size: 20, color: AppColors.inkSoft),
              title: Text('Custom amount', style: AppTextStyles.rowTitle),
              subtitle: Text('Enter a one-off rate for this document',
                  style: AppTextStyles.caption),
              onTap: () => Navigator.of(context).pop(
                const TaxRate(id: kCustomPickId, proId: 0, name: '', rate: 0),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<List<TaxRate>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          '${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.inkSoft),
                        ),
                      ),
                    );
                  }
                  final taxes = snapshot.data ?? [];
                  if (taxes.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No saved tax rates yet — add one from '
                          'More > Taxes.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: taxes.length,
                    itemBuilder: (context, i) {
                      final t = taxes[i];
                      final selected = t.id == widget.selectedId;
                      return ListTile(
                        leading: Icon(
                          selected
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          size: 20,
                          color: selected
                              ? AppColors.greenDeep
                              : AppColors.inkFaint,
                        ),
                        title: Text(t.name, style: AppTextStyles.rowTitle),
                        trailing: Text(t.displayRate,
                            style: AppTextStyles.rowAmount
                                .copyWith(fontSize: 14)),
                        onTap: () => Navigator.of(context).pop(t),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet listing the pro's saved markup templates (see
/// `more/screens/markups_screen.dart`). Picking a new template replaces the
/// estimate's current markup; re-picking the one already applied stacks
/// (adds) its rate instead, so a markup can be applied more than once.
class _MarkupPickerSheet extends StatefulWidget {
  final int proId;

  /// Adds a "Remove markup" row (when the line item already has one).
  final bool allowRemove;
  const _MarkupPickerSheet({required this.proId, this.allowRemove = false});

  @override
  State<_MarkupPickerSheet> createState() => _MarkupPickerSheetState();
}

class _MarkupPickerSheetState extends State<_MarkupPickerSheet> {
  late Future<List<MarkupTemplate>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<MarkupTemplate>> _load() async {
    final result = await Injection.markupRepository.fetchMarkups(widget.proId);
    return result.fold((f) => throw f.message, (markups) => markups);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.5,
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.grabber,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text('Select markup',
                style: AppTextStyles.headingSmall.copyWith(fontSize: 17)),
            const SizedBox(height: 4),
            ListTile(
              leading: const Icon(Icons.edit_outlined,
                  size: 20, color: AppColors.inkSoft),
              title: Text('Custom amount', style: AppTextStyles.rowTitle),
              subtitle: Text('Enter a one-off markup for this item',
                  style: AppTextStyles.caption),
              onTap: () => Navigator.of(context).pop(
                const MarkupTemplate(
                    id: kCustomPickId,
                    proId: 0,
                    name: '',
                    type: MarkupType.flat,
                    rate: 0),
              ),
            ),
            if (widget.allowRemove)
              ListTile(
                leading: const Icon(Icons.remove_circle_outline,
                    size: 20, color: AppColors.redDeep),
                title: Text('Remove markup',
                    style: AppTextStyles.rowTitle
                        .copyWith(color: AppColors.redDeep)),
                onTap: () => Navigator.of(context).pop(
                  const MarkupTemplate(
                      id: kRemoveMarkupId,
                      proId: 0,
                      name: '',
                      type: MarkupType.flat,
                      rate: 0),
                ),
              ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<List<MarkupTemplate>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          '${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.inkSoft),
                        ),
                      ),
                    );
                  }
                  final markups = snapshot.data ?? [];
                  if (markups.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No saved markup templates yet — add one from '
                          'More > Markups.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: markups.length,
                    itemBuilder: (context, i) {
                      final m = markups[i];
                      return ListTile(
                        leading: const Icon(Icons.trending_up,
                            size: 20, color: AppColors.inkSoft),
                        title: Text(m.name, style: AppTextStyles.rowTitle),
                        trailing: Text(m.displayRate,
                            style: AppTextStyles.rowAmount
                                .copyWith(fontSize: 14)),
                        onTap: () => Navigator.of(context).pop(m),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for choosing how an amount (discount or deposit) is
/// calculated — a percentage of the total, or a fixed dollar amount — and
/// its value. Pops with `(type, value)` on Apply, or null on cancel/close.
class _AmountPickerSheet extends StatefulWidget {
  final String title;
  final String amountLabel;
  final AmountType initialType;
  final double initialValue;

  const _AmountPickerSheet({
    required this.title,
    required this.amountLabel,
    required this.initialType,
    required this.initialValue,
  });

  @override
  State<_AmountPickerSheet> createState() => _AmountPickerSheetState();
}

class _AmountPickerSheetState extends State<_AmountPickerSheet> {
  late AmountType _type;
  late final TextEditingController _value;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _value = TextEditingController(text: _fmt(widget.initialValue));
  }

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  double get _numeric => double.tryParse(_value.text.trim())?.abs() ?? 0;

  void _setType(AmountType v) {
    setState(() {
      _type = v;
      // A percentage above 100 makes no sense — clamp if they'd switched
      // from a large fixed amount.
      if (v == AmountType.percent && _numeric > 100) {
        _value.text = _fmt(100);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 16),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.line)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(widget.title,
                          style:
                              AppTextStyles.headingSmall.copyWith(fontSize: 19)),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(16),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child:
                            Icon(Icons.close, size: 22, color: AppColors.inkSoft),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.amountLabel,
                        style: AppTextStyles.rowTitle.copyWith(fontSize: 15)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _AmountTypeOption(
                          label: 'Percentage (%)',
                          value: AmountType.percent,
                          groupValue: _type,
                          onChanged: _setType,
                        ),
                        const SizedBox(width: 28),
                        _AmountTypeOption(
                          label: 'Fixed Amount (\$)',
                          value: AmountType.fixed,
                          groupValue: _type,
                          onChanged: _setType,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.line),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _value,
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,2}')),
                              ],
                              style:
                                  AppTextStyles.headingSmall.copyWith(fontSize: 18),
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 14),
                              ),
                            ),
                          ),
                          Container(width: 1, height: 44, color: AppColors.line),
                          Container(
                            width: 44,
                            height: 52,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: AppColors.page,
                              borderRadius:
                                  BorderRadius.horizontal(right: Radius.circular(10)),
                            ),
                            child: Text(
                              _type == AmountType.percent ? '%' : '\$',
                              style: AppTextStyles.rowTitle
                                  .copyWith(color: AppColors.inkSoft),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.inkSoft,
                              side: const BorderSide(color: AppColors.line),
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              textStyle: AppTextStyles.buttonText
                                  .copyWith(fontSize: 15),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () =>
                                Navigator.of(context).pop((_type, _numeric)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.green800,
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              textStyle: AppTextStyles.buttonText
                                  .copyWith(fontSize: 15),
                            ),
                            child: const Text('Apply'),
                          ),
                        ),
                      ],
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

class _AmountTypeOption extends StatelessWidget {
  final String label;
  final AmountType value;
  final AmountType groupValue;
  final ValueChanged<AmountType> onChanged;

  const _AmountTypeOption({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.greenDeep : AppColors.inkFaint,
                width: 2,
              ),
            ),
            child: selected
                ? Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.greenDeep,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 7),
          Text(label, style: AppTextStyles.rowTitle.copyWith(fontSize: 14.5)),
        ],
      ),
    );
  }
}

/// Bottom sheet for entering or editing a note. Pops with the trimmed text
/// on Save, or null on cancel/close (an empty save clears the note).
class _NotesSheet extends StatefulWidget {
  final String title;
  final String hint;
  final String initialText;

  const _NotesSheet({
    required this.title,
    required this.hint,
    required this.initialText,
  });

  @override
  State<_NotesSheet> createState() => _NotesSheetState();
}

class _NotesSheetState extends State<_NotesSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 16),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.line)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(widget.title,
                          style:
                              AppTextStyles.headingSmall.copyWith(fontSize: 19)),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(16),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child:
                            Icon(Icons.close, size: 22, color: AppColors.inkSoft),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _controller,
                      autofocus: true,
                      minLines: 4,
                      maxLines: 8,
                      textCapitalization: TextCapitalization.sentences,
                      style: AppTextStyles.bodyMedium,
                      decoration: InputDecoration(
                        hintText: widget.hint,
                        filled: true,
                        fillColor: AppColors.page,
                        hintStyle: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.inkFaint, height: 1.4),
                        contentPadding: const EdgeInsets.all(13),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(11),
                          borderSide:
                              const BorderSide(color: AppColors.line, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(11),
                          borderSide: const BorderSide(
                              color: AppColors.greenDeep, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.inkSoft,
                              side: const BorderSide(color: AppColors.line),
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              textStyle: AppTextStyles.buttonText
                                  .copyWith(fontSize: 15),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () =>
                                Navigator.of(context).pop(_controller.text),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.green800,
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              textStyle: AppTextStyles.buttonText
                                  .copyWith(fontSize: 15),
                            ),
                            child: const Text('Save'),
                          ),
                        ),
                      ],
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

