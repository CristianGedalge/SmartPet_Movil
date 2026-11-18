import 'package:flutter/material.dart';

import '../../../shared/widgets/app_widgets.dart';
import '../services/chat_service.dart';
import '../screens/chat_screen.dart';

class ContactAuthorButton extends StatefulWidget {
  const ContactAuthorButton({
    super.key,
    required this.service,
    this.alertId,
    this.sightingId,
  });
  final ChatService service;
  final String? alertId, sightingId;
  @override
  State<ContactAuthorButton> createState() => _ContactAuthorButtonState();
}

class _ContactAuthorButtonState extends State<ContactAuthorButton> {
  bool _busy = false;
  String? _error;
  Future<void> _open() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final chat = await widget.service.open(
        alertId: widget.alertId,
        sightingId: widget.sightingId,
      );
      if (!mounted) return;
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ChatScreen(conversation: chat, service: widget.service),
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FilledButton.icon(
        onPressed: _busy ? null : _open,
        icon: const Icon(Icons.chat_bubble_outline_rounded),
        label: Text(_busy ? 'Abriendo chat…' : 'Contactar al autor'),
      ),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: InlineMessage(_error!),
        ),
    ],
  );
}
