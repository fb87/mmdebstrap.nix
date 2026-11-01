{
  description = "mmdebstrap packaged for Nix";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.zst";
  };

  outputs = inputs: let
    targetPkgs = {
      "aarch64-linux" = import inputs.nixpkgs { system = "aarch64-linux"; };
      "x86_64-linux" = import inputs.nixpkgs { system = "x86_64-linux"; };
    };
  in {
    packages = builtins.mapAttrs (system: pkgs: {
      mmdebstrap = pkgs.stdenvNoCC.mkDerivation {
        pname = "mmdebstrap";
        version = "1.6.0";

        src = pkgs.fetchgit {
          url = "https://gitlab.mister-muffin.de/josch/mmdebstrap.git";
          rev = "9aa28de934a3654657c879054965b1d358350448";
          hash = "sha256-pSmfyIYFSdD14p0B3/sEurGOekQpT8L7CaV17TemeEY=";
        };

        nativeBuildInputs = [ pkgs.glibc.dev pkgs.linuxHeaders pkgs.makeWrapper pkgs.perl ];

        installPhase = ''
          substituteInPlace mmdebstrap \
            --replace-fail "/usr/lib/apt/apt-helper" apt-helper
          install -Dm755 mmdebstrap $out/bin/mmdebstrap
          install -Dm644 <(pod2man mmdebstrap) $out/share/man/man1/mmdebstrap.1
          install -Dm644 /dev/null $out/etc/apt.conf
          printf '%s\n' \
            'Dir::Etc::Trusted "/etc/apt/trusted.gpg";' \
            'Dir::Etc::TrustedParts "/etc/apt/trusted.gpg.d";' \
            'DPkg::Path "/usr/sbin:/usr/bin:/sbin:/bin";' \
            > $out/etc/apt.conf
          mkdir -p $out/lib/perl5/sys
          (cd ${pkgs.glibc.dev}/include && h2ph -r -d $out/lib/perl5 .)
          (cd ${pkgs.linuxHeaders}/include && h2ph -r -d $out/lib/perl5 .)
          patchShebangs $out/bin/mmdebstrap
          mkdir -p $out/libexec/mmdebstrap
          printf '%s\n' \
            '#!${pkgs.bash}/bin/bash' \
            'if [ -n "''$APT_CONFIG" ] && [ -f "''$APT_CONFIG" ] && [ -w "''$APT_CONFIG" ]; then printf "%s\\n" "Dir::Etc etc/apt;" "Dir::Etc::parts apt.conf.d;" "Dir::Etc::sourceparts sources.list.d;" "Dir::Etc::sourcelist sources.list;" "Dir::State var/lib/apt;" "Dir::Cache var/cache/apt;" "Dir::Log var/log/apt;" "APT::Sandbox::User root;" >> "''$APT_CONFIG"; fi' \
            'if [ "''$1" = --version ]; then' \
            '  ${pkgs.apt}/bin/apt-get "''$@" 2>/dev/null || true' \
            '  exit 0' \
            'fi' \
            'exec ${pkgs.apt}/bin/apt-get -o APT::Sandbox::User=root -o Dir::Etc=etc/apt -o Dir::Etc::parts=apt.conf.d -o Dir::Etc::sourceparts=sources.list.d -o Dir::Etc::sourcelist=sources.list -o Dir::State=var/lib/apt -o Dir::Cache=var/cache/apt -o Dir::Log=var/log/apt -o Dir::Etc::TrustedParts=${pkgs.debian-archive-keyring}/etc/apt/trusted.gpg.d "''$@"' \
            > $out/libexec/mmdebstrap/apt-get
          printf '%s\n' \
            '#!${pkgs.bash}/bin/bash' \
            'if [ -n "''$APT_CONFIG" ] && [ -f "''$APT_CONFIG" ] && [ -w "''$APT_CONFIG" ]; then printf "%s\\n" "Dir::Etc etc/apt;" "Dir::Etc::parts apt.conf.d;" "Dir::Etc::sourceparts sources.list.d;" "Dir::Etc::sourcelist sources.list;" "Dir::State var/lib/apt;" "Dir::Cache var/cache/apt;" "Dir::Log var/log/apt;" "APT::Sandbox::User root;" >> "''$APT_CONFIG"; fi' \
            'if [ "''$1" = --version ]; then' \
            '  ${pkgs.apt}/bin/apt-cache "''$@" 2>/dev/null || true' \
            '  exit 0' \
            'fi' \
            'exec ${pkgs.apt}/bin/apt-cache -o Dir::Etc=etc/apt -o Dir::Etc::parts=apt.conf.d -o Dir::Etc::sourceparts=sources.list.d -o Dir::Etc::sourcelist=sources.list -o Dir::State=var/lib/apt -o Dir::Cache=var/cache/apt -o Dir::Log=var/log/apt -o Dir::Etc::TrustedParts=${pkgs.debian-archive-keyring}/etc/apt/trusted.gpg.d "''$@"' \
            > $out/libexec/mmdebstrap/apt-cache
          printf '%s\n' \
            '#!${pkgs.bash}/bin/bash' \
            'if [ -n "''$APT_CONFIG" ] && [ -f "''$APT_CONFIG" ] && [ -w "''$APT_CONFIG" ]; then printf "%s\\n" "Dir::Etc etc/apt;" "Dir::Etc::parts apt.conf.d;" "Dir::Etc::sourceparts sources.list.d;" "Dir::Etc::sourcelist sources.list;" "Dir::State var/lib/apt;" "Dir::Cache var/cache/apt;" "Dir::Log var/log/apt;" "APT::Sandbox::User root;" >> "''$APT_CONFIG"; fi' \
            'if [ "''$1" = --version ]; then' \
            '  ${pkgs.apt}/bin/apt-config "''$@" 2>/dev/null || true' \
            '  exit 0' \
            'fi' \
            'case "''$*" in' \
            '  *Dir::Etc::trusted/f*) printf "v=/etc/apt/trusted.gpg; export v\\n"; exit 0 ;;' \
            '  *Dir::Etc::trustedparts/d*) printf "v=/etc/apt/trusted.gpg.d; export v\\n"; exit 0 ;;' \
            '  *DPkg::Path*) printf "v=${pkgs.coreutils-full}/bin:/usr/sbin:/usr/bin:/sbin:/bin; export v\\n"; exit 0 ;;' \
            'esac' \
            'exec ${pkgs.apt}/bin/apt-config -o Dir::Etc=etc/apt -o Dir::Etc::parts=apt.conf.d -o Dir::Etc::sourceparts=sources.list.d -o Dir::Etc::sourcelist=sources.list -o Dir::State=var/lib/apt -o Dir::Cache=var/cache/apt -o Dir::Log=var/log/apt "''$@"' \
            > $out/libexec/mmdebstrap/apt-config
          chmod 755 $out/libexec/mmdebstrap/apt-get
          chmod 755 $out/libexec/mmdebstrap/apt-cache
          chmod 755 $out/libexec/mmdebstrap/apt-config
          printf '%s\n' \
            '#!${pkgs.bash}/bin/bash' \
            'if [ "''$1" = drop-privs ]; then exit 0; fi' \
            'exec ${pkgs.apt}/libexec/apt/apt-helper "''$@"' \
            > $out/libexec/mmdebstrap/apt-helper
          chmod 755 $out/libexec/mmdebstrap/apt-helper

          wrapProgram $out/bin/mmdebstrap \
            --set APT_CONFIG $out/etc/apt.conf \
            --set FAKECHROOT_EXCLUDE_PATH /nix:/dev \
            --prefix LD_LIBRARY_PATH : ${pkgs.libarchive.lib}/lib \
            --set PERL5LIB $out/lib/perl5 \
            --prefix PATH : ${pkgs.lib.makeBinPath [
              pkgs.apt
              pkgs.coreutils
              pkgs.coreutils-full
              pkgs.dpkg
              pkgs.fakechroot
              pkgs.fakeroot
              pkgs.findutils
              pkgs.gawk
              pkgs.gnugrep
              pkgs.gnused
              pkgs.gzip
              pkgs.gnutar
              pkgs.libarchive
              pkgs.util-linux
              pkgs.util-linux.bin
              pkgs.xz
            ]} \
            --prefix PATH : $out/libexec/mmdebstrap \
            --add-flags '--aptopt=APT::Sandbox::User=root' \
            --add-flags '--aptopt=Dir::Etc=etc/apt' \
            --add-flags '--aptopt=Dir::State=var/lib/apt' \
            --add-flags '--aptopt=Dir::Cache=var/cache/apt' \
            --add-flags '--aptopt=Dir::Log=var/log/apt'
        '';

        meta = {
          description = "An alternative to debootstrap using apt";
          homepage = "https://gitlab.mister-muffin.de/josch/mmdebstrap";
          license = pkgs.lib.licenses.mit;
          mainProgram = "mmdebstrap";
        };
      };

      default = inputs.self.packages.${system}.mmdebstrap;
    }) inputs.nixpkgs.legacyPackages;

    apps = builtins.mapAttrs (system: pkgs: {
      rootfs = {
        type = "app";
        program = "${pkgs.writeShellApplication {
          name = "mmdebstrap-rootfs";
          runtimeInputs = [
             inputs.self.packages.${system}.mmdebstrap
             pkgs.coreutils
             pkgs.cpio
             pkgs.curl
             pkgs.apt
             pkgs.debootstrap
             pkgs.dpkg
             pkgs.e2fsprogs
             pkgs.findutils
             pkgs.gnused
             pkgs.gnutar
             pkgs.gawk
             pkgs.qemu
          ];
          text = ''
            if (( $# < 4 )); then
              printf 'usage: %s DISTRO IMAGE SUITE ARCH [PACKAGE ...]\n' "$0" >&2
              exit 2
            fi

            distro=$1
            image=$2
            suite=$3
            arch=$4
            shift 4

            host_arch=$(uname -m)
            case "$host_arch:$arch" in
              aarch64:arm64|x86_64:amd64)
                native=yes
                ;;
              aarch64:amd64)
                native=no
                qemu="${pkgs.qemu}/bin/qemu-system-x86_64"
                target_kernel="${targetPkgs."x86_64-linux".linuxPackages.kernel}/bzImage"
                target_modules="${targetPkgs."x86_64-linux".linuxPackages.kernel.modules}/lib/modules"
                target_busybox="${targetPkgs."x86_64-linux".pkgsStatic.busybox}/bin/busybox"
                target_debootstrap="${targetPkgs."x86_64-linux".debootstrap}/bin/debootstrap"
                target_debootstrap_dir="${targetPkgs."x86_64-linux".debootstrap}/share/debootstrap"
                ;;
              x86_64:arm64)
                native=no
                qemu="${pkgs.qemu}/bin/qemu-system-aarch64"
                target_kernel="${targetPkgs."aarch64-linux".linuxPackages.kernel}/Image"
                target_modules="${targetPkgs."aarch64-linux".linuxPackages.kernel.modules}/lib/modules"
                target_busybox="${targetPkgs."aarch64-linux".pkgsStatic.busybox}/bin/busybox"
                target_debootstrap="${targetPkgs."aarch64-linux".debootstrap}/bin/debootstrap"
                target_debootstrap_dir="${targetPkgs."aarch64-linux".debootstrap}/share/debootstrap"
                ;;
              *)
                printf 'unsupported host/target architecture pair: %s -> %s\n' "$host_arch" "$arch" >&2
                exit 2
                ;;
            esac

            if [[ "$arch" == amd64 ]]; then
              machine=q35
              console=ttyS0
            else
              machine=virt
              console=ttyAMA0
            fi

            case "$distro" in
              debian)
                case "$arch" in
                  amd64) kernel=linux-image-amd64 ;;
                  arm64) kernel=linux-image-arm64 ;;
                  *) printf 'unsupported Debian architecture: %s\n' "$arch" >&2; exit 2 ;;
                esac
                mirror=https://deb.debian.org/debian
                keyring=${pkgs.debian-archive-keyring}/etc/apt/trusted.gpg.d
                packages="apt,dpkg,$kernel,initramfs-tools,initramfs-tools-core,kmod,busybox-static,tar,systemd-sysv,systemd,udev,passwd,debian-archive-keyring,usr-is-merged"
                components=()
                ;;
              ubuntu)
                case "$arch" in
                  amd64|arm64) kernel=linux-image-virtual ;;
                  *) printf 'unsupported Ubuntu architecture: %s\n' "$arch" >&2; exit 2 ;;
                esac
                 if [[ "$arch" == amd64 ]]; then
                   mirror=https://archive.ubuntu.com/ubuntu
                 else
                   mirror=https://ports.ubuntu.com/ubuntu-ports
                 fi
                keyring_dir=$(mktemp -d)
                trap 'rm -rf "$keyring_dir"' EXIT
                mkdir -p "$keyring_dir/etc/apt/trusted.gpg.d"
                curl --fail --silent --show-error --location \
                  --output "$keyring_dir/etc/apt/trusted.gpg.d/ubuntu-archive-keyring.gpg" \
                  "$mirror/project/ubuntu-archive-keyring.gpg"
                keyring="$keyring_dir/etc/apt/trusted.gpg.d"
                packages="apt,dpkg,$kernel,initramfs-tools,initramfs-tools-core,kmod,busybox-static,tar,systemd-sysv,systemd,udev,passwd,ubuntu-keyring,usr-is-merged"
                components=("--components=main,universe")
                ;;
              *) printf 'unsupported distribution: %s\n' "$distro" >&2; exit 2 ;;
            esac

            for package in "$@"; do
              packages="$packages,$package"
            done
            mkdir -p "$(dirname "$image")"

            if [[ "$native" == yes ]]; then
              hook=$(mktemp)
              trap 'rm -f "$hook"' EXIT
              cat > "$hook" <<'EOF'
              #!/bin/sh
              echo 'root:root' | chroot "$1" chpasswd
              printf 'proc /proc proc defaults 0 0\n' > "$1/etc/fstab"
              mkdir -p "$1/etc/systemd/system/getty.target.wants"
              ln -sf /lib/systemd/system/getty@.service \
                "$1/etc/systemd/system/getty.target.wants/getty@''${console}.service"
