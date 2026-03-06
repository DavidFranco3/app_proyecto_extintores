import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../components/Logs/list_logs.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';

class LogsPage extends ConsumerStatefulWidget {
  const LogsPage({super.key});

  @override
  ConsumerState<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends ConsumerState<LogsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(logsProvider).cargarLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(),
      drawer: MenuLateral(currentPage: "Logs"),
      body: Consumer(
        builder: (context, ref, child) {
          final controller = ref.watch(logsProvider);
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
