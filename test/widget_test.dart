import 'package:flutter_test/flutter_test.dart';
import 'package:serden/app.dart';
import 'package:serden/core/di/injection.dart';

void main() {
  setUpAll(() => Injection.init());

  testWidgets('App smoke test', (tester) async {
    await tester.pumpWidget(const SerdenApp());
    await tester.pump();
  });
}
