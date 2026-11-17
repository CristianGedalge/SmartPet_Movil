# Aplicación ciudadana SmartPet

Primera versión funcional Flutter para Android/iOS sobre las APIs existentes. Conservar identidad SmartPet (verde #00B894, fondos claros, tarjetas redondeadas, logo SVG existente). Interfaz en español, adaptable a pantallas pequeñas y texto ampliado, sin estadísticas ni funciones ficticias.

Flujos: registro CIUDADANO sin rol ni establecimiento, login, sesión persistente segura, validación de perfil al restaurar, logout y expiración 401. Rechazar sesiones ADMIN/ENCARGADO en este portal. No implementar recuperación de contraseña: no existe endpoint.

Navegación Inicio, Mascotas, Alertas y Perfil. Inicio ofrece accesos a mascotas y publicaciones reales. Mascotas: lista paginada propia, detalle, alta con 1–5 fotos, edición de datos, agregar/eliminar fotos mediante endpoints separados, baja lógica confirmada. Especies del servidor. No inventar adopciones, avisos de avistamiento, notificaciones ni IA.

Alertas: publicaciones activas y mis alertas/historial paginados, detalle, publicar para mascota propia, editar ACTIVA, resolver o cancelar con confirmación. Mostrar fecha y estado amigables. El cliente debe recordar el contexto propio/público sin inferir propiedad de una respuesta pública que omite usuarioId. Abrir publicaciones ajenas no muestra edición ni cierres. Fechas no futuras y zona UTC en API.

Ubicación: MapLibre + OpenFreeMap Liberty sin clave, selección tocando el mapa y GPS opcional. Coordenadas solo internas, nunca campos ni texto numérico para el ciudadano. No preconfirmar centro inicial como ubicación seleccionada. Respetar atribuciones. Manejar permisos denegados, GPS apagado, carga y error; liberar recursos al salir.

Perfil: datos propios, cambio de contraseña opcional validado y logout. Manejar loading/error/empty/reintento y errores parciales al guardar datos y fotos. No afirmar que se guardaron todos los cambios si falló una operación posterior. Limitar fotos por tamaño y cantidad y validar formato antes de enviarlas; Cloudinary solo se contacta desde backend.

Configuración local en .env documentada con .env.example; solo URL de API y estilo, sin secretos. Emulador Android usa host 10.0.2.2; móvil físico requiere IP local o HTTPS accesible. No cambiar contratos ni variables de los proyectos API/web. HTTP de desarrollo permitido solo en builds de depuración; release requiere HTTPS.

Criterios: navegación y formularios reales, ausencia de credenciales en logs, token seguro, aislamiento de roles, validaciones españolas, peticiones JSON/multipart correctas, recuperación de errores de red, pruebas de modelos/cliente/sesión/widgets, flutter analyze y flutter test correctos. Intentar APK y documentar limitaciones del entorno.

## Recuperaci?n de permisos de ubicaci?n

Al pulsar Usar mi ubicaci?n se solicita permiso mientras se usa la app. Si el GPS est? apagado se ofrece abrir los ajustes de ubicaci?n; si el permiso est? bloqueado se ofrecen los ajustes de la app. Al regresar, el usuario vuelve a pulsar el bot?n. La selecci?n manual sigue disponible y el GPS no depende de que termine de cargar el mapa. No se solicita ubicaci?n al abrir la pantalla ni en segundo plano.
