{
  inputs = {
    # This has SBCL 2.4.10 and docktuil 3.1.3 which are known to work
    nixpkgs.url = "github:NixOS/nixpkgs/af51545ec9a44eadf3fe3547610a5cdd882bc34e";
    flake-parts.url = "github:hercules-ci/flake-parts";
    cl-nix-lite = {
      url = "github:hraban/cl-nix-lite";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (
      { withSystem, flake-parts-lib, ... }:
      let
        inherit (flake-parts-lib) importApply;
        flakeModule = importApply ./flake-module.nix { inherit withSystem; };
      in
      {
        imports = [
          flakeModule
          inputs.treefmt-nix.flakeModule
        ];
        systems = [
          "aarch64-darwin"
          "x86_64-darwin"
        ];
        flake.flakeModules.default = flakeModule;
        perSystem = {
          treefmt = {
            projectRootFile = "flake.nix";
            programs.nixfmt = {
              enable = true;
              strict = true;
            };
          };
        };
      }
    );
}
