import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class QRGenerator extends StatelessWidget {
  QRGenerator({
    @required this.document,
  });

  final DocumentSnapshot document;

  @override
  Widget build(BuildContext context) {
    return Container(
        child: _buildQRCode(context, document),
    );
  }
}

Widget _buildQRCode(BuildContext context, DocumentSnapshot document) {
  print(document.documentID);
  return Container(
      color: Colors.white,
      child: Center(
        child: StreamBuilder(
          stream: Firestore.instance
              .collection("presence")
              .where("event", isEqualTo: document.reference)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }
            return QrImage(
              data: document.documentID,
              size: 250.0,
            );
          }
        ),
      ),
  );
}