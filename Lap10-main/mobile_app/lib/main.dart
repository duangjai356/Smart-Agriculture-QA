import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

// ===== ตั้งค่า Server ที่นี่จุดเดียว =====
// Chrome/เครื่องเดียวกับ XAMPP: "localhost" | Android Emulator: "10.0.2.2" | มือถือจริง: IP เครื่อง เช่น "192.168.1.10"
const String kServerHost = "10.234.116.141:8080";

void main() => runApp(const SmartFarmApp());

class SmartFarmApp extends StatelessWidget {
  const SmartFarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Agriculture QA',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _telemetryData;
  Map<String, dynamic>? _inventoryData;
  bool _loaded = false;
  String? _error;
  Timer? _timer;

  final String apiUrl = "http://192.168.1.106:8080/smart_farm/api/get_latest.php";

  @override
  void initState() {
    super.initState();
    fetchData();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) => fetchData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchData() async {
    try {
      final response = await http
          .get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'success' && mounted) {
          setState(() {
            _telemetryData = jsonResponse['telemetry'];
            _inventoryData = jsonResponse['inventory'];
            _loaded = true;
            _error = null;
          });
        }
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
      if (mounted) setState(() => _error = "เชื่อมต่อ Server ไม่ได้");
    }
  }

  Widget buildCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: ListTile(
        leading: Icon(icon, color: color, size: 40),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _telemetryData;
    final inv = _inventoryData;

    return Scaffold(
      appBar: AppBar(title: const Text("Smart Warehouse Dashboard")),
      body: !_loaded
          ? Center(
              child: _error != null
                  ? Text(_error!)
                  : const CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  if (_error != null)
                    Text(_error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center),
                  buildCard("Temperature", "${t?['temperature'] ?? '-'} °C",
                      Icons.thermostat, Colors.red),
                  buildCard("Humidity", "${t?['humidity'] ?? '-'} %",
                      Icons.water_drop, Colors.blue),
                  const Divider(height: 30),
                  buildCard("Apple Count", "${inv?['apple_count'] ?? 0} pcs",
                      Icons.apple, Colors.redAccent),
                  buildCard("Mango Count", "${inv?['mango_count'] ?? 0} pcs",
                      Icons.eco, Colors.amber),
                  buildCard("Orange Count", "${inv?['orange_count'] ?? 0} pcs",
                      Icons.circle, Colors.orange),
                  const SizedBox(height: 10),
                  Text("Last Updated: ${inv?['created_at'] ?? '-'}",
                      textAlign: TextAlign.center),
                ],
              ),
            ),
    );
  }
}
