import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

final Firestore _db = Firestore.instance;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(member['name']),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              child: StreamBuilder(
                  stream: _db
                      .collection('presences')
                      .where('member', isEqualTo: member.documentID)
                      .snapshots(),
                  builder: (pcontext, psnapshot) {
                    if (!psnapshot.hasData) return ListTile();
                    return FutureBuilder(
                      future: _getMissingCount(psnapshot.data.documents),
                      builder: (econtext, esnapshot) {
                        if (!esnapshot.hasData) return ListTile();
                        return ListTile(
                          title: Text(
                              'Mandatory events missed ${esnapshot.data[0]}'),
                          subtitle:
                              Text('Normal events missed ${esnapshot.data[0]}'),
                        );
                      },
                    );
                  }),
            ),
          ),
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
                    child: Text('No activity to show'),
                  );

                List<ExpansionPanel> explist = List<ExpansionPanel>();
                for (DocumentSnapshot document in snapshot.data.documents) {
                  explist.add(
                    ExpansionPanel(
                      body: Text('Show info about the worked hours'),
                      headerBuilder: (BuildContext context, bool isExpanded) {
                        return Text('Something something worked hours');
                      },
                    ),
                  );
                }

                return Expanded(
                  child: ExpansionPanelList(
                    children: explist,
                  ),
                );
              }),
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
              labelText: 'Search Name',
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
              if (member['name']
                  .toLowerCase()
                  .startsWith(_searchController.text.toLowerCase())) {
                _members.add(member);
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
