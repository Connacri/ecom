import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/AuthProvider.dart';
import '../../fonctions/DeleteUserButton.dart';
import '../../pages/MyApp.dart';
import '../providers.dart';
import '../screens/userHomePage.dart';
import 'multiphoto/PhotoSelectionPage.dart';

class ProfHomePage extends StatefulWidget {
  const ProfHomePage({super.key});

  @override
  State<ProfHomePage> createState() => _ProfHomePageState();
}

class _ProfHomePageState extends State<ProfHomePage> {
  final String backgrounds = 'assets/photos/a (8).png';
  final String profile = 'assets/photos/a (6).png';
  final String modeling = 'assets/photos/a (8).png';

  Future<List<String>> fetchImageUrlsFromStorage() async {
    final storage = FirebaseStorage.instance;
    final ListResult result = await storage.ref('uploads').listAll();
    final List<String> urls = [];

    for (final ref in result.items) {
      final url = await ref.getDownloadURL();
      urls.add(url);
    }

    return urls;
  }

  // Liste des URLs des images depuis Firebase Storage
  List<String> modelingShotsImages = [];

  late PageController _pageController;
  int _currentPage = 0;
  User? _user = FirebaseAuth.instance.currentUser;
  bool isSigningOut = false;
  bool isLoading = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0, viewportFraction: 0.92);
    _loadImageUrls();
  }

  Future<void> _loadImageUrls() async {
    modelingShotsImages = await fetchImageUrlsFromStorage();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handleSignOut() async {
    setState(() => isSigningOut = true);

    try {
      await Future.wait([
        _authService.signOut(),
        Future.delayed(const Duration(seconds: 2)),
      ]);

      if (mounted) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (ctx) => MyApp1()));
      }

      if (mounted) {
        setState(() {
          _user = null;
        });
      }
    } catch (e) {
      if (mounted) {
        // Gérer l'erreur
      }
    } finally {
      if (mounted) {
        setState(() => isSigningOut = false);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final childProvider = Provider.of<ChildProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    return user == null
        ? CustomShimmerEffect()
        : Scaffold(
          body: Stack(
            children: [
              // ——— Fond et overlay existants ———
              SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: FadeInImage(
                  placeholder: AssetImage(profile), // Placeholder image
                  image:
                      user.photos != null && user.photos!.isNotEmpty
                          ? CachedNetworkImageProvider(user.photos!.last)
                          : AssetImage(profile) as ImageProvider,
                  fit: BoxFit.cover,
                  fadeInDuration: Duration(milliseconds: 1500),
                  fadeOutDuration: Duration(milliseconds: 1200),
                ),

                //  Image.asset(background, fit: BoxFit.cover),
              ),
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withOpacity(0.5),
              ),
              Positioned(
                top: 150,
                right: 12,
                child: GestureDetector(
                  onTap: () async {
                    // On ouvre la page de sélection d’images dans Storage
                    final selectedUrl = await Navigator.of(
                      context,
                    ).push<String>(
                      MaterialPageRoute(
                        builder:
                            (_) => const PhotoSelectionPage(
                              storageFolderPath: 'uploads',
                            ),
                      ),
                    );

                    // Si l’utilisateur a sélectionné une URL, on met à jour
                    if (selectedUrl != null) {
                      await userProvider.updateListPhoto(selectedUrl);
                    }
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white70,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.photo,
                      size: 18,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),

              // ——— Contenu général ———
              Column(
                children: [
                  const SizedBox(height: 40),
                  // ——— Header ———
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {},
                          child: const Icon(
                            Icons.menu,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const Expanded(child: SizedBox()),
                        const Text(
                          'Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Expanded(child: SizedBox()),
                        GestureDetector(
                          onTap: () {},
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ——— Photo de profil avec icône “éditer” ———
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Grand cercle extérieur
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 3,
                            ),
                          ),
                        ),
                        // Cercle intermédiaire
                        Container(
                          width: 116,
                          height: 116,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.6),
                              width: 3,
                            ),
                          ),
                        ),
                        // Cercle intérieur (photo actuelle)
                        Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(shape: BoxShape.circle),
                          child: ClipOval(
                            child: FadeInImage(
                              placeholder: AssetImage(
                                profile,
                              ), // Placeholder image
                              image:
                                  user.logoUrl != null &&
                                          user.logoUrl!.isNotEmpty
                                      ? CachedNetworkImageProvider(
                                        user.logoUrl!,
                                      )
                                      : AssetImage(profile) as ImageProvider,
                              fit: BoxFit.cover,
                              fadeInDuration: Duration(milliseconds: 1500),
                              fadeOutDuration: Duration(milliseconds: 1200),
                            ),
                          ),
                        ),

                        // Icône “éditer”
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () async {
                              // On ouvre la page de sélection d’images dans Storage
                              final selectedUrl = await Navigator.of(
                                context,
                              ).push<String>(
                                MaterialPageRoute(
                                  builder:
                                      (_) => const PhotoSelectionPage(
                                        storageFolderPath: 'uploads',
                                      ),
                                ),
                              );
                              // Si l’utilisateur a sélectionné une URL, on met à jour
                              if (selectedUrl != null) {
                                await userProvider.updateProfilePhoto(
                                  selectedUrl,
                                );
                              }
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white70,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 18,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ——— Nom et pseudo ———
                  Text(
                    user.name, // ou user.name.capitalize()
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email, // ou user.email.capitalize()
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: isLoading ? null : _handleSignOut,
                          icon:
                              isLoading
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(
                                    Icons.logout,
                                    color: Colors.white,
                                  ),
                          tooltip: 'Logout',
                        ),
                        DeleteAccountButton(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // ——— Statistiques ———
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        _StatItem(count: '220', label: 'Followers'),
                        _StatItem(count: '180', label: 'Following'),
                        _StatItem(count: '270', label: 'Pictures'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ——— CAROUSEL “Modeling Shots” (inchangé) ———
                  Expanded(
                    child: Stack(
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          itemCount: modelingShotsImages.length,
                          onPageChanged: (int index) {
                            setState(() {
                              _currentPage = index;
                            });
                          },

                          itemBuilder: (context, index) {
                            final imgPath = modelingShotsImages[index];
                            return Stack(
                              children: [
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    image: DecorationImage(
                                      image:
                                          user.photos != null &&
                                                  user.photos!.isNotEmpty
                                              ? CachedNetworkImageProvider(
                                                imgPath,
                                              )
                                              : AssetImage(modeling)
                                                  as ImageProvider,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      color: Colors.black.withOpacity(0.3),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 50,
                                  left: 32,
                                  right: 32,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Align(
                                        alignment: Alignment.topLeft,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white
                                                .withOpacity(0.8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 8,
                                            ),
                                          ),
                                          onPressed: () {
                                            // Action sur le bouton + (ex : ouvrir une page détaillée)
                                          },
                                          child: Text(
                                            '+${modelingShotsImages.length}  $index',
                                            style: const TextStyle(
                                              color: Colors.black87,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Modeling Shots',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                modelingShotsImages.length,
                                (idx) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4.0,
                                    ),
                                    child: _DotIndicator(
                                      isActive: idx == _currentPage,
                                      num: idx,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ],
          ),
        );
  }
}

/// Widget pour afficher une statistique (nombre + label)
class _StatItem extends StatelessWidget {
  final String count;
  final String label;
  const _StatItem({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }
}

/// Point (dot) pour indiquer la page active dans le carousel
class _DotIndicator extends StatelessWidget {
  final bool isActive;
  final int num;
  const _DotIndicator({required this.isActive, required this.num});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: isActive ? 30 : 25,
          height: isActive ? 30 : 25,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Colors.white : Colors.white54,
          ),
        ),
        Text(num.toString()),
      ],
    );
  }
}
