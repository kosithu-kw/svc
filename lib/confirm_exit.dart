import 'dart:io';

import 'package:flutter/material.dart';
import 'package:svc/home.dart';


class AppExit extends StatelessWidget {
  const AppExit({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          primaryColor: Color(0x204665).withOpacity(1.0)
      ),
      home: Scaffold(
        backgroundColor: Color(0x204665).withOpacity(1.0),

        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Text("S V C", style: TextStyle(color: Colors.amber[500], fontWeight: FontWeight.bold, fontSize: 35),),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  margin: EdgeInsets.only(bottom: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [

                      Container(
                        child: TextButton(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.home, color: Colors.white, size: 17,),
                              SizedBox(width: 5,),
                              Text("HOME", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
                            ],
                          ),
                          onPressed: (){
                            Navigator.push(context, MaterialPageRoute(builder: (context)=>Home()));
                          },
                        ),
                      ),
                      Container(
                        child: TextButton(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.movie_filter, color: Colors.white, size: 17,),
                              SizedBox(width: 5,),
                              Text("VIDEOS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
                            ],
                          ),
                          onPressed: (){
                            Navigator.push(context, MaterialPageRoute(builder: (context)=>Home(data: 1)));
                          },
                        ),
                      ),
                      Container(
                        child: TextButton(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.exit_to_app, color: Colors.white, size: 17,),
                              SizedBox(width: 5,),
                              Text("QUIT",style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          onPressed: (){
                            exit(0);
                          },
                        ),
                      ),
                    ],
                  ),
                )
              )
            ],
          ),
        ),
      ),
    );
  }
}
