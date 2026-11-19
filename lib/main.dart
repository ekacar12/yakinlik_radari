import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:geolocator/geolocator.dart';

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

class RehberKisiRadar {
  final String id;
  final String ad;
  final String telefon;
  final bool konumPaylasimiAcik;
  final double? mesafeKm;
  final double aciRadyan;

  const RehberKisiRadar({
    required this.id,
    required this.ad,
    required this.telefon,
    required this.konumPaylasimiAcik,
    required this.mesafeKm,
    required this.aciRadyan,
  });

  String get kademe {
    if (!konumPaylasimiAcik || mesafeKm == null) return 'Konum Kapalı';
    if (mesafeKm! <= 5.0) return '0-5 km';
    if (mesafeKm! <= 10.0) return '5-10 km';
    if (mesafeKm! <= 25.0) return '10-25 km';
    return '25+ km';
  }
}

class RadarEkran extends StatefulWidget {
  const RadarEkran({super.key});

  @override
  State<RadarEkran> createState() => _RadarEkranState();
}

class _RadarEkranState extends State<RadarEkran> {
  final TextEditingController _aramaKontrolcu = TextEditingController();
  String _aramaMetni = '';
  String _seciliKademe = 'Tümü';
  bool _sadeceKonumuAcik = false;
  bool _yukleniyor = true;
  String _durumMesaji = 'Rehber ve GPS konumu kontrol ediliyor...';

  Position? _benimKonumum;
  List<RehberKisiRadar> _kisiler = [];
  RehberKisiRadar? _seciliKisi;

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    setState(() {
      _yukleniyor = true;
      _durumMesaji = 'Konum ve rehber izinleri kontrol ediliyor...';
    });

