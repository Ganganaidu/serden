import 'package:equatable/equatable.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/status_badge.dart';

enum InvoiceTab { active, overdue, paid }

/// Maps the API `status` string onto [DocumentStatus].
DocumentStatus invoiceDocStatus(String? status) {
  switch (status?.toLowerCase()) {
    case 'paid':
      return DocumentStatus.paid;
    case 'partial':
      return DocumentStatus.partial;
    case 'overdue':
      return DocumentStatus.overdue;
    case 'viewed':
    case 'opened':
      return DocumentStatus.viewed;
    case 'sent':
    case 'issued':
      return DocumentStatus.sent;
    default:
      return DocumentStatus.draft;
  }
}

InvoiceTab invoiceTab(DocumentStatus status, {bool isOverdue = false}) {
  if (status == DocumentStatus.paid) return InvoiceTab.paid;
  if (isOverdue || status == DocumentStatus.overdue) return InvoiceTab.overdue;
  return InvoiceTab.active;
}

// ─── Photo ──────────────────────────────────────────────────────────────────

class InvoicePhoto extends Equatable {
  final int photoId;
  final String? fileName;
  final String? fileUrl;
  final String? caption;
  final int sortOrder;

  const InvoicePhoto({
    this.photoId = 0,
    this.fileName,
    this.fileUrl,
    this.caption,
    this.sortOrder = 0,
  });

  String? get url {
    final u = fileUrl?.trim();
    if (u != null && u.isNotEmpty) {
      return u.startsWith('http') ? u : AppConstants.projectPhotoUrl(u);
    }
    final f = fileName?.trim();
    if (f != null && f.isNotEmpty) return AppConstants.projectPhotoUrl(f);
    return null;
  }

  factory InvoicePhoto.fromJson(Map<String, dynamic> json) => InvoicePhoto(
        photoId: json['photoId'] as int? ?? 0,
        fileName: json['fileName'] as String?,
        fileUrl: json['fileUrl'] as String?,
        caption: json['caption'] as String?,
        sortOrder: json['sortOrder'] as int? ?? 0,
      );

  @override
  List<Object?> get props => [photoId, fileName, fileUrl, caption, sortOrder];
}

// ─── Line item ───────────────────────────────────────────────────────────────

class InvoiceLineItem extends Equatable {
  final int lineItemId;
  final String? publicId;
  final int? sectionId;
  final String description;
  final String? notes;
  final double unitPrice;
  final int quantity;
  final String? markupType;
  final double? markupValue;
  final bool isTaxable;
  final double? taxRate;
  final double taxAmount;
  final double total;
  final int sortOrder;
  final bool isActive;
  final List<InvoicePhoto> photos;

  const InvoiceLineItem({
    this.lineItemId = 0,
    this.publicId,
    this.sectionId,
    this.description = '',
    this.notes,
    this.unitPrice = 0,
    this.quantity = 1,
    this.markupType,
    this.markupValue,
    this.isTaxable = false,
    this.taxRate,
    this.taxAmount = 0,
    this.total = 0,
    this.sortOrder = 0,
    this.isActive = true,
    this.photos = const [],
  });

  double get lineTotal => total != 0 ? total : unitPrice * quantity;

