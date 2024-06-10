import 'package:contabilidad/models/product_model.dart';
import 'package:contabilidad/pages/checkout.dart';
import 'package:contabilidad/widget/item_widget.dart';
import 'package:flutter/material.dart';

class PickItemBuy extends StatefulWidget {
  final List<ProductModel> products;

  const PickItemBuy({super.key, required this.products});

  @override
  State<PickItemBuy> createState() => _PickItemBuyState();
}

class _PickItemBuyState extends State<PickItemBuy> {
  final _controller = TextEditingController();
  ValueNotifier<List<ProductModel>> products = ValueNotifier([]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Escoge un producto"),
      ),
      body: products.value.isEmpty
          ? Container(
              padding: const EdgeInsets.all(
                  20.0), // Añade padding alrededor del texto
              margin: const EdgeInsets.all(
                  20.0), // Añade margen alrededor del Container
              decoration: BoxDecoration(
                color: Colors.white, // Define el color de fondo del Container
                borderRadius: BorderRadius.circular(
                    20.0), // Define los bordes redondeados
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5), // Color de la sombra
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset:
                        const Offset(0, 3), // Cambios de posición de la sombra
                  ),
                ],
              ),
              child: const Text(
                "Aún no has agregado ningún producto a tu inventario",
                textAlign: TextAlign.center, // Centra el texto horizontalmente
                style: TextStyle(
                  fontSize: 16.0, // Tamaño del texto
                  color: Colors.black, // Color del texto
                ),
              ),
            )
          : Container(
              child: ListView.builder(
                itemCount: widget.products.length,
                itemBuilder: (context, index) {
                  // Make sure 'Item' widget is defined or replace it with an appropriate widget
                  return GestureDetector(
                    onTap: () async {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => CheckoutScreen(
                                    product: products.value[index],
                                  )));
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Item(
                        // This seems to be a custom widget. Ensure it's defined elsewhere in your code.
                        amount: widget.products[index].amount,
                        name: widget.products[index].name,
                        precio: widget.products[index].unitPrice,
                        imagePath: widget.products[index].file!,
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}


/// 
///    if (_controller.text.isNotEmpty &&
                      //     int.parse(_controller.text) > 0) {
                      //   final result = await showConfirmDialog(context,
                      //       '¿Estás seguro de que deseas agregar ${_controller.text} DOP a este artículo al inventario?');
                      //   if (result) {
                      //     final int pago = int.parse(_controller.text);
                      //     final costo = widget.products[index].cost;

                      //     if (pago % costo == 0) {
                      //       int veces = pago ~/ costo;
                      //       int vecesTotal =
                      //           veces + widget.products[index].amount;

                      //       await dataBaseProvider.updateProductAmount(
                      //           widget.products[index].id!, vecesTotal);

                      //       final snackBar = SnackBar(
                      //           backgroundColor: Colors.green,
                      //           content: Text(
                      //               'Agregaste 1 o mas ${widget.products[index].unit} de ${widget.products[index].name}'));
                      //       ScaffoldMessenger.of(context)
                      //           .showSnackBar(snackBar);
                      //       _controller.clear();
                      //       setState(() {});
                      //     } else {
                      //       final snackBar = SnackBar(
                      //           content: Text(
                      //               'La cantidad del pago no es exacta para ${widget.products[index].name}'));
                      //       ScaffoldMessenger.of(context)
                      //           .showSnackBar(snackBar);
                      //     }
                      //   } else {
                      //     print('Acción cancelada');
                      //   }
                      // } else {
                      //   const snackBar = SnackBar(
                      //       backgroundColor: Colors.red,
                      //       content: Text('Seleccione un monto primero'));
                      //   ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      // }
/// 