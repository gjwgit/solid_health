/// Survey form for health survey questions.
//
// Time-stamp: <Thursday 2024-12-19 13:33:06 +1100 Graham Williams>
//
/// Copyright (C) 2025, Software Innovation Institute, ANU
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
// details.
//
// You should have received a copy of the GNU General Public License along with
// this program.  If not, see <https://www.gnu.org/licenses/>.
///
/// Authors: Ashley Tang

library;

import 'package:flutter/material.dart';

import 'package:healthpod/constants/health_data_type.dart';
import 'package:healthpod/widgets/health_survey/question.dart';

/// A widget that displays and collects responses for health survey questions.

class HealthSurveyForm extends StatefulWidget {
  final List<HealthSurveyQuestion> questions;
  final void Function(Map<String, dynamic> responses) onSubmit;
  final String submitButtonText;

  const HealthSurveyForm({
    super.key,
    required this.questions,
    required this.onSubmit,
    this.submitButtonText = 'Submit',
  });

  @override
  State<HealthSurveyForm> createState() => _HealthSurveyFormState();
}

class _HealthSurveyFormState extends State<HealthSurveyForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _responses = {};

  Widget _buildQuestionWidget(HealthSurveyQuestion question) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: switch (question.type) {
        HealthDataType.categorical => _buildCategoricalQuestion(question),
        HealthDataType.number => _buildNumberInput(question),
        HealthDataType.text => _buildTextInput(question),
      },
    );
  }

  Widget _buildTextInput(HealthSurveyQuestion question) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: question.question,
        suffixText: question.unit,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (question.isRequired && (value == null || value.isEmpty)) {
          return 'Please enter a value';
        }
        return null;
      },
      onSaved: (value) {
        _responses[question.question] = value;
      },
    );
  }

  Widget _buildNumberInput(HealthSurveyQuestion question) {
    return TextFormField(
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: question.question,
        suffixText: question.unit,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return question.isRequired ? 'Please enter a value' : null;
        }
        final number = double.tryParse(value);
        if (number == null) {
          return 'Please enter a valid number';
        }
        if (question.min != null && number < question.min!) {
          return 'Value must be at least ${question.min}';
        }
        if (question.max != null && number > question.max!) {
          return 'Value must not exceed ${question.max}';
        }
        return null;
      },
      onSaved: (value) {
        _responses[question.question] = double.tryParse(value ?? '');
      },
    );
  }

  Widget _buildCategoricalQuestion(HealthSurveyQuestion question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.question,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        FormField<String>(
          validator: (value) {
            if (question.isRequired && (value == null || value.isEmpty)) {
              return 'Please select an option';
            }
            return null;
          },
          builder: (FormFieldState<String> field) {
            return Column(
              children: [
                ...question.options!.map(
                  (option) => RadioListTile<String>(
                    title: Text(option),
                    value: option,
                    groupValue: field.value,
                    onChanged: (value) {
                      field.didChange(value);
                      _responses[question.question] = value;
                    },
                  ),
                ),
                if (field.hasError)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 8),
                    child: Text(
                      field.errorText!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      widget.onSubmit(_responses);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ...widget.questions.map((question) => _buildQuestionWidget(question)),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              width: 120, // Fixed width for smaller button
              child: ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(widget.submitButtonText),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
