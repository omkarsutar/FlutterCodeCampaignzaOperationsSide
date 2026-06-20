import 'package:flutter/material.dart';

Future<bool> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String content,
  required String confirmLabel,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
              ),
              child: Text(
                confirmLabel,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ) ??
      false;
}

/// Delete confirmation dialog with a "type to confirm" gate.
///
/// The Delete button stays disabled until the user types the exact [confirmText]
/// (default: "sure") into the text field. This adds an extra layer of safety
/// against accidental destructive deletes.
///
/// Returns `true` only if the user typed the exact text and tapped Delete.
/// Returns `false` if cancelled, dismissed, or if the text didn't match.
///
/// [entityNameLower] is shown in the helper text, e.g. "this agency".
Future<bool> showConfirmDeleteWithTextDialog({
  required BuildContext context,
  required String title,
  required String content,
  String confirmText = 'sure',
  String? entityNameLower,
}) async {
  final result = await showDialog<bool>(
    context: context,
    // Dismissing outside the dialog cancels (returns null -> false).
    barrierDismissible: true,
    builder: (dialogContext) => _ConfirmDeleteWithTextDialog(
      title: title,
      content: content,
      confirmText: confirmText,
      entityNameLower: entityNameLower,
    ),
  );
  return result ?? false;
}

class _ConfirmDeleteWithTextDialog extends StatefulWidget {
  final String title;
  final String content;
  final String confirmText;
  final String? entityNameLower;

  const _ConfirmDeleteWithTextDialog({
    required this.title,
    required this.content,
    required this.confirmText,
    this.entityNameLower,
  });

  @override
  State<_ConfirmDeleteWithTextDialog> createState() =>
      _ConfirmDeleteWithTextDialogState();
}

class _ConfirmDeleteWithTextDialogState
    extends State<_ConfirmDeleteWithTextDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _canDelete = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  void _onChanged() {
    final matched = _controller.text.trim() == widget.confirmText;
    if (matched != _canDelete) {
      setState(() => _canDelete = matched);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final helper = widget.entityNameLower != null
        ? 'Type "${widget.confirmText}" to delete this ${widget.entityNameLower}. This action cannot be undone.'
        : 'Type "${widget.confirmText}" to delete. This action cannot be undone.';

    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.content),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Type ${widget.confirmText}',
              hintText: widget.confirmText,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.warning_amber_rounded),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            helper,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          // Delete is only enabled once the user has typed the exact text.
          onPressed: _canDelete ? () => Navigator.of(context).pop(true) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE53935),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFE53935).withValues(alpha: 0.4),
            disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
          ),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}

/* Future<bool> showDeleteConfirmationDialog(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Note'),
          content: const Text('Are you sure you want to delete this note?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935)),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ) ??
      false; // default to false if dismissed
}

Future<bool> showLogoutConfirmationDialog(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to Logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935)),
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ) ??
      false; // default to false if dismissed
} */

Future<void> showLoadingDialog({
  required BuildContext context,
  required String message,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 24),
            Text(message),
          ],
        ),
      ),
    ),
  );
}
