{ lib, stdenvNoCC, fetchurl, autoPatchelfHook, glibc, libgcc, system }:

let
  releases = {
    "aarch64-darwin" = {
      asset = "ray-macos-aarch64";
      hash = "sha256-lOrwg3sMVRadZQAS3bHx6LGnsQhmVygVYWFwq7zcyUQ=";
    };
    "aarch64-linux" = {
      asset = "ray-linux-aarch64";
      hash = "sha256-yr2652UVRvCCGhOcSOwKqKtxEgBy4tta1QwW9elvdRY=";
    };
    "x86_64-linux" = {
      asset = "ray-linux-x86_64";
      hash = "sha256-YC8cK6UN+Ls2KGMm80GFEpBHRwyFn1VUv7GF2Lou9A8=";
    };
  };
  release = releases.${system} or (throw "Rayfish has no prebuilt release for ${system}");
in
stdenvNoCC.mkDerivation rec {
  pname = "rayfish";
  version = "0.5.0";

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
