# MIGUEL PHONK — 3D Konser

Tarayicida calisan tek dosyalik 3D konser. Sarkinin hook'u ses dosyasi olarak degil,
**Web Audio API ile canli sentezlenerek** calinir; sahnedeki isik, lazer, LED duvar ve
kalabalik ayni sesin kendisine tepki verir.

Ac: `index.html` — kurulum yok, derleme yok.

## Muzik

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
| `M` | MIDI yukle / yerlesik hook'a don |
| `H` | HUD ac/kapa |
| `F` | Tam ekran |
| Surukle | Serbest kamerada bakis (surukleyince otomatik gecer) |
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
- Sekme arka plana alininca ses otomatik duraklar.
- MIDI dosyasi tarayiciyi hic terk etmez; `FileReader` ile yerelde okunur.

## Kaynak

Butun nota, akor, tempo ve davul verisi kullanicinin yukledigi
`MIGUEL - PHONK (ULTRA SLOWED)` kaydinin sinyal analizinden gelir. Disaridan bir
nota tablosu veya ses ornegi kullanilmadi.
