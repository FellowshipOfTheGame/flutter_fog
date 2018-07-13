import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qr_reader/qr_reader.dart';

final _db = Firestore.instance;

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
              "${document['date'].day}/${document['date'].month}",
              style: Theme.of(context).textTheme.subhead,
            ),
            Text(
              weekdayByNumber(document['date'].weekday),
              style: Theme.of(context).textTheme.body1,
            ),
          ],
        ),
      ),
      Expanded(
        flex: 5,
        child: StreamBuilder(
          stream: _db
              .collection("presence")
              .where("event", isEqualTo: document.reference)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return Container();
            else if (snapshot.data.documents.length == 0)
              return Card(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                      title: Center(child: Text(document['name'])),
                    ),
                  ],
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
                print(barcode);
                print(document.documentID);
                print(document.data['went']);
                if (barcode == document.documentID &&
                    (document.data['went'] == null || !document.data['went'])) {
                  Firestore.instance.runTransaction((transaction) async {
                    DocumentSnapshot meeting =
                        await transaction.get(document.reference);
                    await transaction.update(meeting.reference, {'went': true});
                  });
                }
              },
              child: Card(
                color:
                    document.data['went'] == true ? Colors.green : Colors.red,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                      title: Center(child: Text(document['name'])),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      )
    ],
  );
}

class AttendanceWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _db.collection("events").orderBy("date").snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return Center(child: CircularProgressIndicator());
        return ListView.builder(
          itemCount: snapshot.data.documents.length,
          itemBuilder: (context, index) =>
              _buildListItem(context, snapshot.data.documents[index]),
        );
      },
    );
  }
}

class _InputDropdown extends StatelessWidget {
  const _InputDropdown(
      {Key key,
      this.child,
      this.labelText,
      this.valueText,
      this.valueStyle,
      this.onPressed})
      : super(key: key);

  final String labelText;
  final String valueText;
  final TextStyle valueStyle;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(),
        ),
        baseStyle: valueStyle,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(valueText, style: valueStyle),
            Icon(Icons.arrow_drop_down,
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.grey.shade700
                    : Colors.white70),
          ],
        ),
      ),
    );
  }
}

class _DateTimePicker extends StatelessWidget {
  const _DateTimePicker(
      {Key key,
      this.labelTextDate,
      this.labelTextTime,
      this.selectedDate,
      this.selectedTime,
      this.selectDate,
      this.selectTime})
      : super(key: key);

  final String labelTextDate;
  final String labelTextTime;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final ValueChanged<DateTime> selectDate;
  final ValueChanged<TimeOfDay> selectTime;

  Future<Null> _selectDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2015, 8),
        lastDate: DateTime(2101));
    if (picked != null && picked != selectedDate) selectDate(picked);
  }

  Future<Null> _selectTime(BuildContext context) async {
    final TimeOfDay picked =
        await showTimePicker(context: context, initialTime: selectedTime);
    if (picked != null && picked != selectedTime) selectTime(picked);
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle valueStyle = Theme.of(context).textTheme.title;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          flex: 4,
          child: _InputDropdown(
            labelText: labelTextDate,
            valueText:
                "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
            valueStyle: valueStyle,
            onPressed: () {
              _selectDate(context);
            },
          ),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          flex: 3,
          child: _InputDropdown(
            labelText: labelTextTime,
            valueText: selectedTime.format(context),
            valueStyle: valueStyle,
            onPressed: () {
              _selectTime(context);
            },
          ),
        ),
      ],
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
  TimeOfDay _fromTime = const TimeOfDay(hour: 19, minute: 00);
  bool myvalue = false;
  final _nameController = TextEditingController();
  CollectionReference get events => _db.collection('events');
  CollectionReference get members => _db.collection('members');
  CollectionReference get presences => _db.collection('presences');

  Future<DocumentReference> _addEvent(
      DateTime date, String name, bool haspresence) async {
    final DocumentReference document = events.document();
    document.setData(<String, dynamic>{
      'date': date,
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
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: <Widget>[
        _DateTimePicker(
          labelTextDate: 'Date',
          labelTextTime: 'Time',
          selectedDate: _fromDate,
          selectedTime: _fromTime,
          selectDate: (DateTime date) {
            setState(() {
              _fromDate = date;
            });
          },
          selectTime: (TimeOfDay time) {
            setState(() {
              _fromTime = time;
            });
          },
        ),
        const SizedBox(height: 12.0),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
          style: Theme.of(context).textTheme.display1.copyWith(fontSize: 20.0),
        ),
        const SizedBox(height: 12.0),
        CheckboxListTile(
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
            DateTime date = DateTime(_fromDate.year, _fromDate.month,
                _fromDate.day, _fromTime.hour, _fromTime.minute);
            DocumentReference _event =
                await _addEvent(date, _nameController.text, myvalue);
            _nameController.clear();

            print(_event);
            _addPresences(_event);

            setState(() {
              myvalue = false;
            });
          },
        ),
      ],
    );
  }
}
