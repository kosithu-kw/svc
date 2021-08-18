import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:svc/player.dart';

import 'ad_helper.dart';
import 'confirm_exit.dart';
import 'drawer.dart';
import 'home.dart';

class Videos extends StatefulWidget {
  const Videos({Key? key}) : super(key: key);

  @override
  _VideosState createState() => _VideosState();
}

class _VideosState extends State<Videos> {
  final _title="Videos";
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
    _callBanner();
    /* firestore.collection("Ads").snapshots().forEach((e) {
      var data=e.docs.first.data();
      if(data['show_banner_videos']){

      }
    });

     */
  }

  @override
  void initState() {
   // _checkLogin();
    // TODO: implement initState
    _checkShowAds();
    //_callBanner();
    super.initState();
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
    return WillPopScope(
        onWillPop: ()async{
          return await Navigator.of(context).push(MaterialPageRoute(builder: (context)=> AppExit()));
        },
        child :MaterialApp(
      theme: ThemeData(
          primaryColor: Color(0x204665).withOpacity(1.0)
      ),
      title: _title,
      home: Scaffold(
        appBar: AppBar(
          title: Text(_title, style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
        ),
        drawer: SDrawer(),
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Container(
                  decoration: BoxDecoration(
                      border: Border(
                          top: BorderSide(
                              width: 50,
                              color: Colors.white
                          )
                      )
                  ),
                  padding: EdgeInsets.all(5),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: firestore.collection("Videos").orderBy("created_at", descending: true).snapshots(),
                    builder: (context, s){
                      if(s.hasData){
                        var v=s.data!.docs;
                        final orientation = MediaQuery.of(context).orientation;
                        var size = MediaQuery.of(context).size;

                        return GridView.builder(
                          itemCount: v.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: (orientation == Orientation.portrait) ? 2 : 3,
                            childAspectRatio: (orientation == Orientation.portrait) ? MediaQuery.of(context).size.width /
                                (MediaQuery.of(context).size.height / 2)
                                :
                            MediaQuery.of(context).size.width /
                                (MediaQuery.of(context).size.height / 1)
                            ,

                          ),
                          itemBuilder: (context, i){
                            bool _isFavorite=v[i]['favorites'].contains(_email);
                            return InkWell(
                              onTap: (){
                                Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (context)=>Player(data: v[i])));
                              },
                              child: Card(
                                  child: Container(
                                      decoration: BoxDecoration(
                                          color: Colors.black
                                      ),
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
                                                        Text(v[i]['favorites'].length.toString(), style: TextStyle(color: Colors.white),)
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
                                                    color: Colors.black.withOpacity(0.4),
                                                    borderRadius: BorderRadius.circular(5)

                                                ),
                                                child: Text(v[i]['title'], style: TextStyle(height: 1.5, color: Colors.white)),
                                              )
                                          )
                                        ],
                                      )
                                  )
                              ),
                            );
                          },
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
          ),
        )
      ),
      )
    );
  }
}
