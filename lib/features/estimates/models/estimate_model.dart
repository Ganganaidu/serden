import 'package:equatable/equatable.dart';

import '../../../core/widgets/status_badge.dart';

enum EstimateTab { pending, approved, declined }

class Estimate extends Equatable {
  final String id;
  final String clientName;
  final DateTime date;
  final int number;

  /// Null for drafts without a total yet.
  final double? amount;
  final EstimateTab tab;
  final DocumentStatus status;

  /// Chip label, e.g. "Viewed 2h ago".
  final String statusNote;

  const Estimate({
    required this.id,
    required this.clientName,
    required this.date,
    required this.number,
    required this.amount,
    required this.tab,
    required this.status,
    required this.statusNote,
  });

  factory Estimate.fromJson(Map<String, dynamic> json) => Estimate(
        id: json['id'] as String,
        clientName: json['clientName'] as String,
        date: DateTime.parse(json['date'] as String),
        number: json['number'] as int,
        amount: (json['amount'] as num?)?.toDouble(),
        tab: EstimateTab.values.byName(json['tab'] as String),
        status: DocumentStatus.fromString(json['status'] as String),
        statusNote: json['statusNote'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientName': clientName,
        'date': date.toIso8601String(),
        'number': number,
        'amount': amount,
        'tab': tab.name,
        'status': status.name,
        'statusNote': statusNote,
      };

  @override
  List<Object?> get props => [id, clientName, date, number, amount, tab, status, statusNote];
}

/// Test data matching the design mockups. Replaced by the API later.
final List<Estimate> mockEstimates = [
  Estimate(id: '1172', clientName: 'Joseph Ulrich', date: DateTime(2026, 4, 4), number: 1172, amount: 10600.00, tab: EstimateTab.pending, status: DocumentStatus.viewed, statusNote: 'Viewed 2h ago'),
  Estimate(id: '1171', clientName: 'Susan Perry', date: DateTime(2026, 4, 4), number: 1171, amount: 14800.00, tab: EstimateTab.pending, status: DocumentStatus.sent, statusNote: 'Sent'),
  Estimate(id: '1170', clientName: 'David Woods', date: DateTime(2026, 2, 9), number: 1170, amount: 9729.00, tab: EstimateTab.pending, status: DocumentStatus.sent, statusNote: 'Sent'),
  Estimate(id: '1169', clientName: 'New estimate', date: DateTime(2026, 2, 9), number: 1169, amount: null, tab: EstimateTab.pending, status: DocumentStatus.draft, statusNote: 'Draft'),
  Estimate(id: '1166', clientName: 'Shawn Jensen', date: DateTime(2026, 2, 9), number: 1166, amount: 19983.00, tab: EstimateTab.pending, status: DocumentStatus.viewed, statusNote: 'Viewed Feb 10'),
  Estimate(id: '1164', clientName: 'Lindsey Farland', date: DateTime(2026, 2, 6), number: 1164, amount: 12903.00, tab: EstimateTab.pending, status: DocumentStatus.viewed, statusNote: 'Viewed Feb 7'),
  Estimate(id: '1163', clientName: 'Paula Cercea', date: DateTime(2026, 2, 2), number: 1163, amount: 57768.23, tab: EstimateTab.pending, status: DocumentStatus.sent, statusNote: 'Sent'),
  Estimate(id: '1160', clientName: 'Marcus Reed', date: DateTime(2026, 1, 28), number: 1160, amount: 8450.00, tab: EstimateTab.approved, status: DocumentStatus.approved, statusNote: 'Approved'),
  Estimate(id: '1154', clientName: 'Angela Torres', date: DateTime(2026, 1, 15), number: 1154, amount: 22140.00, tab: EstimateTab.approved, status: DocumentStatus.approved, statusNote: 'Approved'),
  Estimate(id: '1149', clientName: 'Bill Hartman', date: DateTime(2026, 1, 9), number: 1149, amount: 5300.00, tab: EstimateTab.declined, status: DocumentStatus.declined, statusNote: 'Declined'),
];
