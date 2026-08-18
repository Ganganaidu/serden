import 'package:equatable/equatable.dart';

enum MarkupType { percent, flat }

class ItemMarkup extends Equatable {
  final String? name;
  final MarkupType type;
  final double rate;

  const ItemMarkup({
    this.name,
    this.type = MarkupType.percent,
    this.rate = 0,
  });

  static const none = ItemMarkup();

  bool get hasMarkup => rate > 0;

  String get apiType => type == MarkupType.percent ? 'P' : 'F';

  String get displayRate {
    final r = rate == rate.roundToDouble()
        ? rate.toStringAsFixed(0)
        : rate.toStringAsFixed(2);
    return type == MarkupType.percent ? '$r%' : '\$$r';
  }

  static ItemMarkup fromApi(
      String? markupName, String? markupType, double? markupRate) {
    if (markupRate == null || markupRate == 0) return const ItemMarkup();
    return ItemMarkup(
      name: markupName,
      type: markupType == 'F' ? MarkupType.flat : MarkupType.percent,
      rate: markupRate,
    );
  }

  @override
  List<Object?> get props => [name, type, rate];
}

class Item extends Equatable {
  final int itemId;
  final int proId;
  final String name;
  final String? description;
  final double? unitPrice;
  final String? unit;
  final ItemMarkup markup;
  final String? privateNote;

  const Item({
    required this.itemId,
    required this.proId,
    required this.name,
    this.description,
    this.unitPrice,
    this.unit,
    this.markup = ItemMarkup.none,
    this.privateNote,
  });

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        itemId: json['lineItemId'] as int,
        proId: (json['proId'] as int?) ?? 0,
        name: json['itemName'] as String,
        description: json['description'] as String?,
        unitPrice: (json['rate'] as num?)?.toDouble(),
        unit: json['unit'] as String?,
        markup: ItemMarkup.fromApi(
          json['markupName'] as String?,
          json['markupType'] as String?,
          (json['markupRate'] as num?)?.toDouble(),
        ),
        privateNote: json['privateNote'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'lineItemId': itemId,
        'proId': proId,
        'itemName': name,
        if (unitPrice != null) 'rate': unitPrice,
        if (description != null) 'description': description,
        if (unit != null) 'unit': unit,
        'markupName': markup.hasMarkup ? markup.name : null,
        'markupType': markup.hasMarkup ? markup.apiType : null,
        'markupRate': markup.hasMarkup ? markup.rate : null,
        if (privateNote != null) 'privateNote': privateNote,
      };

  Item copyWith({
    int? itemId,
    int? proId,
    String? name,
    String? description,
    double? unitPrice,
    String? unit,
    ItemMarkup? markup,
    String? privateNote,
  }) =>
      Item(
        itemId: itemId ?? this.itemId,
        proId: proId ?? this.proId,
        name: name ?? this.name,
        description: description ?? this.description,
        unitPrice: unitPrice ?? this.unitPrice,
        unit: unit ?? this.unit,
        markup: markup ?? this.markup,
        privateNote: privateNote ?? this.privateNote,
      );

  @override
  List<Object?> get props =>
      [itemId, proId, name, description, unitPrice, unit, markup, privateNote];
}

const _mockItems = [
  Item(itemId: 1, proId: 1, name: 'ADA walk-in shower with curbless tile pan', unitPrice: 4800, unit: 'each', description: 'Labor and materials'),
  Item(itemId: 2, proId: 1, name: 'Add electrical outlet', unitPrice: 185, unit: 'each', description: 'Labor and materials'),
  Item(itemId: 3, proId: 1, name: 'Additional work and notes', description: 'Custom scope — priced per job'),
  Item(itemId: 4, proId: 1, name: 'Attic remodel', unitPrice: 95, unit: 'sq ft', description: 'Labor and materials'),
  Item(itemId: 5, proId: 1, name: 'Baseboard installation', unitPrice: 6.5, unit: 'linear ft', description: 'Material extra'),
  Item(itemId: 6, proId: 1, name: 'Cabinet installation', unitPrice: 120, unit: 'unit', description: 'Labor only'),
  Item(itemId: 7, proId: 1, name: 'Countertop — quartz, supply and install', unitPrice: 75, unit: 'sq ft', description: 'Includes template and cutouts'),
  Item(itemId: 8, proId: 1, name: 'Demolition and haul away', unitPrice: 850, unit: 'flat', description: 'Per room, dump fees included'),
  Item(itemId: 9, proId: 1, name: 'Drywall — hang, tape, and texture', unitPrice: 3.25, unit: 'sq ft', description: 'Level 4 finish'),
  Item(itemId: 10, proId: 1, name: 'Flooring — LVP, supply and install', unitPrice: 7.5, unit: 'sq ft', description: 'Underlayment included'),
  Item(itemId: 11, proId: 1, name: 'Kitchen faucet replacement', unitPrice: 265, unit: 'each', description: 'Fixture extra'),
  Item(itemId: 12, proId: 1, name: 'Paint — interior walls', unitPrice: 2.8, unit: 'sq ft', description: 'Two coats, paint included'),
  Item(itemId: 13, proId: 1, name: 'Permit fees', description: 'Billed at cost'),
  Item(itemId: 14, proId: 1, name: 'Plumbing drain relocation', unitPrice: 1150, unit: 'flat', description: 'Up to 5 ft'),
  Item(itemId: 15, proId: 1, name: 'Tile shower surround', unitPrice: 2400, unit: 'each', description: 'Standard tub surround, tile extra'),
  Item(itemId: 16, proId: 1, name: 'Water heater replacement', unitPrice: 2450, unit: 'each', description: '50-gal tank, haul away included'),
];

List<Item> get mockItems => List.unmodifiable(_mockItems);
