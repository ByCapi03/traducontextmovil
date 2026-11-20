import 'package:flutter/material.dart';
import 'package:traducontextmovil/funcionalidades/catalogos/dominio/idioma.dart';
import 'package:traducontextmovil/funcionalidades/traduccion/presentacion/widgets/selector_idioma.dart';
import 'package:traducontextmovil/nucleo/tema/dimensiones.dart';

/// Elige los idiomas para traducir un documento. Devuelve (origen, destino);
/// origen null significa detección automática.
class DialogoIdiomasDocumento extends StatefulWidget {
  const DialogoIdiomasDocumento({
    super.key,
    required this.nombreDocumento,
    required this.idiomas,
    this.destinoInicial,
  });

  final String nombreDocumento;
  final List<Idioma> idiomas;
  final String? destinoInicial;

  @override
  State<DialogoIdiomasDocumento> createState() => _DialogoIdiomasDocumentoState();
}

class _DialogoIdiomasDocumentoState extends State<DialogoIdiomasDocumento> {
  String? _origen;
  late String? _destino = widget.destinoInicial ?? widget.idiomas.porCodigo('en')?.codigo;
  String? _error;

  void _aceptar() {
    if (_destino == null) {
      setState(() => _error = 'Elige el idioma de destino.');
      return;
    }
    if (_origen == _destino) {
      setState(() => _error = 'El idioma de origen y el de destino deben ser distintos.');
      return;
    }
    Navigator.of(context).pop((_origen, _destino!));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Traducir documento'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.nombreDocumento, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: Espaciados.md),
            SelectorIdioma(
              etiqueta: 'Idioma del documento',
              valor: _origen,
              idiomas: widget.idiomas,
              permitirDeteccion: true,
              alCambiar: (codigo) => setState(() => _origen = codigo),
            ),
            const SizedBox(height: Espaciados.md),
            SelectorIdioma(
              etiqueta: 'Traducir a',
              valor: _destino,
              idiomas: widget.idiomas,
              alCambiar: (codigo) => setState(() => _destino = codigo),
            ),
            if (_error != null) ...[
              const SizedBox(height: Espaciados.sm),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        TextButton(onPressed: _aceptar, child: const Text('Traducir')),
      ],
    );
  }
}
