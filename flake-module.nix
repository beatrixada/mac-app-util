# Reusable flake-parts module for mac-app-util.
# Imported via importApply, receiving { withSystem } from the calling flake.

{ withSystem }:

{ inputs, ... }:

{
  perSystem =
    { pkgs, lib, ... }:
    let
      clPkgs = pkgs.extend inputs.cl-nix-lite.overlays.default;
      mac-app-util = clPkgs.callPackage (
        {
          lispPackagesLite,
          dockutil,
          findutils,
          jq,
          rsync,
        }:
        with lispPackagesLite;
        lispScript rec {
          name = "mac-app-util";
          src = ./main.lisp;
          dependencies = [
            alexandria
            inferior-shell
            cl-interpol
            cl-json
            str
            trivia
          ];
          nativeBuildInputs = [ clPkgs.makeBinaryWrapper ];
          postInstall = ''
            wrapProgramBinary "$out/bin/${name}" \
              --suffix PATH : "${
                with clPkgs;
                lib.makeBinPath [
                  dockutil
                  rsync
                  findutils
                  jq
                ]
              }"
          '';
          installCheckPhase = ''
            $out/bin/${name} --help
          '';
          doInstallCheck = true;
          meta.license = clPkgs.lib.licenses.agpl3Only;
        }
      ) { };
    in
    {
      packages.mac-app-util = mac-app-util;
      packages.default = mac-app-util;
      checks.mac-app-util = mac-app-util;
    };

  flake = {
    homeManagerModules.default =
      {
        pkgs,
        lib,
        config,
        ...
      }:
      {
        options = with lib; {
          targets.darwin.mac-app-util.enable = mkOption {
            type = types.bool;
            default = pkgs.stdenv.isDarwin;
            example = true;
            description = "Whether to enable mac-app-util home manager integration";
          };
        };
        config = lib.mkIf config.targets.darwin.mac-app-util.enable {
          home.activation = {
            trampolineApps =
              let
                mac-app-util = withSystem pkgs.stdenv.system ({ config, ... }: config.packages.mac-app-util);
              in
              lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                fromDir="$HOME/Applications/Home Manager Apps"
                toDir="$HOME/Applications/Home Manager Trampolines"
                ${mac-app-util}/bin/mac-app-util sync-trampolines "$fromDir" "$toDir"
              '';
          };
        };
      };

    darwinModules.default =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      {
        options = {
          services.mac-app-util.enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            example = false;
          };
        };
        config = lib.mkIf config.services.mac-app-util.enable {
          system.activationScripts.postActivation.text =
            let
              mac-app-util = withSystem pkgs.stdenv.system ({ config, ... }: config.packages.mac-app-util);
            in
            ''
              ${mac-app-util}/bin/mac-app-util sync-trampolines "/Applications/Nix Apps" "/Applications/Nix Trampolines"
            '';
        };
      };
  };
}
