#!/bin/bash
set -e

# Cek semua file output ada
FILES_TO_BACKUP=(
    "osboot/bzImage"
    "osboot/single.gz"
    "osboot/multi.gz"
    "osboot/farewell.iso"
)

for f in "${FILES_TO_BACKUP[@]}"; do
    if [ ! -f "$f" ]; then
        echo "[!] File $f tidak ditemukan."
        echo "[!] Pastikan semua script sudah dijalankan: kernel.sh, single.sh, multi.sh, iso.sh"
        exit 1
    fi
done

# Format nama file sesuai soal: farewell_backup_[DDMMYYYY-HHMMSS].zip
TIMESTAMP=$(date +"%d%m%Y-%H%M%S")
OUTPUT="osboot/farewell_backup_[${TIMESTAMP}].zip"

echo "[*] Membuat backup: $OUTPUT"

zip "$OUTPUT" \
    osboot/bzImage \
    osboot/single.gz \
    osboot/multi.gz \
    osboot/farewell.iso

# Hapus file asli setelah di-zip
echo "[*] Menghapus file asli..."
rm -f osboot/bzImage osboot/single.gz osboot/multi.gz osboot/farewell.iso

echo "[+] Selesai! Backup tersimpan di: $OUTPUT"
ls -lh "$OUTPUT"
