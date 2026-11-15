# AGENTS.md — `smartpet_movil`

Aplicación móvil de SmartPet: Flutter + Dart, consumo de API REST (`smartpet_api` bajo `/api/v1`) con autenticación JWT.

## Metodología (SDD)

No escribir código sin spec previa. `specs/` es la fuente de verdad.

1. `specs/<modulo>/spec.md`: objetivo, requisitos, flujos de usuario y criterios de aceptación.
2. `specs/<modulo>/design.md`: pantallas, widgets, estado, modelos y endpoints consumidos.
3. `specs/<modulo>/tasks.md`: tareas pequeñas y ordenadas.
4. Implementar y verificar contra los criterios de aceptación.

- No inventar pantallas, campos ni llamadas a endpoints que no estén en la spec.
- Si algo es ambiguo, preguntar al usuario.
- Bugfixes pequeños y ajustes visuales menores sin cambio de flujo no requieren spec nueva.

## Estructura

- `lib/config/` — configuración global (tema, rutas, variables de entorno / constantes de API)
- `lib/shared/` — widgets reutilizables, utilidades y servicios comunes (cliente HTTP, almacenamiento seguro de token)
- `lib/features/<modulo>/` — un directorio por dominio (`models/`, `services/`, `providers/` o `bloc/`, `screens/`, `widgets/`)
- `test/` — pruebas unitarias y de widgets
- `specs/` — specs, designs y tasks

## Comandos

```bash
flutter pub get
flutter run
flutter analyze
flutter test
flutter build apk
```

## Convenciones

- Consumir únicamente los contratos definidos en `smartpet_api` (`/api/v1`).
- Separar la UI (`screens/`, `widgets/`) de la lógica de estado y llamadas HTTP (`services/`).
- Manejar siempre los estados de carga (`loading`), éxito (`data`) y error (`error`) en las pantallas que consultan la API.
- Guardar el `access_token` JWT de forma segura y enviarlo en el header `Authorization: Bearer <token>`.
- Variables de entorno o URL base configuradas en `.env` (documentadas en `.env.example`); nunca commitear `.env` ni credenciales.
- Pedir confirmación antes de agregar paquetes en `pubspec.yaml`.

## Definition of Done

1. Cumple la spec y el design.
2. Maneja validaciones de formulario y errores de red/API amigables en español.
3. `flutter analyze` y `flutter test` pasan sin errores.
