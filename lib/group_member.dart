import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'global.dart';
import 'home.dart';

class GroupMemberPage extends StatefulWidget {
  final String groupId; // group id passed from group.dart
  final String groupName; // For display in AppBar

  const GroupMemberPage({
    Key? key,
    required this.groupId,
    required this.groupName,
  }) : super(key: key);

  @override
  State<GroupMemberPage> createState() => _GroupMemberPageState();
}

class GroupMember extends ChangeNotifier {
  void setLoading() {
    notifyListeners();
  }
}

class _GroupMemberPageState extends State<GroupMemberPage> with ChangeNotifier {
  var user_largest_share = "";
  var displayed_userid = "";
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _groupMembers = [];
  String? _selectedUserId;
  Map<String, dynamic>? _selectedMemberDetails;
  Map<String, String>? getUserNamebyId = {};
  List<String> _notifications = [];
  Map<String, Map<String, double>> transactions = {};
  int l = 0;

  @override
  void initState() {
    super.initState();
    fetchGroupMembers();
    fetchNotifications();
    calculate();
  }

  //fetches all group members
  Future<void> fetchGroupMembers() async {
    final response = await supabase
        .from('group_members')
        .select()
        .eq('Group_Id', widget.groupId);
    _groupMembers =
        (response as List).map((e) => e as Map<String, dynamic>).toList();
    if (l == _groupMembers.length) {
      return;
    }
    for (var member in _groupMembers) {
      String userId = member['User_Id'];
      if (getUserNamebyId![userId] != null) {
        continue;
      }
      String username = await _getUsernameById(userId);
      getUserNamebyId![userId] = username;
    }

    print("getUserNamebyId: $getUserNamebyId");

    if (_selectedMemberDetails != null) {
      _onUserSelected(_selectedMemberDetails!['User_Id']);
    } else {
      calculate();
    }
  }

