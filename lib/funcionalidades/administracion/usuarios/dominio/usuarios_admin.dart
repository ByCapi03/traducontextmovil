import 'package:traducontextmovil/funcionalidades/autenticacion/dominio/usuario_actual.dart';

/// Estados de cuenta que define el backend.
enum EstadoCuenta {
  activo('ACTIVO', 'Activa'),
  inactivo('INACTIVO', 'Sin verificar'),
  suspendido('SUSPENDIDO', 'Suspendida');

  const EstadoCuenta(this.codigo, this.etiqueta);

  final String codigo;
  final String etiqueta;

  static EstadoCuenta? desdeCodigo(String codigo) {
    for (final estado in values) {
      if (estado.codigo == codigo) return estado;
    }
    return null;
  }
}

/// Fila del listado de administración (GET /usuarios).
class UsuarioAdmin {
  const UsuarioAdmin({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.estado,
    required this.rol,
    required this.fechaCreacion,
  });

  final int id;
  final String nombre;
  final String correo;
  final String estado;
  final Rol rol;
  final DateTime fechaCreacion;

  String get etiquetaEstado => EstadoCuenta.desdeCodigo(estado)?.etiqueta ?? estado;
}

/// Detalle de una cuenta (GET /usuarios/{id}).
class DetalleUsuarioAdmin extends UsuarioAdmin {
  const DetalleUsuarioAdmin({
    required super.id,
    required super.nombre,
    required super.correo,
    required super.estado,
    required super.rol,
    required super.fechaCreacion,
    this.ultimoAcceso,
    this.sesionesActivas = 0,
    this.totalTraducciones = 0,
    this.totalDocumentos = 0,
    this.totalConversaciones = 0,
    this.totalGlosarios = 0,
  });

  final DateTime? ultimoAcceso;
  final int sesionesActivas;
  final int totalTraducciones;
  final int totalDocumentos;
  final int totalConversaciones;
  final int totalGlosarios;
}

class PaginaUsuarios {
  const PaginaUsuarios({
    required this.elementos,
    required this.total,
    required this.pagina,
    required this.totalPaginas,
  });

  final List<UsuarioAdmin> elementos;
  final int total;
  final int pagina;
  final int totalPaginas;

  bool get hayMas => pagina < totalPaginas;
}

/// Lanza `ExcepcionApi` si el backend responde con error.
abstract interface class UsuariosAdminRepositorio {
  Future<PaginaUsuarios> listar({int pagina = 1, String? busqueda, EstadoCuenta? estado});

  Future<List<Rol>> roles();

  Future<DetalleUsuarioAdmin> detalle(int id);

  Future<DetalleUsuarioAdmin> suspender(int id);

  Future<DetalleUsuarioAdmin> reactivar(int id);

  Future<DetalleUsuarioAdmin> cambiarRol(int id, int idRol);
}
