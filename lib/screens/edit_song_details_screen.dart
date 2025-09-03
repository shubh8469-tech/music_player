import 'package:flutter/material.dart';
import '../commonWidgets/app_bar_with_icon_title.dart';
import '../l10n/l10n.dart';

class EditSongDetailsScreen extends StatefulWidget {
  const EditSongDetailsScreen({super.key});

  @override
  State<EditSongDetailsScreen> createState() => _EditSongDetailsScreenState();
}

class _EditSongDetailsScreenState extends State<EditSongDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBarWithIconTitle(title: S.of(context).editDetails));
  }
}