  factory InvoiceLineItem.fromJson(Map<String, dynamic> json) =>
      InvoiceLineItem(
        lineItemId: json['lineItemId'] as int? ?? 0,
        publicId: json['publicId'] as String?,
        sectionId: json['sectionId'] as int?,
        description: json['description'] as String? ?? '',
        notes: json['notes'] as String?,
        unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        markupType: json['markupType'] as String?,
        markupValue: (json['markupValue'] as num?)?.toDouble(),
        isTaxable: json['isTaxable'] as bool? ?? false,
        taxRate: (json['taxRate'] as num?)?.toDouble(),
        taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0,
        total: (json['total'] as num?)?.toDouble() ?? 0,
        sortOrder: json['sortOrder'] as int? ?? 0,
        isActive: json['isActive'] as bool? ?? true,
        photos: (json['photos'] as List<dynamic>?)
                ?.map((e) => InvoicePhoto.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  Map<String, dynamic> toJson() => {
        'lineItemId': lineItemId,
        if (sectionId != null) 'sectionId': sectionId,
        'description': description,
        if (notes != null) 'notes': notes,
        'unitPrice': unitPrice,
        'quantity': quantity,
        if (markupType != null) 'markupType': markupType,
        if (markupValue != null) 'markupValue': markupValue,
        'isTaxable': isTaxable,
        if (taxRate != null) 'taxRate': taxRate,
        'taxAmount': taxAmount,
        'total': lineTotal,
        'sortOrder': sortOrder,
        'isActive': isActive,
      };

  @override
  List<Object?> get props =>
      [lineItemId, sectionId, description, unitPrice, quantity, total, sortOrder];
}

// ─── Section ─────────────────────────────────────────────────────────────────

class InvoiceSection extends Equatable {
  final int sectionId;
  final String? publicId;
  final String name;
  final int sortOrder;
  final double subtotal;
  final bool isExpanded;
  final bool isActive;
  final List<InvoiceLineItem> lineItems;

  const InvoiceSection({
    this.sectionId = 0,
    this.publicId,
    this.name = '',
    this.sortOrder = 0,
    this.subtotal = 0,
    this.isExpanded = true,
    this.isActive = true,
    this.lineItems = const [],
  });

  factory InvoiceSection.fromJson(Map<String, dynamic> json) => InvoiceSection(
        sectionId: json['sectionId'] as int? ?? 0,
        publicId: json['publicId'] as String?,
        name: json['name'] as String? ?? '',
        sortOrder: json['sortOrder'] as int? ?? 0,
        subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
        isExpanded: json['isExpanded'] as bool? ?? true,
        isActive: json['isActive'] as bool? ?? true,
        lineItems: (json['lineItems'] as List<dynamic>?)
                ?.map((e) => InvoiceLineItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  Map<String, dynamic> toJson() => {
        'sectionId': sectionId,
        'name': name,
        'sortOrder': sortOrder,
        'subtotal': subtotal,
        'isExpanded': isExpanded,
        'isActive': isActive,
        'lineItems': lineItems.map((e) => e.toJson()).toList(),
      };

  @override
  List<Object?> get props => [sectionId, name, sortOrder, subtotal, lineItems];
}

// ─── Payment record ───────────────────────────────────────────────────────────

class InvoicePayment extends Equatable {
  final int invoicePaymentId;
  final String? publicId;
  final int invoiceId;
  final DateTime paymentDate;
  final double amount;
  final String? paymentMethod;
  final String? referenceNumber;
  final String? notes;
  final bool isActive;
  final DateTime createdDate;

  const InvoicePayment({
    this.invoicePaymentId = 0,
    this.publicId,
    this.invoiceId = 0,
    required this.paymentDate,
    this.amount = 0,
    this.paymentMethod,
    this.referenceNumber,
    this.notes,
    this.isActive = true,
    required this.createdDate,
  });

  factory InvoicePayment.fromJson(Map<String, dynamic> json) => InvoicePayment(
        invoicePaymentId: json['invoicePaymentId'] as int? ?? 0,
        publicId: json['publicId'] as String?,
        invoiceId: json['invoiceId'] as int? ?? 0,
        paymentDate: DateTime.tryParse(json['paymentDate'] as String? ?? '') ??
            DateTime.now(),
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        paymentMethod: json['paymentMethod'] as String?,
        referenceNumber: json['referenceNumber'] as String?,
        notes: json['notes'] as String?,
        isActive: json['isActive'] as bool? ?? true,
        createdDate: DateTime.tryParse(json['createdDate'] as String? ?? '') ??
            DateTime.now(),
      );

  @override
  List<Object?> get props =>
      [invoicePaymentId, invoiceId, paymentDate, amount, paymentMethod];
}

// ─── Full invoice (detail) ────────────────────────────────────────────────────

class Invoice extends Equatable {
  final int invoiceId;
  final String? publicId;
  final int proId;
  final int? clientId;
  final String? clientName;
  final String? invoiceNumber;
  final DateTime invoiceDate;
  final int? daysToPay;
  final DateTime? dueDate;
  final String? poNumber;
  final bool groupItemsIntoSections;
  final double subtotal;
  final String? markupType;
  final double? markupValue;
  final String? discountType;
  final double? discountValue;
  final String? depositType;
  final double? depositValue;
  final String? taxName;
  final double? taxRate;
  final double total;
  final bool showClientSignature;
  final bool showMySignature;
  final bool showRate;
  final bool showQuantity;
  final bool showItemTotals;
  final bool showSectionTotals;
  final String? notes;
  final String? privateNotes;
  final String? status;
  final DateTime? sentDate;
  final DateTime? viewedDate;
  final DateTime? paidDate;
  final bool isActive;
  final DateTime? createdDate;
  final DateTime? modifiedDate;
  final List<InvoiceSection> sections;
  final List<InvoiceLineItem> lineItems;
  final List<InvoicePhoto> photos;
  final int attachmentCount;
  final String? proName;
  final String? proEmail;
  final String? proAddress;
  final String? proCity;
  final String? proState;
  final String? proZipCode;

  const Invoice({
    this.invoiceId = 0,
    this.publicId,
    this.proId = 0,
    this.clientId,
    this.clientName,
    this.invoiceNumber,
    required this.invoiceDate,
    this.daysToPay,
    this.dueDate,
    this.poNumber,
    this.groupItemsIntoSections = false,
    this.subtotal = 0,
    this.markupType,
    this.markupValue,
    this.discountType,
    this.discountValue,
    this.depositType,
    this.depositValue,
    this.taxName,
    this.taxRate,
    this.total = 0,
    this.showClientSignature = true,
    this.showMySignature = false,
    this.showRate = true,
    this.showQuantity = true,
    this.showItemTotals = true,
    this.showSectionTotals = true,
    this.notes,
    this.privateNotes,
    this.status,
    this.sentDate,
    this.viewedDate,
    this.paidDate,
    this.isActive = true,
    this.createdDate,
    this.modifiedDate,
    this.sections = const [],
    this.lineItems = const [],
    this.photos = const [],
    this.attachmentCount = 0,
    this.proName,
    this.proEmail,
    this.proAddress,
    this.proCity,
    this.proState,
    this.proZipCode,
  });

  DocumentStatus get docStatus => invoiceDocStatus(status);

  bool get isOverdue =>
      status?.toLowerCase() == 'overdue' ||
      (dueDate != null &&
          dueDate!.isBefore(DateTime.now()) &&
          docStatus != DocumentStatus.paid);

  int get number => int.tryParse(invoiceNumber ?? '') ?? invoiceId;

  List<InvoiceLineItem> get allLineItems => [
        ...lineItems,
        for (final s in sections) ...s.lineItems,
      ];

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
        invoiceId: json['invoiceId'] as int? ?? 0,
        publicId: json['publicId'] as String?,
        proId: json['proId'] as int? ?? 0,
        clientId: json['clientId'] as int?,
        clientName: json['clientName'] as String?,
        invoiceNumber: json['invoiceNumber']?.toString(),
        invoiceDate: DateTime.tryParse(json['invoiceDate'] as String? ?? '') ??
            DateTime.now(),
        daysToPay: json['daysToPay'] as int?,
        dueDate: DateTime.tryParse(json['dueDate'] as String? ?? ''),
        poNumber: json['poNumber'] as String?,
        groupItemsIntoSections:
            json['groupItemsIntoSections'] as bool? ?? false,
        subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
        markupType: json['markupType'] as String?,
        markupValue: (json['markupValue'] as num?)?.toDouble(),
        discountType: json['discountType'] as String?,
        discountValue: (json['discountValue'] as num?)?.toDouble(),
        depositType: json['depositType'] as String?,
        depositValue: (json['depositValue'] as num?)?.toDouble(),
        taxName: json['taxName'] as String?,
        taxRate: (json['taxRate'] as num?)?.toDouble(),
        total: (json['total'] as num?)?.toDouble() ?? 0,
        showClientSignature: json['showClientSignature'] as bool? ?? true,
        showMySignature: json['showMySignature'] as bool? ?? false,
        showRate: json['showDisplayOptionsRate'] as bool? ?? true,
        showQuantity: json['showDisplayOptionsQuantity'] as bool? ?? true,
        showItemTotals: json['showDisplayOptionsItemTotals'] as bool? ?? true,
        showSectionTotals:
            json['showDisplayOptionsSectionTotals'] as bool? ?? true,
        notes: json['notes'] as String?,
        privateNotes: json['privateNotes'] as String?,
        status: json['status'] as String?,
        sentDate: DateTime.tryParse(json['sentDate'] as String? ?? ''),
        viewedDate: DateTime.tryParse(json['viewedDate'] as String? ?? ''),
        paidDate: DateTime.tryParse(json['paidDate'] as String? ?? ''),
        isActive: json['isActive'] as bool? ?? true,
        createdDate: DateTime.tryParse(json['createdDate'] as String? ?? ''),
        modifiedDate: DateTime.tryParse(json['modifiedDate'] as String? ?? ''),
        sections: (json['sections'] as List<dynamic>?)
                ?.map((e) => InvoiceSection.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        lineItems: (json['lineItems'] as List<dynamic>?)
                ?.map((e) => InvoiceLineItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        photos: (json['photos'] as List<dynamic>?)
                ?.map((e) => InvoicePhoto.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        attachmentCount: (json['attachments'] as List<dynamic>?)?.length ?? 0,
        proName: json['proName'] as String?,
        proEmail: json['proEmail'] as String?,
        proAddress: json['proAddress'] as String?,
        proCity: json['proCity'] as String?,
        proState: json['proState'] as String?,
        proZipCode: json['proZipCode'] as String?,
      );

  /// Body for `PUT /api/Invoices/{id}`.
  Map<String, dynamic> toJson() => {
        'invoiceId': invoiceId,
        if (publicId != null) 'publicId': publicId,
        'proId': proId,
        if (clientId != null) 'clientId': clientId,
        if (clientName != null) 'clientName': clientName,
        if (invoiceNumber != null) 'invoiceNumber': invoiceNumber,
        'invoiceDate': invoiceDate.toIso8601String(),
        if (daysToPay != null) 'daysToPay': daysToPay,
        if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
        if (poNumber != null) 'poNumber': poNumber,
        'groupItemsIntoSections': groupItemsIntoSections,
        'subtotal': subtotal,
        if (markupType != null) 'markupType': markupType,
        if (markupValue != null) 'markupValue': markupValue,
        if (discountType != null) 'discountType': discountType,
        if (discountValue != null) 'discountValue': discountValue,
        if (depositType != null) 'depositType': depositType,
        if (depositValue != null) 'depositValue': depositValue,
        if (taxName != null) 'taxName': taxName,
        if (taxRate != null) 'taxRate': taxRate,
        'total': total,
        'showClientSignature': showClientSignature,
        'showMySignature': showMySignature,
        if (notes != null) 'notes': notes,
        if (privateNotes != null) 'privateNotes': privateNotes,
        if (status != null) 'status': status,
        'isActive': isActive,
        'sections': sections.map((e) => e.toJson()).toList(),
        'lineItems': lineItems.map((e) => e.toJson()).toList(),
      };

  Invoice copyWith({
    int? clientId,
    String? clientName,
    String? status,
    DateTime? paidDate,
  }) =>
      Invoice(
        invoiceId: invoiceId,
        publicId: publicId,
        proId: proId,
        clientId: clientId ?? this.clientId,
        clientName: clientName ?? this.clientName,
        invoiceNumber: invoiceNumber,
        invoiceDate: invoiceDate,
        daysToPay: daysToPay,
        dueDate: dueDate,
        poNumber: poNumber,
        groupItemsIntoSections: groupItemsIntoSections,
        subtotal: subtotal,
        markupType: markupType,
        markupValue: markupValue,
        discountType: discountType,
        discountValue: discountValue,
        depositType: depositType,
        depositValue: depositValue,
        taxName: taxName,
        taxRate: taxRate,
        total: total,
        showClientSignature: showClientSignature,
        showMySignature: showMySignature,
        showRate: showRate,
        showQuantity: showQuantity,
        showItemTotals: showItemTotals,
        showSectionTotals: showSectionTotals,
        notes: notes,
        privateNotes: privateNotes,
        status: status ?? this.status,
        sentDate: sentDate,
        viewedDate: viewedDate,
        paidDate: paidDate ?? this.paidDate,
        isActive: isActive,
        createdDate: createdDate,
        modifiedDate: modifiedDate,
        sections: sections,
        lineItems: lineItems,
        photos: photos,
        attachmentCount: attachmentCount,
        proName: proName,
        proEmail: proEmail,
        proAddress: proAddress,
        proCity: proCity,
        proState: proState,
        proZipCode: proZipCode,
      );

  @override
  List<Object?> get props => [
        invoiceId,
        publicId,
        clientId,
        clientName,
        invoiceNumber,
        invoiceDate,
        total,
        status,
        sections,
        lineItems,
      ];
}

// ─── List row (InvoiceListViewModel) ─────────────────────────────────────────

class InvoiceSummary extends Equatable {
  final int invoiceId;
  final String? publicId;
  final String? invoiceNumber;
  final String clientName;
  final DateTime invoiceDate;
  final int? daysToPay;
  final DateTime? dueDate;
  final double total;
  final double paidAmount;
  final String? status;
  final DateTime? createdDate;
  final bool emailOpened;
  final DateTime? emailOpenedDate;
  final DateTime? clientSignedDate;

  const InvoiceSummary({
    required this.invoiceId,
    this.publicId,
    this.invoiceNumber,
    this.clientName = 'Unnamed client',
    required this.invoiceDate,
    this.daysToPay,
    this.dueDate,
    this.total = 0,
    this.paidAmount = 0,
    this.status,
    this.createdDate,
    this.emailOpened = false,
    this.emailOpenedDate,
    this.clientSignedDate,
  });

  String get id => invoiceId.toString();
  int get number => int.tryParse(invoiceNumber ?? '') ?? invoiceId;
  DateTime get date => invoiceDate;

  DocumentStatus get docStatus => invoiceDocStatus(status);

  bool get isOverdue =>
      status?.toLowerCase() == 'overdue' ||
      (dueDate != null &&
          dueDate!.isBefore(DateTime.now()) &&
          docStatus != DocumentStatus.paid);

  bool get isPaid => docStatus == DocumentStatus.paid;
  bool get isPartial => docStatus == DocumentStatus.partial;

  double get balance => total - paidAmount;

  int get paidPercent =>
      total == 0 ? 0 : (paidAmount / total * 100).round();

  InvoiceTab get tab => invoiceTab(docStatus, isOverdue: isOverdue);

  String get dueNote {
    if (isPaid) return '';
    final d = dueDate;
    if (d == null) return 'Due upon receipt';
    final now = DateTime.now();
    if (isOverdue) {
      final days = now.difference(d).inDays;
      return '$days day${days == 1 ? '' : 's'} overdue';
    }
    return 'Due ${Formatters.dateShort(d)}';
  }

  String get statusNote {
    switch (docStatus) {
      case DocumentStatus.paid:
        return 'Paid';
      case DocumentStatus.partial:
        return 'Partly paid';
      case DocumentStatus.overdue:
        return 'Overdue';
      case DocumentStatus.viewed:
        final d = emailOpenedDate;
        return d != null ? 'Viewed ${Formatters.dateShort(d)}' : 'Viewed';
      case DocumentStatus.sent:
        return emailOpened ? 'Viewed' : 'Sent';
      case DocumentStatus.draft:
        return 'Draft';
      default:
        return 'Sent';
    }
  }

  factory InvoiceSummary.fromJson(Map<String, dynamic> json) => InvoiceSummary(
        invoiceId: json['invoiceId'] as int? ?? 0,
        publicId: json['publicId'] as String?,
        invoiceNumber: json['invoiceNumber']?.toString(),
        clientName: (json['clientName'] as String?)?.trim().isNotEmpty == true
            ? json['clientName'] as String
            : 'Unnamed client',
        invoiceDate: DateTime.tryParse(json['invoiceDate'] as String? ?? '') ??
            DateTime.now(),
        daysToPay: json['daysToPay'] as int?,
        dueDate: DateTime.tryParse(json['dueDate'] as String? ?? ''),
        total: (json['total'] as num?)?.toDouble() ?? 0,
        paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
        status: json['status'] as String?,
        createdDate: DateTime.tryParse(json['createdDate'] as String? ?? ''),
        emailOpened: json['emailOpened'] as bool? ?? false,
        emailOpenedDate:
            DateTime.tryParse(json['emailOpenedDate'] as String? ?? ''),
        clientSignedDate:
            DateTime.tryParse(json['clientSignedDate'] as String? ?? ''),
      );

  @override
  List<Object?> get props => [
        invoiceId,
        invoiceNumber,
        clientName,
        invoiceDate,
        total,
        paidAmount,
        status,
        emailOpened,
      ];
}

/// Sample rows for mock mode (AppConfig.useMockData).
final List<InvoiceSummary> mockInvoices = [
  InvoiceSummary(invoiceId: 95, invoiceNumber: '95', clientName: 'Zachary Bosma', invoiceDate: DateTime(2026, 6, 3), total: 2500.00, paidAmount: 0, status: 'viewed', emailOpened: true, emailOpenedDate: DateTime(2026, 6, 5), dueDate: DateTime(2026, 7, 3)),
  InvoiceSummary(invoiceId: 94, invoiceNumber: '94', clientName: 'Praveen Kumar', invoiceDate: DateTime(2026, 4, 28), total: 155000.00, paidAmount: 77500.00, status: 'partial', dueDate: DateTime(2026, 7, 28)),
  InvoiceSummary(invoiceId: 93, invoiceNumber: '93', clientName: 'Aman Gupta', invoiceDate: DateTime(2026, 2, 9), total: 4200.00, paidAmount: 2100.00, status: 'overdue', dueDate: DateTime(2026, 3, 9)),
  InvoiceSummary(invoiceId: 92, invoiceNumber: '92', clientName: "Dennis O'Doherty", invoiceDate: DateTime(2026, 2, 2), total: 6900.00, paidAmount: 0, status: 'draft'),
  InvoiceSummary(invoiceId: 90, invoiceNumber: '90', clientName: 'Mary Ellen Melville', invoiceDate: DateTime(2026, 1, 19), total: 9600.00, paidAmount: 3600.00, status: 'overdue', dueDate: DateTime(2026, 2, 19)),
  InvoiceSummary(invoiceId: 89, invoiceNumber: '89', clientName: 'Robert Chen', invoiceDate: DateTime(2026, 1, 6), total: 12750.00, paidAmount: 12750.00, status: 'paid'),
  InvoiceSummary(invoiceId: 87, invoiceNumber: '87', clientName: 'Karen Whitfield', invoiceDate: DateTime(2025, 12, 12), total: 3350.00, paidAmount: 3350.00, status: 'paid'),
];
