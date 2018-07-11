import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fog/signup.dart';
import 'package:flutter_fog/tabs/attendance.dart';
import 'package:flutter_fog/tabs/qrreader.dart';
import 'package:google_sign_in/google_sign_in.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: <String>[
    'email',
  ],
);

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
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  Future<FirebaseUser> _user = _auth.currentUser();

  final List<Tab> _tabs = <Tab>[
    Tab(
      text: "Attendance",
    ),
    Tab(
      text: "Add Event",
    ),
    Tab(
      text: 'QR Reader',
    ),
  ];

  final List<Widget> _tabsContent = <Widget>[
    AttendanceWidget(),
    AddAttendance(),
    QRReader(),
  ];

  Future<FirebaseUser> _handleSignIn() async {
    FirebaseUser user;

    final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    user = await _auth.signInWithGoogle(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    assert(user.email != null);
    assert(user.displayName != null);
    assert(!user.isAnonymous);
    assert(await user.getIdToken() != null);

    final FirebaseUser currentUser = await _auth.currentUser();
    assert(user.uid == currentUser.uid);

    return user;
  }

  Future<Null> _handleSignOut() async {
    _googleSignIn.disconnect();
    _auth.signOut();
  }

  void initState() {
    _user = _handleSignOut();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _user,
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
            ),
            body: Padding(
              padding: const EdgeInsets.only(
                  left: 16.0, bottom: 16.0, right: 16.0, top: 32.0),
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'E-mail',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: TextField(
                      controller: _passController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: RaisedButton(
                            onPressed: () {
                              setState(() {
                                _user = _auth.signInWithEmailAndPassword(
                                    email: _emailController.text,
                                    password: _passController.text);
                              });
                            },
                            child: Text('Login'),
                          ),
                        ),
                        RaisedButton(
                          onPressed: () async {
                            FirebaseUser _user2 = await Navigator
                                .of(context)
                                .push(MaterialPageRoute<FirebaseUser>(
                                    builder: (context) => SignUpWidget()));
                            setState(() {
                              _user = Future.value(_user2);
                            });
                          },
                          child: Text('Signup'),
                        ),
                      ],
                    ),
                  ),
                  MaterialButton(
                    child: Text("Login with Google"),
                    onPressed: () => setState(
                          () {
                            _user = _handleSignIn().catchError((e) => print(e));
                          },
                        ),
                  ),
                ],
              ),
            ),
          );
        return DefaultTabController(
          length: _tabs.length,
          child: Scaffold(
            appBar: AppBar(
              bottom: TabBar(
                tabs: _tabs,
              ),
              title: Text(widget.title),
            ),
            body: TabBarView(
              children: _tabsContent,
            ),
          ),
        );
      },
    );
  }
}
