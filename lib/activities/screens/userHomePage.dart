import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/AuthProvider.dart';
import '../../fonctions/AppLocalizations.dart';
import '../../pages/MyApp.dart';
import '../AddCourseScreen.dart';
import '../ParentsScreen.dart';
import '../edition/EditClubScreen.dart';
import '../modèles.dart';
import '../providers.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User? _user = FirebaseAuth.instance.currentUser;
  bool _isMounted = false;
  @override
  void initState() {
    super.initState();
    _isMounted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Charge l'utilisateur et les enfants si parent
      if (_isMounted) {
        _loadInitialData();
      }
    });
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser!.uid;
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.loadCurrentUser(currentUser);

      if (_isMounted &&
          userProvider.user != null &&
          userProvider.user!.role.toLowerCase() == 'parent') {
        final childProvider = Provider.of<ChildProvider>(
          context,
          listen: false,
        );
        await childProvider.loadChildren(currentUser);
      }
    } catch (e) {
      if (_isMounted) {
        // Gérer l'erreur si nécessaire
        debugPrint('Erreur lors du chargement initial: $e');
      }
    }
  }

  Future<void> _retryLoading() async {
    if (_isMounted) {
      await _loadInitialData();
    }
  }

  bool isSigningOut = false;
  bool isLoading = false;
  final AuthService _authService = AuthService();
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final childProvider = Provider.of<ChildProvider>(context);

    // Gestion des états globaux
    if (userProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (userProvider.error != null) {
      return _buildErrorScreen(userProvider.error!, onRetry: _retryLoading);
    }

    if (userProvider.user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = userProvider.user!;

    // Gestion spécifique pour les parents (chargement des enfants)
    if (user.role.toLowerCase() == 'parent') {
      if (childProvider.isLoading) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      if (childProvider.error != null) {
        return _buildErrorScreen(
          childProvider.error!,
          onRetry:
              () => childProvider.loadChildren(user.id, forceRefresh: true),
        );
      }
    }

    // Redirection en fonction du rôle
    switch (user.role.toLowerCase()) {
      // Rôles parentaux et familiaux
      case 'parent':
      case 'grand-parent':
      case 'oncle/tante':
      case 'frère/sœur':
      case 'famille d’accueil':
        return ParentHomePage(user: user);

      // Rôles éducatifs et enseignants
      case 'professeur':
      case 'prof':
      case 'enseignant suppléant':
      case 'conseiller pédagogique':
      case 'éducateur':
      case 'formateur':
      case 'coach':
      case 'animateur':
      case 'moniteur':
      case 'intervenant extérieur':
      case 'médiateur':
      case 'tuteur':
        return _ProfHomePage(
          user: user,
        ); // Ou un autre page spécifique si nécessaire

      // Structures organisationnelles
      case 'club':
      case 'association':
      case 'ecole':
        return _ClubHomePage(user: user);

      // Rôle par défaut
      case 'autre':
      default:
        return _UnknownRolePage(user: user);
    }
  }

  Widget _buildErrorScreen(String error, {VoidCallback? onRetry}) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Erreur: $error'),
            const SizedBox(height: 20),
            if (onRetry != null)
              Column(
                children: [
                  IconButton(
                    onPressed: isLoading ? null : _handleSignOut,
                    icon:
                        isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.logout),
                    tooltip: 'Logout',
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: onRetry,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // Logout handler with confirmation dialog
  Future<void> _handleSignOut() async {
    setState(() => isSigningOut = true);

    try {
      // On attend que les deux futures se terminent : la déconnexion + le délai
      await Future.wait([
        _authService.signOut(),
        Future.delayed(const Duration(seconds: 2)), // 👈 délai imposé
      ]);
      if (_isMounted) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (ctx) => MyApp()));
      }
      setState(() {
        _user = null;
      });
    } catch (e) {
      print('Erreur déconnexion: $e');
      if (_isMounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).translate('connexErreur'),
            ),
          ),
        );
      }
    } finally {
      setState(() => isSigningOut = false);
    }
  }
}

class _ProfHomePage extends StatefulWidget {
  final UserModel user;

  const _ProfHomePage({required this.user});

  @override
  State<_ProfHomePage> createState() => _ProfHomePageState();
}

