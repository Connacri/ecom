import 'package:ecom/activities/providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/AuthProvider.dart';
import '../fonctions/AppLocalizations.dart';
import '../pages/MyApp.dart';
import 'AddChildScreen.dart';
import 'data_populator.dart';
import 'modèles.dart';

class ParentHomePage extends StatefulWidget {
  final UserModel user;

  const ParentHomePage({Key? key, required this.user}) : super(key: key);

  @override
  _ParentHomePageState createState() => _ParentHomePageState();
}

class _ParentHomePageState extends State<ParentHomePage> {
  User? _user = FirebaseAuth.instance.currentUser;
  bool isSigningOut = false;
  bool isLoading = false;
  final AuthService _authService = AuthService();
  @override
  void initState() {
    super.initState();
    // Charge les enfants une seule fois au début
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChildProvider>(
        context,
        listen: false,
      ).loadChildren(widget.user.id);
    });
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
        // leading: CircleAvatar(
        //   backgroundImage: CachedNetworkImageProvider(widget.user.),
        // ),
        title: Text('NextGen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed:
                () => childProvider.loadChildren(
                  widget.user.id,
                  forceRefresh: true,
                ),
          ),
          IconButton(
            onPressed: () async {
              await DataPopulatorClaude().populateData();
            },
            icon: Icon(Icons.add_road, color: Colors.deepPurple),
          ),
          IconButton(
            onPressed:
                isLoading
                    ? null
                    : () async {
                      await _handleSignOut();
                      childProvider.clearCache();
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
          children: [
            Text(
              '${widget.user.role} '.toUpperCase() +
                  '${widget.user.name}'.toUpperCase(),
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            _buildBody(childProvider, widget.user),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddChild(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(ChildProvider provider, parent) {
    if (provider.isLoading && provider.children.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(child: Text(provider.error!));
    }

    if (provider.children.isEmpty) {
      return const Center(child: Text('Aucun enfant enregistré'));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        ...provider.children.map((child) {
          //final enrolledCourses =
          // courseProvider.courses
          //     .where(
          //       (course) =>
          //       child.enrolledCourses.contains(course.id),
          // )
          //  .toList();

          return SizedBox(
            width: MediaQuery.of(context).size.width / 2.4,
            height: 170,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onLongPress: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('Confirmer la suppression'),
                          content: const Text(
                            'Voulez-vous vraiment supprimer cet enfant ?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Annuler'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text(
                                'Supprimer',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                  );

                  if (confirmed == true) {
                    await context.read<ChildProvider>().deleteChild(
                      child.id,
                      parent,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Enfant supprimé avec succès'),
                      ),
                    );
                  }
                },
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 20,
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor:
                                  child.gender == 'male'
                                      ? Colors.blue.shade100
                                      : child.gender == 'female'
                                      ? Colors.pink.shade100
                                      : Colors.grey.shade300,
                              child: Icon(
                                child.gender == 'male'
                                    ? Icons.face
                                    : child.gender == 'female'
                                    ? Icons.face_3
                                    : Icons.account_box,
                                size: 30,
                                color:
                                    child.gender == 'male'
                                        ? Colors.blue
                                        : child.gender == 'female'
                                        ? Colors.pink
                                        : Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              child.name,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '(${child.age} ans)',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const Spacer(),
                            // if (enrolledCourses.isNotEmpty)
                            //   ...enrolledCourses.map(
                            //         (course) => Padding(
                            //       padding: const EdgeInsets.only(
                            //         top: 4.0,
                            //       ),
                            //       child: Column(
                            //         crossAxisAlignment:
                            //         CrossAxisAlignment.start,
                            //         children: [
                            //           Text(
                            //             course.name,
                            //             style:
                            //             Theme.of(
                            //               context,
                            //             ).textTheme.bodyMedium,
                            //           ),
                            //           // Text(
                            //           //   course.schedules.toString(),
                            //           //   style:
                            //           //       Theme.of(
                            //           //         context,
                            //           //       ).textTheme.bodySmall,
                            //           // ),
                            //         ],
                            //       ),
                            //     ),
                            //   ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 0,
                      child: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        tooltip: 'Actions',
                        onSelected: (value) async {
                          if (value == 'edit') {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => AddChildScreen(
                                      parent: parent,
                                      child: child,
                                    ),
                              ),
                            );
                          } else if (value == 'delete') {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: const Text(
                                      'Confirmer la suppression',
                                    ),
                                    content: const Text(
                                      'Voulez-vous vraiment supprimer cet enfant ?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.of(
                                              context,
                                            ).pop(false),
                                        child: const Text('Annuler'),
                                      ),
                                      TextButton(
                                        onPressed:
                                            () =>
                                                Navigator.of(context).pop(true),
                                        child: const Text(
                                          'Supprimer',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                            );

                            if (confirmed == true) {
                              await context.read<ChildProvider>().deleteChild(
                                child.id,
                                parent,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Enfant supprimé avec succès'),
                                ),
                              );
                            }
                          }
                        },
                        itemBuilder:
                            (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: ListTile(
                                  leading: Icon(Icons.edit),
                                  title: Text('Modifier'),
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  leading: Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  title: Text(
                                    'Supprimer',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ),
                            ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Future<void> _navigateToAddChild(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddChildScreen(parent: widget.user),
      ),
    );

    // Seulement rafraîchir si un nouvel enfant a été ajouté
    if (result == true) {
      Provider.of<ChildProvider>(
        context,
        listen: false,
      ).loadChildren(widget.user.id, forceRefresh: true);
    }
  }
}
