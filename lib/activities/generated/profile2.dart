import 'package:flutter/material.dart';

class Profile2 extends StatelessWidget {
  const Profile2({super.key});

  @override
  Widget build(BuildContext context) {
    // Taille de l’écran pour ajuster certains éléments
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    // Couleurs de dégradé : du transparent en haut vers un rouge/orange en bas
    const Color gradientStart = Colors.transparent;
    const Color gradientEnd = Color(
      0xFFFE4164,
    ); // un rose-rouge vif (à ajuster)

    // Liste des miniatures (chemins d’assets)
    final List<String> thumbs = [
      'assets/photos/a (2).png',
      'assets/photos/a (4).png',
      'assets/photos/a (5).png',
      'assets/photos/a (6).png',
      // Ajoutez d’autres miniatures si besoin
    ];

    return Scaffold(
      // Pas d'AppBar, on gère tout dans le body via Stack
      body: Stack(
        children: [
          // 1) Image de fond plein écran
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Image.asset('assets/photos/a (11).png', fit: BoxFit.cover),
          ),

          // 2) Overlay dégradé (transparent en haut → couleur chaude en bas)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [gradientStart, gradientEnd],
              ),
            ),
          ),

          // 3) Contenu principal (back button + titre + texte + miniatures)
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // 3.1) Back arrow + titre "Candidates"
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Candidates',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(), // pousse tout vers le haut ; le bas sera occupé par les textes et miniatures.
                // 3.2) Section “Nom, âge, lieu”
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'NATASHA KORGEEVA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '23 years, Lisbon, Portugal',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'I’m a Digital Marketing Manager working in Lisbon. '
                        'I like to go out for drinks and fun, cinema, travel and beach :)',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 3.3) Rangée de miniatures circulaires
                SizedBox(
                  height: 70, // hauteur pour les avatars + padding
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: thumbs.length,
                    separatorBuilder:
                        (context, index) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      return Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white70, width: 2),
                          image: DecorationImage(
                            image: AssetImage(thumbs[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
