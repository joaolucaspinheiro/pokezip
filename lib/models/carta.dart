/// Uma carta Pokemon.
///
/// A mesma classe representa tanto a carta que veio da API TCGdex quanto a
/// carta que esta salva na sua colecao no Firestore -- a diferenca e so o
/// campo [quantidade], que a API nao tem.
class Carta {
  final String id;
  final String nome;
  final String imagem;
  final String raridade;
  final String setId;
  final int quantidade;

  const Carta({
    required this.id,
    required this.nome,
    required this.imagem,
    required this.raridade,
    required this.setId,
    this.quantidade = 1,
  });

  // A TCGdex manda a imagem SEM extensao (ex: .../base/base1/4).
  // Quem escolhe a qualidade e a gente, completando a URL:
  String get imagemPequena => '$imagem/low.png';
  String get imagemGrande => '$imagem/high.png';

  bool get ehRara => raridade.toLowerCase().contains('rare');

  factory Carta.daApi(
    Map<String, dynamic> json,
    String raridade,
    String setId,
  ) {
    return Carta(
      id: json['id'] as String,
      nome: (json['name'] as String?) ?? 'Sem nome',
      imagem: (json['image'] as String?) ?? '',
      raridade: raridade,
      setId: setId,
    );
  }

  factory Carta.doFirestore(Map<String, dynamic> json) {
    return Carta(
      id: json['id'] as String,
      nome: json['nome'] as String,
      imagem: json['imagem'] as String,
      raridade: json['raridade'] as String,
      setId: json['setId'] as String,
      quantidade: (json['quantidade'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> paraFirestore() => {
    'id': id,
    'nome': nome,
    'imagem': imagem,
    'raridade': raridade,
    'setId': setId,
  };
}
