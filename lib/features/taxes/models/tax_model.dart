import 'package:equatable/equatable.dart';

class TaxRate extends Equatable {
  final int id;
  final int proId;
  final String name;

  /// Percentage value — e.g. 5.0 means 5%.
  final double rate;

  const TaxRate({
    required this.id,
    required this.proId,
    required this.name,
    required this.rate,
  });

  factory TaxRate.fromJson(Map<String, dynamic> json) => TaxRate(
        id: json['taxId'] as int,
        proId: (json['proId'] as int?) ?? 0,
        name: json['taxName'] as String,
        rate: (json['taxRate'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'proId': proId,
        'taxName': name,
        'taxRate': rate,
      };

  TaxRate copyWith({String? name, double? rate}) => TaxRate(
        id: id,
        proId: proId,
        name: name ?? this.name,
        rate: rate ?? this.rate,
      );

  /// Display string: "5.00%"
  String get displayRate => '${rate.toStringAsFixed(2)}%';

  @override
  List<Object?> get props => [id, proId, name, rate];
}
