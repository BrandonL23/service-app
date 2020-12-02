import 'package:cse442_App/user%20model/user_listings_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:flappy_search_bar/flappy_search_bar.dart';
import '../user model/user_model.dart';
import 'new_listing_page.dart';
import 'package:cse442_App/user%20model/user_model.dart';
import 'search_bar.dart';

class HomeScreen extends StatefulWidget {
  @override
  final UserModel user;
  HomeScreen({this.user});
  HomeScreenState createState() => HomeScreenState(user: user);
}

// Used to send verification email to user to add verification badge to their profile.
Future<bool> sendVerifyEmail(String _userId, String _email) async {
  print("Sending Verification Email");

  final String apiUrl = "https://job-5cells.herokuapp.com/verify";
  final response = await http.post(apiUrl,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: json.encode({"userId": _userId, "email": _email}));
  print(response.body);
  if (response.statusCode == 200) {
    return true;
  } else {
    return false;
  }
}

/*
  Home Screen Widget to be used when in the "Home" tab of the Navigation bar.
  This widget will contain the Search Bar used to find listings within the app.
*/
class HomeScreenState extends State<HomeScreen> {
  final UserModel user;
  HomeScreenState({this.user});

  final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;
  Position _userPos;

  void getLocation() async {
    final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;

    geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((Position position) async {
      print(position);
      final String location =
      await _getAddressFromLatLng(position.latitude, position.longitude);
      print(location);
      final String apiUrl = "https://job-5cells.herokuapp.com/update/location";
      final response = await http.post(apiUrl,
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: json.encode({
            "userId": user.id,
            "lat": position.latitude,
            "long": position.longitude,
            "location": location
          }));

      setState(() {
        _userPos = position;
        user.lat = position.latitude;
        user.long = position.longitude;
        user.location = location;
      });
    }).catchError((e) {
      print(e);
    });
  }

  Future<String> _getAddressFromLatLng(double lat, double long) async {
    try {
      List<Placemark> p = await geolocator.placemarkFromCoordinates(lat, long);

      Placemark place = p[0];
      print("place" + place.toString());
      return "${place.locality}, ${place.postalCode}, ${place.country}";
    } catch (e) {
      print(e);
    }
  }

  bool pressON = false;
  bool _firstPress = true;

  Widget getVerificationButton(){
    if (user.verify == null || user.verify == false){
      return Stack(
        children: [
          Container(
            padding: EdgeInsets.all(5),
            alignment: Alignment.center,
            child: Text(
              "Your email has not been verified",
              style: TextStyle(color: Colors.red),
            ),
          ),
          // Email button to send email verification link
          Container(
              child: RaisedButton(
                textColor: Colors.white,
                child: pressON
                    ? Text("Verification email has been sent.")
                    : Text("Click here to send verification email."),
                onPressed: () async {
                  if (_firstPress) {
                    print(user.id);
                    print(user.email);
                    final bool emailSent = await sendVerifyEmail(
                        user.id.toString(), user.email.toString());
                    print(emailSent.toString());
                    if (emailSent) _firstPress = false;
                    setState(() {
                      pressON = !pressON;
                    });
                  }
                },
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                color: Colors.blue,
              )
          ),
        ],
      );
    } else {
      return Container();
    }
  }

  String dropdownValue = 'English';
  final dropdownLanguages = [
    'English',
    'Spanish',
    'Arabic',
    'Armenian',
    'Bengali',
    'Cantonese',
    'Creole',
    'Croatian',
    'French',
    'German',
    'Greek',
    'Gujarati',
    'Hebrew',
    'Hindi',
    'Italian',
    'Japanese',
    'Korean',
    'Mandarin',
    'Persian',
    'Polish',
    'Portuguese',
    'Punjabi',
    'Russian',
    'Serbian',
    'Tagalog',
    'Tai–Kadai',
    'Tamil',
    'Telugu',
    'Urdu',
    'Vietnamese',
    'Yiddish',
    'Pig Latin']
      .map<DropdownMenuItem<String>>((String value) {
    return DropdownMenuItem<String>(
      value: value,
      child: Text(value),
    );
  }).toList();
  bool services = true;

