import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fog_members/tabs/members.dart';

final Firestore _db = Firestore.instance;

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
  String _project;

  Future<DocumentReference> _addProject(String name) async {
    final DocumentReference document = projects.document();
    document.setData(<String, dynamic>{
      'name': name,
    });

    return document;
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot document,
      DocumentReference project) {
    return StreamBuilder(
      stream: _db
          .collection('workedhours')
          .where('member', isEqualTo: document.documentID)
          .where('project', isEqualTo: project)
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
            title: Text(document['name']),
            subtitle: Text('Trabalhou $work minutos'),
            trailing: FlatButton(
              shape: BeveledRectangleBorder(),
              child: Icon(Icons.delete),
              onPressed: () async {
                switch (await showDialog(
                  context: context,
                  builder: (context) {
                    return SimpleDialog(
                      children: <Widget>[
                        Center(
                            child:
                                const Text('Você tem certeza? (Não há volta)')),
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
                                child: const Text('Deletar'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                )) {
                  case 1:
                    dynamic projects = List<dynamic>.from(document['projects']);
                    projects.remove(project);
                    Firestore.instance.runTransaction((transaction) async {
                      await transaction
                          .update(document.reference, {'projects': projects});
                    });

                    break;
                  default:
                    break;
                }
              },
            ),
            onTap: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => ShowMemberDetails(document)));
            },
          ),
        );
      },
    );
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
        await projects.where('name', isEqualTo: _project).getDocuments();
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
              if (psnapshot.data.documents.length <= 0 || _project == null)
                return Container();
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
                                title: const Text('Resumo'),
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
          child: RaisedButton(
            child: const Text(
                'Adicionar membro'), // Change to a select member by search and return intent
            onPressed: _project == null
                ? null
                : () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return Scaffold(
                            appBar: AppBar(
                              title: const Text('Adicionar membro'),
                            ),
                            body: MembersProjectWidget(_project),
                          );
                        },
                      ),
                    );
                  },
          ),
        ),
      ],
    );
  }
}

class MembersProjectWidget extends StatefulWidget {
  const MembersProjectWidget(this.project, {Key key}) : super(key: key);

  final String project;

  @override
  _MembersProjectWidgetState createState() => _MembersProjectWidgetState();
}

class _MembersProjectWidgetState extends State<MembersProjectWidget> {
  final _searchController = TextEditingController();
  List<DocumentSnapshot> selectionfiles;
  List<bool> selection = List<bool>();

  Widget _buildListItem(BuildContext context, DocumentSnapshot document,
      int index, String project) {
    return Card(
      color: selection[index] ? Colors.grey : Colors.white,
      child: ListTile(
        selected: selection[index],
        title: Text(document['name']),
        onTap: selection[index]
            ? () {
                setState(() {
                  selection[index] = false;
                });
              }
            : (selection.indexOf(true) != -1
                ? () {
                    setState(() {
                      selection[index] = true;
                    });
                  }
                : () async {
                    QuerySnapshot _projectDocument = await _db
                        .collection('projects')
                        .where("name", isEqualTo: project)
                        .getDocuments();
                    if (_projectDocument.documents.length > 0) {
                      DocumentReference _projectReference =
                          _projectDocument.documents[0].reference;

                      dynamic aux = List<dynamic>.from(document['projects']);
                      aux.add(_projectReference);
                      _db.runTransaction((transaction) async {
                        await transaction
                            .update(document.reference, {'projects': aux});
                      });

                      Navigator.pop(context);
                    }
                  }),
        onLongPress: () {
          setState(() {
            selection[index] = true;
          });
        },
      ),
    );
  }

  Future<List<DocumentSnapshot>> _searchedMembers(
      List<DocumentSnapshot> allmembers) async {
    List<DocumentSnapshot> _members = List<DocumentSnapshot>();
    for (DocumentSnapshot member in allmembers) {
      bool inside = false;

      List<DocumentReference> inproj = List.from(member['projects']);

      QuerySnapshot _projectDocument = await _db
          .collection('projects')
          .where('name', isEqualTo: widget.project)
          .getDocuments();

      if (_projectDocument.documents.length > 0) {
        for (String name in member['name'].split(' ')) {
          if (!inside &&
              inproj.indexOf(_projectDocument.documents[0].reference) == -1 &&
              name
                  .toLowerCase()
                  .startsWith(_searchController.text.toLowerCase())) {
            _members.add(member);
            inside = true;
          }
        }
      }
    }

    if (selection.length != _members.length) {
      selection.length = _members.length;
      selection = List<bool>.filled(_members.length, false);
      selectionfiles = List.from(_members);
    }

    return _members;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Procurar nome',
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),
        ),
        StreamBuilder(
          stream: _db
              .collection('members')
              .orderBy('authority')
              .where('authority', isGreaterThanOrEqualTo: 0)
              .orderBy('name')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return LinearProgressIndicator();
            return FutureBuilder(
              future: _searchedMembers(snapshot.data.documents),
              builder: (context, ssnapshot) {
                if (!ssnapshot.hasData)
                  return Center(child: CircularProgressIndicator());
                return Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                    itemCount: ssnapshot.data.length,
                    itemBuilder: (context, index) => _buildListItem(
                        context, ssnapshot.data[index], index, widget.project),
                  ),
                );
              },
            );
          },
        ),
        Builder(
          builder: (context) {
            if (selection.indexOf(true) != -1) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: RaisedButton(
                  child: const Text(
                      'Adicionar membro'), // Change to a select member by search and return intent
                  onPressed: () async {
                    QuerySnapshot _projectDocument = await _db
                        .collection('projects')
                        .where('name', isEqualTo: widget.project)
                        .getDocuments();

                    if (_projectDocument.documents.length > 0) {
                      DocumentReference _projectReference =
                          _projectDocument.documents[0].reference;

                      for (int i = 0; i < selection.length; i++) {
                        if (selection[i]) {
                          dynamic aux =
                              List<dynamic>.from(selectionfiles[i]['projects']);
                          aux.add(_projectReference);
                          print(selectionfiles[i]['name']);
                          _db.runTransaction((transaction) async {
                            await transaction.update(
                                selectionfiles[i].reference, {'projects': aux});
                          });
                        }
                      }

                      Navigator.pop(context);
                    }
                  },
                ),
              );
            } else {
              return Container();
            }
          },
        ),
      ],
    );
  }
}
