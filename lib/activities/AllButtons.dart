import 'package:flutter/material.dart';

class AllButtons extends StatelessWidget {
  const AllButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ElevatedButton(onPressed: (){
          //   Navigator.of(context).push(
          //     MaterialPageRoute(
          //       builder: (ctx) => AddCourseScreen(club: club),
          //     ),
          //   );
          // }, child: Text(''))
        ],
      ),
    );
  }
}
