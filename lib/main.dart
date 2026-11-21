import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const TuglaKiriciApp());
}

class TuglaKiriciApp extends StatelessWidget {
  const TuglaKiriciApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tuğla Kırıcı',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0F1E),
      ),
      home: const OyunEkrani(),
    );
  }
}

class Tugla {
  Rect rect;
  int hp;
  int maxHp;
  Tugla({required this.rect, required this.hp}) : maxHp = hp;
}

class OyunEkrani extends StatefulWidget {
  const OyunEkrani({super.key});

  @override
  State<OyunEkrani> createState() => _OyunEkraniState();
}

class _OyunEkraniState extends State<OyunEkrani> {
  Timer? _timer;
  final Random _rng = Random();

  double _alanGenislik = 360;
  double _alanYukseklik = 540;

  double _raketX = 135;
  double _raketGenislik = 90;
  final double _raketYukseklik = 14;
  double _raketY = 500;

  double _topX = 180;
  double _topY = 480;
  double _topHizX = 3.6;
  double _topHizY = -4.2;
  final double _topYaricap = 9;

  int _skor = 0;
  int _can = 3;
  int _seviye = 1;
  bool _calisiyor = false;
  bool _oyunBitti = false;
  List<Tugla> _tuglalar = [];

  @override
  void initState() {
    super.initState();
    _seviyeHazirla(1, resetSkor: true);
  }

  void _seviyeHazirla(int seviye, {bool resetSkor = false}) {
    _timer?.cancel();
    _calisiyor = false;
    _oyunBitti = false;
    _seviye = seviye;
    if (resetSkor) {
      _skor = 0;
      _can = 3;
    }
    _raketGenislik = 90;
    _raketX = (_alanGenislik - _raketGenislik) / 2;
    _raketY = _alanYukseklik - 36;
    _topuRastgeleBaslat();

    _tuglalar.clear();
    const satirSayisi = 5;
    const sutunSayisi = 6;
    const bosluk = 6.0;
    final tuglaGenislik =
        (_alanGenislik - (sutunSayisi + 1) * bosluk) / sutunSayisi;
    const tuglaYukseklik = 22.0;

    for (int r = 0; r < satirSayisi; r++) {
      for (int c = 0; c < sutunSayisi; c++) {
        final hp = min(3, 1 + ((r + seviye - 1) ~/ 2));
        final left = bosluk + c * (tuglaGenislik + bosluk);
        final top = 48.0 + r * (tuglaYukseklik + bosluk);
        _tuglalar.add(Tugla(
          rect: Rect.fromLTWH(left, top, tuglaGenislik, tuglaYukseklik),
          hp: hp,
        ));
      }
    }
    setState(() {});
  }

  void _topuRastgeleBaslat() {
    _topX = _raketX + _raketGenislik / 2;
    _topY = _raketY - _topYaricap - 2;
    final yon = _rng.nextBool() ? 1.0 : -1.0;
    final hizCarpani = 1.0 + (_seviye - 1) * 0.08;
    _topHizX = yon * 3.5 * hizCarpani;
    _topHizY = -4.2 * hizCarpani;
  }

