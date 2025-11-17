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
  python310, # Starting python 3.11: invalid use of incomplete type 'PyFrameObject'
  zlib,
}:
stdenv.mkDerivation rec {
  pname = "sst-core";
  version = "15.0.0";

  src = fetchFromGitHub {
    owner = "sstsimulator";
    repo = "sst-core";
    rev = "v${version}_Final";
    hash = "sha256-QJj9At7Mm6UCc4v0dbpyt9gBDEOzzl2UY8tTdgG4s+k=";
  };

  parallelBuild = true;

  preConfigure = "bash ./autogen.sh";

  python = python310;

  nativeBuildInputs = [
    makeWrapper
    bash
    autoconf
    automake
    openmpi
    python310
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
    description = "SST Structural Simulation Toolkit Parallel Discrete Event Core and Services";
    longDescription = ''
      The Structural Simulation Toolkit (SST) Core provides a parallel discrete
      event simulation infrastructure for modeling computer systems.
    '';
  };
}
