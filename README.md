# Crates.nix

A simple wrapper using crates-io-index for nix

If you need a package from crates.io which is not packaged or available in nixpkgs then you can use this

By default this will use the latest version available on crates.io (you can use `nix flake update crates-nix` to update crates-io-index)

This has two main functions `buildCrate` and `fetchCrate`

## `buildCrate'
### Signature
`buildCrate "string" {attrs}`
### Example
```nix
foo = crates.buildCrate "foo" {
    buildInputs = with pkgs; [libxml];
}; 
```
## `fetchCrate`
### Signature
`fetchCrate "string" {attrs}`
### Example 
```nix
foo-src = crates.fetchCrate "foo" {};
```

### Other Examples

```nix
crates = crates-nix.mkLib {inherit pkgs;};
foo = crates.buildCrate "foo" {};
foo-src = crates.fetchCrate "foo" {};
foo-v1 = crates.buildCrate "foo" { version = "1" };
```

### Example 
Example flake.nix file
```nix
{
  description = "Flake utils demo";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    crates-nix = {
      url = "github:uttarayan21/crates.nix";
      inputs.crates-io-index.follows = "crates-io-index";
    };
    crates-io-index = {
      url = "github:rust-lang/crates.io-index";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    crates-nix,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
        crates = crates-nix.mkLib {inherit pkgs;};
      in {
        packages = rec {
          default = ripgrep;
          foo = crates.buildCrate "foo" {
            buildInputs = with pkgs; [libxml];
          }; 
        };
        devShells = pkgs.mkShell {
            packages = [(crates.buildCrate "cargo-with" {})];
        };
      }
    );
}

```
