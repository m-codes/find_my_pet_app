import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

//Gets the image from firebase and provides styling
//If loading displays a loading indicator, if there is an error it displays error message
Widget cachedNetworkImage(context, imageUrl) {
  return Card(
    elevation: 10,
    margin: EdgeInsets.all(1),
    child: CachedNetworkImage(
      imageUrl: imageUrl,
      height: MediaQuery.of(context).size.height * .4,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (context, url) => Padding(
        child: CircularProgressIndicator(),
        padding: EdgeInsets.all(40),
      ),
      //If image doesn load
      errorWidget: (context, url, error) => Icon(Icons.error),
    ),
  );
}
