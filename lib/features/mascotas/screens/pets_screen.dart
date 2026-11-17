import 'package:flutter/material.dart';

import '../../../shared/controllers/paged_list_controller.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/paged_list_view.dart';
import '../models/pet.dart';
import '../services/pets_service.dart';
import 'pet_detail_screen.dart';
import 'pet_form_screen.dart';

class PetsScreen extends StatefulWidget {
  const PetsScreen({super.key, required this.service, this.select = false});
  final PetsService service;
  final bool select;
  @override
  State<PetsScreen> createState() => _PetsScreenState();
}

class _PetsScreenState extends State<PetsScreen> {
  late final _list = PagedListController<Pet>(fetchPage: widget.service.mine);
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

  Future<void> _create() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PetFormScreen(service: widget.service)),
    );
    if (saved == true && mounted) {
      showMessage(context, 'Mascota registrada.');
      await _list.refresh();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: widget.select
        ? AppBar(title: const Text('Selecciona tu mascota'))
        : null,
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _create,
      icon: const Icon(Icons.add_rounded),
      label: const Text('Registrar mascota'),
    ),
    body: PagedListView<Pet>(
      controller: _list,
      empty: const EmptyPanel(
        title: 'Sus huellas empiezan aquí',
        message: 'Registra tu primera mascota con sus datos y fotografías.',
      ),
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.select ? '¿Quién se perdió?' : 'Mis mascotas',
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text('Un espacio para quienes hacen tu vida más bonita.'),
        ],
      ),
      itemBuilder: (context, pet) => PetCard(
        pet: pet,
        onTap: () async {
          if (widget.select) {
            Navigator.pop(context, pet);
            return;
          }
          await Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  PetDetailScreen(service: widget.service, id: pet.id),
            ),
          );
          if (mounted) await _list.refresh();
        },
      ),
    ),
  );
}

class PetCard extends StatelessWidget {
  const PetCard({super.key, required this.pet, this.onTap});
  final Pet pet;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimalImage(
          url: pet.mainPhoto?.url,
          height: 200,
          label: 'Foto de ${pet.nombre}',
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pet.nombre,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                [
                  pet.species?.nombre,
                  pet.razaNombre,
                  pet.ageLabel,
                ].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    ),
  );
}
