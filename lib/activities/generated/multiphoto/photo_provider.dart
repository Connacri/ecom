import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart' as path_provider;

class PhotoProvider extends ChangeNotifier {
  final firebase_storage.FirebaseStorage _storage =
      firebase_storage.FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  // Images récupérées depuis Firestore
  List<Map<String, dynamic>> _images = [];

  // État de chargement
  bool _isLoading = false;

  // Pour la pagination
  DocumentSnapshot? _lastVisible;
  static const int _pageSize = 15;
  bool _hasMoreData = true;

  // Getters
  List<Map<String, dynamic>> get images => _images;
  bool get isLoading => _isLoading;
  bool get hasMoreData => _hasMoreData;
  List<XFile> _pickedImages = [];
  List<String> _uploadedImageUrls = [];

  List<XFile> get pickedImages => _pickedImages;
  List<String> get uploadedImageUrls => _uploadedImageUrls;
  // Configuration de compression
  static const int compressQuality = 80;
  static const int minWidth = 1080;
  static const int minHeight = 1080;
  static const double webpCompressionFactor = 0.8;
  // Liste locale des XFile sélectionnés (avant upload)
  final List<XFile> _pickedFiles = [];

  // URLs obtenues après upload (vide tant que l'upload n'a pas été fait)
  List<String> _uploadedUrls = [];

  bool _isUploading = false;
  bool get isUploading => _isUploading;

  // Getters pour l'UI
  List<XFile> get pickedFiles => List.unmodifiable(_pickedFiles);
  List<String> get uploadedUrls => List.unmodifiable(_uploadedUrls);
  // Constructeur - Charger les images au démarrage
  PhotoProvider() {
    loadImages(refresh: true);
  }

