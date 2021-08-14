import 'package:flutter/material.dart';
import 'package:svc/auth.dart';
import 'package:svc/confirm_exit.dart';
import 'package:svc/drawer.dart';
import 'package:svc/genres.dart';
import 'package:svc/favorite.dart';
import 'package:svc/videos.dart';


class Home extends StatefulWidget {
  final data;
  const Home({Key? key, this.data=0}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _title="S V C";
  final _des="Short Video Clips";

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  int _currentIndex = 0;
  final List<Widget> _children = [
    Genres(),
    Videos(),
    //Favorite(),
  ];

  @override
  void initState() {
    setState(() {
      _currentIndex=widget.data;
    });
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      home: Scaffold(
        body:_children[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          onTap: onTabTapped, // new
          currentIndex: _currentIndex,  // this will be set when a new tab is tapped
          items: [
            BottomNavigationBarItem(
              icon: new Icon(Icons.home),
              title: new Text('S V C'),
            ),
            BottomNavigationBarItem(
              icon: new Icon(Icons.movie_filter),
              title: new Text('Videos'),
            ),
            /*
            BottomNavigationBarItem(
                icon: Icon(Icons.favorite),
                title: Text('Favorites')
            ),

             */

          ],
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          backgroundColor: Color(0x204665).withOpacity(1.0),
        ),
      ),
    );
  }
}
