import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/botao_principal.dart';
import '../widgets/painel_central.dart';
import '../widgets/pokebola.dart';

/// Tela separada de cadastro -- pede apelido, e-mail e senha.
///
/// O apelido nao existe no Firebase Authentication por padrao, entao
/// ele e salvo no proprio campo `displayName` do usuario logo depois de
/// criar a conta (ver [FirebaseAuth.updateDisplayName]). E a Home mostra
/// esse apelido em vez do e-mail quando ele existe.
class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _apelido = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _apelido.dispose();
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    final apelido = _apelido.text.trim();

    if (apelido.isEmpty) {
      setState(() => _erro = 'Escolha um apelido primeiro.');
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final credencial = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _email.text.trim(),
            password: _senha.text,
          );

      // Guarda o apelido no perfil do usuario que acabou de ser criado.
      await credencial.user?.updateDisplayName(apelido);
      await credencial.user?.reload();

      // O PortaoDeEntrada (main.dart) ja troca sozinho o conteudo BASE
      // de Login pra Home assim que a conta loga -- mas essa tela de
      // Cadastro foi empurrada POR CIMA dessa base com Navigator.push,
      // entao ela continua na frente, escondendo a Home, ate alguem
      // fechar essa rota. E o que o pop() faz aqui.
      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      setState(() => _erro = _mensagem(e.code));
    } catch (e) {
      setState(() => _erro = 'Erro inesperado: $e');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  String _mensagem(String codigo) {
    switch (codigo) {
      case 'invalid-email':
        return 'E-mail invalido.';
      case 'weak-password':
        return 'A senha precisa ter no minimo 6 caracteres.';
      case 'email-already-in-use':
        return 'Esse e-mail ja tem conta. Volte e toque em Entrar.';
      case 'network-request-failed':
        return 'Sem internet.';
      default:
        return 'Nao rolou ($codigo).';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: PainelCentral(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const LogoDoApp(
                  pokebola: Pokebola(tamanho: 64),
                  titulo: 'Criar conta',
                  subtitulo: 'Escolha um apelido pra começar',
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _apelido,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Apelido',
                    prefixIcon: Icon(Icons.emoji_emotions_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _senha,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                if (_erro != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _erro!,
                    style: const TextStyle(color: Color(0xFFD32F2F)),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 20),
                if (_carregando)
                  const Center(child: CircularProgressIndicator())
                else
                  BotaoPrincipal(
                    aoPressionar: _cadastrar,
                    texto: 'Criar conta',
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Ja tem conta?',
                      style: TextStyle(color: Color(0xFF6E90AE)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Entrar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
