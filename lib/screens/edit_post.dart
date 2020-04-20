import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:find_my_pet/screens/home.dart';
import 'package:find_my_pet/widgets/custom_image.dart';
import 'package:find_my_pet/widgets/progress.dart';

//Class the build and display edit screen
class EditPost extends StatefulWidget {
  final String imageUrl;
  final String postId;
  final String description;
  final String title;

  EditPost({this.imageUrl, this.postId, this.description, this.title});

  @override
  _EditPostState createState() => _EditPostState();
}

class _EditPostState extends State<EditPost> {
  TextEditingController titleController = TextEditingController();
  TextEditingController descController = TextEditingController();
  bool isUploading = false;

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  //Initialise page with title and description already filled with users previous data
  @override
  void initState() {
    super.initState();
    titleController.text = widget.title;
    descController.text = widget.description;
  }

  //Function to handle when the data is submitted
  handleSubmit(String postId) async {
    //Loading set to true while uploading to display loading spinner
    setState(() {
      isUploading = true;
    });
    //Update existing data with new data
    postsRef.document(postId).updateData(
        {"title": titleController.text, 'description': descController.text});

    setState(() {
      isUploading = false;
    });

    //Close keyboard on screen
    FocusScope.of(context).unfocus();

    //Display notification on the bottom of the screen
    SnackBar snackbar = SnackBar(
      content: Text('Post Updated!'),
    );
    _scaffoldKey.currentState.showSnackBar(snackbar);
    Timer(Duration(seconds: 1), () {
      //Then will return to previous screen
      Navigator.pop(context);
      titleController.clear();
      descController.clear();
    });
  }

  //Display the screen, form and buttons
  @override
  Widget build(BuildContext context) {
    final inputWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.white70,
        leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop()),
        title: Text(
          "Edit Post",
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          FlatButton(
            //If uploading user cant press post again
            onPressed: isUploading ? null : () => {handleSubmit(widget.postId)},
            child: Text(
              "Update",
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
        child: ListView(
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
                    child: Container(
                      height: MediaQuery.of(context).size.hashCode * .2,
                      width: double.infinity,
                      child: cachedNetworkImage(context, widget.imageUrl),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 10.0),
            ),
            //Show the users photo
            ListTile(
              leading: CircleAvatar(
                backgroundImage:
                    CachedNetworkImageProvider(currentUser.photoUrl),
              ),
              title: Container(
                width: inputWidth,
                child: TextField(
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
                child: TextField(
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
          ],
        ),
      ),
    );
  }
}