class _ProfHomePageState extends State<_ProfHomePage> {
  User? _user = FirebaseAuth.instance.currentUser;
  bool isSigningOut = false;
  bool isLoading = false;
  final AuthService _authService = AuthService();
  Future<void> _handleSignOut() async {
    setState(() => isSigningOut = true);

    try {
      // On attend que les deux futures se terminent : la déconnexion + le délai

      await Future.wait([
        _authService.signOut(),
        Future.delayed(const Duration(seconds: 2)), // 👈 délai imposé
      ]);
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (ctx) => MyApp()));
      setState(() {
        _user = null;
      });
    } catch (e) {
      print('Erreur déconnexion: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).translate('connexErreur')),
        ),
      );
    } finally {
      setState(() => isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final childProvider = Provider.of<ChildProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Bienvenue ${widget.user.name}'),
        actions: [
          IconButton(
            onPressed:
                isLoading
                    ? null
                    : () async {
                      childProvider.clearCache();
                      await _handleSignOut();
                    },
            icon:
                isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school, size: 50),
            const SizedBox(height: 20),
            Text(
              'Interface Professeur',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text('Rôle: ${widget.user.role}'),
            const SizedBox(height: 20),
            // ElevatedButton(
            //   onPressed: () async {
            //     await Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder: (context) => AddCourseScreen(club: user),
            //       ),
            //     );
            //   },
            //   child: Text('Ajouter un Cour'),
            // ),
          ],
        ),
      ),
    );
  }
}

class _ClubHomePage extends StatefulWidget {
  final UserModel user;

  const _ClubHomePage({required this.user});

  @override
  _ClubHomePageState createState() => _ClubHomePageState();
}

class _ClubHomePageState extends State<_ClubHomePage> {
  List<Course> _courses = [];
  bool _isLoading = true;
  User? _user = FirebaseAuth.instance.currentUser;
  bool isSigningOut = false;
  bool isLoading = false;
  final AuthService _authService = AuthService();
  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('courses')
              .where('clubId', isEqualTo: widget.user.id)
              .get();

      final courses =
          querySnapshot.docs.map((doc) {
            final data = doc.data();
            return Course.fromMap(data, doc.id);
          }).toList();

