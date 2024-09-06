import 'package:contabilidad/database/database.dart';
import 'package:contabilidad/models/order_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  late int countDB;

  @override
  void initState() {
    super.initState();
    dataBaseProvider = Provider.of<DataBase>(context, listen: false);
    getCountAmountOrders();
  }

  getCountAmountOrders() async {
    countDB = await dataBaseProvider.getTotalOrdersCount("COBRO");
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
                        labelText: 'Monto (opcional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: true,
                        decimal: true,
                      ),
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
                          .where((order) =>
                              order.status == "pendiente" &&
                              double.parse(order.totalOwned) > 0.0)
                          .toList();

                      return ValueListenableBuilder<int?>(
                        valueListenable: selectedOrderIndex,
                        builder: (context, value, child) {
                          return ListView.builder(
                            itemCount: filteredOrderList.length,
                            itemBuilder: (context, index) {
                              final order = filteredOrderList[index];
                              double totalOwnedAmount =
                                  double.tryParse(order.totalOwned) ?? 0.0;

                              bool isSelected =
                                  selectedOrderIndex.value == index;

                              return Card(
                                color:
                                    isSelected ? Colors.greenAccent[100] : null,
                                child: ListTile(
                                  onTap: () {
                                    if (selectedOrderIndex.value == index) {
                                      selectedOrderIndex.value = null;
                                    } else {
                                      selectedOrderIndex.value = index;
                                      cobroOrder = order;
                                    }
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
                                        order.orderId,
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
                                        'Deuda total: ${order.totalOwned}',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: totalOwnedAmount < 0
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
                          child:
                              Center(child: Text('No hay datos disponibles')));
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
                    onPressed: _conceptoController.text.isNotEmpty
                        ? () async {
                            if (value != null &&
                                _montoController.text.isNotEmpty) {
                              double paymentAmount =
                                  double.parse(_montoController.text);

                              // Crear un nuevo pago solo si se seleccionó una orden
                              PagoModel newPago = PagoModel(
                                date: DateFormat('MM/dd/yyyy')
                                    .format(DateTime.now()),
                                amount: paymentAmount,
                              );

                              // Agregar el pago a la orden seleccionada
                              cobroOrder.pagos.add(newPago);

                              // Actualizar el total pendiente
                              double newTotalOwed =
                                  (double.tryParse(cobroOrder.totalOwned) ??
                                          0.0) -
                                      paymentAmount;

                              cobroOrder = cobroOrder.copyWith(
                                  totalOwned: newTotalOwed.toString());

                              if (newTotalOwed <= 0) {
                                cobroOrder =
                                    cobroOrder.copyWith(status: "cerrado");
                              }

                              // Actualizar la orden en la base de datos
                              await dataBaseProvider.updateOrderWithProducts(
                                  cobroOrder.id.toString(),
                                  cobroOrder,
                                  cobroOrder.productList!);
                            }

                            // Crear una nueva orden sin cobro asociado
                            if (value != null) {
                              print("TEST44");
                              await dataBaseProvider.createOrderWithProducts(
                                OrderModel(
                                  orderId:
                                      "COBRO ${cobroOrder.pagos.length} ${cobroOrder.orderId}",
                                  pagos: [],
                                  totalOwned: "",
                                  margen: "",
                                  status: "Pago",
                                  clientName: _conceptoController.text,
                                  celNumber: "",
                                  direccion: "",
                                  date: DateTime.now().toString(),
                                  comment: "",
                                  totalCost:
                                      double.tryParse(_montoController.text) ??
                                          0,
                                ),
                                cobroOrder.productList!,
                              );
                            }
                            if (value == null) {
                              print("TEST45");
                              await dataBaseProvider.createOrderWithProducts(
                                OrderModel(
                                  orderId: "COBRO $countDB",
                                  pagos: [],
                                  totalOwned: "",
                                  margen: "",
                                  status: "Pago",
                                  clientName: _conceptoController.text,
                                  celNumber: "",
                                  direccion: "",
                                  date: DateTime.now().toString(),
                                  comment: "",
                                  totalCost:
                                      double.tryParse(_montoController.text) ??
                                          0,
                                ),
                                [
                                  // ProductModel(
                                  //   id: 1,
                                  //   name: "Sample Product",
                                  //   file: "path/to/file.png",
                                  //   amount: 10,
                                  //   unitPrice: 20.5,
                                  //   productCategory: "Category",
                                  //   cost: 15,
                                  //   unit: "kg",
                                  //   productType: "Sale",
                                  //   quantity: ValueNotifier<int>(5),
                                  //   subProduct: const [], // You can add nested ProductModel instances here if needed
                                  //   datesNotAvailable: const [],
                                  //   datesUsed: const [],
                                  // )
                                ],
                              );
                            }

                            final snackBar = SnackBar(
                              content: const Text(
                                'Orden creada correctamente',
                                style: TextStyle(
                                  fontSize: 16.0,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor: Colors.deepPurple,
                              duration: const Duration(seconds: 3),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              margin: const EdgeInsets.all(10),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24.0, vertical: 12.0),
                            );
                            ScaffoldMessenger.of(context)
                                .showSnackBar(snackBar);
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
