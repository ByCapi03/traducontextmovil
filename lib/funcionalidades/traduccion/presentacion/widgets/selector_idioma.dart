import 'package:flutter/material.dart';
import 'package:traducontextmovil/funcionalidades/catalogos/dominio/idioma.dart';

/// Desplegable de idiomas. Con [permitirDeteccion], la opción null es
/// "Detectar idioma".
class SelectorIdioma extends StatelessWidget {
  const SelectorIdioma({
    super.key,
    required this.etiqueta,
    required this.valor,
    required this.idiomas,
    required this.alCambiar,
    this.permitirDeteccion = false,
    this.habilitado = true,
  });

  final String etiqueta;
  final String? valor;
  final List<Idioma> idiomas;
  final ValueChanged<String?> alCambiar;
  final bool permitirDeteccion;
  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    final valorValido = idiomas.porCodigo(valor) != null ? valor : null;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: etiqueta,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: valorValido,
          isExpanded: true,
          onChanged: habilitado ? alCambiar : null,
          items: [
            if (permitirDeteccion)
              const DropdownMenuItem<String?>(
                child: Text('Detectar idioma', overflow: TextOverflow.ellipsis),
              ),
            for (final idioma in idiomas)
              DropdownMenuItem<String?>(
                value: idioma.codigo,
                child: Text(idioma.nombre, overflow: TextOverflow.ellipsis),
              ),
          ],
        ),
      ),
    );
  }
}
