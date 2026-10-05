import 'package:flutter/material.dart';

/// Cartao arredondado que centraliza o conteudo das telas de login e
/// home, pra ele parecer um painel de verdade em vez de campos soltos
/// direto no fundo escuro.
class PainelCentral extends StatelessWidget {
  const PainelCentral({super.key, required this.child, this.largura = 400});

  final Widget child;
  final double largura;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: largura),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFFD3ECFB), width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A4FC3F7),
              blurRadius: 30,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// O logo padrao do app: pokebola com um brilho suave atras, titulo e
/// subtitulo. Usado em cima do painel de login e do painel da home.
class LogoDoApp extends StatelessWidget {
  const LogoDoApp({
    super.key,
    required this.pokebola,
    required this.titulo,
    this.subtitulo,
  });

  final Widget pokebola;
  final String titulo;
  final String? subtitulo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [Color(0x334FC3F7), Colors.transparent],
            ),
          ),
          child: pokebola,
        ),
        const SizedBox(height: 12),
        Text(
          titulo,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            color: const Color(0xFF1E3A5F),
          ),
        ),
        if (subtitulo != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitulo!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF6E90AE)),
          ),
        ],
      ],
    );
  }
}
