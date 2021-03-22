import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geocoder/geocoder.dart' as Geo;
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_store/screens/login_screen.dart';
import 'package:image_store/screens/saved_screen.dart';
import 'package:image_store/utilities/constants.dart';
import 'package:location/location.dart';
import 'package:path/path.dart' as p;

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  FocusNode myFocus;
  final picker = ImagePicker();
  File _image;
  String downloadURL;
  TextEditingController captionController = TextEditingController();
  TextEditingController descController = TextEditingController();
  Location location;
  Geoflutterfire geo = Geoflutterfire();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = new GoogleSignIn();
  bool userSignedIn = false;

  @override
  void initState() {
    super.initState();
    Firebase.initializeApp();
  }
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    captionController.dispose();
    descController.dispose();
  }

  void _signOut() {
    googleSignIn.signOut();
    userSignedIn = false;
  }

  Future<User> _signIn() async {
    final GoogleSignInAccount account = await googleSignIn.signIn();
    final GoogleSignInAuthentication authentication =
        await account.authentication;

    final GoogleAuthCredential credential = GoogleAuthProvider.credential(
      idToken: authentication.idToken,
      accessToken: authentication.accessToken,
    );
    final UserCredential authResult =
        await _auth.signInWithCredential(credential);
    final User user = authResult.user;
    return user;
  }

  Future<void> _uploadData(String caption, String desc, String imageURL) async {
    var location = new Location();
    double lat, lon;
    try {
      await location.getLocation().then((onValue) {
        print(onValue.latitude.toString() + "," + onValue.longitude.toString());
        lat = onValue.latitude;
        lon = onValue.longitude;
      });
    } catch (e) {
      print(e);
      if (e.code == 'PERMISSION_DENIED') {
        print('Permission Denied');
      }
    }
    final coordinates = Geo.Coordinates(lat, lon);
    var addresses =
        await Geo.Geocoder.local.findAddressesFromCoordinates(coordinates);
    var first = addresses.first;

    GeoFirePoint point = geo.point(latitude: lat, longitude: lon);

    CollectionReference reference1 =
        FirebaseFirestore.instance.collection('posts');
    await reference1
        .add({
          'caption': caption,
          'description': desc,
          'imageurl': imageURL,
          'location': point.data,
          'city': first.featureName,
        })
        .then((value) => print("Post Added"))
        .catchError((error) => print('Failed to add it.'));
  }

  void _showAlert(context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          actions: [
            TextButton(
                onPressed: () {
                  captionController.text = "";
                  descController.text = "";
                  Navigator.of(context).pop();
                  setState(() {
                    _image = null;
                  });
                },
                child: Text("Okay")),
          ],
          title: new Text("Upload Complete"),
        );
      },
    );
  }

  _uploadImage() async {
    final _storage = FirebaseStorage.instance;
    String caption = captionController.text;
    String desc = descController.text;
    if (_image != null) {
      var snapshot =
          await _storage.ref().child(p.basename(_image.path)).putFile(_image);
      downloadURL = await snapshot.ref.getDownloadURL();
      _uploadData(caption, desc, downloadURL);
      _showAlert(context);
    } else {
      print("Error uploading the image");
    }
  }

  _imageFromGallery() async {
    PickedFile pickedFile = await picker.getImage(source: ImageSource.gallery);
    var image = File(pickedFile.path);
    if (image == null) return null;
    setState(() {
      _image = File(image.path);
    });
    Navigator.pop(context);
  }

  _imageFromCamera() async {
    PickedFile pickedFile = await picker.getImage(source: ImageSource.camera);
    var image = File(pickedFile.path);
    if (image == null) return null;
    setState(() {
      _image = File(image.path);
    });
    Navigator.pop(context);
  }

  void _showDialog(context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(Constants.cancel)),
          ],
          title: new Text(Constants.selectImageFrom),
          content: Container(
            height: 100.0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextButton(
                  child: Text(Constants.imageFromCamera),
                  onPressed: _imageFromCamera,
                ),
                TextButton(
                  child: Text(Constants.imageFromGallery),
                  onPressed: _imageFromGallery,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final node = FocusScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(Constants.imageStore),
        centerTitle: true,

      ),
      extendBody: true,
      body: GestureDetector(
        onTap: () {
          FocusScopeNode currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus &&
              currentFocus.focusedChild != null) {
            FocusManager.instance.primaryFocus.unfocus();
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _image == null
                  ? Container(
                      child: Column(
                        children: [
                          Image.asset(
                            Constants.bannerPath,
                          ),
                          SizedBox(
                            height: 50,
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Container(
                          child: Image.file(_image),
                        ),
                        SizedBox(
                          height: 50,
                        ),
                      ],
                    ),
              TextField(
                decoration: InputDecoration(
                    border: OutlineInputBorder(), labelText: "Caption"),
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => node.nextFocus(),
                controller: captionController,
              ),
              SizedBox(
                height: 20,
              ),
              TextField(
                decoration: InputDecoration(
                    border: OutlineInputBorder(), labelText: "Description"),
                maxLines: 4,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  node.unfocus();
                  _uploadImage();
                },
                controller: descController,
              ),
              SizedBox(
                height: 10.0,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    child: Text("Select Image"),
                    onPressed: () => _showDialog(context),
                  ),
                  ElevatedButton(
                    onPressed: _uploadImage,
                    child: Text("Upload"),
                  ),
                ],
              ),
              SizedBox(
                height: 50,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => SavedScreen()));
        },
        label: const Text(Constants.saved),
        icon: const Icon(Icons.save_outlined),
      ),
    );
  }
}
