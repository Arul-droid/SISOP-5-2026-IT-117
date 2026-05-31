#!/bin/bash
set -e

# Harus dijalankan sebagai root
if [ "$(id -u)" -ne 0 ]; then
    echo "[!] Jalankan dengan sudo: sudo ./single.sh"
    exit 1
fi

WORK_DIR="single_fs"
OUTPUT="osboot/single.gz"

echo "[*] Membuat single-user filesystem..."

# ─── 1. Buat struktur direktori ───────────────────────────────────────────────
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"/{bin,dev,proc,sys,etc,tmp,root}

# ─── 2. Device files ─────────────────────────────────────────────────────────
cp -a /dev/null    "$WORK_DIR/dev/"
cp -a /dev/zero    "$WORK_DIR/dev/"
cp -a /dev/console "$WORK_DIR/dev/"
cp -a /dev/tty*    "$WORK_DIR/dev/" 2>/dev/null || true

# ─── 3. BusyBox ──────────────────────────────────────────────────────────────
cp /usr/bin/busybox "$WORK_DIR/bin/"
cd "$WORK_DIR/bin"
./busybox --install .
cd - > /dev/null

# ─── 4. /etc/passwd (root only, tanpa password) ──────────────────────────────
cat > "$WORK_DIR/etc/passwd" << 'EOF'
root::0:0:root:/root:/bin/sh
EOF

# ─── 5. Permissions ──────────────────────────────────────────────────────────
chmod 700  "$WORK_DIR/root"   # hanya root
chmod 1777 "$WORK_DIR/tmp"    # sticky bit, semua bisa akses

# ─── 6. Init script ──────────────────────────────────────────────────────────
# Single user: langsung masuk shell tanpa login
cat > "$WORK_DIR/init" << 'EOF'
#!/bin/sh

# Mount virtual filesystems
/bin/mount -t proc  none /proc
/bin/mount -t sysfs none /sys

# Setup network (untuk soal 8 - internet access)
ip link set eth0 up 2>/dev/null || true
udhcpc -i eth0 -q  2>/dev/null || true

# Langsung masuk shell sebagai root
exec /bin/sh
EOF
chmod +x "$WORK_DIR/init"

# ─── 7. Kemas menjadi initramfs ──────────────────────────────────────────────
mkdir -p osboot
cd "$WORK_DIR"
find . | cpio -oHnewc | gzip > "../$OUTPUT"
cd ..

# Bersihkan folder sementara
rm -rf "$WORK_DIR"

echo "[+] Selesai! Output: $OUTPUT"
ls -lh "$OUTPUT"
