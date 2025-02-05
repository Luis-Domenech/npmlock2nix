{
  description = "npmlock2nix";

  inputs = {
    # NixOS unstable at 25.05 on 12/03/2024 (MM/DD/YYYY)
    nixpkgs.url = "github:NixOS/nixpkgs/55d15ad12a74eb7d4646254e13638ad0c4128776";

    flake-compat = {
      # 11/27/2024
      url = "github:edolstra/flake-compat/9ed2ac151eada2306ca8c418ebd97807bb08f6ac";
      flake = false;
    };

    flake-utils = {
      # 11/13/2024
      url = "github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b";
      inputs.systems.follows = "systems";
    };

    gitignore = {
      # 02/27/2024
      url = "github:hercules-ci/gitignore.nix/637db329424fd7e46cf4185293b9cc8c88c95394";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pre-commit-hooks = {
      # 11/19/2024
      url = "github:cachix/git-hooks.nix/3308484d1a443fc5bc92012435d79e80458fe43c";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs";

      inputs.flake-compat.follows = "flake-compat";
      inputs.gitignore.follows = "gitignore";
    };

    smoke = {
      # 09/24/2024
      url = "github:SamirTalwar/smoke/c2424c6d03445b6eb38f33c1f4eb6e71e7656a02";
      inputs.nixpkgs.follows = "nixpkgs";

      inputs.flake-compat.follows = "flake-compat";
      inputs.flake-utils.follows = "flake-utils";
    };

    systems = {
      # 04/09/2023
      url = "github:nix-systems/default/da67096a3b9bf56a91d16901293e51ba5b49a27e";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      pre-commit-hooks,
      smoke,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let

        pkgs = nixpkgs.legacyPackages.${system};

        smoke-pkg = smoke.packages.${system}.default;

        npmlock2nix = pkgs.callPackage ./default.nix { };

        test-suite = pkgs.callPackage ./tests {
          npmlock2nix = npmlock2nix;
          smoke = smoke-pkg;
        };

      in
      {
        inherit (npmlock2nix) v1 v2;

        tests = rec {
          v1-unit-tests = test-suite.v1.unit-tests;
          v1-integration-tests = test-suite.v1.integration-tests;
          v1-restricted-tests = test-suite.v1.restricted-tests;
          v1-tests = v1-unit-tests // v1-integration-tests;

          v2-unit-tests = test-suite.v2.unit-tests;
          v2-integration-tests = test-suite.v2.integration-tests;
          v2-restricted-tests = test-suite.v2.restricted-tests;
          v2-tests = v2-unit-tests // v2-integration-tests;

          unit-tests = v1-unit-tests // v2-unit-tests;

          integration-tests = v1-integration-tests // v2-integration-tests;

          all-tests = unit-tests // integration-tests;
        };

        checks = {
          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              nixfmt-rfc-style.enable = true;
            };
          };
        };

        devShells.default =
          let
            test-runner = pkgs.writeScriptBin "test-runner" ''
              # find . -type f | ${pkgs.entr}/bin/entr -c nix build .#unit-tests -I nixpkgs=flake:nixpkgs
              find . -type f | ${pkgs.entr}/bin/entr -c just run-unit-tests
            '';

            pre-commit-check = self.checks.${system}.pre-commit-check;

          in
          pkgs.mkShell {

            buildInputs = [
              pre-commit-check.enabledPackages

              smoke-pkg
              test-runner

              pkgs.entr
              pkgs.just
              pkgs.nodejs

            ];

            shellHook = ''
              ${pre-commit-check.shellHook}
            '';

          };

        # devShells.ci = {

        # };
      }
    );
}
