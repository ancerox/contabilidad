import 'dart:io';

import 'package:contabilidad/consts.dart';
import 'package:contabilidad/database/database.dart';
import 'package:contabilidad/models/date_range.dart';
import 'package:contabilidad/models/product_model.dart';
import 'package:contabilidad/pages/choose_component_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class CreateProductPage extends StatefulWidget {
  final ProductModel? product;
  final bool isEditPage;

  const CreateProductPage({super.key, required this.isEditPage, this.product});

  @override
  _CreateProductPageState createState() => _CreateProductPageState();
}

final List<String> _units = [
  // Longitud
  'Milímetros (mm)',
  'Centímetros (cm)',
  'Metros (m)',
  'Kilómetros (km)',
  'Pulgadas (in)',
  'Pies (ft)',
  'Yardas (yd)',
  'Millas (mi)',
  // Masa
  'Miligramos (mg)',
  'Gramos (g)',
  'Kilogramos (kg)',
  'Toneladas (t)',
  'Libras (lb)',
  'Onzas (oz)',
  // Volumen
  'Mililitros (ml)',
  'Litros (l)',
  'Metros cúbicos (m³)',
  'Teaspoons (tsp)',
  'Tablespoons (tbsp)',
  'Cups (cup)',
  'Pintas (pt)',
  'Galones (gal)',
  // Y más según necesites...
  "Unidad"
];

class _CreateProductPageState extends State<CreateProductPage> {
  bool isListOfSubProductsDropped = false;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedValue = 'Producto terminado';
  String _selectedValueProductCategory = 'En venta';
  final _costController = TextEditingController();
  final _amountController = TextEditingController();
  final _unitPriceController = TextEditingController();
  late CalendarFormat _calendarFormat;
  late DateTime _focusedDay;
  DateTime? _startDay;
  DateTime? _endDay;
  DateTime? _selectedDay;
  RangeSelectionMode _rangeSelectionMode =
      RangeSelectionMode.toggledOff; // Can be toggled on or off

  ValueNotifier<int> quantity = ValueNotifier<int>(0);
  final Map<int, TextEditingController> _quantityControllers = {};

  final List<ProductModel> _subproducts = [];
  List<DateRange> dateRanges = [];
  List<DateRange> markdateRanges = [];

  String? _selectedUnit;
  late DataBase databaseProvider;
  final List<int> _selectedSubProductIds =
      []; // Asume que cada producto tiene un ID único
  File? _image = File("none");
  ValueNotifier<String> selectedItemNotifier = ValueNotifier('Materia prima');
  ValueNotifier<List<ProductModel>> products = ValueNotifier([]);

  @override
  void dispose() {
    databaseProvider.selectedCommodities.value.clear();
    databaseProvider.selectedProductsNotifier.value.clear();
    _nameController.dispose();
    databaseProvider.selectedCommodities.value.clear();
    _costController.dispose();
    _amountController.dispose();
    _unitPriceController.dispose();
    _quantityControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    getProducts();
    isEditPage();

    _calendarFormat = CalendarFormat.month;
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;
  }

  void isEditPage() {
    if (widget.isEditPage && widget.product != null) {
      databaseProvider.selectedProductsNotifier = products;
      dateRanges = widget.product!.datesNotAvailable!;
      databaseProvider.selectedCommodities =
          ValueNotifier(widget.product!.subProduct ?? []);
      _nameController.text = widget.product!.name;
      _costController.text = widget.product!.cost.toString();
      _amountController.text = widget.product!.amount.toString();
      _unitPriceController.text = widget.product!.unitPrice.toString();
      _selectedUnit = widget.product!.unit;
      _selectedValue = widget.product!.productType;
      _selectedValueProductCategory = widget.product!.productCategory;
      // If your product has an image path, you might want to handle loading the image as well.
      if (widget.product!.file!.isNotEmpty) {
        _image = File(widget.product!.file!);
      }
    }
  }