EOF
              chmod 755 "$hook"
              mmdebstrap --mode=unshare --architectures="$arch" \
                --keyring="$keyring" "''${components[@]}" --format=ext4 \
                --variant=minbase --include="$packages" \
                --customize-hook="$hook" "$suite" "$image" "$mirror"
              exit 0
            fi

            work=$(mktemp -d)
            cleanup_work() {
              rm -rf "$work"
            }
            trap cleanup_work EXIT
            chmod 755 "$work"
            downloadroot="$work/download"
            mkdir -p "$downloadroot"
            repo="$work/repo"
            mkdir -p "$repo"
            mmdebstrap --mode=fakechroot --skip=check/qemu --skip=cleanup/apt --skip=essential/unlink \
              --architectures="$arch" --keyring="$keyring" \
              "''${components[@]}" --format=directory --variant=extract \
              --include='?essential' --include="$packages" "$suite" "$downloadroot" "$mirror"
            cp -r "$downloadroot/var/cache/apt/archives/." "$repo/"

            kernel_file="$target_kernel"
            busybox_file="$target_busybox"
            [[ -r "$kernel_file" && -x "$busybox_file" ]] || {
              printf 'target Nix kernel or BusyBox is missing\n' >&2
              exit 1
            }

             initrd="$work/initrd"
             mkdir -p "$initrd/bin" "$initrd/dev" "$initrd/proc" "$initrd/sys" "$initrd/newroot" "$initrd/mnt/host" "$initrd/mnt/repo" "$initrd/nix" "$initrd/lib"
            cp "$busybox_file" "$initrd/bin/busybox"
            for applet in sh mount umount mkdir mknod modprobe ls cat cp ln rm touch switch_root chroot poweroff; do
              ln -s busybox "$initrd/bin/$applet"
            done
            if [[ -d "$target_modules" ]]; then
              cp -r "$target_modules" "$initrd/lib/"
              chmod -R u+w "$initrd/lib/modules"
            fi
            vm_packages="''${packages//,/ }"
            printf '%s\n' \
               '#!/bin/sh' \
               'set -x' \
               'set -e' \
               'trap "poweroff -f" EXIT' \
               'export PATH=/usr/sbin:/usr/bin:/sbin:/bin' \
               'mount -t devtmpfs devtmpfs /dev' \
              'mount -t proc proc /proc' \
               'mount -t sysfs sysfs /sys' \
               'modprobe -v virtio_pci' \
               'modprobe -v virtio_blk' \
               'modprobe -v ext4' \
               'modprobe -v 9pnet' \
               'modprobe -v 9p' \
               'modprobe -v 9pnet_virtio' \
               'mount -t ext4 /dev/vda /newroot' \
               'mount -t ext4 -o ro /dev/vdb /mnt/repo' \
               'mount -t 9p -o trans=virtio,version=9p2000.L hostshare /mnt/host' \
               'mount -t 9p -o trans=virtio,version=9p2000.L nixshare /nix' \
               'mkdir -p /newroot/mnt/repo' \
               'mount -o bind,ro /mnt/repo /newroot/mnt/repo' \
               'export DEBIAN_FRONTEND=noninteractive' \
               'export DEBOOTSTRAP_DIR=/mnt/host/debootstrap' \
               "''${target_debootstrap} --verbose --arch=$arch --unpack-tarball=/mnt/repo/bootstrap.tar.gz $suite /newroot file:///mnt/repo" \
               'mount -t proc proc /newroot/proc' \
               'mount -t sysfs sysfs /newroot/sys' \
               'mount -t devtmpfs devtmpfs /newroot/dev' \
               "chroot /newroot sh -c 'dpkg --force-overwrite --force-confold --skip-same-version --unpack /var/cache/apt/archives/*.deb'" \
               'chroot /newroot dpkg --configure -a || true' \
               "printf 'deb [trusted=yes] file:/mnt/repo $suite main\\n' > /newroot/etc/apt/sources.list" \
               'rm -f /newroot/etc/apt/sources.list.d/*' \
               "chroot /newroot apt-get -o APT::Sandbox::User=root update" \
               "chroot /newroot apt-get -o APT::Sandbox::User=root --yes --fix-broken install" \
               "chroot /newroot apt-get -o APT::Sandbox::User=root --yes --no-install-recommends install $vm_packages" \
               'echo root:root | chroot /newroot chpasswd || true' \
               'printf "proc /proc proc defaults 0 0\\n" > /newroot/etc/fstab' \
               'mkdir -p /newroot/etc/systemd/system/getty.target.wants' \
               "ln -sf /lib/systemd/system/getty@.service /newroot/etc/systemd/system/getty.target.wants/getty@''${console}.service" \
               'touch /mnt/host/rootfs-bootstrap-success 2>/dev/null || true' \
               "set -- /newroot/boot/vmlinuz-*; cp \"\$1\" /mnt/host/rootfs.kernel" \
               "set -- /newroot/boot/initrd.img-*; cp \"\$1\" /mnt/host/rootfs.initrd" \
               'mkdir -p /newroot/etc/systemd/system/multi-user.target.wants' \
               'printf "%s\\n" "[Unit]" "Description=Rootfs bootstrap test shutdown" "After=multi-user.target" "[Service]" "Type=oneshot" "ExecStart=/sbin/poweroff -f" "[Install]" "WantedBy=multi-user.target" > /newroot/etc/systemd/system/rootfs-bootstrap-shutdown.service' \
               'ln -sf /etc/systemd/system/rootfs-bootstrap-shutdown.service /newroot/etc/systemd/system/multi-user.target.wants/rootfs-bootstrap-shutdown.service' \
               'umount /mnt/host 2>/dev/null || true' \
               'umount /newroot/mnt/repo' \
               'umount /mnt/repo' \
               'umount /nix' \
               'trap - EXIT' \
               'exec switch_root /newroot /sbin/init' \
              > "$initrd/init"
            chmod 755 "$initrd/init"
            (cd "$initrd" && find . -print0 | cpio --null --create --format=newc) > "$work/initrd.img"

            blocks=2097152
            truncate --size=$((blocks * 4096)) "$image"
            mke2fs -q -F -t ext4 "$image" "$blocks"
            hostshare="$work/share"
            mkdir -p "$hostshare"
            cp -r "$target_debootstrap_dir" "$hostshare/debootstrap"
            chmod -R u+w "$hostshare/debootstrap"
            sed -i "s/^[[:space:]]*setup_available \$required \$base$/\t: # target apt handles the base set/" \
              "$hostshare/debootstrap/scripts/debian-common"
            deb_count=$(find "$repo" -type f -name '*.deb' | wc -l)
            if (( deb_count == 0 )); then
              printf 'host package repository is empty: %s\n' "$repo" >&2
              exit 1
            fi
            repo_index="$repo/dists/$suite/main/binary-$arch"
            mkdir -p "$repo_index"
            (cd "$repo" && dpkg-scanpackages --multiversion . /dev/null) \
              > "$repo_index/Packages"
            gzip --no-name --force "$repo_index/Packages"
            {
              printf '%s\n' "Suite: $suite" "Codename: $suite" 'Components: main' "Architectures: $arch"
              (cd "$repo/dists/$suite" && apt-ftparchive release .)
            } > "$repo_index/../../Release"
            debootstrap --arch="$arch" --variant=minbase --no-check-gpg \
              --make-tarball="$repo/bootstrap.tar.gz" \
              "$suite" "$work/debootstrap-download" "file://$repo"
            mkdir -p "$work/bootstrap-tar"
            tar --extract --gzip --file="$repo/bootstrap.tar.gz" --directory="$work/bootstrap-tar"
            truncate --size=0 "$work/bootstrap-tar/debootstrap/base"
            tar --create --gzip --file="$repo/bootstrap.tar.gz" --directory="$work/bootstrap-tar" .
            repo_used_kb=$(du --summarize --block-size=1024 "$repo" | cut -f1)
            repo_blocks=$((repo_used_kb + 65536))
            repo_image="$work/repo.ext4"
            truncate --size=$((repo_blocks * 4096)) "$repo_image"
            mke2fs -q -F -t ext4 -d "$repo" "$repo_image" "$repo_blocks"
            timeout --foreground 1200 "$qemu" -machine "$machine" -accel tcg,thread=multi -smp 4 -m 2048 -nographic \
              -kernel "$kernel_file" -initrd "$work/initrd.img" \
              -append "console=$console root=/dev/vda rw systemd.unit=multi-user.target" \
              -drive "file=$image,if=virtio,format=raw" \
              -drive "file=$repo_image,if=virtio,format=raw,readonly=on" \
              -fsdev "local,id=share,path=$hostshare,security_model=none" \
              -fsdev "local,id=nixshare,path=/nix,security_model=none" \
              -device virtio-9p-pci,fsdev=share,mount_tag=hostshare \
              -device virtio-9p-pci,fsdev=nixshare,mount_tag=nixshare \
              -no-reboot
            [[ -e "$hostshare/rootfs-bootstrap-success" ]] || {
              printf 'QEMU bootstrap did not report success\n' >&2
              exit 1
            }
            [[ -s "$hostshare/rootfs.kernel" && -s "$hostshare/rootfs.initrd" ]] || {
              printf 'target kernel or initrd was not generated\n' >&2
              exit 1
            }
            kernel_output="''${image}.kernel"
            initrd_output="''${image}.initrd"
            cp "$hostshare/rootfs.kernel" "$kernel_output"
            cp "$hostshare/rootfs.initrd" "$initrd_output"
            timeout --foreground 60 "$qemu" -machine "$machine" -m 1024 -nographic \
              -kernel "$kernel_output" -initrd "$initrd_output" \
              -append "console=$console root=/dev/vda rw systemd.unit=multi-user.target" \
              -drive "file=$image,if=virtio,format=raw" \
              -no-reboot
          '';
        }}/bin/mmdebstrap-rootfs";
        meta.description = "Build Debian or Ubuntu rootfs images, using QEMU for cross architectures";
      };
    }) inputs.nixpkgs.legacyPackages;
  };
}
