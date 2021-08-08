
import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:svc/drawer.dart';
import 'package:svc/home.dart';
import 'package:video_player/video_player.dart';
import 'package:flick_video_player/flick_video_player.dart';

import 'ad_helper.dart';
import 'auth.dart';




class Player extends StatefulWidget {
  final data;
  const Player({Key? key, required this.data}) : super(key: key);

  @override
  _PlayerState createState() => _PlayerState();
}

class _PlayerState extends State<Player> {

  FirebaseFirestore firestore= FirebaseFirestore.instance;

  late FlickManager flickManager;

  _checkLogin()async{
    var currentUser=await FirebaseAuth.instance.currentUser;
    if(currentUser.uid !=null){
      setState(() {
        _email=currentUser.email;
        _isLogin=true;
      });
    }
  }
  String _email="";
  bool _isLogin=false;

  String _url="";
  String _vId="";
  String _genre="";
  String _title="";
  bool _isVideoReady=false;

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIOverlays(
        [SystemUiOverlay.bottom, SystemUiOverlay.top]);
    _checkLogin();
    setState(() {
      _isVideoReady=true;
      _url=widget.data['video_url'];
      _vId=widget.data.id;
      _genre=widget.data['genre'];
      _title=widget.data['title'];
    });
    _checkFavorite(widget.data.id);
    _getVideo();

    if(!_isInterstitialAdReady){
      _loadInterstitialAd();
    }
    _checkShowAds();

