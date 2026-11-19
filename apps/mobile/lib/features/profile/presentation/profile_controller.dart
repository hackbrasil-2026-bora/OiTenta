import 'package:flutter/foundation.dart';

import '../../../core/format/bora_format.dart';
import '../../../core/theme/theme_controller.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/data/session_store.dart';
import '../../auth/domain/auth_user.dart';
import '../../scheduling/data/scheduling_repository.dart';

/// Opção do sheet "Idioma" (M28).
typedef LanguageOptionData = ({String code, String name});

/// Perfil (M26).
///
/// - nome e e-mail vêm de `GET /auth/me` (MP6: o subtítulo é o e-mail);
/// - "Máximo por dia" vem de `GET /scheduling/availability`;
/// - "Modo escuro" troca o tema do app de verdade (MP7);
/// - bloquear apps, lembrete e idioma são só visuais, em memória (MP8).
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
