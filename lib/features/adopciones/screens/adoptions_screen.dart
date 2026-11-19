import 'package:flutter/material.dart';

import '../../../shared/controllers/paged_list_controller.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/paged_list_view.dart';
import '../models/adoption.dart';
import '../services/adoptions_service.dart';
import 'adoption_detail_screen.dart';

class AdoptionsScreen extends StatefulWidget {
  const AdoptionsScreen({super.key, required this.service});
  final AdoptionsService service;
  @override
  State<AdoptionsScreen> createState() => _AdoptionsScreenState();
}

class _AdoptionsScreenState extends State<AdoptionsScreen> {
  late final _list = PagedListController<AdoptionPublication>(
    fetchPage: widget.service.list,
  );
  @override
  void initState() {
    super.initState();
    _list.refresh();
  }

  @override
  void dispose() {
    _list.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PagedListView<AdoptionPublication>(
    controller: _list,
    header: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Adopciones',
          style: TextStyle(fontSize: 29, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 8),
        Text(
          'Un nuevo compañero, una nueva historia. Conoce a quienes buscan un hogar.',
        ),
      ],
    ),
    empty: const EmptyPanel(
      title: 'Pronto habrá nuevas historias',
      message: 'Aquí aparecerán los animales disponibles para adopción de veterinarias y refugios. Desliza hacia abajo para actualizar.',
      icon: Icons.favorite_border_rounded,
    ),
    itemBuilder: (context, item) => AppCard(
      onTap: () async {
        await Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) =>
                AdoptionDetailScreen(id: item.id, service: widget.service),
          ),
        );
        if (mounted) await _list.refresh();
      },
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimalImage(
            url: item.pet.mainPhoto?.url,
            height: 200,
            label: 'Foto de ${item.pet.nombre}',
          ),
          const SizedBox(height: 12),
          Text(
            item.pet.nombre,
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
          ),
          Text(
            '${item.pet.species?.nombre ?? 'Mascota'} · ${item.pet.ageLabel}',
          ),
          const SizedBox(height: 8),
          Text(
            item.establishment.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),
          const Text(
            'Ver adopción →',
            style: TextStyle(
              color: Color(0xFF008F73),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}
