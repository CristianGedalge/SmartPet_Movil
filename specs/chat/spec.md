# Chat ciudadano

Contactar al autor de alertas y avistamientos desde sus detalles, sin pedir ni exponer teléfono/correo. El backend deduce destinatario; autochat devuelve mensaje legible. Acceso a bandeja Mensajes desde icono superior, manteniendo cinco pestañas existentes. Cada ficha abre/reutiliza conversación privada; bandeja muestra interlocutor, contexto, último texto y pendientes.

Detalle: mensajes propios/recibidos, fechas, texto hasta 4000 caracteres, cargar anteriores, envío bloqueado mientras pendiente. Guardar texto e ID de envío ante error para reintentar sin duplicar; limpiar solo tras confirmación. Actualizar desde eventos Socket.IO y recuperar mensajes perdidos al reconectar. Estado de conexión y errores legibles. Lectura solo cuando pantalla de conversación está visible y mensaje cargado. Sin adjuntos, push ni acciones desde web.

Conexión autenticada por token de sesión a namespace /chat del origen de API_URL. Suspender/desconectar al pasar a segundo plano, cerrar pantalla o sesión; reconectar y recuperar al volver. Sin temporizadores de sondeo. Descartar respuestas tardías y recursos al desmontar. No generar APK.