  Future<void> pickAndUploadMultipleImages() async {
    try {
      _setLoading(true);

      // 1) Ouvrir le sélecteur de la galerie
      final List<XFile>? pickedFiles = await _picker.pickMultiImage(
        limit: 10, // Limite le nombre d'images à 10
      );

      if (pickedFiles == null || pickedFiles.isEmpty) {
        _setLoading(false);
        return;
      }

      // Limiter manuellement à 10 images si nécessaire
      final List<XFile> limitedFiles =
          pickedFiles.length > 10 ? pickedFiles.sublist(0, 10) : pickedFiles;

      // 2) Pour chaque image sélectionnée, compresser puis uploader
      for (var file in limitedFiles) {
        // Compresser l'image en WebP
        final File compressedFile = await _compressImage(File(file.path));

        // Utiliser l'extension .webp pour le fichier
        final String fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${p.basenameWithoutExtension(file.path)}.webp';

        // Définir le chemin dans le storage
        final firebase_storage.Reference ref = _storage
            .ref()
            .child('uploads')
            .child(fileName);

        // Uploader le fichier compressé
        final firebase_storage.UploadTask uploadTask = ref.putFile(
          compressedFile,
        );

        // Attendre la fin de l'upload
        final firebase_storage.TaskSnapshot snapshot = await uploadTask
            .whenComplete(() {});

        // Récupérer l'URL de téléchargement
        final String downloadUrl = await snapshot.ref.getDownloadURL();

        // Ajouter l'URL à Firestore
        String docId = await _addImageUrlToFirestore(downloadUrl);

        // Ajouter immédiatement l'image à la liste locale
        _images.insert(0, {
          'url': downloadUrl,
          'createdAt': Timestamp.now(),
          'id': docId,
        });

        // Notifier pour mettre à jour l'UI immédiatement
        notifyListeners();

        // Supprimer le fichier temporaire compressé
        if (await compressedFile.exists()) {
          await compressedFile.delete();
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de pickAndUploadMultipleImages : $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> pickMultipleImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? images = await picker.pickMultiImage();

    if (images != null && images.isNotEmpty) {
      _pickedImages = images;
      notifyListeners();
    }
  }

  Future<void> uploadPickedImages() async {
    _uploadedImageUrls.clear();

    for (var image in _pickedImages) {
      final url = await _uploadImage(File(image.path));
      if (url != null) {
        _uploadedImageUrls.add(url);
      }
    }

    notifyListeners();
  }

  Future<String?> _uploadImage(File file) async {
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final storageRef = firebase_storage.FirebaseStorage.instance.ref().child(
        'cours/$fileName.jpg',
      );
      await storageRef.putFile(file);
      return await storageRef.getDownloadURL();
    } catch (e) {
      debugPrint('Erreur upload image: $e');
      return null;
    }
  }

  void clear() {
    _pickedImages.clear();
    _uploadedImageUrls.clear();
    notifyListeners();
  }

  // Méthode pour prendre une photo avec la caméra et l'uploader
  Future<void> takeAndUploadPhoto() async {
    try {
      _setLoading(true);

      // Prendre une photo avec la caméra
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);

      if (photo == null) {
        _setLoading(false);
        return;
      }

      // Compresser l'image en WebP
      final File compressedFile = await _compressImage(File(photo.path));

      // Définir le nom du fichier
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${p.basenameWithoutExtension(photo.path)}.webp';

      // Référence de stockage
      final firebase_storage.Reference ref = _storage
          .ref()
          .child('uploads')
          .child(fileName);

      // Upload du fichier compressé
      final firebase_storage.UploadTask uploadTask = ref.putFile(
        compressedFile,
      );
      final firebase_storage.TaskSnapshot snapshot = await uploadTask
          .whenComplete(() {});

      // Récupérer l'URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // Ajouter l'URL à Firestore
      String docId = await _addImageUrlToFirestore(downloadUrl);

      // Ajouter immédiatement l'image à la liste locale
      _images.insert(0, {
        'url': downloadUrl,
        'createdAt': Timestamp.now(),
        'id': docId,
      });

      // Notifier pour mettre à jour l'UI immédiatement
      notifyListeners();

      // Supprimer le fichier temporaire
      if (await compressedFile.exists()) {
        await compressedFile.delete();
      }
    } catch (e) {
      debugPrint('Erreur lors de takeAndUploadPhoto : $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Ajouter une URL à Firestore
  Future<String> _addImageUrlToFirestore(String downloadUrl) async {
    try {
      DocumentReference docRef = await _firestore.collection('storage').add({
        'url': downloadUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout de l\'URL à Firestore : $e');
      rethrow;
    }
  }

  // Méthode pour compresser une image
  // Future<File> _compressImage(File file) async {
  //   final Directory tempDir = await path_provider.getTemporaryDirectory();
  //   final String targetPath = p.join(
  //     tempDir.path,
  //     '${DateTime.now().millisecondsSinceEpoch}.webp',
  //   );
  //
  //   final result = await FlutterImageCompress.compressAndGetFile(
  //     file.absolute.path,
  //     targetPath,
  //     quality: compressQuality,
  //     minWidth: minWidth,
  //     minHeight: minHeight,
  //     keepExif: false,
  //     format: CompressFormat.webp,
  //   );
  //
  //   if (result == null) {
  //     return file;
  //   }
  //
  //   return File(result.path);
  // }

  // Charger les images depuis Firestore avec pagination
  Future<void> loadImages({bool refresh = false}) async {
    if (_isLoading || (!refresh && !_hasMoreData)) return;

    _setLoading(true);

    try {
      // Si on rafraîchit, on repart de zéro
      if (refresh) {
        _images = [];
        _lastVisible = null;
        _hasMoreData = true;
      }

      // Construire la requête avec pagination
      Query query = _firestore
          .collection('storage')
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);

      if (_lastVisible != null) {
        query = query.startAfterDocument(_lastVisible!);
      }

      // Exécuter la requête
      QuerySnapshot querySnapshot = await query.get();

      // Si on n'a pas de résultats, il n'y a plus de données
      if (querySnapshot.docs.isEmpty) {
        _hasMoreData = false;
        _setLoading(false);
        return;
      }

      // Traiter les résultats
      List<Map<String, dynamic>> newImages = [];

      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] =
            doc.id; // Ajouter l'ID du document pour faciliter la suppression
        newImages.add(data);
      }

      // Mettre à jour la liste d'images
      _images.addAll(newImages);

      // Mettre à jour le dernier document visible pour la pagination
      _lastVisible = querySnapshot.docs.last;

      // Vérifier s'il reste des données à charger
      _hasMoreData = querySnapshot.docs.length >= _pageSize;

      // Notifier des changements
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors du chargement des images: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Supprimer une image
  Future<void> deleteImage(String url) async {
    try {
      _setLoading(true);

      // 1. Trouver et supprimer le document dans Firestore
      QuerySnapshot querySnapshot =
          await _firestore
              .collection('storage')
              .where('url', isEqualTo: url)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        WriteBatch batch = _firestore.batch();
        for (var doc in querySnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      // 2. Supprimer le fichier dans Firebase Storage
      try {
        firebase_storage.Reference ref = _storage.refFromURL(url);
        await ref.delete();
      } catch (e) {
        debugPrint('Erreur lors de la suppression du fichier dans Storage: $e');
        // On continue même si la suppression du fichier échoue
      }

      // 3. Mettre à jour la liste locale d'images
      _images.removeWhere((image) => image['url'] == url);
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de la suppression de l\'image: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Pour synchroniser les images Firebase Storage avec Firestore (utilité ponctuelle)
  Future<void> syncStorageWithFirestore() async {
    try {
      _setLoading(true);

      // Récupérer la liste des fichiers dans le dossier 'uploads'
      final firebase_storage.ListResult result =
          await _storage.ref('uploads').listAll();

      // Pour chaque fichier dans le Storage
      for (final firebase_storage.Reference ref in result.items) {
        final String downloadUrl = await ref.getDownloadURL();

        // Vérifier si l'URL existe déjà dans Firestore
        QuerySnapshot querySnapshot =
            await _firestore
                .collection('storage')
                .where('url', isEqualTo: downloadUrl)
                .limit(1)
                .get();

        // Si l'URL n'existe pas dans Firestore, l'ajouter
        if (querySnapshot.docs.isEmpty) {
          await _firestore.collection('storage').add({
            'url': downloadUrl,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // Rafraîchir la liste d'images
      await loadImages(refresh: true);
    } catch (e) {
      debugPrint('Erreur lors de la synchronisation Storage/Firestore: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  //////////////////////////////////////////////////////////
  /// Vide la liste de fichiers sélectionnés (si besoin de "reset").
  void clearPicked() {
    _pickedFiles.clear();
    _uploadedUrls.clear();
    notifyListeners();
  }

  /// Méthode pour sélectionner plusieurs images (stockées localement, sans upload)
  Future<void> pickImages({int limit = 10}) async {
    try {
      final List<XFile>? picked = await _picker.pickMultiImage(
        // on peut également proposer un paramètre « limit »
      );
      if (picked == null || picked.isEmpty) return;

      // Contrainte manuelle de nombre max
      final List<XFile> limited =
          picked.length > limit ? picked.sublist(0, limit) : picked;

      // On ajoute à la liste interne (sans upload)
      _pickedFiles.clear();
      _pickedFiles.addAll(limited);
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur pickImages : $e');
      rethrow;
    }
  }

  /// Méthode pour prendre une photo (stocker localement, sans upload)
  Future<void> takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo == null) return;

      _pickedFiles.clear();
      _pickedFiles.add(photo);
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur takePhoto : $e');
      rethrow;
    }
  }

  /// Compresse un fichier en format WebP et renvoie le File compressé
  Future<File> _compressImage(File file) async {
    final Directory tempDir = await path_provider.getTemporaryDirectory();
    final String targetPath = p.join(
      tempDir.path,
      '${DateTime.now().millisecondsSinceEpoch}.webp',
    );

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: compressQuality,
      minWidth: minWidth,
      minHeight: minHeight,
      keepExif: false,
      format: CompressFormat.webp,
    );

    if (result == null) {
      // Si compression échoue, on retourne le fichier d’origine
      return file;
    }
    return File(result.path);
  }

  /// Méthode appelée dans _submitForm() pour uploader toutes les images sélectionnées
  /// - compress
  /// - upload sur Firebase Storage
  /// - enregistrer URL dans Firestore (collection 'storage')
  /// - stocker la liste des URL dans _uploadedUrls
  Future<List<String>> uploadSelectedImages() async {
    if (_pickedFiles.isEmpty) return [];

    _setUploading(true);

    try {
      final List<String> urls = [];

      for (var xfile in _pickedFiles) {
        final File original = File(xfile.path);
        final File compressedFile = await _compressImage(original);

        final String fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${p.basenameWithoutExtension(xfile.path)}.webp';
        final firebase_storage.Reference ref = _storage
            .ref()
            .child('uploads')
            .child(fileName);

        final firebase_storage.UploadTask uploadTask = ref.putFile(
          compressedFile,
        );
        final firebase_storage.TaskSnapshot snapshot = await uploadTask
            .whenComplete(() {});

        final String downloadUrl = await snapshot.ref.getDownloadURL();
        // Ajouter l’URL à Firestore
        await _firestore.collection('storage').add({
          'url': downloadUrl,
          'createdAt': FieldValue.serverTimestamp(),
        });

        urls.add(downloadUrl);

        // Supprimer le fichier temporaire compressé
        if (await compressedFile.exists()) {
          await compressedFile.delete();
        }
      }

      _uploadedUrls = urls;
      return urls;
    } catch (e) {
      debugPrint('Erreur uploadSelectedImages : $e');
      rethrow;
    } finally {
      _setUploading(false);
    }
  }

  void _setUploading(bool val) {
    _isUploading = val;
    notifyListeners();
  }
}
