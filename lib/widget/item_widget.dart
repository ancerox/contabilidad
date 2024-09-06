import 'dart:io';

import 'package:contabilidad/consts.dart';
import 'package:contabilidad/models/product_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  final int? cost;
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return ValueListenableBuilder(
        valueListenable: widget.quantity ?? ValueNotifier<int>(0),
        builder: (context, value, child) {
          return Container(
            margin: EdgeInsets.symmetric(
              vertical: screenHeight * 0.01,
              horizontal: screenWidth * 0.02,
            ),
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
              constraints: const BoxConstraints(minHeight: 100), // Ajustable
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.02,
                      vertical: screenHeight * 0.01,
                    ),
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
                                    height: screenHeight * 0.07,
                                    width: screenHeight * 0.07,
                                    decoration: BoxDecoration(
                                        image: const DecorationImage(
                                          scale: 17.0,
                                          image: AssetImage(
                                              "assets/icons/icon.jpeg"),
                                        ),
                                        color: const Color(0xffD8DFFF),
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  )
                                : Container(
                                    height: screenHeight * 0.07,
                                    width: screenHeight * 0.07,
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
                            SizedBox(
                              height: screenHeight * 0.01,
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
                                          height: screenHeight * 0.03,
                                          width: screenWidth * 0.15,
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
                        SizedBox(
                          width: screenWidth * 0.03,
                        ),
                        widget.costCTRController == null
                            ? Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: subtitles.copyWith(
                                          color: Colors.black,
                                          fontSize: screenHeight * 0.02),
                                    ),
                                    widget.unitPriceCTRController != null
                                        ? Container()
                                        : Text(
                                            "Costo: ${widget.cost.toString()} ${widget.magnitud}",
                                            overflow: TextOverflow.ellipsis,
                                            style: subtitles.copyWith(
                                                color: Colors.black,
                                                fontSize: screenHeight * 0.018),
                                          ),
                                    widget.unitPriceCTRController == null
                                        ? Container()
                                        : Row(
                                            children: [
                                              Container(
                                                decoration:
                                                    const BoxDecoration(),
                                                height: screenHeight * 0.04,
                                                width: screenWidth * 0.18,
                                                child: TextFormField(
                                                  onChanged:
                                                      widget.unitPriceOnChange,
                                                  maxLines: 1,
                                                  textAlign: TextAlign.left,
                                                  inputFormatters: <TextInputFormatter>[
                                                    FilteringTextInputFormatter
                                                        .digitsOnly,
                                                  ],
                                                  style: TextStyle(
                                                      overflow:
                                                          TextOverflow.visible,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize:
                                                          screenHeight * 0.02),
                                                  controller: widget
                                                      .unitPriceCTRController,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  decoration:
                                                      const InputDecoration(
                                                          isDense: true,
                                                          contentPadding:
                                                              EdgeInsets
                                                                  .fromLTRB(
                                                                      2.0,
                                                                      2.0,
                                                                      2.0,
                                                                      2.0),
                                                          border:
                                                              InputBorder.none),
                                                ),
                                              ),
                                              Container(
                                                decoration:
                                                    const BoxDecoration(),
                                                height: screenHeight * 0.04,
                                                width: screenWidth * 0.05,
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
                                ),
                              )
                            : Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      overflow: TextOverflow.ellipsis,
                                      widget.name,
                                      style: subtitles.copyWith(
                                          color: Colors.black,
                                          fontSize: screenHeight * 0.02),
                                    ),
                                    widget.costCTRController == null
                                        ? widget.quantityCTRController == null
                                            ? Text(
                                                "\$${widget.amount == 0 ? widget.cost : widget.amount! * widget.cost!} DOP",
                                                textAlign: TextAlign.start,
                                                style: subtitles.copyWith(
                                                    color: Colors.black,
                                                    fontSize:
                                                        screenHeight * 0.018,
                                                    fontWeight:
                                                        FontWeight.w400),
                                              )
                                            : Container()
                                        : Row(
                                            children: [
                                              ConstrainedBox(
                                                constraints: BoxConstraints(
                                                    maxWidth:
                                                        screenWidth * 0.15),
                                                child: TextFormField(
                                                  onChanged:
                                                      widget.costOnChange,
                                                  maxLines: 1,
                                                  textAlign: TextAlign.left,
                                                  inputFormatters: <TextInputFormatter>[
                                                    FilteringTextInputFormatter
                                                        .digitsOnly,
                                                  ],
                                                  style: TextStyle(
                                                      overflow:
                                                          TextOverflow.visible,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize:
                                                          screenHeight * 0.02),
                                                  controller:
                                                      widget.costCTRController,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  decoration:
                                                      const InputDecoration(
                                                          isDense: true,
                                                          contentPadding:
                                                              EdgeInsets
                                                                  .fromLTRB(
                                                                      2.0,
                                                                      2.0,
                                                                      2.0,
                                                                      2.0),
                                                          border:
                                                              InputBorder.none),
                                                ),
                                              ),
                                              Container(
                                                decoration:
                                                    const BoxDecoration(),
                                                height: screenHeight * 0.04,
                                                width: screenWidth * 0.1,
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
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: screenHeight * 0.018),
                                    )
                                  ],
                                ),
                              ),
                        widget.hasTrailing == true
                            ? Container(
                                width: screenWidth * 0.4,
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
                                    Flexible(
                                      child: ValueListenableBuilder(
                                        valueListenable: widget.quantity!,
                                        builder: (context, value, child) {
                                          Future.microtask(() {
                                            if (mounted) {
                                              widget.quantityCTRController!
                                                  .text = value.toString();
                                            }
                                          });
                                          return ConstrainedBox(
                                            constraints: BoxConstraints(
                                              maxWidth: screenWidth * 0.15,
                                            ),
                                            child: TextFormField(
                                              onChanged:
                                                  widget.quantityOnChange,
                                              maxLines: 1,
                                              textAlign: TextAlign.center,
                                              inputFormatters: <TextInputFormatter>[
                                                FilteringTextInputFormatter
                                                    .digitsOnly,
                                              ],
                                              style: TextStyle(
                                                  overflow:
                                                      TextOverflow.visible,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize:
                                                      screenHeight * 0.02),
                                              controller:
                                                  widget.quantityCTRController,
                                              keyboardType:
                                                  TextInputType.number,
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
                                    ),
                                    Container(
                                      decoration: const BoxDecoration(),
                                      height: screenHeight * 0.04,
                                      width: screenWidth * 0.1,
                                      child: Center(
                                        child: Text(
                                          widget.magnitud!.substring(0, 3),
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: screenHeight * 0.018),
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
                                        color: Colors.black,
                                        fontSize: screenHeight * 0.018),
                                  ),
                                  Text("Artículos",
                                      style: subtitles.copyWith(
                                          color: Colors.black,
                                          fontSize: screenHeight * 0.018)),
                                ],
                              ),
                      ],
                    ),
                  ),
                  isDetailedPressed
                      ? Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.05),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: widget.subProducts!.map((subProduct) {
                              return Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: screenHeight * 0.005),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "${subProduct.quantity!.value} x ${subProduct.unit}  ${subProduct.name}",
                                      style: TextStyle(
                                        overflow: TextOverflow.ellipsis,
                                        fontSize: screenHeight * 0.018,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const SizedBox(width: 40),
                                    Text(
                                      "${subProduct.cost * subProduct.quantity!.value}\$",
                                      style: TextStyle(
                                        overflow: TextOverflow.ellipsis,
                                        fontSize: screenHeight * 0.018,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      padding: EdgeInsets.all(screenHeight * 0.015),
      height: screenHeight * 0.12,
      width: screenWidth * 0.45,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15), gradient: gradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            inventary,
            style: subtitles.copyWith(fontSize: screenHeight * 0.025),
          ),
          Text(
            title,
            style: subtitles.copyWith(fontSize: screenHeight * 0.015),
          ),
        ],
      ),
    );
  }
}
