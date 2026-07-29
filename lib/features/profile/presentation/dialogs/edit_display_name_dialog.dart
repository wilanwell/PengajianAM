import 'package:flutter/material.dart';

Future<String?> showEditDisplayNameDialog(
  BuildContext context, {
  required String initialName,
}) {
  var editedName = initialName;

  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        key: const Key('profile-edit-name-dialog'),
        title: const Text('Edit Nama Paparan'),
        content: TextFormField(
          key: const Key('profile-edit-name-field'),
          initialValue: initialName,
          autofocus: true,
          maxLength: 30,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Nama paparan',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
          onChanged: (newValue) {
            editedName = newValue;
          },
          onFieldSubmitted: (submittedValue) {
            Navigator.of(dialogContext).pop(submittedValue);
          },
        ),
        actions: [
          TextButton(
            key: const Key('profile-edit-name-cancel'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Batal'),
          ),
          FilledButton(
            key: const Key('profile-edit-name-save'),
            onPressed: () {
              Navigator.of(dialogContext).pop(editedName);
            },
            child: const Text('Simpan'),
          ),
        ],
      );
    },
  );
}
