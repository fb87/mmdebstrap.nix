{
  description = "mmdebstrap packaged for Nix";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.zst";
  };

  outputs = inputs: {
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
  };
}
