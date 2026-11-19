import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/bora_colors.dart';
import '../../../core/theme/bora_text.dart';

/// Campo de senha do Acesso: o mesmo visual do `BoraInput` (raio 12, borda
/// 2px `--border`, focado `--blue`) com o olho 44×44 à direita, que alterna
/// o texto oculto ("Mostrar senha"/"Esconder senha").
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.hint,
    required this.obscure,
    required this.onToggleObscure,
    this.textInputAction,
    this.onSubmitted,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String hint;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  late final TextEditingController _text = TextEditingController(
    text: widget.value,
  );

  @override
  void didUpdateWidget(covariant PasswordField old) {
    super.didUpdateWidget(old);
    if (widget.value != _text.text) _text.text = widget.value;
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: 2),
    );
    final style = BoraText.nunito(15, 20, color: c.tx);
    return SizedBox(
      height: 52,
      child: Stack(
        children: [
          Positioned.fill(
            child: TextField(
              controller: _text,
              onChanged: widget.onChanged,
              obscureText: widget.obscure,
              autocorrect: false,
              enableSuggestions: false,
              keyboardType: TextInputType.visiblePassword,
              textInputAction: widget.textInputAction,
              onSubmitted: widget.onSubmitted,
              style: style,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: style.copyWith(color: c.tx2),
                filled: true,
                fillColor: c.surface,
                contentPadding: const EdgeInsets.fromLTRB(14, 14, 52, 14),
                enabledBorder: border(c.border),
                focusedBorder: border(c.blue),
                border: border(c.border),
              ),
            ),
          ),
          Positioned(
            right: 4,
            top: 4,
            child: Semantics(
              button: true,
              label: widget.obscure ? 'Mostrar senha' : 'Esconder senha',
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onToggleObscure,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    widget.obscure
                        ? PhosphorIconsRegular.eye
                        : PhosphorIconsRegular.eyeSlash,
                    size: 20,
                    color: c.tx2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rótulo de campo do Acesso (Nunito 800 12/16 caixa-alta, `--tx2`).
class AuthFieldLabel extends StatelessWidget {
  const AuthFieldLabel(this.text, {super.key, this.top = 20});

  final String text;
  final double top;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: top, bottom: 8),
    child: Text(text.toUpperCase(), style: BoraText.label(context.bora.tx2)),
  );
}

/// Mensagem de erro do Acesso, anunciada pelo leitor de tela (região viva).
class AuthError extends StatelessWidget {
  const AuthError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Semantics(
      liveRegion: true,
      child: Text(
        message,
        style: BoraText.nunito(
          14,
          20,
          weight: FontWeight.w700,
          color: context.bora.danger,
        ),
      ),
    ),
  );
}

/// Dica com ícone abaixo de um campo (ícone 16, gap 6, Nunito 600 12/16).
class AuthHint extends StatelessWidget {
  const AuthHint({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
    this.iconKey,
  });

  final IconData icon;
  final Color color;
  final String text;
  final Key? iconKey;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(
      children: [
        Icon(icon, key: iconKey, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: BoraText.caption(context.bora.tx2))),
      ],
    ),
  );
}
