import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final Firestore _db = Firestore.instance;

class SignUpWidget extends StatefulWidget {
  @override
  _SignUpWidget createState() => new _SignUpWidget();
}

class _SignUpWidget extends State<SignUpWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _cpassController = TextEditingController();
  Future<bool> _sigin = Future.value(false);
  CollectionReference get members => _db.collection('members');

  Future<Null> _addMember(FirebaseUser user) async {
    final DocumentReference document = members.document(user.uid);
    document.setData(<String, dynamic>{
      'name': user.displayName,
      'authority': 0,
      'projects': [],
    });
  }

  Widget loading(bool value) {
    if (value) {
      return Center(child: CircularProgressIndicator());
    } else {
      return Container();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _cpassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sign Up"),
      ),
      body: FutureBuilder(
        future: _sigin,
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());
          return Stack(
            children: <Widget>[
              ListView(
                padding: const EdgeInsets.only(
                    left: 16.0, bottom: 16.0, right: 16.0, top: 32.0),
                children: <Widget>[
                  Form(
                    key: _formKey,
                    child: Column(children: <Widget>[
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Name *',
                        ),
                        validator: (value) {
                          if (value.isEmpty) return 'Name is empty';
                        },
                      ),
                      const SizedBox(height: 12.0),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Email *',
                        ),
                        validator: (value) {
                          if (value.isEmpty) return 'Email is empty';
                          if (value.contains(' ') ||
                              !value.contains(RegExp(r'^[^@]+@[^.]+\..+$')))
                            return 'Invalid email';
                        },
                      ),
                      const SizedBox(height: 12.0),
                      TextFormField(
                        controller: _passController,
                        decoration: InputDecoration(
                          labelText: 'Password *',
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
                      const SizedBox(height: 12.0),
                      TextFormField(
                        controller: _cpassController,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password *',
                        ),
                        validator: (value) {
                          if (value != _passController.text)
                            return 'Passwords do not match';
                        },
                        obscureText: true,
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16.0),
                  RaisedButton(
                    child: Text('Confirm'),
                    onPressed: () async {
                      if (_formKey.currentState.validate() && !snapshot.data) {
                        setState(() {
                          _sigin = Future.value(true);
                        });

                        try {
                          await _auth.createUserWithEmailAndPassword(
                              email: _emailController.text,
                              password: _passController.text);
                          UserUpdateInfo _user = UserUpdateInfo();
                          _user.displayName = _nameController.text;
                          await _auth.updateProfile(_user);

                          FirebaseUser user = await _auth.currentUser();
                          _addMember(user);
                          Navigator.of(context).pop(user);
                        } catch (e) {
                          if (e.message ==
                              'The email address is already in use by another account.') {
                            Scaffold.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Email already in use'),
                              ),
                            );
                          } else {
                            print(e.message);
                            Scaffold.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Unknown error please report'),
                              ),
                            );
                          }
                          setState(() {
                            _sigin = Future.value(false);
                          });
                        }
                      }
                    },
                  ),
                ],
              ),
              loading(snapshot.data),
            ],
          );
        },
      ),
    );
  }
}
