{ lib, stdenvNoCC, fetchurl }:

stdenvNoCC.mkDerivation rec {
  pname = "rayfish";
  version = "0.5.0";

  src = fetchurl {
    url = "https://github.com/rayfish/rayfish/releases/download/v${version}/ray-macos-aarch64";
    hash = "sha256-lOrwg3sMVRadZQAS3bHx6LGnsQhmVygVYWFwq7zcyUQ=";
  };

  dontUnpack = true;
  dontFixup = true;

  installPhase = ''
    install -Dm755 "$src" "$out/libexec/rayfish/ray"
    install -Dm755 ${./ray-guard.sh} "$out/bin/ray"
    substituteInPlace "$out/bin/ray" \
      --replace-fail '@REAL@' "$out/libexec/rayfish/ray"
  '';

  meta = {
    description = "P2P mesh VPN powered by iroh";
    homepage = "https://rayfish.xyz";
    license = lib.licenses.mpl20;
    mainProgram = "ray";
    platforms = [ "aarch64-darwin" ];
  };
}
