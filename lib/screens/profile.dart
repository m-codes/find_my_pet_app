import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nice_button/NiceButton.dart';

import 'package:find_my_pet/models/user.dart';
import 'package:find_my_pet/screens/edit_post.dart';
import 'package:find_my_pet/screens/edit_profile.dart';
import 'package:find_my_pet/screens/home.dart';
import 'package:find_my_pet/widgets/header.dart';
import 'package:find_my_pet/widgets/post.dart';
import 'package:find_my_pet/widgets/post_tile.dart';
import 'package:find_my_pet/widgets/progress.dart';

//Class that contains the users profile layout and logic
class Profile extends StatefulWidget {
  final String profileId;

  Profile({this.profileId});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final String currentUserId = currentUser?.id;
  bool isLoading = false;
  List<Post> posts = [];
  bool postGridOrientation = true;

  //Get profile posts when page is initialised
  @override
  void initState() {
    super.initState();
    getProfilePosts();
  }

  //Function to get profile posts for the current user
  getProfilePosts() async {
    setState(() {
      isLoading = true;
    });
    //Get a snapshot of the posts the current user owns
    QuerySnapshot snapshot = await postsRef
        .where("ownerId", isEqualTo: currentUserId)
        .getDocuments();
    setState(() {
      isLoading = false;
      //Get each post returned from the snapshot and turn it into a post widget, then add it to the list
      posts = snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();
    });
  }

