{
  npmlock2nix,
  default-nodejs,
  alternate-nodejs,
}:
# We need make sure that `default-nodejs` does not default to `alternate-nodejs` because then our test cannot ensure that we can override the default. If the assert below throws, change `alternate-nodejs` to a different version.
assert
  default-nodejs.version == alternate-nodejs.version
  -> throw "The default nodejs (v${default-nodejs.version}) at `pkgs.nodejs` is the same as the nodejs version of this test, thus rendering the test ineffective.";

npmlock2nix.v1.shell {
  src = ./.;
  nodejs = alternate-nodejs;
}
