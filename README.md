# MIGUEL PHONK — 3D Konser

Tarayicida calisan tek dosyalik 3D konser. Sarkinin hook'u ses dosyasi olarak degil,
**Web Audio API ile canli sentezlenerek** calinir; sahnedeki isik, lazer, LED duvar ve
kalabalik ayni sesin kendisine tepki verir.

Ac: `index.html` — kurulum yok, derleme yok.

## Muzik

Notalar kod icinde acik veri olarak durur (`index.html` icinde `LEAD`, `BASS`, `CHORDS`, `DRUMS`).

- **Ton:** Si minor (B minor) — `59 61 62 64 66 67 69`
- **Akor dongusu:** Bm – G – D – A (4 bar)
- **Tempo:** 140 BPM, 16'lik grid, bar basina 16 adim
- **Enstrumanlar:** 808 sub (glide + soft clip), cowbell (iki kare osilator + bandpass),
  trap kick, snare, hi-hat, uc osilatorlu lead, pad, riser ve impact
- **Efekt busleri:** uretilen impulse ile convolver reverb, noktali sekizlik delay

Lead hattı, Miguel'in phonk edit'lerinden tanidik hook'un **kulaktan yeniden yazilmis
yaklasik bir uyarlamasidir** — nota nota dogrulanmis bir transkripsiyon degildir, orijinal
kayittan hicbir ses ornegi kullanilmaz. Kendi melodini yazmak icin `LEAD` dizisini degistir:
her giris `[adim, midi_notasi, 16'lik_cinsinden_sure]`.

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
| `H` | HUD ac/kapa |
| `F` | Tam ekran |
| Surukle | Serbest kamerada bakis (surukleyince otomatik gecer) |
| Tekerlek | Zoom |

## URL parametreleri

| Parametre | Varsayilan | Aciklama |
|---|---|---|
| `?bpm=` | 140 | 60–200 arasi tempo |
| `?vol=` | 0.8 | 0–1 baslangic ses seviyesi |
| `?quality=` | auto | `low` / `high` / `ultra` — kalabalik, lazer, LED yogunlugu |
| `?cam=` | cinema | `cinema` / `orbit` / `crowd` |
| `?debug=1` | kapali | Konsola sekans ve sahne logu |

Ornek: `index.html?bpm=150&quality=ultra&cam=crowd&debug=1`

## Teknik notlar

- Bagimlilik: three.js r128 (CDN). CDN engellenirse ekranda hata banneri cikar.
- Ses zamanlamasi `AudioContext.currentTime` uzerinden 25 ms'lik lookahead scheduler ile
  yapilir; `setTimeout` jitter'i sese yansimaz.
- Gorsel tetikler ses zamaniyla ayni kuyruga yazilir (`engine.events`), kare dongusu bu
  kuyrugu `currentTime`'a gore tuketir — isik ve vurus kaymaz.
- Kalite katmani cihaz belleği/cekirdek sayisina gore secilir: kalabalik 420–2200 instance.
- `prefers-reduced-motion` acikken strobe ve kamera sarsintisi kisilir.
- Sekme arka plana alininca ses otomatik duraklar.
