{
  description = "Devshell for Node projects";

  inputs.devshell.url = "github:numtide/devshell";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, flake-utils, devshell, nixpkgs, ... }:
    flake-utils.lib.eachDefaultSystem (system: {
      devShells.default =
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ devshell.overlays.default ];
          };
          
          buildNodeJs = pkgs.callPackage "${nixpkgs}/pkgs/development/web/nodejs/nodejs.nix" {
            python = pkgs.python3;
          };

          nodejs = buildNodeJs {
            enableNpm = true;
            version = "20.5.1";
            sha256 = "sha256-Q5xxqi84woYWV7+lOOmRkaVxJYBmy/1FSFhgScgTQZA=";
          };
        in
        pkgs.devshell.mkShell {
          name = "dash-dev";
          packages = with pkgs; [
            nodejs
            # nodejs_18
            # nodejs-12_x
          ];

          commands = [
            {
              package = "yarn";
              category = "node";
              help = "Prefered package tool for Node";
            }
          ];
        };
    });
}
