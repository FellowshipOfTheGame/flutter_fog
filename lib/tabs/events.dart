import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fog_members/extra/inputs.dart';
import 'package:fog_members/tabs/qrgenerator.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final Firestore _db = Firestore.instance;

String weekdayByNumber(int day) {
  if (day == DateTime.monday) {
    return "seg";
  } else if (day == DateTime.tuesday) {
    return "ter";
  } else if (day == DateTime.wednesday) {
    return "qua";
  } else if (day == DateTime.thursday) {
    return "qui";
  } else if (day == DateTime.friday) {
    return "sex";
  } else if (day == DateTime.saturday) {
    return "sáb";
  } else if (day == DateTime.sunday) {
    return "dom";
  } else {
    return "err";
  }
}

String formatTime(DateTime from, DateTime to) {
  String _fromh;
  String _fromm;
  String _toh;
  String _tom;

  from.minute < 10 ? _fromm = "0${from.minute}" : _fromm = "${from.minute}";
  to.minute < 10 ? _tom = "0${to.minute}" : _tom = "${to.minute}";
  from.hour < 10 ? _fromh = "0${from.hour}" : _fromh = "${from.hour}";
  to.hour < 10 ? _toh = "0${to.hour}" : _toh = "${to.hour}";

  return "$_fromh:$_fromm - $_toh:$_tom";
}

Widget _eventCard(BuildContext context, DocumentSnapshot document) {
  return Card(
    color: document['mandatory'] ? Colors.red : Colors.white,
    child: ListTile(
      title: Text(document['name']),
      subtitle: Text(
        formatTime(document['from'], document['to']),
      ),
      onTap: () async {
        FirebaseUser _user = await _auth.currentUser();
        DocumentReference _ref = _db.collection("members").document(_user.uid);
        DocumentSnapshot member = await _ref.get();
        await Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => ShowEventDetails(document, member)));
      },
    ),
  );
}

Widget _buildListItem(BuildContext context, DocumentSnapshot document) {
  return Row(
    key: Key(document.documentID),
    children: <Widget>[
      Expanded(
        flex: 1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              "${document['from'].day}/${document['from'].month}",
              style: Theme.of(context).textTheme.subhead,
            ),
            Text(
              weekdayByNumber(document['from'].weekday),
              style: Theme.of(context).textTheme.body1,
            ),
          ],
        ),
      ),
      Expanded(flex: 5, child: _eventCard(context, document))
    ],
  );
}

class ShowEventDetails extends StatefulWidget {
  const ShowEventDetails(this.event, this.member, {Key key}) : super(key: key);

  final DocumentSnapshot event;
  final DocumentSnapshot member;

  @override
  _ShowEventDetailsState createState() => _ShowEventDetailsState();
}

class _ShowEventDetailsState extends State<ShowEventDetails> {
  bool _just = false;

