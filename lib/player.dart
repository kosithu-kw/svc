import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:chewie/src/chewie_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:svc/home.dart';
import 'package:video_player/video_player.dart';

import 'ad_helper.dart';



class Player extends StatefulWidget {
  final data;
  Player({required this.data});


  @override
  State<StatefulWidget> createState() {
    return _PlayerState();
  }
}

class _PlayerState extends State<Player> {
  FirebaseFirestore firestore=FirebaseFirestore.instance;

  late VideoPlayerController _videoController;
   ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _getVideoInit();
    _initVideoController();

    if(!_isInterstitialAdReady){
      _loadInterstitialAd();
    }
    _checkShowAds();
  }

  _initVideoController(){
    _videoController = VideoPlayerController.network(_videoUrl);
    _createChewieController();

    setState(() {});

    _videoController.addListener(() {
      setState(() {
        if(_videoController.value.isPlaying==true && _videoController.value.isInitialized==true){
          _isPlaying=true;
          setState(() {

          });
        }
      });
      if (_videoController.value.position ==
          _videoController.value.duration) {
      }
    });
  }

  _createChewieController(){

    _chewieController = ChewieController(
      videoPlayerController: _videoController,
      //aspectRatio: _videoController.value.aspectRatio,
      autoPlay: true,
      looping: false,
      showOptions: false,
      // Try playing around with some of these other options:

      // showControls: false,
      // materialProgressColors: ChewieProgressColors(
      //   playedColor: Colors.red,
      //   handleColor: Colors.blue,
      //   backgroundColor: Colors.grey,
      //   bufferedColor: Colors.lightGreen,
      // ),
      // placeholder: Container(
      //   color: Colors.grey,
      // ),
      // autoInitialize: true,
    );
  }

  String _videoUrl="";
  String _videoPoster="";
  String _genre="";
  String _title="";
  String _id="";

  bool _isPlaying=false;

  _getVideoInit(){
    setState(() {
      _videoUrl=widget.data['video_url'];
      _videoPoster=widget.data['poster_url'];
      _genre=widget.data['genre'];
      _title=widget.data['title'];
      _id=widget.data.id;
    });
  }
  _changeVideo(v){
    setState(() {
      _videoController.pause();
      _isPlaying=false;
      _videoUrl=v['video_url'];
      _videoPoster=v['poster_url'];
      _genre=v['genre'];
      _title=v['title'];
      _id=v.id;
    });
    _initVideoController();
  }

  bool downloading=false;
  String progressString="";

  Future<void> checkPermission()async{
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      // You can request multiple permissions at once.
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
      ].request();
      downloadFile();
      //print(statuses[Permission.storage]); // it should print PermissionStatus.granted
    }

    if(status.isGranted){
      downloadFile();
    }

  }

  Future<void> downloadFile() async {
    Dio dio = Dio();

    try {
        await dio.download(_videoUrl, "/storage/emulated/0/Download/${_title}.mp4",
            onReceiveProgress: (rec, total) {
              // print("Rec: $rec , Total: $total");

              setState(() {
                downloading = true;
                progressString = ((rec / total) * 100).toStringAsFixed(0) + "%";
              });
            }).then((value){
          setState(() {
            downloading = false;
            progressString = "Completed";
            _finishSnackBar("Downloading Success, check your download folder.", true);
          });
        });

      } catch (e) {
        setState(() {
          downloading = false;
          progressString = "Uncompleted";
          _finishSnackBar("Downloading failed, check your internet connection.", false);
        });
      }

    // print("Download completed");
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  void _finishSnackBar(v, _status) {
    _scaffoldKey.currentState!.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(_status ? Icons.check_circle : Icons.error, color: Colors.white, size: 20,),
              SizedBox(width: 5,),
              Text(v)
            ],
          ),

          duration: Duration(seconds: 5),
        ));
  }

  _checkShowAds(){
    firestore.collection("Ads").snapshots().forEach((e) {
      var data=e.docs.first.data();
      if(data['show_inter_download']){
        setState(() {
          _showInterDownload=true;
        });
      }
      if(data['show_inter_nav']){
        setState(() {
          _showInterNav=true;
        });
      }
      if(data['show_inter_change_video']){
        setState(() {
          _showInterChangeVideo=true;
        });
      }
    });
  }


  bool _downloadAds=false;
  bool _goHomeAds=false;
  bool _changeVideoAds=false;
  int _changeCount=0;

  bool _showInterDownload=false;
  bool _showInterNav=false;
  bool _showInterChangeVideo=false;

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

              if(_changeVideoAds){
                ad.dispose();
                _loadInterstitialAd();
                setState(() {
                  _changeVideoAds=false;
                  _isInterstitialAdReady=false;
                  _videoController.play();
                });
              }

              if(_goHomeAds){
                Navigator.push(context, MaterialPageRoute(builder: (context)=>Home()));
              }

              if(_downloadAds){
                ad.dispose();
                _loadInterstitialAd();
                checkPermission();
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


  @override
  void dispose() {
    _videoController.dispose();
    _chewieController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          primaryColor: Color(0x204665).withOpacity(1.0)
      ),
      title: _genre,

      home: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          leading: IconButton(
            onPressed: (){
              Navigator.pop(context);
            },
            icon: Icon(Icons.arrow_back),
          ),
          title: Text(_genre, style: TextStyle(color: Colors.white),),
          backgroundColor:  Color(0x204665).withOpacity(1.0),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Color(0x204665).withOpacity(1.0),
          onPressed: (){
              if(_isInterstitialAdReady==true && _showInterNav==true){
                setState(() {
                  _goHomeAds=true;
                });
                _videoController.pause();
                _videoController.dispose();
                _chewieController?.dispose();
                _interstitialAd?.show();

              }else{
                _videoController.pause();
                _videoController.dispose();
                _chewieController?.dispose();
                Navigator.push(context, MaterialPageRoute(builder: (context)=>Home()));
              }

          },
          child:Icon(Icons.home)
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              flex: 5,
              child: Container(
                  color: Colors.black,
                  child: Column(
                    children: [
                      Expanded(
                        flex: 9,
                          child: Center(
                              child: _isPlaying
                                  ? AspectRatio(
                                aspectRatio: _videoController.value.aspectRatio,
                                child: Chewie(
                                  controller: _chewieController!,
                                ),
                              )
                                  : AspectRatio(
                                aspectRatio: _videoController.value.aspectRatio,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children:  [
                                    CircularProgressIndicator(
                                      color: Colors.white,
                                      backgroundColor: Colors.amber,
                                    ),
                                    SizedBox(height: 20),
                                    Text('Loading', style: TextStyle(color: Colors.white),),
                                  ],
                                ),
                              )
                          )
                      ),
                      SizedBox(height: 10,),
                      Expanded(
                        flex: 1,
                          child: Container(
                            padding: EdgeInsets.only(top: 5),
                            child: Text(_title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
                          )
                      )
                    ],
                  )
              ),
            ),
            SizedBox(height: 10,),
            Expanded(
              flex: 1,
                     child: Card(
                     child: Container(
                       padding: EdgeInsets.only(left: 20, right: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [


                            InkWell(
                              onTap: (){
                                if(!downloading){
                                  _videoController.pause();
                                  if(_isInterstitialAdReady==true && _showInterDownload==true){
                                      setState(() {
                                        _downloadAds=true;
                                      });
                                      _interstitialAd?.show();
                                  }else{
                                    checkPermission();
                                  }
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
                                  child: !downloading
                                      ?
                                  Icon(Icons.download, color: Colors.black,)
                                      :
                                  Container(
                                      child: Row(
                                        children: [
                                          Icon(Icons.downloading, color: Colors.black,),
                                          Text("${progressString}", style: TextStyle(color: Colors.black),)
                                        ],
                                      )
                                  )
                              )

                            ),
                            IconButton(
                                onPressed: (){
                                  setState(() {
                                    if(_videoController.value.isPlaying){
                                      _videoController.pause();
                                    }else{
                                      _videoController.play();
                                    }
                                  });
                                },
                                icon: Icon(_videoController.value.isPlaying ? Icons.pause_circle : Icons.play_circle)
                            ),
                            IconButton(
                                onPressed: (){
                                  _chewieController!.enterFullScreen();
                                },
                                icon: Icon(Icons.fullscreen)
                            )

                          ],
                        ),
                      )
                      )

            ),
            Expanded(
              flex: 4,
            child :Container(
              height: 220,
                margin: EdgeInsets.only(bottom: 10),
                child: Container(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.only(top: 10, left: 10,bottom: 10),
                        child: Text("Suggested video clips", style: TextStyle(fontWeight: FontWeight.bold),),
                      ),
                      Container(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: firestore.collection("Videos").where("genre", isEqualTo: _genre).snapshots(),
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

                                            bool _isFavorite=v[i]['favorites'].contains("");
                                            return Row(
                                              children: [
                                                Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  width: 160,
                                                  child: Card(
                                                    child: InkWell(
                                                      onTap: (){
                                                          if(_isPlaying){

                                                            if(_changeCount >=2){
                                                              _changeCount=0;
                                                            }else{
                                                              _changeCount++;
                                                            }

                                                            if(_isInterstitialAdReady==true && _showInterChangeVideo==true && _changeCount==2){
                                                              _videoController.pause();
                                                              setState(() {
                                                                _changeVideoAds=true;
                                                              });
                                                              _interstitialAd?.show();

                                                            }else{
                                                              _changeVideo(v[i]);

                                                            }

                                                          }
                                                      },
                                                      child: Container(
                                                          decoration: BoxDecoration(
                                                            color: Colors.black,
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
                                                                /*
                                                                Align(
                                                                  alignment: Alignment.topRight,
                                                                  child: Container(
                                                                      margin: EdgeInsets.all(5),
                                                                      child: Row(
                                                                        mainAxisAlignment: MainAxisAlignment.end,
                                                                        children: [

                                                                          Row(
                                                                            children: [
                                                                              Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.white,),
                                                                              Text("${v[i]['favorites'].length}", style: TextStyle(color: Colors.white))
                                                                            ],
                                                                          ),
                                                                        ],
                                                                      )
                                                                  ),
                                                                ),

                                                                 */

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
                      )
                    ],
                  ),
                )
              )
            )



          ],
        ),
      ),
    );
  }
}