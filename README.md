# PokeZip

App em Flutter para **abrir pacotes de cartas Pokémon** e montar a sua coleção.
Cada pacote traz 5 cartas reais do *Base Set* (3 comuns, 1 incomum e 1 rara),
que ficam salvas na conta de quem abriu.

Atividade individual — Flutter integrado a **Firebase** e a uma **API externa**.

## As duas APIs

| API | Para que serve no app |
|---|---|
| **[TCGdex](https://tcgdex.dev)** (API externa, REST, sem chave) | É o **catálogo oficial das cartas**: nome, raridade e imagem em alta resolução. O app sorteia as cartas do pacote a partir dela e usa a lista completa do set para montar o álbum. |
| **Firebase Authentication** | Cadastro (apelido + e-mail + senha) e login. O apelido é guardado no `displayName` do usuário. |
| **Cloud Firestore** | Guarda a **coleção de cada usuário**: quais cartas ele tem e quantas repetidas. |

A divisão é: a **TCGdex diz quais cartas existem**, o **Firestore diz quais cartas são suas**.

## Telas

1. **Login** — entrar com e-mail e senha.
2. **Cadastro** — tela própria, com apelido, e-mail e senha.
3. **Home** — saudação com o apelido e contadores da coleção (diferentes / total), atualizados em tempo real.
4. **Abertura do pacote** — as cartas aparecem uma por vez; é só **arrastar** a carta pra fora para ver a próxima. A rara sempre vem por último.
5. **Resumo do pacote** — as 5 cartas juntas, com opção de abrir outro.
6. **Minha coleção** — álbum com as 102 cartas do set: as que você tem aparecem coloridas (com `x2`, `x3`… nas repetidas) e as que faltam ficam apagadas.

## Como as APIs são usadas

**TCGdex** — [`lib/services/tcgdex_service.dart`](lib/services/tcgdex_service.dart)

```
GET https://api.tcgdex.net/v2/en/cards?set=base1&rarity=Common
GET https://api.tcgdex.net/v2/en/cards?set=base1&rarity=Uncommon
GET https://api.tcgdex.net/v2/en/cards?set=base1&rarity=Rare
GET https://api.tcgdex.net/v2/en/cards?set=base1            (álbum completo)
```

As três buscas do pacote saem em paralelo (`Future.wait`) e a imagem de cada carta
vem da URL que a API devolve, completada com `/high.png` ou `/low.png`.

**Firebase** — [`lib/services/colecao_service.dart`](lib/services/colecao_service.dart)

Cada usuário tem a sua coleção em `colecoes/{uid}/cartas/{idDaCarta}`.
Um pacote é salvo de uma vez só (`WriteBatch`) e carta repetida não duplica
documento: o campo `quantidade` é incrementado com `FieldValue.increment(1)`.
A Home e o álbum escutam `snapshots()`, então atualizam sozinhos.

## Estrutura

```
lib/
├── main.dart                 # inicia o Firebase; PortaoDeEntrada escolhe Login ou Home
├── theme.dart                # tema azul claro + fonte Fredoka
├── firebase_options.dart     # gerado pelo flutterfire configure
├── models/carta.dart
├── services/
│   ├── tcgdex_service.dart   # API externa
│   └── colecao_service.dart  # Firestore
├── screens/                  # login, cadastro, home, pacote, coleção
└── widgets/                  # pokebola, painel central, botão principal, imagem da carta
firestore.rules               # regras de segurança do Firestore
tool/testar_api.dart          # testa a TCGdex sozinha, sem Firebase
```

## Como rodar

Pré-requisito: [Flutter](https://docs.flutter.dev/get-started/install) (testado na 3.41).
O projeto já vem com o `lib/firebase_options.dart` configurado para **Web**.

```bash
flutter pub get
flutter run -d chrome
```

Precisa de internet (TCGdex, Firebase e a fonte do Google Fonts).
No Windows, se aparecer erro de *symlink*, ative o **Modo de Desenvolvedor**.

### Usando o seu próprio projeto Firebase

1. Crie um projeto no [console do Firebase](https://console.firebase.google.com).
2. Ative **Authentication → E-mail/senha** e crie o **Firestore Database**.
3. Gere a configuração do app (substitui o `firebase_options.dart`):
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
4. Publique as regras de segurança:
   ```bash
   firebase deploy --only firestore:rules
   ```

> Só a plataforma **Web** está configurada. Para rodar em Android ou Windows,
> marque essas plataformas no `flutterfire configure`.

## Observações técnicas

- **Filtro de raridade da TCGdex é por "contém".** Buscar `Common` também devolve as
  `Uncommon` (a palavra contém "common"). O serviço remove da lista de comuns tudo
  que já apareceu na lista de incomuns.
- **CORS na CDN das imagens.** Parte das imagens vem da CDN com o cabeçalho
  `Access-Control-Allow-Origin` duplicado, e o navegador as bloqueia. O app usa
  `WebHtmlElementStrategy.fallback`, que cai para um elemento `<img>` nesses casos, e
  baixa as 5 imagens do pacote em paralelo (`precacheImage`) antes de mostrar a primeira.

## Créditos

Dados e imagens das cartas: [TCGdex](https://tcgdex.dev).
Pokémon e seus personagens são marcas da Nintendo, Game Freak e Creatures Inc.
Projeto educacional, sem fins lucrativos e sem vínculo com essas empresas.
