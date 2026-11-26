import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('tocar fora do campo de texto fecha o teclado (tira o foco)', (
    tester,
  ) async {
    await pumpApp(tester);
    final field = find.byType(EditableText).first;
    await tester.tap(field);
    await tester.pump();
    expect(tester.widget<EditableText>(field).focusNode.hasFocus, isTrue);

    // Toca numa área sem botão nem campo (canto do topo).
    await tester.tapAt(const Offset(4, 4));
    await tester.pump();
    expect(tester.widget<EditableText>(field).focusNode.hasFocus, isFalse);
  });

  testWidgets('tocar no próprio campo mantém o foco', (tester) async {
    await pumpApp(tester);
    final field = find.byType(EditableText).first;
    await tester.tap(field);
    await tester.pump();
    await tester.tap(field);
    await tester.pump();
    expect(tester.widget<EditableText>(field).focusNode.hasFocus, isTrue);
  });
}
