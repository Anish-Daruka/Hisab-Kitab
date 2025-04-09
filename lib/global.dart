import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

List<Map<int, DateTime>> ts = [];
List<Map<String, dynamic>> transactions = [];

class Global {
  static String? userId;
  static String? username;
  // Returns monthly and daily expense bar groups
  static List<BarChartGroupData> barGroupsmonth = [];
  static List<BarChartGroupData> barGroupsday = [];
  static void getBarChartGroups() {
    barGroupsmonth = [];
    barGroupsday = [];

    List<double> expensesmonth = [];
    List<double> expensesday = [];
    List<String> months = [];
    List<String> days = [];
    transactions.forEach((tx) {
      DateTime date = DateTime.parse(tx['date']);
      int day = date.day;
      int month = date.month;
      int year = date.year;
      double amount = tx['amount'];
      int indexMonth = months.indexOf('$month-$year');
      int indexDay = days.indexOf('$day-$month-$year');
      if (indexMonth == -1) {
        months.add('$month-$year');
        expensesmonth.add(amount);
      } else {
        expensesmonth[indexMonth] += amount;
      }
      if (indexDay == -1) {
        days.add('$day-$month-$year');
        expensesday.add(amount);
      } else {
        expensesday[indexDay] += amount;
      }
    });

    for (int i = 0; i < months.length; i++) {
      barGroupsmonth.add(
        BarChartGroupData(
          x: i,
          barRods: [BarChartRodData(toY: expensesmonth[i], color: Colors.blue)],
        ),
      );
    }

    for (int i = 0; i < days.length; i++) {
      barGroupsday.add(
        BarChartGroupData(
          x: i,
          barRods: [BarChartRodData(toY: expensesday[i], color: Colors.green)],
        ),
      );
    }
  }

  // Returns a list of expenses grouped by category
  static List<CategoryExpense> getCategoryExpenses() {
    Map<String, double> dataMap = {};
    transactions.forEach((tx) {
      final String category = tx['category'] ?? 'Unknown';
      final double amount =
          (tx['amount'] is num) ? tx['amount'].toDouble() : 0.0;
      dataMap[category] = (dataMap[category] ?? 0) + amount;
    });
    return dataMap.entries.map((e) => CategoryExpense(e.key, e.value)).toList();
  }

  static String getMonthName(int month) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return monthNames[month - 1];
  }
}

class CategoryExpense {
  final String category;
  final double amount;
  CategoryExpense(this.category, this.amount);
}
