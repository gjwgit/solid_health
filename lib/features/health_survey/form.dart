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
import 'package:healthpod/features/health_survey/question.dart';

/// A widget for rendering a dynamic health survey form.
///
/// The form displays a series of questions with various input types, including
/// text, number, and categorical options. It validates responses and submits
/// them as a map when the form is completed.

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
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  /// Generates UI for each survey question, including text, number, and categorical options.

  Widget _buildQuestionWidget(HealthSurveyQuestion question, int index) {
    const double fixedWidth = 300.0; // Define a fixed width for all fields

    // Special handling for the notes field.

    if (question.type == HealthDataType.text) {
      return SizedBox(
        width: fixedWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${index + 1}. ${question.question}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              maxLines: null,
              minLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter your notes here',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
                contentPadding: EdgeInsets.all(12),
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
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: fixedWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${index + 1}. ${question.question}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          if (question.type != HealthDataType.categorical)
            _buildInputField(question)
          else
            _buildCategoricalQuestion(question),
        ],
      ),
    );
  }

  /// Handles rendering of input fields for non-categorical questions like number and text.

  Widget _buildInputField(HealthSurveyQuestion question) {
    return SizedBox(
      width: double.infinity,
      child: switch (question.type) {
        HealthDataType.number => _buildNumberInput(question),
        HealthDataType.text => _buildTextInput(question),
        _ => const SizedBox(), // Categorical handled separately
      },
    );
  }

  /// Handles rendering of text input fields.

  Widget _buildTextInput(HealthSurveyQuestion question) {
    return TextFormField(
      decoration: InputDecoration(
        hintText: 'Enter your response',
        suffixText: question.unit,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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

  /// Handles rendering of number input fields.

  Widget _buildNumberInput(HealthSurveyQuestion question) {
    return TextFormField(
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: 'Enter value',
        suffixText: question.unit,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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

  /// Handles rendering of categorical questions.

  Widget _buildCategoricalQuestion(HealthSurveyQuestion question) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FormField<String>(
          validator: (value) {
            if (question.isRequired && (value == null || value.isEmpty)) {
              return 'Please select an option';
            }
            return null;
          },
          builder: (FormFieldState<String> field) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ...question.options!.map(
                  (option) => SizedBox(
                    width: 300,
                    child: RadioListTile<String>(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(option),
                      value: option,
                      groupValue: field.value,
                      onChanged: (value) {
                        field.didChange(value);
                        _responses[question.question] = value;
                      },
                    ),
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
      ),
    );
  }

  /// Submits the form when the submit button is pressed.

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      widget.onSubmit(_responses);
    }
  }

  /// Builds the form UI.

  @override
  Widget build(BuildContext context) {
    final regularQuestions =
        widget.questions.where((q) => q.type != HealthDataType.text).toList();
    final notesQuestion =
        widget.questions.firstWhere((q) => q.type == HealthDataType.text);

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final optimalCount = constraints.maxWidth > 900
                    ? 3
                    : constraints.maxWidth > 600
                        ? 2
                        : 1;

                final rows = <Widget>[];
                for (var i = 0;
                    i < regularQuestions.length;
                    i += optimalCount) {
                  final rowItems = <Widget>[];

                  for (var j = 0;
                      j < optimalCount && i + j < regularQuestions.length;
                      j++) {
                    rowItems.add(
                      Padding(
                        padding: EdgeInsets.only(
                          right: j < optimalCount - 1 ? 16.0 : 0,
                        ),
                        child: _buildQuestionWidget(
                          regularQuestions[i + j],
                          i + j,
                        ),
                      ),
                    );
                  }

                  rows.add(
                    Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: rowItems
                              .map((item) => Expanded(child: item))
                              .toList(),
                        )),
                  );
                }

                return Column(children: rows);
              },
            ),
            const SizedBox(height: 20),
            Center(
              child: _buildQuestionWidget(
                  notesQuestion, widget.questions.length - 1),
            ),
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: 120,
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
      ),
    );
  }
}
