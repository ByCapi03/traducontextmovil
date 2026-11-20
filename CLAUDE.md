# traducontextmovil — instrucciones para Claude Code

## Git
- NUNCA añadir líneas `Co-Authored-By` ni `Claude-Session` (ni "Generated with Claude Code") en mensajes de commit ni en PR. La única autoría es la del usuario.
- No hacer push de `master` sin avisar antes.
- Nunca versionar `google-services.json`, `firebase_options.dart`, `firebase.json`, `key.properties`, `*.jks` ni `local.properties`.

## Verificación
- `flutter analyze` y `flutter test` en verde antes de cada commit.
