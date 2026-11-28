import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oitenta/core/errors/app_errors.dart';
import 'package:oitenta/core/theme/theme_controller.dart';
import 'package:oitenta/features/auth/data/auth_repository.dart';
import 'package:oitenta/features/auth/data/session_store.dart';
import 'package:oitenta/features/auth/domain/auth_user.dart';
import 'package:oitenta/features/profile/presentation/profile_controller.dart';
import 'package:oitenta/features/scheduling/data/scheduling_repository.dart';
import 'package:oitenta/features/scheduling/domain/availability.dart';
import 'package:oitenta/features/scheduling/domain/plan.dart';

/// `GET /auth/me` controlado pelo teste: responde na hora ou só quando
/// [gate] for completado.
class _FakeAuth implements AuthRepository {
  _FakeAuth({this.user});

  AuthUser? user;
  Object? error;
  Completer<void>? gate;
  int meCalls = 0;

  @override
  Future<AuthUser> me() async {
    meCalls++;
    if (gate != null) await gate!.future;
    if (error != null) throw error!;
    return user!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// `GET /scheduling/availability` controlado pelo teste.
class _FakeScheduling implements SchedulingRepository {
  _FakeScheduling({this.limit});

  int? limit;
  Object? error;
  Completer<void>? gate;
  int calls = 0;

  @override
  Future<WeeklyAvailability?> getAvailability() async {
    calls++;
    if (gate != null) await gate!.future;
    if (error != null) throw error!;
    final l = limit;
    if (l == null) return null;
    return WeeklyAvailability(windows: _windows, dailyLimitMinutes: l);
  }

  final List<WeeklyAvailability> saved = [];
  Object? setError;

  @override
  Future<SetAvailabilityResult> setAvailability(WeeklyAvailability a) async {
    saved.add(a);
    if (setError != null) throw setError!;
    limit = a.dailyLimitMinutes;
    return SetAvailabilityResult(
      availability: a,
      plan: const PlanSummary(totalMinutes: 0, days: 0, goals: []),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _windows = [
  AvailabilityWindow(weekday: 0, startMinute: 1080, endMinute: 1380),
];

const _meUser = AuthUser(
  id: 'u1',
  name: 'arthur',
  email: 'arthur@bora.app',
  timezone: 'America/Sao_Paulo',
);

const _sessionUser = AuthUser(
  id: 'u1',
  name: 'Beatriz',
  email: 'bia@bora.app',
  timezone: 'America/Sao_Paulo',
);

SessionStore _session([AuthUser? user = _sessionUser]) {
  final s = SessionStore();
  if (user != null) s.save(AuthSession(token: 't', user: user));
  return s;
}

void main() {
  late _FakeAuth auth;
  late _FakeScheduling scheduling;
  late ThemeController theme;

  ProfileController make({SessionStore? session}) =>
      ProfileController(auth, scheduling, session ?? _session(), theme);

  setUp(() {
    auth = _FakeAuth(user: _meUser);
    scheduling = _FakeScheduling(limit: 240);
    theme = ThemeController();
  });

  group('load()', () {
    test('chama me() e getAvailability() em paralelo', () async {
      auth.gate = Completer<void>();
      scheduling.gate = Completer<void>();
      final c = make();
      final done = c.load();
      await Future<void>.delayed(Duration.zero);
      // As duas chamadas saíram antes de qualquer uma responder.
      expect(auth.meCalls, 1);
      expect(scheduling.calls, 1);
      auth.gate!.complete();
      scheduling.gate!.complete();
      await done;
      expect(c.name, 'arthur');
    });

    test('preenche nome, inicial maiúscula, e-mail (MP6) e limite', () async {
      final c = make();
      await c.load();
      expect(c.name, 'arthur');
      expect(c.initial, 'A');
      expect(c.subtitle, 'arthur@bora.app');
      expect(c.dailyLimitText, '4h');
      expect(c.error, isNull);
    });

    test('210 minutos viram "3h30"', () async {
      scheduling.limit = 210;
      final c = make();
      await c.load();
      expect(c.dailyLimitText, '3h30');
    });

    test('60 minutos viram "1h"', () async {
      scheduling.limit = 60;
      final c = make();
      await c.load();
      expect(c.dailyLimitText, '1h');
    });

    test('sem disponibilidade (null), o limite é "—" e não há erro', () async {
      scheduling.limit = null;
      final c = make();
      await c.load();
      expect(c.dailyLimitText, '—');
      expect(c.error, isNull);
    });

    test('se me() falhar, usa o usuário da sessão e guarda um erro', () async {
      auth.error = NetworkFailure('sem rede');
      final c = make();
      await c.load();
      expect(c.name, 'Beatriz');
      expect(c.initial, 'B');
      expect(c.subtitle, 'bia@bora.app');
      expect(c.dailyLimitText, '4h');
      expect(c.error, 'Não deu pra carregar o seu perfil.');
    });

    test('se me() falhar e não houver sessão, nome e inicial vazios', () async {
      auth.error = NetworkFailure('sem rede');
      final c = make(session: _session(null));
      await c.load();
      expect(c.name, '');
      expect(c.initial, '');
      expect(c.subtitle, '');
    });

    test('se getAvailability() falhar, o limite é "—" e há erro', () async {
      scheduling.error = ApiFailure(500, 'erro');
      final c = make();
      await c.load();
      expect(c.name, 'arthur');
      expect(c.dailyLimitText, '—');
      expect(c.error, 'Não deu pra carregar o máximo por dia.');
    });

    test('um load() bem-sucedido limpa o erro anterior', () async {
      scheduling.error = ApiFailure(500, 'erro');
      final c = make();
      await c.load();
      scheduling.error = null;
      await c.load();
      expect(c.error, isNull);
      expect(c.dailyLimitText, '4h');
    });

    test('loading é verdadeiro durante a carga e falso no fim', () async {
      auth.gate = Completer<void>();
      final c = make();
      expect(c.loading, isFalse);
      final done = c.load();
      expect(c.loading, isTrue);
      auth.gate!.complete();
      await done;
      expect(c.loading, isFalse);
    });

    test('loading volta a falso também com erro', () async {
      auth.error = NetworkFailure('sem rede');
      scheduling.error = ApiFailure(500, 'erro');
      final c = make();
      var notified = 0;
      c.addListener(() => notified++);
      await c.load();
      expect(c.loading, isFalse);
      expect(notified, greaterThanOrEqualTo(2));
    });
  });

  group('antes de carregar', () {
    test('mostra o usuário da sessão e o limite "—"', () {
      final c = make();
      expect(c.name, 'Beatriz');
      expect(c.dailyLimitText, '—');
    });
  });

  group('Modo escuro (MP7)', () {
    test('isDark e themeText vêm do ThemeController', () {
      final c = make();
      expect(c.isDark, isFalse);
      expect(c.themeText, 'Claro');
      theme.toggle();
      expect(c.isDark, isTrue);
      expect(c.themeText, 'Escuro');
    });

    test('toggleDark() chama theme.toggle() e avisa os ouvintes', () {
      final c = make();
      var notified = 0;
      c.addListener(() => notified++);
      c.toggleDark();
      expect(theme.isDark, isTrue);
      expect(notified, 1);
    });

    test('depois do dispose, o tema não avisa mais o controlador', () {
      final c = make();
      c.dispose();
      expect(theme.toggle, returnsNormally);
    });
  });

  group('preferências só visuais (MP8)', () {
    test('bloquear apps começa ligado e alterna em memória', () {
      final c = make();
      var notified = 0;
      c.addListener(() => notified++);
      expect(c.blockApps, isTrue);
      c.toggleBlockApps();
      expect(c.blockApps, isFalse);
      c.toggleBlockApps();
      expect(c.blockApps, isTrue);
      expect(notified, 2);
    });

    test('lembrete da rampa é fixo em 09:30', () {
      expect(make().reminderText, '09:30');
    });

    test('idioma começa em pt, "Português (Brasil)"', () {
      final c = make();
      expect(c.language, 'pt');
      expect(c.languageName, 'Português (Brasil)');
    });

    test('as opções de idioma são pt, en e es, nesta ordem', () {
      expect(ProfileController.languages.map((l) => l.code), [
        'pt',
        'en',
        'es',
      ]);
      expect(ProfileController.languages.map((l) => l.name), [
        'Português (Brasil)',
        'English',
        'Español',
      ]);
    });

    test('selectLanguage muda o nome e avisa os ouvintes', () {
      final c = make();
      var notified = 0;
      c.addListener(() => notified++);
      c.selectLanguage('en');
      expect(c.language, 'en');
      expect(c.languageName, 'English');
      c.selectLanguage('es');
      expect(c.languageName, 'Español');
      expect(notified, 2);
    });
  });

  group('E-mail diário (AT4, só visual)', () {
    test('começa ligado e alterna', () {
      final c = make();
      expect(c.dailyEmail, isTrue);
      c.toggleDailyEmail();
      expect(c.dailyEmail, isFalse);
    });
  });

  group('Máximo por dia direto no Perfil (AT5)', () {
    test('dailyLimitHours vem da disponibilidade (210 min → 4h)', () async {
      scheduling.limit = 210;
      final c = make();
      await c.load();
      expect(c.dailyLimitHours, 4);
    });

    test(
      'salvar grava só o limite, mantém a grade e atualiza o texto',
      () async {
        scheduling.limit = 240;
        final c = make();
        await c.load();

        final ok = await c.saveDailyLimit(6);

        expect(ok, isTrue);
        expect(scheduling.saved.single.dailyLimitMinutes, 360);
        expect(scheduling.saved.single.windows, _windows);
        expect(c.dailyLimitText, '6h');
        expect(c.error, isNull);
      },
    );

    test('o limite fica entre 1h e 8h', () async {
      scheduling.limit = 240;
      final c = make();
      await c.load();
      await c.saveDailyLimit(12);
      expect(scheduling.saved.single.dailyLimitMinutes, 480);
    });

    test('sem rotina cadastrada, não grava e explica', () async {
      scheduling.limit = null;
      final c = make();
      await c.load();

      final ok = await c.saveDailyLimit(5);

      expect(ok, isFalse);
      expect(scheduling.saved, isEmpty);
      expect(c.error, 'Cadastre sua rotina antes de mudar o máximo por dia.');
    });

    test('falha ao gravar mantém o valor antigo e mostra o erro', () async {
      scheduling.limit = 240;
      final c = make();
      await c.load();
      scheduling.setError = NetworkFailure('sem rede');

      final ok = await c.saveDailyLimit(6);

      expect(ok, isFalse);
      expect(c.dailyLimitText, '4h');
      expect(c.error, 'Não deu pra salvar o máximo por dia. Tenta de novo?');
    });
  });

  test(
    'refreshUser lê o usuário da sessão (depois de Editar perfil)',
    () async {
      final session = _session();
      final c = make(session: session);
      session.updateUser(
        const AuthUser(
          id: 'u1',
          name: 'Beatriz Lima',
          email: 'bia@bora.app',
          timezone: 'America/Sao_Paulo',
        ),
      );
      c.refreshUser();
      expect(c.name, 'Beatriz Lima');
    },
  );

  group('AT8 e AT9', () {
    test('lembrete começa às 09:30 e muda de horário (só visual)', () {
      final c = make();
      expect(c.reminderText, '09:30');
      c.setReminder(7, 5);
      expect(c.reminderText, '07:05');
      expect(c.reminderHour, 7);
      expect(c.reminderMinute, 5);
    });

    test('logout limpa a sessão', () {
      final session = _session();
      final c = make(session: session);
      c.logout();
      expect(session.session, isNull);
    });
  });
}
