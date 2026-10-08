{
  inputs = {
    acadia-engineering-examples = {
      url = "github:acadia-engineering/examples";
      flake = false;
    };
    acadia-engineering-elm-simple-server = {
      url = "github:acadia-engineering/elm-simple-server";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, acadia-engineering-examples, acadia-engineering-elm-simple-server }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      acadia = pkgs.callPackage ./nix/acadia.nix {};
      elm = pkgs.callPackage ./nix/elm.nix {};
      examples = pkgs.callPackage ./nix/examples.nix { inherit acadia-engineering-examples; };
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

          example3="$examples/03-users"
          server3="$example3/elm-simple-server"

          if [ ! -e "$examples" ]; then
            mkdir -p "$examples"
            cp -r ${examples}/. "$examples"
            chmod -R u+w "$examples"

            mkdir -p "$server3"
            cp -r ${acadia-engineering-elm-simple-server}/. "$server3"
            chmod -R u+w "$server3"
          fi

          serve () {
            (cd "$examples/''${1:?}" && \
              acadia make --gen-elm=gen/ && \
              elm make src/Main.elm && \
              acadia serve --html=index.html)
          }

          serve-3 () {
            (cd "$example3" && \
              PATH="${pkgs.nodejs}/bin:$PATH" bash "$server3/src/serve.sh"
            )
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
          alias s3='serve-3'
          alias st='serve-todos'
        '';
      };
    };
}
