import 'package:contabilidad/database/database.dart';
import 'package:contabilidad/models/order_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AgregarGastoPage extends StatefulWidget {
  const AgregarGastoPage({super.key});

  @override
  _AgregarGastoPageState createState() => _AgregarGastoPageState();
}

class _AgregarGastoPageState extends State<AgregarGastoPage> {
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
    countDB = await dataBaseProvider.getTotalOrdersCount("GASTO");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Agregar Gasto', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 229, 0, 34),
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
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: true,
                        decimal: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            ValueListenableBuilder<int?>(
              valueListenable: selectedOrderIndex,
              builder: (context, value, child) {
                return SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _conceptoController.text.isNotEmpty &&
                            _montoController.text.isNotEmpty
                        ? () async {
                            // Crear una nueva orden sin cobro asociado

                            print("TEST45");
                            await dataBaseProvider.createOrderWithProducts(
                              OrderModel(
                                orderId: "GASTO $countDB",
                                pagos: [],
                                totalOwned: "",
                                margen: "",
                                status: "Gasto",
                                clientName: _conceptoController.text,
                                celNumber: "",
                                direccion: "",
                                date: DateFormat('MM/dd/yyyy')
                                    .format(DateTime.now())
                                    .toString(),
                                comment: "",
                                totalCost:
                                    double.tryParse(_montoController.text) ?? 0,
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
