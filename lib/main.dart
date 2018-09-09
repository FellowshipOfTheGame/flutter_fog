import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fog_members/signup.dart';
import 'package:fog_members/tabs/events.dart';
import 'package:fog_members/tabs/members.dart';
import 'package:fog_members/tabs/projects.dart';
import 'package:fog_members/tabs/worked.dart';
import 'package:google_sign_in/google_sign_in.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final Firestore _db = Firestore.instance;
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
        ),
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
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(0.0)),
          ),
        ),
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
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  Future<FirebaseUser> _user = _auth.currentUser();
  Future<bool> _loading = Future.value(false);
  CollectionReference get members => _db.collection('members');

  static List<Tab> _userTabs = <Tab>[
    Tab(
      text: "Callendar",
    ),
    Tab(
      text: 'Work',
    ),
  ];

  static List<Tab> _adminTabs = <Tab>[
    Tab(
      text: "Projects",
    ),
    Tab(
      text: "Members",
    ),
  ];

  List<Tab> _currentTabs = _userTabs;

  static List<Widget> _userTabsContent = <Widget>[
    AttendanceWidget(),
    AddWork(),
  ];

  static List<Widget> _adminTabsContent = <Widget>[
    ProjectsWidget(),
    MembersWidget(),
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

  Widget loading(bool value) {
    if (value) {
      return Center(child: CircularProgressIndicator());
    } else {
      return Container();
    }
  }

  Future<DocumentSnapshot> getSnapshot(FirebaseUser user) async {
    DocumentSnapshot document = await members.document(user.uid).get();
    return document;
  }

  Future<Null> _addMember(FirebaseUser user) async {
    final DocumentReference document = members.document(user.uid);
    document.setData(<String, dynamic>{
      'name': user.displayName,
      'authority': 0,
      'projects': [],
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
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
            body: FutureBuilder(
              future: _loading,
              builder: (lcontext, lsnapshot) {
                if (!lsnapshot.hasData)
                  return Center(child: CircularProgressIndicator());
                return Stack(
                  children: <Widget>[
                    Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.only(
                            left: 16.0, bottom: 16.0, right: 16.0, top: 32.0),
                        children: <Widget>[
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                            ),
                            validator: (value) {
                              if (value.isEmpty) return 'Email is empty';
                              if (value.contains(' ') ||
                                  !value.contains(RegExp(r'^[^@]+@[^.]+\..+$')))
                                return 'Invalid email';
                            },
                          ),
                          const SizedBox(height: 12.0),
                          TextFormField(
                            controller: _passController,
                            decoration: InputDecoration(
                              labelText: 'Password',
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value.isEmpty) return 'Password is empty';
                            },
                          ),
                          const SizedBox(height: 16.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              Expanded(
                                child: RaisedButton(
                                  child: Text('Login'),
                                  onPressed: () async {
                                    if (_formKey.currentState.validate() &&
                                        !lsnapshot.data) {
                                      setState(() {
                                        _loading = Future.value(true);
                                      });

                                      try {
                                        FirebaseUser user = await _auth
                                            .signInWithEmailAndPassword(
                                                email: _emailController.text,
                                                password: _passController.text);
                                        _emailController.clear();
                                        _passController.clear();

                                        _user = Future.value(user);
                                      } catch (e) {
                                        print(e.message);
                                        if (e.message ==
                                                'There is no user record corresponding to this identifier. The user may have been deleted.' ||
                                            e.message ==
                                                'The password is invalid or the user does not have a password.') {
                                          Scaffold.of(lcontext)
                                              .showSnackBar(SnackBar(
                                            content:
                                                Text('Invalid email/password'),
                                          ));
                                          _passController.clear();
                                        }
                                      }

                                      setState(() {
                                        _loading = Future.value(false);
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12.0),
                              Expanded(
                                child: RaisedButton(
                                  child: Text('Signup'),
                                  onPressed: () async {
                                    if (!lsnapshot.data) {
                                      _passController.clear();
                                      _emailController.clear();

                                      FirebaseUser _user2 =
                                          await Navigator.of(context).push(
                                              MaterialPageRoute<FirebaseUser>(
                                                  builder: (context) =>
                                                      SignUpWidget()));
                                      setState(() {
                                        _user = Future.value(_user2);
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16.0),
                          RaisedButton(
                            color: Colors.white,
                            shape: Border(),
                            elevation: 1.0,
                            child: GoogleButton(),
                            onPressed: () async {
                              if (!lsnapshot.data) {
                                setState(() {
                                  _loading = Future.value(true);
                                });

                                try {
                                  FirebaseUser user = await _handleSignIn();

                                  DocumentSnapshot user2 =
                                      await getSnapshot(user);
                                  if (user2.data == null) _addMember(user);

                                  _emailController.clear();
                                  _passController.clear();

                                  _user = Future.value(user);
                                } catch (e) {
                                  print(e);
                                }

                                setState(() {
                                  _loading = Future.value(false);
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    loading(lsnapshot.data),
                  ],
                );
              },
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
            body: TabBarView(
              children: _currentTabsContent,
            ),
            drawer: Drawer(
              child: ListView(
                children: <Widget>[
                  DrawerHeader(
                    child: Text("Menu"),
                    decoration: BoxDecoration(
                      color: Color(0xFF1E2264),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListTile(
                      title: Text("Área Principal"),
                      onTap: () {
                        setState(() {
                          _currentTabsContent = _userTabsContent;
                          _currentTabs = _userTabs;
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  FutureBuilder(
                    future: getSnapshot(snapshot.data),
                    builder: (ucontext, usnapshot) {
                      if (!usnapshot.hasData) return Container();
                      if (usnapshot.data["authority"] == 1) {
                        return Padding(
                          padding: const EdgeInsets.only(
                            left: 8.0,
                            right: 8.0,
                            bottom: 8.0,
                          ),
                          child: ListTile(
                            title: Text("Ademir"),
                            onTap: () {
                              setState(() {
                                _currentTabsContent = _adminTabsContent;
                                _currentTabs = _adminTabs;
                              });
                              Navigator.pop(context);
                            },
                          ),
                        );
                      }
                      return Container();
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 8.0,
                      right: 8.0,
                      top: 4.0,
                    ),
                    child: ListTile(
                      title: Text("Logout"),
                      onTap: () {
                        setState(() {
                          _user = _handleSignOut();
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
