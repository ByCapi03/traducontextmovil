import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traducontextmovil/compartido/formato.dart';
import 'package:traducontextmovil/compartido/mensajes_error.dart';
import 'package:traducontextmovil/compartido/widgets/contenido_adaptable.dart';
import 'package:traducontextmovil/compartido/widgets/vista_estado.dart';
import 'package:traducontextmovil/funcionalidades/catalogos/datos/catalogos_api.dart';
import 'package:traducontextmovil/funcionalidades/catalogos/dominio/idioma.dart';
import 'package:traducontextmovil/funcionalidades/documentos/datos/documentos_repositorio_remoto.dart';
import 'package:traducontextmovil/funcionalidades/documentos/dominio/documentos.dart';
import 'package:traducontextmovil/funcionalidades/documentos/presentacion/widgets/dialogo_idiomas_documento.dart';
import 'package:traducontextmovil/nucleo/archivos/gestor_archivos.dart';
import 'package:traducontextmovil/nucleo/archivos/selector_archivos.dart';
import 'package:traducontextmovil/nucleo/red/excepcion_api.dart';
import 'package:traducontextmovil/nucleo/tema/colores.dart';
import 'package:traducontextmovil/nucleo/tema/dimensiones.dart';

/// Traducción de documentos .docx, .xlsx y .pdf (HU-21/HU-22).
class PantallaDocumentos extends ConsumerStatefulWidget {
  const PantallaDocumentos({super.key});

  @override
  ConsumerState<PantallaDocumentos> createState() => _PantallaDocumentosState();
}

class _PantallaDocumentosState extends ConsumerState<PantallaDocumentos> {
  List<Documento>? _originales;
  List<DocumentoTraducido>? _traducidos;
  String? _error;

  /// Texto de la operación en curso (subir, traducir, descargar); null si no hay.
  String? _operacion;

  DocumentosRepositorio get _repositorio => ref.read(documentosRepositorioProvider);

  @override
  void initState() {
    super.initState();
    unawaited(_cargar());
  }

  Future<void> _cargar() async {
    try {
      final resultados = await Future.wait([
        _repositorio.listarOriginales(),
        _repositorio.listarTraducidos(),
      ]);
      if (!mounted) return;
      setState(() {
        _originales = resultados[0] as List<Documento>;
        _traducidos = resultados[1] as List<DocumentoTraducido>;
        _error = null;
      });
    } on ExcepcionApi catch (error) {
      if (mounted) setState(() => _error = MensajesError.de(error));
    }
  }

  void _avisar(String mensaje) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<T?> _conOperacion<T>(String texto, Future<T> Function() accion, {Map<int, String>? errores}) async {
    setState(() => _operacion = texto);
    try {
      return await accion();
    } on ExcepcionApi catch (error) {
      if (mounted) _avisar(MensajesError.de(error, porCodigo: errores ?? const {}));
      return null;
    } finally {
      if (mounted) setState(() => _operacion = null);
    }
  }

  Future<void> _subirYTraducir() async {
    final archivo =
        await ref.read(selectorArchivosProvider).elegir(extensiones: extensionesDocumento);
    if (archivo == null || !mounted) return;
    final extension = archivo.nombre.split('.').last.toLowerCase();
    if (!extensionesDocumento.contains(extension)) {
      _avisar('Solo se admiten archivos .docx, .xlsx y .pdf.');
      return;
    }
    final documento = await _conOperacion(
      'Subiendo documento…',
      () => _repositorio.subir(nombre: archivo.nombre, bytes: archivo.bytes),
      errores: {400: 'El archivo no es válido. Solo se admiten .docx, .xlsx y .pdf.'},
    );
    if (documento == null || !mounted) return;
    await _cargar();
    await _traducir(documento);
  }

  Future<void> _traducir(Documento documento) async {
    final idiomas = await ref.read(idiomasProvider.future);
    if (!mounted) return;
    final eleccion = await showDialog<(String?, String)>(
      context: context,
      builder: (contexto) => DialogoIdiomasDocumento(nombreDocumento: documento.nombre, idiomas: idiomas),
    );
    if (eleccion == null || !mounted) return;
    final (origen, destino) = eleccion;
    final traducido = await _conOperacion(
      'Traduciendo documento… Puede tardar unos minutos.',
      () => _repositorio.traducir(idDocumento: documento.id, idiomaDestino: destino, idiomaOrigen: origen),
      errores: {400: 'No se pudo traducir el documento. Revisa los idiomas o el archivo.'},
    );
    if (traducido == null || !mounted) return;
    await _cargar();
    _avisar('Documento traducido. Ya puedes descargarlo.');
  }

