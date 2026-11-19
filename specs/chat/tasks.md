# Tareas

- [x] Servicio/modelos REST y conexión WebSocket autenticada.
- [x] Bandeja, conversación y contacto desde publicaciones.
- [x] Recuperación, lectura, reintentos y liberación de recursos.
- [x] Pruebas y analyze; documentación y commit en dev, sin APK ni push.

Verificado: suite completa de 54 pruebas y posteriormente 6 del chat con una nueva regresión de envío concurrente (55 casos únicos); analyze sin problemas. Transporte y conexión sustituidos en widgets; backend validado con clientes Socket.IO reales y PostgreSQL. Pendiente prueba manual entre dos cuentas/dispositivos. No se generó APK ni se modificó env.