      setState(() {
        _courses = courses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur lors de la récupération des cours: ${e.toString()}',
          ),
        ),
      );
    }
  }

  // Logout handler with confirmation dialog
  Future<void> _handleSignOut() async {
    setState(() => isSigningOut = true);

    try {
      // On attend que les deux futures se terminent : la déconnexion + le délai

      await Future.wait([
        _authService.signOut(),
        Future.delayed(const Duration(seconds: 2)), // 👈 délai imposé
      ]);
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (ctx) => MyApp()));
      setState(() {
        _user = null;
      });
    } catch (e) {
      print('Erreur déconnexion: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).translate('connexErreur')),
        ),
      );
    } finally {
      setState(() => isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final childProvider = Provider.of<ChildProvider>(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Hello ${widget.user.name}',
          // style: TextStyle(color: Colors.white),
        ),
        //backgroundColor: Colors.blueAccent,
        elevation: 0,
        //  iconTheme: IconThemeData(color: Colors.white),
        // actions: [
        //   IconButton(icon: Icon(Icons.refresh), onPressed: _fetchCourses),
        //   IconButton(
        //     onPressed:
        //         isLoading
        //             ? null
        //             : () async {
        //               childProvider.clearCache();
        //               await _handleSignOut();
        //             },
        //     icon:
        //         isLoading
        //             ? const SizedBox(
        //               width: 20,
        //               height: 20,
        //               child: CircularProgressIndicator(strokeWidth: 2),
        //             )
        //             : const Icon(Icons.logout),
        //     tooltip: 'Logout',
        //   ),
        // ],
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _fetchCourses),
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditClubScreen(club: widget.user),
                ),
              );
              // Optionally refresh data after editing
              _fetchCourses();
            },
          ),
          IconButton(
            onPressed:
                isLoading
                    ? null
                    : () async {
                      childProvider.clearCache();
                      await _handleSignOut();
                    },
            icon:
                isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(Icons.sports_soccer, size: 50),
                  SizedBox(height: 10),
                  Text(
                    'Interface Club',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.grey[700]),
                  ),
                  Text(
                    'Rôle: ${widget.user.role}',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 20),
                  // Display Club Details
                  Text(
                    'Nom: ${widget.user.name}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Email: ${widget.user.email}',
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Téléphone: ${widget.user.phone ?? "Non spécifié"}',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 10),
                  if (widget.user.logoUrl != null)
                    Image.network(
                      widget.user.logoUrl!,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  SizedBox(height: 10),
                  if (widget.user.photos != null &&
                      widget.user.photos!.isNotEmpty)
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.user.photos!.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.only(right: 8.0),
                            child: Image.network(
                              widget.user.photos![index],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      ),
                    ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: Icon(Icons.add),
                    label: Text('Ajouter un Cours'),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => AddCourseScreen(user: widget.user),
                        ),
                      );
                      _fetchCourses(); // Refresh the list of courses after adding a new one
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Rest of your existing code for displaying courses
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : _courses.isEmpty
                ? Center(
                  child: Text(
                    'Aucun cours trouvé',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
                : ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _courses.length,
                  itemBuilder: (context, index) {
                    final course = _courses[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 3,
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  course.name.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      onPressed: () => _editCourse(course),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: Text(
                                                'Confirmer la suppression',
                                              ),
                                              content: Text(
                                                'Êtes-vous sûr de vouloir supprimer ce cours?',
                                              ),
                                              actions: <Widget>[
                                                TextButton(
                                                  child: Text('Annuler'),
                                                  onPressed: () {
                                                    Navigator.of(
                                                      context,
                                                    ).pop(); // Close the dialog
                                                  },
                                                ),
                                                TextButton(
                                                  child: Text('Supprimer'),
                                                  onPressed: () {
                                                    Navigator.of(
                                                      context,
                                                    ).pop(); // Close the dialog
                                                    _deleteCourse(
                                                      course.id,
                                                    ); // Delete the course
                                                  },
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            // Display up to 3 images
                            if (course.photos!.isNotEmpty)
                              SizedBox(
                                height: 100,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount:
                                      course.photos!.length > 3
                                          ? 3
                                          : course.photos!.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: EdgeInsets.only(right: 8.0),
                                      child: Image.network(
                                        course.photos![index],
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            SizedBox(height: 8),
                            Text(
                              'Description: ${course.description}',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tranche d\'âge: ${course.ageRange}',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Horaires:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            ...course.schedules.map((schedule) {
                              return Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: 4.0,
                                  horizontal: 8.0,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${schedule.days.join(", ")}: ${schedule.startTime.hour}:${schedule.startTime.minute.toString().padLeft(2, '0')} - ${schedule.endTime.hour}:${schedule.endTime.minute.toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            SizedBox(height: 8),
                            Text(
                              'Professeurs:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            ...course.profIds.map((profId) {
                              return FutureBuilder<DocumentSnapshot>(
                                future:
                                    FirebaseFirestore.instance
                                        .collection('userModel')
                                        .doc(profId)
                                        .get(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 4.0,
                                        horizontal: 8.0,
                                      ),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1,
                                      ),
                                    );
                                  }
                                  if (snapshot.hasError) {
                                    return Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 4.0,
                                        horizontal: 8.0,
                                      ),
                                      child: Text(
                                        'Erreur: ${snapshot.error}',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    );
                                  }
                                  final profData =
                                      snapshot.data!.data()
                                          as Map<String, dynamic>;
                                  final prof = UserModel.fromMap(
                                    profData,
                                    snapshot.data!.id,
                                  );
                                  return Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 4.0,
                                      horizontal: 8.0,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.person,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          prof.name,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }

  void _editCourse(Course course) {
    // Navigate to a screen where the course can be edited
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditCourseScreen(course: course)),
    ).then((_) {
      // Refresh the list of courses after editing
      _fetchCourses();
    });
  }

  Future<void> _deleteCourse(String courseId) async {
    try {
      await FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .delete();
      // Refresh the list of courses after deletion
      _fetchCourses();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la suppression: ${e.toString()}'),
        ),
      );
    }
  }
}

// Page pour les rôles non reconnus
class _UnknownRolePage extends StatefulWidget {
  final UserModel user;

  const _UnknownRolePage({required this.user});

  @override
  State<_UnknownRolePage> createState() => _UnknownRolePageState();
}

class _UnknownRolePageState extends State<_UnknownRolePage> {
  bool isSigningOut = false;
  bool isLoading = false;
  final AuthService _authService = AuthService();
  User? _user = FirebaseAuth.instance.currentUser;
  Future<void> _handleSignOut() async {
    setState(() => isSigningOut = true);

    try {
      // On attend que les deux futures se terminent : la déconnexion + le délai

      await Future.wait([
        _authService.signOut(),
        Future.delayed(const Duration(seconds: 2)), // 👈 délai imposé
      ]);
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (ctx) => MyApp()));
      setState(() {
        _user = null;
      });
    } catch (e) {
      print('Erreur déconnexion: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).translate('connexErreur')),
        ),
      );
    } finally {
      setState(() => isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final childProvider = Provider.of<ChildProvider>(context);
    // Logout handler with confirmation dialog

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rôle non reconnu'),
        actions: [
          IconButton(
            onPressed:
                isLoading
                    ? null
                    : () async {
                      childProvider.clearCache();
                      await _handleSignOut();
                    },
            icon:
                isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning, size: 50, color: Colors.orange),
            const SizedBox(height: 20),
            Text(
              'Rôle "${widget.user.role}" non pris en charge',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Text(
              'Contactez le support',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
