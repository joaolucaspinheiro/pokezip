import 'package:flutter/material.dart';

/// Uma pokebola desenhada na mao, sem depender de nenhuma imagem externa:
/// metade vermelha em cima, metade branca embaixo, faixa preta no meio e
/// o botao central. Usada como logo do app (login e home).
class Pokebola extends StatelessWidget {
  const Pokebola({super.key, this.tamanho = 64});

  final double tamanho;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: tamanho,
      height: tamanho,
      child: CustomPaint(painter: _PokebolaPainter()),
    );
  }
}

class _PokebolaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    final raio = size.width / 2;

    // Metade branca (embaixo), pintada primeiro pra cobrir o circulo
    // inteiro.
    canvas.drawCircle(centro, raio, Paint()..color = const Color(0xFFF5F5F5));

    // Metade vermelha (em cima), recortando so a parte de cima do
    // circulo com um clipe retangular.
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height / 2));
    canvas.drawCircle(centro, raio, Paint()..color = const Color(0xFFE3350D));
    canvas.restore();

    // Contorno preto em volta de tudo.
    final espessuraContorno = raio * 0.09;
    canvas.drawCircle(
      centro,
      raio - espessuraContorno / 2,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = espessuraContorno,
    );

    // Faixa preta horizontal, bem no meio.
    canvas.drawRect(
      Rect.fromLTWH(0, size.height / 2 - raio * 0.085, size.width, raio * 0.17),
      Paint()..color = Colors.black,
    );

    // Botao central: anel preto, disco branco, miolo cinza.
    final raioBotao = raio * 0.32;
    canvas.drawCircle(centro, raioBotao, Paint()..color = Colors.black);
    canvas.drawCircle(centro, raioBotao * 0.72, Paint()..color = Colors.white);
    canvas.drawCircle(
      centro,
      raioBotao * 0.34,
      Paint()..color = const Color(0xFFBDBDBD),
    );
  }

  @override
  bool shouldRepaint(covariant _PokebolaPainter oldDelegate) => false;
}
