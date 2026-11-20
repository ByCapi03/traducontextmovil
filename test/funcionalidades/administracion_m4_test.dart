import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traducontextmovil/compartido/periodo.dart';
import 'package:traducontextmovil/funcionalidades/administracion/dashboard/datos/dashboard_repositorio_remoto.dart';
import 'package:traducontextmovil/funcionalidades/administracion/dashboard/dominio/dashboard.dart';
import 'package:traducontextmovil/funcionalidades/administracion/reportes/datos/reportes_repositorio_remoto.dart';
import 'package:traducontextmovil/funcionalidades/administracion/reportes/dominio/reportes.dart';
import 'package:traducontextmovil/funcionalidades/administracion/usuarios/datos/usuarios_admin_repositorio_remoto.dart';
import 'package:traducontextmovil/funcionalidades/administracion/usuarios/dominio/usuarios_admin.dart';
import 'package:traducontextmovil/funcionalidades/administracion/usuarios/presentacion/pantallas/pantalla_detalle_usuario.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/dominio/usuario_actual.dart';
import 'package:traducontextmovil/navegacion/enrutador.dart';
import 'package:traducontextmovil/navegacion/rutas.dart';
import 'package:traducontextmovil/nucleo/archivos/gestor_archivos.dart';
import 'package:traducontextmovil/nucleo/red/excepcion_api.dart';
import 'package:traducontextmovil/funcionalidades/autenticacion/presentacion/proveedores/estado_sesion.dart';

import '../apoyo/falsos.dart';
import '../apoyo/montar_app.dart';

const _admin = UsuarioActual(
  id: 1,
  nombre: 'Admin',
  correo: 'admin@correo.com',
  estado: 'ACTIVO',
  rol: Rol(id: 1, nombre: 'ADMINISTRADOR'),
  permisos: ['ver_dashboard', 'gestionar_usuarios', 'generar_reportes'],
);

class _DashboardFalso implements DashboardRepositorio {
  final List<Periodo> consultas = [];

  @override
  Future<Dashboard> consultar(Periodo periodo) async {
    consultas.add(periodo);
    return Dashboard(
      usuariosTotal: 42,
      usuariosActivos: 30,
      usuariosNuevos: 5,
      traducciones: 120,
      documentos: 8,
      conversaciones: 3,
      idiomas: const [UsoElemento(nombre: 'Inglés', total: 80)],
      contextos: const [UsoElemento(nombre: 'Médico', total: 12)],
      evolucion: [
        PuntoEvolucion(fecha: DateTime(2026, 11, 19), traducciones: 4, documentos: 1, conversaciones: 0),
      ],
      agrupacionMensual: false,
    );
  }
}

class _UsuariosFalsos implements UsuariosAdminRepositorio {
  DetalleUsuarioAdmin cuenta = DetalleUsuarioAdmin(
    id: 7,
    nombre: 'Ana',
    correo: 'ana@correo.com',
    estado: 'ACTIVO',
    rol: const Rol(id: 2, nombre: 'USUARIO'),
    fechaCreacion: DateTime(2026, 10, 1),
    totalTraducciones: 15,
  );
  final List<String> acciones = [];
  ExcepcionApi? errorSuspender;

  @override
  Future<PaginaUsuarios> listar({int pagina = 1, String? busqueda, EstadoCuenta? estado}) async =>
      PaginaUsuarios(
        elementos: [if (estado == null || estado.codigo == cuenta.estado) cuenta],
        total: 1,
        pagina: 1,
        totalPaginas: 1,
      );

  @override
  Future<List<Rol>> roles() async =>
      const [Rol(id: 1, nombre: 'ADMINISTRADOR'), Rol(id: 2, nombre: 'USUARIO')];

  @override
  Future<DetalleUsuarioAdmin> detalle(int id) async => cuenta;

  DetalleUsuarioAdmin _conEstado(String estado) => cuenta = DetalleUsuarioAdmin(
        id: cuenta.id,
        nombre: cuenta.nombre,
        correo: cuenta.correo,
        estado: estado,
        rol: cuenta.rol,
        fechaCreacion: cuenta.fechaCreacion,
      );

  @override
  Future<DetalleUsuarioAdmin> suspender(int id) async {
    acciones.add('suspender:$id');
    final error = errorSuspender;
    if (error != null) throw error;
    return _conEstado('SUSPENDIDO');
  }

  @override
  Future<DetalleUsuarioAdmin> reactivar(int id) async {
    acciones.add('reactivar:$id');
    return _conEstado('ACTIVO');
  }

  @override
  Future<DetalleUsuarioAdmin> cambiarRol(int id, int idRol) async {
    acciones.add('rol:$id:$idRol');
    return cuenta;
  }
}

class _ReportesFalsos implements ReportesRepositorio {
  final List<FiltrosReporte> consultas = [];
  final List<FormatoExportacion> exportados = [];

  @override
  Future<ReporteActividad> consultar(FiltrosReporte filtros, {int pagina = 1}) async {
    consultas.add(filtros);
    return ReporteActividad(
      total: 2,
      texto: 1,
      documento: 1,
      conversacion: 0,
      actividades: [
        ActividadReporte(
          tipoServicio: 'texto',
          fecha: DateTime(2026, 11, 20, 9),
          nombreUsuario: 'Ana',
          idiomaOrigen: 'Inglés',
          idiomaDestino: 'Español',
        ),
      ],
      pagina: 1,
      totalPaginas: 1,
    );
  }

  @override
  Future<ArchivoDescargado> exportar(FiltrosReporte filtros, FormatoExportacion formato) async {
    exportados.add(formato);
    return ArchivoDescargado(bytes: const [1, 2, 3], nombre: 'reporte.${formato.codigo}');
  }
}

