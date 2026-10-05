import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Liga o app ao projeto do Firebase. O arquivo firebase_options.dart e
  // gerado pelo comando "flutterfire configure".
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const AppCartas());
}

class AppCartas extends StatelessWidget {
  const AppCartas({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PokeZip',
      debugShowCheckedModeBanner: false,
      theme: construirTema(),
      home: const PortaoDeEntrada(),
    );
  }
}

/// Decide qual tela mostrar: se tem alguem logado, vai pra Home;
/// se nao tem, vai pro Login.
///
/// O authStateChanges() e um stream do Firebase Auth que avisa sozinho
/// quando alguem entra ou sai -- por isso nenhuma tela precisa mandar
/// navegar na mao depois do login ou do logout.
class PortaoDeEntrada extends StatelessWidget {
  const PortaoDeEntrada({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.hasData ? const HomeScreen() : const LoginScreen();
      },
    );
  }
}
