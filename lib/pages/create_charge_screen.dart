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
                          .where((order) => order.status == "pendiente")
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
                              bool isSelected = totalOwnedAmount <= 0;

                              return Card(
                                color: totalOwnedAmount <= 0
                                    ? Colors.greenAccent[100]
                                    : null,
                                child: ListTile(
                                  onTap: totalOwnedAmount <= 0
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
                                            backgroundColor: Colors.red,
                                            duration:
                                                const Duration(seconds: 3),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20.0),
                                            ),
                                            margin: const EdgeInsets.all(10),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 24.0,
                                                vertical: 12.0),
                                          );
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
                                        totalOwnedAmount < 0
                                            ? "Extra ${totalOwnedAmount.abs()}"
                                            : 'Deuda total: ${order.totalOwned}',
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
                    onPressed: value != null && _montoController.text.isNotEmpty
                        ? () async {
                            double paymentAmount =
                                double.parse(_montoController.text);

                            // Create a new payment
                            PagoModel newPago = PagoModel(
                              date: DateFormat('MM/dd/yyyy')
                                  .format(DateTime.now()),
                              amount: paymentAmount,
                            );

                            // Add the new payment to the order's pagos list
                            cobroOrder.pagos.add(newPago);

                            // Subtract the payment amount from the total owed
                            double newTotalOwed =
                                (double.tryParse(cobroOrder.totalOwned) ??
                                        0.0) -
                                    paymentAmount;

                            // Update the totalOwned amount
                            cobroOrder = cobroOrder.copyWith(
                                totalOwned: newTotalOwed.toString());

                            // If the debt is fully paid, close the order
                            if (newTotalOwed <= 0) {
                              cobroOrder =
                                  cobroOrder.copyWith(status: "cerrado");
                            }

                            // Update the order in the database
                            await dataBaseProvider.updateOrderWithProducts(
                                cobroOrder.id!,
                                cobroOrder,
                                cobroOrder.productList!);

                            // Create a ticket for this payment
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
                                totalCost: paymentAmount,
                              ),
                              cobroOrder.productList!,
                            );

                            final snackBar = SnackBar(
                              content: Text(
                                'Has recibido un pago de ${cobroOrder.clientName} correctamente',
                                style: const TextStyle(
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
                            setState(() {});
                            Navigator.pop(context);
                          }
                        : _montoController.text.isNotEmpty &&
                                _conceptoController.text.isNotEmpty
                            ? () async {
                                double paymentAmount =
                                    double.parse(_montoController.text);

                                // Create a new payment
                                PagoModel newPago = PagoModel(
                                  date: DateFormat('MM/dd/yyyy')
                                      .format(DateTime.now()),
                                  amount: paymentAmount,
                                );

                                // Add the new payment to the order's pagos list
                                cobroOrder.pagos.add(newPago);

                                // Subtract the payment amount from the total owed
                                double newTotalOwed =
                                    (double.tryParse(cobroOrder.totalOwned) ??
                                            0.0) -
                                        paymentAmount;

                                // Update the totalOwned amount
                                cobroOrder = cobroOrder.copyWith(
                                    totalOwned: newTotalOwed.toString());

                                // If the debt is fully paid, close the order
                                if (newTotalOwed <= 0) {
                                  cobroOrder =
                                      cobroOrder.copyWith(status: "cerrado");
                                }

                                // Update the order in the database
                                await dataBaseProvider.updateOrderWithProducts(
                                    cobroOrder.id!,
                                    cobroOrder,
                                    cobroOrder.productList!);

                                // Create a ticket for this payment
                                await dataBaseProvider.createOrderWithProducts(
                                  OrderModel(
                                    pagos: [],
                                    totalOwned: "",
                                    margen: "",
                                    status: "Pago",
                                    clientName: _conceptoController.text,
                                    celNumber: "",
                                    direccion: "",
                                    date: DateTime.now().toString(),
                                    comment: "",
                                    totalCost: paymentAmount,
                                  ),
                                  cobroOrder.productList!,
                                );

                                final snackBar = SnackBar(
                                  content: Text(
                                    'Has recibido un pago de ${_conceptoController.text} correctamente',
                                    style: const TextStyle(
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
