{
  pkgs,
  lib,
  v1-nodejs ? null,
  v2-nodejs ? null,
  v1-alternate-nodejs ? null,
  v2-alternate-nodejs ? null,
}:
let
  v1_internal = pkgs.callPackage ./internal-v1.nix {
    default-nodejs = v1-nodejs;
    alternate-nodejs = v1-alternate-nodejs;
  };
  v2_internal = pkgs.callPackage ./internal-v2.nix {
    default-nodejs = v2-nodejs;
    alternate-nodejs = v2-alternate-nodejs;
  };
  separatePublicAndInternalAPI =
    api: extraAttributes:
    {
      inherit (api) shell build node_modules;

      # *** WARNING ****
      # using any of the functions exposed by `internal` is not supported. That
      # being said, hiding them would only lead to copy&paste and it is also useful
      # for testing internal building blocks.
      internal = lib.warn "[npmlock2nix] You are using the unsupported internal API." (api);
    }
    // (lib.listToAttrs (map (name: lib.nameValuePair name api.${name}) extraAttributes));
  v1 = separatePublicAndInternalAPI v1_internal [ ];
  v2 = separatePublicAndInternalAPI v2_internal [ "packageRequirePatchShebangs" ];
in
{
  inherit v1 v2;
}
