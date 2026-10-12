import 'package:flutter_test/flutter_test.dart';
import 'package:Serden/shared/utils/section_linker.dart';

void main() {
  // Two rows in a new section (temp id -1) and one loose row.
  final sent = <Map<String, dynamic>>[
    {'lineItemId': 0, 'description': 'A', 'sortOrder': 0, 'sectionId': -1},
    {'lineItemId': 0, 'description': 'B', 'sortOrder': 1, 'sectionId': -1},
    {'lineItemId': 0, 'description': 'C', 'sortOrder': 2},
  ];

  test('temp section ids are stripped before sending', () {
    expect(SectionLinker.hasTempSections(sent), isTrue);
    final clean = SectionLinker.withoutTemp(sent);
    expect(clean.every((li) => !li.containsKey('sectionId')), isTrue);
    expect(SectionLinker.hasTempSections(clean), isFalse);
  });

  test('saved line items are pointed at the section the API created', () {
    // Server renumbers sortOrder (1-based) and assigns ids / a section id.
    final saved = <String, dynamic>{
      'estimateId': 76,
      'sections': [
        {'sectionId': 103, 'name': 'Kitchen', 'sortOrder': 0, 'lineItems': []},
      ],
      'lineItems': [
        {'lineItemId': 502, 'description': 'C', 'sortOrder': 3},
        {'lineItemId': 500, 'description': 'A', 'sortOrder': 1},
        {'lineItemId': 501, 'description': 'B', 'sortOrder': 2},
      ],
    };
    final body = SectionLinker.link(sent, saved)!;
    final items = body['lineItems'] as List;
    Map<String, dynamic> byDesc(String d) =>
        items.cast<Map<String, dynamic>>().firstWhere((i) => i['description'] == d);
    expect(byDesc('A')['sectionId'], 103);
    expect(byDesc('B')['sectionId'], 103);
    expect(byDesc('C').containsKey('sectionId'), isFalse);
  });

  test('returns null when the saved items do not match what was sent', () {
    final saved = <String, dynamic>{'sections': [], 'lineItems': []};
    expect(SectionLinker.link(sent, saved), isNull);
  });
}
