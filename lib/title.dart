import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dsm_chat/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import "package:http/http.dart" as http;
import 'package:url_launcher/url_launcher.dart';

const String ver = "0.4";

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  final TextEditingController _ipController = TextEditingController();
  late SharedPreferences _prefs;
  late String _address = "null";
  String _ver = "null";

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
    getData();
  }

  Future getData() async{
    var res = await http.get(Uri.parse("https://1408bg.github.io/chat.json"));
    setState(() {
      _address = jsonDecode(res.body)['url'];
      _ver = jsonDecode(res.body)['ver'];
    });
  }

  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    return Scaffold(
      appBar: AppBar(
        title: const Text("DSM_Chat"),
        centerTitle: true,
      ),
      body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: Platform.isAndroid ? 200 : (MediaQuery.of(context).size.width-400),
                child: TextField(
                  controller: _ipController,
                  style: const TextStyle(height: 1),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'input ip address'
                  ),
                  onSubmitted: (text){
                    _prefs.setString('address', _ipController.text);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MyApp()),
                    );
                  },
                ),
              ),
              TextButton(
                onPressed: () => {
                  _prefs.setString('address', _address),
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MyApp()),
                  )
                },
                child: Text('추천 주소 / $_address')
              ),
              const SizedBox(height: 16),
              Text(ver.compareTo(_ver) == 0 ? "최신 버전입니다" : "신규 업데이트가 나왔습니다", style: const TextStyle(fontSize: 18)),
              TextButton(
                onPressed: () {
                  launchUrl(
                    Uri.parse('https://1408bg.github.io/store'),
                  );
                },
                child: const Text("스토어로 이동하기", style: TextStyle(color: Colors.blueAccent),),
              )
            ],
          )
      )
    );
  }
}
