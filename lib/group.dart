import 'package:flutter/material.dart';
import 'package:hisab_kitab/group_member.dart';
import 'package:hisab_kitab/home.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'global.dart';
import 'group_member.dart';

class GroupPage extends StatefulWidget {
  @override
  _GroupPageState createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  final supabase = Supabase.instance.client;
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _myGroups = []; // Added variable for user's groups
  List<Map<String, dynamic>> _individual = [];
  var _state = 1;

  @override
  void initState() {
    super.initState();
    _fetchMyGroups();
    _fetchIndividual(); // Fetch groups on initialization
  }

  Future<void> _fetchMyGroups() async {
    print("fetching my groups.......");
    final groupIdsResponse = await supabase
        .from('group_members')
        .select('Group_Id')
        .eq('User_Id', Global.userId!);
    print("here.......");

    List<dynamic> groupIds =
        groupIdsResponse.map((e) => e['Group_Id']).toList();
    print(groupIds);
    final response = await supabase
        .from('groups')
        .select()
        .filter('Group_Id', 'in', groupIds);
    print("here 2........");
    print(response);

    if (response != null && response is List) {
      setState(() {
        _myGroups = response.map((e) => e as Map<String, dynamic>).toList();
      });
    }
    print(" groups fetched........");
  }

  Future<void> _fetchIndividual() async {
    final response = await supabase
        .from('individual')
        .select()
        .or('created_by.eq.${Global.userId!},created_for.eq.${Global.userId!}');
    setState(() {
      _individual =
          (response as List).map((e) => e as Map<String, dynamic>).toList();
    });
  }

