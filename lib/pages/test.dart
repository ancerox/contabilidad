import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  List<ProductModel> products = [];
  Map<ProductModel, List<DateRange>> productDateRanges = {};

  Map<ProductModel, DateTime?> focusedDays = {};
  Map<ProductModel, DateTime?> startDays = {};
  Map<ProductModel, DateTime?> endDays = {};
  Map<ProductModel, RangeSelectionMode> rangeSelectionModes = {};

  @override
  void initState() {
    super.initState();
    // Mock data
    products = [
      ProductModel(
        datesNotAvailable: [
          DateRange(
              start: DateTime.utc(2024, 6, 10), end: DateTime.utc(2024, 6, 15))
        ],
      ),
      ProductModel(
        datesNotAvailable: [
          DateRange(
              start: DateTime.utc(2024, 6, 20), end: DateTime.utc(2024, 6, 25))
        ],
      ),
    ];
  }

  void showCalendar(int index, ProductModel product) {
    List<DateRange> selectedDateRanges = productDateRanges[product] ?? [];

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext builder) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(25)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 0,
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    const Text(
                      'Select a Date',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TableCalendar(
                      enabledDayPredicate: (day) {
                        for (var range in product.datesNotAvailable ?? []) {
                          if ((range.start != null && range.end != null) &&
                              (day.isAfter(range.start!
                                      .subtract(const Duration(days: 1))) &&
                                  day.isBefore(range.end!
                                      .add(const Duration(days: 1))))) {
                            return false;
                          }
                        }
                        for (var range in product.datesUsed ?? []) {
                          if ((range.start != null && range.end != null) &&
                              (day.isAfter(range.start!
                                      .subtract(const Duration(days: 1))) &&
                                  day.isBefore(range.end!
                                      .add(const Duration(days: 1))))) {
                            return false;
                          }
                        }
                        return true;
                      },
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        leftChevronIcon:
                            Icon(Icons.chevron_left, color: Colors.deepPurple),
                        rightChevronIcon:
                            Icon(Icons.chevron_right, color: Colors.deepPurple),
                        titleTextStyle:
                            TextStyle(fontSize: 18, color: Colors.deepPurple),
                      ),
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) {
                          for (var range in selectedDateRanges) {
                            if (day.isAfter(range.start!
                                    .subtract(const Duration(days: 1))) &&
                                day.isBefore(
                                    range.end!.add(const Duration(days: 1)))) {
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
                            }
                          }
                          return null;
                        },
                      ),
                      firstDay: DateTime.utc(2010, 10, 16),
                      lastDay: DateTime.utc(2030, 3, 14),
                      focusedDay: focusedDays[product] ?? DateTime.now(),
                      rangeSelectionMode: rangeSelectionModes[product] ??
                          RangeSelectionMode.toggledOff,
                      rangeStartDay: startDays[product],
                      rangeEndDay: endDays[product],
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          if (startDays[product] != null &&
                              selectedDay.isAfter(startDays[product]!) &&
                              endDays[product] == null) {
                            endDays[product] = selectedDay;
                            rangeSelectionModes[product] =
                                RangeSelectionMode.toggledOn;
                            selectedDateRanges.add(DateRange(
                                start: startDays[product],
                                end: endDays[product]));
                          } else {
                            startDays[product] = selectedDay;
                            endDays[product] = null;
                            rangeSelectionModes[product] =
                                RangeSelectionMode.toggledOff;
                          }
                          focusedDays[product] = focusedDay;
                        });
                      },
                      onPageChanged: (focusedDay) {
                        setState(() {
                          focusedDays[product] = focusedDay;
                        });
                      },
                      calendarStyle: CalendarStyle(
                        rangeHighlightColor: Colors.deepPurple.withOpacity(0.6),
                        rangeStartDecoration: const BoxDecoration(
                          color: Colors.deepPurple,
                          shape: BoxShape.circle,
                        ),
                        rangeEndDecoration: const BoxDecoration(
                          color: Colors.deepPurple,
                          shape: BoxShape.circle,
                        ),
                        outsideDaysVisible: false,
                      ),
                    ),
                    GestureDetector(
                      onTap: selectedDateRanges.isNotEmpty
                          ? () {
                              product.datesUsed ??= [];
                              product.datesUsed!.addAll(selectedDateRanges);

                              productDateRanges[product] =
                                  List.from(selectedDateRanges);

                              Navigator.pop(context);
                            }
                          : null,
                      child: Container(
                        height: 50,
                        width: 200,
                        decoration: BoxDecoration(
                          color: selectedDateRanges.isNotEmpty
                              ? Colors.deepPurple.withOpacity(0.6)
                              : Colors.grey,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Text(
                            "Continue",
                            style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              );
            },
          );
        }).then((value) => setState(() {
          _calculateTotalPrice();
        }));
  }

  void _calculateTotalPrice() {
    // Your calculation logic here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return ListTile(
            title: Text('Product ${index + 1}'),
            onTap: () => showCalendar(index, product),
          );
        },
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(home: MyPage()));
}

// product_model.dart

class DateRange {
  final DateTime? start;
  final DateTime? end;

  DateRange({this.start, this.end});
}

class ProductModel {
  List<DateRange>? datesNotAvailable;
  List<DateRange>? datesUsed;

  ProductModel({this.datesNotAvailable, this.datesUsed});
}
