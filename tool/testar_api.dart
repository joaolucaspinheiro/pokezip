// ignore_for_file: avoid_print

import 'package:tcgdex/services/tcgdex_service.dart';

/// Teste rapido so da parte da API, sem Firebase.
Future<void> main() async {
  final api = TcgdexService();

  print('Abrindo um pacote do Base Set...\n');
  final pacote = await api.abrirPacote();

  for (final carta in pacote) {
    print('  ${carta.raridade.padRight(9)} | ${carta.nome.padRight(16)} | ${carta.imagemGrande}');
  }

  print('\nTotal no pacote: ${pacote.length} cartas');
  print('Ids repetidos? ${pacote.map((c) => c.id).toSet().length != pacote.length ? "SIM (bug)" : "nao"}');

  final todas = await api.todasAsCartas();
  print('Cartas no set inteiro: ${todas.length}');
}
