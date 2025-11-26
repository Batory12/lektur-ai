import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:lekturai_front/api/profile.dart';

class SchoolPicker extends StatefulWidget {
  final String? initialCity;
  final String? initialSchool;
  final String? initialClass;
  final Function(String city, String school, String className) onSaved;
  final VoidCallback? onCancel;

  const SchoolPicker({
    super.key,
    this.initialCity,
    this.initialSchool,
    this.initialClass,
    required this.onSaved,
    this.onCancel,
  });

  @override
  State<SchoolPicker> createState() => _SchoolPickerState();
}

class _SchoolPickerState extends State<SchoolPicker> {
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();
  final TextEditingController _classController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final ProfileApi profileApi = ProfileApi();

  @override
  void initState() {
    super.initState();
    _cityController.text = widget.initialCity ?? '';
    _schoolController.text = widget.initialSchool ?? '';
    _classController.text = widget.initialClass ?? '';
  }

  @override
  void dispose() {
    _cityController.dispose();
    _schoolController.dispose();
    _classController.dispose();
    super.dispose();
  }

  String? _validateCity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Wybierz miejscowość twojej szkoły';
    }
    // Async validation cannot be done synchronously here.
    // We rely on the user selecting from the list or we could validate on submit.
    return null;
  }

  String? _validateSchool(String? value) {
    if (value == null || value.isEmpty) {
      return 'Wybierz szkołę';
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
              return await profileApi.getCityAutocompletions(pattern);
            },
            itemBuilder: (context, suggestion) {
              return ListTile(title: Text(suggestion));
            },
            onSuggestionSelected: (suggestion) {
              _cityController.text = suggestion;
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
              if (_cityController.text.isEmpty) return [];
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
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (widget.onCancel != null)
                TextButton(onPressed: widget.onCancel, child: Text('Anuluj')),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    widget.onSaved(
                      _cityController.text,
                      _schoolController.text,
                      _classController.text,
                    );
                  }
                },
                child: Text('Zapisz'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
