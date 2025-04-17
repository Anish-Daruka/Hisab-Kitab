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
  bool _isMonth = true;

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

    List<String> labels = [];
    if (_isMonth) {
      for (var tx in transactions) {
        DateTime date = DateTime.parse(tx['date']);
        if (!labels.contains(Global.getMonthName(date.month))) {
          labels.add('${Global.getMonthName(date.month)}');
        }
      }
    } else {
      for (var tx in transactions) {
        DateTime date = DateTime.parse(tx['date']);
        if (!labels.contains(
          '${date.day} ${Global.getMonthName(date.month)}',
        )) {
          labels.add('${date.day} ${Global.getMonthName(date.month)}');
        }
      }
    }
    final double maxY =
        barGroups.isNotEmpty
            ? barGroups.map((group) => group.barRods.first.toY).reduce(max) *
                1.2
            : 0.0;

    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 40,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: _isMonth ? Colors.blueAccent : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _isMonth = true;
                    });
                  },
                  child: const Text(
                    'Month',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 100,
                height: 40,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor:
                        !_isMonth ? Colors.blueAccent : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _isMonth = false;
                    });
                  },
                  child: const Text(
                    'Day',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Text(
                  _isMonth ? "Monthly Expenses" : "Daily Expenses",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: max(barGroups.length * 60.0, 325),
                    height: 300,
                    child: BarChart(
                      BarChartData(
                        maxY: maxY,
                        barGroups: barGroups,
                        backgroundColor: Colors.white,
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(color: Colors.blue, width: 1),
                        ),
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
          ),
        ],
      ),
    );
  }
}