  Future<void> _descargar(DocumentoTraducido traducido) async {
    final archivo = await _conOperacion('Descargando…', () => _repositorio.descargar(traducido));
    if (archivo == null) return;
    await ref.read(gestorArchivosProvider).guardarYCompartir(archivo);
  }

  Future<void> _eliminar(String descripcion, Future<void> Function() accion) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Eliminar'),
        content: Text('¿Quieres eliminar $descripcion?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (!(confirmado ?? false)) return;
    final hecho = await _conOperacion('Eliminando…', () async {
      await accion();
      return true;
    });
    if (hecho ?? false) await _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Documentos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _operacion == null ? _subirYTraducir : null,
        icon: const Icon(Icons.upload_file),
        label: const Text('Subir y traducir'),
      ),
      body: ContenidoAdaptable.lista(child: _cuerpo()),
    );
  }

  Widget _cuerpo() {
    final originales = _originales;
    final traducidos = _traducidos;
    if (originales == null && _error != null) {
      return VistaEstado(
        icono: Icons.cloud_off_outlined,
        esError: true,
        mensaje: _error!,
        textoAccion: 'Reintentar',
        alPresionar: _cargar,
      );
    }
    if (originales == null || traducidos == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final idiomas = ref.watch(idiomasProvider).valueOrNull ?? const <Idioma>[];
    final textos = Theme.of(context).textTheme;
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Espaciados.md, Espaciados.md, Espaciados.md, 96),
        children: [
          if (_operacion != null) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: Espaciados.xs),
            Text(_operacion!, style: textos.bodySmall),
            const SizedBox(height: Espaciados.md),
          ],
          Text(
            'Sube un archivo .docx, .xlsx o .pdf y elige el idioma. Se conserva el formato original.',
            style: textos.bodyMedium?.copyWith(color: ColoresApp.textoSecundario),
          ),
          const SizedBox(height: Espaciados.lg),
          Text('Traducciones', style: textos.titleMedium),
          const SizedBox(height: Espaciados.sm),
          if (traducidos.isEmpty)
            Text('Aún no has traducido documentos.', style: textos.bodySmall)
          else
            for (final traducido in traducidos)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.description, color: ColoresApp.primario),
                  title: Text(traducido.nombre, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    '${idiomas.nombreDe(traducido.codigoOrigen)} → ${idiomas.nombreDe(traducido.codigoDestino)}'
                    ' · ${Formato.fechaHora(traducido.fecha)}'
                    '${traducido.completado ? '' : ' · ${traducido.estado}'}',
                  ),
                  trailing: PopupMenuButton<String>(
                    tooltip: 'Opciones del documento',
                    enabled: _operacion == null,
                    onSelected: (opcion) => switch (opcion) {
                      'descargar' => _descargar(traducido),
                      _ => _eliminar(
                          'la traducción «${traducido.nombre}»',
                          () => _repositorio.eliminarTraducido(traducido.id),
                        ),
                    },
                    itemBuilder: (context) => [
                      if (traducido.completado)
                        const PopupMenuItem(value: 'descargar', child: Text('Descargar')),
                      const PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: Espaciados.lg),
          Text('Documentos originales', style: textos.titleMedium),
          const SizedBox(height: Espaciados.sm),
          if (originales.isEmpty)
            Text('Aún no has subido documentos.', style: textos.bodySmall)
          else
            for (final documento in originales)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.insert_drive_file_outlined),
                  title: Text(documento.nombre, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    '${documento.extension.toUpperCase()} · ${_tamano(documento.tamano)}'
                    ' · ${Formato.fecha(documento.fecha)}',
                  ),
                  trailing: PopupMenuButton<String>(
                    tooltip: 'Opciones del original',
                    enabled: _operacion == null,
                    onSelected: (opcion) => switch (opcion) {
                      'traducir' => _traducir(documento),
                      _ => _eliminar(
                          'el documento «${documento.nombre}» y sus traducciones',
                          () => _repositorio.eliminarOriginal(documento.id),
                        ),
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'traducir', child: Text('Traducir')),
                      PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  static String _tamano(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
