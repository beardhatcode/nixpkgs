{
  autoreconfHook,
  cairo,
  cppunit,
  fetchFromGitHub,
  fetchNpmDeps,
  lib,
  libcap,
  libpng,
  libreoffice-collabora,
  nodejs,
  npmHooks,
  pam,
  pango,
  pixman,
  pkg-config,
  poco,
  python3,
  rsync,
  stdenv,
  zstd,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "collabora-online";
  version = "24.04.13-3";

  src = fetchFromGitHub {
    owner = "CollaboraOnline";
    repo = "online";
    tag = "cp-${finalAttrs.version}";
    hash = "sha256-Pghn/T5cJ5FysmHsop6lJjiAWYSwSInCI6Od64/H0gc=";
  };

  nativeBuildInputs = [
    autoreconfHook
    nodejs
    npmHooks.npmConfigHook
    pkg-config
    python3
    python3.pkgs.lxml
    python3.pkgs.polib
    rsync
  ];

  buildInputs = [
    cairo
    cppunit
    libcap
    libpng
    pam
    pango
    pixman
    poco
    zstd
  ];

  configureFlags = [
    "--disable-werror" # ignore deprecation warning due to newer Poco
    "--enable-silent-rules" # less verbose build output
    "--with-lo-path=${libreoffice-collabora}/lib/collaboraoffice"
    "--with-lokit-path=${libreoffice-collabora.src}/include"
  ];

  patches = [
    ./fix-file-server-regex.patch
    ./0001-fix-test.patch
  ];

  postPatch = ''
    cp ${./package-lock.json} ${finalAttrs.npmRoot}/package-lock.json

    patchShebangs browser/util/*.py coolwsd-systemplate-setup scripts/*
    substituteInPlace configure.ac --replace-fail '/usr/bin/env python3' python3
    substituteInPlace coolwsd-systemplate-setup --replace-fail /bin/pwd pwd
  '';

  # Copy dummy self-signed certificates provided for testing.
  postInstall = ''
    cp etc/ca-chain.cert.pem etc/cert.pem etc/key.pem $out/etc/coolwsd
  '';

  npmDeps = fetchNpmDeps {
    unpackPhase = "true";
    # TODO: Use upstream `npm-shrinkwrap.json` once it's fixed
    # https://github.com/CollaboraOnline/online/issues/9644
    postPatch = ''
      cp ${./package-lock.json} package-lock.json
    '';
    hash = "sha256-XS1A+7rza9wW47P6WIsL8khjxOylkojqKCTXzz/H5Gc=";
  };

  npmRoot = "browser";

  passthru = {
    libreoffice = libreoffice-collabora; # Used by NixOS module.
  };

  meta = {
    description = "Collaborative online office suite based on LibreOffice technology";
    license = lib.licenses.mpl20;
    maintainers = [ lib.maintainers.xzfc ];
    homepage = "https://www.collaboraonline.com";
    platforms = lib.platforms.linux;
  };
})
