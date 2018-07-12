import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_fog/tabs/attendance.dart';
import 'package:flutter_fog/tabs/login.dart';
import 'package:flutter_fog/tabs/qrreader.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FoG Member',
      theme: ThemeData(
        primaryColor: Color(0xFF1E2264),
        primaryColorDark: Color(0xFF000039),
        primaryColorLight: Color(0xFF4F4A92),
        accentColor: Color(0xFFF1CD36),
        backgroundColor: Color(0xFFB8B8B8),
      ),
      home: MyHomePage(title: 'FoG'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<Tab> myTabs = <Tab>[
    Tab(
      text: "Attendance",
    ),
    Tab(
      text: "Add Event",
    ),
    Tab(
      text: 'QR Reader',
    ),
    Tab(
      text: "Log In",
    ),
  ];

  static Future<List<Widget>> userTabsContent = Future(
    () => <Widget>[
      AttendanceWidget(),
      QRReader(),
      LoginWidget(),
    ]
  );

  static Future<List<Widget>> adminTabsContent = Future(
    () =>  <Widget>[
      AddAttendance(),
    ],
  );

  Future<List<Widget>> currentTabsContent = userTabsContent;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: myTabs.length,
      child: Scaffold(
        appBar: AppBar(
          bottom: TabBar(
            tabs: myTabs,
          ),
          title: Text(widget.title),
        ),
        body: FutureBuilder<List>(
          future: currentTabsContent,
          builder: (BuildContext context, AsyncSnapshot<List> snapshot) {
            return(snapshot.data == null ? snapshot.data : Future(()=>Widget));
          },
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                child: Text("Menu"),
                decoration: BoxDecoration(
                  color: Color(0xFF1E2264),
                ),
              ),
              ListTile(
                title: Text("Área Principal"),
                onTap: () {
                  setState(() {
                    currentTabsContent = userTabsContent;
                  });
                  Navigator.pop(context);  
                },
              ),
              ListTile(
                title: Text("Ademir"),
                onTap: () {
                  setState(() {
                    currentTabsContent = adminTabsContent;
                  });
                  Navigator.pop(context);  
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
