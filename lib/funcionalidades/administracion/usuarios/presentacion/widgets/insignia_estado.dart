import 'package:flutter/material.dart';
import 'package:traducontextmovil/funcionalidades/administracion/usuarios/dominio/usuarios_admin.dart';
import 'package:traducontextmovil/nucleo/tema/colores.dart';
import 'package:traducontextmovil/nucleo/tema/dimensiones.dart';

/// Etiqueta de color con el estado de una cuenta.
class InsigniaEstado extends StatelessWidget {
  const InsigniaEstado({super.key, required this.estado});

  final String estado;

  @override
  Widget build(BuildContext context) {
    final cuenta = EstadoCuenta.desdeCodigo(estado);
    final color = switch (cuenta) {
      EstadoCuenta.activo => ColoresApp.exito,
      EstadoCuenta.suspendido => ColoresApp.error,
      _ => ColoresApp.advertencia,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Espaciados.sm, vertical: Espaciados.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Radios.grande),
      ),
      child: Text(
        cuenta?.etiqueta ?? estado,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
      ),
    );
  }
}
