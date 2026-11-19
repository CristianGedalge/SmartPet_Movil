# Diseño

`PetPosterService` compone el PNG mediante `dart:ui`. Descarga únicamente la foto principal mediante el cliente HTTP ya disponible, limita la espera y usa un marcador si la descarga o decodificación falla.

`PetPosterScreen` recibe el modelo `Pet`, inicia la generación, presenta progreso y muestra el PNG dentro de una vista ampliable. Permite compartir, guardar mediante las aplicaciones disponibles en el dispositivo y volver a generar el afiche.

`PetPosterShareService` escribe el PNG en el directorio temporal de la aplicación, lo entrega a `share_plus`, define un nombre seguro para el archivo y abre la hoja nativa de compartir. La posición del botón se usa como ancla en iPad. El archivo temporal se elimina después de dar tiempo a la aplicación receptora para leerlo.

`PetDetailScreen` navega a `PetPosterScreen` desde un botón secundario. No se modifica `PetsService` porque no existe una operación remota.
