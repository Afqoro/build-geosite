#!/bin/sh

# Direktori basis untuk domain-list-community
BASE_DIR="/root/buildgeo/domain-list-community"

# Direktori untuk custom files
CUSTOM_DIR="$BASE_DIR/my-custom"

# Direktori data
DATA_DIR="$BASE_DIR/data"

# Nama file category
CATEGORY_FILE="$BASE_DIR/category"

# Fungsi untuk mengunduh data menggunakan curl dengan retry dan timeout
fetch_with_retry() {
    local url="$1"
    local output_file="$2"
    local timeout_duration="$3"  # Durasi timeout dinamis
    local max_retries=2          # Maksimal jumlah percobaan
    local attempt=0
    local start_time
    local end_time
    local elapsed_time

    while [ $attempt -lt $max_retries ]; do
        attempt=$((attempt + 1))
        echo "[INFO] Percobaan ke-$attempt untuk mengunduh: $url (timeout $timeout_duration detik)"
        
        # Catat waktu mulai
        start_time=$(date +%s)
        
        # Unduh file menggunakan curl
        curl --max-time "$timeout_duration" -s "$url" -o "$output_file"
        
        # Catat waktu selesai
        end_time=$(date +%s)
        elapsed_time=$((end_time - start_time))
        echo "[DEBUG] Waktu yang dihabiskan untuk percobaan ke-$attempt: $elapsed_time detik"
        
        # Periksa apakah file hasil memiliki isi
        if [ -s "$output_file" ]; then
            echo "[INFO] Data berhasil diunduh dari: $url"
            break
        else
            echo "[WARNING] Tidak ada data ditemukan atau proses timeout untuk: $url"
            sleep 2  # Tunggu sebelum mencoba lagi
        fi
    done

    if [ ! -s "$output_file" ]; then
        echo "[ERROR] Gagal mengunduh data dari: $url setelah $max_retries percobaan."
    fi
}

# Pindah ke direktori basis
cd "$BASE_DIR"

