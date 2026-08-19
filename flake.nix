{
  inputs.acadia-engineering-examples = {
    url = "github:acadia-engineering/examples";
    flake = false;
  };

  outputs = { self, nixpkgs, acadia-engineering-examples }:
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

          examples="$PROJECT_ROOT/examples"
          if [ ! -e "$examples" ]; then
            mkdir "$examples"
            cp -r ${acadia-engineering-examples}/. "$examples"
            chmod -R u+w "$examples"
          fi
        '';
      };
    };
}
