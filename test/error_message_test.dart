import 'package:flutter_test/flutter_test.dart';
import 'package:smartpet_movil/shared/services/api_client.dart';
import 'package:smartpet_movil/shared/utils/error_message.dart';

void main() {
  test('conserva mensajes funcionales preparados para el usuario', () {
    expect(
      userErrorMessage(const ApiFailure('Revisa los datos ingresados.')),
      'Revisa los datos ingresados.',
    );
  });

  test('oculta los detalles de excepciones inesperadas', () {
    expect(
      userErrorMessage(
        const FormatException('token inválido en respuesta JSON'),
        fallback: 'No pudimos cargar la información.',
      ),
      'No pudimos cargar la información.',
    );
  });
}
