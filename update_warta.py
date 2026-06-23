"""
Script ini membaca data dari Google Sheet "Warta Jemaat GRIA" dan
menghasilkan ulang bagian tabel di warta.html serta informasi ibadah
di index.html, lalu menimpa file-file tersebut.

Cara pakai (lokal, untuk testing):
    export GOOGLE_SERVICE_ACCOUNT_KEY='<isi file JSON service account>'
    export SPREADSHEET_ID='1QJZf9hmfc5IQe5VE6OpHlLTmegBRhqyQq0wupx8z8fY'
    python update_warta.py

Di GitHub Actions, kedua env var di atas diambil dari repository secrets.
"""

import os
import json
import re
import sys
import gspread
from google.oauth2.service_account import Credentials

SPREADSHEET_ID = os.environ.get("SPREADSHEET_ID", "1QJZf9hmfc5IQe5VE6OpHlLTmegBRhqyQq0wupx8z8fY")
WARTA_HTML_PATH = os.environ.get("WARTA_HTML_PATH", "warta.html")
INDEX_HTML_PATH = os.environ.get("INDEX_HTML_PATH", "index.html")

SCOPES = ["https://www.googleapis.com/auth/spreadsheets.readonly"]


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
    return (text.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;"))


def build_jadwal_pelayanan_table(ws):
    """Sheet: Bidang, Minggu_1_Tanggal, Minggu_1_Nama, Minggu_2_Tanggal, Minggu_2_Nama, ..."""
    rows = ws.get_all_values()
    header_row_idx = next(i for i, r in enumerate(rows) if r and r[0] == "Bidang")
    data_rows = [r for r in rows[header_row_idx + 1:] if r and r[0].strip()]

    if not data_rows:
        return "<p style=\"color:var(--grey);\">Belum ada data jadwal pelayanan.</p>"

    n_weeks = (len(data_rows[0]) - 1) // 2
    tanggal_cols = [data_rows[0][1 + 2 * i] for i in range(n_weeks)]

    html = ['<table class="warta-table">', "  <tr>", "    <th>Bidang</th>"]
    for tgl in tanggal_cols:
        html.append(f"    <th>{escape_html(tgl)}</th>")
    html.append("  </tr>")

    for row in data_rows:
        bidang = row[0]
        html.append(f"  <tr><td>{escape_html(bidang)}</td>")
        for i in range(n_weeks):
            nama = row[2 + 2 * i] if len(row) > 2 + 2 * i else "-"
            html.append(f"<td>{escape_html(nama)}</td>")
        html.append("</tr>")
    html.append("</table>")
    return "\n    ".join(html)


def build_laporan_persembahan_table(ws):
    """Sheet: Pos, Tanggal_1, Nilai_1, Tanggal_2, Nilai_2, ..."""
    rows = ws.get_all_values()
    header_row_idx = next(i for i, r in enumerate(rows) if r and r[0] == "Pos")
    data_rows = [r for r in rows[header_row_idx + 1:] if r and r[0].strip()]

    if not data_rows:
        return "<p style=\"color:var(--grey);\">Belum ada data laporan persembahan.</p>"

    n_cols = (len(data_rows[0]) - 1) // 2
    tanggal_cols = [data_rows[0][1 + 2 * i] for i in range(n_cols)]

    html = ['<table class="warta-table">', "  <tr>", "    <th>Pos</th>"]
    for tgl in tanggal_cols:
        html.append(f"    <th>{escape_html(tgl)}</th>")
    html.append("  </tr>")

    for row in data_rows:
        pos = row[0]
        html.append(f"  <tr><td>{escape_html(pos)}</td>")
        for i in range(n_cols):
            nilai = row[2 + 2 * i] if len(row) > 2 + 2 * i else "-"
            html.append(f"<td>{escape_html(nilai)}</td>")
        html.append("</tr>")
    html.append("</table>")
    return "\n    ".join(html)


def build_info_umum_table(ws):
    """Sheet: Bidang, Tanggal_1, Nama_1, ... + baris terpisah 'Kalimat Info Umum' & 'Pekan Info'"""
    rows = ws.get_all_values()
    header_row_idx = next(i for i, r in enumerate(rows) if r and r[0] == "Bidang")

    data_rows = []
    for r in rows[header_row_idx + 1:]:
        if not r or not r[0].strip():
            break
        data_rows.append(r)

    info_kalimat = ""
    pekan_info = ""
    for r in rows:
        if r and r[0].strip().startswith("Kalimat Info Umum"):
            info_kalimat = r[1] if len(r) > 1 else ""
        if r and r[0].strip().startswith("Pekan Info"):
            pekan_info = r[1] if len(r) > 1 else ""

    if not data_rows:
        table_html = "<p style=\"color:var(--grey);\">Belum ada data.</p>"
    else:
        n_cols = (len(data_rows[0]) - 1) // 2
        tanggal_cols = [data_rows[0][1 + 2 * i] for i in range(n_cols)]

        html = ['<table class="warta-table">', "  <tr>", "    <th>Bidang</th>"]
        for tgl in tanggal_cols:
            html.append(f"    <th>{escape_html(tgl)}</th>")
        html.append("  </tr>")

        for row in data_rows:
            bidang = row[0]
            html.append(f"  <tr><td>{escape_html(bidang)}</td>")
            for i in range(n_cols):
                nama = row[2 + 2 * i] if len(row) > 2 + 2 * i else "-"
                html.append(f"<td>{escape_html(nama)}</td>")
            html.append("</tr>")
        html.append("</table>")
        table_html = "\n    ".join(html)

    return table_html, info_kalimat, pekan_info


def build_auto_block(jadwal_html, persembahan_html, info_table_html, info_kalimat, pekan_info):
    eyebrow_text = f"{escape_html(pekan_info)} • Update Mingguan" if pekan_info else "Update Mingguan"
    return f"""<!-- AUTO-GENERATED:START -->
  <section class="warta-hero">
    <span class="eyebrow">{eyebrow_text}</span>
    <h1>Warta <span class="accent">Jemaat</span></h1>
    <p>Informasi mingguan jemaat GRIA Pemulihan Palu — jadwal pelayanan, laporan persembahan, dan informasi umum. Diperbarui setiap minggu.</p>
  </section>

  <!-- ============ JADWAL PELAYANAN ============ -->
  <section class="warta-block">
    <h2><span class="badge-num">01</span> Jadwal Pelayanan</h2>
    <p class="block-lead">Pelayan ibadah raya minggu untuk beberapa pekan ke depan.</p>
  <div class="warta-scroll">
    {jadwal_html}
  </div>
  </section>

  <!-- ============ LAPORAN PERSEMBAHAN ============ -->
  <section class="warta-block">
    <h2><span class="badge-num">02</span> Laporan Persembahan</h2>
    <p class="block-lead">Rekapitulasi persembahan jemaat sebagai bentuk transparansi pengelolaan.</p>
  <div class="warta-scroll">
    {persembahan_html}
  </div>
  </section>

  <!-- ============ INFORMASI UMUM ============ -->
  <section class="warta-block">
    <h2><span class="badge-num">03</span> Informasi Umum</h2>
    <p class="block-lead">
      {escape_html(info_kalimat)}
    </p>

  <div class="warta-scroll">
    {info_table_html}
  </div>
  </section>
  <!-- AUTO-GENERATED:END -->"""


def replace_marker(content, marker_name, new_value):
    """Replace content between <!-- MARKER_NAME -->...<!-- /MARKER_NAME --> markers."""
    pattern = re.compile(
        r"(<!--\s*" + re.escape(marker_name) + r"\s*-->)"
        r".*?"
        r"(<!--\s*/" + re.escape(marker_name) + r"\s*-->)",
        re.DOTALL,
    )
    return pattern.sub(r"\1" + escape_html(new_value) + r"\2", content)


def read_info_ibadah(ws):
    """Sheet InfoIbadah: Row 1 = header (Tanggal, Tema, Pembicara), Row 2 = values."""
    rows = ws.get_all_values()
    if len(rows) < 2:
        return None
    header = [c.strip() for c in rows[0]]
    values = rows[1]

    def col(name):
        try:
            idx = header.index(name)
            return values[idx].strip() if idx < len(values) else ""
        except ValueError:
            return ""

    return {
        "tanggal": col("Tanggal"),
        "tema": col("Tema"),
        "pembicara": col("Pembicara"),
    }


def update_index_html(ibadah_info):
    """Update worship info markers in index.html with data from InfoIbadah sheet."""
    if not ibadah_info:
        print("Tidak ada data InfoIbadah, index.html tidak diupdate.")
        return False

    with open(INDEX_HTML_PATH, "r", encoding="utf-8") as f:
        content = f.read()

    new_content = content
    if ibadah_info["tanggal"]:
        new_content = replace_marker(new_content, "IBADAH_TANGGAL", ibadah_info["tanggal"])
    if ibadah_info["tema"]:
        new_content = replace_marker(new_content, "IBADAH_TEMA", ibadah_info["tema"])
    if ibadah_info["pembicara"]:
        new_content = replace_marker(new_content, "IBADAH_PEMBICARA", ibadah_info["pembicara"])

    if new_content == content:
        print("Tidak ada perubahan data ibadah, index.html tidak ditulis ulang.")
        return False

    with open(INDEX_HTML_PATH, "w", encoding="utf-8") as f:
        f.write(new_content)

    print("index.html berhasil diupdate dengan info ibadah dari Google Sheet.")
    return True


def main():
    client = get_client()
    sh = client.open_by_key(SPREADSHEET_ID)

    # --- Update warta.html ---
    ws_jadwal = sh.worksheet("JadwalPelayanan")
    ws_persembahan = sh.worksheet("LaporanPersembahan")
    ws_info = sh.worksheet("InfoUmum")

    jadwal_html = build_jadwal_pelayanan_table(ws_jadwal)
    persembahan_html = build_laporan_persembahan_table(ws_persembahan)
    info_table_html, info_kalimat, pekan_info = build_info_umum_table(ws_info)

    new_block = build_auto_block(jadwal_html, persembahan_html, info_table_html, info_kalimat, pekan_info)

    with open(WARTA_HTML_PATH, "r", encoding="utf-8") as f:
        content = f.read()

    start_marker = "<!-- AUTO-GENERATED:START -->"
    end_marker = "<!-- AUTO-GENERATED:END -->"

    start_idx = content.find(start_marker)
    end_idx = content.find(end_marker)

    if start_idx == -1 or end_idx == -1:
        print("ERROR: marker AUTO-GENERATED:START / END tidak ditemukan di warta.html")
        sys.exit(1)

    end_idx += len(end_marker)
    new_content = content[:start_idx] + new_block + content[end_idx:]

    if new_content == content:
        print("Tidak ada perubahan data warta, warta.html tidak ditulis ulang.")
    else:
        with open(WARTA_HTML_PATH, "w", encoding="utf-8") as f:
            f.write(new_content)
        print("warta.html berhasil diupdate dari Google Sheet.")

    # --- Update index.html (info ibadah) ---
    try:
        ws_ibadah = sh.worksheet("InfoIbadah")
        ibadah_info = read_info_ibadah(ws_ibadah)
        update_index_html(ibadah_info)
    except gspread.exceptions.WorksheetNotFound:
        print("Sheet 'InfoIbadah' belum ada di spreadsheet. Buat sheet tersebut untuk mengaktifkan auto-update info ibadah.")


if __name__ == "__main__":
    main()
