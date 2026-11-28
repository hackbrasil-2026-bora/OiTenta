import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/features/auth/data/session_store.dart';
import 'package:oitenta/features/auth/domain/auth_user.dart';

const _s = AuthSession(
  token: 't',
  user: AuthUser(
    id: 'u',
    name: 'A',
    email: 'a@b.c',
    timezone: 'America/Sao_Paulo',
  ),
);

void main() {
  test('expire limpa a sessão, marca expirada e avisa os ouvintes', () {
    final store = SessionStore()..save(_s);
    var notified = 0;
    store.addListener(() => notified++);
    store.expire();
    expect(store.session, isNull);
    expect(store.expired, isTrue);
    expect(notified, 1);
  });

  test('consumeExpired devolve true uma vez só', () {
    final store = SessionStore()..expire();
    expect(store.consumeExpired(), isTrue);
    expect(store.consumeExpired(), isFalse);
    expect(store.expired, isFalse);
  });

  test('save depois de expirar tira a marca', () {
    final store = SessionStore()..expire();
    store.save(_s);
    expect(store.expired, isFalse);
    expect(store.token, 't');
  });

  test('updateUser troca o usuário e mantém o token, sem avisar o router', () {
    final store = SessionStore()
      ..save(
        const AuthSession(
          token: 'tok',
          user: AuthUser(
            id: 'u1',
            name: 'Ana',
            email: 'ana@bora.app',
            timezone: 'America/Sao_Paulo',
          ),
        ),
      );
    var notified = 0;
    store.addListener(() => notified++);

    store.updateUser(
      const AuthUser(
        id: 'u1',
        name: 'Ana Clara',
        email: 'ana@bora.app',
        timezone: 'America/Sao_Paulo',
      ),
    );

    expect(store.user!.name, 'Ana Clara');
    expect(store.token, 'tok');
    // Os ouvintes (o router) só reagem à expiração; avisar aqui recalcularia
    // a navegação no meio do "voltar" do Editar perfil.
    expect(notified, 0);
  });
}
