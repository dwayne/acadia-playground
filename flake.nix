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
      elm = pkgs.callPackage ./nix/elm.nix {};

      acadia-engineering-examples-patched = pkgs.applyPatches {
        name = "acadia-engineering-examples-patched";
        src = acadia-engineering-examples;

        postPatch = ''
          for f in */elm.json; do
            substituteInPlace "$f" \
              --replace-fail '"elm-version": "0.19.2"' '"elm-version": "0.19.3"'
          done
        '';
      };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        name = "acadia-playground";

        packages = [
          acadia
          elm
        ];

        shellHook = ''
          export PROJECT_ROOT="$(git rev-parse --show-toplevel)"
          export PS1="($name)\n$PS1"

          examples="$PROJECT_ROOT/examples"
          if [ ! -e "$examples" ]; then
            mkdir "$examples"
            cp -r ${acadia-engineering-examples-patched}/. "$examples"
            chmod -R u+w "$examples"
          fi

          serve () {
            (cd "$examples/''${1:?}" && \
              acadia make --gen-elm=gen/ && \
              elm make src/Main.elm && \
              acadia serve --html=index.html)
          }

          serve-todos () {
            (cd "$PROJECT_ROOT/todos" && \
              acadia make --gen-elm=gen/ && \
              elm make src/Main.elm --debug --output=src/app.js && \
              replace-with-contents-of-app-js && \
              acadia serve --html=src/index.html)
          }

          replace-with-contents-of-app-js () {
            sed -i -n '
            \|^// START APP\.JS$|,\|^// END APP\.JS$| {
                \|^// START APP\.JS$| {
                    p
                    r src/app.js
                    a\

                    d
                }
                \|^// END APP\.JS$| {
                    p
                }
                d
            }
            p
            ' src/index.html
          }

          alias s1='serve 01-foods'
          alias s2='serve 02-origin'
          alias s3='serve 03-users'
          alias st='serve-todos'
        '';
      };
    };
}
