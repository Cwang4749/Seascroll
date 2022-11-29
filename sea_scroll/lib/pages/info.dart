import 'package:flutter/material.dart';
import 'package:sea_scroll/pages/home.dart';

class Info extends StatelessWidget {
  const Info({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(
        title: Text("Tutorial"),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Image.asset('assets/InfoBG.png',
        height: height,
        width: width,
        fit: BoxFit.cover,),
      floatingActionButton: IconButton(
        onPressed: () {
          Future.delayed(const Duration(milliseconds: 1000), () {
            Navigator.push(context, MaterialPageRoute(builder: ((context) => Home())));
          });
        },
        icon: Icon(Icons.arrow_forward),
        iconSize: 60,
      ),
    );
  }
}