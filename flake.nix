{
  description = "smol-ivan-recipes dev environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            nodejs_24
            pnpm
            docker-compose
            lazydocker
          ];

          shellHook = ''
            echo "🚀 Smol Ivan Web dev environment loaded (Node.js $(node --version), pnpm $(pnpm --version))"
          '';
        };
      }
    );
}
