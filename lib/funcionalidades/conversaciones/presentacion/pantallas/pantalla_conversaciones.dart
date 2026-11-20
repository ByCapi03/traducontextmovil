import 'package:flutter/material.dart';
import 'package:traducontextmovil/compartido/widgets/contenido_adaptable.dart';
import 'package:traducontextmovil/funcionalidades/chats/presentacion/widgets/lista_chats.dart';
import 'package:traducontextmovil/funcionalidades/conversaciones/presentacion/widgets/lista_conversaciones.dart';
import 'package:traducontextmovil/nucleo/tema/colores.dart';

/// Pestaña Conversaciones: conversación con intérprete (HU-23) y chats entre
/// usuarios.
class PantallaConversaciones extends StatelessWidget {
  const PantallaConversaciones({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 2,
      child: ContenidoAdaptable.lista(
        child: Column(
          children: [
            TabBar(
              labelColor: ColoresApp.primario,
              tabs: [
                Tab(icon: Icon(Icons.record_voice_over_outlined), text: 'Intérprete'),
                Tab(icon: Icon(Icons.chat_bubble_outline), text: 'Chats'),
              ],
            ),
            Expanded(child: TabBarView(children: [ListaConversaciones(), ListaChats()])),
          ],
        ),
      ),
    );
  }
}