    super.initState();
  }

  late VideoPlayerController _videoController =VideoPlayerController.network(_url);

  _getVideo(){
    flickManager = FlickManager(
          videoPlayerController:
          _videoController
    );

  }


  bool _isFavorite=false;
  int _favoritesLength=0;

  _checkFavorite(id){
    firestore.collection("Videos").doc(id).get().then((v){
      setState(() {
        _favoritesLength=v.data()['favorites'].length;
      });
      if(v.data()['favorites'].contains(_email)){
        setState(() {
          _isFavorite=true;
        });
      }else{
        _isFavorite=false;
      }
    });
  }


  _doFavorite(){
    if(_isFavorite){
      setState(() {
        _isFavorite=false;
      });
    }else{
      setState(() {
        _isFavorite=true;
      });
    }
    var db=firestore.collection("Videos").doc(_vId);
    db.get().then((v){
      var oldData=v.data()['favorites'];
      bool isLike=oldData.contains(_email);
      if(isLike){
        db.update({
          "favorites" :FieldValue.arrayRemove([_email])
        }).then((value){
          _checkFavorite(_vId);
        });

      }else{
        db.update({
          "favorites" :FieldValue.arrayUnion([_email])
        }).then((value){
          _checkFavorite(_vId);
        });

      }
    });
  }

  _checkShowAds(){
    firestore.collection("Ads").snapshots().forEach((e) {
      var data=e.docs.first.data();
      if(data['show_inter_download']){
        setState(() {
          _showInterDownload=true;
        });
      }else if(data['show_inter_nav']){
        setState(() {
          _showInterNav=true;
        });
      }
    });
  }

  bool _showInterDownload=false;
  bool _showInterNav=false;

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          this._interstitialAd = ad;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {

              if(!_downloadAds){
                Navigator.push(context, MaterialPageRoute(builder: (context)=>Home(data: _indexForAds)));

              }else{
                ad.dispose();
                _loadInterstitialAd();
                downloadFile();
                setState(() {
                  _downloadAds=false;
                  _isInterstitialAdReady=false;
                  _videoController.play();
                });



              }
            },
          );

          _isInterstitialAdReady = true;
        },
        onAdFailedToLoad: (err) {
          print('Failed to load an interstitial ad: ${err.message}');
          _isInterstitialAdReady = false;
        },
      ),
    );
  }

  bool _downloadAds=false;
  bool downloading=false;
  String progressString="";

  Future<void> downloadFile() async {

    var status = await Permission.storage.status;
    if (!status.isGranted) {
      // You can request multiple permissions at once.
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
      ].request();
      //print(statuses[Permission.storage]); // it should print PermissionStatus.granted
    }

    print(status);

    Dio dio = Dio();

    try {
      await dio.download(_url, "/storage/emulated/0/Download/${_title}.mp4",
          onReceiveProgress: (rec, total) {
           // print("Rec: $rec , Total: $total");

            setState(() {
              downloading = true;
              progressString = ((rec / total) * 100).toStringAsFixed(0) + "%";
            });
          });
    } catch (e) {
      print(e);
    }

    setState(() {
      downloading = false;
      progressString = "Completed";
      _finishSnackBar();
    });
   // print("Download completed");
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  void _finishSnackBar() {
    _scaffoldKey.currentState!.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20,),
              SizedBox(width: 5,),
              Text("Downloading Success, check your download folder.")
            ],
          ),

          duration: Duration(seconds: 5),
        ));
  }


  @override
  void dispose() {
    flickManager.dispose();
    _interstitialAd?.dispose();

    super.dispose();
  }

  int _indexForAds=0;

  void onTabTapped(int index) {
    flickManager.dispose();
    if(_isInterstitialAdReady==true && _showInterNav==true){
      setState(() {
        _indexForAds=index;
      });
      _interstitialAd?.show();
    }else{
      Navigator.push(context, MaterialPageRoute(builder: (context)=>Home(data: index)));

    }
  }
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {

    return  MaterialApp(
      theme: ThemeData(
          primaryColor: Color(0x204665).withOpacity(1.0),
        splashColor: Colors.amber[900],
      ),
      title: _genre,
      home: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          centerTitle: false,
          title: Text(_genre, style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
          /*
          actions: [
            IconButton(
                onPressed: (){
                    flickManager.dispose();
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>Home(data: "1")));
                },
                icon: Icon(Icons.home)
            )
          ],

           */

        ),
        drawer: SDrawer(),
        /*
        floatingActionButton: FloatingActionButton(
          backgroundColor: Color(0x204665).withOpacity(1.0),
          onPressed: (){
            flickManager.dispose();
            Navigator.push(context, MaterialPageRoute(builder: (context)=>Home()));
          },
          child: Icon(Icons.home),
        ),

         */
        body: SafeArea(
          child: Stack(
            children: [
              Container(
                child: Column(
                  children: [
                    Container(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(0x204665).withOpacity(1.0)
                        ),
                        child: Column(
                          children: [
                            Container(
                                child: FlickVideoPlayer(
                                  flickManager: flickManager ,
                                )
                            ),
                            Container(
                              margin:EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                      child: Container(
                                        child: Text("${_title}", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),),
                                      )
                                  ),
                                  SizedBox(width: 10,),
                                  Container(
                                    child: Row(
                                      children: [
                                            InkWell(
                                              onTap: (){
                                                if(_isLogin){
                                                  _doFavorite();
                                                }else{
                                                  _videoController.pause();
                                                  Navigator.push(context, MaterialPageRoute(builder: (context)=>Auth()))
                                                  .then((value) {
                                                    Navigator.push(context, MaterialPageRoute(builder: (context)=>super.widget));
                                                  });
                                                }
                                              },
                                              child: Row(
                                                children: [
                                                  Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.yellowAccent,),
                                                  Text(_favoritesLength.toString(), style: TextStyle(color: Colors.yellowAccent),),

                                                ],
                                              ),
                                            ),

                                       SizedBox(width: 10,),
                                       InkWell(
                                         onTap: (){
                                           _videoController.pause();
                                           if(!downloading){
                                             if(_showInterDownload==true && _isInterstitialAdReady==true){
                                               setState(() {
                                                 _downloadAds=true;
                                               });
                                               _interstitialAd?.show();
                                             }else{
                                               downloadFile();
                                             }
                                           }
                                         },
                                         child: !downloading
                                             ?
                                          Icon(Icons.download, color: Colors.white,)
                                             :
                                           Container(
                                               child: Row(
                                                 children: [
                                                   Icon(Icons.downloading, color: Colors.white,),
                                                   Text("${progressString}", style: TextStyle(color: Colors.white),)
                                                 ],
                                               )
                                           )
                                         ,
                                       )
                                      ],
                                    ),
                                  ),

                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20,),
                   Container(
                     padding: EdgeInsets.only(left: 5, right: 5),
                     child:  Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Container(
                           child: Row(
                             children: [
                               Icon(Icons.playlist_add_check_outlined),
                               Text("Suggested Video Clips", style: TextStyle(fontWeight: FontWeight.bold),),
                             ],
                           ),
                         ),
                         SizedBox(height: 5,),
                         Suggested(data: widget.data)
                       ],
                     )
                   )
                  ],

                  )
              )
            ],
          ),
        ) ,
        bottomNavigationBar: BottomNavigationBar(
            onTap: onTabTapped, // new
            currentIndex: _currentIndex,
          items: [
            BottomNavigationBarItem(
              icon: new Icon(Icons.home),
              title: new Text('S V C'),
            ),
            BottomNavigationBarItem(
              icon: new Icon(Icons.movie_filter),
              title: new Text('Videos'),
            ),
            BottomNavigationBarItem(
                icon: Icon(Icons.favorite),
                title: Text('Favorites')
            ),

          ],
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          backgroundColor: Color(0x204665).withOpacity(1.0),
        ),
      ),

    );
  }
}




