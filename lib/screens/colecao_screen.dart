import 'package:flutter/material.dart';

import '../models/carta.dart';
import '../services/colecao_service.dart';
import '../services/tcgdex_service.dart';
import '../widgets/imagem_carta.dart';

/// Tela 4 -- O album.
///
/// Mostra TODAS as cartas do set (isso vem da TCGdex) e destaca quais
/// voce ja tem (isso vem do Firestore). As que faltam aparecem apagadas.
class ColecaoScreen extends StatefulWidget {
  const ColecaoScreen({super.key});

  @override
  State<ColecaoScreen> createState() => _ColecaoScreenState();
}

class _ColecaoScreenState extends State<ColecaoScreen> {
  final _api = TcgdexService();
  final _colecao = ColecaoService();

  late final Future<List<Carta>> _todas = _api.todasAsCartas();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minha coleção')),
      body: FutureBuilder<List<Carta>>(
        future: _todas,
        builder: (context, snapTodas) {
          if (snapTodas.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapTodas.hasError) {
            return Center(child: Text('Erro na TCGdex: ${snapTodas.error}'));
          }

          final todas = snapTodas.data!;

          return StreamBuilder<List<Carta>>(
            stream: _colecao.assistirColecao(),
            builder: (context, snapMinhas) {
              // Vira um mapa "id da carta -> quantidade" pra consulta rapida.
              final minhas = {
                for (final c in snapMinhas.data ?? <Carta>[])
                  c.id: c.quantidade,
              };

              return Column(
                children: [
                  _Progresso(tenho: minhas.length, total: todas.length),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 130,
                            childAspectRatio: 0.72,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount: todas.length,
                      itemBuilder: (context, i) {
                        final carta = todas[i];
                        final quantidade = minhas[carta.id] ?? 0;
                        return _CartaDoAlbum(
                          carta: carta,
                          quantidade: quantidade,
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _Progresso extends StatelessWidget {
  const _Progresso({required this.tenho, required this.total});

  final int tenho;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$tenho de $total cartas',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A5F),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : tenho / total,
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _CartaDoAlbum extends StatelessWidget {
  const _CartaDoAlbum({required this.carta, required this.quantidade});

  final Carta carta;
  final int quantidade;

  @override
  Widget build(BuildContext context) {
    final tenho = quantidade > 0;

    final imagem = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ImagemCarta(
        url: carta.imagemPequena,
        nome: carta.nome,
        fit: BoxFit.contain,
        // No album a carta e pequena, entao nao precisa guardar a
        // imagem inteira na memoria -- sao 102 delas.
        larguraCache: 260,
      ),
    );

    return Stack(
      children: [
        Positioned.fill(child: imagem),

        // Carta que falta fica apagada, tipo silhueta de album de
        // figurinha -- some quase por completo no fundo claro do app.
        //
        // Isso e feito com uma camada POR CIMA na cor do fundo, e nao
        // com Opacity/ColorFiltered na imagem, porque quando o Flutter
        // precisa desenhar a arte num elemento <img> (o contorno pro
        // CORS da CDN) ele ignora opacidade e filtros -- e a carta
        // faltante apareceria colorida, igual a que voce tem.
        if (!tenho)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(color: const Color(0xE6EAF6FF)),
            ),
          ),

        // Se tem repetida, mostra o "x2", "x3"...
        if (quantidade > 1)
          Positioned(
            right: 4,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE3350D),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'x$quantidade',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
