{
  buildEnv,
  lib,
  makeWrapper,
  sst-elements,
  sst-core,
  extraElements ? {
    # Will be converted to sst-register SST_ELEMENT_LIBRARY SST_ELEMENT_LIBRARY_SOURCE_ROOT=... etc
    SST_ELEMENT_LIBRARY = {
      SST_ELEMENT_LIBRARY_SOURCE_ROOT = "${sst-elements.src}";
      SST_ELEMENT_LIBRARY_HOME = "${sst-elements}";
      SST_ELEMENT_LIBRARY_BINDIR = "$out/bin";
      SST_ELEMENT_LIBRARY_LIBDIR = "${sst-elements}/lib/sst-elements-library";
      SST_ELEMENT_LIBRARY_BUILDDIR = "${sst-elements}";
    };
  },
}:

assert sst-core.version == sst-elements.version;

buildEnv {
  name = "sst-${sst-core.version}";

  nativeBuildInputs = [ makeWrapper ];

  paths = [
    sst-core
    sst-elements
  ];

  pathsToLink = [
    "/bin"
    "/include"
    "/libexec"
    "/lib"
  ];

  # make a fake HOME for SST that will become read-only
  postBuild =
    let
      concatMapAttrsToList = f: attrs: lib.concatStrings (lib.attrsets.mapAttrsToList f attrs);
      extraRegistrationsScript = concatMapAttrsToList (
        name: group:
        concatMapAttrsToList (
          key: value: ''
            $out/bin/sst-register ${
              lib.strings.escapeShellArgs [
                name
                "${key}=${value}"
              ]
            }
          ''
        )
      ) extraElements;
    in
    ''
      mkdir -p $out/{etc/sst,home}

      for i in $out/bin/*; do
        wrapProgram "$i" \
          --set SST_HOME "$out"  \
          --set HOME "$out/home"
      done

      # Also set these vars here for simplicity
      export HOME=$out/home
      export SST_HOME=$out

      # Writeable copy
      cat ${sst-core}/etc/sst/sstsimulator.conf > $out/etc/sst/sstsimulator.conf

      # Above copy is not used as SST hardcodes this path in the binary (to sst-core)
      # The regiter tool will use what is in $HOME/.sst instead
      mkdir $HOME/.sst
      ln -s $out/etc/sst/sstsimulator.conf $HOME/.sst

      ${extraRegistrationsScript}

      # Remove test binaries that won't work in the sandboxed environment
      rm $out/bin/{.,}sst-test-{core,elements}*
    '';

  meta = sst-core.meta // {
    mainProgram = "sst";
    description = "SST Core and Elements - ${sst-core.meta.description}";
    longDescription = ''
      The Structural Simulation Toolkit (SST) combines the SST Core, which provides
      a parallel discrete event simulation core and shared libraries, with the SST
      Elements, which provide a set of simulation components for various
      architectures and devices.
    '';
  };
}
