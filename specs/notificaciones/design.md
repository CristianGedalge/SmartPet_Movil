# Diseño

`PushNotificationService` inicializa Firebase cuando las cuatro opciones públicas están configuradas, escucha mensajes en primer plano y utiliza `flutter_local_notifications` para mostrarlos. Después de autenticar, solicita permiso, obtiene el Firebase Installation ID y llama al backend. Antes del logout manual llama al endpoint de cierre.

`SessionNotifications` desacopla `Session` de Firebase. `Session.authenticate` ejecuta el registro después de persistir el JWT. `Session.logout` conserva el JWT mientras intenta el cierre remoto y luego siempre elimina la sesión local. Los cierres automáticos usan `notifyDevice: false`.

Configuración pública por `--dart-define`: `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_MESSAGING_SENDER_ID` y `FIREBASE_PROJECT_ID`. Si alguna falta, la función queda deshabilitada sin afectar la aplicación.

