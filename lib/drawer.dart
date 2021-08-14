import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:svc/auth.dart';
import 'package:svc/favorite.dart';
import 'package:svc/genres.dart';
import 'package:svc/videos.dart';

import 'home.dart';

class SDrawer extends StatefulWidget {
  const SDrawer({Key? key}) : super(key: key);

  @override
  _SDrawerState createState() => _SDrawerState();
}

class _SDrawerState extends State<SDrawer> {


  String _name="Guest";
  String _email="guest@svc";
  String _picture="";
  bool _isLogin=false;

   _checkLogin()async{
     var currentUser=await FirebaseAuth.instance.currentUser;
     if(currentUser.uid !=null){
       setState(() {
         _email=currentUser.email;
         _isLogin=true;
         _name=currentUser.displayName;
         _picture=currentUser.photoURL;
       });
     }
   }
   googleSignout()async{
     await FirebaseAuth.instance.signOut().then((value){
       setState(() {
         _email="guest@svc";
         _isLogin=false;
         _name="Guest";
         _picture="";
       });
     });
   }
   @override
   void initState() {
     _checkLogin();
     // TODO: implement initState
     super.initState();
   }

  @override
  Widget build(BuildContext context) {
    return Drawer(
        child: ListView(
            children: [
              UserAccountsDrawerHeader(
                  accountName: Text("S V C"),
                  accountEmail: Text("Short Video Clips"),
                currentAccountPicture: CircleAvatar(
                  radius: 30,
                  child: ClipOval(
                    child: _isLogin ? Image.network(_picture) : Image.asset("images/icon.png"),
                  ),
                )
              ),
             Card(
               child: ListTile(
                 onTap: (){
                   Navigator.push(context, MaterialPageRoute(builder: (context)=>Genres()));
                 },
                 title: Text("Home"),
                 trailing: Icon(Icons.home),
               ),
             ),
              Card(
                child: ListTile(
                  onTap: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>Videos()));
                  },
                  title: Text("Videos"),
                  trailing: Icon(Icons.movie_filter_sharp),
                ),
              ),
              /*
              Card(
                child: ListTile(
                  onTap: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>Favorite()));
                  },
                  title: Text("Favorites"),
                  trailing: Icon(Icons.favorite),
                ),
              ),

               */
             /*
             if(!_isLogin) Card(
               child: ListTile(
                 onTap: (){
                   Navigator.push(context, MaterialPageRoute(builder: (context)=>Auth())).then((value){
                     setState(() {

                     });
                   });
                 },
                 title: Text("Sign In"),
                 trailing: Icon(Icons.login),

               ),
             ),

              */

              if(_isLogin) Card(
                child: ListTile(
                  onTap: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>Auth())).then((value){
                      setState(() {

                      });
                    });
                  },
                  title: Text("Profile"),
                  trailing: Icon(Icons.account_circle),

                ),
              ),

              if(_isLogin) Card(
                child: ListTile(
                  onTap: (){
                    googleSignout();
                  },
                  title: Text("Sign Out"),
                  trailing: Icon(Icons.logout),

                ),
              )
            ],
        ),
    );
  }
}