  Future<Null> _addJustify(
    DocumentReference presence,
    String reason,
  ) async {
    final DocumentReference document = _db.collection('justifies').document();
    await document.setData(<String, dynamic>{
      'presence': presence,
      'reason': reason,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event['name']),
      ),
      body: FutureBuilder(
        future: _db
            .collection('presences')
            .where('event', isEqualTo: widget.event.reference)
            .where('member', isEqualTo: widget.member.reference)
            .getDocuments(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());
          return Column(
            children: <Widget>[
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: <Widget>[
                    Text('De: ${widget.event['from']}'),
                    const SizedBox(height: 4.0),
                    Text('Até: ${widget.event['to']}'),
                    Divider(),
                    Text(
                      'Descrição: ${widget.event['description']}',
                      overflow: TextOverflow.clip,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16.0, left: 16.0),
                child: RaisedButton(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        child: Image.asset(
                          'assets/qr-code.png',
                          color: (snapshot.data.documents.length <= 0 ||
                                  snapshot.data.documents[0]['went'] ||
                                  _just)
                              ? Colors.grey
                              : Colors.black,
                        ),
                        width: 18.0,
                        height: 18.0,
                      ),
                      const SizedBox(width: 12.0),
                      const Text('Ler QR'),
                    ],
                  ),
                  onPressed: (snapshot.data.documents.length <= 0 ||
                          snapshot.data.documents[0]['went'] ||
                          _just)
                      ? null
                      : () async {
                          if (await readQR(
                                  widget.event, snapshot.data.documents[0]) ==
                              true) {
                            Scaffold.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Presença adicionada'),
                              ),
                            );

                            setState(() {});
                          }
                        },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16.0, left: 16.0),
                child: RaisedButton(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.subject),
                      const SizedBox(width: 12.0),
                      const Text('Justificar falta'),
                    ],
                  ),
                  onPressed: (snapshot.data.documents.length <= 0 ||
                          snapshot.data.documents[0]['went'] ||
                          _just)
                      ? null
                      : () async {
                          final _reasonController = TextEditingController();

                          switch (await showDialog(
                            context: context,
                            builder: (context) {
                              return SimpleDialog(
                                children: <Widget>[
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Center(
                                      child: TextField(
                                        keyboardType: TextInputType.multiline,
                                        controller: _reasonController,
                                        maxLines: 5,
                                        decoration: InputDecoration(
                                          labelText: 'Razão',
                                        ),
                                      ),
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
                                          child: const Text('Enviar'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          )) {
                            case 1:
                              await _addJustify(
                                  snapshot.data.documents[0].reference,
                                  _reasonController.text);
                              Scaffold.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      const Text('Justificativa adicionada'),
                                ),
                              );

                              setState(() {
                                _just = true;
                              });
                              break;
                            default:
                              break;
                          }
                        },
                ),
              ),
              Builder(
                builder: (context) {
                  if (widget.member['authority'] == 1) {
                    return Padding(
                      padding: const EdgeInsets.only(
                          right: 16.0, left: 16.0, bottom: 8.0),
                      child: RaisedButton(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(Icons.add),
                            const SizedBox(width: 12.0),
                            const Text('Gerar QR'),
                          ],
                        ),
                        onPressed: () async {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => QRGenerator(widget.event)));
                        },
                      ),
                    );
                  }
                  return Container();
                },
              ),
              Builder(
                builder: (context) {
                  if (widget.member['authority'] == 1) {
                    return Padding(
                      padding: const EdgeInsets.only(
                          right: 16.0, left: 16.0, bottom: 8.0),
                      child: RaisedButton(
                        color: Colors.red,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(Icons.delete_forever),
                            const SizedBox(width: 12.0),
                            const Text('Deletar evento'),
                          ],
                        ),
                        onPressed: () async {
                          switch (await showDialog(
                            context: context,
                            builder: (context) {
                              return SimpleDialog(
                                children: <Widget>[
                                  Center(
                                      child: Text(
                                          'Você tem certeza? (Não há volta)')),
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
                              QuerySnapshot presences = await _db
                                  .collection('presences')
                                  .getDocuments();
                              for (DocumentSnapshot pr in presences.documents) {
                                if (pr['event'] == widget.event.reference) {
                                  _db.runTransaction((transaction) async {
                                    await transaction.delete(pr.reference);
                                  });
                                }
                              }
                              _db.runTransaction(
                                (transaction) async {
                                  await transaction
                                      .delete(widget.event.reference);
                                },
                              );

                              Navigator.pop(context);
                              break;
                            default:
                              break;
                          }
                        },
                      ),
                    );
                  }
                  return SizedBox(height: 8.0);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class AttendanceWidget extends StatelessWidget {
  Future<DocumentSnapshot> getSnapshot(FirebaseUser user) async {
    DocumentSnapshot document =
        await _db.collection("members").document(user.uid).get();
    return document;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FutureBuilder(
          future: _auth.currentUser(),
          builder: (ucontext, usnapshot) {
            if (!usnapshot.hasData) return Container();
            return FutureBuilder(
              future: getSnapshot(usnapshot.data),
              builder: (fabcontext, fabsnapshot) {
                if (!fabsnapshot.hasData) return Container();
                if (fabsnapshot.data["authority"] == 1) {
                  return FloatingActionButton(
                    child: Icon(Icons.add),
                    onPressed: () {
                      Navigator.of(fabcontext).push(MaterialPageRoute(
                          builder: (fabcontext) => AddEvent()));
                    },
                  );
                }
                return Container();
              },
            );
          }),
      body: StreamBuilder(
        stream: _db.collection('events').orderBy('from').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Container();

          double initIndex = -2.0;
          DateTime now = DateTime.now();
          for (int i = 0;
              i < snapshot.data.documents.length && initIndex == -2.0;
              i++) {
            if (snapshot.data.documents[i]['from'].isAfter(now)) {
              initIndex = i - 1.0;
            }
          }

          if (initIndex == -1.0)
            initIndex = 0.0;
          else if (initIndex == -2.0)
            initIndex = snapshot.data.documents.length - 1.0;

          ScrollController _listController = ScrollController(
            initialScrollOffset: initIndex * 90,
            keepScrollOffset: false,
          );

          return ListView.builder(
            controller: _listController,
            physics: BouncingScrollPhysics(),
            itemCount: snapshot.data.documents.length,
            itemBuilder: (context, index) {
              return _buildListItem(context, snapshot.data.documents[index]);
            },
          );
        },
      ),
    );
  }
}

class AddEvent extends StatefulWidget {
  static const String routeName = '/material/date-and-time-pickers';

  @override
  _AddEvent createState() => _AddEvent();
}

class _AddEvent extends State<AddEvent> {
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();
  TimeOfDay _fromTime = const TimeOfDay(hour: 19, minute: 00);
  TimeOfDay _toTime = const TimeOfDay(hour: 19, minute: 00);
  bool _haspresence = false;
  bool _mandatory = false;
  final _nameController = TextEditingController();
  final _timesController = TextEditingController(text: '1');
  final _descController = TextEditingController();
  CollectionReference get events => _db.collection('events');
  CollectionReference get members => _db.collection('members');
  CollectionReference get presences => _db.collection('presences');

  Future<DocumentReference> _addEvent(
    DateTime from,
    DateTime to,
    String name,
    String description,
    bool haspresence,
    bool mandatory,
  ) async {
    final DocumentReference document = events.document();
    document.setData(<String, dynamic>{
      'from': from,
      'to': to,
      'name': name,
      'description': description,
      'haspresence': haspresence,
      'mandatory': mandatory,
    });

    return document;
  }

  Future<Null> _addPresence(
      DocumentReference event, DocumentReference member, bool went) async {
    final DocumentReference document = presences.document();
    document.setData(<String, dynamic>{
      'event': event,
      'member': member,
      'went': went,
    });
  }

  Future<Null> _addPresences(DocumentReference event) async {
    try {
      QuerySnapshot documents = await members.getDocuments();
      for (DocumentSnapshot document in documents.documents) {
        _addPresence(event, document.reference, false);
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _timesController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar evento'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          DateTimePicker(
            labelTextDate: 'De',
            selectedDate: _fromDate,
            selectedTime: _fromTime,
            selectDate: (DateTime date) {
              DateTime from = DateTime(date.year, date.month, date.day,
                  _fromTime.hour, _fromTime.minute);
              DateTime to = DateTime(_toDate.year, _toDate.month, _toDate.day,
                  _toTime.hour, _toTime.minute);

              if (from.isAfter(to)) {
                _toDate = date;
              }

              setState(() {
                _fromDate = date;
              });
            },
            selectTime: (TimeOfDay time) {
              DateTime from = DateTime(_fromDate.year, _fromDate.month,
                  _fromDate.day, time.hour, time.minute);
              DateTime to = DateTime(_toDate.year, _toDate.month, _toDate.day,
                  _toTime.hour, _toTime.minute);

              if (from.isAfter(to)) {
                _toTime = time;
              }

              setState(() {
                _fromTime = time;
              });
            },
          ),
          const SizedBox(height: 12.0),
          DateTimePicker(
            labelTextDate: 'Até',
            selectedDate: _toDate,
            selectedTime: _toTime,
            selectDate: (DateTime date) {
              DateTime from = DateTime(_fromDate.year, _fromDate.month,
                  _fromDate.day, _fromTime.hour, _fromTime.minute);
              DateTime to = DateTime(date.year, date.month, date.day,
                  _toTime.hour, _toTime.minute);

              if (from.isAfter(to)) {
                _fromDate = date;
              }

              setState(() {
                _toDate = date;
              });
            },
            selectTime: (TimeOfDay time) {
              DateTime from = DateTime(_fromDate.year, _fromDate.month,
                  _fromDate.day, _fromTime.hour, _fromTime.minute);
              DateTime to = DateTime(_toDate.year, _toDate.month, _toDate.day,
                  time.hour, time.minute);

              if (from.isAfter(to)) {
                _fromTime = time;
              }

              setState(() {
                _toTime = time;
              });
            },
          ),
          const SizedBox(height: 12.0),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nome',
            ),
          ),
          const SizedBox(height: 12.0),
          TextField(
            keyboardType: TextInputType.multiline,
            controller: _descController,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Descrição do evento',
            ),
          ),
          const SizedBox(height: 12.0),
          TextField(
            controller: _timesController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Repete quantas semanas',
            ),
          ),
          const SizedBox(height: 12.0),
          SwitchListTile(
            title: const Text('Tem presença'),
            value: _haspresence,
            onChanged: (bool value) {
              setState(() {
                _haspresence = value;
              });
            },
          ),
          const SizedBox(height: 12.0),
          SwitchListTile(
            title: const Text('Obrigatório'),
            value: _mandatory,
            onChanged: (bool value) {
              setState(() {
                _mandatory = value;
              });
            },
          ),
          const SizedBox(height: 12.0),
          RaisedButton(
            child: const Text('Adicionar evento'),
            onPressed: () async {
              DateTime from = DateTime(_fromDate.year, _fromDate.month,
                  _fromDate.day, _fromTime.hour, _fromTime.minute);
              DateTime to = DateTime(_toDate.year, _toDate.month, _toDate.day,
                  _toTime.hour, _toTime.minute);

              for (int times = 0;
                  times < int.parse(_timesController.text);
                  times++) {
                if (from.day == to.day &&
                    from.month == to.month &&
                    from.year == to.year) {
                  DocumentReference _event = await _addEvent(
                    from,
                    to,
                    _nameController.text,
                    _descController.text,
                    _haspresence,
                    _mandatory,
                  );

                  if (_haspresence) _addPresences(_event);
                } else {
                  DocumentReference _event = await _addEvent(
                    from,
                    DateTime(_fromDate.year, _fromDate.month, _fromDate.day, 23,
                        59, 59),
                    _nameController.text,
                    _descController.text,
                    _haspresence,
                    _mandatory,
                  );

                  if (_haspresence) _addPresences(_event);

                  for (var i = from.year; i <= to.year; i++) {
                    for (var j = from.month; j <= to.month; j++) {
                      for (var k = from.day + 1; k < to.day; k++) {
                        _event = await _addEvent(
                          DateTime(i, j, k, 0, 0),
                          DateTime(i, j, k, 23, 59, 59),
                          _nameController.text,
                          _descController.text,
                          _haspresence,
                          _mandatory,
                        );

                        if (_haspresence) _addPresences(_event);
                      }
                    }
                  }

                  _event = await _addEvent(
                    DateTime(_toDate.year, _toDate.month, _toDate.day, 0, 0),
                    to,
                    _nameController.text,
                    _descController.text,
                    _haspresence,
                    _mandatory,
                  );

                  if (_haspresence) _addPresences(_event);
                }

                from = from.add(Duration(days: 7));
                to = to.add(Duration(days: 7));
              }

              _nameController.clear();
              _timesController.clear();
              _mandatory = false;
              setState(() {
                _haspresence = false;
              });

              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