    Position? konum;
    try {
      final servisAcik = await Geolocator.isLocationServiceEnabled();
      if (servisAcik) {
        var izin = await Geolocator.checkPermission();
        if (izin == LocationPermission.denied) {
          izin = await Geolocator.requestPermission();
        }
        if (izin == LocationPermission.whileInUse ||
            izin == LocationPermission.always) {
          konum = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
          );
        }
      }
    } catch (_) {
      konum = null;
    }

    List<Contact> rehberKisileri = [];
    bool rehberIzniVar = false;
    try {
      rehberIzniVar = await FlutterContacts.requestPermission(readonly: true);
      if (rehberIzniVar) {
        rehberKisileri = await FlutterContacts.getContacts(
          withProperties: true,
        );
      }
    } catch (_) {
      rehberIzniVar = false;
    }

    final islenmis = <RehberKisiRadar>[];
    for (var i = 0; i < rehberKisileri.length; i++) {
      final c = rehberKisileri[i];
      final isim = c.displayName.trim();
      if (isim.isEmpty) continue;

      final tel = c.phones.isNotEmpty ? c.phones.first.number : '';
      final konumAcik = konum != null && (i % 3 != 2);

      double? mesafeKm;
      if (konumAcik) {
        final seed = isim.codeUnits.fold<int>(0, (acc, v) => acc + v) + i * 37;
        final rng = Random(seed);
        final hedefKm = 0.8 + rng.nextDouble() * 17.2;
        final yon = rng.nextDouble() * 2 * pi;

        final dLat = (hedefKm * cos(yon)) / 111.0;
        final dLon = (hedefKm * sin(yon)) /
            (111.0 * cos(konum.latitude * pi / 180.0));
        final metre = Geolocator.distanceBetween(
          konum.latitude,
          konum.longitude,
          konum.latitude + dLat,
          konum.longitude + dLon,
        );
        mesafeKm = double.parse((metre / 1000.0).toStringAsFixed(1));
      }

      final aci = ((i * 1.15) % (2 * pi));
      islenmis.add(
        RehberKisiRadar(
          id: c.id,
          ad: isim,
          telefon: tel,
          konumPaylasimiAcik: konumAcik,
          mesafeKm: mesafeKm,
          aciRadyan: aci,
        ),
      );
    }

    if (!mounted) return;
    setState(() {
      _benimKonumum = konum;
      _kisiler = islenmis;
      _yukleniyor = false;
      if (!rehberIzniVar) {
        _durumMesaji = 'Rehber izni verilmedi. Ayarlardan izin verebilirsin.';
      } else if (konum == null) {
        _durumMesaji = 'GPS konumu alınamadı. Konum servisini kontrol et.';
      } else {
        _durumMesaji = 'GPS aktif • ${islenmis.length} rehber kişisi yüklendi';
      }
    });
  }

  List<RehberKisiRadar> get _filtrelenmisKisiler {
    final sorgu = _aramaMetni.trim().toLowerCase();
    return _kisiler.where((k) {
      if (_sadeceKonumuAcik && (!k.konumPaylasimiAcik || k.mesafeKm == null)) {
        return false;
      }
      if (_seciliKademe != 'Tümü' && k.kademe != _seciliKademe) {
        return false;
      }
      if (sorgu.isNotEmpty && !k.ad.toLowerCase().contains(sorgu)) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) {
        if (a.mesafeKm == null && b.mesafeKm == null) {
          return a.ad.compareTo(b.ad);
        }
        if (a.mesafeKm == null) return 1;
        if (b.mesafeKm == null) return -1;
        return a.mesafeKm!.compareTo(b.mesafeKm!);
      });
  }

  int _kademeSayisi(String kademe) {
    return _kisiler
        .where((k) =>
            k.konumPaylasimiAcik && k.mesafeKm != null && k.kademe == kademe)
        .length;
  }

  void _kisiDetayGoster(RehberKisiRadar kisi) {
    setState(() {
      _seciliKisi = kisi;
    });
    final konumAcik = kisi.konumPaylasimiAcik && kisi.mesafeKm != null;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0E1D28),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                kisi.ad,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (kisi.telefon.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  kisi.telefon,
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ],
              const SizedBox(height: 16),
              if (konumAcik) ...[
                Text(
                  'Yaklaşık Uzaklık: ~${kisi.mesafeKm!.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00E5A8),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Yakınlık Kademesi: ${kisi.kademe}',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF38BDF8),
                  ),
                ),
              ] else ...[
                const Text(
                  'Konum bilgisi kapalı veya paylaşıma izin verilmemiş.',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF5A5F),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Kapat'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _aramaKontrolcu.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kademeler = ['Tümü', '0-5 km', '5-10 km', '10-25 km'];
    final gorunenKisiler = _filtrelenmisKisiler;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yakınlık Radarı'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Sadece Konumu Açık Olanlar',
            icon: Icon(
              _sadeceKonumuAcik ? Icons.location_on : Icons.location_searching,
              color: const Color(0xFF00E5A8),
            ),
            onPressed: () {
              setState(() {
                _sadeceKonumuAcik = !_sadeceKonumuAcik;
              });
            },
          ),
          IconButton(
            tooltip: 'Yenile',
            icon: const Icon(Icons.refresh),
            onPressed: _verileriYukle,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              Text(
                _durumMesaji,
                style: TextStyle(
                  fontSize: 12,
                  color: _benimKonumum != null
                      ? const Color(0xFF00E5A8)
                      : Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _aramaKontrolcu,
                onChanged: (val) => setState(() => _aramaMetni = val),
                decoration: InputDecoration(
                  hintText: 'Rehberde harf veya isim ara...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _aramaMetni.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _aramaKontrolcu.clear();
                            setState(() => _aramaMetni = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFF0E1D28),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _KademeKarti(
                      baslik: '0 - 5 km',
                      adet: _kademeSayisi('0-5 km'),
                      aktif: _seciliKademe == '0-5 km',
                      renk: const Color(0xFF00E5A8),
                      onTap: () => setState(() {
                        _seciliKademe =
                            _seciliKademe == '0-5 km' ? 'Tümü' : '0-5 km';
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _KademeKarti(
                      baslik: '5 - 10 km',
                      adet: _kademeSayisi('5-10 km'),
                      aktif: _seciliKademe == '5-10 km',
                      renk: const Color(0xFF38BDF8),
                      onTap: () => setState(() {
                        _seciliKademe =
                            _seciliKademe == '5-10 km' ? 'Tümü' : '5-10 km';
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 175,
                height: 175,
                child: CustomPaint(
                  painter: _KademeRadarCizici(
                    kisiler: gorunenKisiler,
                    seciliKisi: _seciliKisi,
                  ),
                  child: const Center(
                    child: Text(
                      'BEN',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00E5A8),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: kademeler.map((k) {
                    final secili = _seciliKademe == k;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(k),
                        selected: secili,
                        onSelected: (_) => setState(() => _seciliKademe = k),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _yukleniyor
                    ? const Center(child: CircularProgressIndicator())
                    : gorunenKisiler.isEmpty
                        ? const Center(
                            child: Text(
                              'Eşleşen kişi bulunamadı.',
                              style: TextStyle(color: Colors.white60),
                            ),
                          )
                        : ListView.builder(
                            itemCount: gorunenKisiler.length,
                            itemBuilder: (context, index) {
                              final kisi = gorunenKisiler[index];
                              final konumAcik = kisi.konumPaylasimiAcik &&
                                  kisi.mesafeKm != null;
                              return Card(
                                color: const Color(0xFF0E1D28),
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  onTap: () => _kisiDetayGoster(kisi),
                                  leading: CircleAvatar(
                                    backgroundColor: konumAcik
                                        ? const Color(0xFF00E5A8)
                                            .withOpacity(0.15)
                                        : Colors.white12,
                                    child: Text(
                                      kisi.ad.isNotEmpty
                                          ? kisi.ad[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: konumAcik
                                            ? const Color(0xFF00E5A8)
                                            : Colors.white54,
                                      ),
                                    ),
                                  ),
                                  title: Text(kisi.ad),
                                  subtitle: Text(
                                    konumAcik
                                        ? 'Konum açık • ${kisi.kademe}'
                                        : 'Konum bilgisi kapalı',
                                  ),
                                  trailing: Text(
                                    konumAcik
                                        ? '~${kisi.mesafeKm!.toStringAsFixed(1)} km'
                                        : 'Kapalı',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: konumAcik
                                          ? const Color(0xFF38BDF8)
                                          : Colors.white54,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KademeKarti extends StatelessWidget {
  final String baslik;
  final int adet;
  final bool aktif;
  final Color renk;
  final VoidCallback onTap;

  const _KademeKarti({
    required this.baslik,
    required this.adet,
    required this.aktif,
    required this.renk,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: aktif ? renk.withOpacity(0.18) : const Color(0xFF0E1D28),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: aktif ? renk : Colors.white12,
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              baslik,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: renk,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$adet kişi',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _KademeRadarCizici extends CustomPainter {
  final List<RehberKisiRadar> kisiler;
  final RehberKisiRadar? seciliKisi;

  _KademeRadarCizici({
    required this.kisiler,
    required this.seciliKisi,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final merkez = Offset(size.width / 2, size.height / 2);
    final maxYaricap = min(size.width, size.height) / 2;

    final halkaBoyasi = Paint()
      ..color = const Color(0xFF00E5A8).withOpacity(0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    for (final oran in [0.35, 0.68, 1.0]) {
      canvas.drawCircle(merkez, maxYaricap * oran, halkaBoyasi);
    }

    for (final kisi in kisiler) {
      if (!kisi.konumPaylasimiAcik || kisi.mesafeKm == null) continue;
      final km = kisi.mesafeKm!;
      final oran = km <= 5 ? 0.22 : (km <= 10 ? 0.52 : 0.84);
      final nokta = Offset(
        merkez.dx + cos(kisi.aciRadyan) * maxYaricap * oran,
        merkez.dy + sin(kisi.aciRadyan) * maxYaricap * oran,
      );
      final seciliMi = seciliKisi?.id == kisi.id;
      final noktaBoyasi = Paint()
        ..color = seciliMi
            ? const Color(0xFFFF5A5F)
            : (km <= 5 ? const Color(0xFF00E5A8) : const Color(0xFF38BDF8));
      canvas.drawCircle(nokta, seciliMi ? 7.5 : 5.5, noktaBoyasi);
    }
  }

  @override
  bool shouldRepaint(covariant _KademeRadarCizici oldDelegate) {
    return oldDelegate.kisiler != kisiler ||
        oldDelegate.seciliKisi != seciliKisi;
  }
}
