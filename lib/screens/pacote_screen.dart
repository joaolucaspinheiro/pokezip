import 'dart:math';

import 'package:flutter/material.dart';

import '../models/carta.dart';
import '../services/colecao_service.dart';
import '../services/tcgdex_service.dart';
import '../widgets/imagem_carta.dart';

/// Proporcao de uma carta de verdade (largura / altura).
const double _proporcaoCarta = 0.72;

/// Quanto o dedo/mouse precisa andar pra valer como arrasto.
const double _distanciaMinima = 70;

/// Tela 3 -- A abertura do pacote.
///
/// Junta as duas APIs: busca as cartas na TCGdex e salva no Firestore.
///
/// As cartas aparecem UMA POR VEZ e JA VIRADAS, na ordem em que o
/// servico montou o pacote (3 comuns -> 1 incomum -> 1 rara), entao a
/// rara sempre cai por ultimo, igual pacote de verdade.
///
/// A interacao e so arrastar: arrasta a carta pra qualquer lado pra
/// joga-la fora e trazer a proxima.
class PacoteScreen extends StatefulWidget {
  const PacoteScreen({super.key});

  @override
  State<PacoteScreen> createState() => _PacoteScreenState();
}

class _PacoteScreenState extends State<PacoteScreen> {
  final _api = TcgdexService();
  final _colecao = ColecaoService();

  late Future<List<Carta>> _pacote;

  /// Qual carta esta na tela agora (0 a 4).
  int _indice = 0;

  /// Ja passou pelas 5 e esta vendo o resumo?
  bool _terminou = false;

  /// Quanto a carta ja foi arrastada a partir do centro.
  Offset _arrasto = Offset.zero;

  /// Dedo/mouse esta pressionado agora? Serve pra carta grudar no
  /// cursor sem atraso enquanto arrasta, e so animar quando solta.
  bool _arrastando = false;

  /// Carta esta voando pra fora da tela (trava novos arrastos).
  bool _saindo = false;

  /// Ids das cartas deste pacote que ainda nao estavam na colecao.
  /// Quem descobre isso e o guardarPacote, que olha a colecao antes de
  /// gravar -- depois de gravar, toda carta do pacote ja existe.
  Set<String> _novas = {};

  @override
  void initState() {
    super.initState();
    _pacote = _abrirPacote();
  }

  Future<List<Carta>> _abrirPacote() async {
    final cartas = await _api.abrirPacote(); // <- API TCGdex
    _novas = await _colecao.guardarPacote(cartas); // <- Firestore

    // Baixa as 5 artes AGORA, todas em paralelo, enquanto a tela ainda
    // mostra "Rasgando o plastico...".
    //
    // Antes cada imagem so comecava a baixar na hora que a carta
    // aparecia, e como cada uma tem uns 360 KB (~1,3s), a abertura tinha
    // ate 5 esperas espalhadas. Assim vira uma espera so, no comeco, e
    // cada carta ja aparece pronta.
    //
    // O "webHtmlElementStrategy: fallback" aqui e essencial -- sem ele
    // o NetworkImage usa so o caminho de baixar bytes, que falha nas
    // cartas com o bug de CORS da CDN (ver ImagemCarta). O precache
    // ficava "com sucesso" mas nao tinha de fato baixado nada, entao
    // essas cartas continuavam carregando so na hora de aparecer. Com o
    // fallback igual ao do ImagemCarta, o precache tambem cai pro
    // elemento <img> quando precisa, e so ai da pra dizer que a carta
    // esta REALMENTE pronta.
    if (mounted) {
      await Future.wait(
        cartas.map((carta) async {
          try {
            await precacheImage(
              NetworkImage(
                carta.imagemGrande,
                webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
              ),
              context,
            );
          } catch (_) {
            // Se mesmo assim uma imagem falhar, o pacote abre do mesmo
            // jeito: quem cuida do erro e o ImagemCarta, que oferece
            // tentar de novo.
          }
        }),
      );
    }

    return cartas;
  }

