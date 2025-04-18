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

String selectedCategory = 'Food';
final List<String> categories = [
  'Food',
  'Travel',
  'Shopping',
  'Bills',
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
    selectedCategory = 'Food';
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
      color: Colors.blue.shade50,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              color: Color.fromARGB(255, 186, 226, 248),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
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
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
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
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Category:'),
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
                          onSelected: (_) {
                            setState(() {
                              transaction_type = "Expense";
                            });
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Income'),
                          selected: transaction_type == "Income",
                          onSelected: (_) {
                            setState(() {
                              transaction_type = "Income";
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    ElevatedButton(
                      onPressed:
                          _amountController.text.isNotEmpty &&
                                  _descriptionController.text.isNotEmpty
                              ? _addTransaction
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      child: const Text('Add Transaction'),
                    ),
                  ],
                ),
              ),
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
                        // Determine card color depending on amount > 0 (green) or < 0 (red)
                        final double amt =
                            transaction['amount'] is double
                                ? transaction['amount']
                                : double.parse(
                                  transaction['amount'].toString(),
                                );
                        final Color cardColor =
                            amt > 0
                                ? const Color.fromARGB(255, 248, 179, 189)
                                : const Color.fromARGB(255, 184, 253, 190);
                        final BorderSide borderSide = BorderSide(
                          color:
                              amt > 0
                                  ? const Color.fromARGB(255, 249, 139, 132)
                                  : const Color.fromARGB(255, 146, 249, 149),
                          width: 1,
                        );

                        return Card(
                          color: cardColor,
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: borderSide, // added boundary to the card
                          ),
                          child: ListTile(
                            title: Text('${transaction['description']}'),
                            subtitle: Text('₹${transaction['amount'].abs()}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('${transaction['category']}'),
                                const SizedBox(width: 10),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
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
