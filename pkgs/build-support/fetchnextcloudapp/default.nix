{ stdenv, pkgs, ... }:
{ name
, url
, version
, sha256
, patches ? [ ]
}:
stdenv.mkDerivation {
  name = "nc-app-${name}";
  version = "${version}";

  src = pkgs.fetchurl {
    url = url;
    sha256 = sha256;
  };

  nativeBuildInputs = with pkgs; [
    gnutar
    findutils
  ];

  buildInputs = with pkgs; [ ];

  unpackPhase = ''
    tar -xzpf $src
    find -type f -executable -exec chmod o-x,g-x-w,a-x-w '{}' \;
  '';

  patches = patches;

  installPhase = ''
    tgr=$(dirname $(dirname $(find -path '*/appinfo/info.xml' | head -n 1)))

    if [ \! -d $tgr ];
    then
      echo "Could not find appinfo/info.xml"
      exit 1;
    fi

    mv $tgr/ $out
    chmod -R g-w $out
  '';
}
