import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:docword/app/docword_app.dart';

void main() {
  testWidgets('DocWord abre o editor principal', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const DocWordApp());
    await tester.pumpAndSettle();

    expect(find.text('DocWord'), findsOneWidget);
    expect(find.text('Documento sem título'), findsOneWidget);
    expect(find.text('A4 • Rich Text'), findsOneWidget);
  });
}
