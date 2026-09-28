# MIGUEL PHONK — 3D Konser

Tarayicida calisan tek dosyalik 3D konser. Iki ses kaynagi vardir:

1. **KAYIT** — sarkilarin kendisi calar. Bir **calma listesi** olarak gomulu gelirler
   (`bundle.py` ile paketlenir); `N`/`P` ile parca degistirilir, parca bitince
   kendiliginden sonrakine gecer. Isik, lazer, LED duvar ve kalabalik **canli spektrum
   analiziyle** surulur: 0–170 Hz kick'i, 170–1000 Hz snare'i, 6–13 kHz hi-hat'i
   tetikler; sahne siddeti sarkinin anlik enerjisinden gelir. Esikler her bandin kendi
   hareketli ortalamasina gore uyarlanir ve **parca degisiminde sifirlanir**, boylece
   sessiz bir parca gurultulu bir parcadan sonra da dogru tetiklenir.
2. **SENTEZ** — nota calar. Kayittan cikarilmis notalar Web Audio ile canli sentezlenir
   (808, cowbell, trap davul, lead). Ses dosyasi gerektirmez.

`S` tusu ikisi arasinda gecis yapar. `index.html` tek basina sentez modunda acilir;
sarkilarla acilan surum icin asagidaki paketlemeyi kullan.

## GitHub Pages'te yayinlamak

Depo Pages icin hazir: `.github/workflows/pages.yml` her push'ta siteyi yayinlar.
Bir kez ayar gerekir — **Settings → Pages → Source: GitHub Actions**.

Parcalari siteye eklemek:

```bash
mkdir -p tracks
cp ~/muzik/*.mp3 tracks/
python3 bundle.py -a tracks/*.mp3 --manifest     # tracks.json uretir
git add tracks tracks.json && git commit -m "parcalar" && git push
```

Sayfa acilinca `tracks.json` okunur ve parcalar **akis halinde** calar: ne base64
cozulur ne de dosya bellege kopyalanir. `tracks.json` yoksa site sentez moduyla acilir,
hata vermez. Is akisi yayindan once manifesti dogrular: listede olmayan bir dosya varsa
dagitim durur.

`tracks.example.json` bicimi gosterir. Herkese acik bir siteye muzik koymanin
telif sorumlulugu senindir — bu yuzden depoya hicbir ses dosyasi eklemedim.

## Ziyaretcilerin yukledigi muzikler

Sayfaya mp3 birakan biri icin parca **o cihazda kalir**: dosya IndexedDB'ye yazilir,
sayfa yenilendiginde listeye geri gelir, `SIL` butonuyla kaldirilir. Depo siniri 200 MB.

> Bu **cihaz basina** kaliciliktir. GitHub Pages statik bir sunucudur, sunucu tarafi
> depolama yoktur — yani bir ziyaretcinin yukledigi parcayi baska ziyaretciler duymaz.
> Herkesin duyacagi ortak bir liste icin bir depolama servisi (ornegin S3, Supabase,
> Cloudflare R2) ve kucuk bir yukleme ucu gerekir; Pages bunu tek basina yapamaz.

## Mobil

- Kontroller dokunma icin buyutulur (en az 42 px), dar ekranda yazilar kisalir,
  centik/ev cubugu icin `env(safe-area-inset-*)` payi birakilir.
- Parmakla surukle: kamera. Cift dokun: duraklat. Alttaki `◀ ▶`: parca.
- Mobilde ses `<audio>` uzerinden calar. Iki nedeni var: iOS'ta zil/sessiz anahtari
  Web Audio'yu susturur ama medya kanalini susturmaz; ayrica parca basina ~60 MB'lik
  PCM tamponu acilmaz, dosya akis halinde cozulur. Analiz yine `AnalyserNode` ile
  yapilir, gorseller ayni sekilde surulur.
- iOS ses kilidi jestin **icinde** acilir (`resume()` senkron cagrilir), yoksa Safari
  reddeder.
- Kare hizi 26'nin altina duserse sahne kademeli hafifler: once piksel orani, sonra
  kalabalik detayi ve sis, sonra lazerler. Konser yavaslamak yerine sadelesir.
- Calarken ekran sonmesin diye Wake Lock istenir; desteklenmiyorsa sessizce gecilir.

## Paketleme — tek dosya, cevrimdisi

`bundle.py`, sayfayi ve ses dosyalarini tek bir HTML'e gomer. Cikti cift tiklamayla
(`file://`) acilir; internet, sunucu ve kurulum istemez.

```bash
python3 bundle.py -a tracks/*.mp3 --three three.min.js -o konser.html
```

