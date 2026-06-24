"""
Script ini membaca data ulang tahun dari Google Sheet tab "UlangTahun" dan
menghasilkan ulang section "Ulang Tahun Bulan Ini" di komunitas.html — hanya
menampilkan jemaat yang ulang tahun di bulan berjalan, diurutkan per tanggal.

Struktur kolom sheet yang diharapkan (baris pertama = header):
    Nama     | Tanggal | Bulan
    Andreas  |   3     |   9
    Maria    |   9     |   9

  Nama    : nama lengkap jemaat
  Tanggal : tanggal lahir (angka 1–31)
  Bulan   : bulan lahir (angka 1–12)

Cara pakai (lokal, untuk testing):
    export GOOGLE_SERVICE_ACCOUNT_KEY='<isi file JSON service account>'
    export SPREADSHEET_ID='1QJZf9hmfc5IQe5VE6OpHlLTmegBRhqyQq0wupx8z8fY'
    python update_ulang_tahun.py

Di GitHub Actions, kedua env var di atas diambil dari repository secrets.
"""

import os
import json
import sys
from datetime import date
import gspread
from google.oauth2.service_account import Credentials

SPREADSHEET_ID = os.environ.get("SPREADSHEET_ID", "1QJZf9hmfc5IQe5VE6OpHlLTmegBRhqyQq0wupx8z8fY")
KOMUNITAS_HTML_PATH = os.environ.get("KOMUNITAS_HTML_PATH", "komunitas.html")

SCOPES = ["https://www.googleapis.com/auth/spreadsheets.readonly"]

NAMA_BULAN = [
    "", "Januari", "Februari", "Maret", "April", "Mei", "Juni",
    "Juli", "Agustus", "September", "Oktober", "November", "Desember",
]


def get_client():
    key_json = os.environ.get("GOOGLE_SERVICE_ACCOUNT_KEY")
    if not key_json:
        print("ERROR: env var GOOGLE_SERVICE_ACCOUNT_KEY tidak ditemukan.")
        sys.exit(1)
    info = json.loads(key_json)
    creds = Credentials.from_service_account_info(info, scopes=SCOPES)
    return gspread.authorize(creds)


def escape_html(text):
    if text is None:
        return ""
    text = str(text)
    return (
        text.replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
    )


def get_initial(nama):
    nama = nama.strip()
    return nama[0].upper() if nama else "?"


def build_bday_html(ws, bulan_ini):
    """Baca sheet, filter bulan ini, kembalikan HTML untuk isi bday-section."""
    rows = ws.get_all_values()
    if len(rows) < 2:
        return _empty_msg("Belum ada data ulang tahun.")

    header = [c.strip().lower() for c in rows[0]]
    data_rows = rows[1:]

    try:
        idx_nama = next(i for i, h in enumerate(header) if "nama" in h)
        idx_tgl = next(i for i, h in enumerate(header) if "tanggal" in h)
        idx_bln = next(i for i, h in enumerate(header) if "bulan" in h)
    except StopIteration:
        print("ERROR: Kolom Nama/Tanggal/Bulan tidak ditemukan di sheet UlangTahun.")
        return _empty_msg("Format kolom sheet tidak sesuai.")

    daftar = []
    for row in data_rows:
        if len(row) <= max(idx_nama, idx_tgl, idx_bln):
            continue
        nama = row[idx_nama].strip()
        tgl_str = row[idx_tgl].strip()
        bln_str = row[idx_bln].strip()
        if not nama or not tgl_str or not bln_str:
            continue
        try:
            tgl = int(tgl_str)
            bln = int(bln_str)
        except ValueError:
            continue
        if bln == bulan_ini:
            daftar.append((tgl, nama))

    if not daftar:
        return _empty_msg(f"Tidak ada ulang tahun di bulan {NAMA_BULAN[bulan_ini]}.")

    daftar.sort(key=lambda x: x[0])
    nama_bulan = NAMA_BULAN[bulan_ini]

    cards = []
    for tgl, nama in daftar:
        inisial = escape_html(get_initial(nama))
        nama_esc = escape_html(nama)
        tgl_label = escape_html(f"{tgl} {nama_bulan}")
        cards.append(
            f'        <div class="bday-card">'
            f'<div class="bday-avatar">{inisial}</div>'
            f'<h4>{nama_esc}</h4>'
            f'<span>{tgl_label}</span>'
            f'</div>'
        )

    return '<div class="bday-carousel">\n' + "\n".join(cards) + "\n      </div>"


def _empty_msg(text):
    return f'<p style="color:var(--grey-dim);text-align:center;padding:32px 0;">{escape_html(text)}</p>'


def main():
    bulan_ini = date.today().month
    print(f"Memfilter ulang tahun untuk bulan: {NAMA_BULAN[bulan_ini]} ({bulan_ini})")

    client = get_client()
    sh = client.open_by_key(SPREADSHEET_ID)

    try:
        ws = sh.worksheet("UlangTahun")
    except gspread.exceptions.WorksheetNotFound:
        print("ERROR: Sheet 'UlangTahun' tidak ditemukan di spreadsheet.")
        sys.exit(1)

    bday_html = build_bday_html(ws, bulan_ini)

    with open(KOMUNITAS_HTML_PATH, "r", encoding="utf-8") as f:
        content = f.read()

    start_marker = "<!-- ULANG-TAHUN:START -->"
    end_marker = "<!-- ULANG-TAHUN:END -->"

    start_idx = content.find(start_marker)
    end_idx = content.find(end_marker)

    if start_idx == -1 or end_idx == -1:
        print("ERROR: marker ULANG-TAHUN:START / END tidak ditemukan di komunitas.html")
        sys.exit(1)

    end_idx += len(end_marker)
    replacement = f"{start_marker}\n      {bday_html}\n      {end_marker}"
    new_content = content[:start_idx] + replacement + content[end_idx:]

    if new_content == content:
        print("Tidak ada perubahan, komunitas.html tidak ditulis ulang.")
    else:
        with open(KOMUNITAS_HTML_PATH, "w", encoding="utf-8") as f:
            f.write(new_content)
        print("komunitas.html berhasil diupdate dengan data ulang tahun dari Google Sheet.")


if __name__ == "__main__":
    main()
