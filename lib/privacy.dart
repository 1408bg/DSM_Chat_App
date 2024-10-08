import 'dart:convert';
import 'package:dsm_chat/main.dart';
import 'package:flutter/material.dart';
import "package:http/http.dart" as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

const String _ver = "0.4";

class privacy extends StatelessWidget {
  const privacy({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: PrivacyApp(),
    );
  }
}

class PrivacyApp extends StatefulWidget {
  const PrivacyApp({super.key});

  @override
  State<PrivacyApp> createState() => _PrivacyAppState();
}

class _PrivacyAppState extends State<PrivacyApp> {
  late SharedPreferences _prefs;
  late String _address;

  late FutureBuilder _appBar;
  late FutureBuilder _body;

  final TextStyle _contentsStyle = const TextStyle(fontSize: 12);

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
  }
  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _address = _prefs.getString('address')!;
  }

  Future fetch(String address) async {
    var res = null;
    try {
      res = await http.get(
          Uri.parse("$_address$address"),
          headers: {
            "user-header" : "flutter-v$_ver"
          }
      );
    } on Exception catch (_) {
      Future.delayed(const Duration(seconds: 1), (){
        return fetch(address);
      });
    }
    return jsonDecode(res.body);
  }

  FutureBuilder _getMainView(){
    return FutureBuilder(future: Future.delayed(const Duration(seconds: 2), () => fetch("/privacy")), builder: (context, snap){
      if (!snap.hasData) {
        return const Center(
          child: CircularProgressIndicator()
        );
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              snap.data['main'][0],
              style: _contentsStyle,
            ),
            Text(
              snap.data['main'][1],
              style: _contentsStyle,
            ),
            Text(
              snap.data['main'][2],
              style: _contentsStyle,
            )
          ],
        ),
      );
    });
  }
  FutureBuilder _getAppBarView(){
    return FutureBuilder(future: Future.delayed(const Duration(seconds: 2), () => fetch("/privacy")), builder: (context, snap){
      if (!snap.hasData) return const Text("Loading..");
      return Text(
        snap.data['title'],
        style: const TextStyle(fontSize: 22),
      );
    });
  }

  @override
  Widget build(BuildContext context){
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    _appBar = _getAppBarView();
    _body = _getMainView();

    return Scaffold(
      appBar: AppBar(
        title: _appBar,
        automaticallyImplyLeading: false,
      ),
      body: _body,
      bottomNavigationBar: SizedBox(
        height: 80,
        child: TextButton(
          child: const Text(
            "Back",
            style: TextStyle(fontSize: 16),
          ),
          onPressed: (){
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MyApp()),
            );
          },
        ),
      )
    );
  }
}