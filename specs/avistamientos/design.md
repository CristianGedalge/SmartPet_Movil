# Diseño

features/avistamientos/{models,services,screens}; Sighting tipado y SightingsService sobre ApiClient. Reutilizar paginación, AsyncResource, PhotoPicker y validación de imágenes, Species y LocationMap existentes. NavigationBar con cinco destinos; Perfil cambia al índice 4. Modelo con esPropio del servidor, sin datos del reportante.

Contratos en smartpet_api/specs/avistamientos/design.md. Publicación multipart; edición JSON; fotos se gestionan separadamente en detalle. Fecha UTC y coordenadas con ocho decimales solo en payload. Formularios con bloqueo de doble envío y navegación al guardar. Proveedor sustituible de mapa y picker para pruebas sin plataforma nativa. Galería mantiene orden y foto principal definidos por API.
