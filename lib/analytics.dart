import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'transaction.dart'; // For TransactionsNotifier

class Analytics extends StatefulWidget {
  const Analytics({super.key});

  @override
  State<Analytics> createState() => _AnalyticsState();
}

class _AnalyticsState extends State<Analytics> {
  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionsNotifier>(
      builder: (context, notifier, child) {
        // Group transactions by category
        final Map<String, double> dataMap = {};
        for (var tx in notifier.transactions) {
          final String category = tx['category'] ?? 'Unknown';
          final double amount =
              (tx['amount'] is num) ? tx['amount'].toDouble() : 0.0;
          dataMap[category] = (dataMap[category] ?? 0) + amount;
        }
        final List<CategoryExpense> chartData =
            dataMap.entries
                .map((entry) => CategoryExpense(entry.key, entry.value))
                .toList();

        // Create bar groups for fl_chart
        List<BarChartGroupData> barGroups = [];
        for (int i = 0; i < chartData.length; i++) {
          barGroups.add(
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: chartData[i].amount,
                  color: Colors.blue,
                  width: 22,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
              showingTooltipIndicators: [0],
            ),
          );
        }
        final List<String> categories =
            chartData.map((e) => e.category).toList();
        final double maxY =
            chartData.isNotEmpty
                ? chartData
                        .map((e) => e.amount)
                        .reduce((a, b) => a > b ? a : b) *
                    1.2
                : 0.0;

        return SingleChildScrollView(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Expenses by Category',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
                height: 300,
                child: BarChart(
                  BarChartData(
                    maxY: maxY,
                    barGroups: barGroups,
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: true),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            int index = value.toInt();
                            if (index < 0 || index >= categories.length)
                              return Container();
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(categories[index]),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                  ),
                  swapAnimationDuration: const Duration(milliseconds: 250),
                ),
              ),
              // ...existing code or additional analysis widgets...
            ],
          ),
        );
      },
    );
  }
}

class CategoryExpense {
  final String category;
  final double amount;
  CategoryExpense(this.category, this.amount);
}
