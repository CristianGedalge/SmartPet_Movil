# Diseño móvil

Feature chat con modelos Conversation/ChatMessage/MessagePage, ChatService REST y ChatRealtime Socket.IO inyectable para pruebas. El cliente usa websocket, auth token, forceNew/disableAutoConnect para evitar compartir credenciales/caché entre sesiones y dispose explícito. Stream solo emite cambios de conexión/ID de conversación. La reconexión funciona mientras la pantalla está activa.

Bandeja ChatInboxScreen paginada y actualizable con AppCards; ChatScreen detalle cronológico y cargar anteriores. Recuperación tras evento/reconexión mediante cursor despuesDe hasta completar hayMas; deduplicar por ID y preservar historial anterior. Antes de marcar lectura enviar el último mensaje cargado con PATCH lectura. Mostrar error 404 sin remitentes inventados. Entrada en SafeArea sobre teclado, hasta 4000 caracteres. ID aleatorio UUIDv4 generado con Random.secure; reusar para reintentos del mismo texto y renovar si cambia texto.

ContactAuthorButton encapsula apertura/bloqueo/error y navegación usando la API existente de AlertsService/SightingsService. Propiedad de alerta no siempre figura en respuesta pública: backend protege autochat. Botón en avistamiento solo para esPropio=false; alerta solo fuera de gestión propia. Las rutas siguen dentro del Navigator privado de SmartPetApp. Bandeja accesible desde AppBar sin alterar pestañas. Perfil conserva avatar.

Dependencia socket_io_client autorizada expresamente. Sin variables de entorno nuevas ni secretos en móvil. No mostrar ni solicitar datos del adoptante.
