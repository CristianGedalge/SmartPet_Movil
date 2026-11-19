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
- Adopciones: catálogo público paginado, detalle con galería de fotos, características, requisitos y contacto institucional; permite copiar teléfono y dirección.
- Chat privado: contactar al autor desde alertas/avistamientos, bandeja Mensajes, historial, mensajes pendientes y actualizaciones WebSocket autenticadas.
- Estados de carga, listas vacías, errores, reintentos y paginación `limit`/`offset`.

No se agregaron notificaciones ni recuperación de contraseña. Cloudinary se utiliza únicamente desde la API. El móvil consulta adopciones; las entregas y los datos del adoptante se gestionan desde el portal web del encargado.

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

Estado verificado: 55 casos comprobados (suite de 54 y una regresión adicional de chat) y `flutter analyze` sin problemas. APIs verificadas mediante PostgreSQL aislado y clientes Socket.IO reales. No se generó APK en esta entrega; quedan pendientes las pruebas manuales de cámara, galería, mapa/GPS y comunicación entre teléfonos en dispositivo.

Mascotas y avistamientos comparten un selector de fotografías con contador, vistas previas, foto principal y eliminación. Se limita la selección a los espacios disponibles, se explican los errores de permisos y se bloquean acciones simultáneas mientras se preparan las imágenes. Las subidas multipart tienen un tiempo de espera de 120 segundos; las peticiones normales conservan 45 segundos.

Para producción configura API_URL con HTTPS y una firma de publicación propia. Esta entrega no publica la aplicación ni configura una firma de producción.

En Windows, Gradle usa dos trabajadores y un límite de memoria de 3 GiB. Se deshabilitó la caché incremental de Kotlin porque los paquetes están en C: y el proyecto en D:, combinación que provocaba `this and base files have different roots` al compilar los plugins. Esto puede hacer más lenta la recompilación de Kotlin, pero evita ese fallo entre unidades.


## Avistamientos

Nueva pestaña Avistamientos: Comunidad y Mis avistamientos, publicación con especie, descripción, referencia, fecha/hora, mapa y fotos; detalle con edición y gestión de fotos del autor. Los cierres/cancelaciones conservan historial y ocultan la publicación de Comunidad. Sin IA ni coincidencias automáticas.

Requiere aplicar en el backend `npm run migration:run` y reiniciar el servidor si no usa watch. Después hacer Hot Restart del móvil. No cambian API_URL ni MAP_STYLE_URL y no hay paquetes nuevos. Especificación y contrato en `specs/avistamientos/` y `smartpet_api/specs/avistamientos/`.

## Adopciones

La pestaña Adopciones y el acceso Explorar adopciones del Inicio consultan `GET /api/v1/adopciones` y `GET /api/v1/adopciones/:id`, sin enviar JWT. El catálogo se actualiza deslizando hacia abajo, al reintentar y al volver del detalle; permite cargar más resultados. Una publicación retirada o adoptada muestra un aviso de que ya no está disponible.

Se mantienen cinco pestañas inferiores. El perfil se abre desde el avatar superior (Mi perfil), con regreso y descarte de la ruta al cerrar sesión. El contacto institucional es seleccionable y puede copiarse; no se abre automáticamente una llamada ni una aplicación externa. Sin postulaciones ni registro de adopciones desde el móvil. Especificación en `specs/adopciones/`. No requiere paquetes ni variables nuevos. Hacer Hot Restart para ver la nueva navegación.

## Chat

Desde una alerta o avistamiento de la comunidad, pulsa Contactar al autor. El backend deduce al destinatario y reutiliza la conversación. El autor responde desde Mensajes (icono de chat superior). Solo los participantes leen o envían; no se muestran teléfonos ni correos. Las conversaciones anteriores siguen disponibles al cerrar una publicación mientras los usuarios sigan activos.

El historial se guarda por HTTP en `/api/v1/chat/conversaciones`; los avisos Socket.IO del namespace `/chat` actualizan el móvil al instante. `socket_io_client` se añadió con autorización. El token va en el handshake, no en URL. Al reconectar se recuperan mensajes perdidos por páginas y se eliminan duplicados; un reintento de envío conserva el UUID y el borrador. Conexiones, listeners y temporizadores de actualización se liberan al salir, cerrar sesión o pasar a segundo plano.

Usa el mismo host/puerto de `API_URL`; con USB basta `adb reverse tcp:3000 tcp:3000`. Reiniciar backend y hacer `flutter pub get` y Hot Restart. No hay variables nuevas. No incluye adjuntos, indicadores de escritura ni notificaciones push con app cerrada. Especificación en `specs/chat/` y contrato backend en `smartpet_api/docs/chat.md`.
