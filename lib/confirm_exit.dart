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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        child: TextButton(
                          child: Text("QUICK",style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          onPressed: (){
                            exit(0);
                          },
                        ),
                      ),
                      Container(
                        child: TextButton(
                          child: Text("CONTINUED", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
                          onPressed: (){
                            Navigator.push(context, MaterialPageRoute(builder: (context)=>Home()));
                          },
                        ),
                      )
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
