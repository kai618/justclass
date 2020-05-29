import 'package:flutter/material.dart';
import 'package:justclass/providers/class.dart';
import 'package:justclass/screens/update_class_info_screen.dart';
import 'package:provider/provider.dart';

import '../themes.dart';
import 'app_icon_button.dart';

class NoteScreenTopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
//    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    final cls = Provider.of<Class>(context);
    return SliverAppBar(
      elevation: 5,
      expandedHeight: 130,
      forceElevated: true,
      backgroundColor: Themes.forClass(cls.theme).primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: <Widget>[
            Positioned.fill(
              child: Hero(
                tag: 'background${cls.cid}',
                child: Image.asset(Themes.forClass(cls.theme).imageUrl, fit: BoxFit.cover),
              ),
            ),
            Container(
              height: double.infinity,
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              alignment: Alignment.bottomLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    cls.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (cls.subject.isNotEmpty)
                    Text(
                      cls.subject,
                      style: const TextStyle(fontSize: 15, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            )
          ],
        ),
      ),
      leading: AppIconButton.back(onPressed: () => Navigator.of(context).pop()),
      actions: <Widget>[
        AppIconButton(
          tooltip: 'Edit Class Info',
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => UpdateClassInfoScreen(cls: Provider.of<Class>(context))),
            );
          },
        ),
      ],
    );
  }
}