import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _searchController.addListener(_filterUsers);
  }

  Future<void> _fetchUsers() async {
    final QuerySnapshot result = await FirebaseFirestore.instance.collection('users').get();
    final List<DocumentSnapshot> documents = result.docs;
    setState(() {
      _users = documents.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        data['isActive'] = data['isActive'] ?? true; // Asegúrate de que isActive no sea null
        return data;
      }).toList();
      _filteredUsers = _users;
    });
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _users.where((user) {
        final email = user['email'].toLowerCase();
        return email.contains(query);
      }).toList();
    });
  }

  Future<void> _addUser(String email, String password, String role, String? documentType, String? idNumber, String? matricula) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/addUser'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'role': role,
          'documentType': documentType,
          'idNumber': idNumber,
          'matricula': matricula,
        }),
      );

      if (response.statusCode == 200) {
        _fetchUsers();
      } else {
        _showErrorSnackBar('Error: ${response.body}');
      }
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }

  Future<void> _updateUser(String id, String email, String role, String? documentType, String? idNumber, String? matricula) async {
    try {
      final response = await http.put(
        Uri.parse('http://localhost:3000/updateUser'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'uid': id,
          'email': email,
          'role': role,
          'documentType': documentType,
          'idNumber': idNumber,
          'matricula': matricula,
        }),
      );

      if (response.statusCode == 200) {
        _fetchUsers();
      } else {
        _showErrorSnackBar('Error: ${response.body}');
      }
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }

  Future<void> _deleteUser(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('http://localhost:3000/deleteUser'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'uid': id}),
      );

      if (response.statusCode == 200) {
        _fetchUsers();
      } else {
        _showErrorSnackBar('Error: ${response.body}');
      }
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }

  Future<void> _resetPassword(String uid) async {
    try {
      String newPassword = _generateRandomPassword();
      final response = await http.post(
        Uri.parse('http://localhost:3000/resetPassword'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'uid': uid, 'newPassword': newPassword}),
      );

      if (response.statusCode == 200) {
        _showErrorSnackBar('Nueva contraseña: $newPassword');
      } else {
        _showErrorSnackBar('Error: ${response.body}');
      }
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }

  String _generateRandomPassword() {
    const length = 6;
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return List.generate(length, (index) => chars[rand.nextInt(chars.length)]).join();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showAddUserDialog() {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController identificationNumberController = TextEditingController();
    final TextEditingController nroMatriculaController = TextEditingController();
    bool isProfessional = false;
    String? selectedDocumentType;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Agregar Usuario'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(labelText: 'Email'),
                    ),
                    TextField(
                      controller: passwordController,
                      decoration: InputDecoration(labelText: 'Contraseña'),
                      obscureText: true,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Paciente'),
                        Switch(
                          value: isProfessional,
                          onChanged: (value) {
                            setState(() {
                              isProfessional = value;
                            });
                          },
                        ),
                        Text('Profesional'),
                      ],
                    ),
                    if (isProfessional) ...[
                      DropdownButtonFormField<String>(
                        value: selectedDocumentType,
                        decoration: InputDecoration(
                          labelText: 'Tipo de Documento',
                        ),
                        items: ['DNI', 'Pasaporte', 'Otro'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            selectedDocumentType = newValue;
                          });
                        },
                      ),
                      TextField(
                        controller: identificationNumberController,
                        decoration: InputDecoration(labelText: 'Número de Identificación'),
                      ),
                      TextField(
                        controller: nroMatriculaController,
                        decoration: InputDecoration(labelText: 'Matrícula Nacional'),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    final role = isProfessional ? 'professional' : 'patient';
                    _addUser(
                      emailController.text,
                      passwordController.text,
                      role,
                      selectedDocumentType,
                      identificationNumberController.text,
                      nroMatriculaController.text,
                    );
                    Navigator.of(context).pop();
                  },
                  child: Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    final TextEditingController emailController = TextEditingController(text: user['email']);
    final TextEditingController identificationNumberController = TextEditingController(text: user['idNumber'] ?? '');
    final TextEditingController nroMatriculaController = TextEditingController(text: user['matricula'] ?? '');
    bool isProfessional = user['role'] == 'professional';
    String? selectedDocumentType = user['documentType'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Editar Usuario'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(labelText: 'Email'),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Paciente'),
                        Switch(
                          value: isProfessional,
                          onChanged: (value) {
                            setState(() {
                              isProfessional = value;
                            });
                          },
                        ),
                        Text('Profesional'),
                      ],
                    ),
                    if (isProfessional) ...[
                      DropdownButtonFormField<String>(
                        value: selectedDocumentType,
                        decoration: InputDecoration(
                          labelText: 'Tipo de Documento',
                        ),
                        items: ['DNI', 'Pasaporte', 'Otro'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            selectedDocumentType = newValue;
                          });
                        },
                      ),
                      TextField(
                        controller: identificationNumberController,
                        decoration: InputDecoration(labelText: 'Número de Identificación'),
                      ),
                      TextField(
                        controller: nroMatriculaController,
                        decoration: InputDecoration(labelText: 'Matrícula Nacional'),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    final role = isProfessional ? 'professional' : 'patient';
                    _updateUser(
                      user['id'],
                      emailController.text,
                      role,
                      selectedDocumentType,
                      identificationNumberController.text,
                      nroMatriculaController.text,
                    );
                    Navigator.of(context).pop();
                  },
                  child: Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showUserDetailsDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Detalles del Usuario'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Email: ${user['email']}'),
                Text('Rol: ${user['role']}'),
                if (user['role'] == 'professional') ...[
                  Text('Tipo de Documento: ${user['documentType']}'),
                  Text('Número de Identificación: ${user['idNumber']}'),
                  Text('Matrícula Nacional: ${user['matricula']}'),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void _toggleUserActivation(String id, bool isActive) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(id).update({
        'isActive': isActive,
      });
      _fetchUsers();
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }

  void _sendNotification(String id, String message) async {
    try {
      // Aquí puedes agregar la lógica para enviar una notificación al usuario
      _showErrorSnackBar('Notificación enviada: $message');
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }

  void _showSendNotificationDialog(String id) {
    final TextEditingController messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enviar Notificación'),
          content: TextField(
            controller: messageController,
            decoration: InputDecoration(labelText: 'Mensaje'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                _sendNotification(id, messageController.text);
                Navigator.of(context).pop();
              },
              child: Text('Enviar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Page'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showAddUserDialog,
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar usuario por email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) {
                final user = _filteredUsers[index];
                return ListTile(
                  title: Text(user['email']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.info),
                        onPressed: () {
                          _showUserDetailsDialog(user);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          _showEditUserDialog(user);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          _deleteUser(user['id']);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.refresh),
                        onPressed: () {
                          _resetPassword(user['id']);
                        },
                      ),
                      IconButton(
                        icon: Icon(user['isActive'] ? Icons.block : Icons.check_circle),
                        onPressed: () {
                          _toggleUserActivation(user['id'], !user['isActive']);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.notifications),
                        onPressed: () {
                          _showSendNotificationDialog(user['id']);
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
    );
  }
}