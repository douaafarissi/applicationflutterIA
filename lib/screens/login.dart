import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'activity.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  String email = '';
  String password = '';
  bool rememberPassword = false;
  bool showPassword = false;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple,
      appBar: AppBar(
        title: Text('DouaaApp'),
        actions: [
          TextButton(
            onPressed: () {
              // Navigate to the registration screen
              // Navigator.push(context, MaterialPageRoute(builder: (context) => Register()));
            },
            child: Text(
              'Register',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 20, horizontal: 50),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(height: 20.0),
                // Image.network with the provided image URL and increased size
                Image.network(
                  'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRdi8P0Oe6ZBeSxupmQ2Ey28pE9w-qS7u8I0A&usqp=CAU',
                  height: 150, // Adjust the height as needed
                  width: 150, // Adjust the width as needed
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 30.0),
                TextFormField(
                  onChanged: (value) {
                    setState(() {
                      email = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Email',
                    prefixIcon: Icon(Icons.person),
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 20.0),
                TextFormField(
                  onChanged: (value) {
                    setState(() {
                      password = value;
                    });
                  },
                  obscureText: !showPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          showPassword = !showPassword;
                        });
                      },
                    ),
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 20.0),
                Row(
                  children: [
                    Checkbox(
                      value: rememberPassword,
                      onChanged: (value) {
                        setState(() {
                          rememberPassword = value!;
                        });
                      },
                    ),
                    Text('Remember Password'),
                  ],
                ),
                SizedBox(height: 20.0),
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.cyan),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      login();
                    }
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      'Login',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> login() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ActivityPage()),
      );
    } catch (e) {
      print('Login error: $e');
    }
  }
}
