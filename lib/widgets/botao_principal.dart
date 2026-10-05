import 'package:flutter/material.dart';

import '../theme.dart';

/// O botao de acao principal do app: vermelho (a cor da pokebola),
/// arredondado, com uma sombra colorida por baixo pra dar volume "de
/// brinquedo" em vez de ficar achatado.
///
/// Usado no "ABRIR PACOTE" da Home, no "Entrar" do Login e no "Criar
/// conta" do Cadastro -- mesma cara em toda acao principal do app.
class BotaoPrincipal extends StatelessWidget {
  const BotaoPrincipal({
    super.key,
    required this.aoPressionar,
    required this.texto,
    this.icone,
  });

  final VoidCallback? aoPressionar;
  final String texto;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: corAcento.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: aoPressionar,
          style: FilledButton.styleFrom(
            backgroundColor: corAcento,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 20),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          child: icone == null
              ? Text(texto)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icone, size: 24),
                    const SizedBox(width: 10),
                    Text(texto),
                  ],
                ),
        ),
      ),
    );
  }
}
