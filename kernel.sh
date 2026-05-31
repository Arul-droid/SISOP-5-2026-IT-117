#!/bin/bash
set -e

KERNEL_VERSION="6.1.1"
KERNEL_DIR="linux-${KERNEL_VERSION}"

# ─── 1. Download ────────────────────────────────────────────────────────────
if [ ! -f "${KERNEL_DIR}.tar.xz" ]; then
    echo "[*] Mengunduh kernel ${KERNEL_VERSION}..."
    wget "https://cdn.kernel.org/pub/linux/kernel/v6.x/${KERNEL_DIR}.tar.xz"
else
    echo "[*] File kernel sudah ada, skip download."
fi

# ─── 2. Ekstrak ─────────────────────────────────────────────────────────────
if [ ! -d "$KERNEL_DIR" ]; then
    echo "[*] Mengekstrak kernel..."
    tar -xf "${KERNEL_DIR}.tar.xz"
fi

cd "$KERNEL_DIR"

# ─── 3. Konfigurasi ─────────────────────────────────────────────────────────
if [ -s "../.config" ]; then
    echo "[*] Menggunakan .config yang sudah ada..."
    cp "../.config" .config
    make olddefconfig
else
    echo "[*] Membuat konfigurasi kernel minimal..."
    make tinyconfig

    # General
    scripts/config --enable CONFIG_64BIT
    scripts/config --enable CONFIG_PRINTK
    scripts/config --enable CONFIG_FUTEX
    scripts/config --enable CONFIG_BLK_DEV_INITRD
    scripts/config --enable CONFIG_TMPFS
    scripts/config --enable CONFIG_CGROUPS

    # TTY & Console
    scripts/config --enable CONFIG_TTY
    scripts/config --enable CONFIG_SERIAL_8250
    scripts/config --enable CONFIG_SERIAL_8250_CONSOLE
    scripts/config --enable CONFIG_VIRTIO_CONSOLE

    # Executable formats
    scripts/config --enable CONFIG_BINFMT_ELF
    scripts/config --enable CONFIG_BINFMT_SCRIPT

    # Filesystem
    scripts/config --enable CONFIG_PROC_FS
    scripts/config --enable CONFIG_SYSFS
    scripts/config --enable CONFIG_DEVTMPFS
    scripts/config --enable CONFIG_DEVTMPFS_MOUNT
    scripts/config --enable CONFIG_FUSE_FS
    scripts/config --enable CONFIG_EXT4_FS
    scripts/config --enable CONFIG_EXT2_FS

    # Networking
    scripts/config --enable CONFIG_NET
    scripts/config --enable CONFIG_UNIX
    scripts/config --enable CONFIG_INET
    scripts/config --enable CONFIG_PACKET
    scripts/config --enable CONFIG_VIRTIO_NET

    # Virtio drivers
    scripts/config --enable CONFIG_VIRTIO
    scripts/config --enable CONFIG_VIRTIO_PCI
    scripts/config --enable CONFIG_VIRTIO_BLK

    # Block devices
    scripts/config --enable CONFIG_BLK_DEV_LOOP
    scripts/config --enable CONFIG_BLK_DEV_RAM

    make olddefconfig

    # Simpan .config ke folder soal
    cp .config "../.config"
    echo "[*] .config disimpan ke soal_1/.config"
fi

# ─── 4. Kompilasi ────────────────────────────────────────────────────────────
echo "[*] Mengompilasi kernel (15-60 menit tergantung CPU)..."
make -j$(nproc) bzImage

# ─── 5. Salin output ─────────────────────────────────────────────────────────
mkdir -p ../osboot
cp arch/x86/boot/bzImage ../osboot/bzImage
echo "[+] Selesai! Output: osboot/bzImage"
ls -lh ../osboot/bzImage
