import 'package:flutter/material.dart';

class EditTitleDialog extends StatefulWidget {
  final String initialTitle;
  final String type;

  const EditTitleDialog({
    super.key,
    required this.initialTitle,
    required this.type,
  });

  @override
  State<EditTitleDialog> createState() => _EditTitleDialogState();
}

class _EditTitleDialogState extends State<EditTitleDialog> {
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${widget.type} Title'),
      content: TextField(
        controller: _titleController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Enter a title',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFC6C2FF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6E61FD), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final newTitle = _titleController.text.trim();
            if (newTitle.isNotEmpty) {
              Navigator.pop(context, newTitle);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6E61FD),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
