{
  newScope,
}:
let
  callPackage = newScope self;

  self = {
    sst-core = callPackage ./sst-core.nix { };
    sst-elements = callPackage ./sst-elements.nix { };
    sst = callPackage ./wrapper.nix { };
  };

in
self
