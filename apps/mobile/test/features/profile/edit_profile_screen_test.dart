import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/core/errors/app_errors.dart';
import 'package:oitenta/core/widgets/bora_buttons.dart';
import 'package:oitenta/features/auth/data/session_store.dart';
import 'package:oitenta/features/auth/domain/auth_user.dart';
import 'package:oitenta/features/profile/presentation/edit_profile_controller.dart';
import 'package:oitenta/features/profile/presentation/edit_profile_screen.dart';

import '../../helpers/test_app.dart';
import '../auth/fake_auth_repository.dart';

const _ana = AuthUser(
  id: 'u1',
  name: 'Ana Souza',
  email: 'ana@bora.app',
  timezone: 'America/Sao_Paulo',
);

void main() {
  late FakeAuthRepository auth;
  late EditProfileController c;
  var saved = 0;

  Future<void> pump(WidgetTester tester) async {
    await usePhoneSize(tester);
    await tester.pumpWidget(
      themed(
        ListenableBuilder(
          listenable: c,
          builder: (_, _) => EditProfileScreen(
            state: c,
            onBack: () {},
            onName: c.setName,
            onEmail: c.setEmail,
            onCurrentPassword: c.setCurrentPassword,
            onSave: () async {
              if (await c.save()) saved++;
            },
          ),
        ),
      ),
    );
  }

  setUp(() {
    saved = 0;
    auth = FakeAuthRepository();
    c = EditProfileController(
      auth,
      SessionStore()..save(const AuthSession(token: 't', user: _ana)),
    );
  });

  testWidgets('mostra o nome e o e-mail atuais; Salvar começa desligado', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Editar perfil'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Ana Souza'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'ana@bora.app'), findsOneWidget);
    expect(find.text('SENHA ATUAL'), findsNothing);
    final button = find.widgetWithText(PrimaryButton, 'Salvar');
    expect(button, findsOneWidget);
    expect(tester.widget<PrimaryButton>(button).onPressed, isNull);
  });

  testWidgets('trocar o nome e salvar chama o backend', (tester) async {
    await pump(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'Ana Souza'),
      'Ana Clara',
    );
    await tester.pump();
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(saved, 1);
    expect(auth.updateArgs.single['name'], 'Ana Clara');
  });

  testWidgets('trocar o e-mail mostra o campo da senha atual', (tester) async {
    await pump(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'ana@bora.app'),
      'ana.nova@bora.app',
    );
    await tester.pump();

    expect(find.text('SENHA ATUAL'), findsOneWidget);
    expect(
      find.text('Pra trocar o e-mail, confirme sua senha atual.'),
      findsOneWidget,
    );
  });

  testWidgets('mostra o erro do backend', (tester) async {
    auth.updateError = ApiFailure(403, 'Senha atual incorreta.');
    c.setEmail('ana.nova@bora.app');
    c.setCurrentPassword('errada');
    await pump(tester);

    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Senha atual incorreta.'), findsOneWidget);
    expect(saved, 0);
  });
}
