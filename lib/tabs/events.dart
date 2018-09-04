import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fog_members/extra/inputs.dart';
import 'package:intl/intl.dart';
import 'package:qr_reader/qr_reader.dart';

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
  if (!document['haspresence']) {
    return Card(
      child: ListTile(
        title: Text(document['name']),
        subtitle: Text(
          formatTime(document['from'], document['to']),
        ),
      ),
    );
  } else {
    return FutureBuilder(
      future: _auth.currentUser(),
      builder: (ucontext, usnapshot) {
        if (!usnapshot.hasData) return Container();
        DocumentReference _ref =
            _db.collection("members").document(usnapshot.data.uid);
        return StreamBuilder(
          stream: _db
              .collection("presences")
              .where("event", isEqualTo: document.reference)
              .where("member", isEqualTo: _ref)
              .snapshots(),
          builder: (pcontext, psnapshot) {
            if (!psnapshot.hasData) return Container();
            if (psnapshot.data.documents.length == 0)
              return Card(
                color: Colors.red,
                child: ListTile(
                  title: Text(document['name']),
                  subtitle: Text(formatTime(document['from'], document['to'])),
                ),
              );
            return FlatButton(
              padding: EdgeInsets.zero,
              onPressed: () async {
                String barcode = await QRCodeReader()
                    .setAutoFocusIntervalInMs(200)
                    .setForceAutoFocus(true)
                    .setTorchEnabled(true)
                    .setHandlePermissions(true)
                    .setExecuteAfterPermissionGranted(true)
                    .scan();
                if (barcode == document.documentID &&
                    (psnapshot.data.documents[0]['went'] == null ||
                        !psnapshot.data.documents[0]['went'])) {
                  Firestore.instance.runTransaction((transaction) async {
                    DocumentSnapshot meeting =
                        await transaction.get(psnapshot.data.reference);
                    await transaction.update(meeting.reference, {'went': true});
                  });
                }
              },
              child: Card(
                color: psnapshot.data.documents[0]['went']
                    ? Colors.green
                    : Colors.red,
                child: ListTile(
                  title: Text(document['name']),
                  subtitle: Text(
                    formatTime(document['from'], document['to']),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
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
        stream: _db.collection("events").orderBy("from").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Container();
          return ListView.builder(
            itemCount: snapshot.data.documents.length,
            itemBuilder: (context, index) =>
                _buildListItem(context, snapshot.data.documents[index]),
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
  bool myvalue = false;
  final _nameController = TextEditingController();
  CollectionReference get events => _db.collection('events');
  CollectionReference get members => _db.collection('members');
  CollectionReference get presences => _db.collection('presences');

  Future<DocumentReference> _addEvent(
      DateTime from, DateTime to, String name, bool haspresence) async {
    final DocumentReference document = events.document();
    document.setData(<String, dynamic>{
      'from': from,
      'to': to,
      'name': name,
      'haspresence': haspresence,
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Event"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          DateTimePickerFormField(
            format: DateFormat("EEEE, MMMM d, yyyy 'at' h:mma"),
          ),
          DateTimePicker(
            labelTextDate: 'From',
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
            labelTextDate: 'To',
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
              labelText: 'Name',
            ),
          ),
          const SizedBox(height: 12.0),
          SwitchListTile(
            title: Text('Has presence'),
            value: myvalue,
            onChanged: (bool value) {
              setState(() {
                myvalue = value;
              });
            },
          ),
          const SizedBox(height: 12.0),
          RaisedButton(
            child: Text("Add event"),
            onPressed: () async {
              DateTime from = DateTime(_fromDate.year, _fromDate.month,
                  _fromDate.day, _fromTime.hour, _fromTime.minute);
              DateTime to = DateTime(_toDate.year, _toDate.month, _toDate.day,
                  _toTime.hour, _toTime.minute);

              if (from.day == to.day &&
                  from.month == to.month &&
                  from.year == to.year) {
                DocumentReference _event =
                    await _addEvent(from, to, _nameController.text, myvalue);

                if (myvalue) _addPresences(_event);
              } else {
                DocumentReference _event = await _addEvent(
                    from,
                    DateTime(_fromDate.year, _fromDate.month, _fromDate.day, 23,
                        59, 59),
                    _nameController.text,
                    myvalue);

                if (myvalue) _addPresences(_event);

                for (var i = from.year; i <= to.year; i++) {
                  for (var j = from.month; j <= to.month; j++) {
                    for (var k = from.day + 1; k < to.day; k++) {
                      _event = await _addEvent(
                          DateTime(i, j, k, 0, 0),
                          DateTime(i, j, k, 23, 59, 59),
                          _nameController.text,
                          myvalue);

                      if (myvalue) _addPresences(_event);
                    }
                  }
                }

                _event = await _addEvent(
                    DateTime(_toDate.year, _toDate.month, _toDate.day, 0, 0),
                    to,
                    _nameController.text,
                    myvalue);

                if (myvalue) _addPresences(_event);
              }

              _nameController.clear();
              setState(() {
                myvalue = false;
              });

              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
