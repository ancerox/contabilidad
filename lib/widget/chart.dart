import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

enum Period { Year, Month, Week }

class LineChartSample extends StatefulWidget {
  const LineChartSample({super.key});

  @override
  _LineChartSampleState createState() => _LineChartSampleState();
}

class _LineChartSampleState extends State<LineChartSample> {
  Period selectedPeriod = Period.Month;

  // Define example dates and values based on periods
  List<DateTime> getDates() {
    switch (selectedPeriod) {
      case Period.Week:
        return [
          DateTime(2024, 9, 1), // Week 1
          DateTime(2024, 9, 8), // Week 2
          DateTime(2024, 9, 15), // Week 3
          DateTime(2024, 9, 22), // Week 4
          DateTime(2024, 9, 29), // Week 5
        ];
      case Period.Month:
        return [
          DateTime(2024, 1, 1),
          DateTime(2024, 2, 1),
          DateTime(2024, 3, 1),
          DateTime(2024, 4, 1),
          DateTime(2024, 5, 1),
        ];
      case Period.Year:
      default:
        return [
          DateTime(2020, 1, 1),
          DateTime(2021, 1, 1),
          DateTime(2022, 1, 1),
          DateTime(2023, 1, 1),
          DateTime(2024, 1, 1),
        ];
    }
  }

  List<double> getValues() {
    switch (selectedPeriod) {
      case Period.Week:
        return [20, 80, 50, 90, 40];
      case Period.Month:
        return [30, 70, 55, 80, 45];
      case Period.Year:
      default:
        return [10, 60, 40, 70, 90];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dynamic Line Chart")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<Period>(
              value: selectedPeriod,
              onChanged: (Period? newValue) {
                setState(() {
                  selectedPeriod = newValue!;
                });
              },
              items: Period.values.map((Period period) {
                return DropdownMenuItem<Period>(
                  value: period,
                  child: Text(periodToString(period)),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(
                    show: true,
                    border:
                        Border.all(color: const Color(0xff37434d), width: 1),
                  ),
                  minX: 0,
                  maxX: (getDates().length - 1).toDouble(), // Last index
                  minY: 0,
                  maxY: 100, // Change according to your expected values
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(getDates().length, (index) {
                        return FlSpot(index.toDouble(), getValues()[index]);
                      }),
                      isCurved: true,
                      color: Colors.blue,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String periodToString(Period period) {
    switch (period) {
      case Period.Year:
        return "Año";
      case Period.Month:
        return "Mes";
      case Period.Week:
        return "Semana";
      default:
        return "";
    }
  }
}
