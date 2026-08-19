{ fetchurl, lib, stdenv }:

stdenv.mkDerivation (finalAttrs: {
  pname = "acadia";
  version = "0.3.0";

  src = fetchurl {
    url = "https://get.acadia.engineering/acadia-${finalAttrs.version}-linux-x64.gz";
    hash = "sha256-3KT/RnyxZhe3xfoI+R++T9GxY4DOTJuicRyVcudBMsI=";
  };

  unpackPhase = ''
    runHook preUnpack

    gzip -dc $src > acadia

    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    install -Dm755 acadia $out/bin/acadia

    runHook postInstall
  '';

  meta = {
    mainProgram = finalAttrs.pname;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
