import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const legalVersion = '2026-11-18.1';

class LegalScreen extends StatefulWidget {
  const LegalScreen({super.key, required this.privacy});
  final bool privacy;
  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  late final Future<Map<String, dynamic>> _document = _load();
  Future<Map<String, dynamic>> _load() async {
    final data = jsonDecode(
      await rootBundle.loadString('assets/legal/legal.json'),
    ) as Map<String, dynamic>;
    if (data['version'] != legalVersion) {
      throw const FormatException('Versión legal incompatible.');
    }
    return data;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.privacy ? 'Política de privacidad' : 'Términos y condiciones',
      ),
    ),
    body: FutureBuilder<Map<String, dynamic>>(
      future: _document,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No se pudo abrir el documento. Reinicia la app y vuelve a intentarlo.',
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.requireData;
        final document =
            (data['documents'] as Map)[widget.privacy
                    ? 'privacidad'
                    : 'terminos']
                as Map;
        return SelectionArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                document['title'] as String,
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Versión ${data['version']} · ${data['updatedAt']}',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              Text(
                document['introduction'] as String,
                style: const TextStyle(fontSize: 16, height: 1.6),
              ),
              const SizedBox(height: 20),
              Text(
                'Responsable del servicio: ${data['responsible']}.',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text(
                data['contact'] as String,
                style: const TextStyle(height: 1.6),
              ),
              for (final section in document['sections'] as List) ...[
                const SizedBox(height: 28),
                Text(
                  section['title'] as String,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  section['body'] as String,
                  style: const TextStyle(fontSize: 16, height: 1.65),
                ),
              ],
              const SizedBox(height: 28),
              const Text(
                'Leer el documento no marca las casillas del registro. Vuelve al formulario para decidir si aceptas.',
                style: TextStyle(fontSize: 14, height: 1.6),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class LegalLinks extends StatelessWidget {
  const LegalLinks({super.key});
  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 8,
    children: [
      TextButton(
        onPressed: () => Navigator.push<void>(
          context,
          MaterialPageRoute(builder: (_) => const LegalScreen(privacy: false)),
        ),
        child: const Text('Términos y condiciones'),
      ),
      TextButton(
        onPressed: () => Navigator.push<void>(
          context,
          MaterialPageRoute(builder: (_) => const LegalScreen(privacy: true)),
        ),
        child: const Text('Política de privacidad'),
      ),
    ],
  );
}
