import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/features/auth/domain/auth_rules.dart';

void main() {
  group('isEmail (regex do protótipo, aparado)', () {
    for (final ok in ['a@b.co', 'arthur@bora.app', '  arthur@bora.app  ']) {
      test('aceita "$ok"', () => expect(AuthRules.isEmail(ok), isTrue));
    }
    for (final bad in ['', '   ', 'arthur', 'a@b', '@b.co', 'a b@c.co']) {
      test('recusa "$bad"', () => expect(AuthRules.isEmail(bad), isFalse));
    }
  });

  group('isStrongPassword (MP1: regra do backend)', () {
    test(
      'aceita 8+ com maiúscula, minúscula, número e símbolo',
      () => expect(AuthRules.isStrongPassword('Senha@12'), isTrue),
    );
    for (final bad in [
      'Senh@1', // 6 caracteres
      'Senha@1', // 7 caracteres
      'senha@123', // sem maiúscula
      'SENHA@123', // sem minúscula
      'Senha@abc', // sem número
      'Senha1234', // sem símbolo
      '',
    ]) {
      test(
        'recusa "$bad"',
        () => expect(AuthRules.isStrongPassword(bad), isFalse),
      );
    }
  });

  group('isDisplayName (MP2: uma palavra ou mais, 2–80)', () {
    for (final ok in [
      'Arthur',
      'Ana Souza',
      'João-Pedro',
      "D'Ávila",
      'Ana  Souza',
      '  Bia  ',
      'Al',
      'a' * 80,
    ]) {
      test(
        'aceita "${ok.length > 20 ? '${ok.length} letras' : ok}"',
        () => expect(AuthRules.isDisplayName(ok), isTrue),
      );
    }
    for (final bad in [
      '',
      '   ',
      'A',
      ' A ',
      'Arthur2',
      '@na',
      'Ana_',
      '-Ana',
      'a' * 81,
    ]) {
      test(
        'recusa "${bad.length > 20 ? '${bad.length} letras' : bad}"',
        () => expect(AuthRules.isDisplayName(bad), isFalse),
      );
    }
  });

  group('firstNameOf', () {
    test(
      '"Ana Souza" → "Ana"',
      () => expect(AuthRules.firstNameOf('Ana Souza'), 'Ana'),
    );
    test(
      'apara e ignora espaços repetidos',
      () => expect(AuthRules.firstNameOf('  Bia   Lima '), 'Bia'),
    );
    test('vazio → vazio', () => expect(AuthRules.firstNameOf('  '), ''));
  });
}
