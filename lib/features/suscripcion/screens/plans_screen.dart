import 'package:flutter/material.dart';

import '../../../config/app_theme.dart';
import '../../../shared/utils/error_message.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../auth/services/session.dart';
import '../models/plan_offer.dart';
import '../services/subscription_service.dart';
import 'payment_screen.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key, required this.session});
  final Session session;

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  late final SubscriptionService _service;
  late Future<List<PlanOffer>> _plans;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _service = SubscriptionService(widget.session.api);
    _plans = _service.plans();
  }

  Future<void> _openPayment(PlanOffer plan) async {
    if (_updating) return;
    final paid = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          plan: plan,
          service: _service,
          defaultHolder: widget.session.user?.fullName ?? '',
        ),
      ),
    );
    if (paid != true || !mounted) return;
    setState(() => _updating = true);
    try {
      await widget.session.reload();
      if (!mounted) return;
      showMessage(
        context,
        'Demostración aprobada. Tu plan ${plan.nombre} ya está activo.',
      );
      Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        showMessage(
          context,
          userErrorMessage(
            error,
            fallback:
                'El pago fue aprobado, pero no pudimos actualizar la pantalla.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Elige tu plan')),
    body: FutureBuilder<List<PlanOffer>>(
      future: _plans,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingPanel(message: 'Preparando tus opciones…');
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: ErrorPanel(
              message: userErrorMessage(
                snapshot.error,
                fallback: 'No pudimos cargar los planes. Intenta nuevamente.',
              ),
              onRetry: () => setState(() => _plans = _service.plans()),
            ),
          );
        }
        final paid = (snapshot.data ?? const <PlanOffer>[])
            .where((plan) => plan.dePago)
            .toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
          children: [
            Text(
              'Más oportunidades para encontrar y cuidar a tu mascota',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900, height: 1.15),
            ),
            const SizedBox(height: 10),
            const Text(
              'Compara los beneficios y activa 30 días de acceso. La demostración no realiza cargos ni se renueva automáticamente.',
              style: TextStyle(color: AppColors.muted, height: 1.5),
            ),
            const SizedBox(height: 22),
            if (paid.isEmpty)
              const EmptyPanel(
                title: 'No hay planes disponibles',
                message: 'Vuelve a revisar más adelante.',
                icon: Icons.workspace_premium_outlined,
              )
            else
              for (var index = 0; index < paid.length; index++) ...[
                _PlanOfferCard(
                  plan: paid[index],
                  featured: index == 0,
                  current:
                      widget.session.user?.suscripcion?.planId ==
                      paid[index].id,
                  disabled: _updating,
                  onChoose: () => _openPayment(paid[index]),
                ),
                const SizedBox(height: 16),
              ],
            const SizedBox(height: 4),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, size: 20, color: AppColors.muted),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'El modo de pago es una simulación académica. No ingreses datos de una tarjeta real.',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );
}

class _PlanOfferCard extends StatelessWidget {
  const _PlanOfferCard({
    required this.plan,
    required this.featured,
    required this.current,
    required this.disabled,
    required this.onChoose,
  });

  final PlanOffer plan;
  final bool featured, current, disabled;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: featured ? AppColors.primary : AppColors.line,
        width: featured ? 1.8 : 1,
      ),
      boxShadow: featured
          ? const [
              BoxShadow(
                color: Color(0x16008F73),
                blurRadius: 22,
                offset: Offset(0, 8),
              ),
            ]
          : null,
    ),
    padding: const EdgeInsets.all(22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                plan.nombre,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (current)
              const _Badge(label: 'Plan actual')
            else if (featured)
              const _Badge(label: 'Recomendado'),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          plan.descripcionClara,
          style: const TextStyle(color: AppColors.muted, height: 1.45),
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              plan.precioTexto,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 5, left: 5),
              child: Text(
                '/ 30 días',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _Benefit(text: plan.cupo('búsquedas por foto', plan.busquedasFotoMes)),
        const SizedBox(height: 10),
        _Benefit(
          text: plan.cupo(
            'mensajes con el agente SmartPet',
            plan.mensajesAgenteMes,
          ),
        ),
        const SizedBox(height: 10),
        const _Benefit(text: 'Activación inmediata al aprobar la demostración'),
        const SizedBox(height: 10),
        const _Benefit(text: 'Sin renovación automática'),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: disabled || current ? null : onChoose,
            child: Text(
              current ? 'Este es tu plan actual' : 'Elegir ${plan.nombre}',
            ),
          ),
        ),
      ],
    ),
  );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.mint,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Color(0xFF008F73),
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Icon(Icons.check_circle, size: 20, color: AppColors.primary),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: const TextStyle(height: 1.35))),
    ],
  );
}
