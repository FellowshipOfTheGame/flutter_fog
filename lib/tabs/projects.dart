import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

final Firestore _db = Firestore.instance;

Widget _buildListItem(BuildContext context, DocumentSnapshot document,
    DocumentReference project) {
  return StreamBuilder(
    stream: _db
        .collection('workedhours')
        .where("member", isEqualTo: document.documentID)
        .where("project", isEqualTo: project)
        .snapshots(),
    builder: (wcontext, wsnapshot) {
      if (!wsnapshot.hasData) return Container();
      int work = 0;
      for (DocumentSnapshot workedhours in wsnapshot.data.documents) {
        work += workedhours['hours'] * 60;
        work += workedhours['minutes'];
      }
      return Card(
        child: ListTile(
          // TODO show member info if clicked
          title: Text(document['name']),
          subtitle: Text('Trabalhou $work minutos'),
          trailing: FlatButton(
            shape: BeveledRectangleBorder(),
            child: Icon(
              // TODO remove member from project
              Icons.delete,
            ),
            onPressed: () {},
          ),
        ),
      );
    },
  );
}

class ProjectsWidget extends StatefulWidget {
  @override
  _ProjectsWidgetState createState() => _ProjectsWidgetState();
}

class _ProjectsWidgetState extends State<ProjectsWidget> {
  final _dialogController = TextEditingController();
  CollectionReference get projects => _db.collection('projects');
  CollectionReference get members => _db.collection('members');
  List<DocumentSnapshot> _notinproject;
  List<DropdownMenuItem<String>> _notinprojectItems =
      List<DropdownMenuItem<String>>();
  String _selectedMember;
  String _project;

  Future<DocumentReference> _addProject(String name) async {
    final DocumentReference document = projects.document();
    document.setData(<String, dynamic>{
      'name': name,
    });

    return document;
  }

  @override
  void dispose() {
    _dialogController.dispose();
    super.dispose();
  }

  Future<Null> _projectDialog() async {
    switch (await showDialog(
        context: context,
        builder: (context) {
          return SimpleDialog(
            title: const Text('Criar projeto'),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _dialogController,
                  autofocus: true,
                ),
              ),
              ButtonTheme.bar(
                child: ButtonBar(
                  children: <Widget>[
                    SimpleDialogOption(
                      onPressed: () {
                        Navigator.pop(context, 0);
                      },
                      child: const Text('Cancelar'),
                    ),
                    SimpleDialogOption(
                      onPressed: () {
                        Navigator.pop(context, 1);
                      },
                      child: const Text('Submeter'),
                    ),
                  ],
                ),
              ),
            ],
          );
        })) {
      case 1:
        _addProject(_dialogController.text);
        _dialogController.clear();
        break;
      case 0:
        break;
    }
  }

  Future<Null> _attMembers() async {
    _notinprojectItems = List<DropdownMenuItem<String>>();
    QuerySnapshot _projectDocument =
        await projects.where("name", isEqualTo: _project).getDocuments();
    if (_projectDocument.documents.length > 0) {
      DocumentReference _projectReference =
          _projectDocument.documents[0].reference;
      QuerySnapshot _membersDocuments = await members.getDocuments();
      _notinproject = List<DocumentSnapshot>();

      for (DocumentSnapshot member in _membersDocuments.documents) {
        if (!member['projects'].contains(_projectReference)) {
          _notinproject.add(member);
          _notinprojectItems.add(DropdownMenuItem<String>(
            value: member['name'],
            child: Text(member['name']),
          ));
        }
      }
    }
    if (_notinprojectItems.isEmpty) {
      _notinprojectItems.add(
        DropdownMenuItem<String>(
          child: Container(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_notinprojectItems.isEmpty) {
      _notinprojectItems.add(
        DropdownMenuItem<String>(
          child: Container(),
        ),
      );
    }
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: <Widget>[
              Expanded(
                child: InputDecorator(
                  decoration: InputDecoration(),
                  child: DropdownButtonHideUnderline(
                    child: StreamBuilder(
                      stream: projects.orderBy('name').snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return Container();
                        List<DropdownMenuItem<String>> _items =
                            List<DropdownMenuItem<String>>();
                        snapshot.data.documents.forEach((document) {
                          String _name = document['name'];
                          _items.add(DropdownMenuItem<String>(
                            value: _name,
                            child: Text(_name),
                          ));
                        });
                        if (_items.isEmpty)
                          _items.add(
                            DropdownMenuItem<String>(
                              child: Container(),
                            ),
                          );
                        return DropdownButton<String>(
                          hint: const Text('Selecionar projeto'),
                          value: _project,
                          isDense: true,
                          items: _items,
                          onChanged: (value) async {
                            await _attMembers();
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
        ),
        Expanded(
          child: StreamBuilder(
            stream: projects.where("name", isEqualTo: _project).snapshots(),
            builder: (pcontext, psnapshot) {
              if (!psnapshot.hasData)
                return Center(child: CircularProgressIndicator());
              if (psnapshot.data.documents.length <= 0) return Container();
              return StreamBuilder(
                stream: members.snapshots(),
                builder: (mcontext, msnapshot) {
                  if (!msnapshot.hasData)
                    return Center(child: CircularProgressIndicator());

                  List<DocumentSnapshot> _inproject = List<DocumentSnapshot>();
                  for (DocumentSnapshot member in msnapshot.data.documents) {
                    if (member['projects']
                        .contains(psnapshot.data.documents[0].reference)) {
                      _inproject.add(member);
                    }
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                    itemCount: _inproject.length + 1,
                    itemBuilder: (context, index) {
                      if (index != _inproject.length)
                        return _buildListItem(context, _inproject[index],
                            psnapshot.data.documents[0].reference);
                      else
                        return StreamBuilder(
                          stream: _db
                              .collection('workedhours')
                              .where("project",
                                  isEqualTo:
                                      psnapshot.data.documents[0].reference)
                              .snapshots(),
                          builder: (wcontext, wsnapshot) {
                            if (!wsnapshot.hasData) return Container();
                            int work = 0;
                            for (DocumentSnapshot workedhours
                                in wsnapshot.data.documents) {
                              work += workedhours['hours'] * 60;
                              work += workedhours['minutes'];
                            }
                            return Card(
                              child: ListTile(
                                title: Text('Resumo'),
                                subtitle: Text('Trabalhou $work minutos'),
                              ),
                            );
                          },
                        );
                    },
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: <Widget>[
              Expanded(
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Membros *',
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      hint: Text('Selecionar membro'),
                      value: _selectedMember,
                      isDense: true,
                      items: _notinprojectItems,
                      onChanged: (value) {
                        setState(() {
                          _selectedMember = value;
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              RaisedButton(
                child: Text(
                    'Adicionar membro'), // Change to a select member by search and return intent
                onPressed: () async {
                  if (_selectedMember != null) {
                    QuerySnapshot _projectDocument = await projects
                        .where("name", isEqualTo: _project)
                        .getDocuments();
                    if (_projectDocument.documents.length > 0) {
                      DocumentReference _projectReference =
                          _projectDocument.documents[0].reference;
                      DocumentSnapshot _theone;
                      for (DocumentSnapshot member in _notinproject) {
                        if (member['name'] == _selectedMember) {
                          _theone = member;
                          break;
                        }
                      }
                      dynamic aux = List<dynamic>.from(_theone['projects']);
                      aux.add(_projectReference);
                      await Firestore.instance
                          .runTransaction((transaction) async {
                        await transaction
                            .update(_theone.reference, {'projects': aux});
                      });

                      await _attMembers();
                      setState(() {
                        _selectedMember = null;
                      });
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
