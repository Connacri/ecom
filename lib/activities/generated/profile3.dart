import 'dart:ui';

import 'package:flutter/material.dart';

/// Page de profil avec fond, zone floutée et texte “More+”
class Profile3 extends StatefulWidget {
  const Profile3({super.key});

  @override
  State<Profile3> createState() => _Profile3State();
}

class _Profile3State extends State<Profile3> {
  // État pour savoir si on a cliqué sur “More+” ou non
  bool isExpanded = false;

  // Texte de présentation (exemple)
  final String longDescription = """
Je suis développeur Flutter basé en Algérie, passionné par la création d’applications mobiles performantes et esthétiques. 
J’aime travailler sur des projets e-commerce, intégrer des services comme Firebase ou Supabase, et optimiser les performances avec ObjectBox. 
Dans mon temps libre, je teste des frameworks UI, j’écris des articles techniques et j’aide la communauté via des tutoriels. 
N’hésitez pas à me contacter si vous souhaitez collaborer ou échanger sur des idées innovantes !
""";

  @override
  Widget build(BuildContext context) {
    // Récupère la taille de l'écran
    final size = MediaQuery.of(context).size;

    return Scaffold(
      // Pas d'AppBar : tout est dans le body pour gérer le fond d'écran derrière
      body: Stack(
        children: [
          // 1) Image de fond plein écran
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Image.asset(
              'assets/photos/a (5).png', // Votre asset
              fit: BoxFit.cover,
            ),
          ),

          // 2) Overlay sombre semi-transparent (pour améliorer la lisibilité)
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withOpacity(0.3),
          ),

          // 3) Contenu du profil (par dessus le fond)
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),
                // 3.1) Bouton retour et titre (facultatif)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          // Navigator.pop(context);
                        },
                        child: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 3.2) Photo de profil (optionnel)
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      image: const DecorationImage(
                        image: AssetImage('assets/photos/a (7).png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 3.3) Nom et pseudo
                const Text(
                  'Votre Nom Prénom',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '@votre_pseudo',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),

                const Spacer(), // pousse tout vers le haut pour que le blur soit en bas
                // 4) Zone floutée avec texte et “More+”
                //    On utilise un AnimatedContainer pour animer la hauteur
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  // Si expanded, on permet un maximum de hauteur ; sinon, on fixe une hauteur réduite
                  height: isExpanded ? size.height * 0.5 : size.height * 0.25,
                  width: double.infinity,
                  // On utilise Stack pour empiler le blur et le contenu texte
                  child: Stack(
                    children: [
                      // 4.1) Le filtre de flou (BackDropFilter)
                      ClipRRect(
                        // On arrondit uniquement les coins supérieurs de la carte floutée
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(24),
                                topRight: Radius.circular(24),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 4.2) Contenu texte + “More+” en colonne
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 20.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Un petit indicateur visuel (une mini barre) pour signaler qu'on peut glisser
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white70,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 4.2.1) Texte d'introduction ou titre du paragraphe
                            const Text(
                              'À propos de moi',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // 4.2.2) Texte principal qui peut être tronqué ou non
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child:
                                    isExpanded
                                        ? SingleChildScrollView(
                                          key: const ValueKey('expanded'),
                                          child: Text(
                                            longDescription,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
                                              height: 1.4,
                                            ),
                                          ),
                                        )
                                        : Text(
                                          // Tronque à 3 lignes si pas expand
                                          longDescription,
                                          key: const ValueKey('collapsed'),
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                            height: 1.4,
                                          ),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // 4.2.3) Lien “More+” ou “Less-” qu’on peut cliquer
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  isExpanded = !isExpanded;
                                });
                              },
                              child: Text(
                                isExpanded ? 'Less -' : 'More +',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
