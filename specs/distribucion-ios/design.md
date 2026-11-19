# Diseño

El workflow `.github/workflows/build-ios-unsigned.yml` se ejecuta con `workflow_dispatch`. Instala Flutter estable, restaura dependencias, compila iOS sin firma, crea la estructura `Payload/Runner.app`, genera `SmartPet-unsigned.ipa` y la publica mediante `actions/upload-artifact`.

La configuración pública de Firebase se lee de variables del repositorio. Si están vacías, las notificaciones quedan deshabilitadas sin impedir la compilación.
