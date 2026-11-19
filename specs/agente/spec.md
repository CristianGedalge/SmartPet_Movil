# Chat con Agente SmartPet

## Objetivo

Permitir que el ciudadano consulte desde el móvil un asistente de SmartPet respaldado por Amazon Bedrock a través de la API.

## Requisitos

- Acceso desde la barra superior de la sesión ciudadana.
- Mostrar bienvenida y aviso de que las respuestas pueden equivocarse.
- Conservar el historial mientras la pantalla permanezca abierta.
- Enviar como máximo los últimos once mensajes alternados.
- Mostrar carga, error y acción de reintento.
- Conservar el texto del usuario cuando falle el envío.
- No incluir claves de AWS ni configuración de Bedrock en la aplicación.
- No persistir conversaciones en el dispositivo.

## Criterios de aceptación

1. El usuario puede abrir el agente, escribir y recibir una respuesta.
2. Durante la petición no puede duplicar envíos.
3. Ante un error, el texto permanece editable y puede reintentarse.
4. El historial enviado respeta el contrato `/agente/chat`.
