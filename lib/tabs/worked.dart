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
  bool _textra = false;
  int _tfinished;
  int _estimate;
  final _hoursController = TextEditingController(text: '0');
  final _minutesController = TextEditingController(text: '0');
  final _notdoneController = TextEditingController();
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
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: <Widget>[
        InputDecorator(
          decoration: InputDecoration(
            labelText: 'Project *',
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
                        usnapshot.data['projects'].forEach((project) {
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
        InputDecorator(
          decoration: InputDecoration(
            labelText: 'Worked Hours *',
          ),
          child: Row(
            children: <Widget>[
              Flexible(
                child: TextField(
                  controller: _hoursController,
                  keyboardType: TextInputType.number,
                  decoration: null,
                ),
              ),
              const SizedBox(width: 12.0),
              Text(':'),
              const SizedBox(width: 12.0),
              Flexible(
                child: TextField(
                  controller: _minutesController,
                  keyboardType: TextInputType.number,
                  decoration: null,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12.0),
        TextField(
          keyboardType: TextInputType.multiline,
          controller: _notdoneController,
          maxLines: 5,
          decoration: InputDecoration(
            labelText: 'Work not finished',
          ),
        ),
        const SizedBox(height: 12.0),
        Text('Finished work percentage *'),
        Row(
          children: <Widget>[
            Text('0%'),
            Flexible(
              child: RadioListTile(
                groupValue: 0,
                onChanged: (int value) {
                  setState(() {
                    _tfinished = 0;
                  });
                },
                value: _tfinished,
              ),
            ),
            Flexible(
              child: RadioListTile(
                groupValue: 20,
                onChanged: (int value) {
                  setState(() {
                    _tfinished = 20;
                  });
                },
                value: _tfinished,
              ),
            ),
            Flexible(
              child: RadioListTile(
                groupValue: 40,
                onChanged: (int value) {
                  setState(() {
                    _tfinished = 40;
                  });
                },
                value: _tfinished,
              ),
            ),
            Flexible(
              child: RadioListTile(
                groupValue: 60,
                onChanged: (int value) {
                  setState(() {
                    _tfinished = 60;
                  });
                },
                value: _tfinished,
              ),
            ),
            Flexible(
              child: RadioListTile(
                groupValue: 80,
                onChanged: (int value) {
                  setState(() {
                    _tfinished = 80;
                  });
                },
                value: _tfinished,
              ),
            ),
            Flexible(
              child: RadioListTile(
                groupValue: 100,
                onChanged: (int value) {
                  setState(() {
                    _tfinished = 100;
                  });
                },
                value: _tfinished,
              ),
            ),
            Text('100%'),
          ],
        ),
        const SizedBox(height: 12.0),
        Text('Correctly estimate work time *'),
        Row(
          children: <Widget>[
            Column(
              children: <Widget>[
                Text(
                  'Completely',
                ),
                Text(
                  'Disagree',
                ),
              ],
            ),
            Flexible(
              child: RadioListTile(
                groupValue: 0,
                onChanged: (int value) {
                  setState(() {
                    _estimate = 0;
                  });
                },
                value: _estimate,
              ),
            ),
            Flexible(
              child: RadioListTile(
                groupValue: 1,
                onChanged: (int value) {
                  setState(() {
                    _estimate = 1;
                  });
                },
                value: _estimate,
              ),
            ),
            Flexible(
              child: RadioListTile(
                groupValue: 2,
                onChanged: (int value) {
                  setState(() {
                    _estimate = 2;
                  });
                },
                value: _estimate,
              ),
            ),
            Flexible(
              child: RadioListTile(
                groupValue: 3,
                onChanged: (int value) {
                  setState(() {
                    _estimate = 3;
                  });
                },
                value: _estimate,
              ),
            ),
            Column(
              children: <Widget>[
                Text(
                  'Completely',
                ),
                Text(
                  'Agree',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12.0),
        SwitchListTile(
          title: Text('Extra work done?'),
          value: _textra,
          onChanged: (bool value) {
            setState(() {
              _textra = value;
            });
          },
        ),
        const SizedBox(height: 12.0),
        RaisedButton(
          child: Text("Add event"),
          onPressed: () async {
            if (_tfinished == null) {
              Scaffold.of(context).showSnackBar(SnackBar(
                content: Text('Please select a finished work percentage'),
              ));
            } else if (_estimate == null) {
              Scaffold.of(context).showSnackBar(SnackBar(
                content: Text('Please select a estimate work time'),
              ));
            } else {
              int _hours = _hoursController.text.isEmpty
                      ? 0
                      : int.parse(_hoursController.text),
                  _minutes = _minutesController.text.isEmpty
                      ? 0
                      : int.parse(_minutesController.text);

              _addWorkedHours(
                _project,
                _hours,
                _minutes,
                _tfinished,
                _estimate,
                _textra,
                _notdoneController.text,
              );

              _hoursController.text = '0';
              _minutesController.text = '0';
              _notdoneController.clear();
              _tfinished = null;
              _estimate = null;
              setState(() {
                _textra = false;
              });
            }
          },
        ),
      ],
    );
  }
}
