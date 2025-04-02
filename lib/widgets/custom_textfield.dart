import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A custom widget that displays a header with a label and copy button,
/// and below it, a TextFormField that can be multi-line.
class CustomEditableField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isMultiLine;

  const CustomEditableField({
    super.key,
    required this.label,
    required this.controller,
    this.isMultiLine = false,
  });

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: controller.text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with label and copy button.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: Theme.of(context).textTheme.titleSmall),
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () => _copyToClipboard(context),
              ),
            ],
          ),
          // The text field.
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Enter $label',
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if ((value == null || value.isEmpty) &&
                  (label == 'Full Name' || label == 'Email')) {
                return 'Please enter your $label';
              }
              return null;
            },
            keyboardType:
                isMultiLine ? TextInputType.multiline : TextInputType.text,
            minLines: isMultiLine ? 3 : 1,
            maxLines: isMultiLine ? null : 1,
          ),
        ],
      ),
    );
  }
}
