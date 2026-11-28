import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/core/widgets/bora_buttons.dart';
import 'package:oitenta/core/widgets/bora_widgets.dart';
import 'package:oitenta/features/profile/presentation/daily_limit_sheet.dart';

import '../../helpers/test_app.dart';

/// "Máximo por dia" direto no Perfil (AT5).
void main() {
  testWidgets('mostra o valor atual e devolve o novo ao salvar', (
    tester,
  ) async {
    await usePhoneSize(tester);
    int? saved;
    await tester.pumpWidget(
      themed(DailyLimitSheet(initialHours: 4, onSave: (h) => saved = h)),
    );

    expect(find.text('Máximo por dia'), findsOneWidget);
    expect(find.text('4h'), findsOneWidget);

    final slider = tester.widget<BoraSlider>(find.byType(BoraSlider));
    slider.onChanged(6);
    await tester.pump();
    expect(find.text('6h'), findsOneWidget);

    await tester.tap(find.widgetWithText(PrimaryButton, 'Salvar'));
    expect(saved, 6);
  });

  testWidgets('o controle vai de 1h a 8h, de hora em hora', (tester) async {
    await usePhoneSize(tester);
    await tester.pumpWidget(
      themed(DailyLimitSheet(initialHours: 4, onSave: (_) {})),
    );

    final slider = tester.widget<BoraSlider>(find.byType(BoraSlider));
    expect(slider.min, 1);
    expect(slider.max, 8);
    expect(slider.step, 1);
  });
}
