import 'package:flutter/foundation.dart';

import '../../../core/format/bora_format.dart';
import '../../../core/theme/theme_controller.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/data/session_store.dart';
import '../../auth/domain/auth_user.dart';
import '../../scheduling/data/scheduling_repository.dart';
import '../../scheduling/domain/availability.dart';

/// Opção do sheet "Idioma" (M28).
typedef LanguageOptionData = ({String code, String name});

/// Perfil (M26).
///
/// - nome e e-mail vêm de `GET /auth/me` (MP6: o subtítulo é o e-mail);
/// - "Máximo por dia" vem de `GET /scheduling/availability`;
/// - "Modo escuro" troca o tema do app de verdade (MP7);
/// - "Máximo por dia" se edita direto (AT5): grava só o limite, mantendo a
///   grade, com `PUT /scheduling/availability` (que recalcula o plano);
/// - bloquear apps, lembrete, idioma (MP8) e e-mail diário (AT4) são só
///   visuais, em memória.
class ProfileController extends ChangeNotifier {
  ProfileController(this._auth, this._scheduling, this._session, this._theme)
    : _user = _session.user {
    _theme.addListener(notifyListeners);
  }

  static const List<LanguageOptionData> languages = [
    (code: 'pt', name: 'Português (Brasil)'),
    (code: 'en', name: 'English'),
    (code: 'es', name: 'Español'),
  ];

  final AuthRepository _auth;
  final SchedulingRepository _scheduling;
  final SessionStore _session;
  final ThemeController _theme;

  bool loading = false;
  String? error;
  AuthUser? _user;
  int? _dailyLimitMinutes;
  bool _blockApps = true;
  bool _dailyEmail = true;
  bool savingLimit = false;
  String _language = 'pt';

  /// Lê o usuário e a disponibilidade em paralelo. Uma falha não impede a
  /// outra: sem `me()`, vale o usuário da sessão; sem disponibilidade, "—".
  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    final ok = await Future.wait([_loadUser(), _loadLimit()]);
    if (!ok[0]) {
      error = 'Não deu pra carregar o seu perfil.';
    } else if (!ok[1]) {
      error = 'Não deu pra carregar o máximo por dia.';
    }
    loading = false;
    notifyListeners();
  }

  Future<bool> _loadUser() async {
    try {
      _user = await _auth.me();
      return true;
    } catch (_) {
      _user = _session.user;
      return false;
    }
  }

  Future<bool> _loadLimit() async {
    try {
      _dailyLimitMinutes =
          (await _scheduling.getAvailability())?.dailyLimitMinutes;
      return true;
    } catch (_) {
      _dailyLimitMinutes = null;
      return false;
    }
  }

  String get name => _user?.name.trim() ?? '';

  String get initial => name.isEmpty ? '' : name[0].toUpperCase();

  String get subtitle => _user?.email ?? '';

  /// 240 → "4h", 210 → "3h30"; sem disponibilidade, "—".
  String get dailyLimitText {
    final m = _dailyLimitMinutes;
    return m == null ? '—' : BoraFormat.duration(m);
  }

  /// Limite em horas inteiras (1–8), como no "Redefinir minha rotina".
  int get dailyLimitHours =>
      ((_dailyLimitMinutes ?? 240) / 60).round().clamp(1, 8);

  /// Grava só o limite (AT5): relê a grade salva e manda de volta com o
  /// limite novo. Sem rotina cadastrada não há o que manter.
  Future<bool> saveDailyLimit(int hours) async {
    savingLimit = true;
    error = null;
    notifyListeners();
    try {
      final current = await _scheduling.getAvailability();
      if (current == null) {
        error = 'Cadastre sua rotina antes de mudar o máximo por dia.';
        return false;
      }
      final minutes = hours.clamp(1, 8) * 60;
      await _scheduling.setAvailability(
        WeeklyAvailability(
          windows: current.windows,
          dailyLimitMinutes: minutes,
        ),
      );
      _dailyLimitMinutes = minutes;
      return true;
    } catch (_) {
      error = 'Não deu pra salvar o máximo por dia. Tenta de novo?';
      return false;
    } finally {
      savingLimit = false;
      notifyListeners();
    }
  }

  /// Relê nome e e-mail da sessão (depois de Editar perfil, AT3).
  void refreshUser() {
    _user = _session.user ?? _user;
    notifyListeners();
  }

  bool get dailyEmail => _dailyEmail;

  void toggleDailyEmail() {
    _dailyEmail = !_dailyEmail;
    notifyListeners();
  }

  bool get isDark => _theme.isDark;

  String get themeText => isDark ? 'Escuro' : 'Claro';

  void toggleDark() => _theme.toggle();

  bool get blockApps => _blockApps;

  void toggleBlockApps() {
    _blockApps = !_blockApps;
    notifyListeners();
  }

  String get reminderText => '09:30';

  String get language => _language;

  String get languageName =>
      languages.firstWhere((l) => l.code == _language).name;

  void selectLanguage(String code) {
    _language = code;
    notifyListeners();
  }

  @override
  void dispose() {
    _theme.removeListener(notifyListeners);
    super.dispose();
  }
}
