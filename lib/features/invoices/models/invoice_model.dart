import 'package:equatable/equatable.dart';

import '../../../core/widgets/status_badge.dart';

class Invoice extends Equatable {
  final String id;
  final String clientName;
  final DateTime date;
  final int number;
  final double total;
  final double paid;
  final DocumentStatus status;

  /// Chip label, e.g. "Viewed Jun 5", "Paid Jan 20".
  final String statusNote;

  /// Due line, e.g. "Due Jul 3", "32 days overdue". Empty when paid.
  final String due;
  final bool overdue;

  const Invoice({
    required this.id,
    required this.clientName,
    required this.date,
    required this.number,
    required this.total,
    required this.paid,
    required this.status,
    required this.statusNote,
    required this.due,
    required this.overdue,
  });

  double get balance => total - paid;
  bool get isPaid => status == DocumentStatus.paid;
  bool get isPartial => status == DocumentStatus.partial;
  int get paidPercent => total == 0 ? 0 : (paid / total * 100).round();

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
        id: json['id'] as String,
        clientName: json['clientName'] as String,
        date: DateTime.parse(json['date'] as String),
        number: json['number'] as int,
        total: (json['total'] as num).toDouble(),
        paid: (json['paid'] as num).toDouble(),
        status: DocumentStatus.fromString(json['status'] as String),
        statusNote: json['statusNote'] as String,
        due: json['due'] as String? ?? '',
        overdue: json['overdue'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientName': clientName,
        'date': date.toIso8601String(),
        'number': number,
        'total': total,
        'paid': paid,
        'status': status.name,
        'statusNote': statusNote,
        'due': due,
        'overdue': overdue,
      };

  @override
  List<Object?> get props =>
      [id, clientName, date, number, total, paid, status, statusNote, due, overdue];
}

/// Test data matching the design mockups. Replaced by the API later.
final List<Invoice> mockInvoices = [
  Invoice(id: '95', clientName: 'Zachary Bosma', date: DateTime(2026, 6, 3), number: 95, total: 2500.00, paid: 0, status: DocumentStatus.viewed, statusNote: 'Viewed Jun 5', due: 'Due Jul 3', overdue: false),
  Invoice(id: '94', clientName: 'Praveen Kumar', date: DateTime(2026, 4, 28), number: 94, total: 155000.00, paid: 77500.00, status: DocumentStatus.partial, statusNote: 'Partly paid', due: 'Due Jul 28', overdue: false),
  Invoice(id: '93', clientName: 'Aman Gupta', date: DateTime(2026, 2, 9), number: 93, total: 4200.00, paid: 2100.00, status: DocumentStatus.partial, statusNote: 'Partly paid', due: '32 days overdue', overdue: true),
  Invoice(id: '92', clientName: "Dennis O'Doherty", date: DateTime(2026, 2, 2), number: 92, total: 6900.00, paid: 0, status: DocumentStatus.draft, statusNote: 'Draft', due: 'Not sent', overdue: false),
  Invoice(id: '90', clientName: 'Mary Ellen Melville', date: DateTime(2026, 1, 19), number: 90, total: 9600.00, paid: 3600.00, status: DocumentStatus.partial, statusNote: 'Partly paid', due: '52 days overdue', overdue: true),
  Invoice(id: '89', clientName: 'Robert Chen', date: DateTime(2026, 1, 6), number: 89, total: 12750.00, paid: 12750.00, status: DocumentStatus.paid, statusNote: 'Paid Jan 20', due: '', overdue: false),
  Invoice(id: '87', clientName: 'Karen Whitfield', date: DateTime(2025, 12, 12), number: 87, total: 3350.00, paid: 3350.00, status: DocumentStatus.paid, statusNote: 'Paid Dec 19', due: '', overdue: false),
];
