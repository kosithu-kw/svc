import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:svc/genres.dart';
import 'package:svc/home.dart';

class Auth extends StatefulWidget {
  const Auth({Key? key}) : super(key: key);

  @override
  _AuthState createState() => _AuthState();
}

class _AuthState extends State<Auth> {
  final _title="Authentication";
  String _email="";
  String _picture="";
  bool _isLogin=false;

  signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Once signed in, return the UserCredential
    await FirebaseAuth.instance.signInWithCredential(credential);

    var currentUser= await FirebaseAuth.instance.currentUser;
    if(currentUser.uid !=null){
      setState(() {
        _email=currentUser.email;
        _isLogin=true;
        _picture=currentUser.photoURL;
      });
      Navigator.push(context, MaterialPageRoute(builder: (context)=>Auth()));
    }
  }

  _checkLogin()async{
    var currentUser=await FirebaseAuth.instance.currentUser;
    if(currentUser.uid !=null){
      setState(() {
        _email=currentUser.email;
        _isLogin=true;
        _picture=currentUser.photoURL;
      });
    }
  }
  googleSignout()async{
    await FirebaseAuth.instance.signOut().then((value){
      setState(() {
        _email="";
        _isLogin=false;
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
    return MaterialApp(
      theme: ThemeData(
          primaryColor: Color(0x204665).withOpacity(1.0)
      ),
      title: _title,
      home: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: (){
              Navigator.pop(context);

              //Navigator.push(context, MaterialPageRoute(builder: (context)=>Home()));
            },
            icon: Icon(Icons.arrow_back),
          ),
          title: Text(_title, style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
        ),
        body: Container(
            child: Center(
              child:
                 !_isLogin ?
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    TextButton(
                        onPressed: (){
                          signInWithGoogle();
                        },
                        child: Column(
                          children: [
                            Container(
                              height: 50,
                              child: ClipOval(
                                child: Image.asset("images/google.png"),
                              ),
                            ),
                            SizedBox(height: 10,),
                            Text("Sign in With Google")
                          ],
                        )
                    )
                  ],
                )
                  :
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("You are login as", style: TextStyle(color: Colors.grey),),
                    SizedBox(height: 30),
                    ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: "${_picture}",
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
                    SizedBox(height: 10,),
                    Text(_email, style: TextStyle(fontWeight: FontWeight.bold),),
                    TextButton(
                        onPressed: (){
                            googleSignout();
                        },
                        child: Text("Sign out")
                    )
                  ],
                )

            )
        ),
      ),
    );
  }
}