- `-a` tekrarlanabilir ve her seferinde birden fazla dosya alir; sira calma listesi
  sirasidir.
- `--manifest` verilirse paketleme yapilmaz, sadece `tracks.json` uretilir.
- Parca adi dosya adindan alinir (bastaki numara ve alt cizgiler temizlenir).
- `--three` ile [three.js r128](https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js)
  de gomulur; olmazsa sayfa acilirken internet gerekir.
- Base64 govdeleri **ancak o parca calmaya geldiginde** cozulur; ayni anda en fazla iki
  cozulmus tampon tutulur (bir parca ~60 MB PCM eder).
- Sinirlar: parca basina 60 MB, toplam 120 MB.

> Ses dosyalari ve paketlenmis `konser.html` depoya dahil degildir, `.gitignore` ile
> disarida tutulur. Kendi kopyalarini kendi makinende paketle.

## Muzik (sentez modu)

Notalar **kaydin kendisinden cikarildi**, kulaktan yazilmadi. Sonuc `index.html` icinde
`SONG` ve `DRUMS` sabitlerinde acik veri olarak durur.

- **Tempo:** 73.70 BPM (ultra slowed surumun olculen temposu), 8 barlik dongu
- **Gam:** Re majör / Si minör — `D E F# G A B C#`
- **Akorlar:** D – D – G – Bm (ikiser bar), 808 La pedali uzerinde
- **808:** A1 pedali, 4-5. barlarda G1'e iniyor
- **Kick:** kayitta olculen ~43.7 Hz temel frekansa akort edildi
- **Lead:** 25 nota, D4–B5 araliginda
- **Enstrumanlar:** 808 sub (glide + soft clip), cowbell (iki kare osilator + bandpass),
  trap kick, snare, hi-hat, uc osilatorlu lead, pad, riser ve impact
- **Efekt busleri:** uretilen impulse ile convolver reverb, noktali sekizlik delay

### Nasil cikarildi

1. mp3 → 22050 Hz mono, 2048'lik STFT (11.6 ms cerceve)
2. Yari-ton bantlarina indirgeme (MIDI 24–100)
3. Medyan suzgecli harmonik/perkusif ayrisma — davulu melodiden ayirmak icin
4. Tempo ve faz aramasi: dongu tekrarlari arasindaki benzerligi maksimize eden
   BPM/faz cifti → 73.70 BPM, 8 barlik (128 adim) dongu
5. En yuksek enerjili 3 dongunun medyani → gurultusu temizlenmis tek dongu
6. Harmonik toplamli salience (temel + oktav + beslik) → onset tepe noktalari →
   nota olaylari; oktav siciramasini onlemek icin sureklilik cezasi

**Dogrulama:** lead notalarinin **%88'i** kendi adiminda kayittaki en guclu uc perdeden
biri (808 icin %100). Melodik banttaki kroma ortusmesi **0.649**; ayni transkripsiyon
rastgele kaydirildiginda **0.437 (±0.046)** — yani **4.6 standart sapma** ustunde.

Yine de bu otomatik bir transkripsiyon: polifonik bir mikstan cikarildigi icin tek tek
notalarda hata payi var, orijinal kayittan hicbir ses ornegi kullanilmaz.

Kendi notalarini calmak icin iki yol var:

1. **MIDI birak.** Elindeki `.mid` dosyasini sayfaya surukle (veya `MIDI YUKLE` / `M`).
   Dosya tarayicida cozulur, notalar 16'lik grid'e oturur ve **ayni phonk sentezinden** calar.
   MIDI'de tempo varsa BPM ona gecer. 52'nin altindaki notalar 808'e, ustundekiler lead'e
   gider; 10. kanal (davul) atlanir; yerlesik pad kapanir ki yabanci tonla catismasin.
   Butona tekrar basinca yerlesik hook'a doner.
2. **Kodu duzenle.** `SONG.lead` ve `SONG.bass` nesnelerini degistir — anahtar 0-127
   arasi adim, deger `[[midi_notasi, 16'lik_cinsinden_sure], ...]`.

## Dizilim

| Bolum | Bar | Ne var |
|---|---|---|
| GIRIS | 8 | pad + cowbell + seyrek lead |
| YUKSELIS | 8 | hat, bass, riser |
| DROP | 16 | tam davul, 808, lead, impact |
| BREAK | 8 | pad + lead, davul yok |
| DROP II | 16 | hat roll, alternatif kick, clap |
| OUTRO | 8 | sonumlenme |

Bolumler sarkinin 8 barlik dongusuyle hizali; dongu bastan basa tekrar eder.

## Kontroller

