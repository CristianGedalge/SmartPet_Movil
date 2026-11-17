# Diseño

Feature-based: lib/config (ApiConfig, tema); lib/shared (ApiClient, TokenStorage, componentes y mapa); lib/features/auth (usuario, servicio, SessionController y pantallas); mascotas (modelos, servicio, listas/formulario/detalle); alertas (modelos, servicio, lista/formulario/detalle); profile (edición); home (shell e inicio). Estado con ChangeNotifier y StatefulWidget, sin agregar librería de estado innecesaria.

Navegación Material Navigator y NavigationBar con cuatro destinos. Pantallas de detalle/formulario se abren desde shell; root de sesión debe retirar rutas protegidas al expirar la sesión. Tema Material 3 verde, logotipo SVG compartido, tarjetas blancas y accesos con iconos del SDK; sin imágenes de mascotas simuladas. Fotos reales desde API y placeholders con icono.

Contratos: POST /auth/login, POST /auth/register (ciudadano), GET/PATCH /auth/profile; GET /especies; POST /mascotas multipart, GET /mascotas/mis-mascotas, GET/PATCH/DELETE /mascotas/:id, POST /mascotas/:id/fotos multipart, DELETE /mascotas/:id/fotos/:fotoId; los siete endpoints de alertas-extravio existentes. Siempre prefijo /api/v1 y camelCase. Listas limit/offset, sin asumir total ni estadísticas globales. Alertas públicas no requieren JWT; privadas sí.

ApiClient abstrae JSON y multipart, timeout y ApiException con mensajes seguros; no imprimir tokens. Capturar token de cada solicitud y solo invalidar esa sesión en 401 para evitar que una respuesta antigua cierre un nuevo login. AuthService valida rol CIUDADANO antes de persistir JWT. SessionController distingue restauración, error recuperable de red y sesión inválida; no borrar token por fallo temporal de conexión. TokenStorage tendrá implementación segura por plugin y fake en pruebas.

Galería/cámara mediante image_picker, 1–5 fotos de hasta 5 MiB, JPEG/PNG/WebP detectados por bytes; no confiar solo en extensión. Permitir una foto restante; primera principal indicada por servidor. Editar datos y fotos son operaciones separadas y sus errores se comunican por separado. Recargar recursos tras guardar o cerrar alerta. Bloquear envíos y navegación destructiva mientras se guarda; confirmación para bajas y cierres.

Mapa compartido con MapLibre, estilo de .env, círculos/marcador nativo y confirmación explícita; GPS mediante geolocator solo al solicitarlo, sin seguimiento en segundo plano. Mostrar ubicación descriptiva (punto seleccionado), no coordenadas. Proveedor de mapa sustituible en tests para no necesitar plataforma nativa. Preferir reconstruir la pantalla del mapa al entrar/salir y dejar que el widget libere su controller.

Paquetes autorizados por el usuario e instalados: http, http_parser, flutter_secure_storage, image_picker, maplibre_gl, geolocator, flutter_svg y flutter_localizations del SDK. Configuración mediante --dart-define-from-file=.env, sin incluir archivos de secretos como assets. Android mínimo API 24 e iOS 15.5 conforme al plugin MapLibre instalado.

Android: permiso INTERNET, ubicación while-in-use y tráfico HTTP solo debug; fotos mediante picker del sistema, sin permisos generales de almacenamiento. iOS: descripciones de cámara, fototeca y ubicación, sin permisos de audio ni ubicación de fondo. Persistencia Keychain/almacenamiento cifrado. API_URL HTTPS requerido en release; preparar Android debug APK para pruebas, sin publicación ni firma de producción.

LocationButton separa la solicitud GPS del mapa nativo: controla carga, errores y acceso expl?cito a ajustes mediante geolocator. Entrega Position al mapa, que actualiza el punto y centra la c?mara cuando est? lista. En navegador se indican los permisos del sitio sin intentar abrir ajustes nativos.
