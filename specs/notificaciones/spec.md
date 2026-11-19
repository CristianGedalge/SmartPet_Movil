# Notificaciones de sesión

## Objetivo

Solicitar permiso de notificaciones después de autenticar al ciudadano, enviar el token FCM al backend y recibir avisos de bienvenida y cierre de sesión.

## Reglas

- No solicitar permiso antes de un login o registro exitoso.
- Rechazar o no poder solicitar el permiso no bloquea la sesión.
- Enviar al backend el token actual cuando el permiso permite notificaciones.
- Antes del cierre manual, solicitar al backend el aviso para ese token.
- Un error de red o Firebase no impide cerrar sesión.
- No enviar la solicitud de cierre cuando la sesión expira o es rechazada por el backend.
- Mostrar en primer plano los mensajes remotos mediante una notificación local.

## Criterios de aceptación

- Android solicita permiso del sistema después del login exitoso.
- Login y logout continúan funcionando si el usuario rechaza el permiso.
- El identificador no se imprime ni se muestra en la interfaz.
- Login y logout usan el token del mismo dispositivo sin almacenarlo en el backend.
- Las pruebas pueden sustituir Firebase mediante una interfaz sin inicializar plugins nativos.