  // Simulate fetching notifications about new member additions and amounts added
  Future<void> fetchNotifications() async {
    final response =
        await supabase
            .from('notification')
            .select('Notifications')
            .eq('Group_Id', widget.groupId)
            .maybeSingle();

    if (response != null && response['Notifications'] != null) {
      setState(() {
        _notifications = List<String>.from(response['Notifications']);
      });
    } else {
      setState(() {
        _notifications = [];
      });
    }
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Notifications"),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children:
                    _notifications
                        .map((note) => ListTile(title: Text(note)))
                        .toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          ),
    );
  }

  // Modified calculate() using 'Amount' and 'User_Id'

  void _showAddOptions() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Add Options"),
            content: const Text("Choose an option to add:"),
            actions: [
              TextButton(
                onPressed: () {
                  // Option to add amount
                  Navigator.pop(context);
                  _showAddAmountDialog();
                },
                child: const Text("Add Amount"),
              ),
              TextButton(
                onPressed: () {
                  // Option to add people
                  Navigator.pop(context);
                  _showAddPeopleDialog();
                },
                child: const Text("Add People"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
            ],
          ),
    );
  }

  void _showAddAmountDialog() {
    TextEditingController _amountController = TextEditingController();
    String _transactionType = "Paid"; // Default to "Paid"
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Add Amount"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Amount"),
                ),
                const SizedBox(height: 10),
                StatefulBuilder(
                  builder: (context, setState) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _transactionType = "Paid";
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _transactionType == "Paid"
                                    ? AppColor.moredarkercolor
                                    : Colors.grey,
                          ),
                          child: const Text("Paid"),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _transactionType = "Received";
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _transactionType == "Received"
                                    ? AppColor.moredarkercolor
                                    : Colors.grey,
                          ),
                          child: const Text("Received"),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  if (_amountController.text.isNotEmpty) {
                    double amount = double.parse(_amountController.text);
                    if (_transactionType == "Received") {
                      amount = -amount; // Make amount negative if "Received"
                    }
                    print("Adding amount.........");
                    // Insert amount addition record. Adjust table & fields as needed.
                    // Step 1: Get current value
                    final response =
                        await supabase
                            .from('group_members')
                            .select('Amount')
                            .eq('Group_Id', widget.groupId)
                            .eq('User_Id', Global.userId!)
                            .single();

                    final currentAmount = response['Amount'] ?? 0;

                    // Step 2: Update with incremented value
                    await supabase
                        .from('group_members')
                        .update({'Amount': currentAmount + amount})
                        .eq('Group_Id', widget.groupId)
                        .eq('User_Id', Global.userId!);

                    Navigator.pop(context);
                    fetchGroupMembers();
                    String uname = await _getUsernameById(Global.userId!);
                    String note =
                        _transactionType == "Paid"
                            ? "$uname -> has paid ${amount.abs().toStringAsFixed(0)}"
                            : "$uname -> has received ${amount.abs().toStringAsFixed(0)}";
                    await _appendNotification(note);
                  }
                },
                child: const Text("Submit"),
              ),
            ],
          ),
    );
  }

  void _showAddPeopleDialog() {
    TextEditingController _userNameController = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Add Person"),
            content: TextField(
              controller: _userNameController,
              decoration: const InputDecoration(labelText: "User Name"),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  if (_userNameController.text.isNotEmpty) {
                    final response =
                        await supabase
                            .from('users')
                            .select('id')
                            .eq('user_name', _userNameController.text)
                            .maybeSingle();

                    if (response != null && response['id'] != null) {
                      await supabase.from('group_members').insert({
                        'Group_Id': widget.groupId,
                        'User_Id': response['id'],
                        'Joined_At': DateTime.now().toIso8601String(),
                      });
                      Navigator.pop(context);
                      fetchGroupMembers();
                    } else {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text("Error"),
                              content: const Text("User not found."),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("OK"),
                                ),
                              ],
                            ),
                      );
                    }
                  }
                },
                child: const Text("Submit"),
              ),
            ],
          ),
    );
  }

  // Updated _onUserSelected: fetch details then call calculate()
  void _onUserSelected(String? userId) async {
    _selectedUserId = userId;
    _selectedMemberDetails = null;
    if (userId != null) {
      final response =
          await supabase
              .from('group_members')
              .select()
              .eq('Group_Id', widget.groupId)
              .eq('User_Id', userId)
              .maybeSingle();
      _selectedMemberDetails = response as Map<String, dynamic>?;
    }
    calculate();
  }

  void calculate() {
    print("Calculating transactions...");
    transactions = {};
    Map<String, double> amounts = {};
    double total = 0.0;
    double max = 0.0;
    for (var member in _groupMembers) {
      double amt =
          member['Amount'] != null
              ? double.parse(member['Amount'].toString())
              : 0.0;
      amounts[member['User_Id']] = amt;
      if (amt > max) {
        max = amt;
        user_largest_share = member['User_Id'];
      }
      total += amt;
    }
    if (amounts.isEmpty) return;
    double share = total / amounts.length;
    for (var member in _groupMembers) {
      if (member['User_Id'] == user_largest_share) {
        amounts.forEach((key, value) {
          if (value - share != 0 && key.isNotEmpty) {
            if (key != user_largest_share && value != share) {
              transactions.putIfAbsent(member['User_Id'], () => {});
              transactions[member['User_Id']]![key] = share - value;
            }
          }
        });
      } else {
        if (amounts[member['User_Id']] == share) continue;
        if (user_largest_share.isNotEmpty) {
          transactions.putIfAbsent(member['User_Id'], () => {});
          transactions[member['User_Id']]![user_largest_share] =
              (amounts[member['User_Id']] ?? 0.0) - share;
        }
      }
    }
    print("transactions: $transactions");
    print("Notifying listeners...");
    setState(() {});
    notifyListeners();
  }

  // Updated EachUserDetails: simply show the selected member's details as in group.dart EachIndividual
  Widget EachUserDetails() {
    addListener(() {
      setState(() {});
    });
    print("rebuilding widget....");
    if (_selectedUserId == null) {
      return const SizedBox();
    }
    Map<String, double> eachtransaction = transactions[_selectedUserId] ?? {};
    print("eachtransaction: $eachtransaction");

    if (eachtransaction.isEmpty) {
      return const Center(
        child: Text(
          "No pending settlements",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );
    } else {
      return Container(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                eachtransaction.entries.map((entry) {
                  return ListTile(
                    title: EachUser({
                      'User_Id': entry.key,
                      'Amount': entry.value,
                    }),
                  );
                }).toList(),
          ),
        ),
      );
    }
  }

  // Updated EachIndividual: corrected datatypes and field names.
  Widget EachUser(Map<String, dynamic> transac) {
    String userId = transac['User_Id'];
    double amount =
        transac['Amount'] != null
            ? double.parse(transac['Amount'].toString())
            : 0.0;
    print(amount);
    Color txColor = amount < 0 ? Colors.red : Colors.green;
    String note = "";
    return GestureDetector(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: amount < 0 ? Colors.red.shade50 : Colors.green.shade50,
          border: Border.all(color: txColor, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Builder(
              builder: (context) {
                print(getUserNamebyId);
                print(userId);
                String displayName = getUserNamebyId?[userId] ?? 'Unknown';
                note =
                    amount < 0
                        ? "$displayName -> has paid ${amount.abs().toStringAsFixed(0)}"
                        : "$displayName -> has received ${amount.abs().toStringAsFixed(0)}";
                return Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
            const Spacer(),
            Text(
              "₹${amount.abs().toStringAsFixed(2)}",
              style: TextStyle(fontSize: 16, color: txColor),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: AppColor.moredarkercolor),
              onPressed: () {
                _markNotificationDone(note);
                _done(transac, amount);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Group ${widget.groupName}"),
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: _showNotifications,
          ),
        ],
      ),
      body: body_content(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOptions,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }

  Container body_content() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Dropdown to select a group member (displayed in a rectangular box aligned right)
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border.all(color: AppColor.moredarkercolor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                hint: const Text("Select Group Member"),
                value: _selectedUserId,
                underline: Container(),
                items:
                    _groupMembers.map((member) {
                      return DropdownMenuItem<String>(
                        value: member['User_Id'],
                        child: FutureBuilder<String>(
                          future: _getUsernameById(member['User_Id']),
                          builder: (context, snapshot) {
                            String username =
                                snapshot.hasData
                                    ? snapshot.data!
                                    : 'Loading...';
                            return Text(username);
                          },
                        ),
                      );
                    }).toList(),
                onChanged: (value) => _onUserSelected(value),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Display selected member details
          _selectedMemberDetails != null ? EachUserDetails() : const SizedBox(),
          const Spacer(),
        ],
      ),
    );
  }

  Future<String> _getUsernameById(String userId) async {
    final response =
        await supabase
            .from('users')
            .select('user_name')
            .eq('id', userId)
            .single();
    if (response != null && response['user_name'] != null) {
      return response['user_name'];
    } else {
      return 'Unknown User';
    }
  }

  // Add helper to append a notification message
  Future<void> _appendNotification(String message) async {
    print("Appending notification: $message");
    final notifRecord =
        await supabase
            .from('notification')
            .select('Notifications')
            .eq('Group_Id', widget.groupId)
            .maybeSingle();
    if (notifRecord != null && notifRecord['Notifications'] != null) {
      List current = List.from(notifRecord['Notifications']);
      current.add(message);
      await supabase
          .from('notification')
          .update({'Notifications': current})
          .eq('Group_Id', widget.groupId);
    } else {
      await supabase.from('notification').insert({
        'Group_Id': widget.groupId,
        'Notifications': [message],
      });
    }
    fetchNotifications();
  }

  // Helper to mark a notification as done (i.e. remove it)
  Future<void> _markNotificationDone(String message) async {
    final notifRecord =
        await supabase
            .from('notification')
            .select('Notifications')
            .eq('Group_Id', widget.groupId)
            .maybeSingle();
    if (notifRecord != null && notifRecord['Notifications'] != null) {
      List current = List.from(notifRecord['Notifications']);
      current.remove(message);
      await supabase
          .from('notification')
          .update({'Notifications': current})
          .eq('Group_Id', widget.groupId);
    }
    fetchNotifications();
  }

  // Add _done function to process a completed transaction.
  Future<void> _done(Map<String, dynamic> transac, double amount) async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Confirm Transaction"),
            content: const Text(
              "Are you sure you want to mark this transaction as done?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  // Proceed with marking the transaction as done
                  String userId = transac['User_Id'];
                  double userIdamount = await getAmountByUserId(userId);
                  // Add amount to the current user['Amount'] and subtract from the selected user['Amount']
                  await supabase
                      .from('group_members')
                      .update({'Amount': amount + userIdamount})
                      .eq('Group_Id', widget.groupId)
                      .eq('User_Id', userId);
                  await supabase
                      .from('group_members')
                      .update({
                        'Amount':
                            (_selectedMemberDetails?['Amount'] ?? 0) - amount,
                      })
                      .eq('Group_Id', widget.groupId)
                      .eq('User_Id', _selectedUserId!);
                  fetchGroupMembers();
                  String payer, receiver;
                  // Mark notification in desired format:
                  if (amount > 0) {
                    receiver = getUserNamebyId?[_selectedUserId!] ?? 'Unknown';
                    payer = getUserNamebyId?[userId] ?? 'Unknown';
                  } else {
                    payer = getUserNamebyId?[_selectedUserId!] ?? 'Unknown';
                    receiver = getUserNamebyId?[userId] ?? 'Unknown';
                  }
                  String notificationMessage =
                      "${getUserNamebyId![Global.userId]} -> $payer paid ${amount.abs().toStringAsFixed(0)} to $receiver";
                  await _appendNotification(notificationMessage);
                },
                child: const Text("Confirm"),
              ),
            ],
          ),
    );
    // Example implementation: mark the transaction as done locally and update backend if needed.
  }

  Future<double> getAmountByUserId(String userId) async {
    final response =
        await supabase
            .from('group_members')
            .select('Amount')
            .eq('Group_Id', widget.groupId)
            .eq('User_Id', userId)
            .maybeSingle();

    if (response != null && response['Amount'] != null) {
      return double.parse(response['Amount'].toString());
    } else {
      return 0.0;
    }
  }
}
