import 'package:contabilidad/database/database.dart';
import 'package:contabilidad/models/order_model.dart';
import 'package:contabilidad/models/product_model.dart';
import 'package:contabilidad/pages/home_page.dart';
import 'package:flutter/material.dart';
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
                          'Cantidad: $quantity\nPrecio por unidad: \$${product.cost.toStringAsFixed(2)}'),
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

    // Filtra los productos que tienen subproductos
    List<ProductModel> productsWithSubproducts = consolidatedProducts
        .where((product) =>
            product.subProduct != null && product.subProduct!.isNotEmpty)
        .toList();

    if (productsWithSubproducts.isNotEmpty) {
      // Reduce la cantidad de los productos en la base de datos
      await dataBase.reduceProductStock(productsWithSubproducts);
    }

    // Crea una orden con el concepto y los productos consolidados
    OrderModel order = OrderModel(
      pagos: [],
      orderNumber: "",
      clientName: concepto,
      celNumber: '',
      direccion: '',
      date: DateTime.now().toString(),
      comment: "",
      totalCost: consolidatedProducts.fold(
          0, (sum, item) => sum + (item.cost * item.quantity!.value)),
      status: 'Compra',
      margen: '',
      totalOwned: '',
    );

    await dataBase.createOrderWithProducts(order, consolidatedProducts);

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => HomePage()),
      (Route<dynamic> route) => false,
    );
  }
}
