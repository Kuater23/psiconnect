import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  String _searchTerm = '';
  String _selectedRole = 'All';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    final url = Uri.parse('http://localhost:3000/users');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      setState(() {
        _users = List<Map<String, dynamic>>.from(json.decode(response.body));
        _filteredUsers = _users;
      });
    } else {
      print('Error fetching users: ${response.body}');
    }
  }

  void _filterUsers() {
    setState(() {
      _filteredUsers = _users.where((user) {
        final displayName = user['displayName']?.toLowerCase() ?? '';
        final role = user['role']?.toLowerCase() ?? 'patient';
        final matchesSearchTerm = displayName.contains(_searchTerm.toLowerCase());
        final matchesRole = _selectedRole == 'All' || role == _selectedRole.toLowerCase();
        return matchesSearchTerm && matchesRole;
      }).toList();
    });
  }

  Future<void> deleteUser(String uid) async {
    final url = Uri.parse('http://localhost:3000/deleteUser');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'uid': uid}),
    );

    if (response.statusCode == 200) {
      _fetchUsers();
    } else {
      print('Error deleting user: ${response.body}');
    }
  }

  Future<void> addUser(String email, String password, String displayName) async {
    final url = Uri.parse('http://localhost:3000/addUser');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password, 'displayName': displayName}),
    );

    if (response.statusCode == 200) {
      _fetchUsers();
    } else {
      print('Error adding user: ${response.body}');
    }
  }

  Future<void> updateUser(String uid, String email, String displayName, String role) async {
    final url = Uri.parse('http://localhost:3000/updateUser');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'uid': uid, 'email': email, 'displayName': displayName, 'role': role}),
    );

    if (response.statusCode == 200) {
      _fetchUsers();
    } else {
      print('Error updating user: ${response.body}');
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
    final roleController = TextEditingController(text: user['role'] ?? '');

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
              TextField(
                controller: roleController,
                decoration: InputDecoration(labelText: 'Role'),
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
                final role = roleController.text;
                updateUser(user['uid'], email, displayName, role);
                Navigator.of(context).pop();
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _logout() {
    // Implementa la lógica de logout aquí
    // Por ejemplo, puedes navegar a la pantalla de login
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Page'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchTerm = value;
                  _filterUsers();
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: _selectedRole,
              items: <String>['All', 'Admin', 'Patient']
                  .map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRole = value!;
                  _filterUsers();
                });
              },
            ),
          ),
          Expanded(
            child: _filteredUsers.isEmpty
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
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
                                deleteUser(user['uid']);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}