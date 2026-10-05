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

  /// Filtro do album: quando ligado, esconde as cartas que ja tenho e
  /// deixa so as que faltam -- com 102 cartas na grade, achar os buracos
  /// no olho dava trabalho.
  bool _soFaltantes = false;

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

              // Se a leitura do Firestore falhar, "minhas" fica vazio e o
              // album mostraria as 102 cartas como faltantes -- parece que
              // a colecao foi perdida. Avisa numa faixa em cima e mantem o
              // album na tela, que ainda serve de catalogo.
              final erroColecao = snapMinhas.hasError;

              // Conta so as cartas DESTE set. O "minhas" traz a colecao
              // inteira do usuario, de todos os sets, enquanto "todas" e
              // de um set so -- usar minhas.length direto daria progresso
              // acima de 100% e "faltam" negativo assim que existir um
              // segundo set.
              final tenhoNesteSet = todas
                  .where((c) => minhas.containsKey(c.id))
                  .length;

              final visiveis = _soFaltantes
                  ? todas.where((c) => (minhas[c.id] ?? 0) == 0).toList()
                  : todas;

              return Column(
                children: [
                  if (erroColecao) const _FaixaAviso(),
                  _Progresso(tenho: tenhoNesteSet, total: todas.length),
                  _FiltroFaltantes(
                    ativo: _soFaltantes,
                    faltam: todas.length - tenhoNesteSet,
                    aoMudar: (valor) => setState(() => _soFaltantes = valor),
                  ),
                  Expanded(
                    child: visiveis.isEmpty
                        ? const _SetCompleto()
                        : GridView.builder(
                            padding: const EdgeInsets.all(12),
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 130,
                                  childAspectRatio: 0.72,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                            itemCount: visiveis.length,
                            itemBuilder: (context, i) {
                              final carta = visiveis[i];
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

/// O filtro "so as que faltam", logo abaixo da barra de progresso.
class _FiltroFaltantes extends StatelessWidget {
  const _FiltroFaltantes({
    required this.ativo,
    required this.faltam,
    required this.aoMudar,
  });

  final bool ativo;
  final int faltam;
  final ValueChanged<bool> aoMudar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(
        children: [
          FilterChip(
            selected: ativo,
            onSelected: aoMudar,
            label: Text(
              faltam > 0 ? 'Só as que faltam ($faltam)' : 'Só as que faltam',
            ),
            labelStyle: const TextStyle(
              fontSize: 13,
              color: Color(0xFF1E3A5F),
            ),
            backgroundColor: const Color(0xFFEAF6FF),
            selectedColor: const Color(0xFFD3ECFB),
            checkmarkColor: const Color(0xFF1E3A5F),
            side: const BorderSide(color: Color(0xFFD3ECFB)),
          ),
        ],
      ),
    );
  }
}

/// Faixa que aparece quando a colecao nao pode ser lida do Firestore.
class _FaixaAviso extends StatelessWidget {
  const _FaixaAviso();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFF3CD),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: const Row(
        children: [
          Icon(Icons.cloud_off, size: 18, color: Color(0xFF8A6D1F)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Não foi possível carregar sua coleção. As cartas que você já '
              'tem podem aparecer como faltantes.',
              style: TextStyle(fontSize: 12, color: Color(0xFF8A6D1F)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mostrado quando o filtro esta ligado e nao falta nenhuma carta.
class _SetCompleto extends StatelessWidget {
  const _SetCompleto();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events, size: 48, color: Color(0xFFFFC107)),
            SizedBox(height: 12),
            Text(
              'Você completou o set!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A5F),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Não falta nenhuma carta.',
              style: TextStyle(color: Color(0xFF6E90AE)),
            ),
          ],
        ),
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

    return GestureDetector(
      // Toque abre a carta em tamanho grande. Vale tambem pras que
      // faltam: ai o album serve pra ver o que ainda da pra conseguir.
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => _DetalheCarta(carta: carta, quantidade: quantidade),
      ),
      behavior: HitTestBehavior.opaque,
      child: Stack(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
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
      ),
    );
  }
}

/// A carta ampliada, aberta ao tocar numa carta do album.
///
/// Usa a arte em alta (a mesma da tela de pacote) e diz se a carta ja
/// esta na colecao -- e quantas copias.
class _DetalheCarta extends StatelessWidget {
  const _DetalheCarta({required this.carta, required this.quantidade});

  final Carta carta;
  final int quantidade;

  @override
  Widget build(BuildContext context) {
    final tenho = quantidade > 0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: AspectRatio(
              // Mesma proporcao de uma carta de verdade.
              aspectRatio: 0.72,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ImagemCarta(
                    url: carta.imagemGrande,
                    nome: carta.nome,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  carta.nome,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A5F),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tenho
                      ? (quantidade > 1
                            ? 'Você tem $quantidade cópias'
                            : 'Você tem essa carta')
                      : 'Você ainda não tem essa carta',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: tenho
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFF6E90AE),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
