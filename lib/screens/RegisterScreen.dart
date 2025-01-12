import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../global.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

//variables:
const textfieldscolorfill = Colors.white;

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _errorMessage = '';
  String? _selectedFamilyId;
  List<Map<String, dynamic>> _families = [];
  bool _termsAccepted = false;
  bool _termsExpanded = false;
  String _termsText = '';

  @override
  void initState() {
    super.initState();
    _fetchFamilies();
    _loadTerms();
  }

  Future<void> _fetchFamilies() async {
    try {
      final nameMap = await lookupFunction('name');
      setState(() {
        _families = nameMap.entries.map((entry) {
          return {
            'id': entry.key,
            'name': entry.value ?? 'Unnamed Family',
          };
        }).toList();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load families: $e';
      });
    }
  }

  Future<void> _loadTerms() async {
    try {
      final terms = await rootBundle.loadString('assets/terms.txt');
      setState(() {
        _termsText = terms;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load terms: $e';
      });
    }
  }

  Future<void> _register() async {
    if (_selectedFamilyId == null) {
      setState(() {
        _errorMessage = 'Please select a family.';
      });
      return;
    }
    if (!_termsAccepted) {
      setState(() {
        _errorMessage = 'You must accept the terms of use to create an account.';
      });
      return;
    }

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final uid = userCredential.user!.uid;

      await _firestore.collection('families').doc(_selectedFamilyId).update({
        'members': FieldValue.arrayUnion([uid]),
      });

      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "REGISTER",
          style: TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.bold,
            fontFamily: 'MyCustomFont',
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Spacer(), // Pushes content to bottom
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Colors.black, width: 2.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Colors.black, width: 2.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Colors.black, width: 2.0),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Colors.black, width: 2.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Colors.black, width: 2.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Colors.black, width: 2.0),
                  ),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Register'),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.black, width: 1),
                ),
                child: DropdownButton<String>(
                  value: _selectedFamilyId,
                  hint: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      'Select a Family',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  items: _families.map((family) {
                    return DropdownMenuItem<String>(
                      value: family['id'],
                      child: Container(
                        padding: const EdgeInsets.all(4.0),
                        child: Text(
                          family['name'],
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'MyCustomFont',
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedFamilyId = value;
                    });
                  },
                  isExpanded: true,
                  underline: Container(),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                    Checkbox(
                    value: _termsAccepted,
                    onChanged: (bool? value) {
                      setState(() {
                      _termsAccepted = value ?? false;
                      });
                    },
                    ),
                    const Text('I accept the terms of use'),
                    const Spacer(),
                    TextButton(
                    onPressed: () {
                      setState(() {
                      _termsExpanded = !_termsExpanded;
                      });
                    },
                    child: Text(_termsExpanded ? 'Hide' : 'Show'),
                    ),
                  ],
                  ),
                  if (_termsExpanded)
                  Container(
                    decoration: BoxDecoration(
                    color: textfieldscolorfill,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black, width: 1),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                    height: 200, // Set a fixed height for the scrollable area
                    child: SingleChildScrollView(
                      child: Text(_termsText),
                    ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_errorMessage.isNotEmpty)
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 5), // Bottom padding
            ]
          ),
        ),
      ),
    );
  }
}