import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:find_my_pet/screens/post_screen.dart';
import 'package:find_my_pet/widgets/custom_image.dart';
import 'package:find_my_pet/widgets/post.dart';

//How a post is displayed as a tile
class PostTile extends StatelessWidget {
  final Post post;

  PostTile(this.post);

  //Navigate to post screen
  showPost(context) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                PostScreen(postId: post.postId, userId: post.ownerId)));
  }

  //Builds the post tile layout and styling
  @override
  Widget build(BuildContext context) {
    //Storing screen heigh and width for dynamic sizing
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    //If the tile is pressed anywhere it navigate to the post screen
    return InkWell(
      onTap: () => showPost(context),
      child: Container(
        height: height,
        width: width,
        child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 4,
            margin: EdgeInsets.all(4),
            child: Column(
              children: <Widget>[
                Stack(
                  children: <Widget>[
                    //Creates a rounded-rectangular clip.
                    ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                      //Display the post image
                      child: Container(
                        height: height * .2,
                        width: double.infinity,
                        child: cachedNetworkImage(context, post.imageUrl),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    top: 5.0,
                    left: 5,
                    right: 5,
                  ),
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: height * .03,
                    child: Row(
                      //Posts title
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Container(
                          width: MediaQuery.of(context).size.width / 5,
                          child: Text(
                            post.title,
                            textWidthBasis: TextWidthBasis.longestLine,
                            overflow: TextOverflow.clip,
                            maxLines: 1,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Theme.of(context).accentColor,
                            ),
                          ),
                        ),
                        //Display time since post was posted
                        Container(
                          width: MediaQuery.of(context).size.width / 5,
                          child: Text(
                            '${timeago.format(post.date)}',
                            textWidthBasis: TextWidthBasis.longestLine,
                            overflow: TextOverflow.fade,
                            maxLines: 1,
                            style: TextStyle(
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w400,
                                fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                //Display the posts location
                Padding(
                  padding: const EdgeInsets.only(
                      top: 5.0, left: 5, right: 5, bottom: 0),
                  child: Container(
                    height: height * .03,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: Container(
                            child: Text(
                              post.location,
                              softWrap: false,
                              overflow: TextOverflow.fade,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )),
      ),
    );
  }
}
