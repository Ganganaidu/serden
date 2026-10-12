/// The API ignores line items nested inside a section that doesn't exist yet,
/// and has no id to give a brand-new section until it creates it. So new
/// sections are saved in two steps:
///
/// 1. Save the document with the section (no items inside it) and every line
///    item in the main `lineItems` list, unlinked.
/// 2. Read the new section ids from the response and save again with each line
///    item pointing at its section.
///
/// Rows that belong to a NEW section carry a temporary negative `sectionId`
/// of `-(sectionSortOrder + 1)` until step 2.
class SectionLinker {
  SectionLinker._();

  static bool _isTemp(Object? id) => id is num && id < 0;

  static bool hasTempSections(List<Map<String, dynamic>> lineItems) =>
      lineItems.any((li) => _isTemp(li['sectionId']));

  /// Line items with the temporary section ids removed (safe to send).
  static List<Map<String, dynamic>> withoutTemp(
          List<Map<String, dynamic>> lineItems) =>
      [
        for (final li in lineItems)
          if (_isTemp(li['sectionId']))
            (Map<String, dynamic>.of(li)..remove('sectionId'))
          else
            li,
      ];

  /// Builds the second-step body: the saved document from [saved] with its
  /// line items pointed at the sections the API just created. Returns null if
  /// the saved items can't be matched up with the ones that were sent.
  static Map<String, dynamic>? link(
    List<Map<String, dynamic>> sentItems,
    Map<String, dynamic> saved,
  ) {
    int order(Map<String, dynamic> m) => (m['sortOrder'] as num?)?.toInt() ?? 0;
    int id(Map<String, dynamic> m) => (m['lineItemId'] as num?)?.toInt() ?? 0;

    final sent = [...sentItems]..sort((a, b) => order(a).compareTo(order(b)));
    final items = <Map<String, dynamic>>[
      for (final li in (saved['lineItems'] as List? ?? const []))
        Map<String, dynamic>.of(li as Map<String, dynamic>),
    ]..sort((a, b) {
        final byOrder = order(a).compareTo(order(b));
        return byOrder != 0 ? byOrder : id(a).compareTo(id(b));
      });
    if (items.isEmpty || items.length != sent.length) return null;

    final sectionBySort = <int, Object?>{
      for (final s in (saved['sections'] as List? ?? const []))
        order(s as Map<String, dynamic>): s['sectionId'],
    };

    for (var i = 0; i < items.length; i++) {
      final temp = sent[i]['sectionId'];
      if (!_isTemp(temp)) continue;
      final sectionId = sectionBySort[-(temp as num).toInt() - 1];
      if (sectionId != null) items[i]['sectionId'] = sectionId;
    }
    return Map<String, dynamic>.of(saved)..['lineItems'] = items;
  }
}
