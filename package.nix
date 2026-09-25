{ lib, stdenvNoCC, fetchurl, autoPatchelfHook, glibc, libgcc }:

let
  system = stdenvNoCC.hostPlatform.system;
  releases = {
    "aarch64-darwin" = {
      asset = "ray-macos-aarch64";
      hash = "sha256-cLX0XBBtRkjvsGN5M2fK9kMyCL0I0Npfplh8aLIU+fQ=";
    };
    "aarch64-linux" = {
      asset = "ray-linux-aarch64";
      hash = "sha256-3pwdqeckHq/6q8UqWBnBZ0S39dk2gjIbFJ30+2miqnM=";
    };
    "x86_64-linux" = {
      asset = "ray-linux-x86_64";
      hash = "sha256-/gsMqkKvPaGUtg4EBkGcKr7ERSUzduil4QpUf76pzpU=";
    };
  };
  release = releases.${system} or (throw "Rayfish has no prebuilt release for ${system}");
in
stdenvNoCC.mkDerivation rec {
  pname = "rayfish";
  version = "0.5.1";

  src = fetchurl {
    url = "https://github.com/rayfish/rayfish/releases/download/v${version}/${release.asset}";
    hash = release.hash;
  };

  dontUnpack = true;
  dontFixup = lib.hasSuffix "-darwin" system;

  nativeBuildInputs = lib.optional (lib.hasSuffix "-linux" system) autoPatchelfHook;
  buildInputs = lib.optionals (lib.hasSuffix "-linux" system) [ glibc libgcc ];
  runtimeDependencies = lib.optionals (lib.hasSuffix "-linux" system) [ libgcc ];

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
    platforms = [ system ];
  };
}
