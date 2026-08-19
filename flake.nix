{
  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      acadia = pkgs.callPackage ./nix/acadia.nix {};
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        name = "acadia-playground";

        packages = [
          acadia
          pkgs.elmPackages.elm
        ];

        shellHook = ''
          export PROJECT_ROOT="$(git rev-parse --show-toplevel)"
          export PS1="($name)\n$PS1"
        '';
      };
    };
}
