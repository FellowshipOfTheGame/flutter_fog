import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final Firestore _db = Firestore.instance;

class ShowMemberDetails extends StatelessWidget {
  const ShowMemberDetails(this.member, {Key key}) : super(key: key);

  final DocumentSnapshot member;

  Future<List<int>> _getMissingCount(List<DocumentSnapshot> presences) async {
    List<int> ret = [0, 0];

    for (DocumentSnapshot presence in presences) {
      if (presence['went'] == false) {
        DocumentSnapshot event = await presence['event'].get();
        if (event['to'].isBefore(DateTime.now())) {
          if (event['mandatory'] == true) {
            ret[0]++;
          } else {
            ret[1]++;
          }
        }
      }
    }

    return ret;
  }

  Future<List<String>> _getProjectsNames(List<dynamic> projects) async {
    List<String> ret = List<String>(projects.length);

    for (int i = 0; i < projects.length; i++) {
      DocumentSnapshot p = await projects[i].get();
      ret[i] = p['name'];
    }

    return ret;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informações de membro'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              child: StreamBuilder(
                stream: _db
                    .collection('presences')
                    .where('member', isEqualTo: member.reference)
                    .snapshots(),
                builder: (pcontext, psnapshot) {
                  if (!psnapshot.hasData) return ListTile();
                  return FutureBuilder(
                    future: _getMissingCount(psnapshot.data.documents),
                    builder: (econtext, esnapshot) {
                      if (!esnapshot.hasData) return ListTile();
                      return Column(
                        children: <Widget>[
                          ListTile(
                            isThreeLine: true,
                            title: Text('Nome: ${member['name']}'),
                            subtitle: FutureBuilder(
                              future: _getProjectsNames(member['projects']),
                              builder: (context, psnapshot) {
                                if (!psnapshot.hasData) return Container();

                                String projects = psnapshot.data.join(', ');

                                return Text(
                                    'Email: ${member['email']}\nProjetos: $projects');
                              },
                            ),
                            leading: FutureBuilder(
                              future: _auth.currentUser(),
                              builder: (context, usnapshot) {
                                if (!usnapshot.hasData) return Container();
                                if (member['photo'] != null) {
                                  return CircleAvatar(
                                    radius: 32.0,
                                    child: Image.network(member['photo']),
                                  );
                                } else {
                                  return CircleAvatar(
                                      backgroundColor: Colors.white70,
                                      child: Icon(
                                        Icons.account_circle,
                                        size: 32.0,
                                      ));
                                }
                              },
                            ),
                          ),
                          Divider(),
                          ListTile(
                            title: Text(
                                'Eventos obrigatórios que faltou ${esnapshot.data[0]}'),
                            subtitle: Text(
                                'Eventos normais que faltou ${esnapshot.data[1]}'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
          Divider(),
          StreamBuilder(
            stream: _db
                .collection('workedhours')
                .where('member', isEqualTo: member.documentID)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return Center(child: CircularProgressIndicator());

              if (snapshot.data.documents.length <= 0)
                return Center(
                  child: const Text('Nenhuma atividade para mostrar'),
                );

              List<Widget> explist = List<Widget>();
              for (DocumentSnapshot document in snapshot.data.documents) {
                explist.add(
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                      child: ExpansionTile(
                        title: FutureBuilder(
                          future: document['project'].get(),
                          builder: (_, psnapshot) {
                            if (!psnapshot.hasData) return Container();
                            return Column(
                              children: <Widget>[
                                Text('Projeto: ${psnapshot.data['name']}'),
                                Text(
                                    'Trabalhou: ${document['hours']}:${document['minutes']}'),
                              ],
                            );
                          },
                        ),
                        children: <Widget>[
                          Text(
                              'Porcentagem da tarefa cumprida: ${document['tfinished']}%'),
                          Divider(),
                          Text(
                              'Estimo de tempo necessário para desenvolver a tarefa: ${document['estimate']}'),
                          Divider(),
                          document['textra']
                              ? const Text(
                                  'Foram feitas atividades além da tarefa: Sim')
                              : const Text(
                                  'Foram feitas atividades além da tarefa: Não'),
                          Divider(),
                          Text(
                              'Atividades da  tarefa que não foram desenvolvidas: ${document['notdone']}'),
                          const SizedBox(height: 8.0),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(8.0),
                  children: explist,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class MembersWidget extends StatefulWidget {
  @override
  _MembersWidgetState createState() => _MembersWidgetState();
}

class _MembersWidgetState extends State<MembersWidget> {
  final _searchController = TextEditingController();

  Widget _buildListItem(BuildContext context, DocumentSnapshot document) {
    return Card(
      child: ListTile(
        title: Text(document['name']),
        onTap: () async {
          await Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => ShowMemberDetails(document)));
        },
      ),
    );
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
          stream: _db.collection('members').orderBy('name').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return LinearProgressIndicator();

            List<DocumentSnapshot> _members = List<DocumentSnapshot>();
            for (DocumentSnapshot member in snapshot.data.documents) {
              bool inside = false;
              for (String name in member['name'].split(' ')) {
                if (!inside &&
                    name
                        .toLowerCase()
                        .startsWith(_searchController.text.toLowerCase())) {
                  _members.add(member);
                  inside = true;
                }
              }
            }

            return Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                itemCount: _members.length,
                itemBuilder: (context, index) =>
                    _buildListItem(context, _members[index]),
              ),
            );
          },
        ),
      ],
    );
  }
}
