# SmartPet: aplicación ciudadana

Primera versión Flutter conectada a los endpoints existentes de `smartpet_api`. Usa el logo del proyecto y el verde `#00B894`.

## Funciones implementadas

- Registro ciudadano e inicio de sesión. El registro no envía `rol` ni `establecimiento`. Las cuentas ADMIN y ENCARGADO no ingresan a este portal.
- Sesión persistente con `flutter_secure_storage`, validación del perfil al abrir y cierre automático ante un 401 de la sesión vigente. Un fallo temporal de conexión permite reintentar sin borrar el token.
- Inicio con accesos y alertas reales de la comunidad, sin estadísticas inventadas.
- Mascotas propias: lista paginada, detalle, registro con fotos, edición de datos y desactivación confirmada.
- Fotografías: cámara/galería, 1 a 5 imágenes, JPEG/PNG/WebP de hasta 5 MiB. Validación por bytes y multipart `fotos`; agregar y eliminar fotos son operaciones separadas. Se conserva al menos una foto.
- Alertas: comunidad activa y mis alertas/historial, detalle, publicación para una mascota propia, edición de alertas activas, resolución y cancelación confirmadas.
- Ubicación mediante mapa o GPS opcional. Las coordenadas se envían internamente; no hay campos numéricos para el usuario.
- Perfil: nombre, apellido, teléfono, cambio opcional de contraseña y cierre de sesión.
- Estados de carga, listas vacías, errores, reintentos y paginación `limit`/`offset`.

No se agregaron pantallas de adopciones, notificaciones, avistamientos ni recuperación de contraseña: el backend actual no ofrece esos contratos. Cloudinary se utiliza únicamente desde la API.

## Ejecutar

Desde `smartpet_movil`:

```bash
flutter pub get
flutter run --dart-define-from-file=.env
```

Se creó `.env` con la configuración pública de `.env.example` si todavía no existía. Para otro entorno, copia ese ejemplo y ajusta:

```dotenv
API_URL=http://10.0.2.2:3000/api/v1
MAP_STYLE_URL=https://tiles.openfreemap.org/styles/liberty
```

- Android Emulator: `10.0.2.2` apunta a la computadora que ejecuta el backend.
- Teléfono físico: usa la IP local de la computadora (misma red) o una API HTTPS accesible. `localhost` apunta al propio teléfono. El servidor y el firewall deben permitir la conexión al puerto de la API.
- Simulador iOS: configura la URL de la API en el equipo donde corre el simulador.
- El backend debe tener sus migraciones aplicadas, roles/especies y Cloudinary configurados para guardar fotografías.
- Una cuenta ciudadana se puede crear desde la app. No se incluyen usuarios ni contraseñas predeterminados.

Las variables se incorporan al compilar; reinicia la ejecución al cambiarlas. No son secretos: nunca pongas JWT_SECRET ni credenciales de Cloudinary en la app. No se modificaron los `.env` de API o web.

## Plataformas y permisos

Objetivo principal: Android e iOS. Android mínimo API 24; iOS mínimo 15.5 por el plugin instalado. El mapa también admite navegador para previsualización; el backend debe permitir el origen web mediante CORS. Los mapas no se implementan para Windows/Linux/macOS.

Android declara Internet y ubicación mientras se usa la app. La galería utiliza el selector del sistema, sin permisos generales de almacenamiento. El tráfico HTTP local está habilitado solo en debug y las copias de seguridad automáticas están deshabilitadas para proteger el almacenamiento cifrado.

iOS incluye los motivos de acceso a cámara, fototeca y ubicación. Se permite red local para desarrollo; producción requiere HTTPS. La compilación iOS requiere macOS y Xcode.

MapLibre administra el controlador y la vista nativa al desmontarse. El componente cancela su temporizador de carga e ignora resultados después de salir. GPS se solicita solo al pulsar el botón; no hay seguimiento en segundo plano. Se mantiene la atribución del mapa.

Configuración del mapa según [MapLibre Flutter](https://maplibre.org/flutter-maplibre-gl/getting-started/) y [OpenFreeMap Liberty](https://openfreemap.org/quick_start/).

## Estructura

```text
lib/
  app.dart                       # Raíz de sesión y navegación ciudadana
  config/                        # URLs y tema
  shared/
    services/api_client.dart     # JSON, multipart, Bearer y errores HTTP
    controllers/                 # Paginación y protección frente a respuestas antiguas
    widgets/                     # Componentes, recursos asíncronos y mapa
  features/
    auth/                        # Sesión segura, ingreso, registro y perfil
    inicio/                      # Inicio con publicaciones reales
    mascotas/                    # Modelos, servicios, formularios y fotos
    alertas/                     # Publicaciones, historial, mapa y cierres
specs/ciudadano/                  # Alcance, diseño y tareas
```

## Verificación

```bash
flutter analyze
flutter test
flutter build apk --debug --dart-define-from-file=.env
```

Las pruebas utilizan transporte y almacenamiento sustituidos: comprueban contratos, formularios, autenticación, roles, expiración, paginación, multipart y navegación sin modificar la base de datos real. La validación de cámara, galería, GPS y representación nativa del mapa debe completarse en un dispositivo o emulador Android/iOS.

Estado verificado: 41 pruebas aprobadas y `flutter analyze` sin problemas. Avistamientos integrado con API verificada mediante PostgreSQL aislado. No se generó APK en esta entrega; quedan pendientes las pruebas manuales de cámara, galería y mapa/GPS en dispositivo.

Mascotas y avistamientos comparten un selector de fotografías con contador, vistas previas, foto principal y eliminación. Se limita la selección a los espacios disponibles, se explican los errores de permisos y se bloquean acciones simultáneas mientras se preparan las imágenes. Las subidas multipart tienen un tiempo de espera de 120 segundos; las peticiones normales conservan 45 segundos.

Para producción configura API_URL con HTTPS y una firma de publicación propia. Esta entrega no publica la aplicación ni configura una firma de producción.

En Windows, Gradle usa dos trabajadores y un límite de memoria de 3 GiB. Se deshabilitó la caché incremental de Kotlin porque los paquetes están en C: y el proyecto en D:, combinación que provocaba `this and base files have different roots` al compilar los plugins. Esto puede hacer más lenta la recompilación de Kotlin, pero evita ese fallo entre unidades.


## Avistamientos

Nueva pestaña Avistamientos: Comunidad y Mis avistamientos, publicación con especie, descripción, referencia, fecha/hora, mapa y fotos; detalle con edición y gestión de fotos del autor. Los cierres/cancelaciones conservan historial y ocultan la publicación de Comunidad. Sin IA ni coincidencias automáticas.

Requiere aplicar en el backend `npm run migration:run` y reiniciar el servidor si no usa watch. Después hacer Hot Restart del móvil. No cambian API_URL ni MAP_STYLE_URL y no hay paquetes nuevos. Especificación y contrato en `specs/avistamientos/` y `smartpet_api/specs/avistamientos/`.