  void getProducts() async {
    databaseProvider = Provider.of<DataBase>(context, listen: false);
    var productList = await databaseProvider.obtenerProductos();

    products.value = productList
        .where((product) =>
            product.productType.contains(selectedItemNotifier.value))
        .toList();
    for (int i = 0; i < products.value.length; i++) {
      _quantityControllers[i] = TextEditingController(text: "0");
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final product = ProductModel(
          id: widget.product?.id, // Make sure to handle the ID appropriately
          name: _nameController.text,
          cost: _costController.text.isEmpty
              ? 0
              : int.parse(_costController.text) ?? 0,
          amount: int.tryParse(_amountController.text) ?? 0,
          unitPrice: double.tryParse(_unitPriceController.text) ?? 0.0,
          unit: _selectedUnit ?? 'Unidad',
          productType: _selectedValue,
          productCategory: _selectedValue == "Producto terminado"
              ? _selectedValueProductCategory
              : "Otros",
          file: _image?.path ?? '',
          subProduct: databaseProvider.selectedCommodities
              .value, // Assuming you manage subProduct relationships differently
          datesNotAvailable: markdateRanges);

      if (widget.isEditPage && widget.product != null) {
        product.datesUsed = widget.product!.datesUsed;
        // Update existing product
        await databaseProvider.updateProduct(product);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto actualizado con éxito')),
        );
      } else {
        // Insert new product
        await databaseProvider.insertProduct(product);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto agregado con éxito')),
        );
      }
      databaseProvider.selectedCommodities.value.clear();
      databaseProvider.selectedProductsNotifier.value.clear();
      // Clear form and exit the page or reset the state as needed
      Navigator.pop(context);
    }
  }

  Future getImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _image = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // if (databaseProvider.selectedCommodities.value.isNotEmpty) {
    //   int totalCost = databaseProvider.selectedCommodities.value.fold(
    //       0,
    //       (int sum, ProductModel product) =>
    //           sum + product.cost.toInt() * product.quantity!.value);

    //   _costController.text = totalCost.toString();
    // }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agrega un nuevo producto'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () async {
                    var storageStatus = await Permission.storage.status;
                    if (!storageStatus.isGranted) {
                      await Permission.storage.request();
                    }
                    await getImage();
                  },
                  child: _image!.path.length < 5
                      ? Icon(
                          Icons.add_photo_alternate,
                          size: 50,
                          color: Colors.grey[600],
                        )
                      : Container(
                          // You can specify the container size and decoration as needed
                          width: size(context).width * 0.2,
                          // height: 200,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              fit: BoxFit.contain,
                              image: FileImage(File(_image!.path)),
                            ),
                          ),
                        ),
                ),
              ),
              TextFormField(
                controller: _nameController,
                decoration:
                    const InputDecoration(labelText: 'Nombre del producto'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el nombre del producto';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value:
                    _selectedValue, // Asegúrate de definir esta variable en tu clase de estado para controlar el valor seleccionado
                decoration: const InputDecoration(
                  labelText: 'Tipo de producto',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Producto terminado',
                    child: Text('Producto terminado'),
                  ),
                  DropdownMenuItem(
                    value: 'Materia prima',
                    child: Text('Materia prima'),
                  ),
                  DropdownMenuItem(
                    value: 'Servicios',
                    child: Text('Servicios'),
                  ),
                  DropdownMenuItem(
                    value: 'Gasto administrativo',
                    child: Text('Gasto administrativo'),
                  ),
                ],
                onChanged: (value) {
                  // Aquí puedes manejar el cambio de valor. Por ejemplo, actualizando el estado de la variable _selectedValue
                  setState(() {
                    _selectedValue = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor selecciona una categoría';
                  }
                  return null;
                },
              ),
              _selectedValue == "Producto terminado"
                  ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ChooseComponentScreen(),
                            ),
                          ).then((value) {
                            setState(() {});
                          });
                        },
                        child: const Text('Agregar componente'),
                      ),
                    )
                  : Container(),
              ValueListenableBuilder(
                valueListenable: databaseProvider.selectedCommodities,
                builder: (context, value, child) {
                  if (value.isNotEmpty) {
                    return SizedBox(
                      height: 200,
                      child: ListView.builder(
                        itemCount: value.length,
                        itemBuilder: (context, index) {
                          final commoditie = value[index];

                          return Slidable(
                            startActionPane: ActionPane(
                              motion: const DrawerMotion(),
                              children: [
                                SlidableAction(
                                  onPressed: (context) async {
                                    databaseProvider.selectedCommodities.value
                                        .remove(commoditie);
                                    setState(() {});
                                  },
                                  backgroundColor: const Color(0xFFFE4A49),
                                  foregroundColor: Colors.white,
                                  icon: Icons.delete,
                                  label: 'Borrar',
                                ),
                              ],
                            ),
                            child: ListTile(
                              leading: Text(
                                "${commoditie.quantity!.value} x ${commoditie.unit}",
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                              title: SizedBox(
                                width: size(context).width * 0.2,
                                child: Text(
                                  commoditie.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              trailing: Text(
                                "${commoditie.cost * commoditie.quantity!.value}",
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  } else {
                    return _selectedValue == "Producto terminado"
                        ? const Center(
                            child: Text('No tienes ninguno componente aun'))
                        : Container();
                  }
                },
              ),
              _selectedValue == "Producto terminado"
                  ? DropdownButtonFormField<String>(
                      value:
                          _selectedValueProductCategory, // Asegúrate de definir esta variable en tu clase de estado para controlar el valor seleccionado
                      decoration: const InputDecoration(
                        labelText: 'Categoria de producto',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'En venta',
                          child: Text('En venta'),
                        ),
                        DropdownMenuItem(
                          value: 'En alquiler',
                          child: Text('En alquiler'),
                        ),
                      ],
                      onChanged: (value) {
                        // Aquí puedes manejar el cambio de valor. Por ejemplo, actualizando el estado de la variable _selectedValue
                        setState(() {
                          _selectedValueProductCategory = value!;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor selecciona una categoría';
                        }
                        return null;
                      },
                    )
                  : DropdownButtonFormField<String>(
                      value:
                          "Otros", // Asegúrate de definir esta variable en tu clase de estado para controlar el valor seleccionado
                      decoration: const InputDecoration(
                        labelText: 'Categoria de producto',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Otros',
                          child: Text('Otros'),
                        ),
                      ],
                      onChanged: (value) {
                        // // Aquí puedes manejar el cambio de valor. Por ejemplo, actualizando el estado de la variable _selectedValue
                        // setState(() {
                        //   _selectedValueProductCategory = value!;
                        // });
                      },
                      validator: (value) {
                        return null;

                        // if (value == null || value.isEmpty) {
                        //   return 'Por favor selecciona una categoría';
                        // }
                        // return null;
                      },
                    ),
              _selectedValueProductCategory == "En alquiler"
                  ? TableCalendar(
                      enabledDayPredicate: (day) {
                        // Disable selection of days within any of the unavailable ranges
                        for (var range in dateRanges) {
                          if ((range.start != null && range.end != null) &&
                              (day.isAfter(range.start!
                                      .subtract(const Duration(days: 1))) &&
                                  day.isBefore(range.end!
                                      .add(const Duration(days: 1))))) {
                            return false; // This day should not be selectable
                          }
                        }
                        return true; // Other days are selectable
                      },
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        leftChevronVisible: true,
                        rightChevronVisible: true,
                      ),
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) {
                          if (dateRanges.any((markedDate) =>
                              isSameDay(markedDate.start, markedDate.end))) {
                            // This day will have custom styling
                            return Container(
                              margin: const EdgeInsets.all(4.0),
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                day.day.toString(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          } else {
                            // Return null for default styling
                            return null;
                          }
                        },
                      ),
                      firstDay: DateTime.utc(2010, 10, 16),
                      lastDay: DateTime.utc(2030, 3, 14),
                      focusedDay: _focusedDay,
                      rangeSelectionMode: _rangeSelectionMode,
                      // selectedDayPredicate: (day) {
                      //   return isSameDay(_selectedDay, day);
                      // },
                      rangeStartDay: _startDay,
                      rangeEndDay: _endDay,
                      onDaySelected: (selectedDay, focusedDay) {
                        if (_startDay != null &&
                            selectedDay.isAfter(_startDay!) &&
                            _endDay == null) {
                          // End date is not set yet
                          setState(() {
                            _endDay = selectedDay;
                            _focusedDay = focusedDay;
                            _rangeSelectionMode = RangeSelectionMode.toggledOn;
                            markdateRanges
                                .add(DateRange(start: _startDay, end: _endDay));
                          });
                        } else {
                          setState(() {
                            _selectedDay = selectedDay;
                            _startDay = selectedDay;
                            _endDay = null;
                            _focusedDay = focusedDay;
                            _rangeSelectionMode = RangeSelectionMode.toggledOff;
                          });
                        }
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                      },
                      calendarStyle: CalendarStyle(
                        // Customize range style
                        rangeHighlightColor: Colors.black.withOpacity(0.6),
                        rangeStartDecoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        rangeEndDecoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : Container(),
              TextFormField(
                controller: _costController,
                decoration: const InputDecoration(labelText: 'Costo'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Cantidad'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _unitPriceController,
                decoration: const InputDecoration(labelText: 'Precio unitario'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                // validator:
                //     _selectedValueProductCategory == "Gasto administrativo"
                //         ? null
                //         : (value) {
                //             if (value == null || value.isEmpty) {
                //               return 'Por favor ingresa el precio unitario';
                //             }
                //             return null;
                //           },
              ),
              DropdownButtonFormField<String>(
                value: _selectedUnit,
                decoration:
                    const InputDecoration(labelText: 'Unidad de medida'),
                items: _units.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) {
                  // Asumiendo que este código está dentro de una clase State de StatefulWidget
                  setState(() {
                    _selectedUnit = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor selecciona una unidad de medida';
                  }
                  return null;
                },
              ),
              // const SizedBox(height: 24),
              // DropdownButtonFormField<String>(
              //   decoration: const InputDecoration(
              //       labelText: 'Unidad de medida Comprar'),
              //   items: _units.map<DropdownMenuItem<String>>((String value) {
              //     return DropdownMenuItem<String>(
              //       value: value,
              //       child: Text(value),
              //     );
              //   }).toList(),
              //   onChanged: (value) {
              //     // Asumiendo que este código está dentro de una clase State de StatefulWidget
              //     setState(() {
              //       _selectedUnit = value;
              //     });
              //   },
              //   validator: (value) {
              //     if (value == null || value.isEmpty) {
              //       return 'Por favor selecciona una unidad de medida';
              //     }
              //     return null;
              //   },
              // ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Guardar Producto'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// Container(
//                       margin: const EdgeInsets.all(10),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                         children: <Widget>[
//                           for (var option in [
//                             'Materia prima',
//                             'Gasto adminis',
//                             'Servicios'
//                           ])
//                             GestureDetector(
//                               onTap: () {
//                                 // Aquí puedes manejar lo que sucede cuando se selecciona una de las opciones adicionales
//                                 setState(() {
//                                   isListOfSubProductsDropped = true;
//                                   selectedItemNotifier.value = option;

//                                   getProducts();
//                                 });
//                               },
//                               child: Container(
//                                 height: 40,
//                                 width: 110,
//                                 padding: const EdgeInsets.all(0),
//                                 decoration: BoxDecoration(
//                                   borderRadius: BorderRadius.circular(15),
//                                   color: selectedItemNotifier.value == option
//                                       ? const Color.fromARGB(255, 165, 75, 175)
//                                       : const Color.fromARGB(255, 83, 69,
//                                           84), // Color de fondo de cada opción
//                                 ),
//                                 child: Center(
//                                   child: Text(
//                                     option,
//                                     style: const TextStyle(
//                                         fontWeight: FontWeight.w400,
//                                         color: Colors.white), // Texto blanco
//                                   ),
//                                 ),
//                               ),
//                             ),
//                         ],
//                       ),
//                     )

///////////////////////////
///
///
///
///
///
