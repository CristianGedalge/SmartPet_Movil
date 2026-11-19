# Spec: verificacion de correo movil

## Objetivo

Permitir que un ciudadano confirme el correo usado para registrarse antes de entrar a SmartPet.

## Flujo

- Registro o inicio de sesion pendiente abre una pantalla de codigo sin perder el correo.
- La pantalla explica que se envio un codigo de seis digitos, permite verificarlo y solicitar otro.
- Al verificar, la app guarda el JWT y entra a la aplicacion como en un inicio de sesion normal.
- Los errores de red, codigo vencido e intentos incorrectos se muestran en lenguaje claro.

## Criterios de aceptacion

- La app no intenta leer `access_token` si la respuesta indica verificacion pendiente.
- Solo se puede enviar un codigo numerico de seis digitos.
- El reenvio tiene una cuenta regresiva visible de 60 segundos.
- Volver desde la verificacion regresa al formulario de acceso.

