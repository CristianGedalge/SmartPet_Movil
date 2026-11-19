# IPA de prueba para iOS

## Objetivo

Generar en GitHub Actions un archivo `SmartPet-unsigned.ipa` sin firma, usando un runner macOS y el proyecto Flutter existente.

## Requisitos

- La ejecución se inicia manualmente.
- La URL del backend se recibe como parámetro y debe terminar en `/api/v1`.
- La compilación no requiere certificados de Apple.
- El resultado se publica como artefacto descargable.
- El archivo se identifica claramente como no firmado y no instalable mediante el flujo normal de iOS.

## Criterios de aceptación

- El workflow usa macOS y ejecuta `flutter build ios --release --no-codesign`.
- Empaqueta `Runner.app` dentro de `Payload/` con extensión `.ipa`.
- Publica el archivo como artefacto de GitHub Actions.
