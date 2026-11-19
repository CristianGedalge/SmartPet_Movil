# Catálogo ciudadano de adopciones

El ciudadano consulta las publicaciones disponibles de veterinarias y refugios desde el móvil: listado paginado, actualización, detalle con fotos, características, descripción y requisitos. El detalle muestra nombre, tipo, dirección, teléfono y horario institucional. Permitir copiar teléfono y dirección con las herramientas de Flutter existentes; no añadir paquetes.

Solo consumir GET /adopciones y GET /adopciones/:id públicos. Sin registro de solicitudes, adopción desde el móvil, modificaciones ni datos del adoptante. La entrega la registra el encargado en la web. Si una publicación deja de estar disponible, mostrar mensaje claro y permitir volver al catálogo y actualizarlo.

Acceso desde Inicio y pestaña Adopciones. Mantener cinco destinos inferiores: Inicio, Mascotas, Alertas, Avistamientos, Adopciones. Mi perfil sigue accesible desde el avatar superior y se abre en la navegación privada, descartándose al cerrar sesión. Conservar todos los flujos anteriores.

Aceptación: carga/vacío/error/reintento; paginación sin perder resultados ante fallo; detalle recarga desde la API y maneja 404; contacto seleccionable/copiar; fotos ausentes o fallidas tienen reemplazo; ausencia de acciones y campos privados del encargado/adoptante; rutas se eliminan al salir. Sin APK ni cambios de env/backend.
