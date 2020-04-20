import 'package:flutter/material.dart';

import 'package:find_my_pet/widgets/header.dart';
import 'package:find_my_pet/widgets/post.dart';
import 'package:find_my_pet/widgets/progress.dart';
import 'package:find_my_pet/screens/home.dart';

//Class that displays the page structure for a post page
//But calls on the PostTile class to create the post layout and styling
class PostScreen extends StatelessWidget {
  final String userId;
  final String postId;

  PostScreen({this.userId, this.postId});

  @override
  Widget build(BuildContext context) {
    //Uses future builder to create a posts data based on post id
    return FutureBuilder(
      future: postsRef.document(postId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        Post post = Post.fromDocument(snapshot.data);
        return Center(
            child: Scaffold(
          appBar: header(context, titleText: post.title),
          body: ListView(
            children: <Widget>[
              Container(child: post),
            ],
          ),
        ));
      },
    );
  }
}
