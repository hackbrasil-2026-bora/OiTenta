import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/core/errors/app_errors.dart';
import 'package:oitenta/features/profile/presentation/suggestion_controller.dart';

import 'suggestion_fakes.dart';

void main() {
  late FakeFeedbackRepository repo;
  late SuggestionController c;
  setUp(() {
    repo = FakeFeedbackRepository();
    c = SuggestionController(repo);
  });

  test('começa vazio, sem poder enviar', () {
    expect(c.text, '');
    expect(c.canSend, isFalse);
    expect(c.busy, isFalse);
    expect(c.error, isNull);
  });

  test('setText guarda o texto e avisa os ouvintes', () {
    var calls = 0;
    c.addListener(() => calls++);
    c.setText('Oi');
    expect(c.text, 'Oi');
    expect(calls, 1);
  });

  test('canSend exige texto não vazio depois de aparar', () {
    c.setText('   \n ');
    expect(c.canSend, isFalse);
    c.setText('  ideia  ');
    expect(c.canSend, isTrue);
  });

  test('send envia o texto aparado e devolve true', () async {
    c.setText('  queria mudar a cor  ');
    expect(await c.send(), isTrue);
    expect(repo.sent, ['queria mudar a cor']);
    expect(c.busy, isFalse);
    expect(c.error, isNull);
  });

  test('send sem texto não chama o repositório e devolve false', () async {
    c.setText('   ');
    expect(await c.send(), isFalse);
    expect(repo.sent, isEmpty);
  });

  test('com erro, mostra a mensagem e devolve false', () async {
    repo.error = NetworkFailure('sem rede');
    c.setText('ideia');
    expect(await c.send(), isFalse);
    expect(c.error, 'Não deu pra enviar agora. Tenta de novo?');
    expect(c.busy, isFalse);
  });

  test('um novo envio limpa o erro anterior', () async {
    repo.error = NetworkFailure('sem rede');
    c.setText('ideia');
    await c.send();
    repo.error = null;
    expect(await c.send(), isTrue);
    expect(c.error, isNull);
  });

  test('não envia duas vezes enquanto busy', () async {
    repo.gate = Completer<void>();
    c.setText('ideia');
    final first = c.send();
    expect(c.busy, isTrue);
    expect(c.canSend, isFalse);
    expect(await c.send(), isFalse);
    repo.gate!.complete();
    expect(await first, isTrue);
    expect(repo.sent, ['ideia']);
    expect(c.busy, isFalse);
  });

  test('busy avisa os ouvintes no início e no fim', () async {
    c.setText('ideia');
    final seen = <bool>[];
    c.addListener(() => seen.add(c.busy));
    await c.send();
    expect(seen, [true, false]);
  });
}
