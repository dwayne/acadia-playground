{ applyPatches

, acadia-engineering-examples
}:

applyPatches {
  name = "examples";
  src = acadia-engineering-examples;

  postPatch = ''
    for f in */elm.json; do
      substituteInPlace "$f" \
        --replace-fail '"elm-version": "0.19.2"' '"elm-version": "0.19.3"'
    done
  '';
}
