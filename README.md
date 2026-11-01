# mmdebstrap.nix

A Nix flake packaging [mmdebstrap](https://gitlab.mister-muffin.de/josch/mmdebstrap),
an apt-based alternative to debootstrap.

## Usage

Build the package:

```sh
nix build .#mmdebstrap
```

Run it directly:

```sh
nix run .#mmdebstrap -- --version
```

Build a rootfs image:

```sh
nix run .#rootfs -- debian debian.ext4 bookworm arm64
```

Cross-architecture builds use QEMU system emulation from the Nix store:

```sh
nix run .#rootfs -- debian debian-amd64.ext4 bookworm amd64
```

The cross path prepares packages on the host, boots the target kernel under
QEMU, and completes package configuration inside the target VM. It uses a 9p
share for bootstrap status. Target kernels, modules, and static BusyBox are
selected from nixpkgs using the target system (`x86_64-linux` or
`aarch64-linux`), so cross builds use cached Nix artifacts rather than
cross-compiling them.

The package includes the runtime tools and compatibility support needed to run
mmdebstrap rootlessly on NixOS, including fakechroot, fakeroot, apt, dpkg, and
the generated Perl system header files.

## QEMU Image Test

The following creates a minimal arm64 Debian ext4 image with a kernel,
initramfs, systemd, and a serial console:

```sh
nix run .#mmdebstrap -- \
  --mode=unshare \
  --format=ext4 \
  --variant=essential \
  --include=linux-image-arm64,systemd-sysv,systemd,udev,debian-archive-keyring,passwd \
  --customize-hook='echo "root:root" | chroot "$1" chpasswd; \
    printf "proc /proc proc defaults 0 0\\n" > "$1/etc/fstab"; \
    mkdir -p "$1/etc/systemd/system/getty.target.wants"; \
    ln -sf /lib/systemd/system/getty@.service \
      "$1/etc/systemd/system/getty.target.wants/getty@ttyAMA0.service"' \
  unstable debian-arm64.ext4
```

Boot the resulting image with an arm64 QEMU binary and the kernel/initramfs
extracted from `/boot` in the image:

```sh
qemu-system-aarch64 \
  -machine virt -cpu max -m 1024 -nographic \
  -kernel vmlinuz -initrd initrd.img \
  -append 'root=/dev/vda rw rootwait console=ttyAMA0' \
  -drive file=debian-arm64.ext4,if=virtio,format=raw
```

## License

This flake is licensed under the [MIT License](LICENSE). mmdebstrap remains
under its upstream license.
