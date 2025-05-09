// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
//
// import 'MyApp.dart';
//
// class AuthWrapper extends StatelessWidget {
//   const AuthWrapper({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final auth = Provider.of<AuthProvider2>(context);
//     return auth.isLoggedIn ? const HomeScreen() : const LoginScreen();
//   }
// }
//
// class LoginScreen extends StatelessWidget {
//   const LoginScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final auth = Provider.of<AuthProvider2>(context, listen: false);
//
//     return Scaffold(
//       appBar: AppBar(title: const Text('Connexion')),
//       body: Center(
//         child: ElevatedButton.icon(
//           onPressed: () async {
//             try {
//               await auth.signInWithGoogle();
//             } catch (e) {
//               ScaffoldMessenger.of(
//                 context,
//               ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
//             }
//           },
//           icon: const Icon(Icons.login),
//           label: const Text('Connexion avec Google'),
//         ),
//       ),
//     );
//   }
// }
//
// class HomeScreen extends StatelessWidget {
//   const HomeScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final auth = Provider.of<AuthProvider2>(context);
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Bienvenue'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.logout),
//             onPressed: () => auth.signOut(),
//           ),
//         ],
//       ),
//       body: Center(
//         child: Text('Bonjour, ${auth.user?.displayName ?? 'Utilisateur'}'),
//       ),
//     );
//   }
// }