  //Function to navigate to the edit profile screen
  editProfile() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => EditProfile(currentUserId: currentUserId)));
  }

  //Function to log the user out
  logout() async {
    await googleSignIn.signOut();
    await FirebaseAuth.instance.signOut();
    Navigator.push(context, MaterialPageRoute(builder: (context) => Home()));
  }

  //Function to build a button. Used to remove code duplication
  //Depending on params passed to it, it will be an edit or logout button
  buildProfileButton(bool edit, String text) {
    bool isProfileOwner = currentUserId == widget.profileId;
    if (isProfileOwner) {
      return Container(
        height: MediaQuery.of(context).size.height * .055,
        width: MediaQuery.of(context).size.width * .5,
        child: NiceButton(
          background: edit ? Colors.blue : Colors.red,
          elevation: 4,
          onPressed: edit ? editProfile : logout,
          text: text,
          textColor: Colors.white,
          fontSize: 15,
          radius: 10,
          padding: EdgeInsets.all(3),
        ),
      );
    } else {
      return Text('');
    }
  }

  //Function to build the users profile header
  buildProfileHeader() {
    return FutureBuilder(
        //get user info based on ID
        future: usersRef.document(widget.profileId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }
          User user = User.fromDocument(snapshot.data);
          return Padding(
            padding: EdgeInsets.all(15),
            child: Column(children: <Widget>[
              //Builds the users profile image
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey,
                            backgroundImage:
                                CachedNetworkImageProvider(user.photoUrl),
                          ),
                        ],
                      ),
                    ],
                  ),
                  //Builds the edit and logout button
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      buildProfileButton(true, 'Edit Profile'),
                      const SizedBox(height: 10),
                      buildProfileButton(false, 'Logout'),
                    ],
                  ),
                ],
              ),
              //Displays users name
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Container(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.only(top: 12, left: 10),
                    child: Text(
                      //If user hasnt set a name it will be stated
                      user.displayName != null
                          ? user.displayName
                          : 'No Display Name',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ]),
          );
        });
  }

  //Function that sets the users selected viewing preference, grid or list
  buildTogglePostOrientation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
          icon: Icon(Icons.grid_on),
          color: postGridOrientation
              ? Theme.of(context).primaryColor
              : Colors.grey,
          onPressed: () {
            setState(() {
              this.postGridOrientation = true;
            });
          },
        ),
        IconButton(
          icon: Icon(Icons.list),
          color: !postGridOrientation
              ? Theme.of(context).primaryColor
              : Colors.grey,
          onPressed: () {
            setState(() {
              this.postGridOrientation = false;
            });
          },
        ),
      ],
    );
  }

  //Function to delete a post
  //It is delted from multiple areas within the database
  //Its image,post,feed notifications, comments and map location
  deletePost(String postId, String ownerId) async {
    //Delete the post
    postsRef.document(postId).get().then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    //Delete its stored image
    storageRef.child("post_$postId.jpg").delete();
    //Delete all feed notifications
    QuerySnapshot feedSnapshot = await feedRef
        .document(ownerId)
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .getDocuments();
    feedSnapshot.documents.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

    await commentsRef.document(postId).delete();
    await locationsRef.document(postId).delete();

    QuerySnapshot commentSnapshot = await commentsRef
        .document(postId)
        .collection('comments')
        .getDocuments();
    commentSnapshot.documents.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }

  //Function to build the post image the user owns
  buildProfilePosts() {
    if (isLoading) {
      return circularProgress();
    } else if (posts.isEmpty) {
      //If the user has no posts
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            "No posts available",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
              fontSize: 60.0,
            ),
          ),
          Icon(
            Icons.pets,
            size: MediaQuery.of(context).size.width * .2,
            color: Colors.black54,
          ),
        ],
      );
    } else if (postGridOrientation) {
      //if the user chooses to view posts as a grid
      List<GridTile> gridTiles = [];
      //Stores each post in a grid tile list
      posts.forEach((post) {
        gridTiles.add(GridTile(
          child: PostTile(post),
          footer: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              //An edit button on the post so the user can make changes
              IconButton(
                icon: Icon(
                  Icons.edit,
                  color: Colors.blue,
                ),
                onPressed: () async {
                  setState(() {
                    isLoading = true;
                  });
                  if (isLoading) {
                    //Navigate to edit screen if icon is pressed
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditPost(
                          postId: post.postId,
                          imageUrl: post.imageUrl,
                          description: post.description,
                          title: post.title,
                        ),
                      ),
                    );
                  }

                  setState(() {
                    isLoading = false;
                  });
                  getProfilePosts();
                },
              ),
              //A delete button on the post to remove it and all other aspects from the database
              IconButton(
                  icon: Icon(
                    Icons.delete,
                    color: Colors.redAccent,
                  ),
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          //An alert box to confirm the user wants to delete the post
                          return AlertDialog(
                            title: Text('Delete Post'),
                            content: Text('Are you sure?'),
                            actions: <Widget>[
                              FlatButton(
                                child: Text('Cancel'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                              FlatButton(
                                child: Text('Yes'),
                                onPressed: () async {
                                  setState(() {
                                    isLoading = true;
                                  });
                                  if (isLoading) {
                                    circularProgress();

                                    deletePost(post.postId, post.ownerId);
                                    setState(() {
                                      isLoading = false;
                                    });
                                  }
                                  Navigator.of(context).pop();
                                  getProfilePosts();
                                },
                              )
                            ],
                            elevation: 15,
                          );
                        });
                  }),
            ],
          ),
        ));
      });
      //Display the stored posts in a grid view
      return Expanded(
        child: GridView(
          children: gridTiles,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: (MediaQuery.of(context).size.width /
                (MediaQuery.of(context).size.height * .7)),
          ),
        ),
      );
    } else if (!postGridOrientation) {
      //Display the posts in a list view
      return Expanded(
        child: GridView(
          children: posts,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1,
            childAspectRatio: ((MediaQuery.of(context).size.width * .2) /
                (MediaQuery.of(context).size.height * .3)),
          ),
        ),
      );
    }
  }

  //Builds overall structure of the screen
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, titleText: "Profile"),
      body: Column(
        children: <Widget>[
          buildProfileHeader(),
          Divider(
            height: 0,
          ),
          buildTogglePostOrientation(),
          Divider(height: 0),
          buildProfilePosts(),
        ],
      ),
    );
  }
}