class _ArchivosFalsos implements GestorArchivos {
  final List<String> compartidos = [];

  @override
  Future<void> guardarYCompartir(ArchivoDescargado archivo) async => compartidos.add(archivo.nombre);
}

class _Admin {
  _Admin() {
    falsos.adicionales.addAll([
      dashboardRepositorioProvider.overrideWithValue(dashboard),
      usuariosAdminRepositorioProvider.overrideWithValue(usuarios),
      reportesRepositorioProvider.overrideWithValue(reportes),
      gestorArchivosProvider.overrideWithValue(archivos),
    ]);
  }

  final falsos = Falsos().conSesion(_admin);
  final dashboard = _DashboardFalso();
  final usuarios = _UsuariosFalsos();
  final reportes = _ReportesFalsos();
  final archivos = _ArchivosFalsos();
}

void main() {
  group('redirección de administración', () {
    test('las subrutas exigen el permiso de su sección y un usuario normal no entra', () {
      final soloReportes = const SesionAutenticada(
        UsuarioActual(
          id: 2,
          nombre: 'R',
          correo: 'r@correo.com',
          estado: 'ACTIVO',
          rol: Rol(id: 3, nombre: 'ANALISTA'),
          permisos: ['generar_reportes'],
        ),
      );
      expect(redirigirSegunSesion(soloReportes, Rutas.detalleUsuario(5)), Rutas.administracionReportes);
      expect(redirigirSegunSesion(soloReportes, Rutas.administracionPerfil), isNull);

      final normal = const SesionAutenticada(usuarioNormal);
      expect(redirigirSegunSesion(normal, Rutas.administracionPerfil), Rutas.inicio);
      expect(redirigirSegunSesion(normal, Rutas.administracionPlanes), Rutas.inicio);
    });
  });

  testWidgets('el administrador entra al dashboard y cambia de periodo', (tester) async {
    final admin = _Admin();
    await montarApp(tester, falsos: admin.falsos);

    expect(find.widgetWithText(AppBar, 'Dashboard'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('5 nuevos en el periodo'), findsOneWidget);
    expect(find.text('Médico'), findsOneWidget);

    await tocar(tester, find.text('Últimos 7 días'));
    expect(admin.dashboard.consultas.last, Periodo.semana);
  });

  testWidgets('suspende una cuenta con confirmación y muestra el error propio en 400', (tester) async {
    final admin = _Admin();
    await montarApp(tester, falsos: admin.falsos);
    await irAPestana(tester, Icons.people_outline);

    expect(find.text('Ana'), findsOneWidget);
    await tocar(tester, find.text('Ana'));
    expect(find.byType(PantallaDetalleUsuario), findsOneWidget);
    expect(find.text('15'), findsOneWidget);

    await tocar(tester, find.text('Suspender cuenta'));
    await tocar(tester, find.widgetWithText(TextButton, 'Suspender'));
    expect(admin.usuarios.acciones, ['suspender:7']);
    expect(find.text('Cuenta suspendida.'), findsOneWidget);
    expect(find.text('Reactivar cuenta'), findsOneWidget);

    await tocar(tester, find.byType(BackButton));
    expect(find.widgetWithText(ListTile, 'Suspendida'), findsOneWidget);
  });

  testWidgets('un 400 al suspender muestra un texto propio con tildes', (tester) async {
    final admin = _Admin();
    admin.usuarios.errorSuspender = const ExcepcionApi('No puedes...', codigoEstado: 400);
    await montarApp(tester, falsos: admin.falsos);
    await irAPestana(tester, Icons.people_outline);
    await tocar(tester, find.text('Ana'));
    await tocar(tester, find.text('Suspender cuenta'));
    await tocar(tester, find.widgetWithText(TextButton, 'Suspender'));

    expect(find.textContaining('No se puede realizar esta acción'), findsOneWidget);
  });

  testWidgets('reportes filtra por servicio y exporta a PDF', (tester) async {
    final admin = _Admin();
    await montarApp(tester, falsos: admin.falsos);
    await irAPestana(tester, Icons.description_outlined);

    await tester.scrollUntilVisible(
      find.text('Texto · Ana'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Texto · Ana'), findsOneWidget);
    await tocar(tester, find.widgetWithText(FilterChip, 'Documentos'));
    expect(admin.reportes.consultas.last.tipo, TipoServicio.documento);

    await tocar(tester, find.text('Exportar PDF'));
    expect(admin.reportes.exportados, [FormatoExportacion.pdf]);
    expect(admin.archivos.compartidos, ['reporte.pdf']);
  });

  testWidgets('perfil del administrador muestra planes y suscripciones como próximamente', (tester) async {
    await montarApp(tester, falsos: _Admin().falsos);
    await irAPestana(tester, Icons.person_outline);

    expect(find.text('Planes'), findsOneWidget);
    await tocar(tester, find.text('Suscripciones'));
    expect(find.text('Próximamente. Las suscripciones aún no existen en el backend.'), findsOneWidget);
  });

  group('sin desbordes', () {
    for (final ancho in [360.0, 420.0]) {
      testWidgets('pestañas de administración a $ancho px', (tester) async {
        await montarApp(tester, falsos: _Admin().falsos, tamano: Size(ancho, 640));
        for (final icono in [Icons.people_outline, Icons.description_outlined, Icons.person_outline]) {
          await irAPestana(tester, icono);
        }
        await irAPestana(tester, Icons.people_outline);
        await tocar(tester, find.text('Ana'));
        expect(tester.takeException(), isNull);
      });
    }
  });
}
