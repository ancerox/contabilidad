import 'dart:io';

import 'package:contabilidad/models/product_model.dart';
import 'package:flutter/material.dart';

class ProductTile extends StatefulWidget {
  final DateTime dateSelected;
  final ProductModel productModel;
  final String imagePath;
  final String productName;
  final ValueChanged<int> onQuantityChanged;
  final int initialQuantity;

  const ProductTile({
    required this.dateSelected,
    required this.productModel,
    super.key,
    required this.imagePath,
    required this.productName,
    required this.onQuantityChanged,
    required this.initialQuantity,
  });

  @override
  _ProductTileState createState() => _ProductTileState();
}

class _ProductTileState extends State<ProductTile> {
  late TextEditingController _controller;
  final ValueNotifier<int> _quantityNotifier = ValueNotifier<int>(0);
  bool isConditionMet = false; // This is the condition variable

  @override
  void initState() {
    super.initState();
    _quantityNotifier.value = widget.initialQuantity;
    _controller =
        TextEditingController(text: _quantityNotifier.value.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    _quantityNotifier.dispose();
    super.dispose();
  }

  void _incrementQuantity() {
    if (_quantityNotifier.value >= calculateStockInUse(widget.productModel)) {
      // Optional: Provide feedback if the condition is not met
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'No puedes exeder el total de ${widget.productModel.name} disponibles')),
      );
      return;
    } else {
      // Check the condition before incrementing
      _quantityNotifier.value++;
      widget.onQuantityChanged(_quantityNotifier.value);
      _controller.text = _quantityNotifier.value.toString();
    }
  }

  void _decrementQuantity() {
    if (_quantityNotifier.value > 0) {
      _quantityNotifier.value--;
      widget.onQuantityChanged(_quantityNotifier.value);
      _controller.text = _quantityNotifier.value.toString();
    }
  }

  void _onQuantityChanged(String value) {
    int? newQuantity = int.tryParse(value);
    if (newQuantity != null) {
      _quantityNotifier.value = newQuantity;
      widget.onQuantityChanged(_quantityNotifier.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        height: 30,
        width: 30,
        decoration: BoxDecoration(
          image: DecorationImage(
            fit: BoxFit.contain,
            image: FileImage(File(widget.imagePath)),
          ),
          color: const Color(0xffD8DFFF),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      title: Text(widget.productName),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: _decrementQuantity,
          ),
          SizedBox(
            width: 40,
            child: ValueListenableBuilder<int>(
              valueListenable: _quantityNotifier,
              builder: (context, quantity, child) {
                return TextFormField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                  ),
                  onChanged: _onQuantityChanged,
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _incrementQuantity,
          ),
        ],
      ),
    );
  }

  int calculateStockInUse(ProductModel productModel) {
    if (productModel.datesUsed != null) {
      final now = widget.dateSelected;
      final totalBorrowed = productModel.datesUsed!
          .where((element) => isDateInRange(now, element.start!, element.end!))
          .fold<int>(0, (sum, element) => sum + (element.borrowQuantity ?? 0));

      final availableStock = productModel.amount - totalBorrowed;
      return availableStock;
    }
    return productModel.amount;
  }

  bool isDateInRange(DateTime date, DateTime start, DateTime end) {
    return date.isAfter(start) && date.isBefore(end) ||
        date.isAtSameMomentAs(start) ||
        date.isAtSameMomentAs(end);
  }
}
