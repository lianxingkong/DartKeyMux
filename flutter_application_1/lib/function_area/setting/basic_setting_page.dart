import 'package:flutter/material.dart';


class SettingPage extends StatefulWidget{
  const SettingPage({super.key});

  @override
  State<SettingPage> createState()=> _SettingPage();
}

class _SettingPage extends State<SettingPage>{
  bool state = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("设 置"),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text("测试"),
            value: state,
            onChanged: (bool? _newState){
              setState(() { state = _newState!; });
            }
          ),
        ],
      ),
    );
  }
}