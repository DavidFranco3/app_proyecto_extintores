import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/logs_controller.dart';
import '../../components/Logs/list_logs.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LogsController>().cargarLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(),
      drawer: MenuLateral(currentPage: "Logs"),
      body: Consumer<LogsController>(
        builder: (context, controller, child) {
          if (controller.loading && controller.dataLogs.isEmpty) {
            return Load();
          }

          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                      child: Center(
                        child: Text(
                          "Logs de auditoría",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.color ??
                                const Color(0xFF2C3E50),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TblLogs(
                  showModal: () {
                    if (mounted) Navigator.pop(context);
                  },
                  logs: controller.dataLogs,
                  onCompleted: () => controller.cargarLogs(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
