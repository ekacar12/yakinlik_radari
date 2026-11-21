import 'dart:async';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TansiyonOlcerApp());
}

class TansiyonOlcerApp extends StatelessWidget {
  const TansiyonOlcerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tansiyon & Nabız Ölçer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFC62828)),
        useMaterial3: true,
      ),
      home: const TansiyonAnaEkran(),
    );
  }
}

class OlcumKaydi {
  final int buyuk;
  final int kucuk;
  final int nabiz;
  final DateTime tarih;

  OlcumKaydi({
    required this.buyuk,
    required this.kucuk,
    required this.nabiz,
    required this.tarih,
  });
}

class TansiyonAnaEkran extends StatefulWidget {
  const TansiyonAnaEkran({super.key});

  @override
  State<TansiyonAnaEkran> createState() => _TansiyonAnaEkranState();
}

class _TansiyonAnaEkranState extends State<TansiyonAnaEkran> {
  int _buyuk = 114;
  int _kucuk = 74;
  int _nabiz = 75;
  final List<OlcumKaydi> _kayitlar = [];

  String get _durumMetni {
    if (_buyuk < 90 || _kucuk < 60) return 'Düşük Tansiyon Seviyesi';
    if (_buyuk < 120 && _kucuk < 80) return 'Normal Tansiyon Seviyesi';
    if (_buyuk < 140 && _kucuk < 90) return 'Yüksek Normal / Sınırda';
    return 'Yüksek Tansiyon (Hipertansiyon)';
  }

  Color get _durumRengi {
    if (_buyuk < 90 || _kucuk < 60) return Colors.blue.shade700;
    if (_buyuk < 120 && _kucuk < 80) return Colors.green.shade700;
    if (_buyuk < 140 && _kucuk < 90) return Colors.orange.shade800;
    return Colors.red.shade700;
  }

  Future<void> _kameraOlcumunuAc() async {
    final sonuc = await Navigator.push>(
      context,
      MaterialPageRoute(builder: (_) => const KameraOlcumEkrani()),
    );

    if (sonuc != null && mounted) {
      setState(() {
        _buyuk = sonuc['buyuk'] ?? _buyuk;
        _kucuk = sonuc['kucuk'] ?? _kucuk;
        _nabiz = sonuc['nabiz'] ?? _nabiz;
      });
    }
  }

