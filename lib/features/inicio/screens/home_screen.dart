import 'package:flutter/material.dart';

import '../../../config/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/async_resource.dart';
import '../../auth/models/user_profile.dart';
import '../../alertas/models/lost_alert.dart';
import '../../alertas/services/alerts_service.dart';
import '../../alertas/screens/alerts_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.user,
    required this.alerts,
    required this.onPets,
    required this.onAlerts,
    required this.onAlert,
    required this.onAdoptions,
  });
  final UserProfile user;
  final AlertsService alerts;
  final VoidCallback onPets, onAlerts, onAdoptions;
  final ValueChanged<LostAlert> onAlert;
  @override
  Widget build(BuildContext context) => AsyncResource<List<LostAlert>>(
    load: () => alerts.list(3, 0, mine: false),
    builder: (context, latest, reload) => RefreshIndicator(
      onRefresh: () async {
        reload();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        children: [
          const Text(
            'UNIDOS POR SUS HUELLAS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.8,
              color: Color(0xFF008F73),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Hola, ${user.nombre} 👋',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cuidar empieza con estar cerca.',
            style: TextStyle(color: AppColors.muted, fontSize: 16),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.pets_rounded, size: 40, color: Colors.white),
                const SizedBox(height: 26),
                const Text(
                  'Pequeñas huellas.\nGrandes historias.',
                  style: TextStyle(
                    fontSize: 29,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Guarda sus datos y fotografías. Tener su ficha lista puede ayudar cuando más lo necesitan.',
                  style: TextStyle(color: Colors.white, height: 1.5),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.ink,
                  ),
                  onPressed: onPets,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Ver mis mascotas'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.favorite_border_rounded,
                  color: Color(0xFF008F73),
                  size: 32,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Un hogar cambia su historia',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Conoce a los animales de veterinarias y refugios que buscan una familia.',
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: onAdoptions,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Explorar adopciones'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          const Text(
            'Cerca de tu comunidad',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text('Alertas de extravío que necesitan una mirada atenta.'),
          const SizedBox(height: 18),
          if (latest.isEmpty)
            const EmptyPanel(
              title: 'Sin alertas activas',
              message: 'Las alertas de la comunidad aparecerán aquí.',
              icon: Icons.favorite_border_rounded,
            ),
          for (final alert in latest)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: AlertCard(alert: alert, onTap: () => onAlert(alert)),
            ),
          OutlinedButton.icon(
            onPressed: onAlerts,
            icon: const Icon(Icons.campaign_outlined),
            label: const Text('Explorar alertas'),
          ),
        ],
      ),
    ),
  );
}
