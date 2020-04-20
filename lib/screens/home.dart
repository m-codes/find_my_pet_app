import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:find_my_pet/UI/base_widget.dart';
import 'package:find_my_pet/models/user.dart';
import 'package:find_my_pet/screens/activity_feed.dart';
import 'package:find_my_pet/screens/post_overview.dart';
import 'package:find_my_pet/screens/profile.dart';
import 'package:find_my_pet/screens/search.dart';
import 'package:find_my_pet/screens/post_form.dart';

//Authentication objects
final GoogleSignIn googleSignIn = GoogleSignIn();
final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
final StorageReference storageRef = FirebaseStorage.instance.ref();

//Firebase database references
final usersRef = Firestore.instance.collection('users');
final postsRef = Firestore.instance.collection('posts');
final commentsRef = Firestore.instance.collection('comments');
final feedRef = Firestore.instance.collection('feed');
final locationsRef = Firestore.instance.collection('locations');

//Location objects
Geoflutterfire geo = Geoflutterfire();
GeoFirePoint myLoc;

//Timestamp for database
final DateTime timestamp = DateTime.now();
//User object from data model
User currentUser;

enum AuthMode { Signup, Login }

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  PageController pageController;
  bool isAuth = false;
  int pageIndex = 0;

  //Global keys
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> _unAuthKey = GlobalKey();
  final GlobalKey<FormState> _formKey = GlobalKey();

  //Auth status
  AuthMode _authMode = AuthMode.Login;
  //Map to store auth data
  Map<String, String> _authData = {
    'email': '',
    'password': '',
  };

  var _isLoading = false;

  //Carry out the below function when initialised
  @override
  void initState() {
    super.initState();
    pageController = PageController();
    // Detects when user signed in
    googleSignIn.onCurrentUserChanged.listen((account) {
      handleSignIn(account);
    }, onError: (err) {
      print('Error signing in: $err');
    });
    //Reauthenticate user when app is opened - Google login
    googleSignIn.signInSilently(suppressErrors: false).then((account) {
      handleSignIn(account);
    }).catchError((err) {
      print('Error signing in: $err');
    });
    //Reauthenticate user when app is opened - email login
    getUser().then((user) async {
      if (user != null) {
        DocumentSnapshot doc = await usersRef.document(user.uid).get();
        currentUser = User.fromDocument(doc);
        setState(() {
          isAuth = true;
        });
      }
    });
  }

  //Error function to be shown if issue loggin in
  void _showErrorDialog(String message) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text('An error occured!'),
              content: Text(message),
              actions: <Widget>[
                FlatButton(
                  child: Text('Okay'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
              ],
            ));
  }

  //Get user info if available
  Future<FirebaseUser> getUser() async {
    return await _firebaseAuth.currentUser();
  }

  //Handles signin if done though email/password combo
  Future<FirebaseUser> handleSignInEmail(String email, String password) async {
    //Authenticate user with firebase
    AuthResult result = await _firebaseAuth
        .signInWithEmailAndPassword(email: email, password: password)
        .catchError((signUpError) {
      //If authentication fails show error box
      showDialog<void>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Invalid Login'),
              content: Text('The password or email is incorrect.'),
              actions: <Widget>[
                FlatButton(
                  child: Text('Ok'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          });
    });

    //If it doesnt fail store information
    final FirebaseUser user = result.user;

    //Ensure it contains necessary data
    assert(user != null);
    assert(await user.getIdToken() != null);

    final FirebaseUser current = await _firebaseAuth.currentUser();
    assert(user.uid == current.uid);
    print('signInEmail succeeded: $user');

    //If authenticated build user from data model
    DocumentSnapshot doc = await usersRef.document(user.uid).get();
    currentUser = User.fromDocument(doc);
    //Configure user for push notifications if not already done
    configurePushNotifications();
    setState(() {
      isAuth = true;
    });
    return user;
  }

  //Handle a user signing up
  handleSignUp(email, password) async {
    //Create the user in firebase database
    AuthResult result = await _firebaseAuth
        .createUserWithEmailAndPassword(email: email, password: password)
        .catchError((signUpError) {
      //If email already in use display error box stating so
      if (signUpError is PlatformException) {
        if (signUpError.code == 'ERROR_EMAIL_ALREADY_IN_USE') {
          showDialog<void>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Invalid Email'),
                  content: Text('This email is already in use.'),
                  actions: <Widget>[
                    FlatButton(
                      child: Text('Ok'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              });
        }
      }
    });

    //If it doesnt fail store information and check its contents
    final FirebaseUser user = result.user;
    assert(user != null);
    assert(await user.getIdToken() != null);
    await getUserLocation();

    //Store user info in database as well as authentication platform
    await usersRef.document(user.uid).setData({
      "id": user.uid,
      "photoUrl":
          "https://firebasestorage.googleapis.com/v0/b/find-my-pet-3ddcf.appspot.com/o/pet.png?alt=media&token=4e018ced-3681-4108-82fd-e55758818f24",
      "email": user.email,
      "displayName": user.displayName,
      "timestamp": timestamp,
      "position": myLoc.data,
    });
    //Create current user using data obtained and data model
    var doc = await usersRef.document(user.uid).get();
    currentUser = User.fromDocument(doc);
    showDialog<void>(
        //Notify user when account created
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Account Created'),
            content: Text('Please login to proceed.'),
            actions: <Widget>[
              FlatButton(
                child: Text('Ok'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  //Handles the form being submitted
  //Validate, error checks, calls necessary functions and switches auth mode if authenticated
  Future<void> _submit() async {
    if (!_formKey.currentState.validate()) {
      // Invalid
      return;
    }
    //Saves the inputs
    _formKey.currentState.save();
    setState(() {
      _isLoading = true;
    });
    try {
      if (_authMode == AuthMode.Login) {
        handleSignInEmail(emailController.text, passwordController.text);
      } else {
        handleSignUp(emailController.text, passwordController.text);
      }
      //On: checking for specific type of exception
      //This error is thrown if data validation fails
    } on HttpException catch (error) {
      var errorMessage = 'Authentication failed';
      if (error.toString().contains('EMAIL_EXISTS')) {
        errorMessage = 'This email address is already in use.';
      } else if (error.toString().contains('INVALIS_EMAIL')) {
        errorMessage = 'This is not a valid email address.';
      } else if (error.toString().contains('WEAK_PASSWORD')) {
        errorMessage = 'This password is too weak.';
      } else if (error.toString().contains('EMAIL_NOT_FOUND')) {
        errorMessage = 'Could not find a user with that email.';
      } else if (error.toString().contains('INVALID_PASSWORD')) {
        errorMessage = 'Invalid password.';
      }
      _showErrorDialog(errorMessage);
    } catch (error) {
      const errorMessage = 'Could not authenticate you. Please try again.';
      _showErrorDialog(errorMessage);
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _switchAuthMode() {
    if (_authMode == AuthMode.Login) {
      setState(() {
        _authMode = AuthMode.Signup;
      });
    } else {
      setState(() {
        _authMode = AuthMode.Login;
      });
    }
  }

  //Hangles sign in if done through google
  handleSignIn(GoogleSignInAccount account) async {
    if (account != null) {
      //Create user in database
      await createUserInFirestore(account);
      print('User signed in!: $account');
      setState(() {
        isAuth = true;
      });
      //Configure push notifications if not already done
      configurePushNotifications();
    } else {
      setState(() {
        isAuth = false;
      });
    }
  }

  //Get the users current location
  getUserLocation() async {
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      myLoc =
          geo.point(latitude: position.latitude, longitude: position.longitude);
    });
  }

  //Configure push notifications
  configurePushNotifications() {
    var userId = currentUser.id;
    //Add notification token to users data in database
    _firebaseMessaging.getToken().then((token) {
      DocumentReference docRef = usersRef.document(userId);
      docRef.updateData({"androidNotificationToken": token});
    });

    //Configure notifications for the app
    _firebaseMessaging.configure(
      //display notifications when app is off
      onLaunch: (Map<String, dynamic> message) async {
        final String recipientId = message['data']['recipient'];
        final String body = message['notification']['body'];

        if (recipientId == userId) {
          SnackBar snackbar = SnackBar(
              content: Text(
            body,
            overflow: TextOverflow.ellipsis,
          ));
          _scaffoldKey.currentState.showSnackBar(snackbar);
        }
      },
      //display notifications when app is in background
      onResume: (Map<String, dynamic> message) async {
        final String recipientId = message['data']['recipient'];
        final String body = message['notification']['body'];

        if (recipientId == userId) {
          SnackBar snackbar = SnackBar(
              content: Text(
            body,
            overflow: TextOverflow.ellipsis,
          ));
          _scaffoldKey.currentState.showSnackBar(snackbar);
        }
      },

      //display notifications when in the app
      onMessage: (Map<String, dynamic> message) async {
        final String recipientId = message['data']['recipient'];
        final String body = message['notification']['body'];

        if (recipientId == userId) {
          SnackBar snackbar = SnackBar(
              content: Text(
            body,
            overflow: TextOverflow.ellipsis,
          ));
          _scaffoldKey.currentState.showSnackBar(snackbar);
        }
      },
    );
  }

  //Create user in the database
  createUserInFirestore(GoogleSignInAccount account) async {
    //Get and auth details
    final GoogleSignInAccount googleUser = await googleSignIn.signIn();
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final AuthCredential credentials = GoogleAuthProvider.getCredential(
        idToken: googleAuth.idToken, accessToken: googleAuth.accessToken);

    getUserLocation();
    FirebaseUser userDetails =
        (await _firebaseAuth.signInWithCredential(credentials)).user;

    //check if user exists in users collection in db (according to their id)
    DocumentSnapshot doc = await usersRef.document(userDetails.uid).get();
    if (!doc.exists) {
      //Make a new user doc in users collection if it doesnt exist
      usersRef.document(userDetails.uid).setData({
        "id": userDetails.uid,
        "photoUrl": userDetails.photoUrl,
        "email": userDetails.email,
        "displayName": userDetails.displayName,
        "timestamp": timestamp,
        "position": myLoc.data,
      });
      //Contains users data from database
      doc = await usersRef.document(userDetails.uid).get();
    }

    //If data does exist create current user using User data model
    currentUser = User.fromDocument(doc);
  }

  login() {
    googleSignIn.signIn();
  }

  logout() {
    googleSignIn.signOut();
  }

  //Keep track of users page, i.e bottom navigation
  onPageChanged(int pageIndex) {
    setState(() {
      this.pageIndex = pageIndex;
    });
  }

  //Change users page when tapped
  onTap(int pageIndex) {
    pageController.animateToPage(
      pageIndex,
      duration: Duration(
        milliseconds: 200,
      ),
      curve: Curves.easeInOut,
    );
  }

  //Dispose of controller to prevent memory leak
  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  //Build the screen that is shown when user is authenticated
  Scaffold buildAuthScreen() {
    return Scaffold(
      key: _scaffoldKey, //for notifications
      resizeToAvoidBottomPadding: false,
      body: PageView(
        //The different page options
        children: <Widget>[
          PostsOverview(),
          ActivityFeed(),
          Upload(
            currentUser: currentUser,
          ),
          Search(),
          //? means only get ID if not null
          Profile(profileId: currentUser?.id),
        ],
        controller: pageController,
        onPageChanged: onPageChanged,
        physics: NeverScrollableScrollPhysics(),
      ),

      //Floating action button for adding a post
      floatingActionButton: FloatingActionButton(
        heroTag: 'btn1',
        onPressed: () => onTap(2),
        child: Icon(
          Icons.add,
          size: 40,
        ),
      ),
      //Bottom navigation for the different pages
      bottomNavigationBar: BottomAppBar(
        notchMargin: 5,
        shape: CircularNotchedRectangle(),
        clipBehavior: Clip.antiAlias,
        child: BottomNavigationBar(
          currentIndex: pageIndex,
          onTap: onTap,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.black87,
          //Each page name and icon, keeps an index
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
                icon: Icon(Icons.pets), title: Text('Pets')),
            BottomNavigationBarItem(
                icon: Icon(Icons.notifications_active),
                title: Text('Notifications')),
            BottomNavigationBarItem(
                icon: Icon(
                  Icons.search,
                  color: Colors.transparent,
                ),
                title: Text('')),
            BottomNavigationBarItem(
                icon: Icon(Icons.search), title: Text('Search')),
            BottomNavigationBarItem(
                icon: Icon(Icons.account_circle), title: Text('Profile')),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  //Build the screen that is shown when user is unauthenticated
  Scaffold buildUnAuthScreen() {
    final deviceSize = MediaQuery.of(context).size;
    return Scaffold(
      key: _unAuthKey,
      //Stack to place widgets on top of each other
      body: Stack(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              //Gradient of colours for container
              gradient: LinearGradient(
                colors: [
                  Color.fromRGBO(67, 206, 162, 1).withOpacity(0.5),
                  Color.fromRGBO(24, 90, 157, 1).withOpacity(0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0, 1],
              ),
            ),
          ),
          SingleChildScrollView(
            child: Container(
              height: deviceSize.height,
              width: deviceSize.width,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Flexible(
                    child: Container(
                      width: deviceSize.width * .9,
                      margin: EdgeInsets.only(bottom: 20.0),
                      padding:
                          EdgeInsets.symmetric(vertical: 8.0, horizontal: 44.0),
                      //Transform: allows you to change how container is presented
                      //Matrix4 describes transformation of a container, e.g. rotation, scaling
                      //Rotainz: change z axis, depth into device
                      //translate changes the offset
                      //.. alows you to return the type of the previous statement instead of the translates default (void)
                      transform: Matrix4.rotationZ(-8 * pi / 180)
                        ..translate(-5.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white70,
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 8,
                            color: Colors.black26,
                            offset: Offset(0, 2),
                          )
                        ],
                      ),
                      height: deviceSize.height * .2,
                      child: FittedBox(
                        fit: BoxFit.fitWidth,
                        child: Text(
                          'FindMyPet',
                          style: TextStyle(
                            color: Theme.of(context).accentColor,
                            fontSize: 50,
                            fontFamily: 'Anton',
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                    flex: deviceSize.width > 600 ? 2 : 1,
                    //Authentication form
                    child: buildAuthCard(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  //Auth card as part of authentication screen
  //Conditional checks thoughout change look based on auth mode (sign in or sign up)
  buildAuthCard() {
    final deviceSize = MediaQuery.of(context).size;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      elevation: 8.0,
      child: Container(
        //Need more height depending on auth mode, for confirm password
        height: _authMode == AuthMode.Signup
            ? deviceSize.height * .7
            : deviceSize.height * .5,
        constraints: BoxConstraints(
            minHeight: _authMode == AuthMode.Signup
                ? deviceSize.height * .7
                : deviceSize.height * .5),
        width: deviceSize.width * 0.75,
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'E-Mail'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value.isEmpty || !value.contains('@')) {
                      return 'Invalid email!';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _authData['email'] = value;
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Password'),
                  //So password isnt shown
                  obscureText: true,
                  //Controller is used in conjunction with last from filed, only in signup mode
                  controller: passwordController,
                  validator: (value) {
                    if (value.isEmpty || value.length < 5) {
                      return 'Password is too short!';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _authData['password'] = value;
                  },
                ),
                if (_authMode == AuthMode.Signup)
                  //Confrim password
                  TextFormField(
                    enabled: _authMode == AuthMode.Signup,
                    decoration: InputDecoration(labelText: 'Confirm Password'),
                    obscureText: true,
                    validator: _authMode == AuthMode.Signup
                        ? (value) {
                            //If the value in this form field matches the value in previous form field
                            if (value != passwordController.text) {
                              return 'Passwords do not match!';
                            }
                            return null;
                          }
                        : null,
                  ),
                const SizedBox(
                  height: 20,
                ),
                if (_isLoading)
                  CircularProgressIndicator()
                else
                  //This button calls the submit method
                  RaisedButton(
                    child: Text(
                        _authMode == AuthMode.Login ? 'SIGN IN' : 'SIGN UP'),
                    onPressed: _submit,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding:
                        EdgeInsets.symmetric(horizontal: 30.0, vertical: 8.0),
                    color: Theme.of(context).primaryColor,
                    textColor: Theme.of(context).primaryTextTheme.button.color,
                  ),
                if (_authMode == AuthMode.Login)
                  //Login in with google option
                  GestureDetector(
                    onTap: login,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        width: MediaQuery.of(context).size.width * .4,
                        height: MediaQuery.of(context).size.height * .05,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(
                              'assets/images/google_signin_button.png',
                            ),
                            alignment: Alignment.center,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                //Switch betweens auth modes
                FlatButton(
                  child: Text(
                      '${_authMode == AuthMode.Login ? 'SIGNUP' : 'LOGIN'} INSTEAD'),
                  onPressed: _switchAuthMode,
                  padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 4),
                  //Reduces amount of surface to tap the button
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textColor: Theme.of(context).primaryColor,
                ),
                //Change password option
                if (_authMode == AuthMode.Login)
                  FlatButton(
                    child: Text('Change Password'),
                    onPressed: () async {
                      if (emailController.text == "") {
                        setState(() {
                          showDialog<void>(
                              context: context,
                              builder: (BuildContext context) {
                                //Alert box to tell user to enter email in order to change password
                                return AlertDialog(
                                  title: Text('Change Password'),
                                  content:
                                      Text('Please enter a valid emai first.'),
                                  actions: <Widget>[
                                    FlatButton(
                                      child: Text('Ok'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ],
                                );
                              });
                        });
                      }
                      //Send an email to users email to change password
                      await _firebaseAuth
                          .sendPasswordResetEmail(email: emailController.text)
                          .then((_) {
                        showDialog<void>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Change Password'),
                                content: Text(
                                    'An email to change your password has been sent to ${emailController.text}.'),
                                actions: <Widget>[
                                  FlatButton(
                                    child: Text('Ok'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              );
                            });
                      });
                    },
                    padding:
                        EdgeInsets.symmetric(horizontal: 30.0, vertical: 4),
                    //Reduces amount of surface to tap the button
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textColor: Theme.of(context).primaryColor,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  //Overall structure and decides which screen to build
  @override
  Widget build(BuildContext context) {
    return isAuth
        ? buildAuthScreen()
        : BaseWidget(builder: (context, sizingInfo) {
            return buildUnAuthScreen();
          });
  }
}
