import 'package:flutter/material.dart';
import 'package:traducontextmovil/compartido/widgets/desplegable.dart';
import 'package:traducontextmovil/compartido/widgets/mensaje_formulario.dart';
import 'package:traducontextmovil/funcionalidades/catalogos/dominio/idioma.dart';
import 'package:traducontextmovil/funcionalidades/glosarios/dominio/glosarios.dart';
import 'package:traducontextmovil/nucleo/tema/dimensiones.dart';

/// Crear o editar un glosario. [guardar] devuelve el error o null. True si se guardó.
Future<bool> mostrarDialogoGlosario(
  BuildContext context, {
  required List<Idioma> idiomas,
  required Future<String?> Function(DatosGlosario datos) guardar,
  Glosario? editado,
}) async =>
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DialogoGlosario(idiomas: idiomas, guardar: guardar, editado: editado),
    ) ??
    false;

/// Crear o editar un término. [guardar] devuelve el error o null. True si se guardó.
Future<bool> mostrarDialogoTermino(
  BuildContext context, {
  required Future<String?> Function(DatosTermino datos) guardar,
  TerminoGlosario? editado,
}) async =>
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DialogoTermino(guardar: guardar, editado: editado),
    ) ??
    false;

/// Confirmación de borrado. True si se acepta.
Future<bool> confirmarEliminacion(BuildContext context, {required String titulo, required String mensaje}) async =>
    await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(onPressed: () => Navigator.of(contexto).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(contexto).pop(true), child: const Text('Eliminar')),
        ],
      ),
    ) ??
    false;

/// Guardado común: deshabilita mientras guarda, muestra el error y cierra si salió bien.
mixin _GuardadoDialogo<T extends StatefulWidget> on State<T> {
  bool guardando = false;
  String? error;

  Future<void> ejecutarGuardado(Future<String?> Function() guardar) async {
    setState(() {
      guardando = true;
      error = null;
    });
    final resultado = await guardar();
    if (!mounted) return;
    if (resultado == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      guardando = false;
      error = resultado;
    });
  }
}

class _MarcoDialogo extends StatelessWidget {
  const _MarcoDialogo({
    required this.titulo,
    required this.campos,
    required this.guardando,
    required this.error,
    required this.alGuardar,
  });

  final String titulo;
  final List<Widget> campos;
  final bool guardando;
  final String? error;
  final VoidCallback alGuardar;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(titulo),
      scrollable: true,
      content: SizedBox(
        width: Anchos.formulario,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...campos,
            if (error != null) ...[
              const SizedBox(height: Espaciados.sm),
              MensajeFormulario(error!),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: guardando ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: guardando ? null : alGuardar, child: Text(guardando ? 'Guardando…' : 'Guardar')),
      ],
    );
  }
}

class _DialogoGlosario extends StatefulWidget {
  const _DialogoGlosario({required this.idiomas, required this.guardar, this.editado});

  final List<Idioma> idiomas;
  final Future<String?> Function(DatosGlosario datos) guardar;
  final Glosario? editado;

  @override
  State<_DialogoGlosario> createState() => _DialogoGlosarioState();
}

class _DialogoGlosarioState extends State<_DialogoGlosario> with _GuardadoDialogo {
  late final _nombre = TextEditingController(text: widget.editado?.nombre);
  late final _descripcion = TextEditingController(text: widget.editado?.descripcion);
  late int? _origen = widget.editado?.idIdiomaOrigen;
  late int? _destino = widget.editado?.idIdiomaDestino;

  @override
  void dispose() {
    _nombre.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final opciones = [for (final idioma in widget.idiomas) (idioma.id, idioma.nombre)];
    return _MarcoDialogo(
      titulo: widget.editado == null ? 'Nuevo glosario' : 'Editar glosario',
      guardando: guardando,
      error: error,
      alGuardar: () => ejecutarGuardado(
        () => widget.guardar(
          DatosGlosario(
            nombre: _nombre.text,
            descripcion: _descripcion.text,
            idIdiomaOrigen: _origen,
            idIdiomaDestino: _destino,
          ),
        ),
      ),
      campos: [
        TextField(
          controller: _nombre,
          enabled: !guardando,
          maxLength: ValidacionGlosarios.longitudNombre,
          decoration: const InputDecoration(labelText: 'Nombre *', counterText: ''),
        ),
        TextField(
          controller: _descripcion,
          enabled: !guardando,
          minLines: 1,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Descripción'),
        ),
        const SizedBox(height: Espaciados.md),
        Desplegable<int>(
          etiqueta: 'Idioma de origen *',
          valor: _origen,
          habilitado: !guardando,
          opciones: opciones,
          alCambiar: (id) => setState(() => _origen = id),
        ),
        const SizedBox(height: Espaciados.md),
        Desplegable<int>(
          etiqueta: 'Idioma de destino *',
          valor: _destino,
          habilitado: !guardando,
          opciones: opciones,
          alCambiar: (id) => setState(() => _destino = id),
        ),
      ],
    );
  }
}

class _DialogoTermino extends StatefulWidget {
  const _DialogoTermino({required this.guardar, this.editado});

  final Future<String?> Function(DatosTermino datos) guardar;
  final TerminoGlosario? editado;

  @override
  State<_DialogoTermino> createState() => _DialogoTerminoState();
}

class _DialogoTerminoState extends State<_DialogoTermino> with _GuardadoDialogo {
  late final _origen = TextEditingController(text: widget.editado?.terminoOrigen);
  late final _traduccion = TextEditingController(text: widget.editado?.traduccionPreferida);
  late final _nota = TextEditingController(text: widget.editado?.nota);
  late bool _conservar = widget.editado?.conservarOriginal ?? false;
  late bool _mayusculas = widget.editado?.distinguirMayusculas ?? false;

  @override
  void dispose() {
    _origen.dispose();
    _traduccion.dispose();
    _nota.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _MarcoDialogo(
      titulo: widget.editado == null ? 'Nuevo término' : 'Editar término',
      guardando: guardando,
      error: error,
      alGuardar: () => ejecutarGuardado(
        () => widget.guardar(
          DatosTermino(
            terminoOrigen: _origen.text,
            traduccionPreferida: _traduccion.text,
            conservarOriginal: _conservar,
            distinguirMayusculas: _mayusculas,
            nota: _nota.text,
          ),
        ),
      ),
      campos: [
        TextField(
          controller: _origen,
          enabled: !guardando,
          maxLength: ValidacionGlosarios.longitudTermino,
          decoration: const InputDecoration(labelText: 'Término de origen *', counterText: ''),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Conservar en el idioma original'),
          value: _conservar,
          onChanged: guardando ? null : (valor) => setState(() => _conservar = valor),
        ),
        if (!_conservar)
          TextField(
            controller: _traduccion,
            enabled: !guardando,
            maxLength: ValidacionGlosarios.longitudTermino,
            decoration: const InputDecoration(labelText: 'Traducción preferida *', counterText: ''),
          ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Distinguir mayúsculas'),
          value: _mayusculas,
          onChanged: guardando ? null : (valor) => setState(() => _mayusculas = valor),
        ),
        TextField(
          controller: _nota,
          enabled: !guardando,
          minLines: 1,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Nota'),
        ),
      ],
    );
  }
}