  Future<void> _deleteGroup(dynamic groupId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm"),
          content: const Text(
            "Are you sure all transactions of this group has been completed?",
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Delete"),
              onPressed: () async {
                Navigator.of(context).pop();
                print("deleting group.......");
                await supabase.from('groups').delete().eq('Group_Id', groupId);
                _fetchMyGroups();
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteIndividualEntry(Map<String, dynamic> individual) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm"),
          content: const Text("Are you sure the transaction is completed?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Delete"),
              onPressed: () async {
                Navigator.of(context).pop();
                await supabase
                    .from('individual')
                    .delete()
                    .eq('id', individual['id']);
                _fetchIndividual();
              },
            ),
          ],
        );
      },
    );
  }

  void _createGroup() async {
    print("creating group.......");
    if (_groupNameController.text.isNotEmpty) {
      var response =
          await supabase.from('groups').insert({
            'Group_Name': _groupNameController.text,
            'Created_By': Global.userId,
            'Created_At': DateTime.now().toIso8601String(),
          }).select();

      if (response.isNotEmpty) {
        var groupId = response[0]['Group_Id'];
        await supabase.from('group_members').insert({
          'Group_Id': groupId,
          'User_Id': Global.userId,
          'Joined_At': DateTime.now().toIso8601String(),
        }).select();
        // Insert notification: e.g., "username -> created group {group_name}"
        String uname = await _getUsernameById(Global.userId!);
        await supabase.from('notification').insert({
          'Group_Id': groupId,
          'Notifications': [
            '$uname -> created group ${_groupNameController.text}',
          ],
        });

        _groupNameController.clear();
      }
    }
    _fetchMyGroups();
  }

  void _searchUsers() async {
    final response = await supabase
        .from('users')
        .select()
        .ilike('user_name', '%${_searchController.text}%')
        .neq('id', Global.userId!);

    setState(() {
      _searchResults = response;
    });
  }

  // Updated _sendJoinRequest: store negative amount for "pay" and remove transaction_type
  void _sendJoinRequest(String userId) {
    print("sending join request to $userId");
    TextEditingController _amountController = TextEditingController();
    String _transactionType = 'pay'; // Default to 'pay'
    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('Enter Amount'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Amount'),
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ChoiceChip(
                            label: const Text('Pay'),
                            selected: _transactionType == 'pay',
                            selectedColor: AppColor.moredarkercolor,
                            onSelected: (selected) {
                              setState(() {
                                _transactionType = 'pay';
                              });
                            },
                            labelStyle: TextStyle(
                              color:
                                  _transactionType == 'pay'
                                      ? Colors.white
                                      : Colors.black,
                            ),
                          ),
                          const SizedBox(width: 16),
                          ChoiceChip(
                            label: const Text('Receive'),
                            selected: _transactionType == 'receive',
                            selectedColor: AppColor.moredarkercolor,
                            onSelected: (selected) {
                              setState(() {
                                _transactionType = 'receive';
                              });
                            },
                            labelStyle: TextStyle(
                              color:
                                  _transactionType == 'receive'
                                      ? Colors.white
                                      : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        if (_amountController.text.isNotEmpty) {
                          double amt = double.parse(_amountController.text);
                          // If "pay", store as negative
                          double storedAmount =
                              _transactionType == 'pay' ? amt : -amt;
                          print("Adding individual entry.............");
                          await supabase.from('individual').insert({
                            'created_for': userId,
                            'created_by': Global.userId,
                            'amount': storedAmount,
                            'created_at': DateTime.now().toIso8601String(),
                          });
                          _searchController.clear();
                          _fetchIndividual();
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Submit'),
                    ),
                  ],
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColor.backgroundcolor,
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showDialog(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: Text('Create Group'),
                    content: TextField(
                      controller: _groupNameController,
                      decoration: InputDecoration(labelText: 'Group Name'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          _createGroup();
                          Navigator.pop(context);
                        },
                        child: Text('Create'),
                      ),
                    ],
                  ),
            );
          },
          child: Icon(Icons.add),
        ),
        body: Stack(
          children: [
            Container(color: AppColor.backgroundcolor),
            Positioned(
              top: 90,
              child: SizedBox(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                child: Column(
                  children: [
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 100,
                            height: 40,
                            child: TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor:
                                    _state == 1
                                        ? AppColor.moredarkercolor
                                        : Colors.grey,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  _state = 1;
                                  _searchController.clear();
                                  _searchResults = [];
                                });
                              },
                              child: const Text(
                                'Groups',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 26),
                          SizedBox(
                            width: 100,
                            height: 40,
                            child: TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor:
                                    _state == 0
                                        ? AppColor.moredarkercolor
                                        : Colors.grey,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  _state = 0;
                                  _searchController.clear();
                                  _searchResults = [];
                                });
                              },
                              child: const Text(
                                'Individual',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children:
                                  (_state == 1)
                                      ? _myGroups.isEmpty
                                          ? [
                                            const SizedBox(height: 10),
                                            Text('No groups available'),
                                          ]
                                          : _myGroups.map((group) {
                                            return ListTile(
                                              title: EachGroup(group),
                                            );
                                          }).toList()
                                      : _individual.isEmpty
                                      ? [
                                        const SizedBox(height: 10),
                                        Text('No pending settlements'),
                                      ]
                                      : _individual.map((individual) {
                                        return ListTile(
                                          title: EachIndividual(individual),
                                        );
                                      }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              top: 16,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                height: 40,
                width: 370,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search user by username',
                    hintStyle: TextStyle(fontSize: 15, color: Colors.grey),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.search),
                      onPressed: _searchUsers,
                    ),
                    filled: true,
                    fillColor: const Color.fromARGB(255, 251, 251, 251),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onChanged: (val) {
                    _searchUsers();
                  },
                ),
              ),
            ),

            if (_searchController.text.isNotEmpty && _searchResults.isNotEmpty)
              Positioned(
                top: 60,
                right: 16,
                child: SizedBox(
                  width: 250,
                  height: 250,
                  child: SingleChildScrollView(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        children:
                            _searchResults.map((user) {
                              return ListTile(
                                title: Text(user['user_name']),
                                onTap: () {
                                  _sendJoinRequest(user['id']);
                                },
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget EachGroup(Map<String, dynamic> group) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => GroupMemberPage(
                  groupId: group['Group_Id'],
                  groupName: group['Group_Name'],
                ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColor.darkercolor,
          border: Border.all(color: AppColor.moredarkercolor, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.group, color: AppColor.moredarkercolor),
                SizedBox(width: 8),
                Text(
                  group['Group_Name'],
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (Global.userId == group['Created_By'])
              IconButton(
                icon: Icon(Icons.delete, color: AppColor.darkestcolor),
                onPressed: () => _deleteGroup(group['Group_Id']),
              ),
          ],
        ),
      ),
    );
  }

  // Updated EachIndividual: derive colors from the amount and remove transaction_type references.
  Widget EachIndividual(Map<String, dynamic> individual) {
    String otherUserId =
        Global.userId == individual['created_by']
            ? individual['created_for']
            : individual['created_by'];
    bool isDone = (individual['created_by'] == Global.userId);
    double amount = individual['amount'] ?? 0.0;
    DateTime date =
        DateTime.tryParse(individual['created_at']) ?? DateTime.now();

    // Determine color based on amount and context
    Color txColor = (amount < 0) ^ isDone ? Colors.red : Colors.green;

    return GestureDetector(
      onTap: () {
        // Define tap behavior if needed.
      },
      child: Card(
        color: AppColor.lightercolor,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FutureBuilder<String>(
                future: _getUsernameById(otherUserId),
                builder: (context, snapshot) {
                  String displayName =
                      snapshot.hasData ? snapshot.data! : 'Loading...';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${(amount < 0) ^ isDone ? '' : '+'}₹${amount.abs().toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 14,
                          color: txColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${date.day}/${date.month}/${date.year}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  );
                },
              ),
              if (isDone)
                IconButton(
                  icon: const Icon(Icons.delete, color: AppColor.darkestcolor),
                  onPressed: () => _deleteIndividualEntry(individual),
                ),
            ],
          ),
        ),
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
}
