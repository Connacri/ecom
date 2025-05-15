import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_service.dart';

class iconLogout extends StatelessWidget {
  const iconLogout({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () async {
        await Provider.of<AuthService>(context, listen: false).signOut();
      },
      icon: Icon(Icons.logout),
    );
  }
}
