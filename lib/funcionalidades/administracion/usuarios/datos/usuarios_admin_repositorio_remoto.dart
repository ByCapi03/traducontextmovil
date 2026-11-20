import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traducontextmovil/funcionalidades/administracion/usuarios/dominio/usuarios_admin.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/dominio/usuario_actual.dart';
import 'package:traducontextmovil/nucleo/red/cliente_http.dart';
import 'package:traducontextmovil/nucleo/red/peticiones_api.dart';

/// Administración de cuentas de app/api/routes/usuarios.py (permiso gestionar_usuarios).
class UsuariosAdminRepositorioRemoto implements UsuariosAdminRepositorio {
  UsuariosAdminRepositorioRemoto(this._dio);

  final Dio _dio;
  static const int tamanoPagina = 20;

  @override
  Future<PaginaUsuarios> listar({int pagina = 1, String? busqueda, EstadoCuenta? estado}) async {
    final json = await resultadoDe(
      _dio.get<dynamic>(
        '/usuarios',
        queryParameters: parametros({
          'pagina': pagina,
          'tamano_pagina': tamanoPagina,
          'busqueda': busqueda?.trim(),
          'estado': estado?.codigo,
        }),
      ),
    ) as Map<String, dynamic>;
    return PaginaUsuarios(
      elementos: [for (final fila in listaDeMapas(json['elementos'])) _resumen(fila)],
      total: json['total'] as int,
      pagina: json['pagina'] as int,
      totalPaginas: json['total_paginas'] as int,
    );
  }

  @override
  Future<List<Rol>> roles() async => [
        for (final rol in listaDeMapas(await resultadoDe(_dio.get<dynamic>('/usuarios/roles'))))
          _rol(rol),
      ];

  @override
  Future<DetalleUsuarioAdmin> detalle(int id) =>
      _detalleDe(_dio.get<dynamic>('/usuarios/$id'));

  @override
  Future<DetalleUsuarioAdmin> suspender(int id) =>
      _detalleDe(_dio.patch<dynamic>('/usuarios/$id/suspender'));

  @override
  Future<DetalleUsuarioAdmin> reactivar(int id) =>
      _detalleDe(_dio.patch<dynamic>('/usuarios/$id/reactivar'));

  @override
  Future<DetalleUsuarioAdmin> cambiarRol(int id, int idRol) =>
      _detalleDe(_dio.patch<dynamic>('/usuarios/$id/rol', data: {'id_rol': idRol}));

  Future<DetalleUsuarioAdmin> _detalleDe(Future<Response<dynamic>> peticion) async {
    final json = await resultadoDe(peticion) as Map<String, dynamic>;
    return DetalleUsuarioAdmin(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      correo: json['correo'] as String,
      estado: json['estado'] as String,
      rol: _rol(json['rol'] as Map<String, dynamic>),
      fechaCreacion: fechaDe(json['fecha_creacion']) ?? DateTime.now(),
      ultimoAcceso: fechaDe(json['ultimo_acceso']),
      sesionesActivas: json['sesiones_activas'] as int? ?? 0,
      totalTraducciones: json['total_traducciones'] as int? ?? 0,
      totalDocumentos: json['total_documentos'] as int? ?? 0,
      totalConversaciones: json['total_conversaciones'] as int? ?? 0,
      totalGlosarios: json['total_glosarios'] as int? ?? 0,
    );
  }

  UsuarioAdmin _resumen(Map<String, dynamic> json) => UsuarioAdmin(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        correo: json['correo'] as String,
        estado: json['estado'] as String,
        rol: _rol(json['rol'] as Map<String, dynamic>),
        fechaCreacion: fechaDe(json['fecha_creacion']) ?? DateTime.now(),
      );

  Rol _rol(Map<String, dynamic> json) =>
      Rol(id: json['id'] as int, nombre: json['nombre'] as String);
}

final usuariosAdminRepositorioProvider = Provider<UsuariosAdminRepositorio>(
  (ref) => UsuariosAdminRepositorioRemoto(ref.watch(clienteHttpProvider)),
);
