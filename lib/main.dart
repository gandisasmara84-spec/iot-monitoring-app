import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const IoTMonitoringApp());
}

class IoTMonitoringApp extends StatelessWidget {
  const IoTMonitoringApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IoT Monitoring',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1E88E5),
        scaffoldBackgroundColor: const Color(0xFFF4F7FB),
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final Random _random = Random();
  Timer? _timer;

  // ---------- DATA DUMMY ----------
  bool _isConnected = true;
  double _temperature = 28.5;
  double _humidity = 65.0;
  DateTime _lastUpdate = DateTime.now();
  final List<double> _tempHistory = [27.8, 28.1, 28.4, 28.0, 28.6, 29.0, 28.5];
  final List<double> _humHistory = [63, 64, 66, 65, 67, 66, 65];

  @override
  void initState() {
    super.initState();
    // Simulasi data masuk tiap 3 detik (nanti diganti data MQTT)
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _simulateData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _simulateData() {
    if (!_isConnected) return;
    setState(() {
      _temperature = 26 + _random.nextDouble() * 8; // 26 - 34 °C
      _humidity = 50 + _random.nextDouble() * 30; // 50 - 80 %
      _lastUpdate = DateTime.now();
      _tempHistory.add(_temperature);
      _humHistory.add(_humidity);
      if (_tempHistory.length > 12) _tempHistory.removeAt(0);
      if (_humHistory.length > 12) _humHistory.removeAt(0);
    });
  }

  void _toggleConnection() {
    setState(() => _isConnected = !_isConnected);
  }

  String _formatTime(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.day)}/${two(t.month)}/${t.year}  ${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }

  String _tempStatus() {
    if (_temperature < 28) return 'Normal';
    if (_temperature < 32) return 'Hangat';
    return 'Panas';
  }

  String _humStatus() {
    if (_humidity < 55) return 'Kering';
    if (_humidity < 75) return 'Normal';
    return 'Lembap';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'IoT Monitoring Dashboard',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _simulateData(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _buildConnectionCard(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SensorCard(
                      title: 'Suhu',
                      value: _temperature.toStringAsFixed(1),
                      unit: '°C',
                      status: _isConnected ? _tempStatus() : '-',
                      icon: Icons.thermostat,
                      color: const Color(0xFFEF6C00),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SensorCard(
                      title: 'Kelembapan',
                      value: _humidity.toStringAsFixed(1),
                      unit: '%',
                      status: _isConnected ? _humStatus() : '-',
                      icon: Icons.water_drop,
                      color: const Color(0xFF1E88E5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildLastUpdateCard(),
              const SizedBox(height: 16),
              _ChartCard(
                title: 'Grafik Suhu (°C)',
                data: _tempHistory,
                color: const Color(0xFFEF6C00),
              ),
              const SizedBox(height: 16),
              _ChartCard(
                title: 'Grafik Kelembapan (%)',
                data: _humHistory,
                color: const Color(0xFF1E88E5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Status koneksi MQTT ----------
  Widget _buildConnectionCard() {
    final color = _isConnected ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isConnected ? Icons.wifi : Icons.wifi_off,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Status MQTT',
                    style: TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration:
                          BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isConnected ? 'Connected' : 'Disconnected',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text('broker.hivemq.com : 1883',
                    style: TextStyle(fontSize: 11, color: Colors.black45)),
              ],
            ),
          ),
          Switch(value: _isConnected, onChanged: (_) => _toggleConnection()),
        ],
      ),
    );
  }

  // ---------- Waktu pembaruan ----------
  Widget _buildLastUpdateCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          const Icon(Icons.access_time, color: Colors.black54),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Terakhir diperbarui',
                    style: TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 2),
                Text(
                  _formatTime(_lastUpdate),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Perbarui data',
            onPressed: _simulateData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );

// ---------- Kartu sensor (suhu / kelembapan) ----------
class _SensorCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final String status;
  final IconData icon;
  final Color color;

  const _SensorCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.status,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                    fontSize: 32, fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(unit,
                    style: const TextStyle(fontSize: 16, color: Colors.black54)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(status,
                style: TextStyle(
                    fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ---------- Kartu grafik ----------
class _ChartCard extends StatelessWidget {
  final String title;
  final List<double> data;
  final Color color;

  const _ChartCard({
    required this.title,
    required this.data,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            width: double.infinity,
            child: CustomPaint(painter: _LineChartPainter(data, color)),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Min: ${data.reduce(min).toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 11, color: Colors.black54)),
              Text('Max: ${data.reduce(max).toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 11, color: Colors.black54)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _LineChartPainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    // Garis grid
    final gridPaint = Paint()
      ..color = Colors.black12
      ..strokeWidth = 1;
    for (int i = 0; i <= 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (data.length < 2) return;

    final minV = data.reduce(min) - 1;
    final maxV = data.reduce(max) + 1;
    final range = (maxV - minV) == 0 ? 1 : (maxV - minV);

    Offset point(int i) {
      final x = size.width * i / (data.length - 1);
      final y = size.height - ((data[i] - minV) / range) * size.height;
      return Offset(x, y);
    }

    final linePath = Path()..moveTo(point(0).dx, point(0).dy);
    for (int i = 1; i < data.length; i++) {
      linePath.lineTo(point(i).dx, point(i).dy);
    }

    // Area di bawah garis
    final areaPath = Path.from(linePath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      areaPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.3), color.withOpacity(0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Garis utama
    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );

    // Titik data
    final dotPaint = Paint()..color = color;
    for (int i = 0; i < data.length; i++) {
      canvas.drawCircle(point(i), 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) => true;
}