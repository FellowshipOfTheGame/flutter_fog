import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

class SignUpWidget extends StatefulWidget {
  @override
  _SignUpWidget createState() => new _SignUpWidget();
}

class _SignUpWidget extends State<SignUpWidget> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sign Up"),
      ),
      body: Padding(
        padding: const EdgeInsets.only(
            left: 16.0, bottom: 16.0, right: 16.0, top: 32.0),
        child: Column(
          children: <Widget>[
            Form(
              key: _formKey,
              child: Column(children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'E-mail',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value.isEmpty) return 'E-mail is empty';
                      if (value.contains(' ') ||
                          !value.contains(RegExp(r'^[^@]+@[^.]+\..+$')))
                        return 'Invalid e-mail';
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: TextFormField(
                    controller: _passController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value.isEmpty) return 'Password is empty';
                      if (value.length < 8)
                        return 'Password needs to be at least 8 caracters long';
                      if (!value.contains(RegExp(r'[a-zA-Z]')) ||
                          !value.contains(RegExp(r'[0-9]')))
                        return 'Password needs to contain numbers and letters';
                    },
                    obscureText: true,
                  ),
                ),
              ]),
            ),
            RaisedButton(
              onPressed: () async {
                if (_formKey.currentState.validate()) {
                  try {
                    FirebaseUser user =
                        await _auth.createUserWithEmailAndPassword(
                            email: _emailController.text,
                            password: _passController.text);
                    Navigator.of(context).pop(user);
                  } catch (e) {}
                }
              },
              child: Text('Signup'),
            ),
          ],
        ),
      ),
    );
  }
}
