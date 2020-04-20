import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../screens/home.dart';
import '../screens/post_screen.dart';
import '../widgets/progress.dart';

class ActivityFeed extends StatefulWidget {
  @override
  _ActivityFeedState createState() => _ActivityFeedState();
}

class _ActivityFeedState extends State<ActivityFeed> {
  //Function to get all feed items for the current user from firebase
  //Then add them to a list and return the list
  getActivityFeed() async {
    QuerySnapshot snapshot = await feedRef
        .document(currentUser.id)
        .collection('comments')
        .orderBy("timestamp", descending: true)
        .limit(10)
        .getDocuments();
    List<ActivityFeedItem> feedItems = [];
    snapshot.documents.forEach((doc) {
      feedItems.add(ActivityFeedItem.fromDocument(doc));
    });
    return feedItems;
  }

  //Function to clear the users notification feed
  deleteItems() async {
    QuerySnapshot snapshot = await feedRef
        .document(currentUser.id)
        .collection('comments')
        .getDocuments();
    snapshot.documents.forEach((doc) {
      doc.reference.delete();
    });
    setState(() {});
  }

  //Builds the overall activity feed screen
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).accentColor,
        title: Text(
          'Feed',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22.0,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        //Actions contains the clear feed button, that calls deleteItems function above
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: CircleAvatar(
                backgroundColor: Colors.white54,
                child: IconButton(
                  onPressed: () => deleteItems(),
                  icon: Icon(Icons.delete),
                  color: Colors.black,
                )),
          )
        ],
      ),
      //Body of the page is made up of the activity feed items
      //Created using a future builder, which will call on the data
      //in the database before trying to populate the feed items.
      body: Container(
        child: FutureBuilder(
          future: getActivityFeed(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return circularProgress();
            }
            return ListView(
              children: snapshot.data,
            );
          },
        ),
      ),
    );
  }
}

//Seperate class for individual feed items that defines the structure of each item
class ActivityFeedItem extends StatelessWidget {
  final String commentData;
  final String imageUrl;
  final String postId;
  final Timestamp timestamp;
  final String type;
  final String userId;
  final String userPhotoUrl;
  final String username;
  final String petStatus;

  ActivityFeedItem({
    this.commentData,
    this.imageUrl,
    this.postId,
    this.timestamp,
    this.type,
    this.userId,
    this.userPhotoUrl,
    this.username,
    this.petStatus,
  });

  //factory describes creating an instance from a firebase document
  factory ActivityFeedItem.fromDocument(DocumentSnapshot doc) {
    return ActivityFeedItem(
      commentData: doc['commentData'],
      imageUrl: doc['imageUrl'],
      postId: doc['postId'],
      timestamp: doc['timestamp'],
      type: doc['type'],
      userId: doc['userId'],
      userPhotoUrl: doc['userPhotoUrl'],
      username: doc['displayName'],
      petStatus: doc['petStatus'],
    );
  }

  //Function to navigate to post if tapped on
  showPost(context) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => PostScreen(
                  postId: postId,
                  userId: userId,
                )));
  }

  //Builds the image preview for the feed item
  Widget imagePreview(context) {
    return GestureDetector(
      onTap: () => showPost(context),
      child: Container(
        height: 50,
        width: MediaQuery.of(context).size.width * .2,
        child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: CachedNetworkImageProvider(imageUrl),
                ),
              ),
            )),
      ),
    );
  }

  //Builds and displays each activity item
  //Each contains the users image, comment data, time since it happened
  //the users name and an image of the post
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.only(bottom: 3),
        child: Container(
            color: Colors.black26,
            child: ListTile(
              title: GestureDetector(
                onTap: () => showPost(context),
                //Using RichText to highlight certain areas in notification
                child: RichText(
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                      ),
                      children: [
                        TextSpan(
                          text: username,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: ":\t\t\t$commentData",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        )
                      ]),
                ),
              ),
              leading: CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(userPhotoUrl),
              ),
              subtitle: Text(
                timeago.format(timestamp.toDate()),
                overflow: TextOverflow.ellipsis,
              ),
              trailing: imagePreview(context),
            )));
  }
}
