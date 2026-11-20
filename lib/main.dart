import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

const String kFirebaseDbUrl = 'https://yakinlik-radari-default-rtdb.firebaseio.com';

void main() {
  runApp(const YakinlikRadariApp());
}

class YakinlikRadariApp extends StatelessWidget {
  const YakinlikRadariApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yakınlık Radarı',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const RadarHomePage(),
    );
  }
}

class SharedUserLocation {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final int updatedAtMs;
  final double distanceKm;

  SharedUserLocation({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.updatedAtMs,
    required this.distanceKm,
  });
}

class RadarHomePage extends StatefulWidget {
  const RadarHomePage({super.key});

  @override
  State<RadarHomePage> createState() => _RadarHomePageState();
}

class _RadarHomePageState extends State<RadarHomePage> {
  final TextEditingController _nameController = TextEditingController(text: 'Ben');
  final TextEditingController _phoneKeyController = TextEditingController(text: 'kullanici_1');

  Position? _myPosition;
  bool _shareLocation = true;
  bool _loading = false;
  String _statusText = 'Konum bekleniyor...';
  List<SharedUserLocation> _nearbyUsers = [];
  Timer? _autoTimer;

  @override
  void initState() {
    super.initState();
    _refreshRadar();
    _autoTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_shareLocation) {
        _refreshRadar(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _nameController.dispose();
    _phoneKeyController.dispose();
    super.dispose();
  }

  String _sanitizeKey(String raw) {
    final cleaned = raw.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return cleaned.isEmpty ? 'kullanici_anonim' : cleaned;
  }

  Future<Position?> _ensureAndGetPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _statusText = 'Telefonun konum (GPS) servisi kapalı.');
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      setState(() => _statusText = 'Konum izni verilmedi.');
      return null;
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<void> _writeMyLocationToFirebase(Position pos) async {
    final key = _sanitizeKey(_phoneKeyController.text);
    final name = _nameController.text.trim().isEmpty ? key : _nameController.text.trim();
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final uri = Uri.parse('$kFirebaseDbUrl/users/$key.json');
    final payload = jsonEncode({
      'name': name,
      'lat': pos.latitude,
      'lng': pos.longitude,
      'updatedAtMs': nowMs,
      'sharing': true,
    });

    final client = HttpClient();
    try {
      final request = await client.putUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(payload);
      final response = await request.close();
      await response.drain();
    } finally {
      client.close();
    }
  }

  Future<List<SharedUserLocation>> _fetchAndCalculateDistances(Position myPos) async {
    final myKey = _sanitizeKey(_phoneKeyController.text);
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    const int twoDaysMs = 48 * 60 * 60 * 1000;

    final uri = Uri.parse('$kFirebaseDbUrl/users.json');
    final client = HttpClient();
    String bodyStr = '';
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      bodyStr = await response.transform(utf8.decoder).join();
    } finally {
      client.close();
    }

    if (bodyStr.trim().isEmpty || bodyStr.trim() == 'null') {
      return [];
    }

    final decoded = jsonDecode(bodyStr);
    if (decoded is! Map<String, dynamic>) {
      return [];
    }

    final List<SharedUserLocation> results = [];
    decoded.forEach((key, value) {
      if (key == myKey || value is! Map) return;
      final sharing = value['sharing'] == true;
      final latRaw = value['lat'];
      final lngRaw = value['lng'];
      final updatedRaw = value['updatedAtMs'];

      if (!sharing || latRaw is! num || lngRaw is! num || updatedRaw is! num) return;

      final updatedMs = updatedRaw.toInt();
      if (nowMs - updatedMs > twoDaysMs) return;

      final meters = Geolocator.distanceBetween(
        myPos.latitude,
        myPos.longitude,
        latRaw.toDouble(),
        lngRaw.toDouble(),
      );

      results.add(
        SharedUserLocation(
          id: key.toString(),
          name: (value['name'] ?? key).toString(),
          lat: latRaw.toDouble(),
          lng: lngRaw.toDouble(),
          updatedAtMs: updatedMs,
          distanceKm: meters / 1000.0,
        ),
      );
    });

    results.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return results;
  }

  Future<void> _refreshRadar({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _statusText = 'GPS ve veritabanı güncelleniyor...';
      });
    }

    try {
      final pos = await _ensureAndGetPosition();
      if (pos == null) {
        if (!silent) setState(() => _loading = false);
        return;
      }

      if (_shareLocation) {
        await _writeMyLocationToFirebase(pos);
      }

      final users = await _fetchAndCalculateDistances(pos);

      if (!mounted) return;
      setState(() {
        _myPosition = pos;
        _nearbyUsers = users;
        _loading = false;
        _statusText =
            'Konumunuz: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)} • '
            'Paylaşan kişi: ${users.length}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _statusText = 'Bağlantı/konum hatası: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yakınlık Radarı'),
        actions: [
          IconButton(
            onPressed: _loading ? null : () => _refreshRadar(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Görünen Adınız',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _phoneKeyController,
                          decoration: const InputDecoration(
                            labelText: 'Kimlik / Numara',
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Konumumu paylaş (son 48 saat aktif)'),
                    value: _shareLocation,
                    onChanged: (val) {
                      setState(() => _shareLocation = val);
                      _refreshRadar();
                    },
                  ),
                  Text(
                    _statusText,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child: _nearbyUsers.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Şu an konum paylaşan başka kullanıcı görünmüyor.\n'
                        'İkinci bir cihazda da aynı uygulama açılıp konum paylaştığında '
                        'gerçek kilometre uzaklığı burada listelenecek.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _nearbyUsers.length,
                    itemBuilder: (context, index) {
                      final u = _nearbyUsers[index];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person_pin_circle)),
                        title: Text(u.name),
                        subtitle: Text('Kimlik: ${u.id}'),
                        trailing: Text(
                          '${u.distanceKm.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
