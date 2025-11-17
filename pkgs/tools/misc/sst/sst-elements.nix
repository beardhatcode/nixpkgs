{
  stdenv,
  lib,
  autoconf,
  automake,
  bash,
  fetchFromGitHub,
  libtool,
  makeWrapper,
  openmpi,
  sst-core,
  zlib,
}:
stdenv.mkDerivation rec {
  pname = "sst-elements";
  version = "15.0.0";

  src = fetchFromGitHub {
    owner = "sstsimulator";
    repo = "sst-elements";
    rev = "v${version}_Final";
    hash = "sha256-7THqvt0alAE1aARRo5jwdxRnB78eS4ykDC6Kx4uRvLk=";
  };

  parallelBuild = true;

  preConfigure = ''
    # SST-elements needs a writable home, fake one
    export HOME=$(mktemp -d)
    mkdir $HOME/.sst
    touch $HOME/.sst/sstsimulator.conf
    bash ./autogen.sh
  '';
  configureFlags = [
    "--with-sst-core=${sst-core}"
    # "--with-ramulator=${RAMULATOR_DIR}" # TODO add ramulator
  ];

  CXXFLAGS = [
    "-Wno-error=format-security"
  ];

  CFLAGS = [
    "-Wno-implicit-function-declaration"
    "-Wno-int-conversion"
  ];

  nativeBuildInputs = [
    makeWrapper
    bash
    autoconf
    automake
    openmpi
    sst-core.python
    zlib
  ];
  buildInputs = [ libtool ];

  meta = with lib; {
    homepage = "http://www.sst-simulator.org/";
    license = {
      fullName = "Sandia National Laboratories BSD-like License";
      url = "https://github.com/sstsimulator/sst-elements/blob/master/LICENSE.md";
      free = true;
    };
    maintainers = with maintainers; [
      beardhatcode
    ];
    description = "SST Architectural Simulation Components and Libraries";
    longDescription = ''
      SST Elements provides a collection of architectural simulation components
      (processors, memory, network, etc.) for use with the SST Core infrastructure,
      enabling detailed hardware and system-level simulation.
    '';
  };
}
