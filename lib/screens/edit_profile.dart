import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import "package:flutter/material.dart";

import 'package:find_my_pet/models/user.dart';
import 'package:find_my_pet/screens/home.dart';
import 'package:find_my_pet/widgets/progress.dart';

//Class to edit a users profile
class EditProfile extends StatefulWidget {
  final String currentUserId;

  EditProfile({this.currentUserId});

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  //Key created to show notification when profile updated
  TextEditingController displayNameController = TextEditingController();
  bool isLoading = false;
  User user;
  bool _validDisplayName = true;

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  //Calling function to get users data when pages initialises
  @override
  void initState() {
    getUser();
    super.initState();
  }

  //Function to get and store needed infromation
  getUser() async {
    setState(() {
      isLoading = true;
    });
    DocumentSnapshot doc = await usersRef.document(widget.currentUserId).get();
    user = User.fromDocument(doc);
    displayNameController.text = user.displayName;
    setState(() {
      isLoading = false;
    });
  }

  //Function to build form
  Column buildDisplayNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
            padding: EdgeInsets.only(top: 12.0),
            child: Text(
              "Display Name",
              style: TextStyle(color: Colors.grey),
            )),
        TextField(
          controller: displayNameController,
          decoration: InputDecoration(
              hintText: "Update Display Name",
              errorText: _validDisplayName ? null : "Display name too short."),
        )
      ],
    );
  }

  //Function to update the database with new data
  //And notify user when it is done
  updateProfileData() async {
    SnackBar snackbar = SnackBar(
      content: Text("Profile updated!"),
    );

    setState(() {
      displayNameController.text.trim().length < 3 ||
              displayNameController.text.isEmpty
          ? _validDisplayName = false
          : _validDisplayName = true;
    });
    if (_validDisplayName = true) {
      await usersRef
          .document(widget.currentUserId)
          .updateData({"displayName": displayNameController.text.trim()});
    }
    //Close keyboard when done
    FocusScope.of(context).unfocus();
    _scaffoldKey.currentState.showSnackBar(snackbar);

    //Navigate back to previous page
    Timer(Duration(seconds: 2), () {
      Navigator.pop(context);
    });
  }

  //Build overall screen look and layout
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "Edit Profile",
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        actions: <Widget>[
          IconButton(
            //Go back to profile page
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.done,
              size: 30.0,
              color: Colors.green,
            ),
          ),
        ],
      ),
      //If loading show spinner, if not show data
      body: isLoading
          ? circularProgress()
          : ListView(
              children: <Widget>[
                Container(
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(
                          top: 16.0,
                          bottom: 8.0,
                        ),
                        child: CircleAvatar(
                          radius: 50.0,
                          backgroundImage:
                              CachedNetworkImageProvider(user.photoUrl),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          children: <Widget>[
                            buildDisplayNameField(),
                          ],
                        ),
                      ),
                      RaisedButton(
                        onPressed: updateProfileData,
                        child: Text(
                          "Update Profile",
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: FlatButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.cancel, color: Colors.red),
                          label: Text(
                            "Cancel",
                            style: TextStyle(color: Colors.red, fontSize: 20.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
