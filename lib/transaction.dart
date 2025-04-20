import 'package:flutter/material.dart';
import 'home.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'global.dart';

class Transaction extends StatefulWidget {
  const Transaction({super.key});

  @override
  State<Transaction> createState() => _TransactionState();
}

final SupabaseClient supabase = Supabase.instance.client;
final TextEditingController _amountController = TextEditingController();
final TextEditingController _categoryController = TextEditingController();
final TextEditingController _descriptionController = TextEditingController();
String transaction_type = "expense";

String selectedCategory = 'Party';
final List<String> categories = [
  'Food',
  'Health',
  'Education',
  'Salary',
  'Party',
  'Groceries',
  'Hobby',
  'Travel',
  'Shopping',
  'Housing',
  'Other',
];

class TransactionsNotifier extends ChangeNotifier {
  bool isLoading = false;

  Future<void> fetchTransactions() async {
    final user = supabase.auth.currentUser;
    print("reached here....");
    if (user == null) return;
    setLoading(true);
    try {
      final response = await supabase
          .from('transactions')
          .select('*')
          .eq('user_id', user.id)
          .order('date', ascending: false);
      transactions = response;
      print("fetching transaction.....");
      print(transactions);
    } catch (e) {
      print(e);
    } finally {
      setLoading(false);
    }
  }

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  Future<void> deleteTransaction(dynamic transactionId) async {
    setLoading(true);
    try {
      await supabase.from('transactions').delete().eq('id', transactionId);
      transactions.removeWhere((tx) => tx['id'] == transactionId);
      notifyListeners();
    } catch (e) {
      print(e);
    } finally {
      setLoading(false);
    }
  }
}

class _TransactionState extends State<Transaction> {
  @override
  void initState() {
    super.initState();
    _amountController.addListener(() {
      setState(() {});
    });
    _descriptionController.addListener(() {
      setState(() {});
    });
    print('initstate.....');
    Provider.of<TransactionsNotifier>(
      context,
      listen: false,
    ).fetchTransactions();
  }

  Future<void> _addTransaction() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    final double? parsedAmount = double.tryParse(_amountController.text);
    if (parsedAmount == null) return;
    final double amount =
        transaction_type == "Income" ? -parsedAmount : parsedAmount;
    print("amount: $amount");
    print(transaction_type);

    if (amount == null) return;

    print("adding transaction...");
    await supabase.from('transactions').insert({
      'user_id': user.id,
      'amount': amount,
      'description': _descriptionController.text,
      'category': selectedCategory,
    });
    _amountController.clear();
    _descriptionController.clear();
    selectedCategory = 'Party';
    print("transaction added....");
    Provider.of<TransactionsNotifier>(
      context,
      listen: false,
    ).fetchTransactions();

    print("transactions fetched");
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColor.backgroundcolor,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.currency_rupee),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          fillColor: AppColor.lightercolor,
                          filled: true,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.description),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          fillColor: AppColor.lightercolor,
                          filled: true,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text('Category:'),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: selectedCategory,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedCategory = newValue!;
                        });
                      },
                      items:
                          categories.map<DropdownMenuItem<String>>((
                            String value,
                          ) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ChoiceChip(
                      label: const Text('Spent'),
                      selected: transaction_type == "Expense",
                      // selectedColor: const Color.fromARGB(255, 255, 255, 255), // Set selected color
                      onSelected: (_) {
                        setState(() {
                          transaction_type = "Expense";
                        });
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Income'),
                      selected: transaction_type == "Income",
                      // selectedColor: AppColor.darkercolor, // Set selected color
                      onSelected: (_) {
                        setState(() {
                          transaction_type = "Income";
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Center(
                  child: ElevatedButton(
                    onPressed:
                        _amountController.text.isNotEmpty &&
                                _descriptionController.text.isNotEmpty
                            ? _addTransaction
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.darkercolor,
                    ),
                    child: const Text('Add Transaction'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<TransactionsNotifier>(
              builder: (context, notifier, child) {
                return transactions.isEmpty
                    ? const Center(child: Text('No transactions found'))
                    : ListView.builder(
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = transactions[index];
                        // Determine text color and weight based on amount
                        final double amt =
                            transaction['amount'] is double
                                ? transaction['amount']
                                : double.parse(
                                  transaction['amount'].toString(),
                                );
                        final Color textColor =
                            amt > 0 ? Colors.red : Colors.green;
                        final FontWeight textWeight = FontWeight.bold;

                        return Card(
                          color: AppColor.lightercolor,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              8,
                            ), // added boundary to the card
                          ),

                          child: ListTile(
                            title: Text(
                              '${transaction['description']}',
                              style: TextStyle(
                                fontWeight: textWeight,
                                fontSize: 18,
                              ),
                            ),
                            subtitle: Text(
                              '${amt > 0 ? '' : '+'}₹${transaction['amount'].abs()}',
                              style: TextStyle(
                                color: textColor,
                                fontWeight: textWeight,
                                fontSize: 18,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${transaction['category']}',
                                  style: TextStyle(
                                    fontWeight: textWeight,
                                    fontSize: 18,
                                  ),
                                ),

                                const SizedBox(width: 10),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: AppColor.darkestcolor,
                                  ),
                                  onPressed: () {
                                    Provider.of<TransactionsNotifier>(
                                      context,
                                      listen: false,
                                    ).deleteTransaction(transaction['id']);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
              },
            ),
          ),
        ],
      ),
    );
  }
}