  List<UserListingsModel> initList;
  List<UserListingsModel> searchList;
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      asyncGet();
    });
  }

  void asyncGet() async {
    final List<UserListingsModel> list = await getListing();
    setState(() {
      initList = list;
      print(initList.length);
    });
  }

  Future<List<UserListingsModel>> getListing() async {
    print("Getting listings");

    String apiUrl = '';
    if (services){
      apiUrl = "https://job-5cells.herokuapp.com/allListings";
    } else {
      apiUrl = "https://job-5cells.herokuapp.com/allRequest";
    }
    final response = await http.get(apiUrl);

    final String temp = response.body;
    return userListingsModelFromJson(temp);
  }

  Future<List<UserListingsModel>> search(String text) async {
    List<UserListingsModel> searchedListings = [];
    await Future.delayed(Duration(seconds: 3));
    print(dropdownValue.toLowerCase());
    for (int i = 0; i < initList.length; i++) {
      print(initList[i].language.toLowerCase());
      if (initList[i].language.toLowerCase() == dropdownValue.toLowerCase()){
        if (initList[i]
            .jobType
            .toString()
            .toLowerCase()
            .contains(text.toLowerCase())) {
          searchedListings.add(initList[i]);
        } else if (initList[i]
            .description
            .toString()
            .toLowerCase()
            .contains(text.toLowerCase())) {
          searchedListings.add(initList[i]);
        } else if (initList[i]
            .owner
            .toString()
            .toLowerCase()
            .contains(text.toLowerCase())) {
          searchedListings.add(initList[i]);
        } else if (initList[i]
            .language
            .toString()
            .toLowerCase()
            .contains(text.toLowerCase())) {
          searchedListings.add(initList[i]);
        }
      }
    }

    return searchedListings;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Flex(
        direction: Axis.vertical,
        children: [
          // Email Verification Banner
          getVerificationButton(),
          Flexible(
            child: SearchBar<UserListingsModel>(
              crossAxisCount: 1,
              icon: Icon(Icons.search,),
              searchBarPadding: EdgeInsets.symmetric(horizontal: 10),
              mainAxisSpacing: 0,
              hintText: "Search",
              iconActiveColor: Colors.blue,
              cancellationWidget: Text('Cancel'),
              header: Container(
                  decoration: BoxDecoration(
                      border: Border(
                          bottom: BorderSide(width: 2, color: Colors.grey[300])
                      )
                  ),
                  width: double.infinity,
                  child: ButtonBar(
                    alignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 150,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.blue,
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: DropdownButton<String>(
                          isExpanded: true,
                          dropdownColor: Colors.blue,
                          underline: SizedBox(),
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20
                          ),
                          value: dropdownValue,
                          icon: Icon(Icons.arrow_downward),
                          iconEnabledColor: Colors.white,
                          onChanged: (String newValue) {
                            setState(() {dropdownValue = newValue;});
                          },
                          items: dropdownLanguages,
                        ),
                      ),
                      ButtonTheme(
                        minWidth: 150,
                        height: 50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: RaisedButton(
                          color: Colors.blue,
                          child: Text(
                            services ? "Services" : "Requests",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                            ),
                          ),
                          onPressed: () async {
                            services = !services;
                            initList = await getListing();
                            setState(() {});
                          },
                        ),
                      )
                    ],
                  )
              ),
              onError: (error) {
                return Center(
                  child: Text("Error occurred : $error"),
                );
              },
              emptyWidget: Center(child: Text("No results found")),
              loader: Center(
                child: Text(
                  "loading...",
                  style: TextStyle(fontSize: 20),
                ),
              ),
              // Creates a delayed screen for the listings to prevent null error when loading the listings
              suggestions: initList == null ? [] : initList,
              textStyle:
              TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
              onSearch: search,
              onItemFound: (UserListingsModel listing, int index) {
                return Container(
                  decoration: BoxDecoration(
                      border: Border(
                          bottom: BorderSide(width: 2, color: Colors.grey[300])
                      )
                  ),
                  child: ListTile(
                    title: Text(listing.jobType,
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 20)),
                    subtitle: Text(listing.description,
                        style: TextStyle(color: Colors.black)),
                    // tileColor: Colors.blue,
                    leading: Icon(
                      Icons.description,
                      color: Colors.blue,
                    ),
                    trailing: Icon(
                      Icons.keyboard_arrow_right,
                      size: 30,
                      color: Colors.blue,
                    ),
                    contentPadding: EdgeInsets.all(10),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => Detail(
                            listing: listing,
                          )));
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print(user);
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => NewListing(user: user)));
        },
        child: Icon(Icons.post_add),
      ),
    );
  }
}