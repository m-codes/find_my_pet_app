import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:find_my_pet/screens/home.dart';
import 'package:find_my_pet/widgets/header.dart';
import 'package:find_my_pet/widgets/progress.dart';

//Class that build the overall comment screen

class Comments extends StatefulWidget {
  final String postId;
  final String postOwnerId;
  final String postImageUrl;
  final String petStatus;
  final String displayName;

  Comments(
      {this.postId,
      this.postOwnerId,
      this.postImageUrl,
      this.petStatus,
      this.displayName});

  @override
  CommentsState createState() => CommentsState(
        postId: this.postId,
        postOwnerId: this.postOwnerId,
        postImageUrl: this.postImageUrl,
        petStatus: this.petStatus,
        displayName: this.displayName,
      );
}

class CommentsState extends State<Comments> {
  TextEditingController commentController = TextEditingController();
  final String postId;
  final String postOwnerId;
  final String postImageUrl;
  final String petStatus;
  final String displayName;

  CommentsState(
      {this.postId,
      this.postOwnerId,
      this.postImageUrl,
      this.petStatus,
      this.displayName});

  //Function to build the comments return from the database
  buildComments() {
    //Getting comments in realtime using stream
    //It actively listens to the database section you connect it to
    return StreamBuilder(
        stream: commentsRef
            .document(postId)
            .collection('comments')
            .orderBy("timestamp", descending: false)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }
          List<Comment> comments = [];
          snapshot.data.documents.forEach((doc) {
            comments.add(Comment.fromDocument(doc));
          });
          return ListView(
            children: comments,
          );
        });
  }

  //Functions to add comments to to feed and comments collection in database
  addComments() {
    commentsRef.document(postId).collection("comments").add({
      "username": currentUser.username,
      "comment": commentController.text,
      "timestamp": timestamp,
      "userPhotoUrl": currentUser.photoUrl,
      "userId": currentUser.id,
      "displayName": currentUser.displayName,
    });
    if (postOwnerId != currentUser.id) {
      feedRef.document(postOwnerId).collection('comments').add({
        "type": "comment",
        "username": currentUser.username,
        "commentData": commentController.text,
        "timestamp": timestamp,
        "postId": postId,
        "userPhotoUrl": currentUser.photoUrl,
        "userId": currentUser.id,
        "imageUrl": postImageUrl,
        "petStatus": petStatus,
        "displayName": currentUser.displayName,
      });
    }
    commentController.clear();
  }

  //Dispay the comments screen
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, titleText: "Comments"),
      body: Column(
        children: <Widget>[
          Expanded(child: buildComments()),
          Divider(),
          ListTile(
            title: TextFormField(
              controller: commentController,
              decoration: InputDecoration(labelText: "Write a comment..."),
            ),
            trailing: OutlineButton(
              onPressed: addComments,
              borderSide: BorderSide.none,
              child: Text('Post'),
            ),
          ),
        ],
      ),
    );
  }
}

//Class to build the individual comment look and feel
//Comment data, user  image and time since posted
class Comment extends StatelessWidget {
  final String username;
  final String userId;
  final String userPhotoUrl;
  final String comment;
  final Timestamp timestamp;
  final displayName;

  const Comment({
    this.username,
    this.userId,
    this.userPhotoUrl,
    this.comment,
    this.timestamp,
    this.displayName,
  });

  factory Comment.fromDocument(DocumentSnapshot doc) {
    return Comment(
      username: doc['username'],
      userId: doc['userId'],
      userPhotoUrl: doc['userPhotoUrl'],
      comment: doc['comment'],
      timestamp: doc['timestamp'],
      displayName: doc['displayname'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          title: Text(comment),
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(userPhotoUrl),
          ),
          subtitle: Text(timeago.format(timestamp.toDate())),
        ),
        Divider(),
      ],
    );
  }
}
