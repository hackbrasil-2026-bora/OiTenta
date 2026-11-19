import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/bora_colors.dart';
import '../../../core/theme/bora_text.dart';
import '../../../core/widgets/bora_buttons.dart';
import '../../../core/widgets/bora_scaffold.dart';
import 'suggestion_controller.dart';

/// Enviar sugestão (M29, `.dc.html` + `screens/29`). Só visual (MP9).
/// "Anexar print" aparece desabilitado (o anexo exigiria pacote novo) e o
/// e-mail é só texto (abrir o e-mail exigiria `url_launcher`).
class SuggestionScreen extends StatelessWidget {
  const SuggestionScreen({
    super.key,
    required this.state,
    required this.onBack,
    required this.onText,
    required this.onSend,
  });

  final SuggestionController state;
  final VoidCallback onBack;
  final ValueChanged<String> onText;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    return BoraPage(
      topBar: BoraTopBar(leading: BackNavButton(onPressed: onBack)),
      children: [
        Text('Enviar sugestão', style: BoraText.h1(c.tx)),
        const SizedBox(height: 2),
        Text(
          'Achou algo estranho ou teve uma ideia? Conta pra gente.',
          style: BoraText.small(c.tx2),
        ),
        const SizedBox(height: 20),
        Text(
          'O que podemos melhorar?'.toUpperCase(),
          style: BoraText.label(c.tx2),
        ),
        const SizedBox(height: 8),
        _MessageField(value: state.text, onChanged: onText),
        const SizedBox(height: 12),
        const _AttachButton(),
        if (state.error != null) ...[
          const SizedBox(height: 16),
          Semantics(
            liveRegion: true,
            child: Text(state.error!, style: BoraText.small(c.danger)),
          ),
        ],
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Enviar',
          onPressed: state.canSend ? onSend : null,
        ),
        const SizedBox(height: 24),
        Text(
          'Prefere e-mail? Escreve pra gente:',
          textAlign: TextAlign.center,
          style: BoraText.small(c.tx2),
        ),
        const SizedBox(height: 2),
        Text(
          'contato@bora.app',
          textAlign: TextAlign.center,
          style: BoraText.nunito(
            16,
            22,
            weight: FontWeight.w800,
            color: c.blue,
          ),
        ),
      ],
    );
  }
}

/// Campo multilinha do protótipo (`textarea`): raio 12, borda 2px
/// `--border`, focado `--blue`, Nunito 400 16/24, altura mínima ~132.
class _MessageField extends StatefulWidget {
  const _MessageField({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_MessageField> createState() => _MessageFieldState();
}

class _MessageFieldState extends State<_MessageField> {
  late final TextEditingController _text = TextEditingController(
    text: widget.value,
  );

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
    final style = BoraText.nunito(16, 24, weight: FontWeight.w400, color: c.tx);
    return TextField(
      controller: _text,
      onChanged: widget.onChanged,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      minLines: 4,
      maxLines: null,
      style: style,
      decoration: InputDecoration(
        hintText: 'Ex.: queria poder mudar a cor dos objetivos',
        hintStyle: style.copyWith(color: c.tx2),
        hintMaxLines: 3,
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.all(14),
        enabledBorder: border(c.border),
        focusedBorder: border(c.blue),
        border: border(c.border),
      ),
    );
  }
}

/// "Anexar print (opcional)": visível e desabilitado (MP9).
class _AttachButton extends StatelessWidget {
  const _AttachButton();

  @override
  Widget build(BuildContext context) {
    final c = context.bora;
    return Semantics(
      button: true,
      enabled: false,
      label: 'Anexar print (opcional)',
      excludeSemantics: true,
      child: CustomPaint(
        painter: _DashedBorderPainter(color: c.border),
        child: SizedBox(
          height: 52,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(PhosphorIconsRegular.image, size: 20, color: c.tx2),
              const SizedBox(width: 8),
              Text(
                'Anexar print (opcional)',
                style: BoraText.nunito(
                  15,
                  15,
                  weight: FontWeight.w800,
                  color: c.tx2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Borda tracejada 2px, raio 12 (`border: 2px dashed var(--border)`).
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;

  static const _dash = 6.0;
  static const _space = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final rect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(1),
      const Radius.circular(12),
    );
    for (final metric in (Path()..addRRect(rect)).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += _dash + _space) {
        canvas.drawPath(metric.extractPath(d, d + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) => old.color != color;
}
