import 'package:equatable/equatable.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/status_badge.dart';

enum EstimateTab { pending, approved, declined }

/// Percentage ('P') or fixed-amount ('F') modifier — used by the API for
/// markup / discount / deposit values. Matches the `apiType` used by items.
enum AmountType {
  percent,
  fixed;

  String get apiValue => this == AmountType.percent ? 'P' : 'F';

  static AmountType fromApi(String? v) {
    switch (v?.toLowerCase()) {
      case 'f':
      case 'fixed':
      case 'flat':
      case 'amount':
        return AmountType.fixed;
      default:
        return AmountType.percent;
    }
  }
}

/// Maps the API `status` string + `isApproved` flag onto the app's
/// [DocumentStatus] / [EstimateTab] vocabulary.
DocumentStatus estimateDocStatus(String? status, {bool? isApproved}) {
  if (isApproved == true) return DocumentStatus.approved;
  switch (status?.toLowerCase()) {
    case 'approved':
    case 'accepted':
      return DocumentStatus.approved;
    case 'declined':
    case 'rejected':
      return DocumentStatus.declined;
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

EstimateTab estimateTab(DocumentStatus status) {
  switch (status) {
    case DocumentStatus.approved:
      return EstimateTab.approved;
    case DocumentStatus.declined:
      return EstimateTab.declined;
    default:
      return EstimateTab.pending;
  }
}

// ─── Line item ───────────────────────────────────────────────────────────────

class EstimateLineItem extends Equatable {
  final int lineItemId;
  final String? publicId;
  final int? sectionId;
  final int? catalogLineItemId;
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

  const EstimateLineItem({
    this.lineItemId = 0,
    this.publicId,
    this.sectionId,
    this.catalogLineItemId,
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
  });

  double get lineTotal => total != 0 ? total : unitPrice * quantity;

  factory EstimateLineItem.fromJson(Map<String, dynamic> json) =>
      EstimateLineItem(
        lineItemId: json['lineItemId'] as int? ?? 0,
        publicId: json['publicId'] as String?,
        sectionId: json['sectionId'] as int?,
        catalogLineItemId: json['catalogLineItemId'] as int?,
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
      );

  Map<String, dynamic> toJson() => {
        'lineItemId': lineItemId,
        if (sectionId != null) 'sectionId': sectionId,
        if (catalogLineItemId != null) 'catalogLineItemId': catalogLineItemId,
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

class EstimateSection extends Equatable {
  final int sectionId;
  final String? publicId;
  final String name;
  final int sortOrder;
  final double subtotal;
  final bool isExpanded;
  final bool isActive;
  final List<EstimateLineItem> lineItems;

  const EstimateSection({
    this.sectionId = 0,
    this.publicId,
    this.name = '',
    this.sortOrder = 0,
    this.subtotal = 0,
    this.isExpanded = true,
    this.isActive = true,
    this.lineItems = const [],
  });

  factory EstimateSection.fromJson(Map<String, dynamic> json) => EstimateSection(
        sectionId: json['sectionId'] as int? ?? 0,
        publicId: json['publicId'] as String?,
        name: json['name'] as String? ?? '',
        sortOrder: json['sortOrder'] as int? ?? 0,
        subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
        isExpanded: json['isExpanded'] as bool? ?? true,
        isActive: json['isActive'] as bool? ?? true,
        lineItems: (json['lineItems'] as List<dynamic>?)
                ?.map((e) => EstimateLineItem.fromJson(e as Map<String, dynamic>))
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

// ─── Full estimate (detail) ──────────────────────────────────────────────────

class Estimate extends Equatable {
  final int estimateId;
  final String? publicId;
  final int proId;
  final int? clientId;
  final String? clientName;
  final String? estimateNumber;
  final DateTime estimateDate;
  final DateTime? expirationDate;
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
  final String? notes;
  final String? privateNotes;
  final String? status;
  final bool? isApproved;
  final DateTime? sentDate;
  final DateTime? viewedDate;
  final DateTime? acceptedDate;
  final DateTime? declinedDate;
  final bool isActive;
  final DateTime? createdDate;
  final DateTime? modifiedDate;
  final List<EstimateSection> sections;
  final List<EstimateLineItem> lineItems;
  final int photoCount;
  final int attachmentCount;
  final String? proName;
  final String? proEmail;
  final String? proAddress;
  final String? proCity;
  final String? proState;
  final String? proZipCode;

  const Estimate({
    this.estimateId = 0,
    this.publicId,
    this.proId = 0,
    this.clientId,
    this.clientName,
    this.estimateNumber,
    required this.estimateDate,
    this.expirationDate,
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
    this.notes,
    this.privateNotes,
    this.status,
    this.isApproved,
    this.sentDate,
    this.viewedDate,
    this.acceptedDate,
    this.declinedDate,
    this.isActive = true,
    this.createdDate,
    this.modifiedDate,
    this.sections = const [],
    this.lineItems = const [],
    this.photoCount = 0,
    this.attachmentCount = 0,
    this.proName,
    this.proEmail,
    this.proAddress,
    this.proCity,
    this.proState,
    this.proZipCode,
  });

  DocumentStatus get docStatus =>
      estimateDocStatus(status, isApproved: isApproved);

  EstimateTab get tab => estimateTab(docStatus);

  int get number =>
      int.tryParse(estimateNumber ?? '') ?? estimateId;

  /// Every line item, flattened across sections.
  List<EstimateLineItem> get allLineItems => [
        ...lineItems,
        for (final s in sections) ...s.lineItems,
      ];

  double get depositAmount {
    final v = depositValue ?? 0;
    if (v <= 0) return 0;
    return AmountType.fromApi(depositType) == AmountType.percent
        ? total * v / 100
        : v;
  }

  factory Estimate.fromJson(Map<String, dynamic> json) => Estimate(
        estimateId: json['estimateId'] as int? ?? 0,
        publicId: json['publicId'] as String?,
        proId: json['proId'] as int? ?? 0,
        clientId: json['clientId'] as int?,
        clientName: json['clientName'] as String?,
        estimateNumber: json['estimateNumber']?.toString(),
        estimateDate: DateTime.tryParse(json['estimateDate'] as String? ?? '') ??
            DateTime.now(),
        expirationDate: DateTime.tryParse(json['expirationDate'] as String? ?? ''),
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
        notes: json['notes'] as String?,
        privateNotes: json['privateNotes'] as String?,
        status: json['status'] as String?,
        isApproved: json['isApproved'] as bool?,
        sentDate: DateTime.tryParse(json['sentDate'] as String? ?? ''),
        viewedDate: DateTime.tryParse(json['viewedDate'] as String? ?? ''),
        acceptedDate: DateTime.tryParse(json['acceptedDate'] as String? ?? ''),
        declinedDate: DateTime.tryParse(json['declinedDate'] as String? ?? ''),
        isActive: json['isActive'] as bool? ?? true,
        createdDate: DateTime.tryParse(json['createdDate'] as String? ?? ''),
        modifiedDate: DateTime.tryParse(json['modifiedDate'] as String? ?? ''),
        sections: (json['sections'] as List<dynamic>?)
                ?.map((e) => EstimateSection.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        lineItems: (json['lineItems'] as List<dynamic>?)
                ?.map(
                    (e) => EstimateLineItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        photoCount: (json['photos'] as List<dynamic>?)?.length ?? 0,
        attachmentCount: (json['attachments'] as List<dynamic>?)?.length ?? 0,
        proName: json['proName'] as String?,
        proEmail: json['proEmail'] as String?,
        proAddress: json['proAddress'] as String?,
        proCity: json['proCity'] as String?,
        proState: json['proState'] as String?,
        proZipCode: json['proZipCode'] as String?,
      );

  /// Body for `PUT /api/Estimates/{id}` — the full [EstimateViewModel] shape.
  Map<String, dynamic> toJson() => {
        'estimateId': estimateId,
        if (publicId != null) 'publicId': publicId,
        'proId': proId,
        if (clientId != null) 'clientId': clientId,
        if (clientName != null) 'clientName': clientName,
        if (estimateNumber != null) 'estimateNumber': estimateNumber,
        'estimateDate': estimateDate.toIso8601String(),
        if (expirationDate != null)
          'expirationDate': expirationDate!.toIso8601String(),
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

  Estimate copyWith({
    int? clientId,
    String? clientName,
    String? status,
    bool? isApproved,
  }) =>
      Estimate(
        estimateId: estimateId,
        publicId: publicId,
        proId: proId,
        clientId: clientId ?? this.clientId,
        clientName: clientName ?? this.clientName,
        estimateNumber: estimateNumber,
        estimateDate: estimateDate,
        expirationDate: expirationDate,
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
        notes: notes,
        privateNotes: privateNotes,
        status: status ?? this.status,
        isApproved: isApproved ?? this.isApproved,
        sentDate: sentDate,
        viewedDate: viewedDate,
        acceptedDate: acceptedDate,
        declinedDate: declinedDate,
        isActive: isActive,
        createdDate: createdDate,
        modifiedDate: modifiedDate,
        sections: sections,
        lineItems: lineItems,
        photoCount: photoCount,
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
        estimateId,
        publicId,
        clientId,
        clientName,
        estimateNumber,
        estimateDate,
        total,
        status,
        isApproved,
        sections,
        lineItems,
      ];
}

// ─── List row (EstimateListViewModel) ────────────────────────────────────────

class EstimateSummary extends Equatable {
  final int estimateId;
  final String? publicId;
  final String? estimateNumber;
  final String clientName;
  final DateTime estimateDate;
  final DateTime? expirationDate;
  final double total;
  final String? status;
  final bool? isApproved;
  final DateTime? createdDate;
  final bool emailOpened;
  final DateTime? emailOpenedDate;
  final DateTime? clientSignedDate;

  const EstimateSummary({
    required this.estimateId,
    this.publicId,
    this.estimateNumber,
    this.clientName = 'Unnamed client',
    required this.estimateDate,
    this.expirationDate,
    this.total = 0,
    this.status,
    this.isApproved,
    this.createdDate,
    this.emailOpened = false,
    this.emailOpenedDate,
    this.clientSignedDate,
  });

  String get id => estimateId.toString();

  int get number => int.tryParse(estimateNumber ?? '') ?? estimateId;

  DateTime get date => estimateDate;

  DocumentStatus get docStatus =>
      estimateDocStatus(status, isApproved: isApproved);

  EstimateTab get tab => estimateTab(docStatus);

  /// Null while the estimate is an empty draft with no total yet.
  double? get amount =>
      total == 0 && docStatus == DocumentStatus.draft ? null : total;

  String get statusNote {
    switch (docStatus) {
      case DocumentStatus.approved:
        return 'Approved';
      case DocumentStatus.declined:
        return 'Declined';
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

  factory EstimateSummary.fromJson(Map<String, dynamic> json) => EstimateSummary(
        estimateId: json['estimateId'] as int? ?? 0,
        publicId: json['publicId'] as String?,
        estimateNumber: json['estimateNumber']?.toString(),
        clientName: (json['clientName'] as String?)?.trim().isNotEmpty == true
            ? json['clientName'] as String
            : 'Unnamed client',
        estimateDate: DateTime.tryParse(json['estimateDate'] as String? ?? '') ??
            DateTime.now(),
        expirationDate:
            DateTime.tryParse(json['expirationDate'] as String? ?? ''),
        total: (json['total'] as num?)?.toDouble() ?? 0,
        status: json['status'] as String?,
        isApproved: json['isApproved'] as bool?,
        createdDate: DateTime.tryParse(json['createdDate'] as String? ?? ''),
        emailOpened: json['emailOpened'] as bool? ?? false,
        emailOpenedDate:
            DateTime.tryParse(json['emailOpenedDate'] as String? ?? ''),
        clientSignedDate:
            DateTime.tryParse(json['clientSignedDate'] as String? ?? ''),
      );

  @override
  List<Object?> get props => [
        estimateId,
        estimateNumber,
        clientName,
        estimateDate,
        total,
        status,
        isApproved,
        emailOpened,
      ];
}

/// Sample rows for mock mode (AppConfig.useMockData). Real users start empty.
final List<EstimateSummary> mockEstimates = [
  EstimateSummary(estimateId: 1172, estimateNumber: '1172', clientName: 'Joseph Ulrich', estimateDate: DateTime(2026, 4, 4), total: 10600.00, status: 'viewed', emailOpened: true, emailOpenedDate: DateTime(2026, 4, 4)),
  EstimateSummary(estimateId: 1171, estimateNumber: '1171', clientName: 'Susan Perry', estimateDate: DateTime(2026, 4, 4), total: 14800.00, status: 'sent'),
  EstimateSummary(estimateId: 1169, estimateNumber: '1169', clientName: 'New estimate', estimateDate: DateTime(2026, 2, 9), total: 0, status: 'draft'),
  EstimateSummary(estimateId: 1160, estimateNumber: '1160', clientName: 'Marcus Reed', estimateDate: DateTime(2026, 1, 28), total: 8450.00, status: 'approved', isApproved: true),
  EstimateSummary(estimateId: 1149, estimateNumber: '1149', clientName: 'Bill Hartman', estimateDate: DateTime(2026, 1, 9), total: 5300.00, status: 'declined'),
];