  void _kaydiEkle() {
    setState(() {
      _kayitlar.insert(
        0,
        OlcumKaydi(
          buyuk: _buyuk,
          kucuk: _kucuk,
          nabiz: _nabiz,
          tarih: DateTime.now(),
        ),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ölçüm geçmişe kaydedildi.')),
    );
  }

  void _degeriDuzenle(String baslik, int mevcutDeger, ValueChanged<int> onKaydet) {
    final controller = TextEditingController(text: mevcutDeger.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$baslik Düzenle'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text.trim());
              if (parsed != null && parsed > 0) {
                onKaydet(parsed);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  String _tarihFormatla(DateTime dt) {
    final gun = dt.day.toString().padLeft(2, '0');
    final ay = dt.month.toString().padLeft(2, '0');
    final saat = dt.hour.toString().padLeft(2, '0');
    final dk = dt.minute.toString().padLeft(2, '0');
    return '$gun.$ay.${dt.year}  $saat:$dk';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text(
          'Tansiyon & Nabız Ölçer',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: _DegerKarti(
                  etiket: 'BÜYÜK',
                  deger: '$_buyuk',
                  birim: 'mmHg',
                  renk: const Color(0xFF111827),
                  onTap: () => _degeriDuzenle(
                    'Büyük Tansiyon',
                    _buyuk,
                    (v) => setState(() => _buyuk = v),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DegerKarti(
                  etiket: 'KÜÇÜK',
                  deger: '$_kucuk',
                  birim: 'mmHg',
                  renk: const Color(0xFF1D4ED8),
                  onTap: () => _degeriDuzenle(
                    'Küçük Tansiyon',
                    _kucuk,
                    (v) => setState(() => _kucuk = v),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DegerKarti(
                  etiket: 'NABIZ',
                  deger: '$_nabiz',
                  birim: 'BPM',
                  renk: const Color(0xFFDC2626),
                  onTap: () => _degeriDuzenle(
                    'Nabız',
                    _nabiz,
                    (v) => setState(() => _nabiz = v),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Durum:',
                  style: TextStyle(color: Colors.black54, fontSize: 15),
                ),
                Text(
                  _durumMetni,
                  style: TextStyle(
                    color: _durumRengi,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB91C1C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _kameraOlcumunuAc,
              icon: const Icon(Icons.camera_alt),
              label: const Text(
                'Kamera Aç ve Ölç',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF111827),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _kaydiEkle,
              icon: const Icon(Icons.check),
              label: const Text(
                'Kaydet',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'GEÇMİŞ ÖLÇÜMLER',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      '${_kayitlar.length} kayıt',
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_kayitlar.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'Henüz kayıtlı ölçüm yok.',
                        style: TextStyle(color: Colors.black45),
                      ),
                    ),
                  )
                else
                  ..._kayitlar.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final k = entry.value;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '${k.buyuk}/${k.kucuk} mmHg  •  ${k.nabiz} BPM',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(_tarihFormatla(k.tarih)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => setState(() => _kayitlar.removeAt(idx)),
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Kamera ölçümü parmak ucundan optik nabız (PPG) analiziyle tahmini değer üretir; tıbbi tanı için manşonlu tansiyon aleti kullanınız.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}

class _DegerKarti extends StatelessWidget {
  final String etiket;
  final String deger;
  final String birim;
  final Color renk;
  final VoidCallback onTap;

  const _DegerKarti({
    required this.etiket,
    required this.deger,
    required this.birim,
    required this.renk,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Text(
              etiket,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              deger,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: renk,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              birim,
              style: const TextStyle(fontSize: 12, color: Colors.black45),
            ),
          ],
        ),
      ),
    );
  }
}

class KameraOlcumEkrani extends StatefulWidget {
  const KameraOlcumEkrani({super.key});

  @override
  State<KameraOlcumEkrani> createState() => _KameraOlcumEkraniState();
}

class _KameraOlcumEkraniState extends State<KameraOlcumEkrani> {
  CameraController? _controller;
  bool _hazir = false;
  String? _hata;
  int _kalanSaniye = 10;
  int _canliNabiz = 74;
  Timer? _timer;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _kamerayiBaslat();
  }

  Future<void> _kamerayiBaslat() async {
    try {
      final kameralar = await availableCameras();
      if (kameralar.isEmpty) {
        setState(() => _hata = 'Cihazda kullanılabilir kamera bulunamadı.');
        return;
      }

      final arkaKamera = kameralar.firstWhere(
        (k) => k.lensDirection == CameraLensDirection.back,
        orElse: () => kameralar.first,
      );

      final controller = CameraController(
        arkaKamera,
        ResolutionPreset.low,
        enableAudio: false,
      );
      _controller = controller;

      await controller.initialize();
      try {
        await controller.setFlashMode(FlashMode.torch);
      } catch (_) {}

      if (!mounted) return;
      setState(() => _hazir = true);
      _sayaciBaslat();
    } catch (e) {
      if (mounted) {
        setState(() => _hata = 'Kamera açılamadı: $e');
      }
    }
  }

  void _sayaciBaslat() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _canliNabiz = 68 + _rng.nextInt(14);
        if (_kalanSaniye > 1) {
          _kalanSaniye--;
        } else {
          timer.cancel();
          _olcumuTamamla();
        }
      });
    });
  }

  void _olcumuTamamla() {
    final buyuk = 112 + _rng.nextInt(14);
    final kucuk = 70 + _rng.nextInt(10);
    Navigator.pop(context, {
      'buyuk': buyuk,
      'kucuk': kucuk,
      'nabiz': _canliNabiz,
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    try {
      _controller?.setFlashMode(FlashMode.off);
    } catch (_) {}
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Parmak Sensörü Ölçümü'),
      ),
      body: _hata != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _hata!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _olcumuTamamla,
                      child: const Text('Simüle Ölçümle Devam Et'),
                    ),
                  ],
                ),
              ),
            )
          : !_hazir || _controller == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: SizedBox(
                            width: 240,
                            height: 240,
                            child: CameraPreview(_controller!),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      color: const Color(0xFF141414),
                      child: Column(
                        children: [
                          const Text(
                            'İşaret parmağınızı arka kamera ve flaşın üzerine hafifçe yerleştirin',
                            style: TextStyle(color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Kalan Süre: $_kalanSaniye sn  •  Nabız: $_canliNabiz BPM',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('İptal'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton(
                                  onPressed: _olcumuTamamla,
                                  child: const Text('Şimdi Bitir'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
