/// Regras dos campos de Entrar e Criar conta, conferidas antes de enviar.
class AuthRules {
  const AuthRules._();

  /// Mesmo teste do protótipo (`okMail`), com o valor aparado.
  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static const _namePart = r"[\p{L}\p{M}]+(?:['-][\p{L}\p{M}]+)*";

  /// Uma palavra ou mais, só letras (acentos, hífen e apóstrofo valem) (MP2).
  static final _name = RegExp(
    '^$_namePart(?:\\s+$_namePart)*\$',
    unicode: true,
  );

  static bool isEmail(String value) => _email.hasMatch(value.trim());

  /// Regra do backend (`StrongPasswordRule`, MP1): 8 ou mais caracteres, com
  /// maiúscula, minúscula, número e símbolo.
  static bool isStrongPassword(String value) =>
      value.length >= 8 &&
      RegExp('[A-Z]').hasMatch(value) &&
      RegExp('[a-z]').hasMatch(value) &&
      RegExp(r'\d').hasMatch(value) &&
      RegExp('[^A-Za-z0-9]').hasMatch(value);

  /// "Como quer ser chamado?" (MP2): de 2 a 80 caracteres depois de aparar.
  static bool isDisplayName(String value) {
    final name = value.trim();
    return name.length >= 2 && name.length <= 80 && _name.hasMatch(name);
  }

  /// Primeira palavra do nome, para os toasts ("Ana Souza" → "Ana").
  static String firstNameOf(String name) =>
      name.trim().split(RegExp(r'\s+')).first;
}