  void _oyunuBaslatVeyaDuraklat() {
    if (_oyunBitti) {
      _seviyeHazirla(1, resetSkor: true);
      _oyunuBaslatVeyaDuraklat();
      return;
    }
    if (_calisiyor) {
      _timer?.cancel();
      setState(() => _calisiyor = false);
      return;
    }
    setState(() => _calisiyor = true);
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) => _adim());
  }

  void _adim() {
    if (!_calisiyor || _oyunBitti) return;

    _topX += _topHizX;
    _topY += _topHizY;

    if (_topX - _topYaricap <= 0) {
      _topX = _topYaricap;
      _topHizX = _topHizX.abs();
    } else if (_topX + _topYaricap >= _alanGenislik) {
      _topX = _alanGenislik - _topYaricap;
      _topHizX = -_topHizX.abs();
    }

    if (_topY - _topYaricap <= 0) {
      _topY = _topYaricap;
      _topHizY = _topHizY.abs();
    }

    final raketRect =
        Rect.fromLTWH(_raketX, _raketY, _raketGenislik, _raketYukseklik);
    final topRect = Rect.fromCircle(center: Offset(_topX, _topY), radius: _topYaricap);

    if (_topHizY > 0 && topRect.overlaps(raketRect)) {
      final merkezFarki =
          (_topX - (_raketX + _raketGenislik / 2)) / (_raketGenislik / 2);
      _topHizX = merkezFarki.clamp(-1.0, 1.0) * 5.2;
      _topHizY = -_topHizY.abs();
      _topY = _raketY - _topYaricap - 1;
    }

    for (int i = _tuglalar.length - 1; i >= 0; i--) {
      final tugla = _tuglalar[i];
      if (topRect.overlaps(tugla.rect)) {
        tugla.hp -= 1;
        _skor += 10;
        if (tugla.hp <= 0) {
          _tuglalar.removeAt(i);
          _skor += 15;
        }
        _topHizY = -_topHizY;
        break;
      }
    }

    if (_tuglalar.isEmpty) {
      _seviyeHazirla(_seviye + 1);
      return;
    }

    if (_topY - _topYaricap > _alanYukseklik) {
      _can -= 1;
      if (_can <= 0) {
        _can = 0;
        _oyunBitti = true;
        _calisiyor = false;
        _timer?.cancel();
      } else {
        _calisiyor = false;
        _timer?.cancel();
        _topuRastgeleBaslat();
      }
    }

    setState(() {});
  }

  void _raketiHareketEttir(double deltaX) {
    setState(() {
      _raketX = (_raketX + deltaX).clamp(0.0, _alanGenislik - _raketGenislik);
      if (!_calisiyor && !_oyunBitti) {
        _topX = _raketX + _raketGenislik / 2;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color _tuglaRengi(int hp) {
    switch (hp) {
      case 3:
        return const Color(0xFFEF4444);
      case 2:
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF38BDF8);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tuğla Kırıcı · Seviye $_seviye'),
        backgroundColor: const Color(0xFF111827),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _seviyeHazirla(1, resetSkor: true),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Skor: $_skor',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Can: $_can',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                ElevatedButton(
                  onPressed: _oyunuBaslatVeyaDuraklat,
                  child: Text(_oyunBitti
                      ? 'Yeniden'
                      : (_calisiyor ? 'Duraklat' : 'Başlat')),
                ),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                _alanGenislik = constraints.maxWidth;
                _alanYukseklik = constraints.maxHeight;
                _raketY = _alanYukseklik - 36;
                _raketX =
                    _raketX.clamp(0.0, max(0.0, _alanGenislik - _raketGenislik));
                if (!_calisiyor && !_oyunBitti) {
                  _topX = _raketX + _raketGenislik / 2;
                  _topY = _raketY - _topYaricap - 2;
                }

                return GestureDetector(
                  onHorizontalDragUpdate: (details) =>
                      _raketiHareketEttir(details.delta.dx),
                  onTap: () {
                    if (!_calisiyor) _oyunuBaslatVeyaDuraklat();
                  },
                  child: Container(
                    width: _alanGenislik,
                    height: _alanYukseklik,
                    color: const Color(0xFF060A14),
                    child: CustomPaint(
                      painter: _OyunRessami(
                        tuglalar: _tuglalar,
                        raketRect: Rect.fromLTWH(
                            _raketX, _raketY, _raketGenislik, _raketYukseklik),
                        topX: _topX,
                        topY: _topY,
                        topYaricap: _topYaricap,
                        renkFunc: _tuglaRengi,
                        oyunBitti: _oyunBitti,
                        skor: _skor,
                      ),
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

class _OyunRessami extends CustomPainter {
  final List<Tugla> tuglalar;
  final Rect raketRect;
  final double topX;
  final double topY;
  final double topYaricap;
  final Color Function(int) renkFunc;
  final bool oyunBitti;
  final int skor;

  _OyunRessami({
    required this.tuglalar,
    required this.raketRect,
    required this.topX,
    required this.topY,
    required this.topYaricap,
    required this.renkFunc,
    required this.oyunBitti,
    required this.skor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (final tugla in tuglalar) {
      paint.color = renkFunc(tugla.hp);
      canvas.drawRRect(
        RRect.fromRectAndRadius(tugla.rect, const Radius.circular(5)),
        paint,
      );
    }

    paint.color = const Color(0xFF22C55E);
    canvas.drawRRect(
      RRect.fromRectAndRadius(raketRect, const Radius.circular(7)),
      paint,
    );

    paint.color = Colors.white;
    canvas.drawCircle(Offset(topX, topY), topYaricap, paint);

    if (oyunBitti) {
      final tp = TextPainter(
        text: TextSpan(
          text: 'OYUN BİTTİ\nSkor: $skor\nTekrar için Başlat\'a bas',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width - 32);

      tp.paint(
        canvas,
        Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OyunRessami oldDelegate) => true;
}
