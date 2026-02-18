import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final InternetConnection _internetConnection = InternetConnection();

  Future<bool> get isConnected async {
    final List<ConnectivityResult> results =
        await _connectivity.checkConnectivity();
    if (results.contains(ConnectivityResult.none)) return false;

    // Check for actual internet access
    return await _internetConnection.hasInternetAccess;
  }

  /// Checks if there is a real internet connection (not just Wi-Fi without signal).
  Future<bool> get hasRealInternet async =>
      await _internetConnection.hasInternetAccess;

  /// Stream that emits true when internet is recovered, false when lost.
  Stream<bool> get onInternetChanged => _internetConnection.onStatusChange
      .map((status) => status == InternetStatus.connected);

  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;
}