class Suggested extends StatefulWidget {
  final data;
  const Suggested({Key? key, required this.data}) : super(key: key);

  @override
  _SuggestedState createState() => _SuggestedState();
}

class _SuggestedState extends State<Suggested> {
  FirebaseFirestore firestore=FirebaseFirestore.instance;
  _checkLogin()async{
    var currentUser=await FirebaseAuth.instance.currentUser;
    if(currentUser.uid !=null){
      setState(() {
        _email=currentUser.email;
        _isLogin=true;
      });
    }
  }
  String _email="";
  bool _isLogin=false;

  @override
  void initState() {
    _checkLogin();
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return  Container(
          child: StreamBuilder<QuerySnapshot>(
            stream: firestore.collection("Videos").where("genre", isEqualTo: widget.data['genre']).snapshots(),
            builder: (context, s){
              if(s.hasData){
                var v=s.data!.docs;

                return Container(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 160,
                        child: ListView.builder(
                            scrollDirection: Axis.horizontal,

                            itemCount: v.length,
                            itemBuilder: (_,i){
                              bool _isFavorite=v[i]['favorites'].contains(_email);
                              return Row(
                                children: [
                                  Container(
                                    width: 160,
                                    child: Card(
                                      child: InkWell(
                                        onTap: (){
                                          Navigator.push(context, MaterialPageRoute(builder: (context)=>Player(data: v[i])));
                                        },
                                        child: Container(
                                            decoration: BoxDecoration(
                                                color: Colors.black
                                            ),
                                            child: Container(
                                              child: Stack(
                                                children: [
                                                  Container(
                                                    child: CachedNetworkImage(
                                                      imageUrl: "${v[i]['poster_url']}",
                                                      progressIndicatorBuilder: (context, url, downloadProgress) =>
                                                          Center(
                                                            child: CircularProgressIndicator(
                                                              value: downloadProgress.progress,
                                                              color: Colors.amber[500],
                                                              backgroundColor: Colors.amber[900],
                                                            ),
                                                          ),
                                                      errorWidget: (context, url, error) => Icon(Icons.error),
                                                    ),
                                                  ),
                                                  Align(
                                                    alignment: Alignment.topRight,
                                                    child: Container(
                                                        margin: EdgeInsets.all(5),
                                                        child: Row(
                                                          mainAxisAlignment: MainAxisAlignment.end,
                                                          children: [

                                                            Row(
                                                              children: [
                                                                Icon(_isFavorite ? Icons.favorite: Icons.favorite_border, color: Colors.white,),
                                                                Text("${v[i]['favorites'].length}", style: TextStyle(color: Colors.white),)
                                                              ],
                                                            ),
                                                          ],
                                                        )
                                                    ),
                                                  ),

                                                  Align(
                                                      alignment: Alignment.bottomCenter,
                                                      child:
                                                      Container(
                                                        width: MediaQuery.of(context).size.width,
                                                        padding: EdgeInsets.all(5),
                                                        decoration: BoxDecoration(
                                                            color: Colors.black.withOpacity(0.8),
                                                            borderRadius: BorderRadius.circular(5)

                                                        ),
                                                        child: Text(v[i]['title'], style: TextStyle(height: 1.5, color: Colors.white)),
                                                      )
                                                  )
                                                ],
                                              ),
                                            )
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }
                        ),
                      )
                    ],
                  ),
                );
              }else{
                return Center(
                  child: CircularProgressIndicator(
                    color: Colors.amber[500],
                    backgroundColor: Colors.amber[900],
                  ),
                );
              }
            },
          ),
        );


  }
}
