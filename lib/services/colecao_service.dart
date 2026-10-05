import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/carta.dart';

/// API EXTERNA 2: Firebase (Authentication + Cloud Firestore)
///
/// Enquanto a TCGdex diz quais cartas EXISTEM, o Firestore guarda quais
/// cartas VOCE tem. Cada usuario tem a sua colecao separada:
///
///   colecoes/{uid}/cartas/{idDaCarta}
class ColecaoService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _cartas =>
      _db.collection('colecoes').doc(_uid).collection('cartas');

  /// Salva as 5 cartas do pacote de uma vez so e devolve os ids das que
  /// ainda NAO estavam na colecao -- e o que a tela usa pro selo "NOVA".
  ///
  /// A leitura precisa vir ANTES do lote: depois do increment toda carta
  /// do pacote existe na colecao, e nao daria mais pra saber qual delas
  /// era novidade.
  Future<Set<String>> guardarPacote(List<Carta> pacote) async {
    final atuais = await Future.wait(
      pacote.map((carta) => _cartas.doc(carta.id).get()),
    );

    final novas = <String>{
      for (var i = 0; i < pacote.length; i++)
        if (!atuais[i].exists) pacote[i].id,
    };

    final lote = _db.batch();

    for (final carta in pacote) {
      lote.set(_cartas.doc(carta.id), {
        ...carta.paraFirestore(),
        // Carta repetida nao e problema: vira quantidade, igual album
        // de figurinha. O increment deixa o proprio Firestore somar.
        'quantidade': FieldValue.increment(1),
        'obtidaEm': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await lote.commit();

    return novas;
  }

  /// Acompanha a colecao em tempo real: qualquer carta nova que entrar
  /// atualiza a tela sozinha, sem precisar recarregar.
  Stream<List<Carta>> assistirColecao() {
    return _cartas.snapshots().map(
      (snap) => snap.docs.map((d) => Carta.doFirestore(d.data())).toList(),
    );
  }
}
