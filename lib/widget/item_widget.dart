import 'dart:io';

import 'package:contabilidad/consts.dart';
import 'package:contabilidad/models/product_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gradient_widgets/gradient_widgets.dart';

class Item extends StatefulWidget {
  final String imagePath;
  final String name;
  final double precio;
  final int? amount;
  final bool? hasLeading;
  final bool? hasTrailing;
  final String? magnitud;
  final VoidCallback? minus;
  final VoidCallback? plus;
  final List<ProductModel>? subProducts;

  final void Function(String)? unitPriceOnChange;
  final void Function(String)? quantityOnChange;
  final void Function(String)? costOnChange;
  final void Function(String)? onFieldSubmitted;

  final double? cost;
  final TextEditingController? costCTRController;
  final TextEditingController? quantityCTRController;
  final TextEditingController? unitPriceCTRController;
  ValueNotifier<int>? quantity;

  Item({
    this.subProducts,
    this.onFieldSubmitted,
    this.unitPriceCTRController,
    this.unitPriceOnChange,
    this.costOnChange,
    this.quantityOnChange,
    this.quantityCTRController,
    this.costCTRController,
    this.cost,
    this.plus,
    this.quantity,
    this.minus,
    this.magnitud,
    this.hasTrailing,
    this.hasLeading,
    required this.imagePath,
    required this.name,
    required this.precio,
    this.amount,
    super.key,
  });

  @override
  State<Item> createState() => _ItemState();
}

