{
  stdenv,
  buildGoModule,
  exiftool,
  fetchurl,
  ffmpeg,
  fetchFromGitHub,
  lib,

  ncVersion,
}:
let
  latestVersionForNc = {
    "31" = latestVersionForNc."29";
    "30" = latestVersionForNc."29";
    "29" = {
      version = "7.5.2";
      appHash = "sha256-BfxJDCGsiRJrZWkNJSQF3rSFm/G3zzQn7C6DCETSzw4=";
      srcHash = "sha256-imBO/64NW5MiozpufbMRcTI9WCaN8grnHlVo+fsUNlU=";
    };
  };
  currentVersionInfo =
    latestVersionForNc.${ncVersion}
      or (throw "memories currently does not support nextcloud version ${ncVersion}");

  commonMeta = with lib; {
    homepage = "https://apps.nextcloud.com/apps/memories";
    changelog = "https://github.com/pulsejet/memories/blob/v${currentVersionInfo.version}/CHANGELOG.md";
    license = licenses.agpl3Only;
    maintainers = with maintainers; [ SuperSandro2000 ];
  };

  go-vod = buildGoModule rec {
    pname = "go-vod";
    inherit (currentVersionInfo) version;

    src = fetchFromGitHub {
      owner = "pulsejet";
      repo = "memories";
      tag = "v${version}";
      hash = currentVersionInfo.srcHash;
    };

    sourceRoot = "${src.name}/go-vod";

    vendorHash = null;

    meta = commonMeta // {
      description = "Extremely minimal on-demand video transcoding server in go";
      mainProgram = "go-vod";
    };
  };
in
stdenv.mkDerivation rec {
  pname = "nextcloud-app-memories";
  inherit (currentVersionInfo) version;

  src = fetchurl {
    url = "https://github.com/pulsejet/memories/releases/download/v${version}/memories.tar.gz";
    hash = currentVersionInfo.appHash;
  };

  postPatch = ''
    rm -rf bin-ext/*
    substituteInPlace lib/Service/BinExt.php \
      --replace-fail "EXIFTOOL_VER = '12.70'" "EXIFTOOL_VER = '${exiftool.version}'"

    patch lib/Settings/SystemConfig.php <<'HERE'
    @@ -124,6 +124,12 @@
          */
         public static function get(string $key, mixed $default = null): mixed
         {
    +        switch ($key) {
    +          case "memories.exiftool": return "${lib.getExe exiftool}";
    +          case "memories.vod.ffmpeg": return "${lib.getExe ffmpeg}";
    +          case "memories.vod.ffprobe": return "${lib.getExe' ffmpeg "ffprobe"}";
    +          case "memories.vod.path": return "${lib.getExe go-vod}";
    +        }
             if (!\array_key_exists($key, self::DEFAULTS)) {
                 throw new \InvalidArgumentException("Invalid system config key: {$key}");
             }
    @@ -154,6 +160,10 @@
          */
         public static function set(string $key, mixed $value): void
         {
    +        if ( in_array($key, array( "memories.exiftool", "memories.vod.ffmpeg", "memories.vod.ffprobe", "memories.vod.path")) ){
    +            throw new \InvalidArgumentException("Cannot set nix-managed key: {$key}");
    +        }
    +
             // Check if the key is valid
             if (!\array_key_exists($key, self::DEFAULTS)) {
                 throw new \InvalidArgumentException("Invalid system config key: {$key}");
    HERE

  '';

  installPhase = ''
    mkdir -p $out
    cp -r ./* $out/
  '';

  meta = commonMeta // {
    description = "Fast, modern and advanced photo management suite";
  };
}