run_download() {
# Hapus symlink lama di folder data
find "$DATA_DIR" -type l -exec rm -f {} +

# Unduh data menggunakan fungsi fetch_with_retry dengan timeout dinamis
echo "[PROCESS] BIG"
fetch_with_retry "https://big.oisd.nl/dnsmasq" "$CUSTOM_DIR/mahavpn-oisd-big" 90
perl -ne '/^server=\/([^\/]+)\// && print "$1\n"' "$CUSTOM_DIR/mahavpn-oisd-big" > "$CUSTOM_DIR/mahavpn-oisd-big.tmp"
mv "$CUSTOM_DIR/mahavpn-oisd-big.tmp" "$CUSTOM_DIR/mahavpn-oisd-big"
echo "[SUCCESS] BIG"

echo "[PROCESS] SMALL"
fetch_with_retry "https://small.oisd.nl/dnsmasq" "$CUSTOM_DIR/mahavpn-small-block" 60
perl -ne '/^server=\/([^\/]+)\// && print "$1\n"' "$CUSTOM_DIR/mahavpn-small-block" > "$CUSTOM_DIR/mahavpn-small-block.tmp"
mv "$CUSTOM_DIR/mahavpn-small-block.tmp" "$CUSTOM_DIR/mahavpn-small-block"
echo "[SUCCESS] SMALL"

echo "[PROCESS] NSFW"
fetch_with_retry "https://nsfw.oisd.nl/dnsmasq" "$CUSTOM_DIR/mahavpn-oisd-nsfw" 90
perl -ne '/^server=\/([^\/]+)\// && print "$1\n"' "$CUSTOM_DIR/mahavpn-oisd-nsfw" > "$CUSTOM_DIR/mahavpn-oisd-nsfw.tmp"
mv "$CUSTOM_DIR/mahavpn-oisd-nsfw.tmp" "$CUSTOM_DIR/mahavpn-oisd-nsfw"
echo "[SUCCESS] NSFW"

echo "[PROCESS] DEWARD"
fetch_with_retry "https://raw.githubusercontent.com/d3ward/toolz/master/src/d3host.txt" "$CUSTOM_DIR/mahavpn-d3ward" 60
awk '/^0\.0\.0\.0/ {print $2}' "$CUSTOM_DIR/mahavpn-d3ward" > "$CUSTOM_DIR/mahavpn-d3ward.tmp"
mv "$CUSTOM_DIR/mahavpn-d3ward.tmp" "$CUSTOM_DIR/mahavpn-d3ward"
echo "[SUCCESS] DEWARD"

echo "[PROCESS] ANTISCAM"
fetch_with_retry "https://raw.githubusercontent.com/malikshi/antiscam/refs/heads/main/antiscam.txt" "$CUSTOM_DIR/mahavpn-antiscam" 60
echo "[SUCCESS] ANTISCAM"

echo "[PROCESS] DOH"
fetch_with_retry "https://raw.githubusercontent.com/malikshi/dns_ip/main/domains-doh.txt" "$CUSTOM_DIR/mahavpn-doh" 60
echo "[SUCCESS] DOH"

echo "[PROCESS] MALICIOUS"
fetch_with_retry "https://raw.githubusercontent.com/elliotwutingfeng/Inversion-DNSBL-Blocklists/main/Google_hostnames_light.txt" "$CUSTOM_DIR/mahavpn-malicious" 60
cat "$CUSTOM_DIR/mahavpn-malicious" >> "$CUSTOM_DIR/mahavpn-small-block"
echo "[SUCCESS] MALICIOUS"

echo "[PROCESS] PHISHING DOMAIN BLOCKLIST"
fetch_with_retry "https://phishing.army/download/phishing_army_blocklist_extended.txt" "$CUSTOM_DIR/mahavpn-phishing" 60
# Ambil hanya domain valid (baris yang bukan komentar)
grep -v '^#' "$CUSTOM_DIR/mahavpn-phishing" | awk '{print $1}' > "$CUSTOM_DIR/mahavpn-phishing.tmp"
mv "$CUSTOM_DIR/mahavpn-phishing.tmp" "$CUSTOM_DIR/mahavpn-phishing"
echo "[SUCCESS] PHISHING DOMAIN BLOCKLIST"

echo "[PROCESS] ADWAY BLOCKLIST"
fetch_with_retry "https://adaway.org/hosts.txt" "$CUSTOM_DIR/mahavpn-adaway" 60
# Ambil domain dari format hosts (kolom kedua yang bukan komentar)
grep -v '^#' "$CUSTOM_DIR/mahavpn-adaway" | awk '{if ($2 != "") print $2}' > "$CUSTOM_DIR/mahavpn-adaway.tmp"
mv "$CUSTOM_DIR/mahavpn-adaway.tmp" "$CUSTOM_DIR/mahavpn-adaway"
echo "[SUCCESS] ADWAY BLOCKLIST"

echo "[PROCESS] WHATSAPP"
fetch_with_retry "https://blocklistproject.github.io/Lists/alt-version/whatsapp-nl.txt" "$CUSTOM_DIR/mahavpn-whatsapp-new" 60
# Ambil hanya domain valid (baris yang bukan komentar)
grep -v '^#' "$CUSTOM_DIR/mahavpn-whatsapp-new" | awk '{print $1}' > "$CUSTOM_DIR/mahavpn-whatsapp-new.tmp"
cat "$CUSTOM_DIR/mahavpn-whatsapp-new.tmp" >> "$CUSTOM_DIR/mahavpn-whatsapp"
rm -f "$CUSTOM_DIR/mahavpn-whatsapp-new"
echo "[SUCCESS] WHATSAPP"

python3 conv.py
bash line.sh
}

# run_download

# Copy setiap file dari my-custom ke data
for FILE in "$CUSTOM_DIR"/*; do
    FILE_NAME=$(basename "$FILE")
    DEST="$DATA_DIR/$FILE_NAME"
    
    # Hapus file lama jika sudah ada
    if [ -e "$DEST" ]; then
        rm -f "$DEST"
    fi

    # Copy file baru
    cp "$FILE" "$DEST"
done

# Tambahkan setiap file custom ke dalam file category
for FILE in "$CUSTOM_DIR"/*; do
    FILE_NAME=$(basename "$FILE")
    # Tambahkan nama file ke category jika belum ada
    if ! grep -q "$FILE_NAME" "$CATEGORY_FILE"; then
        echo "$FILE_NAME" >> "$CATEGORY_FILE"
    fi
done

# Membangun ulang file geosite.dat
./dlc -datapath "$DATA_DIR" -outputdir "$BASE_DIR/release" -outputname geosite.dat

# Salin file geosite.dat yang baru dibangun ke direktori yang digunakan oleh Xray
# sudo cp "$BASE_DIR/release/geosite.dat" /root/server/files/geo/geosite.dat

echo "Custom files linked and geosite.dat built successfully."