import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class VendingMachineScreen extends StatefulWidget {
  @override
  _VendingMachineScreenState createState() => _VendingMachineScreenState();
}

class _VendingMachineScreenState extends State<VendingMachineScreen> {
  late WebSocketChannel channel;
  List<Product> products = [
    Product(name: "Eau", price: 50),
    Product(name: "Jus", price: 100),
    Product(name: "Chips", price: 80),
    Product(name: "Chocolat", price: 120),
    Product(name: "Soda", price: 150),
  ];
  List<int> coinValues = [5, 10, 20, 50, 100, 200];
  Product? selectedProduct;
  int insertedAmount = 0;
  int changeAmount = 0;
  String changeDetails = 'Aucune monnaie à rendre';
  bool relayState = false;

  @override
  void initState() {
    super.initState();
    // Connexion au serveur WebSocket (remplacer par l'IP de votre ESP8266)
    channel = WebSocketChannel.connect(Uri.parse('ws://192.168.1.160:81'));

    channel.stream.listen(
      (message) {
        final data = jsonDecode(message);
        if (data['relayState'] != null) {
          setState(() {
            relayState = data['relayState'];
            if (data['changeAmount'] != null) {
              changeAmount = data['changeAmount'];
              changeDetails =
                  data['changeDetails'] ?? 'Aucune monnaie à rendre';
            }
          });
        }
      },
      onError: (error) {
        print('Erreur WebSocket: $error');
      },
    );
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  String calculateChangeDetails(int amount) {
    const coins = [200, 100, 50, 20, 10, 5];
    int remaining = amount;
    List<String> details = [];

    for (int coin in coins) {
      if (remaining >= coin) {
        int count = remaining ~/ coin;
        if (count > 0) {
          details.add('${count} x ${coin} DA');
          remaining -= count * coin;
        }
      }
    }

    return details.isNotEmpty ? details.join(', ') : 'Aucune monnaie à rendre';
  }

  void updateChange() {
    if (selectedProduct != null) {
      int change = insertedAmount - selectedProduct!.price;
      if (change < 0) change = 0;
      setState(() {
        changeAmount = change;
        changeDetails = calculateChangeDetails(changeAmount);
      });
    } else {
      setState(() {
        changeAmount = 0;
        changeDetails = 'Aucune monnaie à rendre';
      });
    }
    sendUpdate();
  }

  void addCoin(int value) {
    setState(() {
      insertedAmount += value;
    });
    updateChange();
  }

  void selectProduct(Product product) {
    setState(() {
      selectedProduct = product;
    });
    updateChange();
  }

  void sendUpdate() {
    if (selectedProduct == null) return;
    final message = jsonEncode({
      'action': 'update',
      'amount': insertedAmount,
      'price': selectedProduct!.price,
    });
    channel.sink.add(message);
  }

  void purchase() {
    if (selectedProduct == null) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Erreur'),
              content: Text('Veuillez sélectionner un produit.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK'),
                ),
              ],
            ),
      );
      return;
    }

    if (insertedAmount < selectedProduct!.price) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Montant insuffisant'),
              content: Text('Veuillez insérer plus d\'argent.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK'),
                ),
              ],
            ),
      );
      return;
    }

    final change = insertedAmount - selectedProduct!.price;
    final details = calculateChangeDetails(change);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Achat réussi!'),
            content: Text('Monnaie rendue: $change DA\nDétail: $details'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
    );

    final message = jsonEncode({
      'action': 'purchase',
      'product': selectedProduct!.name,
      'amount': insertedAmount,
      'price': selectedProduct!.price,
    });
    channel.sink.add(message);

    setState(() {
      insertedAmount = 0;
      changeAmount = 0;
      changeDetails = 'Aucune monnaie à rendre';
      selectedProduct = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Machine de Vente')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Produits',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                shrinkWrap: true,
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  final isSelected = selectedProduct?.name == product.name;
                  return GestureDetector(
                    onTap: () => selectProduct(product),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue[100] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            product.name,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('${product.price} DA'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Pièces',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children:
                  coinValues.map((value) {
                    return GestureDetector(
                      onTap: () => addCoin(value),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.amber[800]!,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$value DA',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
            SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Produit sélectionné: ${selectedProduct?.name ?? "Aucun"}',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Prix: ${selectedProduct?.price ?? 0} DA',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Somme insérée: $insertedAmount DA',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Monnaie à rendre: $changeAmount DA',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Détail de la monnaie: $changeDetails',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(
                          'État du relais: ${relayState ? "ON" : "OFF"}',
                          style: TextStyle(
                            fontSize: 16,
                            color: relayState ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: purchase,
                            child: Text('Acheter'),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class Product {
  final String name;
  final int price;

  Product({required this.name, required this.price});
}