class _ItemState extends State<Item> {
  bool isDetailedPressed = false;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: widget.quantity ?? ValueNotifier<int>(0),
        builder: (context, value, child) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            // height: size(context).height * 0.11,
            decoration: BoxDecoration(
              gradient: value > 0 ? Gradients.backToFuture : null,
              color: value > 0
                  ? Gradients.backToFuture.colors.last.withOpacity(0.25)
                  : null,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                width: 1.5,
                color: const Color(0xffD0A6FA),
              ),
            ),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(minHeight: 100), // Adjust as needed
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: widget.quantityCTRController == null
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            widget.imagePath == "none"
                                ? Container(
                                    height: 50,
                                    width: 50,
                                    decoration: BoxDecoration(
                                        image: const DecorationImage(
                                          scale: 17.0,
                                          // fit: BoxFit.none,
                                          image: AssetImage(
                                              "assets/icons/icon.jpeg"),
                                        ),
                                        color: const Color(0xffD8DFFF),
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  )
                                : Container(
                                    height: 40,
                                    width: 40,
                                    decoration: BoxDecoration(
                                        image: DecorationImage(
                                          fit: BoxFit.fitHeight,
                                          image:
                                              FileImage(File(widget.imagePath)),
                                        ),
                                        color: const Color(0xffD8DFFF),
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                            const SizedBox(
                              height: 5,
                            ),
                            widget.subProducts == null
                                ? Container()
                                : widget.subProducts!.isEmpty
                                    ? Container()
                                    : GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            isDetailedPressed =
                                                !isDetailedPressed;
                                          });
                                        },
                                        child: Container(
                                          height: 15,
                                          width: 40,
                                          decoration: BoxDecoration(
                                            color: isDetailedPressed
                                                ? const Color.fromARGB(
                                                    255, 255, 255, 255)
                                                : const Color.fromARGB(
                                                    255, 215, 53, 255),
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                          child: const Center(
                                            child: Text(
                                              'Detalles',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                        ),
                                      )
                          ],
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        widget.costCTRController == null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.name,
                                    overflow: TextOverflow
                                        .ellipsis, // Use ellipsis to indicate truncation
                                    style: subtitles.copyWith(
                                        color: Colors.black, fontSize: 15),
                                  ),
                                  widget.unitPriceCTRController != null
                                      ? Container()
                                      : Text(
                                          "Costo: ${widget.cost.toString()} ${widget.magnitud}",
                                          overflow: TextOverflow
                                              .ellipsis, // Changed to ellipsis to indicate text truncation more clearly
                                          style: subtitles.copyWith(
                                              color: Colors.black,
                                              fontSize: 15),
                                        ),
                                  widget.unitPriceCTRController == null
                                      ? Container()
                                      : Row(
                                          children: [
                                            Container(
                                              decoration: const BoxDecoration(
                                                  color: Color.fromARGB(
                                                      255, 235, 235, 235)),
                                              height: 30,
                                              width:
                                                  70, // Define un ancho específico para el Container
                                              child: TextFormField(
                                                onChanged: widget.costOnChange,
                                                maxLines: 1,
                                                textAlign: TextAlign.left,
                                                inputFormatters: <TextInputFormatter>[
                                                  FilteringTextInputFormatter
                                                      .digitsOnly, // Acepta solo dígitos
                                                ],
                                                style: const TextStyle(
                                                    overflow:
                                                        TextOverflow.visible,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16),
                                                controller: widget
                                                    .unitPriceCTRController,
                                                keyboardType:
                                                    TextInputType.number,
                                                decoration:
                                                    const InputDecoration(
                                                        isDense: true,
                                                        contentPadding:
                                                            EdgeInsets.fromLTRB(
                                                                2.0,
                                                                2.0,
                                                                2.0,
                                                                2.0),
                                                        border:
                                                            InputBorder.none),
                                              ),
                                            ),
                                            Container(
                                              decoration: const BoxDecoration(
                                                  color: Color.fromARGB(
                                                      255, 235, 235, 235)),
                                              height: 30,
                                              width: 20,
                                              child: const Center(
                                                child: Text(
                                                  "\$",
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                  widget.unitPriceCTRController == null
                                      ? Container()
                                      : Text(
                                          "Costo: ${widget.cost.toString()}",
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w500),
                                        ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.name,
                                    style: subtitles.copyWith(
                                        color: Colors.black, fontSize: 15),
                                  ),
                                  widget.costCTRController == null
                                      ? widget.quantityCTRController == null
                                          ? Text(
                                              "\$${widget.amount == 0 ? widget.cost : widget.amount! * widget.cost!} DOP",
                                              textAlign: TextAlign.start,
                                              style: subtitles.copyWith(
                                                  color: Colors.black,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w400),
                                            )
                                          : Container()
                                      : Row(
                                          children: [
                                            Container(
                                              decoration: const BoxDecoration(
                                                  color: Color.fromARGB(
                                                      255, 235, 235, 235)),
                                              height: 35,
                                              width:
                                                  40, // Define un ancho específico para el Container
                                              child: TextFormField(
                                                onChanged: widget.costOnChange,
                                                maxLines: 1,
                                                textAlign: TextAlign.left,
                                                inputFormatters: <TextInputFormatter>[
                                                  FilteringTextInputFormatter
                                                      .digitsOnly, // Acepta solo dígitos
                                                ],
                                                style: const TextStyle(
                                                    overflow:
                                                        TextOverflow.visible,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16),
                                                controller:
                                                    widget.costCTRController,
                                                keyboardType:
                                                    TextInputType.number,
                                                decoration:
                                                    const InputDecoration(
                                                        isDense: true,
                                                        contentPadding:
                                                            EdgeInsets.fromLTRB(
                                                                2.0,
                                                                2.0,
                                                                2.0,
                                                                2.0),
                                                        border:
                                                            InputBorder.none),
                                              ),
                                            ),
                                            Container(
                                              decoration: const BoxDecoration(
                                                  color: Color.fromARGB(
                                                      255, 235, 235, 235)),
                                              height: 35,
                                              width: 50,
                                              child: const Center(
                                                child: Text(
                                                  "DOP",
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                  Text(
                                    "Costo total ${widget.cost! * widget.quantity!.value}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  )
                                ],
                              ),
                        // const Spacer(),
                        widget.hasTrailing == true
                            ? Container(
                                // height: 40,
                                width: size(context).width * 0.38,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: const Color.fromARGB(
                                        255, 255, 241, 255)),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      onPressed: widget.minus,
                                      icon: SvgPicture.asset(
                                        'assets/icons/minus.svg',
                                        width: 10,
                                      ),
                                    ),
                                    ValueListenableBuilder(
                                      valueListenable: widget.quantity!,
                                      builder: (context, value, child) {
                                        Future.microtask(() {
                                          if (mounted) {
                                            widget.quantityCTRController!.text =
                                                value.toString();
                                          }
                                        });
                                        return Container(
                                          decoration: const BoxDecoration(
                                              color: Color.fromARGB(
                                                  255, 235, 235, 235)),
                                          height: 30,
                                          width:
                                              30, // Define un ancho específico para el Container
                                          child: TextFormField(
                                            onChanged: widget.quantityOnChange,
                                            maxLines: 1,
                                            textAlign: TextAlign.left,
                                            inputFormatters: <TextInputFormatter>[
                                              FilteringTextInputFormatter
                                                  .digitsOnly, // Acepta solo dígitos
                                            ],
                                            style: const TextStyle(
                                                overflow: TextOverflow.visible,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16),
                                            controller:
                                                widget.quantityCTRController,
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                                isDense: true,
                                                contentPadding:
                                                    EdgeInsets.fromLTRB(
                                                        2.0, 2.0, 2.0, 2.0),
                                                border: InputBorder.none),
                                          ),
                                        );
                                      },
                                    ),
                                    Container(
                                      decoration: const BoxDecoration(
                                          color: Color.fromARGB(
                                              255, 235, 235, 235)),
                                      height: 30,
                                      width: 30,
                                      child: Center(
                                        child: Text(
                                          widget.magnitud!.substring(0, 3),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: widget.plus,
                                      icon: const Icon(
                                        Icons.add,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.amount.toString(),
                                    style: subtitles.copyWith(
                                        color: Colors.black, fontSize: 15),
                                  ),
                                  Text("Artciulos",
                                      style: subtitles.copyWith(
                                          color: Colors.black, fontSize: 15)),
                                ],
                              ),
                      ],
                    ),
                  ),
                  isDetailedPressed
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: widget.subProducts!.map((subProduct) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 5),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        subProduct.quantity!.value.toString(),
                                        style: const TextStyle(
                                            overflow: TextOverflow
                                                .ellipsis), // Prevents text overflow.
                                      ),
                                    ),
                                    const SizedBox(
                                        width: 10), // Space between columns
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        subProduct.unit,
                                        style: const TextStyle(
                                            overflow: TextOverflow
                                                .ellipsis), // Prevents text overflow.
                                      ),
                                    ),
                                    const SizedBox(
                                        width: 40), // Space between columns
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        "${subProduct.name} ${subProduct.cost * subProduct.quantity!.value} DOP",
                                        style: const TextStyle(
                                            overflow: TextOverflow
                                                .ellipsis), // Prevents text overflow.
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        )
                      : Container()
                ],
              ),
            ),
          );
        });
  }
}

class CardWidget extends StatelessWidget {
  final String title;
  final String inventary;
  final int count;
  final Gradient gradient;

  const CardWidget(
      {super.key,
      required this.inventary,
      required this.title,
      required this.count,
      required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      height: 90,
      width: 185,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15), gradient: gradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            inventary,
            style: subtitles.copyWith(fontSize: 20),
          ),
          Text(
            title,
            style: subtitles.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
