import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:location/location.dart';

import 'package:find_my_pet/UI/base_widget.dart';
import 'package:find_my_pet/screens/home.dart';
import 'package:find_my_pet/widgets/map.dart';
import 'package:find_my_pet/widgets/post.dart';
import 'package:find_my_pet/widgets/post_tile.dart';
import 'package:find_my_pet/widgets/progress.dart';

//Class to build and display lost, found and spotted pet posts
//Also contains logic for searching for posts within particular radius of the users location
class PostsOverview extends StatefulWidget {
  @override
  _PostsOverviewState createState() => _PostsOverviewState();
}

//SingleTickerProviderStateMixin is used to preserve state if user switches page
class _PostsOverviewState extends State<PostsOverview>
    with SingleTickerProviderStateMixin {
  Location location =
      new Location(); //Initializes location plugin and starts listening for events
  Geoflutterfire geo =
      Geoflutterfire(); //Store and query a set of keys based on geographic location
  List<Post> posts = [];
  List<String> ids = [];
  bool isLoading = false;
  double distance;
  double dropdownValue; //Store users selcted radius from drop down menu
  double radius = 10;
  int currentIndex;
  TabController _tabController; //Track current tab

  //Store the current users ID if it exists
  final String currentUserId = currentUser?.id;

  //Stire tabs to be used in main widget
  final List<Tab> myTabs = <Tab>[
    Tab(
      child: Container(
        alignment: Alignment.center,
        constraints: BoxConstraints.expand(),
        child: Text(
          "Lost",
        ),
      ),
    ),
    Tab(
      child: Container(
        alignment: Alignment.center,
        constraints: BoxConstraints.expand(),
        child: Text(
          "Found",
        ),
      ),
    ),
    Tab(
      child: Container(
        alignment: Alignment.center,
        constraints: BoxConstraints.expand(),
        child: Text(
          "Spotted",
        ),
      ),
    ),
  ];

  //Get posts and initialise tab contoller when page initially loads
  @override
  void initState() {
    super.initState();
    getPosts(currentIndex == null ? 0 : currentIndex);
    _tabController = TabController(vsync: this, length: myTabs.length);
    _tabController.addListener(_handleTabs);
  }

  //Dispose of tab controller to prevent memory leak
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  //Function to store current tab when user changes
  //And reload posts based on that tab
  _handleTabs() async {
    if (currentIndex != _tabController.index) {
      setState(() {
        currentIndex = _tabController.index;
      });
      await getPosts(currentIndex);
    }
  }

  //Function to get the document IDs of all posts that are within a particular radius to the user
  //Creates a geo point for the users location and the posts location using latitude and longitude
  //Then calculates the distance between the two points
  //If it is within the users set radius the ID is added to a list
  getIds(QuerySnapshot checkDistance) async {
    var pos2 = await location.getLocation();
    var point;
    checkDistance.documents.forEach((element) {
      GeoPoint pos1 = element['position']['geopoint'];
      point = geo.point(latitude: pos1.latitude, longitude: pos1.longitude);
      distance = point.distance(lat: pos2.latitude, lng: pos2.longitude);
      if (distance < radius) {
        setState(() {
          ids.add(element.documentID);
        });
      }
    });
  }

  //Function to get posts based on users selected tab and radius
  getPosts(int index) async {
    setState(() {
      isLoading = true;
    });

    List<Post> tempPosts = [];
    //Depending on users tab it will gather the required post types form the database
    QuerySnapshot snapshot;
    if (index == 0) {
      snapshot = await postsRef
          .orderBy("timestamp", descending: true)
          .where("petStatus", isEqualTo: 'lost')
          .getDocuments();
    } else if (index == 1) {
      snapshot = await postsRef
          .orderBy("timestamp", descending: true)
          .where("petStatus", isEqualTo: 'found')
          .getDocuments();
    } else if (index == 2) {
      snapshot = await postsRef
          .orderBy("timestamp", descending: true)
          .where("petStatus", isEqualTo: 'spotted')
          .getDocuments();
    }

    //Using the returned data it will then check and store the IDs of all those posts within
    //the users chosen radius
    await getIds(snapshot);

    ids.forEach((id) {
      snapshot.documents.forEach((element) {
        if (element.documentID == id) {
          tempPosts.add(Post.fromDocument(element));
        }
      });
    });

    //Clears unneeded data
    setState(() {
      isLoading = false;
      snapshot = null;
      posts = tempPosts.toList();
      tempPosts.clear();
      ids.clear();
    });
  }

  //Function to build all the returned posts
  buildPosts() {
    if (isLoading) {
      return circularProgress();
    }
    //If there are no posts returned show a screen that states this
    if (posts.isEmpty) {
      return Column(
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
          )
        ],
      );
    }
    //Pass each post to the PostTile class to build its layout
    //Then add it to a grid tile list
    List<GridTile> gridTiles = [];
    posts.forEach((post) {
      gridTiles.add(GridTile(
        child: PostTile(post),
      ));
    });
    //Create a dynamically sized grid view using the grid list stored above
    return Expanded(
      child: GridView.count(
        crossAxisCount: 2,
        childAspectRatio: (MediaQuery.of(context).size.width /
            (MediaQuery.of(context).size.height * .65)),
        mainAxisSpacing: 1.5,
        crossAxisSpacing: 1.5,
        shrinkWrap: true,
        children: gridTiles,
      ),
    );
  }

  //Build the post overview screen
  @override
  Widget build(BuildContext context) {
    return BaseWidget(builder: (context, sizingInfo) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'FindMyPet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22.0,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          //One action in the app bar, to store a drop down menu
          actions: <Widget>[
            Container(
              //Dynamic sizing and styling
              width: MediaQuery.of(context).size.width * .25,
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40)),
                color: Colors.white30,
              ),
              //Dropdown button to display radius options
              child: DropdownButton<double>(
                hint: Text("Radius"),
                value: dropdownValue,
                icon: Icon(Icons.arrow_drop_down),
                iconSize: 24,
                elevation: 10,
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                underline: SizedBox(),
                onChanged: (double newValue) {
                  //If user selects a new radius store it and getPosts based on new value
                  setState(() {
                    dropdownValue = newValue;
                    radius = newValue;
                    getPosts(currentIndex);
                  });
                },
                items: <double>[5, 10, 20, 50]
                    .map<DropdownMenuItem<double>>((double value) {
                  return DropdownMenuItem<double>(
                    value: value,
                    child: Text('${value.toInt()} km'),
                  );
                }).toList(),
              ),
            )
          ],
          centerTitle: true,
          backgroundColor: Theme.of(context).accentColor,
        ),
        body: Column(
          children: <Widget>[
            //Layout and styling of tabs
            Container(
              constraints: BoxConstraints.expand(height: 50),
              child: TabBar(
                controller: _tabController,
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Theme.of(context).accentColor,
                labelStyle: TextStyle(fontSize: 18),
                unselectedLabelStyle: TextStyle(fontSize: 14),
                tabs: myTabs,
              ),
            ),
            Expanded(
              //Tab View that displays the previously initialised tabs
              //Contoller set to track user selection
              child: TabBarView(
                controller: _tabController,
                children: myTabs.map((Tab tab) {
                  return Column(
                    //Build posts for each tab
                    children: <Widget>[
                      buildPosts(),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        //Floating button that if tapped opens a map that displays each post and where its located
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'btn2',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewMap(),
            ),
          ),
          label: Text('Map'),
          icon: Icon(
            Icons.navigation,
          ),
          backgroundColor: Theme.of(context).primaryColor,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      );
    });
  }
}
