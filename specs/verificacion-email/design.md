# Design: verificacion de correo movil

- `PendingEmailVerification` representa correo, correo enmascarado y estado del primer envio.
- `Session.authenticate` devuelve ese objeto cuando no existe sesion todavia.
- `Session.verifyEmail` consume `/auth/email/verify` y reutiliza la persistencia segura de sesion.
- `Session.resendVerification` consume `/auth/email/resend`.
- `EmailVerificationScreen` contiene un campo numerico, acciones de confirmar y reenviar, estados de carga y mensajes amigables.

