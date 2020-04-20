import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import 'package:find_my_pet/screens/post_screen.dart';
import 'package:find_my_pet/widgets/post.dart';
import 'package:find_my_pet/screens/home.dart';
import 'package:find_my_pet/widgets/progress.dart';

//Class to search for posts based on location
class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search>
    with AutomaticKeepAliveClientMixin<Search> {
  TextEditingController searchController = TextEditingController();
  Future<QuerySnapshot> searchResultsFuture;

  //Function to retrieve the posts that are greater than or equal to the users search
  handleSearch(String query) {
    Future<QuerySnapshot> posts = postsRef
        .where("locationSearch", isGreaterThanOrEqualTo: query.toLowerCase())
        .getDocuments();

    setState(() {
      searchResultsFuture = posts;
    });
  }

  clearSearch() {
    searchController.clear();
  }

  //Function to get the users location
  getUserLocation() async {
    //Get users current position
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    //Get the details of the current postion and store it in a list
    List<Placemark> placemarks = await Geolocator()
        .placemarkFromCoordinates(position.latitude, position.longitude);
    //Store details of the postion
    Placemark placemark = placemarks[0];
    //All possible locations subtypes
    //'${placemark.subThoroughfare} ${placemark.thoroughfare}, ${placemark.subLocality}, ${placemark.locality}, ${placemark.subAdministrativeArea}, ${placemark.administrativeArea} ${placemark.postalCode}, ${placemark.country},';

    //Produce only the users town, county and country
    String formattedAddress = "${placemark.locality}, ${placemark.country}";
    searchController.text = formattedAddress;
  }

  //Function to build the search bar in the app bar widget
  AppBar buildSearchField() {
    return AppBar(
      backgroundColor: Colors.white,
      title: TextFormField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: "Search by location...",
          filled: true,
          //If location icon pressed it generates the users location
          prefixIcon: IconButton(
            icon: Icon(
              Icons.location_on,
              size: 25,
            ),
            onPressed: getUserLocation,
          ),
          //Clears the text field
          suffixIcon: IconButton(
            icon: Icon(Icons.clear),
            onPressed: clearSearch,
          ),
        ),
        onFieldSubmitted: handleSearch,
      ),
    );
  }

  //Function that buils a container to display when there is no content
  Container buildNoContent() {
    return Container(
      child: Stack(
        children: <Widget>[
          Container(
            child: Center(
              child: ListView(
                shrinkWrap: true,
                children: <Widget>[
                  Text(
                    "Search post locations",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                      fontSize: 60.0,
                    ),
                  ),
                  Icon(
                    Icons.search,
                    size: MediaQuery.of(context).size.width * .3,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  //Build the search results based on users input
  buildSearchResults() {
    //Uses a future builder to get all posts that relate to user input
    //Then stores each as a post object in a list
    return FutureBuilder(
      future: searchResultsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        List<LocationResult> searchResults = [];
        snapshot.data.documents.forEach((doc) {
          Post location = Post.fromDocument(doc);
          LocationResult searchResult = LocationResult(location);
          searchResults.add(searchResult);
        });
        //Displays the generated search results to the screen
        return ListView(
          children: searchResults,
        );
      },
    );
  }

  //Variable needed to keep state alive if user leaves page
  bool get wantKeepAlive => true;

  //Builds the overall screen based on if user is searching or not
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.8),
      appBar: buildSearchField(),
      body:
          searchResultsFuture == null ? buildNoContent() : buildSearchResults(),
    );
  }
}

//Class to create individual post search results
class LocationResult extends StatelessWidget {
  final Post location;

  LocationResult(this.location);

  //Function to navigate to post if tapped
  showPost(context) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                PostScreen(postId: location.postId, userId: location.ownerId)));
  }

  //Build the structure of each search result
  //Post title, location, image and pet status(lost/found)
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor.withOpacity(0.7),
      child: Column(
        children: <Widget>[
          GestureDetector(
            onTap: () => showPost(context),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey,
                backgroundImage: CachedNetworkImageProvider(location.imageUrl),
              ),
              title: Text(
                location.title,
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                location.location,
                style: TextStyle(color: Colors.white),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Card(
                    color: Theme.of(context).accentColor.withBlue(150),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Text(
                        location.isFound ? "Found" : "Lost",
                        style: TextStyle(fontSize: 15.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(
            height: 2.0,
            color: Colors.white54,
          ),
        ],
      ),
    );
  }
}
