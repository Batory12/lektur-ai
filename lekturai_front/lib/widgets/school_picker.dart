import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:lekturai_front/api/profile.dart';

class SchoolPicker extends StatefulWidget {
  const SchoolPicker({super.key});

  @override
  State<SchoolPicker> createState() => _SchoolPickerState();
}

class _SchoolPickerState extends State<SchoolPicker> {
  String? _selectedCity;
  String? _selectedSchool;
  String? _selectedClass;
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();
  final TextEditingController _classController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final ProfileApi profileApi = ProfileApi();

  String? _validateCity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Wybierz miejscowość twojej szkoły';
    }
    if (!profileApi.getCityAutocompletions(value).contains(value)) {
      return 'Miejscowość nieznana';
    }
    return null;
  }

  String? _validateSchool(String? value) {
    if (value == null || value.isEmpty) {
      return 'Wybierz szkołę';
    }
    if (!profileApi
        .getSchoolAutocompletions(_cityController.text, value)
        .contains(value)) {
      return 'Szkoła nieznana. Wybierz szkołę z listy';
    }
    return null;
  }

  String? _validateClass(String? value) {
    if (value == null || value.isEmpty) {
      return 'Wybierz klasę';
    }
    if (!RegExp(r'^[1-8][A-Za-z]$').hasMatch(value)) {
      return 'Niepoprawny format klasy (np. 3A)';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TypeAheadFormField(
            textFieldConfiguration: TextFieldConfiguration(
              controller: _cityController,
              decoration: InputDecoration(
                labelText: 'Miejscowość',
                border: OutlineInputBorder(),
              ),
            ),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            suggestionsCallback: (pattern) async {
              return await ProfileApi().getCityAutocompletions(pattern);
            },
            itemBuilder: (context, suggestion) {
              return ListTile(title: Text(suggestion));
            },
            onSuggestionSelected: (suggestion) {
              _cityController.text = suggestion;
              _selectedCity = suggestion;
              _schoolController.clear();
              _classController.clear();
            },
            validator: _validateCity,
            errorBuilder: (context, error) {
              return Padding(
                padding: const EdgeInsets.only(top: 5.0),
                child: Text(
                  error.toString(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 20),
          TypeAheadFormField(
            textFieldConfiguration: TextFieldConfiguration(
              controller: _schoolController,
              decoration: InputDecoration(
                labelText: 'Szkoła',
                border: OutlineInputBorder(),
              ),
            ),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            suggestionsCallback: (pattern) async {
              return await profileApi.getSchoolAutocompletions(
                _cityController.text,
                pattern,
              );
            },
            itemBuilder: (context, suggestion) {
              return ListTile(title: Text(suggestion));
            },
            onSuggestionSelected: (suggestion) {
              _schoolController.text = suggestion;
            },
            validator: _validateSchool,
            errorBuilder: (context, error) {
              return Padding(
                padding: const EdgeInsets.only(top: 5.0),
                child: Text(
                  error.toString(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 20),
          TextFormField(
            controller: _classController,
            decoration: InputDecoration(
              labelText: 'Klasa',
              border: OutlineInputBorder(),
            ),
            validator: _validateClass,
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Form is valid!')));
              }
            },
            child: Text('Validate Form'),
          ),
        ],
      ),
    );
  }
}
