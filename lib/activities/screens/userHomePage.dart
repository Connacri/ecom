import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom/activities/generated/profile3.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart' as osm;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:open_location_picker/open_location_picker.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../auth/AuthProvider.dart';
import '../../auth/google.dart';
import '../../fonctions/DeleteUserButton.dart';
import '../../pages/MyApp.dart';
import '../ParentsScreen.dart';
import '../aGeo/map/LocationAppExample.dart';
import '../add/addCourseProgress.dart';
import '../add/addCoursesNew.dart';
import '../binance.dart';
import '../edition/EditClubScreen.dart';
import '../generated/multiphoto/PhotoUploadPage.dart';
import '../generated/profile1.dart';
import '../generated/profile2.dart';
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
  String? roleChoice;
  bool isSigningOut = false;
  bool isLoading = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _isMounted = true;
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  Future<void> _handleSignOut() async {
    if (!mounted) return; // Vérifier si le widget est toujours monté

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
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('userModel')
              .doc(_user!.uid)
              .snapshots(),
      builder: (context, userSnapshot) {
        // Afficher un indicateur de chargement pendant la connexion
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // Gérer les erreurs
        if (userSnapshot.hasError) {
          return _buildErrorScreen(
            userSnapshot.error.toString(),
            onRetry: () {
              // Logique de réessai si nécessaire
            },
          );
        }

        // Vérifier si les données existent
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Profil utilisateur non trouvé'),
                  SizedBox(height: 50),
                  IconButton(
                    onPressed: () async {
                      await _handleSignOut();
                    },
                    icon: Icon(Icons.logout),
                  ),
                ],
              ),
            ),
          );
        }

        // Extraire les données utilisateur
        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final userModel = UserModel.fromMap(userData, userSnapshot.data!.id);
        final roleBool = lesRoles.contains(userModel.role.toLowerCase());
        print(
          'roleBool =======================${userModel.role} ======> $roleBool',
        );
        // Gérer les rôles non reconnus
        if (!lesRoles.contains(userModel.role.toLowerCase())) {
          return Scaffold(
            appBar: AppBar(
              actions: [
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
                DeleteAccountButton(),
              ],
            ),
            body: Center(
              child: Column(
                children: [
                  Spacer(),
                  Text('Rôle non reconnu: ${userModel.role}'),
                  SizedBox(height: 50),
                  RoleSelectionDropdown(
                    onRoleSelected: (role) {
                      if (mounted) {
                        // setState(() {
                        roleChoice = role;
                        //     });
                      }
                    },
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final docRef = FirebaseFirestore.instance
                          .collection('userModel')
                          .doc(userModel.id);

                      await docRef
                          .set({
                            'editedAt': FieldValue.serverTimestamp(),
                            'role': roleChoice,
                          }, SetOptions(merge: true))
                          .then((value) async {
                            // Recharger les données de l'utilisateur après la mise à jour du rôle
                            final userProvider = Provider.of<UserProvider>(
                              context,
                              listen: false,
                            );
                            await userProvider.loadCurrentUser(userModel.id);

                            // Naviguer vers HomePage après la mise à jour
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (ctx) => HomePage()),
                            );
                          });
                    },
                    child: Text('Valider'),
                  ),
                  SizedBox(height: 50),
                  Spacer(),
                ],
              ),
            ),
          );
        }

        // Rediriger en fonction du rôle
        switch (userModel.role.toLowerCase()) {
          case 'parent':
          case 'grand-parent':
          case 'oncle/tante':
          case 'frère/sœur':
          case 'famille d’accueil':
            return ParentHomePage();
            Scaffold(
              appBar: AppBar(
                actions: [
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
                  DeleteAccountButton(),
                ],
              ),
              body: Center(
                child: Text(
                  'name: ' + userModel.name + 'role: ' + userModel.role,
                ),
              ),
            );
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
            return ProfHomePage();
            Scaffold(
              appBar: AppBar(
                actions: [
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
                  DeleteAccountButton(),
                ],
              ),
              body: Center(
                child: Text(
                  'name: ' + userModel.name + 'role: ' + userModel.role,
                ),
              ),
            );
          case 'club':
          case 'association':
          case 'ecole':
            return _ClubHomePage();
            Scaffold(
              appBar: AppBar(
                actions: [
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
                  DeleteAccountButton(),
                ],
              ),
              body: Center(
                child: Text(
                  'name: ' + userModel.name + 'role: ' + userModel.role,
                ),
              ),
            );
          case 'autre':
          default:
            return _UnknownRolePage();
            Scaffold(
              appBar: AppBar(
                actions: [
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
                  DeleteAccountButton(),
                ],
              ),
              body: Center(
                child: Text(
                  'name: ' + userModel.name + 'role: ' + userModel.role,
                ),
              ),
            );
        }
      },
    );
  }

  Widget _buildErrorScreen(String error, {VoidCallback? onRetry}) {
    return Scaffold(
      appBar: AppBar(
        actions: [
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
          DeleteAccountButton(),
        ],
      ),
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
}

class _ClubHomePage extends StatefulWidget {
  // final UserModel user;
  //
  // const _ClubHomePage({required this.user});

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
  ValueNotifier<osm.GeoPoint?> notifier = ValueNotifier(null);
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
              .where('clubId', isEqualTo: _user!.uid)
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
      ).pushReplacement(MaterialPageRoute(builder: (ctx) => MyApp1()));
      setState(() {
        _user = null;
      });
    } catch (e) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text(AppLocalizations.of(context).translate('connexErreur')),
      //   ),
      // );
    } finally {
      setState(() => isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    final childProvider = Provider.of<ChildProvider>(context);

    return user == null
        ? Center(child: CircularProgressIndicator())
        //CustomShimmerEffect()
        : Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(
              'Hello ${user.name}',
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
                      builder: (context) => EditClubScreen(club: user),
                    ),
                  );
                  // Optionally refresh data after editing
                  _fetchCourses();
                },
              ),
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
              DeleteAccountButton(),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,

                        backgroundImage:
                            user.logoUrl != null
                                ? CachedNetworkImageProvider(user.logoUrl!)
                                : AssetImage('assets/default_logo.png')
                                    as ImageProvider,
                      ),
                      SizedBox(height: 10),
                      Text(
                        '${user.role} : ${user.name}'.toUpperCase(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        'Email: ${user.email}',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 10),
                      user.phone == null || user.phone == ''
                          ? SizedBox.shrink()
                          : Text(
                            'Téléphone: ${user.phone ?? "Non spécifié"}',
                            style: TextStyle(fontSize: 16),
                          ),
                      SizedBox(height: 10),
                      // if (user.logoUrl != null)
                      //   Image.network(
                      //     user.logoUrl!,
                      //     height: 100,
                      //     fit: BoxFit.cover,
                      //   ),
                      // SizedBox(height: 10),
                      if (user.photos != null && user.photos!.isNotEmpty)
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: user.photos!.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: EdgeInsets.only(right: 8.0),
                                child: Image.network(
                                  user.photos![index],
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              );
                            },
                          ),
                        ),
                      SizedBox(height: 20),
                      // ElevatedButton.icon(
                      //   icon: Icon(Icons.add),
                      //   label: Text('Ajouter un Cours'),
                      //   onPressed: () async {
                      //     await Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //         builder: (context) => AddCourseScreen(user: user),
                      //       ),
                      //     );
                      //     _fetchCourses(); // Refresh the list of courses after adding a new one
                      //   },
                      //   style: ElevatedButton.styleFrom(
                      //     padding: EdgeInsets.symmetric(
                      //       horizontal: 20,
                      //       vertical: 10,
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed:
                      () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CheckoutScreen(user: user),
                        ),
                      ),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('CheckoutScreen'),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => StepperDemo()),
                    );
                  },
                  icon: Icon(Icons.add_circle_outline_rounded),
                ),
                SizedBox(height: 20),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => BinancePage()),
                    );
                  },
                  icon: Icon(FontAwesomeIcons.dollar),
                ),
                SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed:
                      () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => PhotoUploadPage()),
                      ),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Choisir & Uploader'),
                ),
                // SizedBox(height: 20),
                // ElevatedButton.icon(
                //   onPressed:
                //       () => Navigator.of(context).push(
                //         MaterialPageRoute(
                //           builder: (_) => AddCourseScreen2(user: user),
                //         ),
                //       ),
                //   icon: const Icon(Icons.upload_file),
                //   label: const Text('AddCourseScreen2'),
                // ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // ElevatedButton.icon(
                    //   onPressed:
                    //       () => Navigator.of(context).push(
                    //         MaterialPageRoute(
                    //           builder: (_) => LocationStepperPage(),
                    //         ),
                    //       ),
                    //   icon: const Icon(Icons.location_history),
                    //   label: const Text('Location Page'),
                    // ),
                  ],
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('Lieu'),
                      notifier.value == null
                          ? Container()
                          : Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ValueListenableBuilder<osm.GeoPoint?>(
                              valueListenable: notifier,
                              builder: (ctx, px, child) {
                                return FutureBuilder<String>(
                                  future: getAddressFromLatLng(
                                    px!.latitude,
                                    px.longitude,
                                  ),
                                  builder: (
                                    BuildContext context,
                                    AsyncSnapshot<String> snapshot,
                                  ) {
                                    if (snapshot.hasData) {
                                      return Text(snapshot.data!);
                                    } else if (snapshot.hasError) {
                                      return Text('Erreur: ${snapshot.error}');
                                    } else {
                                      return CircularProgressIndicator();
                                    }
                                  },
                                );

                                //   Center(
                                //   child: Text(
                                //     "${px?.latitude.toString()} - ${px?.longitude.toString()}" ??
                                //         '',
                                //     textAlign: TextAlign.center,
                                //   ),
                                // );
                              },
                            ),
                          ),
                      // ValueListenableBuilder<GeoPoint?>(
                      //   valueListenable: notifier,
                      //   builder: (ctx, p, child) {
                      //     return Center(
                      //       child: Text(
                      //         "${p?.toString() ?? ""}",
                      //         textAlign: TextAlign.center,
                      //       ),
                      //     );
                      //   },
                      // ),
                      IconButton(
                        onPressed: () async {
                          var p = await Navigator.of(context).push(
                            MaterialPageRoute(builder: (ctx) => SearchPage()),
                          );
                          print(
                            'ppppppppppppppppppppppppppppppppppppppppppppppppppp',
                          );
                          print(p);
                          if (p != null) {
                            setState(() => notifier.value = p);
                          }
                        },
                        icon: Icon(Icons.location_searching),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Spacer(),
                    ElevatedButton(
                      onPressed:
                          () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => ProfHomePage()),
                          ),
                      child: Text('Profile1'),
                    ),
                    Spacer(),
                    ElevatedButton(
                      onPressed:
                          () => Navigator.of(
                            context,
                          ).push(MaterialPageRoute(builder: (_) => Profile2())),
                      child: Text('Profile2'),
                    ),
                    Spacer(),
                    ElevatedButton(
                      onPressed:
                          () => Navigator.of(
                            context,
                          ).push(MaterialPageRoute(builder: (_) => Profile3())),
                      child: Text('Profile2'),
                    ),
                    Spacer(),
                  ],
                ),
                SizedBox(height: 20),
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
                        _courses.sort(
                          (a, b) => b.createdAt!.compareTo(a.createdAt!),
                        );

                        final course = _courses[index];
                        final pricesMap = course.pricesByCotisationType ?? {};
                        return Card(
                          margin: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      course.name.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Icon(Icons.people),
                                    SizedBox(width: 5),
                                    Text(course.placeNumber.toString()),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.edit,
                                            color: Colors.blue,
                                          ),
                                          onPressed: () {},
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
                                buildPricesSection(course),

                                SizedBox(height: 8),
                                // Display up to 3 images
                                if (course.photos!.isNotEmpty)
                                  SizedBox(
                                    height: 100,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: course.photos!.length,
                                      // > 3
                                      // ? 3
                                      // : course.photos!.length
                                      itemBuilder: (context, index) {
                                        return Padding(
                                          padding: EdgeInsets.only(right: 8.0),
                                          child: CachedNetworkImage(
                                            imageUrl: course.photos![index],
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
                                course.saisonStart == null ||
                                        course.saisonStart == null
                                    ? SizedBox.shrink()
                                    : Text(
                                      'Saison:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                course.saisonStart == null ||
                                        course.saisonStart == null
                                    ? SizedBox.shrink()
                                    : SizedBox(height: 8),
                                course.saisonStart == null ||
                                        course.saisonStart == null
                                    ? SizedBox.shrink()
                                    : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Début de Saison\n' +
                                              DateFormat(
                                                'yyyy-MM-dd',
                                              ).format(course.saisonStart!),
                                          textAlign: TextAlign.center,
                                        ),

                                        Text(
                                          'Fin de Saison\n' +
                                              DateFormat(
                                                'yyyy-MM-dd',
                                              ).format(course.saisonStart!),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                SizedBox(height: 8),
                                Container(
                                  child:
                                      course.location == null
                                          ? null
                                          : SizedBox(
                                            height: 200,

                                            child: Stack(
                                              children: [
                                                //Text(LatLng(datam!['position'].latitude,datam!['position'].longitude).toString(),)
                                                FlutterMap(
                                                  options: MapOptions(
                                                    center: LatLng(
                                                      // 'center' au lieu de 'initialCenter'
                                                      course.location!.latitude,
                                                      course
                                                          .location!
                                                          .longitude,
                                                    ),
                                                    zoom:
                                                        16.0, // 'zoom' au lieu de 'initialZoom'
                                                  ),
                                                  children: [
                                                    TileLayer(
                                                      urlTemplate:
                                                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                                      subdomains: [
                                                        'a',
                                                        'b',
                                                        'c',
                                                      ],
                                                      minZoom: 1,
                                                      maxZoom: 18,
                                                      backgroundColor:
                                                          Colors.black,
                                                    ),
                                                    MarkerLayer(
                                                      markers: [
                                                        Marker(
                                                          width:
                                                              40, // Taille réduite pour correspondre à l'icône
                                                          height: 40,
                                                          point: LatLng(
                                                            course
                                                                .location!
                                                                .latitude,
                                                            course
                                                                .location!
                                                                .longitude,
                                                          ),
                                                          builder:
                                                              (
                                                                context,
                                                              ) => const Icon(
                                                                Icons
                                                                    .location_on,
                                                                color:
                                                                    Colors.red,
                                                                size: 40,
                                                              ),
                                                          // Le builder est inutile ici car on utilise 'child'
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                ),
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
                                        SizedBox(width: 5),
                                        Text(
                                          '${schedule.startTime.hour}:${schedule.startTime.minute.toString().padLeft(2, '0')} - ${schedule.endTime.hour}:${schedule.endTime.minute.toString().padLeft(2, '0')}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),

                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${schedule.days.join(", ")}',
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
                                            CircleAvatar(
                                              backgroundImage:
                                                  CachedNetworkImageProvider(
                                                    prof.logoUrl!,
                                                  ),
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

                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                  ),
                                  child: Text(
                                    timeago.format(
                                      course.createdAt!,
                                      locale: 'fr',
                                    ),
                                    textAlign: TextAlign.start,
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontWeight: FontWeight.normal,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
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

  Future<String> getAddressFromLatLng(double lat, double lng) async {
    final List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

    if (placemarks.isNotEmpty) {
      final Placemark place = placemarks.first;
      return "${place.locality}, ${place.country}"; //${place.street}, ${place.postalCode},
    }

    return "";
  }

  Widget buildPricesSection(Course course) {
    final pricesMap = course.pricesByCotisationType ?? {};

    if (pricesMap.isEmpty) {
      return const Text('Aucun tarif défini.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tarifs selon cotisation :',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...pricesMap.entries.map((entry) {
          final type = entry.key;
          final price = entry.value;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _cotisationLabel(type),
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  '${price.toStringAsFixed(2)} DA',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  String _cotisationLabel(String key) {
    switch (key) {
      case 'annuel':
        return 'Annuel';
      case 'mensuel':
        return 'Mensuel';
      case 'seance':
        return 'Par séance';
      default:
        return key[0].toUpperCase() + key.substring(1);
    }
  }
}

class CustomShimmerEffect extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: kToolbarHeight, // Hauteur de l'AppBar
                    // color: Colors.white,
                  ),
                  SizedBox(height: 10),
                  Container(width: 100, height: 100, color: Colors.white),
                  SizedBox(height: 10),
                  Container(width: 200, height: 24, color: Colors.white),
                  SizedBox(height: 10),
                  Container(width: 150, height: 20, color: Colors.white),
                  SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    height: 20,
                    color: Colors.white,
                  ),
                  SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    height: 20,
                    color: Colors.white,
                  ),
                  SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    height: 20,
                    color: Colors.white,
                  ),
                  SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    height: 100,
                    color: Colors.white,
                  ),
                  SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    height: 50,
                    color: Colors.white,
                  ),
                  SizedBox(height: 20),
                  // Ajoutez d'autres conteneurs pour simuler les cours
                  Container(
                    width: double.infinity,
                    height: 200,
                    color: Colors.white,
                  ),
                  SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    height: 200,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Page pour les rôles non reconnus
class _UnknownRolePage extends StatefulWidget {
  // final UserModel user;
  //
  // const _UnknownRolePage({required this.user});

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
      ).pushReplacement(MaterialPageRoute(builder: (ctx) => MyApp1()));
      setState(() {
        _user = null;
      });
    } catch (e) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text(AppLocalizations.of(context).translate('connexErreur')),
      //   ),
      // );
    } finally {
      setState(() => isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final childProvider = Provider.of<ChildProvider>(context);
    final user = Provider.of<UserProvider>(context).user;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChildProvider>(
        context,
        listen: false,
      ).loadChildren(_user!.uid);
    });
    return user == null
        ? CustomShimmerEffect()
        : Scaffold(
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
              DeleteAccountButton(),
            ],
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning, size: 50, color: Colors.orange),
                const SizedBox(height: 20),
                Text(
                  'Rôle "${user.role}" non pris en charge',
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
