{ npmlock2nix }:
npmlock2nix.v1.build {
  src = ./.;
  buildCommands = [ "echo BUILDING" ];
  installPhase = "mkdir $out";
}
