import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fog/signup.dart';
import 'package:flutter_fog/tabs/attendance.dart';
//import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: <String>[
    'profile',
    'email',
  ],
);

class GoogleButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 11.0, bottom: 11.0, left: 8.0),
          child: Container(
            child: Image.asset('assets/google.png'),
            width: 18.0,
            height: 18.0,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 24.0, right: 8.0),
          child: Text(
            "Sign in with Google",
            style: TextStyle(fontFamily: 'Roboto-Medium', fontSize: 14.0),
          ),
        )
      ],
    );
  }
}

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
        buttonTheme: ButtonThemeData(
          shape: BeveledRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(8.0),
            ),
          ),
        ),
        buttonColor: Color(0xFFF1CD36),
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

  static List<Tab> _userTabs = <Tab>[
    Tab(
      text: "Attendance",
    ),

  ];

  static List<Tab> _adminTabs = <Tab>[
    Tab(
      text: "Add Event",
    ),
  ];

  List<Tab> _currentTabs = _userTabs;

  static List<Widget> _userTabsContent = <Widget>[
      AttendanceWidget(),
  ];


  static List<Widget> _adminTabsContent = <Widget>[
      AddAttendance(),
  ];

List<Widget> _currentTabsContent = _userTabsContent;

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
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        RaisedButton(
                          onPressed: () {
                            setState(() {
                              _user = _auth.signInWithEmailAndPassword(
                                  email: _emailController.text,
                                  password: _passController.text);
                            });
                          },
                          child: Text('Login'),
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
                  RaisedButton(
                    color: Colors.white,
                    shape: Border(),
                    elevation: 1.0,
                    child: GoogleButton(),
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
          length: _currentTabs.length,
          child: Scaffold(
            appBar: AppBar(
              bottom: TabBar(
                tabs: _currentTabs,
              ),
              title: Text(widget.title),
            ),
            body:  Padding(
              padding: const EdgeInsets.only(right: 8.0, left: 8.0),
              child: TabBarView(
                children: _currentTabsContent,
              ),
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
                      _currentTabsContent = _userTabsContent;
                      _currentTabs = _userTabs;
                    });
                    Navigator.pop(context);  
                  },
                ),
                ListTile(
                  title: Text("Ademir"),
                  onTap: () {
                    setState(() {
                      _currentTabsContent = _adminTabsContent;
                      _currentTabs = _adminTabs;
                    });
                    Navigator.pop(context);  
                  },
                ),
              ]
              ),
            ),
          ),
        );
      }
    );
    }
  }