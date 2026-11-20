import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:traducontextmovil/navegacion/rutas.dart';

/// Abre una ruta: las pestañas se seleccionan con `go` y las pantallas
/// completas se apilan con `push` (para poder volver atrás).
void navegarA(BuildContext context, String ruta) {
  if (Rutas.pestanas.contains(ruta)) {
    context.go(ruta);
  } else {
    context.push(ruta);
  }
}
