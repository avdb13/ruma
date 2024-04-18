{
  description = "Types and traits for working with the Matrix protocol.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix-filter.url = "github:numtide/nix-filter";

    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      crane,
      flake-utils,
      fenix,
      nix-filter,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgsHost = nixpkgs.legacyPackages.${system};

        craneLib = crane.lib.${system};

        # Nix-accessible `Cargo.toml`
        cargoToml = builtins.fromTOML (builtins.readFile ./Cargo.toml);

        # The Rust toolchain to use
        toolchain = fenix.packages.${system}.fromToolchainFile {
          file = ./rust-toolchain.toml;

          sha256 = "sha256-VaSJ+gvZ3jqO3/U5X0Y9uCVb/aHU5tjFIT4313m0TiM=";
        };

        builder = pkgs: ((crane.mkLib pkgs).overrideToolchain toolchain).buildPackage;

        package =
          pkgs:
          builder pkgs {
            src = nix-filter {
              root = ./.;
              include = [
                "src"
                "Cargo.toml"
                "Cargo.lock"
              ];
            };

            # This is redundant with CI
            doCheck = false;

            meta.mainProgram = cargoToml.package.name;
          };
      in
      {
        packages.default = package pkgsHost;

        apps.default = flake-utils.lib.mkApp { drv = package pkgsHost; };

        devShells.default = craneLib.devShell {
          env = {
            # Rust Analyzer needs to be able to find the path to default crate
            # sources, and it can read this environment variable to do so. The
            # `rust-src` component is required in order for this to work.
            RUST_SRC_PATH = "${toolchain}/lib/rustlib/src/rust/library";
          };

          # Development tools
          nativeBuildInputs = [
            # Always use nightly rustfmt because most of its options are unstable
            #
            # This needs to come before `toolchain` in this list, otherwise
            # `$PATH` will have stable rustfmt instead.
            fenix.packages.${system}.latest.rustfmt

            toolchain
          ];
        };
      }
    );
}
