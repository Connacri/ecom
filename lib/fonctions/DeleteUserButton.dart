import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../auth/AuthProvider.dart';
import '../pages/MyApp.dart';

class DeleteAccountButton extends StatefulWidget {
  @override
  _DeleteAccountButtonState createState() => _DeleteAccountButtonState();
}

class _DeleteAccountButtonState extends State<DeleteAccountButton> {
  bool _isDeleting = false;
  String? _errorMessage;
  final AuthService _authService = AuthService();
  Future<void> _deleteAccount() async {
    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Supprimer le document de l'utilisateur de Firestore
        await FirebaseFirestore.instance
            .collection('userModel')
            .doc(user.uid)
            .delete();

        // Supprimer l'utilisateur de Firebase Authentication
        await user.delete();
        _authService.signOut();
        // Se déconnecter
        await FirebaseAuth.instance.signOut();

        // Rediriger vers une page de connexion ou une autre page appropriée
        //Navigator.of(context).pushReplacementNamed('/login');
        if (mounted) {
          Navigator.of(
            context,
          ).pushReplacement(MaterialPageRoute(builder: (ctx) => MyApp1()));
          setState(() {
            user = null;
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la suppression du compte: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            'Erreur inconnue lors de la suppression du compte: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isDeleting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          onPressed: _isDeleting ? null : _deleteAccount,
          icon:
              _isDeleting
                  ? CircularProgressIndicator()
                  : Icon(Icons.delete, color: Colors.red),
        ),
        // ElevatedButton(
        //   onPressed: _isDeleting ? null : _deleteAccount,
        //   child:
        //       _isDeleting
        //           ? CircularProgressIndicator()
        //           : Text('Supprimer le compte'),
        // ),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(_errorMessage!, style: TextStyle(color: Colors.red)),
          ),
      ],
    );
  }
}
