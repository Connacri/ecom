import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'photo_provider.dart';

class PhotoUploadPage extends StatefulWidget {
  const PhotoUploadPage({super.key});

  @override
  State<PhotoUploadPage> createState() => _PhotoUploadPageState();
}

class _PhotoUploadPageState extends State<PhotoUploadPage> {
  @override
  void initState() {
    super.initState();
    // Charger les images au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PhotoProvider>(
        context,
        listen: false,
      ).loadImages(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Uploader des photos'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Section d'upload
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 24.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: IconButton(
                    onPressed: () => _uploadImages(context),
                    icon: const Icon(Icons.upload_file),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                Flexible(
                  child: IconButton(
                    onPressed: () => _takePhoto(context),
                    icon: const Icon(Icons.camera_alt),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Titre
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Stock d\'Images :',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Grille d'images
          Expanded(
            child: Consumer<PhotoProvider>(
              builder: (context, photoProvider, child) {
                // Cas où il n'y a pas d'images
                if (photoProvider.images.isEmpty && !photoProvider.isLoading) {
                  return const Center(
                    child: Text(
                      'Aucune image disponible.\nUtilisez les boutons ci-dessus pour ajouter des images.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                // Grille d'images avec pagination
                return NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    // Charger plus d'images quand on atteint la fin
                    if (scrollInfo.metrics.pixels ==
                            scrollInfo.metrics.maxScrollExtent &&
                        !photoProvider.isLoading &&
                        photoProvider.hasMoreData) {
                      photoProvider.loadImages();
                    }
                    return true;
                  },
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8.0,
                          mainAxisSpacing: 8.0,
                        ),
                    itemCount:
                        photoProvider.images.length +
                        (photoProvider.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Indicateur de chargement à la fin
                      if (index == photoProvider.images.length) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      // Affichage des images
                      String imageUrl = photoProvider.images[index]['url'];
                      return ImageGridItem(
                        imageUrl: imageUrl,
                        photoProvider: photoProvider,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Méthode pour uploader des images
  Future<void> _uploadImages(BuildContext context) async {
    final photoProvider = Provider.of<PhotoProvider>(context, listen: false);

    try {
      await photoProvider.pickAndUploadMultipleImages();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erreur lors de l'upload : $e")));
      }
    }
  }

  // Méthode pour prendre une photo et l'uploader
  Future<void> _takePhoto(BuildContext context) async {
    final photoProvider = Provider.of<PhotoProvider>(context, listen: false);

    try {
      await photoProvider.takeAndUploadPhoto();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de la prise de photo : $e")),
        );
      }
    }
  }
}

// Widget séparé pour améliorer la lisibilité
class ImageGridItem extends StatelessWidget {
  final String imageUrl;
  final PhotoProvider photoProvider;

  const ImageGridItem({
    super.key,
    required this.imageUrl,
    required this.photoProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Image avec cache
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder:
                (context, url) => Container(
                  color: Colors.grey.shade300,
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
            errorWidget:
                (context, url, error) => Container(
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.error),
                ),
          ),
        ),

        // Zone tactile pour prévisualiser l'image
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showImagePreview(context, imageUrl),
              splashColor: Colors.white.withOpacity(0.3),
              highlightColor: Colors.transparent,
            ),
          ),
        ), // Bouton de suppression
        Positioned(
          right: 0,
          top: 0,
          child: IconButton(
            icon: Icon(Icons.delete, color: Colors.red, size: 18),
            onPressed: () async {
              //  await photoProvider.deleteImage(imageUrl);
              _confirmDeleteImage(context, imageUrl);
            },
          ),
        ),
      ],
    );
  }

  // Boîte de dialogue de confirmation pour la suppression
  void _confirmDeleteImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmation'),
          content: const Text(
            'Êtes-vous sûr de vouloir supprimer cette image ?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Supprimer'),
              onPressed: () async {
                Navigator.of(context).pop();

                // Afficher un indicateur de chargement
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Suppression en cours..."),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }

                try {
                  await Provider.of<PhotoProvider>(
                    context,
                    listen: false,
                  ).deleteImage(imageUrl);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Image supprimée avec succès"),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Erreur lors de la suppression : $e"),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Prévisualisation d'image en plein écran
  void _showImagePreview(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImagePreviewScreen(imageUrl: imageUrl),
      ),
    );
  }
}

// Écran de prévisualisation d'image
class ImagePreviewScreen extends StatelessWidget {
  final String imageUrl;

  const ImagePreviewScreen({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Aperçu de l\'image',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 3.0,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            placeholder:
                (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
            errorWidget:
                (context, url, error) =>
                    const Icon(Icons.error, color: Colors.white, size: 48),
          ),
        ),
      ),
    );
  }
}
