# Diseño

## Archivos

- `models/agent_message.dart`: roles y serialización.
- `services/agent_chat_service.dart`: contrato HTTP autenticado.
- `screens/agent_chat_screen.dart`: conversación local y estados visuales.

## Flujo

El botón `Agente SmartPet` abre una ruta privada. La pantalla muestra una bienvenida local que no se envía al modelo. Al enviar, añade temporalmente el mensaje, llama `POST /agente/chat` y agrega la respuesta. Si falla, restaura el texto en el campo y muestra `Volver a intentar`.

No se requiere paquete, permiso, variable de entorno móvil ni almacenamiento adicional.