| Tus | Islev |
|---|---|
| `Bosluk` | Oynat / duraklat |
| `C` | Kamera modu: SINEMA → SERBEST → KALABALIK |
| `N` / `→` | Sonraki parca |
| `P` / `←` | Onceki parca |
| `M` | Dosya yukle (.mp3 / .wav / .mid) |
| `S` | Kaynak: KAYIT ↔ SENTEZ |
| Cift dokunma | Oynat/duraklat (dokunmatik) |
| `H` | HUD ac/kapa |
| `F` | Tam ekran |
| Surukle | Serbest kamerada bakis (surukleyince otomatik gecer) |
| Dosya birak | .mp3/.wav → listeye eklenir ve calar &middot; .mid → notalar sentezle calar |
| Tekerlek | Zoom |

## URL parametreleri

| Parametre | Varsayilan | Aciklama |
|---|---|---|
| `?bpm=` | 73.7 | 40–220 arasi tempo (`?bpm=147` iki kat hizli phonk hissi) |
| `?vol=` | 0.8 | 0–1 baslangic ses seviyesi |
| `?quality=` | auto | `low` / `high` / `ultra` — kalabalik, lazer, LED yogunlugu |
| `?cam=` | cinema | `cinema` / `orbit` / `crowd` |
| `?debug=1` | kapali | Konsola sekans ve sahne logu |

Ornek: `index.html?bpm=147&quality=ultra&cam=crowd&debug=1`

## MIDI okuyucu

`parseMidi()` ve `melodyFromMidi()` harici kutuphane kullanmaz: Standard MIDI File
format 0 ve 1, running status, variable-length quantity, tempo meta (`FF 51`) ve sysex
atlama desteklenir. SMPTE bolme kullanan dosyalarda 480 tick/nota varsayilir. Bozuk dosya
ekranda hata banneri gosterir, konser calmaya devam eder. Sinir: 4 MB, adim basina 3 ses.

## Teknik notlar

- Bagimlilik: three.js r128 (CDN). CDN engellenirse ekranda hata banneri cikar.
- Ses zamanlamasi `AudioContext.currentTime` uzerinden 25 ms'lik lookahead scheduler ile
  yapilir; `setTimeout` jitter'i sese yansimaz.
- Gorsel tetikler ses zamaniyla ayni kuyruga yazilir (`engine.events`), kare dongusu bu
  kuyrugu `currentTime`'a gore tuketir — isik ve vurus kaymaz.
- Kalite katmani cihaz belleği/cekirdek sayisina gore secilir: kalabalik 420–2200 instance.
- `prefers-reduced-motion` acikken strobe ve kamera sarsintisi kisilir.
- Sekme arka plana alininca ses otomatik duraklar; kayit modunda konum korunur.
- Kayit modunda gorseller `AnalyserNode` uzerinden uyarlamali esikle surulur:
  her bant kendi hareketli ortalamasini asinca tetiklenir, boylece parcanin
  seviyesinden bagimsiz calisir.
- Yuklenen ses ve MIDI dosyalari tarayiciyi hic terk etmez; `FileReader` ile
  yerelde okunur, hicbir yere gonderilmez. Sinirlar: ses 40 MB, MIDI 4 MB.

## Kaynak

Butun nota, akor, tempo ve davul verisi kullanicinin yukledigi
`MIGUEL - PHONK (ULTRA SLOWED)` kaydinin sinyal analizinden gelir. Disaridan bir
nota tablosu veya ses ornegi kullanilmadi.


## Server.pro / Ubuntu tek komut kurulum

DNS A kaydini sunucunun public IP adresine yonlendirdikten sonra root Shell'de:

```bash
curl -fsSL https://raw.githubusercontent.com/pisanadam/miguel-konseri/claude/miguel-phonk-concert-3d-86i8i3/install-server.sh | bash
```

Kurucu alan adini sorar (varsayilan: `jennykonser.pisankus.dedyn.io`) ve `/admin31` icin admin sifresini gizli olarak ister. Admin sifresi GitHub reposuna yazilmaz; sadece sunucuda root tarafindan okunabilen `/etc/phonk-concert.env` dosyasinda tutulur.

Kurulum Node.js + FFmpeg + Nginx + Certbot'u kurar, 5 GiB ortak sarki deposunu korur/olusturur, yuklenen sesleri stereo Opus 32 kbps'e cevirir, systemd servisini kurar ve HTTPS reverse proxy'yi hazirlar.

Guncellemek icin ayni komutu tekrar calistirmak yeterlidir; `/srv/phonk-concert/tracks` altindaki yuklenmis sarkilar korunur.
