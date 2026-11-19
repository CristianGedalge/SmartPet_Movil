# Verificación y mantenimiento

Los términos y la política se incluyen como asset en `assets/legal/legal.json` para poder leerlos sin conexión. La copia debe ser idéntica al JSON canónico del frontend web. La constante `legalVersion` y la API deben coincidir.

El registro requiere las dos casillas, inicialmente desmarcadas. Abrir y volver de un documento conserva los datos y no implica aceptación. Los enlaces también están disponibles en ingreso y perfil. El login de cuentas existentes no exige nueva aceptación.

`test/auth_screen_test.dart` verifica el bloqueo, aceptación parcial, navegación sin perder el borrador y envío de ambas aceptaciones con su versión. Ejecutar `flutter analyze` y `flutter test`; no es necesario generar APK.

El responsable y contacto confirmados son Equipo SmartPet y cristian.gedalge2018@gmail.com. Contrato y persistencia: `smartpet_api/docs/legal.md`.
