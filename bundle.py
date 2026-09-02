#!/usr/bin/env python3
"""index.html + ses dosyalarindan tek parca, cevrimdisi calisan konser uretir.

Her parca base64 olarak bir <script class="song-data"> blogunda gomulur; sayfa
acilir acilmaz calma listesiyle baslar (N/P ile gecis). Base64 govdesi ancak o
parca calmaya geldiginde cozulur, hepsi pesin acilmaz. --three verilirse three.js
de gomulur ve dosya internet olmadan, cift tiklamayla (file://) calisir.

Kullanim:
  python3 bundle.py -a 1.mp3 -a 2.mp3 -a 3.mp3 --three three.min.js -o konser.html
  python3 bundle.py -a tracks/*.mp3                  # kabuk genislemesi de olur
  python3 bundle.py -a song.mp3 --no-audio-check     # bicim kontrolunu atla
"""

import argparse
import base64
import logging
import mimetypes
import os
import re
import sys

LOG = logging.getLogger("bundle")

SCRIPT_TAG = re.compile(
    r'<script\s+src="https://cdnjs\.cloudflare\.com/ajax/libs/three\.js/[^"]+"\s*></script>'
)
ANCHOR = "<script>\n\"use strict\";"

AUDIO_MAGIC = {
    b"ID3": "mp3",
    b"\xff\xfb": "mp3",
    b"\xff\xf3": "mp3",
    b"\xff\xf2": "mp3",
    b"RIFF": "wav",
    b"OggS": "ogg",
    b"fLaC": "flac",
}

MAX_AUDIO_MB = 60      # tek parca
MAX_TOTAL_MB = 120     # toplam gomulu ses


def sniff_audio(head: bytes) -> str:
    """Dosyanin basindan ses bicimini tahmin eder; taninmazsa bos doner."""
    for magic, kind in AUDIO_MAGIC.items():
        if head.startswith(magic):
            return kind
    if head[4:8] == b"ftyp":
        return "m4a"
    return ""


def read_file(path: str, what: str) -> bytes:
    if not os.path.isfile(path):
        raise SystemExit(f"hata: {what} bulunamadi: {path}")
    try:
        with open(path, "rb") as fh:
            return fh.read()
    except OSError as exc:
        raise SystemExit(f"hata: {what} okunamadi: {exc}")


def track_name(path):
    """Dosya adindan gosterilecek parca adi: uzanti ve sayi oneki atilir."""
    stem = os.path.splitext(os.path.basename(path))[0]
    stem = re.sub(r"^\s*\d+\s*[-._)]\s*", "", stem)
    stem = stem.replace("_", " ").strip()
    return stem or "parca"


def esc_attr(text):
    return (text.replace("&", "&amp;").replace('"', "&quot;")
                .replace("<", "&lt;").replace(">", "&gt;"))


def build(page_path, audio_paths, three_path, out_path, check_audio=True):
    page = read_file(page_path, "sayfa").decode("utf-8")
    LOG.info("sayfa: %s (%.1f KB)", page_path, len(page) / 1024)

    if ANCHOR not in page:
        raise SystemExit(
            "hata: sayfada beklenen betik baslangici yok — index.html degistirilmis olabilir."
        )

    blocks, total = [], 0
    for i, audio_path in enumerate(audio_paths, 1):
        audio = read_file(audio_path, "ses dosyasi")
        size_mb = len(audio) / 1024 / 1024
        if size_mb > MAX_AUDIO_MB:
            raise SystemExit(
                f"hata: {audio_path} {size_mb:.1f} MB — parca basina {MAX_AUDIO_MB} MB siniri asiliyor."
            )
        total += size_mb
        if total > MAX_TOTAL_MB:
            raise SystemExit(
                f"hata: toplam ses {total:.1f} MB — {MAX_TOTAL_MB} MB sinirini asiyor."
            )

        kind = sniff_audio(audio[:12])
        if check_audio and not kind:
            raise SystemExit(
                f"hata: {audio_path} taninan bir ses bicimi degil (mp3/wav/ogg/flac/m4a). "
                "Yine de denemek icin --no-audio-check kullan."
            )

        name = track_name(audio_path)
        mime = mimetypes.guess_type(audio_path)[0] or "audio/mpeg"
        b64 = base64.b64encode(audio).decode("ascii")
        blocks.append(
            f'<script class="song-data" type="text/plain" '
            f'data-name="{esc_attr(name)}" data-mime="{mime}">{b64}</script>'
        )
        LOG.info("parca %d: %s (%.2f MB %s -> %.2f MB base64)",
                 i, name, size_mb, kind or "?", len(b64) / 1024 / 1024)

    page = page.replace(ANCHOR, "\n".join(blocks) + "\n" + ANCHOR, 1)
    LOG.info("gomuldu: %d parca, %.2f MB ham ses", len(audio_paths), total)

    if three_path:
        three = read_file(three_path, "three.js").decode("utf-8")
        if "THREE" not in three:
            raise SystemExit(f"hata: {three_path} three.js gibi gorunmuyor.")
        if not SCRIPT_TAG.search(page):
            raise SystemExit("hata: sayfada three.js CDN etiketi bulunamadi.")
        page = SCRIPT_TAG.sub(lambda _: "<script>" + three + "</script>", page, count=1)
        LOG.info("three.js gomuldu: %.1f KB — sayfa artik cevrimdisi calisir", len(three) / 1024)
    else:
        LOG.warning("three.js gomulmedi: sayfa acilirken internet gerekecek (--three ile gom)")

    try:
        with open(out_path, "w", encoding="utf-8") as fh:
            fh.write(page)
    except OSError as exc:
        raise SystemExit(f"hata: cikti yazilamadi: {exc}")

    LOG.info("yazildi: %s (%.2f MB)", out_path, os.path.getsize(out_path) / 1024 / 1024)
    return out_path


def main(argv=None):
    ap = argparse.ArgumentParser(
        description="Konseri tek dosyaya paketler.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    ap.add_argument("-p", "--page", default="index.html", help="kaynak sayfa")
    ap.add_argument("-a", "--audio", required=True, action="append", metavar="DOSYA",
                    help="gomulecek ses dosyasi; sirayla birden fazla kez verilebilir")
    ap.add_argument("-t", "--three", help="gomulecek three.min.js (cevrimdisi calismasi icin)")
    ap.add_argument("-o", "--out", default="konser.html", help="cikti dosyasi")
    ap.add_argument("--no-audio-check", action="store_true", help="ses bicimi kontrolunu atla")
    ap.add_argument("-v", "--verbose", action="store_true", help="ayrintili log")
    args = ap.parse_args(argv)

    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.INFO,
        format="%(levelname)s: %(message)s",
    )

    if os.path.abspath(args.out) == os.path.abspath(args.page):
        raise SystemExit("hata: cikti kaynak sayfanin uzerine yazamaz.")

    missing = [p for p in args.audio if not os.path.isfile(p)]
    if missing:
        raise SystemExit("hata: bulunamayan ses dosyalari: " + ", ".join(missing))

    build(args.page, args.audio, args.three, args.out, check_audio=not args.no_audio_check)
    return 0


if __name__ == "__main__":
    sys.exit(main())
