import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traducontextmovil/compartido/mensajes_error.dart';
import 'package:traducontextmovil/compartido/widgets/contenido_adaptable.dart';
import 'package:traducontextmovil/compartido/widgets/vista_estado.dart';
import 'package:traducontextmovil/funcionalidades/catalogos/datos/catalogos_api.dart';
import 'package:traducontextmovil/funcionalidades/catalogos/dominio/idioma.dart';
import 'package:traducontextmovil/funcionalidades/historial/datos/historial_repositorio_remoto.dart';
import 'package:traducontextmovil/funcionalidades/historial/dominio/historial.dart';
import 'package:traducontextmovil/funcionalidades/historial/presentacion/widgets/tarjeta_historial.dart';
import 'package:traducontextmovil/nucleo/red/excepcion_api.dart';
import 'package:traducontextmovil/nucleo/tema/dimensiones.dart';

/// Historial de traducciones con búsqueda, favoritos y eliminación (HU-19/HU-20).
class PantallaHistorial extends ConsumerStatefulWidget {
  const PantallaHistorial({super.key});

  @override
  ConsumerState<PantallaHistorial> createState() => _PantallaHistorialState();
}

class _PantallaHistorialState extends ConsumerState<PantallaHistorial> {
  final _busqueda = TextEditingController();
  Timer? _esperaBusqueda;
  List<EntradaHistorial>? _entradas;
  bool _soloFavoritos = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_cargar());
  }

  @override
  void dispose() {
    _esperaBusqueda?.cancel();
    _busqueda.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    try {
      final entradas = await ref
          .read(historialRepositorioProvider)
          .listar(texto: _busqueda.text, soloFavoritos: _soloFavoritos);
      if (mounted) {
        setState(() {
          _entradas = entradas;
          _error = null;
        });
      }
    } on ExcepcionApi catch (error) {
      if (mounted) setState(() => _error = MensajesError.de(error));
    }
  }

  void _alBuscar(String _) {
    _esperaBusqueda?.cancel();
    _esperaBusqueda = Timer(const Duration(milliseconds: 400), _cargar);
  }

  void _avisar(String mensaje) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> _cambiarFavorito(EntradaHistorial entrada) async {
    final nuevoValor = !entrada.favorito;
    _reemplazar(entrada.conFavorito(nuevoValor));
    try {
      await ref.read(historialRepositorioProvider).marcarFavorito(entrada.id, favorito: nuevoValor);
      if (_soloFavoritos && !nuevoValor) _quitar(entrada.id);
    } on ExcepcionApi catch (error) {
      _reemplazar(entrada);
      if (mounted) _avisar(MensajesError.de(error));
    }
  }

  Future<void> _eliminar(EntradaHistorial entrada) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Eliminar traducción'),
        content: const Text('¿Quieres eliminar esta traducción del historial?'),
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
    try {
      await ref.read(historialRepositorioProvider).eliminar(entrada.id);
      _quitar(entrada.id);
      if (mounted) _avisar('Traducción eliminada.');
    } on ExcepcionApi catch (error) {
      if (mounted) _avisar(MensajesError.de(error));
    }
  }

  Future<void> _copiar(EntradaHistorial entrada) async {
    await Clipboard.setData(ClipboardData(text: entrada.textoTraducido));
    if (mounted) _avisar('Traducción copiada.');
  }

  void _reemplazar(EntradaHistorial entrada) {
    if (!mounted) return;
    setState(() {
      _entradas = [
        for (final actual in _entradas ?? <EntradaHistorial>[])
          actual.id == entrada.id ? entrada : actual,
      ];
    });
  }

  void _quitar(int id) {
    if (!mounted) return;
    setState(() => _entradas = [...?_entradas?.where((entrada) => entrada.id != id)]);
  }

  @override
  Widget build(BuildContext context) {
    final idiomas = ref.watch(idiomasProvider).valueOrNull ?? const <Idioma>[];
    ref.listen(versionHistorialProvider, (_, _) => _cargar());
    return ContenidoAdaptable.lista(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Espaciados.md, Espaciados.md, Espaciados.md, 0),
            child: TextField(
              controller: _busqueda,
              onChanged: _alBuscar,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                labelText: 'Buscar en el historial',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Espaciados.md),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FilterChip(
                label: const Text('Solo favoritos'),
                selected: _soloFavoritos,
                onSelected: (valor) {
                  setState(() => _soloFavoritos = valor);
                  unawaited(_cargar());
                },
              ),
            ),
          ),
          Expanded(child: _contenido(idiomas)),
        ],
      ),
    );
  }

  Widget _contenido(List<Idioma> idiomas) {
    final entradas = _entradas;
    if (entradas == null && _error != null) {
      return VistaEstado(
        icono: Icons.cloud_off_outlined,
        esError: true,
        mensaje: _error!,
        textoAccion: 'Reintentar',
        alPresionar: _cargar,
      );
    }
    if (entradas == null) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _cargar,
      child: entradas.isEmpty
          ? ListView(
              children: [
                VistaEstado(
                  icono: Icons.history,
                  mensaje: _soloFavoritos || _busqueda.text.trim().isNotEmpty
                      ? 'No hay traducciones que coincidan.'
                      : 'Aún no tienes traducciones guardadas.',
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(Espaciados.md),
              itemCount: entradas.length,
              separatorBuilder: (_, _) => const SizedBox(height: Espaciados.sm),
              itemBuilder: (context, indice) {
                final entrada = entradas[indice];
                return TarjetaHistorial(
                  key: ValueKey(entrada.id),
                  entrada: entrada,
                  idiomas:
                      '${idiomas.nombreDe(entrada.idiomaOrigen)} → ${idiomas.nombreDe(entrada.idiomaDestino)}',
                  alCambiarFavorito: () => _cambiarFavorito(entrada),
                  alEliminar: () => _eliminar(entrada),
                  alCopiar: () => _copiar(entrada),
                );
              },
            ),
    );
  }
}
