import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:nice_button/NiceButton.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as Img;
import 'package:uuid/uuid.dart';

import 'package:find_my_pet/screens/home.dart';
import 'package:find_my_pet/widgets/progress.dart';
import 'package:find_my_pet/models/user.dart';

//Create upload form and logic
class Upload extends StatefulWidget {
  final User currentUser;

  Upload({this.currentUser});

  @override
  _UploadState createState() => _UploadState();
}

//AutomaticKeepAliveClientMixin to keep page state if user navigates to new page
class _UploadState extends State<Upload>
    with AutomaticKeepAliveClientMixin<Upload> {
  //Text controllers to store from inputs
  TextEditingController titleController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController descController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  ScrollController _controller =
      ScrollController(); //Scroll controller to move to top of page when form is submitted

  //Location variables
  Geoflutterfire geo = Geoflutterfire();
  GeoFirePoint myLoc;
  DateTime _selectDate = DateTime.now();
  bool _selectIsFound = false;
  String _petStatus;
  bool isUploading = false;
  File file; //Stores user image
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  //Auto generate unique id
  String postId = Uuid().v4();
  final _form = GlobalKey<FormState>();

  //Store the photo the user takes
  handleTakePhoto() async {
    Navigator.pop(context);
    File file = await ImagePicker.pickImage(
      source: ImageSource.camera,
      maxHeight: 675,
      maxWidth: 960,
    );
    setState(() {
      this.file = file;
    });
  }

  //Stores the image the user chooses from gallery
  handleChooseFromGallery() async {
    Navigator.pop(context);
    File file = await ImagePicker.pickImage(source: ImageSource.gallery);
    setState(() {
      this.file = file;
    });
  }

  //Dialog to display users options for choosing a photo
  selectImage(parentContext) {
    return showDialog(
      context: parentContext,
      builder: (context) {
        return SimpleDialog(
          title: Center(child: Text("Choose a photo of the pet.")),
          titlePadding: EdgeInsets.only(top: 8, bottom: 8),
          children: <Widget>[
            SimpleDialogOption(
                child: Text("Photo with Camera"), onPressed: handleTakePhoto),
            SimpleDialogOption(
                child: Text("Image from Gallery"),
                onPressed: handleChooseFromGallery),
            SimpleDialogOption(
              child: Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            )
          ],
        );
      },
    );
  }

  //Dispalys the initial screen which presents the user with post types
  //Lost, found or spotted a pet. Also a description for each type
  Container buildSplashScreen() {
    var firstColor = Theme.of(context).primaryColor,
        secondColor = Theme.of(context).accentColor;
    return Container(
      color: Theme.of(context).accentColor.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Column(
            children: <Widget>[
              NiceButton(
                elevation: 7,
                radius: 40,
                padding: const EdgeInsets.all(15),
                text: "Missing Pet",
                gradientColors: [secondColor, firstColor],
                onPressed: () {
                  setState(() {
                    _petStatus = 'lost';
                    selectImage(context);
                  });
                },
                background: null,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Container(
                  width: MediaQuery.of(context).size.width * .5,
                  child: RichText(
                    textAlign: TextAlign.center,
                    textWidthBasis: TextWidthBasis.parent,
                    text: TextSpan(
                        text: 'If you have lost your pet.',
                        style: TextStyle(
                          color: firstColor,
                          fontWeight: FontWeight.bold,
                        )),
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              NiceButton(
                elevation: 7,
                radius: 40,
                padding: const EdgeInsets.all(15),
                text: "Found Pet",
                gradientColors: [secondColor, firstColor],
                onPressed: () {
                  setState(() {
                    _petStatus = 'found';
                    selectImage(context);
                  });
                },
                background: null,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Container(
                  width: MediaQuery.of(context).size.width * .5,
                  child: RichText(
                    textAlign: TextAlign.center,
                    textWidthBasis: TextWidthBasis.parent,
                    maxLines: 2,
                    text: TextSpan(
                        text:
                            'If you have found a pet and are looking for the owner.',
                        style: TextStyle(
                          color: firstColor,
                          fontWeight: FontWeight.bold,
                        )),
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              NiceButton(
                elevation: 7,
                radius: 40,
                padding: const EdgeInsets.all(15),
                text: "Spotted Pet",
                gradientColors: [secondColor, firstColor],
                onPressed: () {
                  setState(() {
                    _petStatus = 'spotted';
                    selectImage(context);
                  });
                },
                background: null,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Container(
                  width: MediaQuery.of(context).size.width * .5,
                  child: RichText(
                    textAlign: TextAlign.center,
                    textWidthBasis: TextWidthBasis.parent,
                    text: TextSpan(
                        text: 'If you spot a lost pet.',
                        style: TextStyle(
                          color: firstColor,
                          fontWeight: FontWeight.bold,
                        )),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  //Clear the image stored
  clearImage() {
    setState(() {
      file = null;
    });
  }

  //Compress the image
  compressImage() async {
    //Path to the temporary directory on the device
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    Img.Image imageFile = Img.decodeImage(file.readAsBytesSync());
    final compressedImageFile = File('$path/img_$postId.jpg')
      ..writeAsBytesSync(Img.encodeJpg(imageFile, quality: 80));
    setState(() {
      file = compressedImageFile;
    });
  }

  //Upload the compressed image to firebase storage and return url
  Future<String> uploadImage(imageFile) async {
    StorageUploadTask uploadImg =
        storageRef.child("post_$postId.jpg").putFile(imageFile);
    //Returns a snapshot containing data
    StorageTaskSnapshot storageSnap = await uploadImg.onComplete;
    String downloadUrl = await storageSnap.ref.getDownloadURL();
    return downloadUrl;
  }

  //Clear all text controllers to prevent memory leak
  clearcontrollers() {
    titleController.clear();
    dateController.clear();
    descController.clear();
    locationController.clear();
  }

  //Create the post in the database
  //Both in post and location collection
  createPostInFirestore(
      {String imageUrl,
      String location,
      String description,
      String title,
      String date}) {
    postsRef.document(postId).setData({
      "postId": postId,
      "ownerId": currentUser.id,
      "username": currentUser.displayName,
      "imageUrl": imageUrl,
      "location": location,
      "locationSearch": location.toLowerCase(),
      "description": description,
      "title": title,
      "date": _selectDate,
      "timestamp": timestamp,
      "isFound": _selectIsFound,
      "position": myLoc.data,
      "petStatus": _petStatus,
    });
    locationsRef.document(postId).setData({
      "postId": postId,
      "location": location,
      "locationSearch": location.toLowerCase(),
      "title": title,
      "timestamp": timestamp,
      "position": myLoc.data,
      "ownerId": currentUser.id,
    });
  }

  //Displays a calendar to the screen to pick a date
  void _presentDatePicker() {
    //context is global in this state class, doesnt need to be passed in
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    ).then((pickedDate) {
      //Means user didnt pick a date
      if (pickedDate == null) {
        return;
      }
      setState(() {
        _selectDate = pickedDate;
      });
    });
  }

  //Carries out the functions when form submitted
  handleSubmit() async {
    //Checks the validity of the form
    final isValid = _form.currentState.validate();
    if (!isValid) {
      return;
    }

    setState(() {
      isUploading = true;
    });
    await compressImage();
    String imageUrl = await uploadImage(file);
    print(_petStatus);
    createPostInFirestore(
      imageUrl: imageUrl,
      location: locationController.text,
      description: descController.text,
      title: titleController.text,
      date: dateController.text,
    );
    clearcontrollers();
    setState(() {
      file = null;
      isUploading = false;
      //Ensure new unique ID for every post
      postId = Uuid().v4();
    });
  }

  //Build the post form
  Scaffold buildForm() {
    //Get screen width
    final inputWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.white70,
        leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: clearImage),
        title: Text(
          "Create Post",
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          FlatButton(
            //If uploading user cant press post again
            onPressed: isUploading
                ? null
                : () => {
                      //When pressed close the keybaord and scroll to top of screen
                      FocusScope.of(context).unfocus(),
                      _controller.jumpTo(_controller.position.minScrollExtent),
                      handleSubmit()
                    },
            child: Text(
              "Post",
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
                fontSize: 20.0,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        width: inputWidth,
        child: Form(
          key: _form,
          child: ListView(
            controller: _controller,
            children: <Widget>[
              isUploading ? linearProgress() : Text(''),
              Container(
                height: 220.0,
                width: inputWidth,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Card(
                      elevation: 1,
                      //Display the users picture
                      child: Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            fit: BoxFit.cover,
                            image: FileImage(file),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 10.0),
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                      CachedNetworkImageProvider(currentUser.photoUrl),
                ),
                title: Container(
                  width: inputWidth,
                  child: TextFormField(
                    validator: (value) {
                      if (value.isEmpty) {
                        return "Please provide a name.";
                      }
                      return null;
                    },
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: "Your pets name...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              Divider(),
              ListTile(
                leading: Icon(
                  Icons.description,
                  color: Colors.orange,
                  size: 35.0,
                ),
                title: Container(
                  width: inputWidth,
                  child: TextFormField(
                    validator: (value) {
                      if (value.isEmpty) {
                        return "Please provide a description.";
                      }
                      return null;
                    },
                    controller: descController,
                    keyboardType: TextInputType.multiline,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Description...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              Divider(),
              ListTile(
                leading: Icon(
                  Icons.date_range,
                  color: Colors.orange,
                  size: 35.0,
                ),
                title: TextFormField(
                  controller: dateController,
                  enabled: false,
                  decoration: InputDecoration(
                    enabled: false,
                    //Display the selected date
                    labelText: '${DateFormat.yMd().format(_selectDate)}',
                    hintText: "What date...",
                    border: InputBorder.none,
                  ),
                ),
                trailing: Container(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 8.0,
                        left: 8.0,
                      ),
                      child: FlatButton(
                          textColor: Theme.of(context).primaryColor,
                          child: Text(
                            'Choose date',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: _presentDatePicker),
                    ),
                  ),
                ),
              ),
              Divider(),
              ListTile(
                leading: Icon(
                  Icons.insert_comment,
                  color: Colors.orange,
                  size: 35.0,
                ),
                title: TextFormField(
                  validator: (value) {
                    if (value.isEmpty) {
                      return "Please provide a location.";
                    }
                    return null;
                  },
                  onTap: () async {
                    //Predict users location as they type
                    Prediction p = await PlacesAutocomplete.show(
                        context: context,
                        apiKey: "AIzaSyCc8pwKufUsqJIht_D4blhyITacJeqqdrk",
                        mode: Mode.overlay, // Mode.fullscreen
                        language: "en-GB",
                        components: [new Component(Component.country, "ie")]);

                    //If they choose one store its coordinates
                    if (p != null) {
                      locationController.text = p.description;

                      List<Placemark> placemarks = await Geolocator()
                          .placemarkFromAddress(locationController.text);
                      Placemark placemark = placemarks[0];
                      setState(() {
                        myLoc = geo.point(
                            latitude: placemark.position.latitude,
                            longitude: placemark.position.longitude);
                      });
                    }
                  },
                  controller: locationController,
                  decoration: InputDecoration(
                    hintText: "Location...",
                    border: InputBorder.none,
                  ),
                ),
              ),
              Container(
                width: 200.0,
                height: 100.0,
                alignment: Alignment.center,
                child: RaisedButton.icon(
                  label: Text(
                    "Use Current Location",
                    style: TextStyle(color: Colors.white),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  color: Colors.blue,
                  onPressed: getUserLocation,
                  icon: Icon(
                    Icons.my_location,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //Get the users current location
  getUserLocation() async {
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemarks = await Geolocator()
        .placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark placemark = placemarks[0];
    setState(() {
      myLoc =
          geo.point(latitude: position.latitude, longitude: position.longitude);
    });

    //All possible locations subtypes
    //'${placemark.subThoroughfare} ${placemark.thoroughfare}, ${placemark.subLocality}, ${placemark.locality}, ${placemark.subAdministrativeArea}, ${placemark.administrativeArea} ${placemark.postalCode}, ${placemark.country},';
    if (position == null) {
      //If gps isnt on notify the user
      SnackBar snackbar = SnackBar(
          content: Text(
        'Make sure location is turned on.',
        overflow: TextOverflow.ellipsis,
      ));
      _scaffoldKey.currentState.showSnackBar(snackbar);
    }
    String formattedAddress =
        "${placemark.locality}, ${placemark.administrativeArea} ";
    locationController.text = formattedAddress;
  }

  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return file == null ? buildSplashScreen() : buildForm();
  }
}
