{
  description = "crates.nix";
  inputs = {
    crates-io-index = {
      url = "github:rust-lang/crates.io-index";
      flake = false;
    };
  };

  outputs = {
    self,
    crates-io-index,
  }: {
    mkLib = {
      pkgs,
      crates-io ? crates-io-index,
    }: let
      inherit (pkgs) lib;

      trimNewline = str:
        if lib.hasSuffix "\n" str
        then builtins.substring 0 (builtins.stringLength str - 1) str
        else str;
      getFilename = name: let
        len = builtins.stringLength name;
      in
        if len > 3
        then "${crates-io}/${builtins.substring 0 2 name}/${builtins.substring 2 2 name}/${name}"
        else if len == 3
        then "${crates-io}/${toString len}/${builtins.substring 0 1 name}/${name}"
        else "${crates-io}/${toString len}/${name}";
      getVersions = name:
        builtins.map builtins.fromJSON (pkgs.lib.splitString "\n" (trimNewline (builtins.readFile (getFilename name))));

      getLatest = name: version:
        if version == "*"
        then lib.lists.last (getVersions name)
        else lib.lists.findFirst (v: v.vers == version) (throw "Unable to find a version for ${name} with ${version}") (getVersions name);
    in rec {
      fetchCrate = {
        pname,
        version ? "*",
        hash ? null,
      }: let
        crate = getLatest pname version;
        v = crate.vers;
        h =
          if hash == null
          then "sha256:${crate.cksum}"
          else hash;
        src = pkgs.fetchCrate {
          inherit pname;
          version = v;
          hash = h;
          unpack = false;
        };
      in
        pkgs.stdenvNoCC.mkDerivation {
          version = v;
          name = "${pname}-${v}-source";
          inherit src;
          buildPhase = ''
            cp -r ./ $out
          '';
        };
      buildCrate = name: {
        pname ? name,
        version ? "*",
        hash ? null,
        ...
      } @ flags: let
        crate = getLatest pname version;
        v = crate.vers;
        h =
          if hash == null
          then "sha256:${crate.cksum}"
          else hash;
      in
        pkgs.rustPlatform.buildRustPackage rec {
          inherit pname;
          version = v;
          src = fetchCrate {
            inherit pname;
            version = v;
            hash = h;
          };
          cargoLock = {
            lockFile = "${src}/Cargo.lock";
          };
        }
        // (removeAttrs flags ["pname" "version" "hash"]);
    };
  };
}
