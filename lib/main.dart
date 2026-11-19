import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

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
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF071118),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5A8),
          secondary: Color(0xFF38BDF8),
        ),
      ),
      home: const RadarEkran(),
    );
  }
}

class RadarEkran extends StatefulWidget {
  const RadarEkran({super.key});

  @override
  State<RadarEkran> createState() => _RadarEkranState();
}

class _RadarEkranState extends State<RadarEkran>
    with SingleTickerProviderStateMixin {
  late final AnimationController _taramaKontrolcu;
  final Random _rastgele = Random();
  Timer? _olcumZamanlayici;

  bool _taramaAktif = true;
  double _mesafeMetre = 4.8;
  String _durumMetni = 'Yakın Bölge Taranıyor';

  @override
  void initState() {
    super.initState();
    _taramaKontrolcu = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _olcumuBaslat();
  }

  void _olcumuBaslat() {
    _olcumZamanlayici?.cancel();
    _olcumZamanlayici = Timer.periodic(const Duration(milliseconds: 900), (_) {
      if (!_taramaAktif || !mounted) return;
      setState(() {
        final hamMesafe = 0.6 + _rastgele.nextDouble() * 9.4;
        _mesafeMetre = double.parse(hamMesafe.toStringAsFixed(1));
        if (_mesafeMetre < 2.0) {
          _durumMetni = 'Çok Yakın Sinyal';
        } else if (_mesafeMetre < 5.5) {
          _durumMetni = 'Orta Mesafe Tespit';
        } else {
          _durumMetni = 'Çevre Taranıyor';
        }
      });
    });
  }

  void _taramayiDegistir() {
    setState(() {
      _taramaAktif = !_taramaAktif;
      if (_taramaAktif) {
        _taramaKontrolcu.repeat();
        _olcumuBaslat();
      } else {
        _taramaKontrolcu.stop();
        _olcumZamanlayici?.cancel();
        _durumMetni = 'Tarama Duraklatıldı';
      }
    });
  }

  void _anlikOlcumAl() {
    final yeniMesafe = 0.5 + _rastgele.nextDouble() * 9.5;
    setState(() {
      _mesafeMetre = double.parse(yeniMesafe.toStringAsFixed(1));
      _durumMetni = _mesafeMetre < 2.0
          ? 'Çok Yakın Sinyal'
          : 'Anlık Ölçüm Güncellendi';
    });
  }

  @override
  void dispose() {
    _olcumZamanlayici?.cancel();
    _taramaKontrolcu.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final yakinMi = _mesafeMetre < 2.0;
    final vurguRengi = yakinMi
        ? const Color(0xFFFF5A5F)
        : const Color(0xFF00E5A8);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yakınlık Radarı'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Text(
                    _durumMetni,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: vurguRengi,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_mesafeMetre.toStringAsFixed(1)} m',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              SizedBox(
                width: 270,
                height: 270,
                child: AnimatedBuilder(
                  animation: _taramaKontrolcu,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _RadarCizici(
                        aci: _taramaKontrolcu.value * 2 * pi,
                        vurguRengi: vurguRengi,
                      ),
                      child: Center(
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: vurguRengi,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _taramayiDegistir,
                      icon: Icon(
                        _taramaAktif ? Icons.pause : Icons.play_arrow,
                      ),
                      label: Text(_taramaAktif ? 'Duraklat' : 'Taramayı Başlat'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: vurguRengi,
                        foregroundColor: const Color(0xFF071118),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _anlikOlcumAl,
                      icon: const Icon(Icons.radar),
                      label: const Text('Anlık Ölç'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: vurguRengi.withOpacity(0.7)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadarCizici extends CustomPainter {
  final double aci;
  final Color vurguRengi;

  _RadarCizici({
    required this.aci,
    required this.vurguRengi,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final merkez = Offset(size.width / 2, size.height / 2);
    final yaricap = min(size.width, size.height) / 2;

    final halkaBoyasi = Paint()
      ..color = vurguRengi.withOpacity(0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final oran in [0.33, 0.66, 1.0]) {
      canvas.drawCircle(merkez, yaricap * oran, halkaBoyasi);
    }

    final eksenBoyasi = Paint()
      ..color = vurguRengi.withOpacity(0.14)
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(merkez.dx - yaricap, merkez.dy),
      Offset(merkez.dx + yaricap, merkez.dy),
      eksenBoyasi,
    );
    canvas.drawLine(
      Offset(merkez.dx, merkez.dy - yaricap),
      Offset(merkez.dx, merkez.dy + yaricap),
      eksenBoyasi,
    );

    final yelpazeAlani = Rect.fromCircle(center: merkez, radius: yaricap);
    final yelpazeBoyasi = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: 0,
        endAngle: pi / 2.5,
        colors: [
          vurguRengi.withOpacity(0.0),
          vurguRengi.withOpacity(0.35),
        ],
        transform: GradientRotation(aci - pi / 2.5),
      ).createShader(yelpazeAlani);

    canvas.drawArc(yelpazeAlani, aci - pi / 2.5, pi / 2.5, true, yelpazeBoyasi);

    final cizgiUcu = Offset(
      merkez.dx + cos(aci) * yaricap,
      merkez.dy + sin(aci) * yaricap,
    );
    final taramaCizgisi = Paint()
      ..color = vurguRengi
      ..strokeWidth = 2.2;

    canvas.drawLine(merkez, cizgiUcu, taramaCizgisi);
  }

  @override
  bool shouldRepaint(covariant _RadarCizici oldDelegate) {
    return oldDelegate.aci != aci || oldDelegate.vurguRengi != vurguRengi;
  }
}
