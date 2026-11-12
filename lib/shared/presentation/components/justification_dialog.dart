import 'package:flutter/material.dart';

import '../design/app_colors.dart';

// Pide la justificación de una acción del Verificador senior (reevaluar o suspender).
// Devuelve el texto sin espacios sobrantes, o null si se cancela.
class JustificationDialog extends StatefulWidget {
  final String title;
  final String description;
  final String confirmLabel;
  final int maxLength;
  final bool destructive;

  const JustificationDialog({
    super.key,
    required this.title,
    required this.description,
    required this.confirmLabel,
    required this.maxLength,
    this.destructive = false,
  });

  @override
  State<JustificationDialog> createState() => _JustificationDialogState();
}

class _JustificationDialogState extends State<JustificationDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _error = 'Escribe la justificación');
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.description),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 4,
            maxLength: widget.maxLength,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: 'Justificación', errorText: _error),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _submit,
          style: widget.destructive ? FilledButton.styleFrom(backgroundColor: AppColors.error) : null,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
