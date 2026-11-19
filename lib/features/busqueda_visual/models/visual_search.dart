import '../../../shared/models/json_values.dart';
import '../../avistamientos/models/sighting.dart';

class VisualMatch {
  VisualMatch.fromJson(JsonObject json)
    : sighting = Sighting.fromJson(jsonObject(json['avistamiento']));
  final Sighting sighting;
}

class VisualSearchResult {
  VisualSearchResult.fromJson(JsonObject json)
    : notice = requiredString(json, 'aviso'),
      failedPhotos = integerValue(json['fotosNoProcesadas']) ?? 0,
      matches = List.unmodifiable(
        (json['resultados'] as List).map(
          (item) => VisualMatch.fromJson(jsonObject(item)),
        ),
      );
  final String notice;
  final int failedPhotos;
  final List<VisualMatch> matches;
}
