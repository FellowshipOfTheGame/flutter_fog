import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

final Firestore _db = Firestore.instance;

class ProjectsWidget extends StatefulWidget {
  @override
  _ProjectsWidgetState createState() => _ProjectsWidgetState();
}

class _ProjectsWidgetState extends State<ProjectsWidget> {
  final _dialogController = TextEditingController();
  CollectionReference get projects => _db.collection('projects');
  String _project;

  Future<DocumentReference> _addProject(String name) async {
    final DocumentReference document = projects.document();
    document.setData(<String, dynamic>{
      'name': name,
    });

    return document;
  }

  Future<Null> _projectDialog() async {
    switch (await showDialog(
        context: context,
        builder: (context) {
          return SimpleDialog(
            title: const Text('Create Project'),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _dialogController,
                  autofocus: true,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  SimpleDialogOption(
                    onPressed: () {
                      Navigator.pop(context, 0);
                    },
                    child: const Text('Cancel'),
                  ),
                  SimpleDialogOption(
                    onPressed: () {
                      Navigator.pop(context, 1);
                    },
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ],
          );
        })) {
      case 1:
        _addProject(_dialogController.text);
        _dialogController.dispose();
        break;
      case 0:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(
        left: 16.0,
        top: 16.0,
        bottom: 16.0,
      ),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: InputDecorator(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                ),
                child: DropdownButtonHideUnderline(
                  child: StreamBuilder(
                    stream: projects.snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return Container();
                      List<DropdownMenuItem<String>> _items =
                          List<DropdownMenuItem<String>>();
                      for (DocumentSnapshot document
                          in snapshot.data.documents) {
                        String _name = document['name'];
                        _items.add(DropdownMenuItem<String>(
                          value: _name,
                          child: Text(_name),
                        ));
                      }
                      if (_items.isEmpty)
                        _items.add(
                          DropdownMenuItem<String>(
                            child: Container(),
                          ),
                        );
                      return DropdownButton<String>(
                        hint: const Text('Select project'),
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
                  ),
                ),
              ),
            ),
            FlatButton(
              shape: BeveledRectangleBorder(),
              child: Icon(
                Icons.add,
              ),
              onPressed: () async {
                await _projectDialog();
              },
            ),
          ],
        ),
      ],
    );
  }
}
