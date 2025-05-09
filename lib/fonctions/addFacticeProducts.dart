import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'dart:math';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> ajouterAnnoncesFacticesAvecImages() async {
  final firestore = FirebaseFirestore.instance;
  final storage = FirebaseStorage.instance;
  final adsCollection = firestore.collection('ads');
  final random = Random();

  // Étape 1 : Lister les fichiers dans le dossier 'ads/'
  final ListResult result = await storage.ref('ads').listAll();
  final List<String> imageUrls = [];

  for (final Reference ref in result.items) {
    final url = await ref.getDownloadURL();
    imageUrls.add(url);
  }

  if (imageUrls.isEmpty) {
    print("❌ Aucune image trouvée dans 'ads/' sur Firebase Storage.");
    return;
  }

  // Étape 2 : Créer les annonces
  final fakeTitles = [
    'Promo exceptionnelle sur les chaussures !',
    'Nouvelle collection été 2025',
    'Remise de 30% sur les accessoires',
    'Livraison gratuite tout le mois',
    'Offre spéciale Ramadan',
    'Promo fin de saison',
    'Soldes sur les smartphones',
    'Offre flash aujourd’hui uniquement',
    'Achetez-en 2, recevez 1 gratuit',
    'Retour en stock - Quantité limitée'
  ];

  final fakeDescriptions = [
    'Profitez de nos meilleures offres sur les produits tendance.',
    'Des réductions incroyables sur une large gamme de produits.',
    'Offre limitée dans le temps ! Ne manquez pas cette opportunité.',
    'Ajoutez du style à votre quotidien à petit prix.',
    'Commandez maintenant et économisez gros.',
    'Des produits de qualité à prix réduit.'
  ];

  // Étape 3 : Ajouter les documents
  for (int i = 0; i < 20; i++) {
    final ad = {
      'title': fakeTitles[random.nextInt(fakeTitles.length)],
      'description': fakeDescriptions[random.nextInt(fakeDescriptions.length)],
      'image': imageUrls[random.nextInt(imageUrls.length)],
      'createdAt': FieldValue.serverTimestamp(),
    };

    await adsCollection.add(ad);
    print('✅ Annonce $i ajoutée avec image : ${ad['image']}');
  }

  print('✅ Toutes les annonces factices avec images ont été ajoutées.');
}



Future<void> ajouterAnnoncesFactices() async {
  final firestore = FirebaseFirestore.instance;
  final adsCollection = firestore.collection('ads');
  final random = Random();

  final fakeTitles = [
    'Promo exceptionnelle sur les chaussures !',
    'Nouvelle collection été 2025',
    'Remise de 30% sur les accessoires',
    'Livraison gratuite tout le mois',
    'Offre spéciale Ramadan',
    'Promo fin de saison',
    'Soldes sur les smartphones',
    'Offre flash aujourd’hui uniquement',
    'Achetez-en 2, recevez 1 gratuit',
    'Retour en stock - Quantité limitée'
  ];

  final fakeDescriptions = [
    'Profitez de nos meilleures offres sur les produits tendance.',
    'Des réductions incroyables sur une large gamme de produits.',
    'Offre limitée dans le temps ! Ne manquez pas cette opportunité.',
    'Ajoutez du style à votre quotidien à petit prix.',
    'Commandez maintenant et économisez gros.',
    'Des produits de qualité à prix réduit.'
  ];

  final fakeImages = [
    'https://via.placeholder.com/600x400?text=Ad+1',
    'https://via.placeholder.com/600x400?text=Ad+2',
    'https://via.placeholder.com/600x400?text=Ad+3',
    'https://via.placeholder.com/600x400?text=Ad+4',
    'https://via.placeholder.com/600x400?text=Ad+5',
  ];

  for (int i = 0; i < 20; i++) {
    final ad = {
      'title': fakeTitles[random.nextInt(fakeTitles.length)],
      'description': fakeDescriptions[random.nextInt(fakeDescriptions.length)],
      'image': fakeImages[random.nextInt(fakeImages.length)],
      'createdAt': FieldValue.serverTimestamp(),
    };

    await adsCollection.add(ad);
    print('✅ Annonce $i ajoutée');
  }

  print('✅ Toutes les annonces factices ont été ajoutées avec succès.');
}
