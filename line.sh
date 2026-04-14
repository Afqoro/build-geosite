#!/bin/bash
# Fungsi untuk mencetak log
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Meminta input directory file
directory="/root/buildgeo/domain-list-community/my-custom/"

# Mengecek apakah direktori yang dimasukkan valid
if [ ! -d "$directory" ]; then
    log "Direktori tidak valid."
    exit 1
fi

# Membuat subdirektori /tmp di dalam direktori saat ini jika belum ada
if [ ! -d "./tmp" ]; then
    mkdir ./tmp
    log "Subdirektori ./tmp dibuat."
fi

# Daftar kata kunci yang akan dihapus
delete_list=("bit.ly" "localhost")

# Daftar file yang akan diproses untuk penghapusan kata kunci
target_files=("ads-customku" "mahavpn-antiscam" "mahavpn-d3ward" "mahavpn-oisd-big" "mahavpn-oisd-nsfw" "mahavpn-small-block" "mahavpn-adaway")

# Memproses setiap file dalam direktori
for file in "$directory"/*; do
    if [ -f "$file" ]; then
        # Membuat backup file ke dalam subdirektori /tmp
        cp "$file" "./tmp/$(basename "$file").tmp"
        log "Backup file dibuat: ./tmp/$(basename "$file").tmp"

        # Menghapus duplikasi lines dan membuat file sementara
        awk '!seen[$0]++' "$file" > "$file.tmp"

        # Log line yang terduplikasi
        log "Line yang terduplikasi di file $file:"
        sort "$file" | uniq -d

        # Mengecek apakah file ini termasuk dalam target_files untuk penghapusan kata kunci
        if [[ " ${target_files[@]} " =~ " $(basename "$file") " ]]; then
            log "File $(basename "$file") termasuk dalam target_files untuk penghapusan kata kunci."
            # Menghapus baris yang sama persis dengan kata kunci dari delete_list
            for keyword in "${delete_list[@]}"; do
                log "Menghapus baris yang sama persis dengan kata kunci: $keyword"
                grep -v -x "$keyword" "$file.tmp" > "$file.tmp.filtered"
                mv "$file.tmp.filtered" "$file.tmp"
            done
        else
            log "File $(basename "$file") tidak termasuk dalam target_files untuk penghapusan kata kunci."
        fi

        # Replace file asli dengan file tanpa duplikasi dan baris yang dihapus (jika ada)
        mv "$file.tmp" "$file"
        log "File $file telah diperbarui tanpa duplikasi dan baris yang berisi kata kunci (jika termasuk target_files)."
    fi
done

log "Proses pengecekan duplikasi dan penghapusan baris selesai."