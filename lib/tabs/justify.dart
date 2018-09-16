import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

final Firestore _db = Firestore.instance;

Widget _buildListItem(BuildContext context, DocumentSnapshot document) {
  return Card(
    key: Key(document.documentID),
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FutureBuilder(
            future: document['presence'].get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return Container();
              return FutureBuilder(
                future: snapshot.data['event'].get(),
                builder: (context, esnapshot) {
                  if (!esnapshot.hasData) return Container();
                  return FutureBuilder(
                      future: snapshot.data['member'].get(),
                      builder: (context, usnapshot) {
                        if (!usnapshot.hasData) return Container();
                        return ListTile(
                          title: Text(
                              'Membro: ${usnapshot.data['name']}\nEvento: ${esnapshot.data['name']}'),
                          subtitle: Text(
                              'De ${esnapshot.data['from']} até ${esnapshot.data['to']}'),
                        );
                      });
                },
              );
            },
          ),
          Divider(),
          Text(document['reason']),
          Divider(),
          ButtonTheme.bar(
            child: ButtonBar(
              alignment: MainAxisAlignment.center,
              children: <Widget>[
                SimpleDialogOption(
                  child: const Text(
                    'Negar',
                    style: TextStyle(color: Colors.red),
                  ),
                  onPressed: () {
                    Firestore.instance.runTransaction(
                      (transaction) async {
                        await transaction.delete(document.reference);
                      },
                    );

                    Scaffold.of(context).showSnackBar(SnackBar(
                      content: Text('Negado com sucesso'),
                    ));
                  },
                ),
                SimpleDialogOption(
                  child: const Text(
                    'Aceitar',
                    style: TextStyle(color: Colors.green),
                  ),
                  onPressed: () async {
                    DocumentSnapshot presence =
                        await document['presence'].get();

                    Firestore.instance.runTransaction(
                      (transaction) async {
                        await transaction
                            .update(presence.reference, {'went': true});
                      },
                    );

                    Firestore.instance.runTransaction(
                      (transaction) async {
                        await transaction.delete(document.reference);
                      },
                    );

                    Scaffold.of(context).showSnackBar(SnackBar(
                      content: Text('Aceito com sucesso'),
                    ));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class JustifyWidget extends StatefulWidget {
  _JustifyWidgetState createState() => _JustifyWidgetState();
}

class _JustifyWidgetState extends State<JustifyWidget> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _db.collection('justifies').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return Center(child: CircularProgressIndicator());
        if (snapshot.data.documents.length <= 0)
          return const Text(
            'Nenhum dado para mostrar',
            textAlign: TextAlign.center,
          );
        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          physics: BouncingScrollPhysics(),
          itemCount: snapshot.data.documents.length,
          itemBuilder: (context, index) {
            return _buildListItem(context, snapshot.data.documents[index]);
          },
        );
      },
    );
  }
}
