import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class BinancePage extends StatefulWidget {
  @override
  State<BinancePage> createState() => _BinancePageState();
}

class _BinancePageState extends State<BinancePage> {
  String binanceUrl = '';
  String prix = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchBinanceData();
  }

  Future<void> fetchBinanceData() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('paiement')
              .doc('binance')
              .get();

      setState(() {
        binanceUrl = doc['url'] ?? '';
        prix = doc['prix']?.toString() ?? '';
        isLoading = false;
      });
    } catch (e) {
      print('Erreur Firestore : $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> openBinanceUrl() async {
    if (binanceUrl.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lien Binance non disponible.")));
      return;
    }

    final uri = Uri.parse(binanceUrl);
    if (await canLaunchUrl(uri) && uri.isAbsolute) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Impossible d'ouvrir le lien Binance.")),
      );
    }
  }

  Future<void> askPasswordAndEdit() async {
    final TextEditingController passwordCtrl = TextEditingController();
    final TextEditingController urlCtrl = TextEditingController(
      text: binanceUrl,
    );
    final TextEditingController prixCtrl = TextEditingController(text: prix);

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Authentification"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: passwordCtrl,
                  obscureText: true,
                  decoration: InputDecoration(labelText: "Mot de passe admin"),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: Text("Annuler"),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: Text("Continuer"),
                onPressed: () {
                  if (passwordCtrl.text == '123456') {
                    Navigator.pop(context);
                    editBinanceData(urlCtrl, prixCtrl);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Mot de passe incorrect.")),
                    );
                  }
                },
              ),
            ],
          ),
    );
  }

  Future<void> editBinanceData(
    TextEditingController urlCtrl,
    TextEditingController prixCtrl,
  ) async {
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Modifier le lien Binance"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: urlCtrl,
                  decoration: InputDecoration(labelText: "Nouveau lien"),
                ),
                TextField(
                  controller: prixCtrl,
                  decoration: InputDecoration(labelText: "Prix (€)"),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: Text("Annuler"),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: Text("Enregistrer"),
                onPressed: () async {
                  try {
                    final newUrl = urlCtrl.text.trim();
                    final newPrix = prixCtrl.text.trim();

                    await FirebaseFirestore.instance
                        .collection('paiement')
                        .doc('binance')
                        .set({
                          'url': newUrl,
                          'prix': newPrix,
                        }, SetOptions(merge: true));

                    setState(() {
                      binanceUrl = newUrl;
                      prix = newPrix;
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Données mises à jour avec succès"),
                      ),
                    );
                  } catch (e) {
                    print("Erreur Firestore : $e");
                  }
                },
              ),
            ],
          ),
    );
  }

  Widget buildDonationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/logos/binancelogo.webp', // Assure-toi que ce fichier est bien dans assets et déclaré dans pubspec.yaml
          height: 50,
        ),
        SizedBox(height: 12),
        Text(
          "Aidez ce développeur à améliorer l'application !\n"
          "Un simple café peut faire la différence ☕",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        if (prix.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              "Montant suggéré : ${prix} €",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        SizedBox(height: 16),
        ElevatedButton.icon(
          icon: Icon(Icons.coffee),
          label: Text("Pay me a coffee"),
          onPressed: openBinanceUrl,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            backgroundColor: Colors.orangeAccent,
            foregroundColor: Colors.white,
            textStyle: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Paiement Binance"),
        actions: [
          IconButton(
            icon: Icon(Icons.admin_panel_settings),
            onPressed: askPasswordAndEdit,
            tooltip: "Modifier lien (admin)",
          ),
        ],
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: buildDonationSection(),
              ),
    );
  }
}
