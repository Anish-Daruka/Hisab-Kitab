import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'global.dart';

class Analytics extends StatefulWidget {
  const Analytics({super.key});

  @override
  State<Analytics> createState() => _AnalyticsState();
}

class _AnalyticsState extends State<Analytics> {
  bool _isMonth = true; // true

  @override
  void initState() {
    super.initState();
    Global.getBarChartGroups();
  }

  @override
  Widget build(BuildContext context) {
    Global.getBarChartGroups();
    var barGroups = _isMonth ? Global.barGroupsmonth : Global.barGroupsday;
    barGroups = barGroups.reversed.toList();

    // Compute labels based on view type
    List<String> labels = [];
    print(transactions);
    if (_isMonth) {
      for (var tx in transactions) {
        DateTime date = DateTime.parse(tx['date']);
        int month = date.month;
        int year = date.year;
        String label = '$month-$year';
        if (!labels.contains(Global.getMonthName(month))) {
          labels.add('${Global.getMonthName(month)}');
        }
      }
    } else {
      for (var tx in transactions) {
        DateTime date = DateTime.parse(tx['date']);
        int day = date.day;
        int month = date.month;
        int year = date.year;
        String label = '$day-$month-$year';
        if (!labels.contains('$day ${Global.getMonthName(month)}')) {
          labels.add('$day ${Global.getMonthName(month)}');
        }
      }
    }
    labels = labels.reversed.toList();
    print(labels);
    final double maxY =
        barGroups.isNotEmpty
            ? barGroups
                    .map((group) => group.barRods.first.toY)
                    .reduce((a, b) => a > b ? a : b) *
                1.2
            : 0.0;
    print(barGroups.length);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 100,
              height: 40,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: const Color.fromARGB(255, 1, 12, 22),
                  backgroundColor: _isMonth ? Colors.blueAccent : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _isMonth = true; // Complete state for month view
                  });
                },
                child: const Text(
                  'Month',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 16), // spacing between buttons
            SizedBox(
              width: 100,
              height: 40,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: const Color.fromARGB(255, 1, 12, 22),
                  backgroundColor: !_isMonth ? Colors.blueAccent : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _isMonth = false; // Complete state for day view
                  });
                },
                child: const Text('Day', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),

        graphplot(
          maxY,
          barGroups,
          labels,
          _isMonth ? "Monthly Expenses" : "Daily Expenses",
        ),
      ],
    );
  }

  Container graphplot(
    double maxY,
    List<BarChartGroupData> barGroups,
    List<String> labels,
    String title,
  ) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          // Enclose BarChart in a horizontal SingleChildScrollView with fixed spacing
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: max(
                barGroups.length * 60.0,
                325,
              ), // fixed width per group for spacing
              height: 300,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  barGroups: barGroups,
                  backgroundColor: Colors.grey[200],
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                  // Updated barTouchData to ensure tooltips work on tap
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipPadding: const EdgeInsets.all(8.0),
                      tooltipMargin: 8,

                      tooltipRoundedRadius: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${rod.toY.toStringAsFixed(1)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),

                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index < 0 || index >= labels.length)
                            return Container();
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              labels[index],
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: const FlGridData(show: true),
                  alignment: BarChartAlignment.spaceAround,
                ),
                swapAnimationDuration: const Duration(milliseconds: 250),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
