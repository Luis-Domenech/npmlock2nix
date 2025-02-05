{
  pkgs,
  npmlock2nix,
  smoke,
}:
let

  shared-scope = {
    inherit npmlock2nix;
    testLib = pkgs.callPackage ./lib.nix { inherit smoke; };
  };

  v1-scope = {
    inherit (npmlock2nix.v1.internal) default-nodejs alternate-nodejs;
  };

  v2-scope = {
    inherit (npmlock2nix.v2.internal) default-nodejs alternate-nodejs;
  };

  v1-pkgs.callPackage = pkgs.newScope (shared-scope // v1-scope);
  v2-pkgs.callPackage = pkgs.newScope (shared-scope // v2-scope);

in
{
  v1 = v1-pkgs.callPackage ./tests-v1 { callPackage = v1-pkgs.callPackage; };

  v2 = v2-pkgs.callPackage ./tests-v2 { callPackage = v2-pkgs.callPackage; };
}
