import 'package:flutter_test/flutter_test.dart';

import 'package:docword/main.dart';

void main() {
  testWidgets('DocWord abre o editor principal', (WidgetTester tester) async {
    await tester.pumpWidget(const DocWordApp());

    expect(find.text('DocWord'), findsOneWidget);
    expect(find.text('Documento sem título'), findsOneWidget);
    expect(find.text('Comece a escrever...'), findsOneWidget);
  });
}
