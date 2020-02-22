import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';

void main() => runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    ));

class HomePage extends StatefulWidget {
  @override
  HomePageState createState() {
    return new HomePageState();
  }
}

class HomePageState extends State<HomePage> {
  String result = "Hey There !";
  String imageUrl = "";
  bool isImage = false;
  List<String> emailPhonePurpose;

  doAccept() {
    DateTime now = DateTime.now();
    DocumentReference docRef = Firestore.instance
        .collection('users')
        .document(emailPhonePurpose[0].substring(0, 11))
        .collection("inout_register")
        .document();
    DocumentReference stateRef = Firestore.instance
        .collection('users')
        .document(emailPhonePurpose[0].substring(0, 11));

    Firestore.instance.runTransaction((Transaction tx) async {
      await tx.update(stateRef, {"state": "1"});
      await tx.set(docRef, {
        'approved': false,
        'in_datetime': DateFormat('yyyy-MM-dd-HH:mm:ss').format(now),
        'out_datetime': DateFormat('yyyy-MM-dd-HH:mm:ss').format(now),
        'phone': emailPhonePurpose[1],
        'purpose': emailPhonePurpose[2],
      });
    }).then((rst) {
      print(rst);
      Fluttertoast.showToast(msg: 'Entry Successful');
      setState(() {
        isImage = false;
        imageUrl = "";
        result = "Hey There !";
      });

      return true;
    }).catchError((error) {
      print("$error");
      Fluttertoast.showToast(msg: 'Error: $error');
      return false;
    });
  }

  doReject() {
    setState(() {
      isImage = false;
      imageUrl = "";
      result = "Hey There !";
    });
  }

  Future _scanQR() async {
    try {
      String qrResult = await BarcodeScanner.scan();
      qrResult = "2016ucs0005@iitjammu.ac.in_9825192271_guitar";
      emailPhonePurpose = qrResult.split("_");
      DocumentSnapshot userImgSnap = await Firestore.instance
          .collection("users")
          .document(emailPhonePurpose[0].substring(0, 11))
          .get();
      print(userImgSnap.data);
      setState(() {
        try {
          imageUrl = userImgSnap.data['imgURL'];
          isImage = true;
        } catch (e) {
          print(e);
          return false;
        }
        result = qrResult;
        return true;
      });
    } on PlatformException catch (ex) {
      if (ex.code == BarcodeScanner.CameraAccessDenied) {
        setState(() {
          result = "Camera Permission was denied";
        });
      } else {
        setState(() {
          result = "Unknown Error $ex";
        });
      }
    } on FormatException {
      setState(() {
        result = "you pressed the back button before scanning";
      });
    } catch (ex) {
      setState(() {
        result = "Unknown Error $ex";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("QR Scanner"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          isImage
              ? Image(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.contain,
                )
              : Center(
                  child: Text(
                    result,
                    style: new TextStyle(
                        fontSize: 30.0, fontWeight: FontWeight.bold),
                  ),
                ),
          isImage
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    RaisedButton(
                      onPressed: () {
                        doAccept();
                      },
                      child: Text("ACCEPT"),
                      color: Colors.green,
                    ),
                    RaisedButton(
                      onPressed: () {
                        doReject();
                      },
                      color: Colors.red,
                      child: Text("REJECT"),
                    )
                  ],
                )
              : Text(""),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: Icon(Icons.camera_alt),
        label: Text("Scan"),
        onPressed: _scanQR,
      ),
    );
  }
}
