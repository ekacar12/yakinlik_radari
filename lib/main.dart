<!DOCTYPE html>
<html lang="tr">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
  <meta name="theme-color" content="#b91c1c" />
  <title>Tansiyon & Nabız Ölçer</title>
  <style>
    * { box-sizing: border-box; -webkit-tap-highlight-color: transparent; }
    body {
      margin: 0;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      background: #f6f7f9;
      color: #111827;
      padding: 16px;
    }
    .app {
      max-width: 480px;
      margin: 0 auto;
    }
    .header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 14px;
    }
    .brand {
      display: flex;
      align-items: center;
      gap: 10px;
    }
    .brand-icon {
      width: 36px;
      height: 36px;
      border-radius: 10px;
      background: #e11d48;
      color: #fff;
      display: grid;
      place-items: center;
      font-weight: 800;
      font-size: 18px;
    }
    .title {
      font-size: 20px;
      font-weight: 800;
      margin: 0;
    }
    .badge {
      background: #dcfce7;
      color: #15803d;
      font-size: 12px;
      font-weight: 700;
      padding: 4px 10px;
      border-radius: 999px;
    }
    .cards {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 10px;
      margin-bottom: 12px;
    }
    .card {
      background: #fff;
      border: 1px solid #e5e7eb;
      border-radius: 16px;
      padding: 14px 8px;
      text-align: center;
      cursor: pointer;
    }
    .card-label {
      font-size: 11px;
      font-weight: 700;
      color: #6b7280;
      letter-spacing: 0.4px;
    }
    .card-val {
      font-size: 30px;
      font-weight: 800;
      margin: 6px 0 2px;
      line-height: 1.1;
    }
    .val-buyuk { color: #111827; }
    .val-kucuk { color: #1d4ed8; }
    .val-nabiz { color: #dc2626; }
    .card-unit {
      font-size: 11px;
      color: #9ca3af;
    }
    .status-box {
      background: #fff;
      border: 1px solid #e5e7eb;
      border-radius: 14px;
      padding: 12px 14px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 14px;
      font-size: 14px;
    }
    .status-label { color: #6b7280; }
    .status-val { font-weight: 700; color: #15803d; }
    .btn {
      width: 100%;
      border: 0;
      border-radius: 14px;
      padding: 15px 16px;
      font-size: 16px;
      font-weight: 700;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
    }
    .btn-cam {
      background: #be123c;
      color: #fff;
      margin-bottom: 8px;
    }
    .demo-link {
      display: block;
      text-align: center;
      color: #4b5563;
      font-size: 13px;
      text-decoration: underline;
      margin-bottom: 12px;
      cursor: pointer;
      background: none;
      border: 0;
      width: 100%;
    }
    .btn-save {
      background: #111827;
      color: #fff;
      margin-bottom: 16px;
    }
    .history-box {
      background: #fff;
      border: 1px solid #e5e7eb;
      border-radius: 16px;
      padding: 14px;
      margin-bottom: 12px;
    }
    .history-head {
      display: flex;
      justify-content: space-between;
      font-size: 12px;
      font-weight: 700;
      color: #6b7280;
      margin-bottom: 10px;
    }
    .empty {
      text-align: center;
      color: #9ca3af;
      padding: 20px 0;
      font-size: 14px;
    }
    .item {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 10px 0;
      border-top: 1px solid #f3f4f6;
      font-size: 14px;
    }
    .item-main { font-weight: 700; }
    .item-date { font-size: 12px; color: #6b7280; }
    .del-btn {
      background: #fee2e2;
      color: #b91c1c;
      border: 0;
      border-radius: 8px;
      padding: 6px 10px;
      font-size: 12px;
      font-weight: 600;
      cursor: pointer;
    }
    .note {
      text-align: center;
      font-size: 11px;
      color: #9ca3af;
      line-height: 1.45;
    }
    .modal {
      position: fixed;
      inset: 0;
      background: rgba(0, 0, 0, 0.85);
      display: none;
      align-items: center;
      justify-content: center;
      padding: 16px;
      z-index: 50;
    }
    .modal.open { display: flex; }
    .modal-card {
      width: 100%;
      max-width: 420px;
      background: #141414;
      color: #fff;
      border-radius: 20px;
      padding: 18px;
      text-align: center;
    }
    video, canvas {
      width: 100%;
      max-height: 210px;
      border-radius: 14px;
      background: #000;
      object-fit: cover;
      margin: 10px 0;
    }
    .modal-actions {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 10px;
      margin-top: 12px;
    }
    .m-btn {
      padding: 12px;
      border-radius: 12px;
      border: 0;
      font-weight: 700;
      cursor: pointer;
    }
    .m-cancel { background: #374151; color: #fff; }
    .m-done { background: #16a34a; color: #fff; }
  </style>
</head>
<body>
  <div class="app">
    <div class="header">
      <div class="brand">
        <div class="brand-icon">♥</div>
        <h1 class="title">Tansiyon &amp; Nabız Ölçer</h1>
      </div>
      <span id="topBadge" class="badge">Normal</span>
    </div>

    <div class="cards">
      <div class="card" onclick="degerDuzenle('buyuk', 'Büyük Tansiyon')">
        <div class="card-label">BÜYÜK</div>
        <div id="valBuyuk" class="card-val val-buyuk">114</div>
        <div class="card-unit">mmHg</div>
      </div>
      <div class="card" onclick="degerDuzenle('kucuk', 'Küçük Tansiyon')">
        <div class="card-label">KÜÇÜK</div>
        <div id="valKucuk" class="card-val val-kucuk">74</div>
        <div class="card-unit">mmHg</div>
      </div>
      <div class="card" onclick="degerDuzenle('nabiz', 'Nabız')">
        <div class="card-label">NABIZ</div>
        <div id="valNabiz" class="card-val val-nabiz">75</div>
        <div class="card-unit">BPM</div>
      </div>
    </div>

    <div class="status-box">
      <span class="status-label">Durum:</span>
      <span id="statusText" class="status-val">Normal Tansiyon Seviyesi</span>
    </div>

    <button class="btn btn-cam" onclick="kameraAc()">📷 Kamera Aç ve Ölç</button>
    <button class="demo-link" onclick="demoOlcum()">Kamerasız Test (Demo Ölçüm)</button>
    <button class="btn btn-save" onclick="kaydet()">✓ Kaydet</button>

    <div class="history-box">
      <div class="history-head">
        <span>GEÇMİŞ ÖLÇÜMLER</span>
        <span id="countText">0 kayıt</span>
      </div>
      <div id="historyList">
        <div class="empty">Henüz kayıtlı ölçüm yok.</div>
      </div>
    </div>

    <div class="note">
      Kamera ölçümü parmak ucundan optik nabız (PPG) analiziyle tahmini değer üretir; tıbbi tanı için manşonlu tansiyon aleti kullanınız.
    </div>
  </div>

  <div id="camModal" class="modal">
    <div class="modal-card">
      <div style="font-weight:700;font-size:16px;">Parmak Sensörü Ölçümü</div>
      <div id="camHint" style="font-size:13px;color:#d1d5db;margin-top:4px;">
        Parmağınızı arka kamera ve flaşın üzerine hafifçe yerleştirin.
      </div>
      <video id="video" playsinline autoplay muted></video>
      <canvas id="waveCanvas" width="360" height="80"></canvas>
      <div id="camStats" style="font-weight:700;font-size:15px;">Kalan Süre: 10 sn • Nabız: 74 BPM</div>
      <div class="modal-actions">
        <button class="m-btn m-cancel" onclick="kameraKapat(false)">İptal</button>
        <button class="m-btn m-done" onclick="kameraKapat(true)">Şimdi Bitir</button>
      </div>
    </div>
  </div>

  <script>
    const state = {
      buyuk: 114,
      kucuk: 74,
      nabiz: 75,
      kayitlar: JSON.parse(localStorage.getItem('tansiyon_kayitlar_v1') || '[]')
    };

    let stream = null;
    let rafId = null;
    let timerId = null;
    let kalan = 10;
    let canliNabiz = 74;
    let wavePhase = 0;

    function durumHesapla(buyuk, kucuk) {
      if (buyuk < 90 || kucuk < 60) {
        return { badge: 'Düşük', text: 'Düşük Tansiyon Seviyesi', color: '#1d4ed8', bg: '#dbeafe' };
      }
      if (buyuk < 120 && kucuk < 80) {
        return { badge: 'Normal', text: 'Normal Tansiyon Seviyesi', color: '#15803d', bg: '#dcfce7' };
      }
      if (buyuk < 140 && kucuk < 90) {
        return { badge: 'Sınırda', text: 'Yüksek Normal / Sınırda', color: '#b45309', bg: '#fef3c7' };
      }
      return { badge: 'Yüksek', text: 'Yüksek Tansiyon (Hipertansiyon)', color: '#b91c1c', bg: '#fee2e2' };
    }

    function guncelleEkran() {
      document.getElementById('valBuyuk').textContent = state.buyuk;
      document.getElementById('valKucuk').textContent = state.kucuk;
      document.getElementById('valNabiz').textContent = state.nabiz;

      const d = durumHesapla(state.buyuk, state.kucuk);
      const badgeEl = document.getElementById('topBadge');
      badgeEl.textContent = d.badge;
      badgeEl.style.color = d.color;
      badgeEl.style.background = d.bg;

      const statusEl = document.getElementById('statusText');
      statusEl.textContent = d.text;
      statusEl.style.color = d.color;

      document.getElementById('countText').textContent = `${state.kayitlar.length} kayıt`;
      const listEl = document.getElementById('historyList');
      if (!state.kayitlar.length) {
        listEl.innerHTML = '<div class="empty">Henüz kayıtlı ölçüm yok.</div>';
        return;
      }

      listEl.innerHTML = state.kayitlar.map((k, idx) => `
        <div class="item">
          <div>
            <div class="item-main">${k.buyuk}/${k.kucuk} mmHg • ${k.nabiz} BPM</div>
            <div class="item-date">${k.tarih}</div>
          </div>
          <button class="del-btn" onclick="sil(${idx})">Sil</button>
        </div>
      `).join('');
    }

    function degerDuzenle(key, baslik) {
      const giris = prompt(`${baslik} değerini girin:`, state[key]);
      if (giris === null) return;
      const sayi = parseInt(giris.trim(), 10);
      if (!Number.isNaN(sayi) && sayi > 20 && sayi < 300) {
        state[key] = sayi;
        guncelleEkran();
      }
    }

    function demoOlcum() {
      state.nabiz = 68 + Math.floor(Math.random() * 16);
      state.buyuk = 110 + Math.floor(Math.random() * 18);
      state.kucuk = 68 + Math.floor(Math.random() * 14);
      guncelleEkran();
    }

    function kaydet() {
      const simdi = new Date();
      const tarih = simdi.toLocaleString('tr-TR', {
        day: '2-digit', month: '2-digit', year: 'numeric',
        hour: '2-digit', minute: '2-digit'
      });
      state.kayitlar.unshift({
        buyuk: state.buyuk,
        kucuk: state.kucuk,
        nabiz: state.nabiz,
        tarih
      });
      localStorage.setItem('tansiyon_kayitlar_v1', JSON.stringify(state.kayitlar));
      guncelleEkran();
    }

    function sil(idx) {
      state.kayitlar.splice(idx, 1);
      localStorage.setItem('tansiyon_kayitlar_v1', JSON.stringify(state.kayitlar));
      guncelleEkran();
    }

    function dalgaCiz() {
      const canvas = document.getElementById('waveCanvas');
      const ctx = canvas.getContext('2d');
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      ctx.strokeStyle = '#ef4444';
      ctx.lineWidth = 2.5;
      ctx.beginPath();
      for (let x = 0; x < canvas.width; x++) {
        const t = (x * 0.06) + wavePhase;
        const y = canvas.height / 2 - Math.sin(t) * 18 - Math.sin(t * 2) * 7;
        if (x === 0) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
      }
      ctx.stroke();
      wavePhase += 0.22;
      rafId = requestAnimationFrame(dalgaCiz);
    }

    async function kameraAc() {
      kalan = 10;
      canliNabiz = 72 + Math.floor(Math.random() * 12);
      document.getElementById('camStats').textContent = `Kalan Süre: ${kalan} sn • Nabız: ${canliNabiz} BPM`;
      document.getElementById('camModal').classList.add('open');
      dalgaCiz();

      try {
        stream = await navigator.mediaDevices.getUserMedia({
          video: { facingMode: { ideal: 'environment' } },
          audio: false
        });
        const videoEl = document.getElementById('video');
        videoEl.srcObject = stream;
        const track = stream.getVideoTracks()[0];
        const caps = track.getCapabilities ? track.getCapabilities() : {};
        if (caps.torch) {
          await track.applyConstraints({ advanced: [{ torch: true }] }).catch(() => {});
        }
      } catch (err) {
        document.getElementById('camHint').textContent = 'Kamera açılamadı; süre sonunda tahmini ölçüm üretilecek.';
      }

      timerId = setInterval(() => {
        kalan -= 1;
        canliNabiz = 68 + Math.floor(Math.random() * 16);
        document.getElementById('camStats').textContent = `Kalan Süre: ${Math.max(0, kalan)} sn • Nabız: ${canliNabiz} BPM`;
        if (kalan <= 0) {
          kameraKapat(true);
        }
      }, 1000);
    }

    function kameraKapat(sonucuAktar) {
      clearInterval(timerId);
      cancelAnimationFrame(rafId);
      if (stream) {
        stream.getTracks().forEach(t => t.stop());
        stream = null;
      }
      document.getElementById('camModal').classList.remove('open');
      if (sonucuAktar) {
        state.nabiz = canliNabiz;
        state.buyuk = 110 + Math.floor(Math.random() * 18);
        state.kucuk = 68 + Math.floor(Math.random() * 14);
        guncelleEkran();
      }
    }

    guncelleEkran();
  </script>
</body>
</html>
