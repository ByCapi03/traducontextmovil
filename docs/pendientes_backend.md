# Pendientes detectados en el backend (no modificado desde el móvil)

Revisado contra `traducontextback/app/api/routes/{autenticacion,usuarios}.py` y
`app/services/{autenticacion,usuarios}.py`.

| # | Endpoint | Situación actual | Efecto en la app | Cambio sugerido |
|---|----------|------------------|------------------|-----------------|
| 1 | `POST /autenticacion/iniciar-sesion` | Cuenta sin verificar y cuenta suspendida devuelven ambas **403**; solo cambia el texto del `detail`. | El login muestra «Tu cuenta no está activa.» y el enlace «¿Aún no verificaste tu correo?». Si estaba suspendida, la verificación responde 403 y se muestra «Tu cuenta está suspendida…». | Devolver un código de error estable (p. ej. `{"codigo": "CUENTA_NO_VERIFICADA"}`) o un HTTP distinto. |
| 2 | `verificar-codigo`, `validar-codigo-recuperacion`, `restablecer-contrasena` | Sin límite de intentos. El código es de 6 dígitos y vale 10 min. | Ninguno visible. | Limitar intentos por código/correo (p. ej. 5) e invalidar el código al superarlo. |
| 3 | `reenviar-codigo`, `solicitar-recuperacion` | Sin límite de frecuencia; nunca devuelve **429**. | La app aplica 60 s de espera en cliente y ya tiene texto propio para 429. | Rate limit por correo/IP con 429. |
| 4 | `POST /usuarios/reenviar-codigo` | **404** «No existe un usuario con ese correo.» revela si el correo está registrado. | Se muestra «No encontramos una cuenta con ese correo.» | Responder 200 neutro como en recuperación. |
| 5 | `POST /autenticacion/solicitar-recuperacion` | Respuesta neutra (bien), pero el **502** solo puede ocurrir si la cuenta existe y está activa. | Paso 1 muestra mensaje neutro; con 502, «No pudimos enviar el correo…». | Enviar el correo en segundo plano o responder 200 también ante fallo SMTP (y registrarlo en logs). |
| 6 | `POST /usuarios/verificar-codigo` | **400** agrupa código inválido, expirado y cuenta ya activa. | Un único texto que cubre los tres casos. | Código de error estable por caso. |
| 7 | Todos | Los `detail` llegan sin tildes («contrasena», «sesion»). | La app nunca los muestra en autenticación: usa textos propios por código HTTP. | Corregir textos del backend. |