  void _outroPacote() {
    setState(() {
      _pacote = _abrirPacote();
      _novas = {};
      _indice = 0;
      _terminou = false;
      _arrasto = Offset.zero;
      _arrastando = false;
      _saindo = false;
    });
  }

  /// Joga a carta pra fora e traz a proxima (ou vai pro resumo).
  void _descartar(Offset direcao, int total) {
    setState(() {
      _saindo = true;
      _arrastando = false;
      // Manda a carta pra bem longe, na direcao em que foi arrastada.
      _arrasto = direcao * 1400;
    });

    // Espera a carta sair da tela antes de trocar pela proxima.
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _arrasto = Offset.zero;
        _saindo = false;
        if (_indice >= total - 1) {
          _terminou = true;
        } else {
          _indice++;
        }
      });
    });
  }

  void _soltou(int total) {
    if (_saindo) return;

    final distancia = _arrasto.distance;

    // Arrastou pouco: a carta volta pro lugar.
    if (distancia < _distanciaMinima) {
      setState(() {
        _arrasto = Offset.zero;
        _arrastando = false;
      });
      return;
    }

    _descartar(_arrasto / distancia, total);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seu pacote')),
      body: FutureBuilder<List<Carta>>(
        future: _pacote,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Rasgando o plastico...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Nao consegui buscar as cartas.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _outroPacote,
                      child: const Text('Tentar de novo'),
                    ),
                  ],
                ),
              ),
            );
          }

          final cartas = snapshot.data!;

          return _terminou
              ? _Resumo(
                  cartas: cartas,
                  novas: _novas,
                  aoAbrirOutro: _outroPacote,
                )
              : _revelacao(cartas);
        },
      ),
    );
  }

  Widget _revelacao(List<Carta> cartas) {
    final carta = cartas[_indice];
    final ehUltima = _indice == cartas.length - 1;
    final quantasFaltam = cartas.length - _indice - 1;

    return Column(
      children: [
        const SizedBox(height: 12),
        Text(
          'Carta ${_indice + 1} de ${cartas.length}',
          style: const TextStyle(color: Color(0xFF6E90AE)),
        ),
        const SizedBox(height: 10),
        _Bolinhas(total: cartas.length, atual: _indice),

        Expanded(
          child: LayoutBuilder(
            builder: (context, espaco) {
              // Calcula o tamanho da carta na mao em vez de usar
              // AspectRatio: assim ela nunca vira um palito, nem numa
              // janela larga e baixa, nem num celular estreito.
              var largura = min(espaco.maxWidth - 48, 300.0);
              var altura = largura / _proporcaoCarta;

              final alturaDisponivel = espaco.maxHeight - 24;
              if (altura > alturaDisponivel) {
                altura = alturaDisponivel;
                largura = altura * _proporcaoCarta;
              }

              final tamanho = Size(largura, altura);

              // Quanto a carta atual ja foi arrastada, de 0 (parada) a
              // 1 (arrastou o suficiente pra descartar). A proxima
              // carta usa isso pra ir aparecendo JUNTO com o arrasto --
              // ela e a carta de VERDADE (nao um verso generico), mas
              // so comeca a aparecer quando voce puxa a de cima, entao
              // e um espiar "ganho" pelo gesto, nao um brinde de graca.
              final progressoArrasto = (_arrasto.distance / 220).clamp(
                0.0,
                1.0,
              );

              return Center(
                child: SizedBox(
                  width: largura,
                  height: altura,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      if (quantasFaltam >= 1)
                        Transform.translate(
                          offset: const Offset(0, 8),
                          child: Transform.scale(
                            scale: 0.96,
                            child: Opacity(
                              opacity: progressoArrasto,
                              // O Stack da restricao frouxa pros filhos,
                              // entao sem esse SizedBox a carta de tras
                              // encolheria ate o tamanho da arte.
                              child: SizedBox(
                                width: largura,
                                height: altura,
                                child: _Frente(
                                  carta: cartas[_indice + 1],
                                  nova: _novas.contains(
                                    cartas[_indice + 1].id,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                      // A carta da vez, essa sim arrastavel.
                      _CartaArrastavel(
                        carta: carta,
                        nova: _novas.contains(carta.id),
                        tamanho: tamanho,
                        deslocamento: _arrasto,
                        colado: _arrastando,
                        aoComecar: () => setState(() => _arrastando = true),
                        aoArrastar: (delta) {
                          if (_saindo) return;
                          setState(() => _arrasto += delta);
                        },
                        aoSoltar: () => _soltou(cartas.length),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Nome e raridade da carta -- ela ja chega virada, entao
        // aparece direto, sem esperar nenhum toque.
        SizedBox(
          height: 54,
          child: Column(
            children: [
              Text(
                carta.nome,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A5F),
                ),
              ),
              Text(
                carta.raridade,
                style: TextStyle(
                  // O dourado claro (usado no brilho da carta rara) fica
                  // ilegivel escrito em cima do fundo claro do app --
                  // aqui usa um tom mais escuro do mesmo dourado.
                  color: carta.ehRara
                      ? const Color(0xFFB8860B)
                      : const Color(0xFF6E90AE),
                  fontWeight: carta.ehRara
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),

        // Dica do que fazer agora.
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.swipe, size: 18, color: Color(0xFF9FB7CB)),
              const SizedBox(width: 8),
              Text(
                ehUltima
                    ? 'Arraste pra fora pra ver o pacote'
                    : 'Arraste pra fora pra proxima carta',
                style: const TextStyle(color: Color(0xFF9FB7CB)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A carta que o usuario arrasta.
///
/// Ja chega VIRADA (a arte aparece na hora, sem precisar tocar em nada).
/// Arrastar pra qualquer direcao e o unico jeito de passar pra proxima --
/// e o que joga essa carta pra fora da tela.
///
/// Ela nao guarda estado: quem manda na posicao e na animacao e a tela,
/// isso deixa mais facil de entender o fluxo.
class _CartaArrastavel extends StatelessWidget {
  const _CartaArrastavel({
    required this.carta,
    required this.nova,
    required this.tamanho,
    required this.deslocamento,
    required this.colado,
    required this.aoComecar,
    required this.aoArrastar,
    required this.aoSoltar,
  });

  final Carta carta;

  /// Repassado pro _Frente, que desenha o selo "NOVA".
  final bool nova;

  final Size tamanho;
  final Offset deslocamento;

  /// Se true, a carta acompanha o cursor sem animacao (esta sendo
  /// arrastada). Se false, ela desliza suavemente ate o destino.
  final bool colado;

  final VoidCallback aoComecar;
  final void Function(Offset delta) aoArrastar;
  final VoidCallback aoSoltar;

  @override
  Widget build(BuildContext context) {
    // Gira um pouquinho conforme o arrasto horizontal, tipo carta
    // saindo da mao.
    final inclinacao = deslocamento.dx / 1400;

    return AnimatedContainer(
      duration: colado ? Duration.zero : const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(deslocamento.dx, deslocamento.dy, 0)
        ..rotateZ(inclinacao),
      transformAlignment: Alignment.center,
      width: tamanho.width,
      height: tamanho.height,
      child: GestureDetector(
        onPanStart: (_) => aoComecar(),
        onPanUpdate: (detalhes) => aoArrastar(detalhes.delta),
        onPanEnd: (_) => aoSoltar(),
        // A chave muda a cada carta nova, entao a troca entra com uma
        // animacao suave em vez de aparecer seca.
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _Frente(
            key: ValueKey('frente-${carta.id}'),
            carta: carta,
            nova: nova,
          ),
        ),
      ),
    );
  }
}

/// As bolinhas de progresso embaixo do contador.
class _Bolinhas extends StatelessWidget {
  const _Bolinhas({required this.total, required this.atual});

  final int total;
  final int atual;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final ultima = i == total - 1;
        final jaPassou = i <= atual;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: ultima ? 12 : 9,
          height: ultima ? 12 : 9,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: jaPassou
                ? (ultima ? const Color(0xFFFFC107) : const Color(0xFFE3350D))
                : const Color(0xFFD3ECFB),
          ),
        );
      }),
    );
  }
}

/// Carta virada pra cima, mostrando a arte que veio da TCGdex.
class _Frente extends StatelessWidget {
  const _Frente({
    super.key,
    required this.carta,
    this.nova = false,
    this.seloPequeno = false,
  });

  final Carta carta;

  /// Carta que ainda nao estava na colecao: ganha o selo "NOVA".
  final bool nova;

  /// No resumo as cartas sao bem menores, entao o selo encolhe junto.
  final bool seloPequeno;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        // Carta rara ganha um brilho dourado em volta.
        boxShadow: carta.ehRara
            ? [
                const BoxShadow(
                  color: Color(0xFFFFC107),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ]
            : const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ImagemCarta(url: carta.imagemGrande, nome: carta.nome),
          ),
          if (nova)
            Positioned(
              top: seloPequeno ? 6 : 10,
              left: seloPequeno ? 6 : 10,
              child: _SeloNova(pequeno: seloPequeno),
            ),
        ],
      ),
    );
  }
}

/// O selo "NOVA" no canto da carta.
///
/// Verde de proposito: o vermelho e o dourado do app ja falam de
/// raridade, e "nova" e outra coisa -- uma carta comum pode ser novidade
/// e uma rara pode ser repetida.
class _SeloNova extends StatelessWidget {
  const _SeloNova({this.pequeno = false});

  final bool pequeno;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: pequeno ? 6 : 10,
        vertical: pequeno ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome,
            size: pequeno ? 9 : 12,
            color: Colors.white,
          ),
          SizedBox(width: pequeno ? 3 : 5),
          Text(
            'NOVA',
            style: TextStyle(
              fontSize: pequeno ? 8 : 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tela do fim: as 5 cartas do pacote juntas.
class _Resumo extends StatelessWidget {
  const _Resumo({
    required this.cartas,
    required this.novas,
    required this.aoAbrirOutro,
  });

  final List<Carta> cartas;

  /// Ids das cartas do pacote que entraram na colecao agora.
  final Set<String> novas;

  final VoidCallback aoAbrirOutro;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Column(
            children: [
              const Text(
                'Seu pacote',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                switch (novas.length) {
                  0 => 'Nenhuma carta nova desta vez',
                  1 => '1 carta nova',
                  _ => '${novas.length} cartas novas',
                },
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: novas.isEmpty
                      ? FontWeight.normal
                      : FontWeight.bold,
                  color: novas.isEmpty
                      ? const Color(0xFF9FB7CB)
                      : const Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, espaco) {
              // GridView com "maxCrossAxisExtent" calcula quantas colunas
              // CABEM na largura (numa tela larga, cabem ate 6 de 160px)
              // e so depois encaixa as 5 cartas -- como sobra uma coluna
              // vazia, a fileira ficava colada na esquerda em vez de
              // centralizada como grupo.
              //
              // Um Wrap centralizado resolve isso: ele sempre distribui
              // as cartas no meio, numa fileira so (tela larga) ou
              // quebrando em duas fileiras centralizadas (tela estreita).
              const espacamento = 14.0;
              final colunas = espaco.maxWidth >= 700
                  ? cartas.length
                  : (espaco.maxWidth >= 420 ? 3 : 2);
              final largura =
                  ((espaco.maxWidth - 32 - espacamento * (colunas - 1)) /
                          colunas)
                      .clamp(90.0, 170.0);

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: espacamento,
                    runSpacing: espacamento,
                    children: [
                      for (final carta in cartas)
                        SizedBox(
                          width: largura,
                          height: largura / _proporcaoCarta,
                          child: _Frente(
                            carta: carta,
                            nova: novas.contains(carta.id),
                            seloPequeno: true,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Voltar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: aoAbrirOutro,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Abrir outro'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
