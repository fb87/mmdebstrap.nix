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
          install -Dm755 mmdebstrap $out/bin/mmdebstrap
          install -Dm644 <(pod2man mmdebstrap) $out/share/man/man1/mmdebstrap.1
          mkdir -p $out/lib/perl5/sys
          (cd ${pkgs.glibc.dev}/include && h2ph -r -d $out/lib/perl5 .)
          (cd ${pkgs.linuxHeaders}/include && h2ph -r -d $out/lib/perl5 .)
          patchShebangs $out/bin/mmdebstrap

          wrapProgram $out/bin/mmdebstrap \
            --set PERL5LIB $out/lib/perl5 \
            --prefix PATH : ${pkgs.lib.makeBinPath [
              pkgs.apt
              pkgs.coreutils
              pkgs.dpkg
              pkgs.fakechroot
              pkgs.fakeroot
              pkgs.findutils
              pkgs.gawk
              pkgs.gnugrep
              pkgs.gnused
              pkgs.gzip
              pkgs.gnutar
              pkgs.util-linux
              pkgs.xz
            ]}
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
