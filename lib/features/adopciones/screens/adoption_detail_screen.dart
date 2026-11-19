import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/async_resource.dart';
import '../models/adoption.dart';
import '../services/adoptions_service.dart';

class AdoptionDetailScreen extends StatelessWidget {
  const AdoptionDetailScreen({
    super.key,
    required this.id,
    required this.service,
  });
  final String id;
  final AdoptionsService service;

  Future<void> _copy(BuildContext context, String value, String message) async {
    try {
      await Clipboard.setData(ClipboardData(text: value));
      if (context.mounted) showMessage(context, message);
    } catch (_) {
      if (context.mounted) {
        showMessage(
          context,
          'No se pudo copiar. Mantén pulsado el texto para seleccionarlo.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Detalle de adopción')),
    body: AsyncResource<AdoptionPublication>(
      load: () => service.find(id),
      builder: (context, item, reload) {
        final pet = item.pet;
        final place = item.establishment;
        return RefreshIndicator(
          onRefresh: () async {
            reload();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              if (pet.photos.isEmpty)
                const AnimalImage(height: 250)
              else
                SizedBox(
                  height: 285,
                  child: PageView.builder(
                    itemCount: pet.photos.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        children: [
                          AnimalImage(
                            url: pet.photos[index].url,
                            height: 250,
                            label:
                                'Foto ${index + 1} de ${pet.photos.length} de ${pet.nombre}',
                          ),
                          const SizedBox(height: 8),
                          Text('Foto ${index + 1} de ${pet.photos.length}'),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                pet.nombre,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '${pet.species?.nombre ?? 'Mascota'} · ${pet.sexLabel} · ${pet.ageLabel}',
              ),
              const SizedBox(height: 20),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Conoce su historia',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(item.description),
                    const SizedBox(height: 16),
                    Text('Raza: ${pet.razaNombre ?? 'Sin especificar'}'),
                    Text('Color: ${pet.color ?? 'Sin especificar'}'),
                    Text(
                      'Peso: ${pet.pesoKg == null ? 'Sin especificar' : '${pet.pesoKg} kg'}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Requisitos para adoptar',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item.requirements?.trim().isNotEmpty == true
                          ? item.requirements!
                          : 'Consulta los requisitos directamente con el establecimiento.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Contacta al establecimiento',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      place.name,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(place.typeLabel),
                    const SizedBox(height: 12),
                    SelectableText('Teléfono: ${place.phone}'),
                    OutlinedButton.icon(
                      onPressed: () =>
                          _copy(context, place.phone, 'Teléfono copiado.'),
                      icon: const Icon(Icons.copy_outlined),
                      label: const Text('Copiar teléfono'),
                    ),
                    const SizedBox(height: 12),
                    SelectableText('Dirección: ${place.address}'),
                    OutlinedButton.icon(
                      onPressed: () =>
                          _copy(context, place.address, 'Dirección copiada.'),
                      icon: const Icon(Icons.copy_outlined),
                      label: const Text('Copiar dirección'),
                    ),
                    if (place.hours?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 12),
                      Text('Horario: ${place.hours}'),
                    ],
                    const SizedBox(height: 16),
                    const Text(
                      'Comunícate con la veterinaria o refugio para conocer el proceso. La entrega se registra directamente con el establecimiento.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
