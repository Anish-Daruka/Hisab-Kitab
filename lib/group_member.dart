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

class _GroupMemberPageState extends State<GroupMemberPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _groupMembers = [];
  String? _selectedUserId;
  Map<String, dynamic>? _selectedMemberDetails;
  List<String> _notifications = []; // Simulated notifications

  @override
  void initState() {
    super.initState();
    fetchGroupMembers();
    fetchNotifications();
  }

  Future<void> fetchGroupMembers() async {
    final response = await supabase
        .from('group_members')
        .select()
        .eq('Group_Id', widget.groupId);
    setState(() {
      _groupMembers =
          (response as List).map((e) => e as Map<String, dynamic>).toList();
    });
  }

  // Simulate fetching notifications about new member additions and amounts added
  void fetchNotifications() {
    // In real app, replace with supabase query.
    setState(() {
      _notifications = [
        "User A added ₹500",
        "User B joined the group",
        "User C added ₹200",
      ];
    });
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

  void _onUserSelected(String? userId) async {
    setState(() {
      _selectedUserId = userId;
      _selectedMemberDetails = null;
    });
    if (userId != null) {
      final response =
          await supabase
              .from('group_members')
              .select()
              .eq('Group_Id', widget.groupId)
              .eq('User_Id', userId)
              .maybeSingle();
      setState(() {
        _selectedMemberDetails = response as Map<String, dynamic>?;
      });
    }
  }

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
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Add Amount"),
            content: TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Amount"),
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
                    // Insert amount addition record. Adjust table & fields as needed.
                    await supabase
                        .from('group_members')
                        .update({'amount_added': amount})
                        .eq('group_id', widget.groupId)
                        .eq('user_id', Global.userId!);
                    Navigator.pop(context);
                    fetchGroupMembers();
                  }
                },
                child: const Text("Submit"),
              ),
            ],
          ),
    );
  }

  void _showAddPeopleDialog() {
    TextEditingController _userIdController = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Add Person"),
            content: TextField(
              controller: _userIdController,
              decoration: const InputDecoration(labelText: "User ID"),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  if (_userIdController.text.isNotEmpty) {
                    // Insert new group member record
                    await supabase.from('group_members').insert({
                      'group_id': widget.groupId,
                      'user_id': _userIdController.text,
                      'joined_at': DateTime.now().toIso8601String(),
                    });
                    Navigator.pop(context);
                    fetchGroupMembers();
                  }
                },
                child: const Text("Submit"),
              ),
            ],
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
                border: Border.all(color: Colors.blue),
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
                onChanged: _onUserSelected,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Display selected member details
          _selectedMemberDetails != null
              ? FutureBuilder<String>(
                future: _getUsernameById(_selectedMemberDetails!['user_id']),
                builder: (context, snapshot) {
                  String username =
                      snapshot.hasData ? snapshot.data! : 'Loading...';
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Username: $username",
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Group ID: ${_selectedMemberDetails!['group_id']}",
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Joined At: ${_selectedMemberDetails!['joined_at']}",
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
              : const SizedBox(),
          const Spacer(),
          // + Icon to show alert box for add options
          IconButton(
            icon: const Icon(Icons.add, size: 36, color: Colors.blue),
            onPressed: _showAddOptions,
          ),
          const SizedBox(height: 20),
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
}
