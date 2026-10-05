import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../models/carta.dart';

/// API EXTERNA 1: TCGdex (https://api.tcgdex.net)
///
/// E o catalogo oficial das cartas: nome, imagem em alta e raridade.
/// Nao precisa de chave de API.
class TcgdexService {
  static const String _base = 'https://api.tcgdex.net/v2/en';

  /// Set usado no app. "base1" e o Base Set de 1999, o dos 102 cards
  /// classicos (Charizard, Blastoise, Venusaur...).
  static const String setPadrao = 'base1';

  final Random _sorteio = Random();

  /// Busca as cartas de um set filtrando por raridade.
  Future<List<Carta>> _buscarPorRaridade(String setId, String raridade) async {
    final url = Uri.parse('$_base/cards?set=$setId&rarity=$raridade');
    final resposta = await http.get(url);

    if (resposta.statusCode != 200) {
      throw Exception('A TCGdex respondeu ${resposta.statusCode}');
    }

    final lista = jsonDecode(resposta.body) as List<dynamic>;
    return lista
        .map((j) => Carta.daApi(j as Map<String, dynamic>, raridade, setId))
        // Algumas cartas antigas nao tem imagem cadastrada. Sem imagem nao
        // da pra mostrar no pacote, entao ficam de fora do sorteio.
        .where((c) => c.imagem.isNotEmpty)
        .toList();
  }

  /// Sorteia [quantidade] cartas diferentes da lista.
  List<Carta> _sortear(List<Carta> de, int quantidade) {
    final copia = [...de]..shuffle(_sorteio);
    return copia.take(quantidade).toList();
  }

  /// Monta um pacote: 3 comuns + 1 incomum + 1 rara.
  Future<List<Carta>> abrirPacote({String setId = setPadrao}) async {
    // As tres buscas saem ao mesmo tempo em vez de uma esperando a outra.
    final resultados = await Future.wait([
      _buscarPorRaridade(setId, 'Common'),
      _buscarPorRaridade(setId, 'Uncommon'),
      _buscarPorRaridade(setId, 'Rare'),
    ]);

    final incomuns = resultados[1];
    final raras = resultados[2];

    // PEGADINHA DA API: o filtro de raridade da TCGdex e por "contem", nao
    // por igualdade. Como a palavra "Uncommon" CONTEM "common", a busca por
    // Common devolve comuns + incomuns misturadas (70 cartas em vez de 38).
    // Entao tiramos na mao tudo que ja apareceu na lista de incomuns.
    final idsIncomuns = incomuns.map((c) => c.id).toSet();
    final comuns = resultados[0]
        .where((c) => !idsIncomuns.contains(c.id))
        .toList();

    return [
      ..._sortear(comuns, 3),
      ..._sortear(incomuns, 1),
      ..._sortear(raras, 1),
    ];
  }

  /// Todas as cartas do set, usado na tela de colecao pra saber quantas
  /// cartas existem no total e quais ainda faltam.
  Future<List<Carta>> todasAsCartas({String setId = setPadrao}) async {
    final url = Uri.parse('$_base/cards?set=$setId');
    final resposta = await http.get(url);

    if (resposta.statusCode != 200) {
      throw Exception('A TCGdex respondeu ${resposta.statusCode}');
    }

    final lista = jsonDecode(resposta.body) as List<dynamic>;
    return lista
        .map((j) => Carta.daApi(j as Map<String, dynamic>, '?', setId))
        .where((c) => c.imagem.isNotEmpty)
        .toList();
  }
}
