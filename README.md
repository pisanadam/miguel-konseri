# MIGUEL PHONK — 3D Konser

Tarayicida calisan tek dosyalik 3D konser. Sarkinin hook'u ses dosyasi olarak degil,
**Web Audio API ile canli sentezlenerek** calinir; sahnedeki isik, lazer, LED duvar ve
kalabalik ayni sesin kendisine tepki verir.

Ac: `index.html` — kurulum yok, derleme yok.

## Muzik

Notalar kod icinde acik veri olarak durur (`index.html` icinde `LEAD`, `BASS`, `CHORDS`, `DRUMS`).

- **Ton:** Fa# minor (F# minor) — `66 68 69 71 73 74 76`
- **Akor dongusu:** D – F#m – C#m – Bm (4 bar) — sarkinin gercek progresyonu
- **Tempo:** varsayilan 150 BPM (phonk edit hizi). Orijinal kayit ~80 BPM'dir;
  `?bpm=80` ile normal hiza dusurebilirsin.
- **Ses araligi:** lead A3–E5 icinde tutuldu
- **Enstrumanlar:** 808 sub (glide + soft clip), cowbell (iki kare osilator + bandpass),
  trap kick, snare, hi-hat, uc osilatorlu lead, pad, riser ve impact
- **Efekt busleri:** uretilen impulse ile convolver reverb, noktali sekizlik delay

Ton, akor dongusu ve tempo iliskisi sarkinin kendisinden alindi. **Lead hatti ise bu armoni
uzerine yazilmis bir uyarlamadir** — nota nota dogrulanmis bir transkripsiyon degildir ve
orijinal kayittan hicbir ses ornegi kullanilmaz.

Gercek notalari calmak icin iki yol var:

1. **MIDI birak.** Elindeki `.mid` dosyasini sayfaya surukle (veya `MIDI YUKLE` / `M`).
   Dosya tarayicida cozulur, notalar 16'lik grid'e oturur ve **ayni phonk sentezinden** calar.
   MIDI'de tempo varsa BPM ona gecer. 52'nin altindaki notalar 808'e, ustundekiler lead'e
   gider; 10. kanal (davul) atlanir; yerlesik pad kapanir ki yabanci tonla catismasin.
   Butona tekrar basinca yerlesik hook'a doner.
2. **Kodu duzenle.** `LEAD` dizisini degistir — her giris
   `[adim, midi_notasi, 16'lik_cinsinden_sure]`.

## Dizilim

| Bolum | Bar | Ne var |
|---|---|---|
| GIRIS | 4 | pad + cowbell + seyrek lead |
| YUKSELIS | 4 | hat, bass, riser |
| DROP | 8 | tam davul, 808, lead, impact |
| BREAK | 4 | pad + lead, davul yok |
| DROP II | 8 | hat roll, alternatif kick, clap |
| OUTRO | 4 | sonumlenme |

Dongu bastan basa tekrar eder.

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
| `?bpm=` | 150 | 40–220 arasi tempo (orijinal kayit icin `80`) |
| `?vol=` | 0.8 | 0–1 baslangic ses seviyesi |
| `?quality=` | auto | `low` / `high` / `ultra` — kalabalik, lazer, LED yogunlugu |
| `?cam=` | cinema | `cinema` / `orbit` / `crowd` |
| `?debug=1` | kapali | Konsola sekans ve sahne logu |

Ornek: `index.html?bpm=80&quality=ultra&cam=crowd&debug=1`

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

## Kaynaklar

Ton, tempo ve akor bilgisi icin:
[Hooktheory](https://www.hooktheory.com/theorytab/view/miguel/sure-thing) ·
[Chordify](https://chordify.net/chords/miguel-songs/sure-thing-chords) ·
[Musicnotes](https://www.musicnotes.com/sheetmusic/mtd.asp?ppn=MN0269591)
