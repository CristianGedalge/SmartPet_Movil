# Diseño

Feature lib/features/adopciones con modelos AdoptionPublication y AdoptionEstablishment, servicio AdoptionsService y pantallas AdoptionsScreen / AdoptionDetailScreen.

Reutilizar Pet, PetPhoto, PagedListController, PagedListView, AsyncResource, AppCard y AnimalImage. El modelo solo interpreta campos públicos explícitos; ignora registroAdopcion y cualquier dato privado inesperado. Servicio sin JWT en ambas consultas, limit/offset, ids codificados; 404 traducido a publicación ya no disponible; formatos inválidos como ApiFailure amigable.

Listado con título Adopciones, tarjetas con foto principal, nombre, especie/edad y establecimiento; acceso Ver adopción. Detalle con galería horizontal desplazable y etiqueta de fotografía, ficha, descripción/requisitos y tarjeta de contacto. Clipboard.setData para copiar teléfono/dirección; confirmación o error y comprobación mounted tras awaits. Campos opcionales ausentes no rompen el detalle.

Inicio incluye acceso Explorar adopciones. La pestaña Perfil se reemplaza por Adopciones y el avatar navega a ProfileScreen; no agregar seis destinos estrechos. Controladores de listas se liberan al desmontar. Al volver del detalle se refresca el catálogo. El perfil y detalles siguen dentro del Navigator privado actual.
