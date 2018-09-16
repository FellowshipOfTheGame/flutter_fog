import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

final Firestore _db = Firestore.instance;

class AcceptMember extends StatefulWidget {
  _AcceptMemberState createState() => _AcceptMemberState();
}

class _AcceptMemberState extends State<AcceptMember> {
  Widget _buildListItem(BuildContext context, DocumentSnapshot document) {
    return Card(
      key: Key(document.documentID),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            ListTile(
              title: Text(document['name']),
              subtitle: Text(document['email']),
            ),
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
                      Firestore.instance.runTransaction(
                        (transaction) async {
                          await transaction
                              .update(document.reference, {'authority': 0});
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aceitar membros'),
      ),
      body: StreamBuilder(
        stream: _db.collection('members').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());
          if (snapshot.data.documents.length <= 0)
            return const Text(
              'Nenhum dado para mostrar',
              textAlign: TextAlign.center,
            );

          List<DocumentSnapshot> _memberstoaccept = List<DocumentSnapshot>();
          for (DocumentSnapshot document in snapshot.data.documents) {
            if (document['authority'] < 0) _memberstoaccept.add(document);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            physics: BouncingScrollPhysics(),
            itemCount: _memberstoaccept.length,
            itemBuilder: (context, index) {
              return _buildListItem(context, _memberstoaccept[index]);
            },
          );
        },
      ),
    );
  }
}
