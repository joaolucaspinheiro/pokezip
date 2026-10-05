import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/carta.dart';
import '../services/colecao_service.dart';
import '../widgets/botao_principal.dart';
import '../widgets/painel_central.dart';
import '../widgets/pokebola.dart';
import 'colecao_screen.dart';
import 'pacote_screen.dart';

/// Tela 2 -- Menu principal.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colecao = ColecaoService();
    final usuario = FirebaseAuth.instance.currentUser;
    // Prefere mostrar o apelido (cadastrado na tela de Cadastro); quem
    // criou a conta antes disso existir nao tem apelido, entao cai pro
    // e-mail mesmo.
    final apelido = usuario?.displayName?.trim();
    final saudacao = (apelido != null && apelido.isNotEmpty)
        ? apelido
        : (usuario?.email ?? '');

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Pokebola(tamanho: 26),
            SizedBox(width: 10),
            Text('PokeZip'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: PainelCentral(
            largura: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Olá, $saudacao',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF6E90AE)),
                ),
                const SizedBox(height: 20),

                // Le a colecao do Firestore em tempo real so pra mostrar
                // quantas cartas o usuario ja tem.
                StreamBuilder<List<Carta>>(
                  stream: colecao.assistirColecao(),
                  builder: (context, snapshot) {
                    final cartas = snapshot.data ?? [];
                    final diferentes = cartas.length;
                    final total = cartas.fold<int>(
                      0,
                      (soma, c) => soma + c.quantidade,
                    );

                    return _PainelEstatisticas(
                      diferentes: diferentes,
                      total: total,
                    );
                  },
                ),

                const SizedBox(height: 28),

                // Botao principal: mesma cara do "Entrar"/"Criar conta"
                // (ver BotaoPrincipal), pra toda acao principal do app
                // ter a mesma identidade visual.
                BotaoPrincipal(
                  aoPressionar: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PacoteScreen()),
                  ),
                  icone: Icons.catching_pokemon,
                  texto: 'ABRIR PACOTE',
                ),
                const SizedBox(height: 14),

                // Secundario: preenchido num azul bem clarinho, em vez
                // de contorno fino -- o contorno quase sumia em cima do
                // painel branco.
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ColecaoScreen()),
                  ),
                  icon: const Icon(Icons.grid_view),
                  label: const Text('Minha coleção'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFD3ECFB),
                    foregroundColor: const Color(0xFF1E3A5F),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Os dois numeros da colecao (cartas diferentes e total), lado a lado
/// dentro de um painel proprio com icone e um traco separando os dois.
class _PainelEstatisticas extends StatelessWidget {
  const _PainelEstatisticas({required this.diferentes, required this.total});

  final int diferentes;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD3ECFB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Numero(
              icone: Icons.collections_bookmark,
              valor: '$diferentes',
              rotulo: 'diferentes',
            ),
          ),
          Container(width: 1, height: 40, color: const Color(0xFFD3ECFB)),
          Expanded(
            child: _Numero(
              icone: Icons.style,
              valor: '$total',
              rotulo: 'no total',
            ),
          ),
        ],
      ),
    );
  }
}

class _Numero extends StatelessWidget {
  const _Numero({
    required this.icone,
    required this.valor,
    required this.rotulo,
  });

  final IconData icone;
  final String valor;
  final String rotulo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icone, size: 18, color: const Color(0xFFE3350D)),
        const SizedBox(height: 6),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A5F),
          ),
        ),
        Text(rotulo, style: const TextStyle(color: Color(0xFF6E90AE))),
      ],
    );
  }
}
