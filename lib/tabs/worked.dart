import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final Firestore _db = Firestore.instance;

class AddWork extends StatefulWidget {
  static const String routeName = '/material/date-and-time-pickers';

  @override
  _AddWork createState() => _AddWork();
}

class _AddWork extends State<AddWork> {
  String _project;
  bool textra = false;
  final _hoursController = TextEditingController(text: '0');
  final _minutesController = TextEditingController(text: '0');
  final _notdoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  CollectionReference get workedhours => _db.collection('workedhours');
  CollectionReference get projects => _db.collection('projects');
  CollectionReference get members => _db.collection('members');

  Future<DocumentReference> _addWorkedHours(
    String project,
    int hours,
    int minutes,
    int tfinished,
    int estimate,
    bool textra,
    String notdone,
  ) async {
    final _user = await _auth.currentUser();
    final DocumentReference document = workedhours.document();
    document.setData(<String, dynamic>{
      'member': _user.uid,
      'project': project,
      'hours': hours,
      'minutes': minutes,
      'tfinished': tfinished,
      'estimate': estimate,
      'textra': textra,
      'notdone': notdone,
    });

    return document;
  }

  Future<DocumentSnapshot> getUserSnapshot() async {
    FirebaseUser _user = await _auth.currentUser();
    DocumentSnapshot document = await members.document(_user.uid).get();
    return document;
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    _notdoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          InputDecorator(
            decoration: InputDecoration(
              border: OutlineInputBorder(),
            ),
            child: DropdownButtonHideUnderline(
              child: FutureBuilder(
                  future: getUserSnapshot(),
                  builder: (context, usnapshot) {
                    if (!usnapshot.hasData) return Container();
                    return StreamBuilder(
                      stream: projects.snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return Container();
                        List<DropdownMenuItem<String>> _items =
                            List<DropdownMenuItem<String>>();
                        snapshot.data.documents.forEach((document) {
                          usnapshot.data['projects'].forEarch((project) {
                            if (document.reference == project) {
                              _items.add(DropdownMenuItem<String>(
                                value: document['name'],
                                child: Text(document['name']),
                              ));
                            }
                          });
                        });
                        if (_items.isEmpty)
                          _items.add(
                            DropdownMenuItem<String>(
                              child: Container(),
                            ),
                          );
                        return DropdownButton<String>(
                          hint: Text('Select project'),
                          value: _project,
                          isDense: true,
                          items: _items,
                          onChanged: (value) {
                            setState(() {
                              _project = value;
                            });
                          },
                        );
                      },
                    );
                  }),
            ),
          ),
          const SizedBox(height: 12.0),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Flexible(
                child: TextFormField(
                  controller: _hoursController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Hours *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value.isEmpty) return 'Hours is empty';
                  },
                ),
              ),
              const SizedBox(width: 12.0),
              Text(':'),
              const SizedBox(width: 12.0),
              Flexible(
                child: TextFormField(
                  controller: _minutesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Minutes *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value.isEmpty) return 'Minutes is empty';
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          TextField(
            keyboardType: TextInputType.multiline,
            controller: _notdoneController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Work not finished',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12.0),
          CheckboxListTile(
            title: Text('Extra work done?'),
            value: textra,
            onChanged: (bool value) {
              setState(() {
                textra = value;
              });
            },
          ),
          const SizedBox(height: 12.0),
          RaisedButton(
            child: Text("Add event"),
            onPressed: () async {
              if (_formKey.currentState.validate()) {
                _addWorkedHours(
                  _project,
                  int.parse(_hoursController.text),
                  int.parse(_minutesController.text),
                  3,
                  3,
                  textra,
                  _notdoneController.text,
                );

                _hoursController.clear();
                _minutesController.clear();
                _notdoneController.clear();
                setState(() {
                  textra = false;
                });
              }
            },
          ),
        ],
      ),
    );
  }
}
