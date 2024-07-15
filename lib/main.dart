import 'dart:convert';
import 'package:dsm_chat/privacy.dart';
import 'package:flutter/material.dart';
import "package:http/http.dart" as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;
import 'package:dsm_chat/title.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;

const String _ver = "0.3";

void main() => runApp(
  MediaQuery(
    data: MediaQueryData.fromView(ui.window),
    child: const Directionality(
      textDirection: TextDirection.rtl,
      child: MaterialApp(home: StartPage())))
);

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late IO.Socket _socket;
  late SharedPreferences _prefs;

  Map<String, dynamic> jsonData = {'Smessage' : 'error'};

  late final TextEditingController _nameController;
  late final TextEditingController _messageController;
  final ScrollController scrollController = ScrollController();
  late FutureBuilder _appBar;
  late FutureBuilder _body;
  late FutureBuilder _navBar;
  final List _logList = List.empty(growable: true);
  late String _address;
  bool _named = false;
  late String _num;

  @override
  void initState(){
    super.initState();
    _nameController = TextEditingController();
    _messageController = TextEditingController();
    _num = "-999";
    _initSharedPreferences();
  }

  @override
  void dispose(){
    _nameController.dispose();
    _messageController.dispose();
    _socket.disconnect();
    super.dispose();
  }

  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _address = _prefs.getString('address')!;
    _socket = IO.io('http://$_address',
      IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .setPath('/socket.io')
        .build());
    _socket.connect();
    _socket.on('sendAll', (data) => {
      jsonData = json.decode(data),
      if (jsonData['Stype']){
        setState(() {
          _logList.add(Text('${jsonData['Sname']}[${jsonData['Snum']}] : ${jsonData['Smessage']}'));
        }),
        scrollToBottom()
      }
      else {
        setState(() {
          _logList.add(Text(jsonData['Smessage']));
        }),
        scrollToBottom()
      }
    });
    _socket.on('yourNum', (data) => {
      setState(() {
        _num = data;
      })
    });
    _socket.on('disconnect', (data) => {
      setState(() {
        _logList.clear();
        _logList.add(const Text('서버가 닫혔습미다..'));
      })
    });
  }

  Future fetch(String address) async {
    var res = null;
    try {
      res = await http.get(
          Uri.parse("http://$_address$address"),
          headers: {
            "user-header" : "flutter-v$_ver"
          }
      );
    } on Exception {
      Future.delayed(const Duration(seconds: 1), (){
        return fetch(address);
      });
    }
    return jsonDecode(res.body);
  }
  FutureBuilder _getAppBarView(){
    return FutureBuilder(
      future: Future.delayed(const Duration(seconds: 2), () => fetch("/")),
      builder: (context, snap){
        if(!snap.hasData) return const Text("Loading..");
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Text(snap.data['title'], style: const TextStyle(fontSize: 24),),
            Text("현재 주소 : ${snap.data['address']}", style: const TextStyle(fontSize: 12),),
            const SizedBox(height: 10,),
            SizedBox(
              height: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: Platform.isAndroid ? 50 : MediaQuery.of(context).size.width/10,
                    child: TextField(
                      minLines: 1,
                      controller: _nameController,
                      maxLength: 15,
                      readOnly: _named ? true : false,
                      style: const TextStyle(height: 1),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: 'name',
                        filled: true,
                        fillColor: _named ? Colors.blueGrey[200] : Colors.white,
                      ),
                      onSubmitted: (text){
                        if (_nameController.text.isEmpty){
                          return;
                        }
                        setState(() {
                          _named = true;
                        });
                        _socket.emit('getNum', _nameController.text);
                      },
                      onTapOutside: (text){
                        if (_nameController.text.isEmpty){
                          return;
                        }
                        if (!_named){
                          setState(() {
                            _named = true;
                          });
                          _socket.emit('getNum', _nameController.text);
                        }
                      },
                    )
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  SizedBox(
                    width: Platform.isAndroid ? 200 : MediaQuery.of(context).size.width/3,
                    child: TextField(
                      minLines: 1,
                      controller: _messageController,
                      readOnly: _named ? false : true,
                      maxLength: 20,
                      style: const TextStyle(height: 1),
                      decoration: InputDecoration(
                        isDense: true,
                        border: const OutlineInputBorder(),
                        labelText: 'message',
                        filled: true,
                        fillColor: _named ? Colors.white : Colors.grey[200],
                      ),
                    )
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: (){
                      if (_messageController.text.isEmpty){
                        return;
                      }
                      _socket.emit('message', jsonEncode({
                        'name' : _nameController.text,
                        'message' : _messageController.text,
                        'num' : _num
                      }));
                      _messageController.text = "";
                    },
                  )
                ],
              ),
            )
          ]
        );
      }
    );
  }
  FutureBuilder _getMainView(){
    return FutureBuilder(
        future: Future.delayed(const Duration(seconds: 2), () => fetch("/")),
        builder: (context, snap){
          if(snap.data == null){
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if(!snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.red,)
            );
          }
          return
              Center(
                child: Text(
                  snap.data['main'],
                  style: const TextStyle(fontSize: 20),
                )
              );
        }
    );
  }
  FutureBuilder _getNavView(){
    return FutureBuilder(
      future: Future.delayed(const Duration(seconds: 2), () => fetch("/privacy")),
      builder: (context, snap){
        if(!snap.hasData) return const Text("Wait 5 Seconds..");
        return TextButton(
          onPressed: (){
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const privacy()),
            );
          },
          child: Text(
            snap.data['title'],
          )
        );
      }
    );
  }
  void scrollToBottom() {
    scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    _appBar = _getAppBarView();
    _body = _getMainView();
    _navBar = _getNavView();

    return MaterialApp(
      theme: ThemeData(
        inputDecorationTheme: const InputDecorationTheme(
          contentPadding: EdgeInsets.symmetric(vertical: 15),
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: _appBar,
          centerTitle: true,
          toolbarHeight: 160,
          automaticallyImplyLeading: false,
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 1,
              child: _body,
            ),
            Expanded(
              flex: 5,
              child: ListView.builder(
                controller: scrollController,
                itemCount: _logList.length,
                itemBuilder: (context, index){
                  return ListTile(
                    title: _logList[index],
                    visualDensity: const VisualDensity(vertical: -4),
                    dense: true,
                  );
                },
              )
            )
          ],
        ),
        bottomNavigationBar: SizedBox(
          height: 80,
          child: _navBar,
        )
      ),
    );
  }
}