import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:svc/drawer.dart';
import 'package:svc/gener_videos.dart';
import 'package:svc/player.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'ad_helper.dart';

class Genres extends StatefulWidget {
  const Genres({Key? key}) : super(key: key);

  @override
  _GenresState createState() => _GenresState();
}

class _GenresState extends State<Genres> {
  FirebaseFirestore firestore=FirebaseFirestore.instance;



  final _title="Short Video Clips";
  bool _showAppBar=true;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          primaryColor: Color(0x204665).withOpacity(1.0)
      ),
      title: _title,
      home: Scaffold(
        appBar: _showAppBar ? AppBar(
          title: Text(_title, style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
        ): null,
        drawer: SDrawer(),
        body: SafeArea(
          child: Stack(
            children: [
                Container(
                  child: GData(),
                )
            ],
          ),
        )
      ),

    );
  }
}

class GData extends StatefulWidget {
  const GData({Key? key}) : super(key: key);

  @override
  _GDataState createState() => _GDataState();
}

class _GDataState extends State<GData> {
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

  _checkShowAds(){
     firestore.collection("Ads").snapshots().forEach((e) {
        var data=e.docs.first.data();
        if(data['show_banner_home']){
          _callBanner();
        }
     });
  }

  @override
  void initState() {
    _checkLogin();
    _checkShowAds();
    //_callBanner();
  }

  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;

  _callBanner(){
    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          print('Failed to load a banner ad: ${err.message}');
          _isBannerAdReady = false;
          ad.dispose();
        },
      ),
    );

    _bannerAd.load();
  }
  @override
  void dispose() {
    _bannerAd.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Stack(
          children: [
            Center(
              child: Container(
                decoration: _isBannerAdReady ? BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      width: 55,
                      color: Colors.white
                    )
                  )
                ) : null,
                child: StreamBuilder<QuerySnapshot>(
                  stream: firestore.collection("Genre").orderBy('created_at', descending: true).snapshots(),
                  builder: (context, s){
                    if(s.hasData){
                      var g=s.data!.docs;
                      return ListView.builder(
                          itemCount: g.length,
                          itemBuilder: (_,i){
                            return Padding(
                              padding: EdgeInsets.all(1.0),
                              child: Card(
                                child: Container(
                                  padding: EdgeInsets.all(5),
                                  child: Column(
                                    children: [
                                      Container(
                                          child: InkWell(
                                            onTap: (){
                                              Navigator.push(context, MaterialPageRoute(builder: (context)=>GenerVideos(data: g[i])));
                                            },
                                            child: Row(
                                              children: [
                                                Icon(Icons.playlist_add_check, color: Colors.black,),
                                                Text(g[i]['title'], style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),)
                                              ],
                                            ),
                                          )
                                      ),
                                      Container(
                                        child: StreamBuilder<QuerySnapshot>(
                                          stream: firestore.collection("Videos").where("genre", isEqualTo: g[i]['title']).snapshots(),
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
                                                                  decoration: BoxDecoration(
                                                                    borderRadius: BorderRadius.circular(20),
                                                                  ),
                                                                  width: 160,
                                                                  child: Card(
                                                                    child: InkWell(
                                                                      onTap: (){
                                                                        Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (context)=>Player(data: v[i])));

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
                                ),
                              ),
                            );
                          }
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
              ),
            ),
            if (_isBannerAdReady)
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: _bannerAd.size.width.toDouble(),
                  height: _bannerAd.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd),
                ),
              ),
          ],
        )
    );
  }
}
