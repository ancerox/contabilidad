import 'package:contabilidad/database/database.dart';
import 'package:contabilidad/models/order_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AgregarCobroPage extends StatefulWidget {
  const AgregarCobroPage({super.key});

  @override
  _AgregarCobroPageState createState() => _AgregarCobroPageState();
}

class _AgregarCobroPageState extends State<AgregarCobroPage> {
  final TextEditingController _conceptoController = TextEditingController();
  final TextEditingController _montoController = TextEditingController();
  late DataBase dataBaseProvider;
  ValueNotifier<int?> selectedOrderIndex = ValueNotifier<int?>(null);
  late OrderModel cobroOrder;

  @override
  void initState() {
    super.initState();
    dataBaseProvider = Provider.of<DataBase>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Agregar Cobro', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 108, 40, 123),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _conceptoController,
                      decoration: const InputDecoration(
                        labelText: 'Concepto',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      onChanged: (String value) {
                        setState(() {});
                      },
                      controller: _montoController,
                      decoration: const InputDecoration(
                        labelText: 'Monto',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<OrderModel>>(
                future: dataBaseProvider.getAllOrdersWithProducts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.hasData) {
                      List<OrderModel> filteredOrderList = snapshot.data!
                          .where((order) => order.status == "pendiente")
                          .toList();

                      return ValueListenableBuilder<int?>(
                        valueListenable: selectedOrderIndex,
                        builder: (context, value, child) {
                          return ListView.builder(
                            itemCount: filteredOrderList.length,
                            itemBuilder: (context, index) {
                              final order = filteredOrderList[index];

                              bool isSelected = value == index;
                              return Card(
                                color: int.parse(order.totalOwned) <=
                                        int.parse("0")
                                    ? Colors.greenAccent[100]
                                    : null,
                                child: ListTile(
                                  onTap: int.parse(order.totalOwned) <=
                                          int.parse("0")
                                      ? () {
                                          final snackBar = SnackBar(
                                            content: const Text(
                                              'Esta persona ya no tiene deudas',
                                              style: TextStyle(
                                                fontSize: 16.0,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            backgroundColor: Colors
                                                .red, // Un color de fondo llamativo
                                            duration: const Duration(
                                                seconds:
                                                    3), // Duración que el SnackBar será mostrado

                                            behavior: SnackBarBehavior
                                                .floating, // Hace que el SnackBar "flote" sobre la UI
                                            shape: RoundedRectangleBorder(
                                              // Forma personalizada
                                              borderRadius: BorderRadius.circular(
                                                  20.0), // Bordes redondeados
                                            ),
                                            margin: const EdgeInsets.all(
                                                10), // Margen alrededor del SnackBar
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 24.0,
                                                vertical:
                                                    12.0), // Ajusta el padding interno
                                          );

                                          // Muestra el SnackBar
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(snackBar);
                                        }
                                      : () {
                                          selectedOrderIndex.value =
                                              isSelected ? null : index;
                                          cobroOrder = order;
                                        },
                                  leading: const Icon(Icons.payment,
                                      color: Colors.blue),
                                  title: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        order.clientName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'Numero de orden: ${order.orderNumber}',
                                        style:
                                            TextStyle(color: Colors.grey[600]),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        int.parse(order.totalOwned) <
                                                int.parse("0")
                                            ? "Extra ${int.parse(order.totalOwned).abs()}"
                                            : 'Deuda total: ${order.totalOwned}',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: int.parse(order.totalOwned) <
                                                    int.parse("0")
                                                ? const Color.fromARGB(
                                                    255, 36, 58, 225)
                                                : Colors.red),
                                      ),
                                      Text(
                                        'fecha: ${order.date}',
                                        style:
                                            TextStyle(color: Colors.grey[600]),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                  trailing: Icon(
                                    isSelected
                                        ? Icons.check_circle
                                        : Icons.check_circle_outline,
                                    color: isSelected ? Colors.green : null,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    } else {
                      return const Expanded(
                          child: Center(child: Text('No data available')));
                    }
                  } else {
                    return const Expanded(
                        child: Center(child: CircularProgressIndicator()));
                  }
                },
              ),
            ),
            ValueListenableBuilder<int?>(
              valueListenable: selectedOrderIndex,
              builder: (context, value, child) {
                return SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: value != null && _montoController.text.isNotEmpty
                        ? () async {
                            // await dataBaseProvider.updateOrder(cobroOrder.id!,
                            //     totalOwned:
                            //         "${int.parse("${int.parse(cobroOrder.totalOwned) - int.parse(_montoController.text)} ")}");

                            await dataBaseProvider.createOrderWithProducts(
                              OrderModel(
                                pagos: [],
                                totalOwned: "",
                                margen: "",
                                status: "Pago",
                                clientName: cobroOrder.clientName,
                                celNumber: "",
                                direccion: "",
                                date: DateTime.now().toString(),
                                comment: "",
                                totalCost: double.parse(_montoController.text),
                              ),
                              cobroOrder.productList!,
                            );

                            final snackBar = SnackBar(
                              content: Text(
                                'Has recibido un pago de ${cobroOrder.clientName} Correctamente',
                                style: const TextStyle(
                                  fontSize: 16.0,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor: Colors
                                  .deepPurple, // Un color de fondo llamativo
                              duration: const Duration(
                                  seconds:
                                      3), // Duración que el SnackBar será mostrado
                              action: SnackBarAction(
                                label: '',
                                textColor: Colors
                                    .amber, // Color llamativo para la acción
                                onPressed: () {
                                  // Código para deshacer la acción aquí
                                },
                              ),
                              behavior: SnackBarBehavior
                                  .floating, // Hace que el SnackBar "flote" sobre la UI
                              shape: RoundedRectangleBorder(
                                // Forma personalizada
                                borderRadius: BorderRadius.circular(
                                    20.0), // Bordes redondeados
                              ),
                              margin: const EdgeInsets.all(
                                  10), // Margen alrededor del SnackBar
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24.0,
                                  vertical: 12.0), // Ajusta el padding interno
                            );

                            // Muestra el SnackBar
                            ScaffoldMessenger.of(context)
                                .showSnackBar(snackBar);
                            setState(() {});
                            Navigator.pop(context);
                          }
                        : _montoController.text.isNotEmpty &&
                                _conceptoController.text.isNotEmpty
                            ? () async {
                                await dataBaseProvider.createOrderWithProducts(
                                  OrderModel(
                                    pagos: [],
                                    orderNumber:
                                        "", // Añadir el número de orden si es necesario
                                    totalOwned: "",
                                    margen: "",
                                    status: "Pago",
                                    clientName: _conceptoController.text,
                                    celNumber: "",
                                    direccion: "",
                                    date: DateTime.now().toString(),
                                    comment: "",
                                    totalCost:
                                        double.parse(_montoController.text),
                                  ),
                                  cobroOrder.productList!,
                                );
                                final snackBar = SnackBar(
                                  content: Text(
                                    'Has recibido un pago de ${_conceptoController.text} Correctamente',
                                    style: const TextStyle(
                                      fontSize: 16.0,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  backgroundColor: Colors
                                      .deepPurple, // Un color de fondo llamativo
                                  duration: const Duration(
                                      seconds:
                                          3), // Duración que el SnackBar será mostrado
                                  action: SnackBarAction(
                                    label: '',
                                    textColor: Colors
                                        .amber, // Color llamativo para la acción
                                    onPressed: () {
                                      // Código para deshacer la acción aquí
                                    },
                                  ),
                                  behavior: SnackBarBehavior
                                      .floating, // Hace que el SnackBar "flote" sobre la UI
                                  shape: RoundedRectangleBorder(
                                    // Forma personalizada
                                    borderRadius: BorderRadius.circular(
                                        20.0), // Bordes redondeados
                                  ),
                                  margin: const EdgeInsets.all(
                                      10), // Margen alrededor del SnackBar
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24.0,
                                      vertical:
                                          12.0), // Ajusta el padding interno
                                );

                                // Muestra el SnackBar
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(snackBar);
                                setState(() {});
                                Navigator.pop(context);
                              }
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 108, 40, 123),
                      textStyle: const TextStyle(fontSize: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("Confirmar",
                        style: TextStyle(color: Colors.white)),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
