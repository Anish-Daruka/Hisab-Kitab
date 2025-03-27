import 'package:flutter/material.dart';
import 'home.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Transaction extends StatefulWidget {
  const Transaction({super.key});

  @override
  State<Transaction> createState() => _TransactionState();
}

final SupabaseClient supabase = Supabase.instance.client;
final TextEditingController _amountController = TextEditingController();
final TextEditingController _categoryController = TextEditingController();

// Notifier to track transactions and loading state
class TransactionsNotifier extends ChangeNotifier {
  bool isLoading = false;
  List<Map<String, dynamic>> transactions = [];

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

  // Added function to delete a transaction
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
    _categoryController.addListener(() {
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
    final double? amount = double.tryParse(_amountController.text);
    if (amount == null) return;
    print("adding transaction...");
    print(amount);
    await supabase.from('transactions').insert({
      'user_id': user.id,
      'amount': amount,
      'category': _categoryController.text,
      'type': 'expense', // Change to 'income' if needed
    });
    _amountController.clear();
    _categoryController.clear();
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
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount'),
                ),
                TextField(
                  controller: _categoryController,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed:
                      _amountController.text.isNotEmpty &&
                              _categoryController.text.isNotEmpty
                          ? _addTransaction
                          : null,
                  child: const Text('Add Transaction'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<TransactionsNotifier>(
              builder: (context, notifier, child) {
                print(111);
                return notifier.transactions.isEmpty
                    ? const Center(child: Text('No transactions found'))
                    : ListView.builder(
                      itemCount: notifier.transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = notifier.transactions[index];
                        return ListTile(
                          title: Text('${transaction['category']}'),
                          subtitle: Text('${transaction['amount']} USD'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${transaction['type']}'),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  Provider.of<TransactionsNotifier>(
                                    context,
                                    listen: false,
                                  ).deleteTransaction(transaction['id']);
                                },
                              ),
                            ],
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
