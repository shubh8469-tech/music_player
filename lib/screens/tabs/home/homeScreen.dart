import 'package:flutter/material.dart';
import 'package:music_app/themes/font.dart';

import '../../../commonWidgets/textWidget.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
        child: Column(
          children: [

            Texts('Explore Playlists', fontSize: 18, fontWeight: AppFontWeights.medium, fontFamily: AppFonts.inter,),

          ],
        ),
      ),
    );
  }
}
