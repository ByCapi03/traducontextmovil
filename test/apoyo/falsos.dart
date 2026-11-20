import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/datos/repositorios/autenticacion_repositorio_remoto.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/dominio/usuario_actual.dart';
import 'package:traducontextmovil/funcionalidades/catalogos/datos/catalogos_api.dart';
import 'package:traducontextmovil/funcionalidades/catalogos/dominio/idioma.dart';
import 'package:traducontextmovil/funcionalidades/historial/datos/historial_repositorio_remoto.dart';
import 'package:traducontextmovil/funcionalidades/historial/dominio/historial.dart';
import 'package:traducontextmovil/funcionalidades/notificaciones/datos/notificaciones_repositorio_remoto.dart';
import 'package:traducontextmovil/funcionalidades/notificaciones/dominio/notificacion.dart';
import 'package:traducontextmovil/funcionalidades/traduccion/datos/repositorios/traduccion_repositorio_remoto.dart';
import 'package:traducontextmovil/funcionalidades/traduccion/dominio/traduccion.dart';
import 'package:traducontextmovil/funcionalidades/traduccion/dominio/traduccion_repositorio.dart';
import 'package:traducontextmovil/nucleo/red/excepcion_api.dart';

import 'repositorio_falso.dart';

const usuarioNormal = UsuarioActual(
  id: 7,
  nombre: 'Ana',
  correo: 'ana@correo.com',
  estado: 'ACTIVO',
  rol: Rol(id: 2, nombre: 'USUARIO'),
  permisos: [],
);

const idiomasPrueba = [
  Idioma(id: 1, nombre: 'Español', codigo: 'es'),
  Idioma(id: 2, nombre: 'Francés', codigo: 'fr'),
  Idioma(id: 3, nombre: 'Inglés', codigo: 'en'),
];

/// Todos los repositorios simulados de la app. Ninguna prueba toca la red.
class Falsos {
  Falsos({RepositorioFalso? autenticacion}) : autenticacion = autenticacion ?? RepositorioFalso();

  final RepositorioFalso autenticacion;
  final TraduccionFalsa traduccion = TraduccionFalsa();
  final HistorialFalso historial = HistorialFalso();
  final NotificacionesFalsas notificaciones = NotificacionesFalsas();
  List<Idioma> idiomas = idiomasPrueba;

  /// Arranca con la sesión de [usuario] ya iniciada.
  Falsos conSesion([UsuarioActual usuario = usuarioNormal]) {
    autenticacion.sesionGuardada = usuario;
    return this;
  }

  List<Override> get overrides => [
        autenticacionRepositorioProvider.overrideWithValue(autenticacion),
        traduccionRepositorioProvider.overrideWithValue(traduccion),
        historialRepositorioProvider.overrideWithValue(historial),
        notificacionesRepositorioProvider.overrideWithValue(notificaciones),
        idiomasProvider.overrideWith((ref) async => idiomas),
      ];
}

class TraduccionFalsa implements TraduccionRepositorio {
  int configuracionesPedidas = 0;
  final List<Map<String, String?>> traducciones = [];
  ExcepcionApi? errorTraducir;

  @override
  Future<ConfiguracionTraduccion> obtenerOCrearConfiguracion() async {
    configuracionesPedidas++;
    return const ConfiguracionTraduccion(id: 1, nombreContexto: 'General', nombreTono: 'Neutral');
  }

  @override
  Future<ResultadoTraduccion> traducir({
    required String texto,
    required String idiomaDestino,
    String? idiomaOrigen,
  }) async {
    traducciones.add({'texto': texto, 'origen': idiomaOrigen, 'destino': idiomaDestino});
    final error = errorTraducir;
    if (error != null) throw error;
    return ResultadoTraduccion(
      textoOrigen: texto,
      // Detección simulada: si no se indica, el texto "está" en español (o en inglés si el destino es español).
      idiomaOrigen: idiomaOrigen ?? (idiomaDestino == 'es' ? 'en' : 'es'),
      idiomaDestino: idiomaDestino,
      traduccion: 'Traducido: $texto',
      idTraduccion: 99,
      confianzaDeteccion: idiomaOrigen == null ? 0.98 : null,
    );
  }
}

class HistorialFalso implements HistorialRepositorio {
  List<EntradaHistorial> entradas = [
    EntradaHistorial(
      id: 1,
      textoOriginal: 'Good morning',
      textoTraducido: 'Buenos días',
      idiomaOrigen: 'en',
      idiomaDestino: 'es',
      fecha: DateTime(2026, 11, 20, 9, 30),
      favorito: false,
    ),
    EntradaHistorial(
      id: 2,
      textoOriginal: 'Merci',
      textoTraducido: 'Gracias',
      idiomaOrigen: 'fr',
      idiomaDestino: 'es',
      fecha: DateTime(2026, 11, 19, 18),
      favorito: true,
    ),
  ];
  final List<(int, bool)> favoritos = [];
  final List<int> eliminadas = [];

  @override
  Future<List<EntradaHistorial>> listar({String? texto, bool soloFavoritos = false}) async => [
        for (final entrada in entradas)
          if ((!soloFavoritos || entrada.favorito) &&
              (texto == null ||
                  texto.isEmpty ||
                  entrada.textoOriginal.toLowerCase().contains(texto.toLowerCase())))
            entrada,
      ];

  @override
  Future<void> marcarFavorito(int id, {required bool favorito}) async {
    favoritos.add((id, favorito));
    entradas = [for (final e in entradas) e.id == id ? e.conFavorito(favorito) : e];
  }

  @override
  Future<void> eliminar(int id) async {
    eliminadas.add(id);
    entradas = [...entradas.where((e) => e.id != id)];
  }
}

class NotificacionesFalsas implements NotificacionesRepositorio {
  List<Notificacion> elementos = [
    Notificacion(
      id: 10,
      tipo: TiposNotificacion.documentoListo,
      titulo: 'Tu documento está listo',
      cuerpo: 'Ya puedes descargar la traducción.',
      leida: false,
      fecha: DateTime(2026, 11, 20, 8),
      datos: const {'id_traduccion_documento': '5'},
    ),
    Notificacion(
      id: 11,
      tipo: TiposNotificacion.sistema,
      titulo: 'Bienvenida',
      cuerpo: 'Gracias por usar TraduContext.',
      leida: true,
      fecha: DateTime(2026, 11, 19, 8),
    ),
  ];
  final List<int> marcadas = [];
  int todasMarcadas = 0;

  @override
  Future<PaginaNotificaciones> listar({int pagina = 1}) async => PaginaNotificaciones(
        elementos: elementos,
        noLeidas: elementos.where((n) => !n.leida).length,
        pagina: 1,
        totalPaginas: 1,
      );

  @override
  Future<void> marcarLeida(int id) async => marcadas.add(id);

  @override
  Future<void> marcarTodasLeidas() async => todasMarcadas++;
}
