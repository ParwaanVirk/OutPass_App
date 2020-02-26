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
  bool isApproved = false;
  List<String> emailPhonePurposeApproved;

  doAccept(approved) async {
    if (!approved) {
      DateTime now = DateTime.now();
      DocumentSnapshot docSnapdocRef = await Firestore.instance
          .collection("users")
          .document(emailPhonePurposeApproved[0].substring(0, 11))
          .get();
      DocumentReference docRef = Firestore.instance
          .collection('users')
          .document(emailPhonePurposeApproved[0].substring(0, 11))
          .collection("inout_register")
          .document();

      DocumentReference stateRef = Firestore.instance
          .collection('users')
          .document(emailPhonePurposeApproved[0].substring(0, 11));
      DocumentReference stateRef2 = Firestore.instance
          .collection('users_outside')
          .document(emailPhonePurposeApproved[0].substring(0, 11));

      Firestore.instance.runTransaction((Transaction tx) async {
        await tx.update(stateRef, {"state": "2"});
        // await tx.set(stateRef2, {"docRef": docRef.documentID});
        await tx.update(docRef, {
          'approved': true,
          // 'in_datetime': DateFormat('yyyy-MM-dd-HH:mm:ss').format(now),
          'out_datetime': DateFormat('yyyy-MM-dd-HH:mm:ss').format(now),
          // 'phone': emailPhonePurposeApproved[1],
          // 'purpose': emailPhonePurposeApproved[2],
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
    } else {
      DateTime now = DateTime.now();
      DocumentReference outsideDocRef = await Firestore.instance
          .collection("users")
          .document(emailPhonePurposeApproved[0].substring(0, 11))
          .get()
          .then((onValue) {
        DocumentReference docRef = Firestore.instance
            .collection('users')
            .document(emailPhonePurposeApproved[0].substring(0, 11))
            .collection("inout_register")
            .document(onValue.data["docRef"]);
        DocumentReference stateRef = Firestore.instance
            .collection('users')
            .document(emailPhonePurposeApproved[0].substring(0, 11));
        DocumentReference stateRef2 = Firestore.instance
            .collection('users_outside')
            .document(emailPhonePurposeApproved[0].substring(0, 11));

        Firestore.instance.runTransaction((Transaction tx) async {
          await tx.update(stateRef, {"state": "0"});
          await tx.delete(stateRef2);
          await tx.update(docRef, {
            'in_datetime': DateFormat('yyyy-MM-dd-HH:mm:ss').format(now),
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
      });
    }
  }

  doReject(approved) async {
    if (!approved) {
      DocumentSnapshot docsnap = await Firestore.instance
          .collection('users')
          .document(emailPhonePurposeApproved[0].substring(0, 11))
          .get();
      DocumentReference canceling = Firestore.instance
          .collection("users")
          .document(emailPhonePurposeApproved[0].substring(0, 11))
          .collection("inout_register")
          .document(docsnap.data['docRef']);
      DocumentReference docRefdocRef = Firestore.instance
          .collection("users")
          .document(emailPhonePurposeApproved[0].substring(0, 11));
      DocumentSnapshot docSnapdocRef = await Firestore.instance
          .collection("users")
          .document(emailPhonePurposeApproved[0].substring(0, 11))
          .get();
      Map x = docSnapdocRef.data;
      x.remove("docRef");

      // docSnapdocRef.data.remove("docRef");
      x["state"] = "0";
      // print(x);
      Firestore.instance.runTransaction((Transaction tx) async {
        await tx.delete(canceling);
        await tx.set(docRefdocRef, x);
      }).then((rst) {
        setState(() {
          isImage = false;
          imageUrl = "";
          result = "Hey There !";
        });
      }).catchError((error) {
        // _state = MyState.Inside;
        // _isloading = false;
        // notifyListeners();
        print("$error");
        Fluttertoast.showToast(msg: 'Error: $error');
        return false;
      });
    } else {
      setState(() {
        isImage = false;
        imageUrl = "";
        result = "Hey There !";
      });
    }
  }

  Future _scanQR() async {
    try {
      String qrResult = await BarcodeScanner.scan();
      emailPhonePurposeApproved = qrResult.split("_");

      DocumentSnapshot userImgSnap = await Firestore.instance
          .collection("users")
          .document(emailPhonePurposeApproved[0].substring(0, 11))
          .get();
      // print(userImgSnap.data);
      setState(() {
        try {
          imageUrl = userImgSnap.data['imgURL'];
          isImage = true;
          if (emailPhonePurposeApproved[3] == "1") {
            isApproved = true;
          } else {
            isApproved = false;
          }
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
          Container(height: 200, child: ExpenseList()),
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
                        doAccept(isApproved);
                      },
                      child: Text("ACCEPT"),
                      color: Colors.green,
                    ),
                    RaisedButton(
                      onPressed: () {
                        doReject(isApproved);
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

class ExpenseList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new StreamBuilder<QuerySnapshot>(
        stream: Firestore.instance.collection("users_outside").snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) return new Text("Loading");
          return ListView(
            children: getExpenseItems(snapshot),
            itemExtent: 40,
          );
        });
  }

  getExpenseItems(AsyncSnapshot<QuerySnapshot> snapshot) {
    List<DocumentSnapshot> x = snapshot.data.documents;
    x.removeWhere((item) => item.documentID == "null");
    if (x.length != 0) {
      return snapshot.data.documents
          .map((doc) => ListTile(
                title: new Text(doc.documentID),

                // subtitle: new Text(doc.documentID)
              ))
          .toList();
    }
    else{
      return [ListTile(title:Text("No one is outside"))];
    }
  }
}
