import 'package:ecom/activities/providers.dart';
import 'package:ecom/activities/timelines.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'AddChildScreen.dart';
import 'modèles.dart';

class ParentProfileScreen extends StatelessWidget {
  final String parentId;

  const ParentProfileScreen({Key? key, required this.parentId})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer3<UserProvider, CourseProvider, ProfProvider>(
      builder: (context, userProvider, courseProvider, profProvider, child) {
        final parentWithChildren = userProvider.getParentWithChildrenById(
          parentId,
        );
        final currentUser = FirebaseAuth.instance.currentUser;
        if (parentWithChildren == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Profil de ${parentWithChildren.parent.name}'),
          ),
          body: StreamBuilder<List<Child>>(
            stream: Provider.of<ClubProvider>(context).childrenStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Erreur: ${snapshot.error}'));
              }

              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              final children =
                  snapshot.data!
                      .where((child) => child.parentId == parentId)
                      .toList();

              return Column(
                children: [
                  Text(parentId),
                  Text(currentUser!.uid),

                  SizedBox(
                    width: 200,
                    height: 50,
                    child: Row(
                      children: [
                        Spacer(),
                        ElevatedButton(
                          onPressed:
                              () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (ctx) => TimelineScreen(
                                        children: children,
                                        courses: courseProvider.courses,
                                        profProvider: profProvider,
                                      ),
                                ),
                              ),
                          child: Text('Timeline Screen'),
                        ),
                        Spacer(),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Consumer<UserProvider>(
                          builder: (context, userProvider, child) {
                            final parentWithChildren = userProvider
                                .getParentWithChildrenById(parentId);

                            if (parentWithChildren == null) {
                              return const SizedBox.shrink();
                            }

                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: RichText(
                                    text: TextSpan(
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.titleLarge,
                                      children: [
                                        const WidgetSpan(
                                          alignment:
                                              PlaceholderAlignment.middle,
                                          child: const Icon(
                                            Icons.person,
                                            size: 30,
                                          ),
                                        ),
                                        TextSpan(
                                          text:
                                              '${parentWithChildren.parent.name}   ',
                                        ),
                                        const WidgetSpan(
                                          alignment:
                                              PlaceholderAlignment.middle,
                                          child: Icon(Icons.face),
                                        ),
                                        TextSpan(
                                          text:
                                              ' ${parentWithChildren.children.length}',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                ...parentWithChildren.children.map((child) {
                                  final enrolledCourses =
                                      courseProvider.courses
                                          .where(
                                            (course) => child.enrolledCourses
                                                .contains(course.id),
                                          )
                                          .toList();

                                  return SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width / 2.4,
                                    height: 250,
                                    child: Card(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 4,
                                      clipBehavior: Clip.antiAlias,
                                      child: InkWell(
                                        onLongPress: () async {
                                          final confirmed = await showDialog<
                                            bool
                                          >(
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
                                                      child: const Text(
                                                        'Annuler',
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed:
                                                          () => Navigator.of(
                                                            context,
                                                          ).pop(true),
                                                      child: const Text(
                                                        'Supprimer',
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                          );

                                          if (confirmed == true) {
                                            await context
                                                .read<ClubProvider>()
                                                .deleteChild(child.id);
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Enfant supprimé avec succès',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        child: Stack(
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
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
                                                              ? Colors
                                                                  .blue
                                                                  .shade100
                                                              : child.gender ==
                                                                  'female'
                                                              ? Colors
                                                                  .pink
                                                                  .shade100
                                                              : Colors
                                                                  .grey
                                                                  .shade300,
                                                      child: Icon(
                                                        child.gender == 'male'
                                                            ? Icons.face
                                                            : child.gender ==
                                                                'female'
                                                            ? Icons.face_3
                                                            : Icons.account_box,
                                                        size: 30,
                                                        color:
                                                            child.gender ==
                                                                    'male'
                                                                ? Colors.blue
                                                                : child.gender ==
                                                                    'female'
                                                                ? Colors.pink
                                                                : Colors.grey,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      child.name,
                                                      textAlign:
                                                          TextAlign.center,
                                                      style:
                                                          Theme.of(context)
                                                              .textTheme
                                                              .titleMedium,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    Text(
                                                      '(${child.age} ans)',
                                                      style:
                                                          Theme.of(
                                                            context,
                                                          ).textTheme.bodySmall,
                                                    ),
                                                    const Spacer(),
                                                    if (enrolledCourses
                                                        .isNotEmpty)
                                                      ...enrolledCourses.map(
                                                        (course) => Padding(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                top: 4.0,
                                                              ),
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                course.name,
                                                                style:
                                                                    Theme.of(
                                                                          context,
                                                                        )
                                                                        .textTheme
                                                                        .bodyMedium,
                                                              ),
                                                              // Text(
                                                              //   course.schedules.toString(),
                                                              //   style:
                                                              //       Theme.of(
                                                              //         context,
                                                              //       ).textTheme.bodySmall,
                                                              // ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              top: 4,
                                              right: 0,
                                              child: PopupMenuButton<String>(
                                                icon: const Icon(
                                                  Icons.more_vert,
                                                ),
                                                tooltip: 'Actions',
                                                onSelected: (value) async {
                                                  if (value == 'edit') {
                                                    await Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder:
                                                            (
                                                              context,
                                                            ) => AddChildScreen(
                                                              parent:
                                                                  parentWithChildren
                                                                      .parent,
                                                              child: child,
                                                            ),
                                                      ),
                                                    );
                                                  } else if (value ==
                                                      'delete') {
                                                    final confirmed = await showDialog<
                                                      bool
                                                    >(
                                                      context: context,
                                                      builder:
                                                          (
                                                            context,
                                                          ) => AlertDialog(
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
                                                                    ).pop(
                                                                      false,
                                                                    ),
                                                                child:
                                                                    const Text(
                                                                      'Annuler',
                                                                    ),
                                                              ),
                                                              TextButton(
                                                                onPressed:
                                                                    () => Navigator.of(
                                                                      context,
                                                                    ).pop(true),
                                                                child: const Text(
                                                                  'Supprimer',
                                                                  style: TextStyle(
                                                                    color:
                                                                        Colors
                                                                            .red,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                    );

                                                    if (confirmed == true) {
                                                      await context
                                                          .read<ClubProvider>()
                                                          .deleteChild(
                                                            child.id,
                                                          );
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            'Enfant supprimé avec succès',
                                                          ),
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
                                                          leading: Icon(
                                                            Icons.edit,
                                                          ),
                                                          title: Text(
                                                            'Modifier',
                                                          ),
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
                                                            style: TextStyle(
                                                              color: Colors.red,
                                                            ),
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
                          },
                        ),
                      ),
                    ),
                  ),
                  // Expanded(child: _buildChildrenList(context, children)),
                ],
              );
            },
          ),

          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          AddChildScreen(parent: parentWithChildren.parent),
                ),
              );
            },
            heroTag: 'addChild',
            child: const Icon(Icons.person_add),
          ),
        );
      },
    );
  }

  Widget _buildChildrenList(BuildContext context, List<Child> children) {
    final courseProvider = Provider.of<CourseProvider>(context);

    return ListView.builder(
      itemCount: children.length,
      itemBuilder: (context, index) {
        final child = children[index];
        final courses =
            courseProvider.courses
                .where((c) => child.enrolledCourses.contains(c.id))
                .toList();

        return _buildChildCard(context, child, courses);
      },
    );
  }

  Widget _buildChildCard(
    BuildContext context,
    Child child,
    List<Course> enrolledCourses,
  ) {
    final clubProvider = Provider.of<ClubProvider>(context, listen: false);
    final courseProvider = Provider.of<CourseProvider>(context);

    Future<void> _unenrollFromCourse(String courseId) async {
      try {
        // Crée une nouvelle liste sans le cours à supprimer
        final updatedCourses = List<String>.from(child.enrolledCourses)
          ..remove(courseId);

        // Crée un nouvel objet Child avec les cours mis à jour
        final updatedChild = Child(
          id: child.id,
          name: child.name,
          age: child.age,
          enrolledCourses: updatedCourses,
          parentId: child.parentId,
          gender: child.gender,
        );

        await clubProvider.updateChild(updatedChild);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Désinscription réussie')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
      }
    }

    return InkWell(
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
          await clubProvider.deleteChild(child.id);
        }
      },
      child: SizedBox(
        width: MediaQuery.of(context).size.width / 2.4,
        height: 650,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Expanded(
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
                                onPressed:
                                    () => Navigator.of(context).pop(false),
                                child: const Text('Annuler'),
                              ),
                              TextButton(
                                onPressed:
                                    () => Navigator.of(context).pop(true),
                                child: const Text(
                                  'Supprimer',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                    );

                    if (confirmed == true) {
                      await context.read<ClubProvider>().deleteChild(child.id);
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
                              if (enrolledCourses.isNotEmpty)
                                ...enrolledCourses.map(
                                  (course) => Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          course.name,
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodyMedium,
                                        ),
                                        // Iterate over each schedule in the course's schedules list
                                        ...course.schedules
                                            .map(
                                              (schedule) => Text(
                                                '${schedule.days.join(", ")}: ${schedule.startTime.hour}:${schedule.startTime.minute.toString().padLeft(2, '0')} - ${schedule.endTime.hour}:${schedule.endTime.minute.toString().padLeft(2, '0')}',
                                                style:
                                                    Theme.of(
                                                      context,
                                                    ).textTheme.bodySmall,
                                              ),
                                            )
                                            .toList(),
                                      ],
                                    ),
                                  ),
                                ),
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
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => AddChildScreen(
                                        parent: Provider.of<UserProvider>(
                                          context,
                                          listen: false,
                                        ).users.firstWhere(
                                          (u) => u.id == child.parentId,
                                        ),
                                        child: child,
                                      ),
                                ),
                              );
                              // await Navigator.push(
                              //   context,
                              //   MaterialPageRoute(
                              //     builder:
                              //         (context) => AddChildScreen(
                              //       parent:
                              //       child.parentId,
                              //       child: child,
                              //     ),
                              //   ),
                              // );
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
                                              () => Navigator.of(
                                                context,
                                              ).pop(true),
                                          child: const Text(
                                            'Supprimer',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                              );

                              if (confirmed == true) {
                                await context.read<ClubProvider>().deleteChild(
                                  child.id,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Enfant supprimé avec succès',
                                    ),
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
              ExpansionTile(
                title: Text(child.name),
                subtitle: Text(
                  'Âge: ${child.age} ans • ${child.gender == 'male' ? 'Garçon' : 'Fille'}',
                ),

                children: [
                  if (enrolledCourses.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Aucun cours suivi',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    )
                  else
                    ...enrolledCourses.map(
                      (course) => ListTile(
                        leading: const Icon(Icons.school),
                        title: Text(course.name),
                        subtitle: Text(
                          '${course.ageRange} • ${course.club.name + ' ' + course.club.phone}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: const Text(
                                      'Confirmer la désinscription',
                                    ),
                                    content: Text(
                                      'Désinscrire ${child.name} de ${course.name}?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(context, false),
                                        child: const Text('Annuler'),
                                      ),
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(context, true),
                                        child: const Text(
                                          'Confirmer',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                            );
                            if (confirm == true)
                              await _unenrollFromCourse(course.id);
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),

      // Card(
      //   margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      //   child: ExpansionTile(
      //     title: Text(child.name),
      //     subtitle: Text(
      //       'Âge: ${child.age} ans • ${child.gender == 'male' ? 'Garçon' : 'Fille'}',
      //     ),
      //     trailing: IconButton(
      //       icon: const Icon(Icons.edit),
      //       onPressed:
      //           () => Navigator.push(
      //             context,
      //             MaterialPageRoute(
      //               builder:
      //                   (context) => AddChildScreen(
      //                     parent: Provider.of<UserProvider>(
      //                       context,
      //                       listen: false,
      //                     ).users.firstWhere((u) => u.id == child.parentId),
      //                     child: child,
      //                   ),
      //             ),
      //           ),
      //     ),
      //     children: [
      //       if (enrolledCourses.isEmpty)
      //         const Padding(
      //           padding: EdgeInsets.all(16.0),
      //           child: Text(
      //             'Aucun cours suivi',
      //             style: TextStyle(fontStyle: FontStyle.italic),
      //           ),
      //         )
      //       else
      //         ...enrolledCourses.map(
      //           (course) => ListTile(
      //             leading: const Icon(Icons.school),
      //             title: Text(course.name),
      //             subtitle: Text('${course.ageRange} • ${course.club}'),
      //             trailing: IconButton(
      //               icon: const Icon(Icons.cancel, color: Colors.red),
      //               onPressed: () async {
      //                 final confirm = await showDialog<bool>(
      //                   context: context,
      //                   builder:
      //                       (context) => AlertDialog(
      //                         title: const Text('Confirmer la désinscription'),
      //                         content: Text(
      //                           'Désinscrire ${child.name} de ${course.name}?',
      //                         ),
      //                         actions: [
      //                           TextButton(
      //                             onPressed:
      //                                 () => Navigator.pop(context, false),
      //                             child: const Text('Annuler'),
      //                           ),
      //                           TextButton(
      //                             onPressed: () => Navigator.pop(context, true),
      //                             child: const Text(
      //                               'Confirmer',
      //                               style: TextStyle(color: Colors.red),
      //                             ),
      //                           ),
      //                         ],
      //                       ),
      //                 );
      //                 if (confirm == true) await _unenrollFromCourse(course.id);
      //               },
      //             ),
      //           ),
      //         ),
      //     ],
      //   ),
      // ),
    );
  }
}

class AddParentScreen extends StatefulWidget {
  const AddParentScreen({Key? key}) : super(key: key);

  @override
  _AddParentScreenState createState() => _AddParentScreenState();
}

class _AddParentScreenState extends State<AddParentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un Parent')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nom du parent'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un email';
                  }
                  if (!value.contains('@')) {
                    return 'Email invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un tel';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final newUser = UserModel(
                      id: '', // Firestore générera l'ID
                      name: _nameController.text,
                      email: _emailController.text,
                      childrenIds: [],
                      gender: '',
                      phone: _phoneController.text,
                      createdAt: DateTime.now(),
                      lastLogin: DateTime.now(),
                      editedAt: DateTime.now(),
                      role: '',
                      photos: [], // Aucun enfant au départ
                    );

                    try {
                      await context.read<UserProvider>().addUser(newUser);
                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                    }
                  }
                },
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
