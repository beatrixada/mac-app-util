# Copyright © 2023–2025  Hraban Luyat
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, version 3 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

{
  inputs = {
    # This has SBCL 2.4.10 and docktuil 3.1.3 which are known to work
    nixpkgs.url = "github:NixOS/nixpkgs/af51545ec9a44eadf3fe3547610a5cdd882bc34e";
    flake-parts.url = "github:hercules-ci/flake-parts";
    cl-nix-lite = {
      url = "github:beatrixada/cl-nix-lite";
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
