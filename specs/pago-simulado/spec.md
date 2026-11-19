# Spec: pago simulado movil

## Objetivo

Presentar planes comprensibles y permitir demostrar el pago con una tarjeta de prueba desde el movil.

## Flujo

- Cada plan muestra descripcion, precio, duracion y beneficios con nombres claros.
- Al elegir un plan se abre un resumen y un formulario de tarjeta.
- La pantalla avisa que no se cobra dinero real y permite cargar la tarjeta aprobada de prueba.
- Los campos se validan antes de enviar y el resultado exitoso actualiza la suscripcion.

## Criterios de aceptacion

- El formulario solicita titular, numero, vencimiento y CVV con teclados y limites adecuados.
- El usuario puede llenar la tarjeta aprobada con una accion visible.
- El numero se muestra agrupado y el CVV oculto.
- Los errores se muestran en lenguaje amigable y los datos no se conservan al salir.

