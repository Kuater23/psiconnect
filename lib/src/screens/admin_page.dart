import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    final url = Uri.parse('https://your-secure-api.com/users'); // Cambia a HTTPS
    final response = await http.get(url);

    if (response.statusCode == 200) {
      setState(() {
        _users = List<Map<String, dynamic>>.from(json.decode(response.body));
      });
    } else {
      _showErrorSnackBar('Error fetching users: ${response.body}');
    }
  }

  Future<void> deleteUser(String uid) async {
    final url = Uri.parse('https://your-secure-api.com/deleteUser'); // Cambia a HTTPS
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'uid': uid}),
    );

    if (response.statusCode == 200) {
      _fetchUsers();
    } else {
      _showErrorSnackBar('Error deleting user: ${response.body}');
    }
  }

  Future<void> addUser(String email, String password, String displayName) async {
    if (email.isEmpty || password.isEmpty || displayName.isEmpty) {
      _showErrorSnackBar('Please fill in all fields');
      return;
    }

    final url = Uri.parse('https://your-secure-api.com/addUser'); // Cambia a HTTPS
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password, 'displayName': displayName}),
    );

    if (response.statusCode == 200) {
      _fetchUsers();
      _showSuccessSnackBar('User added successfully');
    } else {
      _showErrorSnackBar('Error adding user: ${response.body}');
    }
  }

  Future<void> updateUser(String uid, String email, String displayName) async {
    if (email.isEmpty || displayName.isEmpty) {
      _showErrorSnackBar('Please fill in all fields');
      return;
    }

    final url = Uri.parse('https://your-secure-api.com/updateUser'); // Cambia a HTTPS
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'uid': uid, 'email': email, 'displayName': displayName}),
    );

    if (response.statusCode == 200) {
      _fetchUsers();
      _showSuccessSnackBar('User updated successfully');
    } else {
      _showErrorSnackBar('Error updating user: ${response.body}');
    }
  }

  void _showAddUserDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final displayNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              TextField(
                controller: displayNameController,
                decoration: InputDecoration(labelText: 'Display Name'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final email = emailController.text;
                final password = passwordController.text;
                final displayName = displayNameController.text;
                addUser(email, password, displayName);
                Navigator.of(context).pop();
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    final emailController = TextEditingController(text: user['email'] ?? '');
    final displayNameController = TextEditingController(text: user['displayName'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: displayNameController,
                decoration: InputDecoration(labelText: 'Display Name'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final email = emailController.text;
                final displayName = displayNameController.text;
                updateUser(user['id'], email, displayName);
                Navigator.of(context).pop();
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: TextStyle(color: Colors.red))),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: TextStyle(color: Colors.green))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Page'),
      ),
      body: _users.isEmpty
          ? Center(
              child: Text(
                'No users found. Add new users using the button below.',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return ListTile(
                  title: Text(user['displayName'] ?? 'No Name'),
                  subtitle: Text(user['email'] ?? 'No Email'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          _showEditUserDialog(user);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          deleteUser(user['id']);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}
