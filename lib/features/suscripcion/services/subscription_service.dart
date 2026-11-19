import '../../../shared/models/json_values.dart';
import '../../../shared/services/api_client.dart';
import '../models/plan_offer.dart';

class SubscriptionService {
  const SubscriptionService(this.api);
  final ApiClient api;

  Future<List<PlanOffer>> plans() async {
    final data = await api.request('GET', '/pagos/planes');
    if (data is! List) {
      throw const ApiFailure(
        'No pudimos cargar los planes. Intenta nuevamente.',
      );
    }
    return data.map((item) => PlanOffer.fromJson(jsonObject(item))).toList();
  }

  Future<JsonObject> simulatePayment({
    required PlanOffer plan,
    required String holder,
    required String cardNumber,
    required int expiryMonth,
    required int expiryYear,
    required String cvv,
  }) async => jsonObject(
    await api.request(
      'POST',
      '/pagos',
      body: {
        'planId': plan.id,
        'titular': holder.trim(),
        'numeroTarjeta': cardNumber.replaceAll(RegExp(r'\D'), ''),
        'mesExpiracion': expiryMonth,
        'anioExpiracion': expiryYear,
        'cvv': cvv,
      },
    ),
  );
}
