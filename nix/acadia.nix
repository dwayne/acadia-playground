{ fetchurl, lib, stdenv }:

stdenv.mkDerivation (finalAttrs: {
  pname = "acadia";
  version = "0.3.1";

  src = fetchurl {
    url = "https://get.acadia.engineering/acadia-${finalAttrs.version}-linux-x64.gz";
    hash = "sha256-T2DxqP8CAAgQUd78Mqbhafm/PcCsV0sgYt573rbwKf0=";
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
