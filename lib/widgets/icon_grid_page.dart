import 'package:flutter/material.dart';

import 'package:healthpod/utils/show_comming_soon_dialog.dart';

class IconGridPage extends StatelessWidget {
  final List<IconData> icons = [
    Icons.home,
    Icons.star,
    Icons.settings,
    Icons.phone,
    Icons.email,
    Icons.camera_alt,
    Icons.map,
    Icons.music_note,
    Icons.shopping_cart,
    Icons.work,
    Icons.wifi,
    Icons.alarm,
  ];

  IconGridPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('What would you like to do today ...'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Wrap(
          spacing: 10.0, // Space between icons horizontally
          runSpacing: 10.0, // Space between icons vertically
          children: icons.map((icon) {
            return GestureDetector(
              onTap: () => showComingSoonDialog(context),
              child: Container(
                width: 80.0, // Fixed width for each icon container
                height: 80.0, // Fixed height for each icon container
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 50.0,
                ),
              ),
            );
          }).toList(),
        ),
        // child: GridView.builder(
        //   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        //     crossAxisCount: 5,
        //     crossAxisSpacing: 10.0,
        //     mainAxisSpacing: 10.0,
        //   ),
        //   itemCount: icons.length,
        //   itemBuilder: (context, index) {
        //     return GestureDetector(
        //       onTap: () => showComingSoonDialog(context),
        //       child: Container(
        //         decoration: BoxDecoration(
        //           color: Colors.blue,
        //           borderRadius: BorderRadius.circular(10.0),
        //         ),
        //         child: Icon(
        //           icons[index],
        //           color: Colors.white,
        //           size: 50.0,
        //         ),
        //       ),
        //     );
        //   },
        // ),
      ),
    );
  }
}
