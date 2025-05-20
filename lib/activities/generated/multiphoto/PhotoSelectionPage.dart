import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

/// PhotoSelectionPage : affiche une grille des images déjà uploadées dans un dossier de Storage.
/// Quand on clique sur une photo, on fait pop(url) pour retourner au parent.
class PhotoSelectionPage extends StatefulWidget {
  /// Chemin du dossier dans Firebase Storage à lister.
  /// Exemple : 'uploads/user_photos' ou 'uploads/modeling_shots'
  final String storageFolderPath;

  const PhotoSelectionPage({Key? key, required this.storageFolderPath})
    : super(key: key);

  @override
  State<PhotoSelectionPage> createState() => _PhotoSelectionPageState();
}

class _PhotoSelectionPageState extends State<PhotoSelectionPage> {
  /// Instance de FirebaseStorage
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Liste des URLs de téléchargement à afficher
  List<String> _downloadUrls = [];

  /// Booléen “chargement en cours”
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAllImagesFromStorage();
  }

  /// Récupère la liste de tous les fichiers dans le dossier `widget.storageFolderPath`
  /// et en extrait leurs downloadURLs.
  Future<void> _fetchAllImagesFromStorage() async {
    try {
      // 1) Référence au dossier
      final Reference folderRef = _storage.ref().child(
        widget.storageFolderPath,
        // widget.storageFolderPath,
      );

      // 2) appelle listAll() pour lister tous les objets du dossier
      final ListResult listResult = await folderRef.listAll();

      // 3) Récupérer les download URLs pour chaque élément
      final List<String> urls = [];
      for (Reference itemRef in listResult.items) {
        final String url = await itemRef.getDownloadURL();
        urls.add(url);
      }

      // 4) Mettre à jour l'état
      if (mounted) {
        setState(() {
          _downloadUrls = urls;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Erreur lors de la récupération des images : $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choisir une photo')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _downloadUrls.isEmpty
              ? const Center(
                child: Text(
                  'Aucune image trouvée dans Storage.',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              )
              : Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.builder(
                  itemCount: _downloadUrls.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // 3 colonnes
                    crossAxisSpacing: 8.0, // espacement entre colonnes
                    mainAxisSpacing: 8.0, // espacement entre lignes
                    childAspectRatio: 1.0, // carré
                  ),
                  itemBuilder: (context, index) {
                    final url = _downloadUrls[index];
                    return GestureDetector(
                      onTap: () {
                        // Retourne immédiatement l'URL sélectionnée
                        Navigator.of(context).pop(url);
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, _) => Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                          errorWidget:
                              (context, _, __) =>
                                  const Icon(Icons.broken_image),
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
