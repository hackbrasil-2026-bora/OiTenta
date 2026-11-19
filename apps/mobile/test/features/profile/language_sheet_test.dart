import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/core/theme/app_theme.dart';
import 'package:oitenta/features/profile/presentation/language_sheet.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../helpers/test_app.dart';

/// Sheet "Idioma" (M28): 3 opções, a atual com check; escolher devolve o código.
void main() {
  Finder checkIn(String name) => find.descendant(
    of: find.ancestor(
      of: find.text(name),
      matching: find.byType(LanguageOption),
    ),
    matching: find.byIcon(PhosphorIconsFill.checkCircle),
  );

  testWidgets('lista as 3 opções com check só na atual', (tester) async {
    await usePhoneSize(tester);
    await tester.pumpWidget(
      themed(LanguageSheet(current: 'pt', onSelect: (_) {})),
    );
    expect(find.text('Idioma'), findsOneWidget);
    expect(find.text('Português (Brasil)'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Español'), findsOneWidget);
    expect(find.byIcon(PhosphorIconsFill.checkCircle), findsOneWidget);
    expect(checkIn('Português (Brasil)'), findsOneWidget);
  });

  testWidgets('a atual pode ser outra', (tester) async {
    await usePhoneSize(tester);
    await tester.pumpWidget(
      themed(LanguageSheet(current: 'es', onSelect: (_) {})),
    );
    expect(checkIn('Español'), findsOneWidget);
    expect(checkIn('Português (Brasil)'), findsNothing);
  });

  testWidgets('tocar uma opção avisa o código', (tester) async {
    await usePhoneSize(tester);
    String? picked;
    await tester.pumpWidget(
      themed(LanguageSheet(current: 'pt', onSelect: (c) => picked = c)),
    );
    await tester.tap(find.text('English'));
    expect(picked, 'en');
  });

  testWidgets('showLanguageSheet fecha e devolve o código escolhido', (
    tester,
  ) async {
    await usePhoneSize(tester);
    String? result = 'nada';
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async =>
                result = await showLanguageSheet(context, current: 'pt'),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.byType(LanguageSheet), findsOneWidget);
    await tester.tap(find.text('Español'));
    await tester.pumpAndSettle();
    expect(find.byType(LanguageSheet), findsNothing);
    expect(result, 'es');
  });
}
