// lib/widgets/app_scaffold.dart
import 'package:flutter/material.dart';
import 'package:lekturai_front/reading_question_screen.dart';
import 'package:lekturai_front/widgets/responsive_center.dart';
import 'package:lekturai_front/widgets/custom_app_bar.dart';

// Breakpoint for large screens (desktop/tablet landscape)
const double kLargeScreenBreakpoint = 1024.0;

class CommonScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final bool showDrawer;
  final bool useResponsiveLayout;
  final bool useSafeArea; // New parameter to control SafeArea

  const CommonScaffold({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.showDrawer = true,
    this.useResponsiveLayout = true,
    this.useSafeArea = true, // Default to true for Android compatibility
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth >= kLargeScreenBreakpoint;

        // Wrap body with SafeArea if needed
        Widget bodyWidget = useResponsiveLayout
            ? ResponsiveCenter(child: body)
            : body;

        if (useSafeArea) {
          bodyWidget = SafeArea(child: bodyWidget);
        }

        // For large screens with drawer enabled, use permanent drawer layout
        if (isLargeScreen && showDrawer) {
          return Scaffold(
            appBar: CustomAppBar(title: title, showDrawerIcon: false),
            body: Row(
              children: [
                // Permanent drawer on the left
                SizedBox(width: 280, child: _buildDrawerContent(context)),
                // Divider between drawer and content
                const VerticalDivider(width: 1, thickness: 1),
                // Main content area
                Expanded(child: bodyWidget),
              ],
            ),
            floatingActionButton: floatingActionButton,
          );
        }

        // For small screens or no drawer, use traditional drawer
        return Scaffold(
          appBar: CustomAppBar(title: title, showDrawerIcon: showDrawer),
          drawer: showDrawer ? _buildDrawer(context) : null,
          body: bodyWidget,
          floatingActionButton: floatingActionButton,
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(child: _buildDrawerContent(context));
  }

  Widget _buildDrawerContent(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 20.0, top: 20.0),
            child: Text('Aktywności'),
          ),
          ListTile(
            leading: const Icon(Icons.today),
            title: const Text('Zadania z lektur'),
            onTap: () {
              showReadingPicker(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.tab),
            title: const Text('Zadania maturalne'),
            onTap: () {
              Navigator.pushNamed(context, '/zmatur');
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Asystent rozprawki'),
            onTap: () {
              Navigator.pushNamed(context, '/rozprawka');
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.0),
            child: Divider(
              height: 20.0,
              thickness: 1.0,
              color: Colors.blueGrey,
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 20.0, top: 20.0),
            child: Text('Dane'),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Strona główna'),
            onTap: () {
              Navigator.pushNamed(context, '/home');
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Historia odpowiedzi'),
            onTap: () {
              Navigator.pushNamed(context, '/historia');
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profil'),
            onTap: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),
    );
  }
}

void showReadingPicker(BuildContext context) {
  final formKey = GlobalKey<FormState>();
  String? selectedOption;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedOption,
                  items:
                      ['Lalka', 'Dziady, cz. 2', 'Cierpienia młodego Wertera']
                          .map(
                            (option) => DropdownMenuItem(
                              value: option,
                              child: Text(option),
                            ),
                          )
                          .toList(),
                  onChanged: (value) => selectedOption = value,
                  decoration: const InputDecoration(
                    labelText: 'Wybierz lekturę',
                  ),
                  validator: (value) => value == null ? 'Wymagane' : null,
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReadingQuestionsScreen(
                              readingName:
                                  selectedOption?.replaceAll(
                                    RegExp(r' '),
                                    "_",
                                  ) ??
                                  "Kordian",
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text('Wygeneruj zadanie'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
