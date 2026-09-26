import 'package:flutter/material.dart';

import 'package:flutter_application_1/function_area/setting/basic_setting_page.dart';
import 'package:flutter_application_1/function_area/services/template_service.dart';


class MainSidebarMenu extends StatefulWidget {
  const MainSidebarMenu({super.key});

  @override
  State<MainSidebarMenu> createState() => _MainSidebarMenuState();
}

class _MainSidebarMenuState extends State<MainSidebarMenu> {

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color.fromARGB(255, 210, 243, 210),
          child: Column(
            children: [
              DrawerHeader(
                child: Icon(
                  Icons.account_circle_outlined,
                  size:40
                )
              ),
              ListTile(
                leading: Icon(Icons.home),
                title: Text("主 页"),
              ),
              ListTile(
                leading: const Icon(Icons.flash_on),
                title: const Text("自启动指定模板"),
                trailing: ListenableBuilder(
                  listenable: TemplateService.instance,
                  builder: (context, _) {
                    final masterOn = TemplateService.instance.autoStartMasterEnabled;
                    // 只有设置了自启动模板时总开关才有实际意义，用副文本提示当前状态
                    final hasTarget = TemplateService.instance.autoStartIndex != null;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasTarget)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              TemplateService.instance.draftAt(TemplateService.instance.autoStartIndex!).name,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        Switch(
                          value: masterOn,
                          onChanged: (value) {
                            TemplateService.instance.setAutoStartMaster(value);
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
              InkWell(
                onTap: () {
                  // 先关闭抽屉，再跳转，否则返回时抽屉还是打开的
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingPage()),
                  );
                },
                child: const ListTile(
                  leading: Icon(Icons.settings),
                  title: Text("设置"),
                ),
              ),
            ],
          ),
    );
  }
}