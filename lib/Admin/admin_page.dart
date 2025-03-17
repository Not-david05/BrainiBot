import 'package:flutter/material.dart';

void main() {
  runApp(const AdminPage());
}

class AdminPage extends StatelessWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ejemplo UI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Tamaño de la pantalla
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Row(
        children: [
          // SIDEBAR (menú lateral)
          Container(
            width: 70,
            color: Colors.pink[100], // Ajusta el color de fondo
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                // Botón "+"
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    overlayColor: Colors.pink, // color del botón
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12),
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
                const SizedBox(height: 30),
                // Ítems del menú
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.people),
                  tooltip: 'Usuarios',
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.check_circle_outline),
                  tooltip: 'Tareas',
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.analytics),
                  tooltip: 'Métricas de uso',
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.person),
                  tooltip: 'Modo usuario',
                ),
              ],
            ),
          ),
          // CONTENIDO PRINCIPAL
          Expanded(
            child: Container(
              color: Colors.pink[50], // Color de fondo suave
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ENCABEZADO
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 16.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Usuarios',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.notifications),
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.settings),
                            ),
                            // Puedes agregar más íconos si lo deseas
                          ],
                        ),
                      ],
                    ),
                  ),
                  // CONTENIDO SCROLLEABLE
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Sección "Usuarios en Línea"
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Usuarios en Línea',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {},
                                  child: Row(
                                    children: const [
                                      Text('Ver todos'),
                                      Icon(Icons.arrow_right),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 80,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: List.generate(7, (index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 12.0),
                                    child: Column(
                                      children: [
                                        CircleAvatar(
                                          radius: 25,
                                          backgroundColor: Colors.grey[400],
                                          child: Icon(
                                            Icons.person,
                                            color: Colors.white,
                                            size: 30,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text('us${index + 1}'),
                                      ],
                                    ),
                                  );
                                }),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Sección "Todos los Usuarios"
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Todos los Usuarios',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {},
                                  child: Row(
                                    children: const [
                                      Text('Ver todos'),
                                      Icon(Icons.arrow_right),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Aquí podrías usar un GridView o un Wrap
                            // para mostrar tarjetas con los usuarios
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: List.generate(4, (index) {
                                return Container(
                                  width: (size.width - 70 - 60) /
                                      2, // Ajustar tamaño con base en el sidebar y paddings
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}º',
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                  ),
                                );
                              }),
                            ),
                            // Agrega más widgets según tu diseño
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
