import 'dart:io';

import 'package:contabilidad/models/product_model.dart';
import 'package:flutter/material.dart';

class CheckoutScreen extends StatefulWidget {
  final ProductModel product;
  const CheckoutScreen({super.key, required this.product});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int quantity = 0;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agregar ${widget.product.name}',
            style: const TextStyle(fontSize: 24)),
      ),
      body: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              // You can specify the container size and decoration as needed
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: const Color.fromARGB(255, 247, 235, 249),
                image: DecorationImage(
                  fit: BoxFit.contain,
                  image: FileImage(File(widget.product.file!)),
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              ElevatedButton(
                onPressed: () {
                  if (quantity != 0) {
                    setState(() {
                      quantity--;
                      _amountController.text = quantity.toString();
                    });
                  }
                },
                child: const Icon(Icons.minimize),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: 100, // Define un ancho específico para el Container
                child: TextField(
                  onChanged: (String value) {
                    setState(() {
                      // Intenta convertir el valor del texto a un número. Si falla, usa 0.
                      int newValue = int.tryParse(value) ?? 0;
                      quantity =
                          newValue; // Actualiza la cantidad con el nuevo valor.
                      // No es necesario actualizar _amountController.text aquí ya que
                      // el cambio del valor del campo ya está siendo reflejado en el TextField.
                    });
                  },
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 40),
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    quantity++;
                    _amountController.text = quantity.toString();
                  });
                },
                child: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(
            height: 30,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: (String value) {
                setState(() {});
              },
              controller: _totalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Costo total',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Center(
            child: Container(
              // Establece el ancho y alto del botón
              width: 200, // Ancho del botón
              height: 70, // Alto del botón
              // Opcional: Agrega un margen alrededor del botón
              margin: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: quantity >= 1 && _totalController.text.isNotEmpty
                    ? () async {}
                    : null,
                style: ElevatedButton.styleFrom(
                  // Personalización adicional aquí, por ejemplo:
                  textStyle: const TextStyle(fontSize: 20), // Tamaño del texto

                  shape: RoundedRectangleBorder(
                    // Forma del botón
                    borderRadius:
                        BorderRadius.circular(10), // Esquinas redondeadas
                  ),
                ),
                child: const Text('Siguiente'),
              ),
            ),
          )
        ],
      ),
    );
  }
}
