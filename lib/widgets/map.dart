import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

import 'package:find_my_pet/screens/home.dart';
import 'package:find_my_pet/screens/post_screen.dart';

class ViewMap extends StatefulWidget {
  @override
  _ViewMapState createState() => _ViewMapState();
}

class _ViewMapState extends State<ViewMap> {
  GoogleMapController mapController;
  Location location = new Location();
  Geoflutterfire geo = Geoflutterfire();
  //StreamController that captures the latest item that has been added to the controller,
  BehaviorSubject<double> radius = BehaviorSubject.seeded(100);
  Stream<dynamic> query;
  StreamSubscription subscription;
  Map<MarkerId, Marker> markers =
      <MarkerId, Marker>{}; //Store a list of post markers
  String postId = Uuid().v4();
  double lat;
  double lng;

  //Get the distance between two locations
  getDistance(
      double currentLat, double currentLng, double postLat, double postLng) {
    var point = geo.point(latitude: currentLat, longitude: currentLng);
    var distance = point.distance(lat: postLat, lng: postLng);
    return distance;
  }

  //Build the overall map view
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(53.1871, -6.80366),
              zoom: 15,
            ),
            onMapCreated: _onMapCreated,
            myLocationEnabled: true,
            mapType: MapType.normal,
            //Set markers on the map, aka post locations
            markers: Set<Marker>.of(markers.values),
          ),
          Positioned(
              bottom: 50,
              right: 10,
              //Button to navigate back to home screen
              child: FlatButton(
                child: Icon(Icons.arrow_back, color: Colors.white),
                color: Colors.green,
                onPressed: () => Navigator.of(context).pop(),
              )),
          //Create a slider to zoom in and out of map
          Positioned(
              bottom: 50,
              left: 10,
              child: Slider(
                min: 100,
                max: 500,
                divisions: 4,
                value: radius.value,
                label: 'Radius ${radius.value}km',
                activeColor: Colors.green,
                inactiveColor: Colors.green.withOpacity(.7),
                onChanged: _updateQuery,
              ))
        ],
      ),
    );
  }

  //When the map is created set the controller
  _onMapCreated(GoogleMapController controller) {
    _startQuery();
    setState(() {
      mapController = controller;
    });
  }

  //set the initial query to show markers
  _startQuery() async {
    var pos = await location.getLocation();

    setState(() {
      lat = pos.latitude;
      lng = pos.longitude;
    });

    GeoFirePoint center = geo.point(latitude: lat, longitude: lng);

    //Sub to query. Which sets the radius from a given position
    subscription = radius.switchMap((rad) {
      return geo.collection(collectionRef: locationsRef).within(
            center: center,
            radius: 400,
            field: 'position',
            strictMode: true,
          );
    }).listen(_updateMarkers);
  }

  //Change the markers dispayed as the map zooms in and out
  _updateQuery(value) {
    final zoomMap = {
      100.0: 12.0,
      200.0: 10.0,
      300.0: 7.0,
      400.0: 6.0,
      500.0: 5.0,
    };
    final zoom = zoomMap[value];
    mapController.moveCamera(CameraUpdate.zoomTo(zoom));

    setState(() {
      radius.add(value);
    });
  }

  //Update the markers displayed and the information each contains
  _updateMarkers(List<DocumentSnapshot> docList) {
    //For each marker give it the below layout and add it to the list
    docList.forEach((DocumentSnapshot doc) {
      GeoPoint pos = doc.data['position']['geopoint'];

      //Get the distance between user and post location
      var distance = getDistance(lat, lng, pos.latitude, pos.longitude);

      var markId = MarkerId(Uuid().v4());
      var marker = Marker(
        markerId: markId,
        position: LatLng(
          pos.latitude,
          pos.longitude,
        ),
        icon: BitmapDescriptor.defaultMarker,
        //The information displayed when marker is tapped
        infoWindow: InfoWindow(
            title: doc['title'],
            snippet: '$distance km from you.',
            //If tapped on navigate to the post
            onTap: () => {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => PostScreen(
                              postId: doc['postId'], userId: doc['ownerId'])))
                }),
      );
      setState(() {
        markers[markId] = marker;
      });
    });
  }

  //Dispose of subscription to prevent memory leak
  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }
}
