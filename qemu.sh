#!/bin/bash

KERNEL="osboot/bzImage"
SINGLE="osboot/single.gz"
MULTI="osboot/multi.gz"
ISO="osboot/farewell.iso"

# Opsi network QEMU (user-mode, tidak butuh sudo)
# Ini yang membuat OS bisa akses internet dari dalam QEMU
NET_OPTS="-netdev user,id=net0 -device virtio-net-pci,netdev=net0"

usage() {
    echo "Usage: $0 [--single | --multi | --all]"
    echo ""
    echo "  --single  Boot single-user filesystem langsung"
    echo "  --multi   Boot multi-user filesystem langsung"
    echo "  --all     Boot dari ISO (pilih single/multi via menu GRUB)"
    exit 1
}

case "$1" in
    --single)
        if [ ! -f "$KERNEL" ] || [ ! -f "$SINGLE" ]; then
            echo "[!] File tidak ditemukan. Jalankan kernel.sh dan single.sh dulu."
            exit 1
        fi
        echo "[*] Booting single-user filesystem..."
        echo "[*] Tekan Ctrl+A lalu X untuk keluar dari QEMU"
        qemu-system-x86_64 \
            -smp 2 \
            -m 256 \
            -kernel "$KERNEL" \
            -initrd "$SINGLE" \
            -append "console=ttyS0 rdinit=/init" \
            $NET_OPTS \
            -nographic
        ;;

    --multi)
        if [ ! -f "$KERNEL" ] || [ ! -f "$MULTI" ]; then
            echo "[!] File tidak ditemukan. Jalankan kernel.sh dan multi.sh dulu."
            exit 1
        fi
        echo "[*] Booting multi-user filesystem..."
        echo "[*] Tekan Ctrl+A lalu X untuk keluar dari QEMU"
        qemu-system-x86_64 \
            -smp 2 \
            -m 256 \
            -kernel "$KERNEL" \
            -initrd "$MULTI" \
            -append "console=ttyS0 rdinit=/init" \
            $NET_OPTS \
            -nographic
        ;;

    --all)
        if [ ! -f "$ISO" ]; then
            echo "[!] File ISO tidak ditemukan. Jalankan iso.sh dulu."
            exit 1
        fi
        echo "[*] Booting dari ISO (pilih filesystem di menu GRUB)..."
        echo "[*] Tekan Ctrl+A lalu X untuk keluar dari QEMU"
        qemu-system-x86_64 \
            -smp 2 \
            -m 256 \
            -cdrom "$ISO" \
            -boot d \
            $NET_OPTS \
            -nographic
        ;;

    *)
        usage
        ;;
esac
