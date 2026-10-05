import 'package:flutter/material.dart';

/// Mostra a arte de uma carta vinda da TCGdex.
///
/// Existe por dois motivos:
///
/// 1. As imagens sao pesadas (a "high.png" tem uns 360 KB), entao
///    enquanto baixa precisa aparecer algo melhor que um quadrado vazio.
/// 2. De vez em quando a CDN falha. Em vez de deixar a carta quebrada
///    pra sempre, aqui o usuario pode tocar pra tentar de novo.
class ImagemCarta extends StatefulWidget {
  const ImagemCarta({
    super.key,
    required this.url,
    required this.nome,
    this.fit = BoxFit.cover,
    this.larguraCache,
  });

  final String url;
  final String nome;
  final BoxFit fit;

  /// Reduz a imagem na hora de decodificar. Usado no album, onde as
  /// cartas sao pequenas e nao precisam da resolucao inteira na memoria.
  final int? larguraCache;

  @override
  State<ImagemCarta> createState() => _ImagemCartaState();
}

class _ImagemCartaState extends State<ImagemCarta> {
  /// Muda de valor a cada nova tentativa, o que forca o Image a
  /// reconstruir e baixar de novo.
  int _tentativa = 0;

  Future<void> _tentarDeNovo() async {
    // O Flutter guarda a imagem em cache pela URL, entao sem jogar a
    // antiga fora ele so repetiria o erro.
    await NetworkImage(widget.url).evict();
    if (mounted) setState(() => _tentativa++);
  }

  @override
  Widget build(BuildContext context) {
    return Image.network(
      widget.url,
      key: ValueKey('${widget.url}#$_tentativa'),
      fit: widget.fit,
      cacheWidth: widget.larguraCache,
      // A CDN da TCGdex as vezes manda o cabecalho
      // "Access-Control-Allow-Origin" DUPLICADO ("*, *"), e o navegador
      // rejeita a resposta por CORS -- por isso umas cartas carregavam
      // e outras nao, sem padrao.
      //
      // Com "fallback", o Flutter tenta baixar os bytes normalmente e,
      // so quando esbarra nesse erro, desenha a imagem num elemento
      // <img> de HTML, que nao passa pela regra de mesma origem.
      //
      // Cuidado: no modo <img> o Flutter ignora opacidade, filtros e
      // blend na imagem. Por isso o album escurece as cartas que faltam
      // com uma camada por cima, em vez de usar ColorFiltered.
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      loadingBuilder: (context, filho, progresso) {
        if (progresso == null) return filho;

        final total = progresso.expectedTotalBytes;
        return _Caixa(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  // Se a CDN informou o tamanho, vira barra de
                  // progresso de verdade em vez de rodinha infinita.
                  value: total == null
                      ? null
                      : progresso.cumulativeBytesLoaded / total,
                ),
              ),
            ],
          ),
        );
      },
      errorBuilder: (context, erro, pilha) {
        return GestureDetector(
          onTap: _tentarDeNovo,
          child: _Caixa(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.refresh, size: 28, color: Colors.white54),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    widget.nome,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'toque pra tentar de novo',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 9, color: Colors.white38),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Fundo neutro usado enquanto a imagem carrega ou quando ela falha.
class _Caixa extends StatelessWidget {
  const _Caixa({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E2129),
      alignment: Alignment.center,
      child: FittedBox(fit: BoxFit.scaleDown, child: child),
    );
  }
}
