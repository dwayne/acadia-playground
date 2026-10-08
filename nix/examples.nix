{ applyPatches

, acadia-engineering-examples
}:

applyPatches {
  name = "examples";
  src = acadia-engineering-examples;

  # If you ever need to make changes to the examples, for e.g. to bump elm-version,
  # you can modify the script below.
  #
  # postPatch = ''
  #   for f in */elm.json; do
  #     substituteInPlace "$f" \
  #       --replace-fail '"elm-version": "0.19.2"' '"elm-version": "0.19.3"'
  #   done
  # '';
}
