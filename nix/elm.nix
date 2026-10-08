{ fetchurl
, lib
, makeWrapper
, nodejs
, stdenv
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "elm";
  version = "0.19.3";

  src = fetchurl {
    url = "https://github.com/elm/compiler/releases/download/${finalAttrs.version}/elm-${finalAttrs.version}-linux-x64.gz";
    hash = "sha256-0RcCsxV37YtyC52BxSyKGaUrcrH8+t7w/K2S8heYxYo=";
  };

  nativeBuildInputs = [
    makeWrapper
  ];

  unpackPhase = ''
    runHook preUnpack

    gzip -dc $src > elm

    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    install -Dm755 elm $out/bin/elm

    runHook postInstall
  '';

  postInstall = ''
    wrapProgram "$out/bin/elm" \
      --prefix PATH ':' ${lib.makeBinPath [ nodejs ]}
  '';

  meta = {
    mainProgram = finalAttrs.pname;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
