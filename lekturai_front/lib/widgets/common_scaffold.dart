// lib/widgets/app_scaffold.dart
import 'package:flutter/material.dart';
import 'package:lekturai_front/widgets/responsive_center.dart';

class CommonScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final bool showDrawer;

  const CommonScaffold({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.showDrawer = true,
    this.useResponsiveLayout = true,
  });

  final bool useResponsiveLayout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      drawer: showDrawer
          ? Drawer(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 20.0, top: 20.0),
                    child: Text('Aktywności'),
                  ),
                  ListTile(
                    leading: Icon(Icons.today),
                    title: Text('Zadania z lektur'),
                    onTap: () {
                      Navigator.pushNamed(context, '/zlektur');
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.tab),
                    title: Text('Zadania maturalne'),
                    onTap: () {
                      Navigator.pushNamed(context, '/zmatur');
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Asystent rozprawki'),
                    onTap: () {
                      Navigator.pushNamed(context, '/rozprawka');
                    },
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.0),
                    child: Divider(
                      height: 20.0,
                      thickness: 1.0,
                      color: Colors.blueGrey,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 20.0, top: 20.0),
                    child: Text('Dane'),
                  ),
                  ListTile(
                    leading: Icon(Icons.home),
                    title: Text('Strona główna'),
                    onTap: () {
                      Navigator.pushNamed(context, '/home');
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.history),
                    title: Text('Historia odpowiedzi'),
                    onTap: () {
                      Navigator.pushNamed(context, '/historia');
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.person),
                    title: Text('Profil'),
                    onTap: () {
                      Navigator.pushNamed(context, '/profile');
                    },
                  ),
                ],
              ),
            )
          : null,
      body: useResponsiveLayout ? ResponsiveCenter(child: body) : body,
      floatingActionButton: floatingActionButton,
    );
  }
}
