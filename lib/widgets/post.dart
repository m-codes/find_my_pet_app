import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:location/location.dart';
import 'package:intl/intl.dart';

import 'package:find_my_pet/screens/comments.dart';
import 'package:find_my_pet/screens/home.dart';
import 'package:find_my_pet/widgets/custom_image.dart';
import 'package:find_my_pet/widgets/progress.dart';

//Data Model and widget so methods can be applied before passing to state class
class Post extends StatefulWidget {
  final String title;
  final String username;
  final String ownerId;
  final String postId;
  final DateTime date;
  final String description;
  final String location;
  final String imageUrl;
  final bool isFound;
  final Map loc;
  final String petStatus;

  Post({
    this.title,
    this.username,
    this.ownerId,
    this.postId,
    this.date,
    this.description,
    this.location,
    this.imageUrl,
    this.isFound,
    this.loc,
    this.petStatus,
  });

  //factory describes creating an instance from a document
  factory Post.fromDocument(DocumentSnapshot doc) {
    Timestamp dateTimestamp = doc['date'];
    DateTime convertedDate = DateTime.parse(dateTimestamp.toDate().toString());
    return Post(
      title: doc['title'],
      username: doc['username'],
      ownerId: doc['ownerId'],
      postId: doc['postId'],
      date: convertedDate,
      description: doc['description'],
      location: doc['location'],
      imageUrl: doc['imageUrl'],
      isFound: doc['isFound'],
      loc: doc['position'],
      petStatus: doc['petStatus'],
    );
  }
  @override
  _PostState createState() => _PostState(
        title: this.title,
        username: this.username,
        ownerId: this.ownerId,
        postId: this.postId,
        date: this.date,
        description: this.description,
        location: this.location,
        imageUrl: this.imageUrl,
        isFound: this.isFound,
        loc: this.loc,
        petStatus: this.petStatus,
      );
}

class _PostState extends State<Post> {
  final String title;
  final String username;
  final String ownerId;
  final String postId;
  final DateTime date;
  final String description;
  final String location;
  final String imageUrl;
  final bool isFound;
  final Map loc;
  final String petStatus;

  _PostState({
    this.title,
    this.username,
    this.ownerId,
    this.postId,
    this.date,
    this.description,
    this.location,
    this.imageUrl,
    this.isFound,
    this.loc,
    this.petStatus,
  });

  Geoflutterfire geo = Geoflutterfire();
  Location location2 = new Location();

  //Build the posts header
  buildPostHeader() {
    //Uses a future builder to first get posts info from firebase then display it
    return FutureBuilder(
      future: usersRef.document(ownerId).get(),
      builder: (context, snapshot) {
        //Show loading spinner if no data
        if (!snapshot.hasData) {
          return circularProgress();
        }
        //The top structure of the post
        return ListTile(
          title: Row(
            children: <Widget>[
              //The posts title
              Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).accentColor,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          //The posts location
          subtitle: Text(
            location,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          //A button which leads to a comments screen
          trailing: RawMaterialButton(
            onPressed: () => showComments(context,
                postId: postId, ownerId: ownerId, imageUrl: imageUrl),
            child: Icon(
              Icons.comment,
              size: 28.0,
              color: Colors.white,
            ),
            shape: CircleBorder(),
            elevation: 2,
            fillColor: Theme.of(context).accentColor,
            padding: EdgeInsets.all(10),
          ),
        );
      },
    );
  }

  //Handles getting the post image and layout
  buildPostImage() {
    return Container(
      alignment: Alignment.center,
      height: MediaQuery.of(context).size.height * .4,
      child: cachedNetworkImage(context, imageUrl),
    );
  }

  //Gets the number of comments for the post
  getCommentCount() async {
    await commentsRef
        .document(postId)
        .collection('comments')
        .getDocuments()
        .then((snapshot) {
      return snapshot.documents.length;
    });
  }

  //Gets the distance of the post from the user
  getDistance() async {
    GeoPoint pos1 = loc['geopoint'];

    var pos2 = await location2.getLocation();
    var point = geo.point(latitude: pos1.latitude, longitude: pos1.longitude);
    var distance = point.distance(lat: pos2.latitude, lng: pos2.longitude);
    return distance;
  }

  //Build the bottom of the post
  buildPostFooter() {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Container(
                child: RichText(
                  text: TextSpan(
                      style: TextStyle(color: Colors.black),
                      children: <TextSpan>[
                        //Displays the data in a friendly format
                        TextSpan(
                            text: 'Date: ',
                            style: new TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: '${DateFormat.MMMEd().format(date)}'),
                      ]),
                ),
              ),
              //Displays the distance of post from user
              Container(
                  margin: EdgeInsets.only(left: 10.0),
                  //Uses a future builder to get distance before displaying
                  child: FutureBuilder(
                    future: getDistance(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) return Text('${snapshot.error}');
                      if (snapshot.hasData)
                        return Text(
                          "${snapshot.data} km away",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      return const CircularProgressIndicator();
                    },
                  )),
            ],
          ),
        ),
        Divider(
          height: 2,
          thickness: 2,
          endIndent: 10,
          indent: 10,
        ),
        //displays owner information
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0, top: 10, left: 12),
          child: Column(
            children: <Widget>[
              Container(
                alignment: Alignment.centerLeft,
                child: RichText(
                  text: TextSpan(
                      style: TextStyle(color: Colors.black),
                      children: <TextSpan>[
                        TextSpan(
                            text: 'Owner:\t\t',
                            style: new TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: '$username'),
                      ]),
                ),
              ),
              //Displays post description
              Padding(
                padding: const EdgeInsets.only(top: 10.0, bottom: 10),
                child: Container(
                  alignment: Alignment.centerLeft,
                  child: RichText(
                    text: TextSpan(
                        style: TextStyle(
                          color: Colors.black,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                              text: 'Description:\n',
                              style:
                                  new TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: '$description'),
                        ]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  //The overall structure of screen
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(5),
      elevation: 5,
      child: Column(
        children: <Widget>[
          buildPostImage(),
          buildPostHeader(),
          Divider(
            height: 2,
            thickness: 2,
            endIndent: 10,
            indent: 10,
          ),
          buildPostFooter(),
        ],
      ),
    );
  }
}

//Navigate to the comments screen and passes necessary information to build comments
showComments(BuildContext context,
    {String postId, String ownerId, String imageUrl}) {
  Navigator.push(context, MaterialPageRoute(
    builder: (context) {
      return Comments(
        postId: postId,
        postOwnerId: ownerId,
        postImageUrl: imageUrl,
      );
    },
  ));
}
