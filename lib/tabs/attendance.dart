import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fog/tabs/qrgenerator.dart';

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
          stream: Firestore.instance
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
                    QRGenerator(
                      document: document,
                    ),
                  ],
                ),
              );
            return Card(
              color: snapshot.data.documents[0]['went']
                  ? Colors.green
                  : Colors.red,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ListTile(
                    title: Center(child: Text(document['name'])),
                  ),
                  Text(
                    document.documentID,
                  ),
                  QRGenerator(
                      document: document,
                  ),
                ],
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
      stream:
          Firestore.instance.collection("events").orderBy("date").snapshots(),
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
      this.labelText,
      this.selectedDate,
      this.selectedTime,
      this.selectDate,
      this.selectTime})
      : super(key: key);

  final String labelText;
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
            labelText: labelText,
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

class AddAttendance extends StatefulWidget {
  static const String routeName = '/material/date-and-time-pickers';

  @override
  _AddAttendance createState() => _AddAttendance();
}

class _AddAttendance extends State<AddAttendance> {
  DateTime _fromDate = DateTime.now();
  TimeOfDay _fromTime = const TimeOfDay(hour: 19, minute: 00);
  bool myvalue = false;
  final myController = TextEditingController();
  CollectionReference get meetings => Firestore.instance.collection('meeting');

  Future<Null> _addMeeting(DateTime date, int member, bool went) async {
    final DocumentReference document = meetings.document();
    document.setData(<String, dynamic>{
      'date': date,
      'member': member,
      'went': went,
    });
  }

  @override
  void dispose() {
    myController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Firestore.instance.collection("meeting").snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return Center(child: CircularProgressIndicator());
        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: <Widget>[
            _DateTimePicker(
              labelText: 'From',
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
            TextField(
              controller: myController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Member',
              ),
              style:
                  Theme.of(context).textTheme.display1.copyWith(fontSize: 20.0),
            ),
            CheckboxListTile(
              value: myvalue,
              onChanged: (bool value) {
                setState(() {
                  myvalue = value;
                });
              },
            ),
            Center(
              child: RaisedButton(
                  child: Text("ADD"),
                  onPressed: () {
                    DateTime date = DateTime(_fromDate.year, _fromDate.month,
                        _fromDate.day, _fromTime.hour, _fromTime.minute);
                    _addMeeting(date, int.parse(myController.text), myvalue);
                  }),
            ),
          ],
        );
      },
    );
  }
}
