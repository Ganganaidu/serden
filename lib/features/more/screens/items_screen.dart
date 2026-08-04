import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_fab.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/main_shell.dart';

class _Item {
  final String name;
  final double? price;
  final String unit;
  final String sub;

  const _Item(this.name, this.price, this.unit, this.sub);
}

/// Saved items catalog with alphabetical index (serden-items design).
class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  static const _letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  // Real items API isn't wired up yet — show sample data only in mock
  // mode; a real logged-in user starts with none (empty state).
  static List<_Item> get _items =>
      AppConfig.useMockData ? _mockItems : const [];

  static const _mockItems = [
    _Item('ADA walk-in shower with curbless tile pan', 4800, 'each', 'Labor and materials'),
    _Item('Add electrical outlet', 185, 'each', 'Labor and materials'),
    _Item('Additional work and notes', null, '', 'Custom scope — priced per job'),
    _Item('Attic remodel', 95, 'sq ft', 'Labor and materials'),
    _Item('Baseboard installation', 6.5, 'linear ft', 'Material extra'),
    _Item('Cabinet installation', 120, 'unit', 'Labor only'),
    _Item('Countertop — quartz, supply and install', 75, 'sq ft', 'Includes template and cutouts'),
    _Item('Demolition and haul away', 850, 'flat', 'Per room, dump fees included'),
    _Item('Drywall — hang, tape, and texture', 3.25, 'sq ft', 'Level 4 finish'),
    _Item('Flooring — LVP, supply and install', 7.5, 'sq ft', 'Underlayment included'),
    _Item('Kitchen faucet replacement', 265, 'each', 'Fixture extra'),
    _Item('Paint — interior walls', 2.8, 'sq ft', 'Two coats, paint included'),
    _Item('Permit fees', null, '', 'Billed at cost'),
    _Item('Plumbing drain relocation', 1150, 'flat', 'Up to 5 ft'),
    _Item('Tile shower surround', 2400, 'each', 'Standard tub surround, tile extra'),
    _Item('Water heater replacement', 2450, 'each', '50-gal tank, haul away included'),
  ];

  final Map<String, GlobalKey> _sectionKeys = {};
  String _search = '';

  Map<String, List<_Item>> get _grouped {
    final q = _search.trim().toLowerCase();
    final rows = _items
        .where((i) =>
            q.isEmpty ||
            i.name.toLowerCase().contains(q) ||
            i.sub.toLowerCase().contains(q))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final groups = <String, List<_Item>>{};
    for (final item in rows) {
      final letter = item.name[0].toUpperCase();
      final key = _letters.contains(letter) ? letter : '#';
      groups.putIfAbsent(key, () => []).add(item);
    }
    return groups;
  }

  void _jumpTo(String letter) {
    final key = _sectionKeys[letter];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  String _money(double value) {
    final hasCents = value != value.roundToDouble();
    return '\$${value.toStringAsFixed(hasCents ? 2 : 0)}';
  }

  @override
  Widget build(BuildContext context) {
    final groups = _grouped;
    _sectionKeys.clear();
    for (final letter in groups.keys) {
      _sectionKeys[letter] = GlobalKey();
    }

    return Scaffold(
      body: Column(
        children: [
          Container(
            color: AppColors.green800,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 6,
              left: 20,
              right: 20,
              bottom: 18,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => context.pop(),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.arrow_back_ios_new,
                            size: 14, color: Color(0xCCFFFFFF)),
                        SizedBox(width: 4),
                        Text(
                          'More',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xCCFFFFFF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text('Items', style: AppTextStyles.headerTitle),
                const SizedBox(height: 3),
                Text(
                  '${_items.length} saved items · drop them into any estimate or invoice',
                  style: AppTextStyles.headerSubtitle,
                ),
                HeaderSearchBar(
                  hint: 'Search your saved items',
                  onChanged: (v) => setState(() => _search = v),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                if (groups.isEmpty)
                  const EmptyState(
                    title: 'No matches',
                    description:
                        'Try a different name — or add it as a new item.',
                  )
                else
                  ListView(
                    padding: const EdgeInsets.only(right: 34, bottom: 96),
                    children: [
                      for (final entry in groups.entries) ...[
                        Padding(
                          key: _sectionKeys[entry.key],
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ),
                        for (final item in entry.value) _row(item),
                      ],
                    ],
                  ),
                Positioned(
                  right: 4,
                  top: 10,
                  bottom: 10,
                  child: _indexBar(groups.keys.toSet()),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: AppFab(label: 'New item', onPressed: () {}),
    );
  }

  Widget _row(_Item item) {
    return Material(
      color: AppColors.card,
      child: InkWell(
        onTap: () {},
        child: Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.line)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 13, 16, 13),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: AppTextStyles.rowTitle
                          .copyWith(fontSize: 14.5, height: 1.35),
                    ),
                    if (item.sub.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(item.sub,
                          style:
                              AppTextStyles.caption.copyWith(fontSize: 12)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (item.price != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _money(item.price!),
                      style: AppTextStyles.rowAmount.copyWith(fontSize: 14.5),
                    ),
                    Text(
                      '/ ${item.unit}',
                      style: AppTextStyles.caption.copyWith(
                          fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                )
              else
                Text(
                  'Price varies',
                  style: AppTextStyles.caption
                      .copyWith(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _indexBar(Set<String> available) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final letter in _letters.split(''))
          GestureDetector(
            onTap: available.contains(letter) ? () => _jumpTo(letter) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                letter,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                  color: available.contains(letter)
                      ? AppColors.greenDeep
                      : const Color(0xFFC9CFC9),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
