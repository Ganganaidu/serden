import 'package:equatable/equatable.dart';

import 'item_model.dart';

class MarkupTemplate extends Equatable {
  final int id;
  final int proId;
  final String name;
  final MarkupType type;
  final double rate;

  const MarkupTemplate({
    required this.id,
    required this.proId,
    required this.name,
    required this.type,
    required this.rate,
  });

  factory MarkupTemplate.fromJson(Map<String, dynamic> json) => MarkupTemplate(
        id: json['lineItemMarkupId'] as int,
        proId: (json['proId'] as int?) ?? 0,
        name: json['markupName'] as String,
        type: (json['markupType'] as String?) == 'F'
            ? MarkupType.flat
            : MarkupType.percent,
        rate: (json['markupRate'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'proId': proId,
        'markupName': name,
        'markupType': type == MarkupType.flat ? 'F' : 'P',
        'markupRate': rate,
      };

  ItemMarkup toItemMarkup() => ItemMarkup(name: name, type: type, rate: rate);

  String get displayRate {
    final r = rate == rate.roundToDouble()
        ? rate.toStringAsFixed(0)
        : rate.toStringAsFixed(2);
    return type == MarkupType.percent ? '$r%' : '\$$r';
  }

  @override
  List<Object?> get props => [id, proId, name, type, rate];
}
