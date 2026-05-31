#!/bin/bash
set -e

if [ "$(id -u)" -ne 0 ]; then
    echo "[!] Jalankan dengan sudo: sudo ./multi.sh"
    exit 1
fi

WORK_DIR="multi_fs"
OUTPUT="osboot/multi.gz"

echo "[*] Membuat multi-user filesystem..."

# ─── 1. Buat struktur direktori ───────────────────────────────────────────────
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"/{bin,dev,proc,sys,etc,tmp,root}
mkdir -p "$WORK_DIR/home"/{henn,hann,viii,kids}

# ─── 2. Device files ─────────────────────────────────────────────────────────
cp -a /dev/null    "$WORK_DIR/dev/"
cp -a /dev/zero    "$WORK_DIR/dev/"
cp -a /dev/console "$WORK_DIR/dev/"
cp -a /dev/tty*    "$WORK_DIR/dev/" 2>/dev/null || true
mknod "$WORK_DIR/dev/fuse" c 10 229
chmod 666 "$WORK_DIR/dev/fuse"

# ─── 3. BusyBox ──────────────────────────────────────────────────────────────
cp /usr/bin/busybox "$WORK_DIR/bin/"
cd "$WORK_DIR/bin"
./busybox --install .
cd - > /dev/null

# ─── 4. Generate password hash ───────────────────────────────────────────────
echo "[*] Membuat hash password..."
HASH_ROOT=$(openssl passwd -1 root123)
HASH_HENN=$(openssl passwd -1 henn123)
HASH_HANN=$(openssl passwd -1 hann123)
HASH_VIII=$(openssl passwd -1 viii123)
HASH_KIDS=$(openssl passwd -1 kids123)

# ─── 5. /etc/passwd ──────────────────────────────────────────────────────────
cat > "$WORK_DIR/etc/passwd" << EOF
root:${HASH_ROOT}:0:0:root:/root:/bin/sh
henn:${HASH_HENN}:1000:1000::/home/henn:/bin/sh
hann:${HASH_HANN}:1001:1001::/home/hann:/bin/sh
viii:${HASH_VIII}:1002:1002::/home/viii:/bin/sh
kids:${HASH_KIDS}:1003:1003::/home/kids:/bin/sh
EOF

# ─── 6. /etc/group ───────────────────────────────────────────────────────────
cat > "$WORK_DIR/etc/group" << 'EOF'
root:x:0:root
henn:x:1000:henn
hann:x:1001:hann,henn
viii:x:1002:viii,henn,hann
kids:x:1003:kids,henn,hann,viii
EOF

# ─── 7. Permissions direktori ────────────────────────────────────────────────
chown -R 0:0       "$WORK_DIR/root"
chmod 700           "$WORK_DIR/root"

chown -R 1000:1000 "$WORK_DIR/home/henn"
chmod 770           "$WORK_DIR/home/henn"

chown -R 1001:1001 "$WORK_DIR/home/hann"
chmod 770           "$WORK_DIR/home/hann"

chown -R 1002:1002 "$WORK_DIR/home/viii"
chmod 770           "$WORK_DIR/home/viii"

chown -R 1003:1003 "$WORK_DIR/home/kids"
chmod 770           "$WORK_DIR/home/kids"

chmod 1777 "$WORK_DIR/tmp"
chmod 755  "$WORK_DIR/bin"
chmod 755  "$WORK_DIR/etc"

# ─── 8. Banner & Profile ─────────────────────────────────────────────────────
cat > "$WORK_DIR/etc/farewell_banner" << 'EOF'

+------------------------------------------+
|  _____                                   |
| |  ___|__ _ _ ____      ___  _| |        |
| | |_ / _` | '__\ \ /\ / / _ \| | |       |
| |  _| (_| | |   \ V  V /  __/ | |        |
| |_|  \__,_|_|    \_/\_/ \___|_|_|        |
|   ____            _                      |
|  |  _ \ __ _ _ __| |_ _   _              |
|  | |_) / _` | '__| __| | | |             |
|  |  __/ (_| | |  | |_| |_| |             |
|  |_|   \__,_|_|   \__|\__, |             |
|                        |___/             |
+------------------------------------------+

EOF

cat > "$WORK_DIR/etc/profile" << 'EOF'
FLAG="/tmp/.banner_shown_$(id -u)"
if [ ! -f "$FLAG" ]; then
    touch "$FLAG"
    cat /etc/farewell_banner
    echo "Welcome, $(whoami)."
    echo ""
fi

export HOME=$(grep "^$(whoami):" /etc/passwd | cut -d: -f6)
cd "$HOME" 2>/dev/null || true
EOF

# ─── 9. Init script ──────────────────────────────────────────────────────────
cat > "$WORK_DIR/init" << 'EOF'
#!/bin/sh

/bin/mount -t proc  none /proc
/bin/mount -t sysfs none /sys

# Setup network otomatis
ip link set eth0 up
ip addr add 10.0.2.15/24 dev eth0
ip route add default via 10.0.2.2
echo "nameserver 10.0.2.3" > /etc/resolv.conf

while true; do
    /bin/getty -L ttyS0 115200 vt100
    sleep 1
done
EOF
chmod +x "$WORK_DIR/init"

# ─── party package manager ───────────────────────────────────────────────────
cat > "$WORK_DIR/bin/party" << 'EOF'
#!/bin/sh
case "$1" in
    install)
        shift
        wget "http://example.com" -O /dev/null 2>&1 && \
        echo "[+] package $@ installed successfully" || \
        echo "[-] failed to install $@"
        ;;
    *)
        echo "Usage: party install <package>"
        ;;
esac
EOF
chmod +x "$WORK_DIR/bin/party"

# ─── FUSE program ────────────────────────────────────────────────────────────
cp /home/arul/soal_1/hello_fuse "$WORK_DIR/bin/hello_fuse"
chmod +x "$WORK_DIR/bin/hello_fuse"
mkdir -p "$WORK_DIR/mnt/fuse"

# ─── 10. Kemas menjadi initramfs ─────────────────────────────────────────────
mkdir -p osboot
cd "$WORK_DIR"
find . | cpio -oHnewc | gzip > "../$OUTPUT"
cd ..

rm -rf "$WORK_DIR"

echo "[+] Selesai! Output: $OUTPUT"
ls -lh "$OUTPUT"
