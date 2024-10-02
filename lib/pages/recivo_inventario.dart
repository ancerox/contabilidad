import 'dart:io';

import 'package:contabilidad/database/database.dart';
import 'package:contabilidad/models/order_model.dart';
import 'package:contabilidad/models/product_model.dart';
import 'package:contabilidad/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

class ReceiptPage extends StatefulWidget {
  final List<ProductModel> selectedProducts;

  const ReceiptPage({super.key, required this.selectedProducts});

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  final TextEditingController conceptoController = TextEditingController();
  late DataBase dataBaseProvider;

  @override
  void initState() {
    dataBaseProvider = Provider.of<DataBase>(context, listen: false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double totalCost = widget.selectedProducts.fold(
        0,
        (previousValue, product) =>
            previousValue + (product.cost * product.quantity!.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recibo de Compra',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const ListTile(
                leading: Icon(Icons.receipt_long,
                    size: 50, color: Colors.deepPurple),
                title: Text('Productos Comprados',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: widget.selectedProducts.length,
                  itemBuilder: (BuildContext context, int index) {
                    final product = widget.selectedProducts[index];
                    final quantity = product.quantity!.value;
                    return ListTile(
                      title: Text(product.name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          'Cantidad: $quantity\nPrecio total de item: \$${product.cost * product.quantity!.value}'),
                    );
                  },
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  controller: conceptoController,
                  decoration: const InputDecoration(
                    labelText: 'Concepto',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text('Costo Total:',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple)),
                    Text('\$${totalCost.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () async {
                    // Lógica para exportar a Excel
                    final order = OrderModel(
                      orderId: "COMPRA",
                      pagos: [],
                      orderNumber: "",
                      clientName: conceptoController.text,
                      celNumber: '',
                      direccion: '',
                      date: DateTime.now().toString(),
                      comment: "",
                      totalCost:
                          widget.selectedProducts.fold(0.0, (sum, product) {
                        return sum + (product.cost * product.quantity!.value);
                      }),
                      status: 'Compra',
                      margen: '',
                      totalOwned: '',
                      productList: widget.selectedProducts,
                    );
                    final pdf = pw.Document();
                    final countDB =
                        await dataBaseProvider.getTotalOrdersCount("COMPRA");
                    DateTime parsedDate = DateTime.parse(order.date);

                    pdf.addPage(
                      pw.Page(
                        build: (pw.Context context) {
                          return pw.Column(
                            children: [
                              // Encabezado del recibo
                              pw.Text('Recibo de Compra',
                                  style: const pw.TextStyle(fontSize: 24)),
                              pw.SizedBox(height: 8),
                              pw.Text('Gracias por tu compra'),
                              pw.SizedBox(height: 8),
                              pw.Text(
                                  'Este es el recibo de la compra de tu producto.'),
                              pw.Divider(),

                              // Detalles del pedido
                              pw.Row(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text('Número de Pedido'),
                                  pw.Text(countDB.toString()),
                                ],
                              ),
                              pw.SizedBox(height: 8),
                              pw.Row(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text('Fecha'),
                                  pw.Text(DateFormat('d MMMM y')
                                      .format(parsedDate)),
                                ],
                              ),

                              pw.Divider(),

                              // Lista de productos
                              pw.Text('Productos Comprados:',
                                  style: const pw.TextStyle(fontSize: 18)),
                              pw.ListView.builder(
                                itemCount: order.productList!.length,
                                itemBuilder: (context, index) {
                                  final product = order.productList![index];
                                  return pw.Row(
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.spaceBetween,
                                    children: [
                                      pw.Text(
                                          '${product.quantity!.value} x ${product.name}'),
                                      pw.Text(
                                          "\$${product.cost * product.quantity!.value}"),
                                    ],
                                  );
                                },
                              ),
                              pw.Divider(),

                              // Precio total
                              pw.Row(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text('Precio total'),
                                  pw.Text('\$${order.totalCost}'),
                                ],
                              ),
                              pw.Divider(),

                              // Pagos
                              if (order.pagos.isNotEmpty)
                                pw.Text('Pagos:',
                                    style: const pw.TextStyle(fontSize: 18)),
                              if (order.pagos.isNotEmpty)
                                pw.ListView.builder(
                                  itemCount: order.pagos.length,
                                  itemBuilder: (context, index) {
                                    final pago = order.pagos[index];
                                    return pw.Row(
                                      mainAxisAlignment:
                                          pw.MainAxisAlignment.spaceBetween,
                                      children: [
                                        pw.Text(
                                            'Pago de \$${pago.amount.toStringAsFixed(2)}'),
                                        pw.Text('Fecha: ${pago.date}'),
                                      ],
                                    );
                                  },
                                ),

                              pw.Divider(),

                              // Estado y Comentarios
                              pw.Row(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text('Estado'),
                                  pw.Text(order.status),
                                ],
                              ),
                              pw.SizedBox(height: 8),
                              pw.Row(
                                // mainAxisAlignment: pw
                                //     .dMainAxisAlignment.spaceBetween, // Distribute space evenly
                                crossAxisAlignment: pw.CrossAxisAlignment
                                    .center, // Align the items at the top
                                children: [
                                  pw.Text('Comentario:${order.clientName}',
                                      maxLines:
                                          1), // The label stays fixed in its space
                                  pw.SizedBox(
                                      width:
                                          10), // Optional space between label and text
                                  pw.Expanded(
                                    child: pw.Text(
                                      order.comment,
                                      textAlign: pw.TextAlign
                                          .left, // Ensure text is justified
                                      overflow: pw.TextOverflow
                                          .clip, // Clip the overflow
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    );

                    // Guardar o imprimir el PDF
                    // await Printing.layoutPdf(
                    //     onLayout: (PdfPageFormat format) async => pdf.save());

                    // Guardar el PDF en un archivo
                    final output = await getApplicationDocumentsDirectory();
                    final file =
                        File("${output.path}/compra_${order.orderId}.pdf");
                    await file.writeAsBytes(await pdf.save());

                    // Mostrar el PDF para imprimir o compartir
                    await Printing.sharePdf(
                        bytes: await pdf.save(),
                        filename: 'compra_${order.orderId}.pdf');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Exportar a PDF',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () async {
                    await updateMultipleProducts(context,
                        conceptoController.text, widget.selectedProducts);

                    final snackBar = SnackBar(
                      content: const Text(
                        'Has agregado productos correctamente',
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: Colors.deepPurple,
                      duration: const Duration(seconds: 3),
                      action: SnackBarAction(
                        label: 'Deshacer',
                        textColor: Colors.amber,
                        onPressed: () {
                          // Código para deshacer la acción aquí
                        },
                      ),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 12.0),
                    );

                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple),
                  child: const Text('Aceptar',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> updateMultipleProducts(BuildContext context, String concepto,
      List<ProductModel> consolidatedProducts) async {
    final dataBase = Provider.of<DataBase>(context, listen: false);

    // This list will store products with their original quantity preserved for creating the order
    List<ProductModel> productsForOrder = [];

    for (var product in consolidatedProducts) {
//update cost
      product.quantity = ValueNotifier(0);
      await dataBase.updateProduct(product);

      // Preserve the original quantity for order creation
      productsForOrder.add(
          product.copyWith(quantity: ValueNotifier(product.quantity!.value)));

      if (product.productType == 'Servicios' ||
          product.productType == "Gasto administrativo") {
        continue;
      } else {
        double newAmount = product.amount + product.quantity!.value;
        product.amount = newAmount;

        // Reset quantity to 0 after updating the amount
        double quantityUsed = product.quantity!.value;
        // product.quantity = ValueNotifier(0);
        // await dataBase.updateProduct(product);

        if (product.subProduct != null && product.subProduct!.isNotEmpty) {
          for (var subProduct in product.subProduct!) {
            var subProductFromDb =
                await dataBase.getProductById(subProduct.id!);
            if (subProductFromDb != null &&
                subProductFromDb.productType == "Materia prima") {
              double newSubProductAmount = subProductFromDb.amount -
                  subProduct.quantity!.value * quantityUsed;
              subProductFromDb.amount = newSubProductAmount;

              // Reset sub-product quantity to 0
              subProductFromDb.quantity = ValueNotifier(0);
              await dataBase.updateProduct(subProductFromDb);
            }
          }
        }
      }
    }

    final countDB = await dataBase.getTotalOrdersCount("COMPRA");

    // Crear orden de transacción
    OrderModel orderTra = OrderModel(
      orderId: "COMPRA $countDB",
      productList: [],
      pagos: [],
      orderNumber: "",
      clientName: concepto,
      celNumber: '',
      direccion: '',
      date: DateFormat('MM/dd/yyyy').format(DateTime.now()).toString(),
      comment: "",
      totalCost: productsForOrder.fold(
          0, (sum, item) => sum + (item.cost * item.quantity!.value)),
      status: 'Compra',
      margen: 'test',
      totalOwned: '',
    );

    // Crear orden de compra
    OrderModel order = OrderModel(
      orderId: "COMPRA $countDB",
      productList: productsForOrder,
      pagos: [],
      orderNumber: "",
      clientName: concepto,
      celNumber: '',
      direccion: '',
      date: DateFormat('MM/dd/yyyy').format(DateTime.now()).toString(),
      comment: "",
      totalCost: productsForOrder.fold(
          0, (sum, item) => sum + (item.cost * item.quantity!.value)),
      status: 'Compra',
      margen: '',
      totalOwned: '',
    );
    OrderModel orderProduccion = OrderModel(
      orderId: "COMPRA $countDB",
      productList: productsForOrder,
      pagos: [],
      orderNumber: "",
      clientName: concepto,
      celNumber: '',
      direccion: '',
      date: DateFormat('MM/dd/yyyy').format(DateTime.now()).toString(),
      comment: "",
      totalCost: productsForOrder.fold(
          0, (sum, item) => sum + (item.cost * item.quantity!.value) * -1),
      status: 'Produccion',
      margen: 'test',
      totalOwned: '',
    );

    await dataBase.createOrderWithProducts(orderTra, []);
    await dataBase.createOrderWithProducts(order, productsForOrder);
    if (productsForOrder.any((element) =>
        element.subProduct != null && element.subProduct!.isNotEmpty)) {
      await dataBase.createOrderWithProducts(orderProduccion, productsForOrder);
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomePage()),
      (Route<dynamic> route) => false,
    );
  }
}
