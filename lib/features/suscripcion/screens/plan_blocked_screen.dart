import 'package:flutter/material.dart';

import '../../auth/services/session.dart';
import 'plans_screen.dart';

class PlanBlockedScreen extends StatelessWidget {
  const PlanBlockedScreen({
    super.key,
    required this.title,
    required this.message,
    required this.session,
  });
  final String title, message;
  final Session session;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: const TextStyle(fontSize: 16, height: 1.4)),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => PlansScreen(session: session),
                ),
              ),
              child: const Text('Ver planes y pagar'),
            ),
          ],
        ),
      ),
    ),
  );
}
