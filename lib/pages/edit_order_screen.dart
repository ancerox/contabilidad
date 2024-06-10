import 'package:contabilidad/database/database.dart';
import 'package:contabilidad/models/order_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditOrderScreen extends StatefulWidget {
  final OrderModel order;

  const EditOrderScreen({super.key, required this.order});

  @override
  _EditOrderScreenState createState() => _EditOrderScreenState();
}

class _EditOrderScreenState extends State<EditOrderScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController orderNumberController;
  late TextEditingController totalOwnedController;
  late TextEditingController margenController;
  late TextEditingController clientNameController;
  late TextEditingController celNumberController;
  late TextEditingController direccionController;
  late TextEditingController dateController;
  late TextEditingController commentController;
  late TextEditingController totalCostController;
  String? status;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    orderNumberController =
        TextEditingController(text: widget.order.orderNumber);
    totalOwnedController = TextEditingController(text: widget.order.totalOwned);
    margenController = TextEditingController(text: widget.order.margen);
    clientNameController = TextEditingController(text: widget.order.clientName);
    celNumberController = TextEditingController(text: widget.order.celNumber);
    direccionController = TextEditingController(text: widget.order.direccion);
    dateController = TextEditingController(text: widget.order.date);
    commentController = TextEditingController(text: widget.order.comment);
    totalCostController =
        TextEditingController(text: widget.order.totalCost.toString());
    status = widget.order.status;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    orderNumberController.dispose();
    totalOwnedController.dispose();
    margenController.dispose();
    clientNameController.dispose();
    celNumberController.dispose();
    direccionController.dispose();
    dateController.dispose();
    commentController.dispose();
    totalCostController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Orden - ${widget.order.clientName}'),
        backgroundColor: const Color(0xffA338FF),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  controller: orderNumberController,
                  label: 'Número de Orden',
                  icon: Icons.numbers,
                ),
                _buildTextField(
                  controller: totalOwnedController,
                  label: 'Total Adeudado',
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                ),
                _buildTextField(
                  controller: margenController,
                  label: 'Margen',
                  icon: Icons.margin,
                ),
                _buildTextField(
                  controller: clientNameController,
                  label: 'Nombre del Cliente',
                  icon: Icons.person,
                ),
                _buildTextField(
                  controller: celNumberController,
                  label: 'Número de Celular',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
                _buildTextField(
                  controller: direccionController,
                  label: 'Dirección',
                  icon: Icons.location_on,
                ),
                _buildTextField(
                  controller: dateController,
                  label: 'Fecha',
                  icon: Icons.date_range,
                ),
                _buildTextField(
                  controller: commentController,
                  label: 'Comentario',
                  icon: Icons.comment,
                ),
                _buildTextField(
                  controller: totalCostController,
                  label: 'Costo Total',
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                ),
                _buildDropdownButton(),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: _saveOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffA338FF),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      textStyle: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Guardar Cambios',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildDropdownButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        value: status,
        decoration: InputDecoration(
          labelText: 'Estado',
          prefixIcon: const Icon(Icons.list),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        items: ['pendiente', 'pago', 'cerrado', 'compra']
            .map((status) => DropdownMenuItem(
                  value: status,
                  child: Text(status),
                ))
            .toList(),
        onChanged: (value) {
          setState(() {
            status = value;
          });
        },
      ),
    );
  }

  void _saveOrder() async {
    // Save the edited order
    OrderModel updatedOrder = OrderModel(
      pagos: [],
      id: widget.order.id,
      orderNumber: orderNumberController.text,
      totalOwned: totalOwnedController.text,
      margen: margenController.text,
      status: status!,
      clientName: clientNameController.text,
      celNumber: celNumberController.text,
      direccion: direccionController.text,
      productList: widget.order.productList,
      date: dateController.text,
      comment: commentController.text,
      totalCost: double.parse(totalCostController.text),
    );

    // Update the order in the database
    final database = Provider.of<DataBase>(context, listen: false);
    // await database.updateOrderWithProducts(updatedOrder.id!, updatedOrder);

    Navigator.pop(context, updatedOrder);
  }
}
