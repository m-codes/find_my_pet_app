import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:find_my_pet/screens/home.dart';

//The main that starts the run process
void main() {
  //Sets the app to be only viewed in portrait mode
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    //Setting theme data to reflect thoughout the app
    return MaterialApp(
      title: 'FindMyPet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        accentColor: Colors.teal,
      ),
      home: Home(),
    );
  }
}
