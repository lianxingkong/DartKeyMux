import 'package:flutter/material.dart';

import './mapping_key_page.dart';
import './change_host.dart';
import '../../app_config.dart';


class SettingPage extends StatefulWidget{
  const SettingPage({super.key});

  @override
  State<SettingPage> createState()=> _SettingPage();
}

class _SettingPage extends State<SettingPage>{
  bool landscapeState = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("设 置"),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,  // 高度收缩为内容高度
            children: [
              ListTile(
                title: const Text("按键映射表（实验性功能）"),
                trailing: const Icon(Icons.chevron_right),    // 右侧箭头
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const KeyMapPage()),
                  );
                },
              ),
              SwitchListTile(
                title: const Text("测试"),
                value: landscapeState,
                onChanged: (bool? _newState){
                setState(() { landscapeState = _newState!; });
                }
              ),
              ChangeHost(
                valueHost: AppConfig.grpcHost,
                valuePort: AppConfig.grpcPort,
                valueUpdateHost: (host) {
                  AppConfig.grpcHost.value = host;
                },
                valueUpdatePort: (port) {
                  AppConfig.grpcPort.value = port;
                },
              ),
            ],
          ),
        ],
      )
    );
  }
}

