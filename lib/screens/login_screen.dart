import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/botao_principal.dart';
import '../widgets/painel_central.dart';
import '../widgets/pokebola.dart';
import 'cadastro_screen.dart';

/// Tela 1 -- Login, usando Firebase Authentication.
///
/// Quem nao tem conta vai pra [CadastroScreen], que e uma tela separada
/// (e la sim se pede o apelido, alem de e-mail e senha).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _senha.text,
      );
      // Nao precisa navegar aqui: o PortaoDeEntrada (main.dart) percebe
      // o login sozinho e troca a tela.
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
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'E-mail ou senha incorretos.';
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
                  pokebola: Pokebola(tamanho: 72),
                  titulo: 'PokeZip',
                  subtitulo: 'Monte sua colecao de cartas Pokemon',
                ),
                const SizedBox(height: 32),
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
                  BotaoPrincipal(aoPressionar: _entrar, texto: 'Entrar'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Ainda nao tem conta?',
                      style: TextStyle(color: Color(0xFF6E90AE)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CadastroScreen(),
                        ),
                      ),
                      child: const Text('Cadastre-se'),
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
