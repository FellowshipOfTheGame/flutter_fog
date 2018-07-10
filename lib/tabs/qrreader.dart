import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_reader/qr_reader.dart';

class QRReader extends StatefulWidget {
  QRReader({Key key}) : super(key: key);

  @override
  _QRReaderState createState() => _QRReaderState();
}

class _QRReaderState extends State<QRReader> {
  Future<String> _barcodeString;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
          child: FutureBuilder<String>(
            future: _barcodeString,
            builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
              return Text(snapshot.data != null ? snapshot.data : "");
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            setState(() {
              _barcodeString = QRCodeReader()
              .setAutoFocusIntervalInMs(200)
              .setForceAutoFocus(true)
              .setTorchEnabled(true)
              .setHandlePermissions(true)
              .setExecuteAfterPermissionGranted(true)
              .scan();
            });
          },
          child: new Icon(Icons.add_a_photo),
        ),
    );
  }
}

