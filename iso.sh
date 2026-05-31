#!/bin/bash
set -e

ISO_DIR="iso_build"
OUTPUT="osboot/farewell.iso"

# Cek file yang dibutuhkan ada
for f in osboot/bzImage osboot/single.gz osboot/multi.gz; do
    if [ ! -f "$f" ]; then
        echo "[!] File $f tidak ditemukan. Jalankan kernel.sh, single.sh, dan multi.sh dulu."
        exit 1
    fi
done

echo "[*] Membuat bootable ISO..."

# ─── 1. Buat struktur ISO ────────────────────────────────────────────────────
rm -rf "$ISO_DIR"
mkdir -p "$ISO_DIR/boot/grub"

# ─── 2. Salin kernel dan filesystem ─────────────────────────────────────────
cp osboot/bzImage   "$ISO_DIR/boot/"
cp osboot/single.gz "$ISO_DIR/boot/"
cp osboot/multi.gz  "$ISO_DIR/boot/"

# ─── 3. GRUB config ──────────────────────────────────────────────────────────
# Menu pilih single atau multi user filesystem
cat > "$ISO_DIR/boot/grub/grub.cfg" << 'EOF'
set timeout=10
set default=0

menuentry "Farewell Party - Single User" {
    linux  /boot/bzImage console=ttyS0 quiet
    initrd /boot/single.gz
}

menuentry "Farewell Party - Multi User" {
    linux  /boot/bzImage console=ttyS0 quiet
    initrd /boot/multi.gz
}
EOF

# ─── 4. Buat ISO ─────────────────────────────────────────────────────────────
mkdir -p osboot
grub-mkrescue -o "$OUTPUT" "$ISO_DIR" 2>/dev/null

# Bersihkan folder sementara
rm -rf "$ISO_DIR"

echo "[+] Selesai! Output: $OUTPUT"
ls -lh "$OUTPUT"
