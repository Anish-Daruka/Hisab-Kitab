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
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  Map<String, double> _categoryData = {};

  @override
  void initState() {
    super.initState();
    Global.getBarChartGroups();
    _calculateCategoryData(_selectedMonth);
  }

  void _calculateCategoryData(DateTime month) {
    _categoryData.clear();
    double total = 0.0;

    for (var tx in transactions) {
      DateTime date = DateTime.parse(tx['date']);
      if (date.year == month.year && date.month == month.month) {
        String category = tx['category'] ?? 'Others';
        double amount = double.tryParse(tx['amount'].toString()) ?? 0.0;
        _categoryData[category] = (_categoryData[category] ?? 0.0) + amount;
        total += amount;
      }
    }

    _categoryData.removeWhere((key, value) => value == 0.0);
    _categoryData = {
      for (var entry in _categoryData.entries)
        if ((entry.value / total * 100).toStringAsFixed(1) != '0.0')
          entry.key: entry.value,
    };
  }

  @override
  Widget build(BuildContext context) {
    Global.getBarChartGroups();
    var barGroups = _isMonth ? Global.barGroupsmonth : Global.barGroupsday;
    barGroups = barGroups.reversed.toList();

    barGroups =
        barGroups.map((group) {
          final rod = group.barRods.first;
          double absValue = rod.toY.abs();
          Color newColor = rod.toY >= 0 ? Colors.green : Colors.red;
          return group.copyWith(
            barRods: [rod.copyWith(toY: absValue, color: newColor)],
          );
        }).toList();

    List<String> labels = [];
    if (_isMonth) {
      for (var tx in transactions) {
        DateTime date = DateTime.parse(tx['date']);
        String label = '${Global.getMonthName(date.month)} ${date.year}';
        if (!labels.contains(label)) {
          labels.add(label);
        }
      }
    } else {
      for (var tx in transactions) {
        DateTime date = DateTime.parse(tx['date']);
        String label =
            '${date.day} ${Global.getMonthName(date.month)} ${date.year}';
        if (!labels.contains(label)) {
          labels.add(label);
        }
      }
    }

    final double maxY =
        barGroups.isNotEmpty
            ? barGroups.map((group) => group.barRods.first.toY).reduce(max) *
                1.2
            : 0.0;

    // Unique months from transactions
    Set<DateTime> uniqueMonthYears = {
      for (var tx in transactions)
        DateTime(
          DateTime.parse(tx['date']).year,
          DateTime.parse(tx['date']).month,
        ),
    };
    List<DateTime> sortedMonthYears =
        uniqueMonthYears.toList()
          ..sort((a, b) => b.compareTo(a)); // Latest first

    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
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
          // After the bar graph
          // Slightly left-aligned dropdown
          Stack(
            children: [
              Container(
                width: 200,
                height: 70,

                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Colors.blueAccent,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButton<DateTime>(
                            value: _selectedMonth,
                            isExpanded: true,
                            dropdownColor: Colors.white,
                            underline: Container(
                              height: 1,
                              color: Colors.blueAccent,
                            ),
                            items:
                                sortedMonthYears.map((monthYear) {
                                  String label =
                                      '${Global.getMonthName(monthYear.month)} ${monthYear.year}';
                                  return DropdownMenuItem<DateTime>(
                                    value: monthYear,
                                    child: Text(
                                      label,
                                      style: const TextStyle(
                                        color: Colors.black,
                                      ),
                                    ),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedMonth = value;
                                  _calculateCategoryData(value);
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  top: 70,
                ), // Padding to push grid down below dropdown
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "Category-wise Expenses",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _categoryData.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 2.5,
                            ),
                        itemBuilder: (context, index) {
                          final key = _categoryData.keys.elementAt(index);
                          final amount = _categoryData[key]!;
                          final total = _categoryData.values.reduce(
                            (a, b) => a + b,
                          );
                          final percent = (amount / total * 100)
                              .toStringAsFixed(1);
                          final isNegative = amount < 0;

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: Colors.blueAccent.withOpacity(0.3),
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blueAccent.withOpacity(0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        key,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '₹${amount.toStringAsFixed(2)} ($percent%)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              isNegative
                                                  ? Colors.green
                                                  : Colors.red,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
