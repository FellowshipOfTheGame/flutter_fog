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
  CollectionReference get presences => _db.collection('presences');
  CollectionReference get members => _db.collection('members');
  CollectionReference get events => _db.collection('events');

  Future<Null> _addPresence(
      DocumentReference event, DocumentReference member, bool went) async {
    final DocumentReference document = presences.document();
    document.setData(<String, dynamic>{
      'event': event,
      'member': member,
      'went': went,
    });
  }

  Future<Null> _addMember(FirebaseUser user) async {
    final DocumentReference document = members.document(user.uid);
    document.setData(<String, dynamic>{
      'name': user.displayName,
      'email': user.email,
      'photo': user.photoUrl,
      'authority': -1,
      'projects': [],
    });

    QuerySnapshot query = await events.getDocuments();
    for (DocumentSnapshot event in query.documents) {
      if (event['to'].isAfter(DateTime.now())) {
        _addPresence(event.reference, document, false);
      }
    }
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
        title: const Text('Signup'),
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
                          labelText: 'Nome *',
                        ),
                        validator: (value) {
                          if (value.isEmpty) return 'Nome não pode ser vazio';
                        },
                      ),
                      const SizedBox(height: 12.0),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email *',
                        ),
                        validator: (value) {
                          if (value.isEmpty) return 'Email não pode ser vazio';
                          if (value.contains(' ') ||
                              !value.contains(RegExp(r'^[^@]+@[^.]+\..+$')))
                            return 'Invalid email';
                        },
                      ),
                      const SizedBox(height: 12.0),
                      TextFormField(
                        controller: _passController,
                        decoration: InputDecoration(
                          labelText: 'Senha *',
                        ),
                        validator: (value) {
                          if (value.isEmpty) return 'Senha não pode ser vazio';
                          if (value.length < 8)
                            return 'Senha precisa ter pelo menos 8 caracteres';
                          if (!value.contains(RegExp(r'[a-zA-Z]')) ||
                              !value.contains(RegExp(r'[0-9]')))
                            return 'Senha precisa ter números e letras';
                        },
                        obscureText: true,
                      ),
                      const SizedBox(height: 12.0),
                      TextFormField(
                        controller: _cpassController,
                        decoration: InputDecoration(
                          labelText: 'Confirmar senha *',
                        ),
                        validator: (value) {
                          if (value != _passController.text)
                            return 'As senhas não são iguais';
                        },
                        obscureText: true,
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16.0),
                  RaisedButton(
                    child: const Text('Confirmar'),
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
                          user.sendEmailVerification();
                          _addMember(user);
                          Navigator.of(context).pop(user);
                        } catch (e) {
                          if (e.message ==
                              'The email address is already in use by another account.') {
                            Scaffold.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                    'Esse email já está sendo usado'),
                              ),
                            );
                          } else {
                            print(e.message);
                            Scaffold.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    const Text('Deu ruim reporte esse erro'),
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
