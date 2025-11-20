import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lekturai_front/widgets/change_password.dart';
import 'package:lekturai_front/widgets/school_picker.dart';

void main() {
  group('SchoolPicker Tests', () {
    testWidgets('Validates empty fields', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SchoolPicker(
            onSaved: (city, school, className) {},
          ),
        ),
      ));

      final buttonFinder = find.text('Zapisz');
      await tester.tap(buttonFinder);
      await tester.pump();

      expect(find.text('Wybierz miejscowość twojej szkoły'), findsOneWidget);
      expect(find.text('Wybierz szkołę'), findsOneWidget);
      expect(find.text('Wybierz klasę'), findsOneWidget);
    });

    testWidgets('Validates class format', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SchoolPicker(
            onSaved: (city, school, className) {},
          ),
        ),
      ));

      final classFieldFinder = find.widgetWithText(TextFormField, 'Klasa');
      await tester.enterText(classFieldFinder, 'invalid');
      
      final buttonFinder = find.text('Zapisz');
      await tester.tap(buttonFinder);
      await tester.pump();

      expect(find.text('Niepoprawny format klasy (np. 3A)'), findsOneWidget);
    });

    testWidgets('Calls onSaved when valid', (WidgetTester tester) async {
      bool saved = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SchoolPicker(
            initialCity: 'Warszawa',
            initialSchool: 'Test School',
            initialClass: '3a',
            onSaved: (city, school, className) {
              saved = true;
            },
          ),
        ),
      ));

      final buttonFinder = find.text('Zapisz');
      await tester.tap(buttonFinder);
      await tester.pump();

      expect(saved, isTrue);
    });
  });

  group('ChangePasswordWidget Tests', () {
    testWidgets('Validates password mismatch', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: ChangePasswordWidget())));

      final newPassFinder = find.widgetWithText(TextFormField, 'New Password');
      final confirmPassFinder = find.widgetWithText(TextFormField, 'Confirm New Password');

      await tester.enterText(newPassFinder, 'password123');
      await tester.enterText(confirmPassFinder, 'password456');

      final buttonFinder = find.text('Change Password');
      await tester.tap(buttonFinder);
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('Validates short password', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: ChangePasswordWidget())));

      final newPassFinder = find.widgetWithText(TextFormField, 'New Password');
      await tester.enterText(newPassFinder, '123');

      final buttonFinder = find.text('Change Password');
      await tester.tap(buttonFinder);
      await tester.pump();

      expect(find.text('Password must be at least 6 characters long'), findsOneWidget);
    });
  });
}

