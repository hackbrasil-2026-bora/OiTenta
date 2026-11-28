import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/core/errors/app_errors.dart';
import 'package:oitenta/core/widgets/bora_buttons.dart';
import 'package:oitenta/features/auth/data/session_store.dart';
import 'package:oitenta/features/auth/domain/auth_user.dart';
import 'package:oitenta/features/profile/presentation/change_password_controller.dart';
import 'package:oitenta/features/profile/presentation/change_password_screen.dart';
import 'package:oitenta/features/profile/presentation/delete_account_controller.dart';
import 'package:oitenta/features/profile/presentation/delete_account_screen.dart';
import 'package:oitenta/features/profile/presentation/logout_sheet.dart';

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
  setUp(() => auth = FakeAuthRepository());

  group('Trocar senha', () {
    testWidgets('três campos; Salvar só com tudo certo', (tester) async {
      await usePhoneSize(tester);
      final c = ChangePasswordController(auth);
      var saved = 0;
      await tester.pumpWidget(
        themed(
          ListenableBuilder(
            listenable: c,
            builder: (_, _) => ChangePasswordScreen(
              state: c,
              onBack: () {},
              onCurrent: c.setCurrent,
              onNew: c.setNew,
              onConfirm: c.setConfirm,
              onSave: () => saved++,
            ),
          ),
        ),
      );

      expect(find.text('Trocar senha'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(3));
      PrimaryButton button() => tester.widget<PrimaryButton>(
        find.widgetWithText(PrimaryButton, 'Salvar senha'),
      );
      expect(button().onPressed, isNull);

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Senha@123');
      await tester.enterText(fields.at(1), 'Nova@4567');
      await tester.enterText(fields.at(2), 'Outra@4567');
      await tester.pump();
      expect(find.text('As senhas não batem.'), findsOneWidget);

      await tester.enterText(fields.at(2), 'Nova@4567');
      await tester.pump();
      await tester.tap(find.text('Salvar senha'));
      expect(saved, 1);
    });
  });

  group('Apagar conta', () {
    testWidgets('explica o que some e só apaga com a senha', (tester) async {
      await usePhoneSize(tester);
      final c = DeleteAccountController(
        auth,
        SessionStore()..save(const AuthSession(token: 't', user: _ana)),
      );
      var deleted = 0;
      await tester.pumpWidget(
        themed(
          ListenableBuilder(
            listenable: c,
            builder: (_, _) => DeleteAccountScreen(
              state: c,
              onBack: () {},
              onPassword: c.setPassword,
              onDelete: () => deleted++,
            ),
          ),
        ),
      );

      expect(find.text('Apagar conta'), findsOneWidget);
      expect(
        find.textContaining('objetivos, etapas, plano, sessões de foco'),
        findsOneWidget,
      );
      await tester.tap(find.text('Apagar minha conta'));
      expect(deleted, 0, reason: 'sem a senha não apaga');

      await tester.enterText(find.byType(TextField), 'Senha@123');
      await tester.pump();
      await tester.tap(find.text('Apagar minha conta'));
      expect(deleted, 1);
    });

    testWidgets('mostra o erro do backend', (tester) async {
      await usePhoneSize(tester);
      auth.deleteError = ApiFailure(403, 'A conta demo não pode ser apagada.');
      final c = DeleteAccountController(
        auth,
        SessionStore()..save(const AuthSession(token: 't', user: _ana)),
      )..setPassword('x');
      await c.delete();
      await tester.pumpWidget(
        themed(
          DeleteAccountScreen(
            state: c,
            onBack: () {},
            onPassword: c.setPassword,
            onDelete: () {},
          ),
        ),
      );
      expect(find.text('A conta demo não pode ser apagada.'), findsOneWidget);
    });
  });

  testWidgets('Sair da conta: confirma ou cancela', (tester) async {
    await usePhoneSize(tester);
    var confirmed = 0;
    var cancelled = 0;
    await tester.pumpWidget(
      themed(
        LogoutSheet(onConfirm: () => confirmed++, onCancel: () => cancelled++),
      ),
    );
    expect(find.text('Sair da conta?'), findsOneWidget);
    await tester.tap(find.text('Sair'));
    await tester.tap(find.text('Cancelar'));
    expect(confirmed, 1);
    expect(cancelled, 1);
  });
}
