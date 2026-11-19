# Afiche de mascota

## Objetivo

Permitir que el ciudadano genere desde la ficha de una mascota un afiche PNG con su fotografía principal y datos descriptivos. La generación ocurre localmente y no crea llamadas nuevas al backend.

## Reglas

- El acceso se muestra en la ficha de una mascota activa.
- El afiche es informativo y no afirma que la mascota esté perdida.
- Incluye nombre, especie, sexo, edad, raza y color cuando estén disponibles.
- Usa la fotografía principal; si no puede descargarse, genera el afiche con un marcador visual.
- No incluye correo, teléfono, coordenadas, identificadores internos ni datos del propietario.
- Debe mostrar estados de generación, resultado y error con mensajes comprensibles.
- La salida es PNG vertical de 1080 por 1350 píxeles.
- El usuario puede abrir la hoja nativa del dispositivo para compartir o guardar el PNG.
- El archivo compartido usa un nombre reconocible basado en el nombre de la mascota.

## Criterios de aceptación

- La ficha ofrece la acción `Generar afiche`.
- La vista previa se abre sin modificar la mascota.
- El afiche puede generarse aunque la foto remota falle.
- La imagen resultante tiene firma PNG y dimensiones 1080x1350.
- La acción `Compartir o guardar` solo se habilita cuando el PNG está listo.
- No se agregan endpoints ni se almacena el afiche en el backend.
