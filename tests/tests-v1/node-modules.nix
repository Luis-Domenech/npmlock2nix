{
  pkgs,
  npmlock2nix,
  default-nodejs,
  alternate-nodejs,
  testLib,
  runCommand,
}:
let

  # Python 3.11 onwards causes node-pre-gyp to fail, which is used by bcrypt, in old NodeJS versions
  python =
    if pkgs ? python310 then
      pkgs.python310
    else
      assert
        pkgs.lib.versionAtLeast pkgs.python3.version "3.11.0"
        -> throw "The default python (v${pkgs.python3.version}) at `pkgs.python3` has a version greater than `3.10.XX` and the current shell's nixpkgs does not have the `python310` package, which has python at version `3.10.XX`. Python `3.11.XX` onwards causes `node-pre-gyp` to fail, which is used by bcrypt, when running the native extensions tests.";
      pkgs.python3;

in
testLib.runTests {
  testNodeModulesForEmptyDependencies = {
    expr =
      let
        drv = npmlock2nix.v1.node_modules {
          src = ./examples-projects/no-dependencies;
        };
      in
      {
        inherit (drv) version name;
      };
    expected = {
      name = "no-dependencies-1.0.0";
      version = "1.0.0";
    };
  };

  testNodeModulesWithNoVersion = {
    expr =
      let
        drv = npmlock2nix.v1.node_modules {
          src = ./examples-projects/no-version;
        };
      in
      {
        inherit (drv) version name;
      };
    expected = {
      name = "no-version-0";
      version = "0";
    };
  };

  testNodeModulesForEmptyDependenciesHasNodeModulesFolder = {
    expr =
      let
        drv = npmlock2nix.v1.node_modules {
          src = ./examples-projects/no-dependencies;
        };
      in
      builtins.pathExists (drv + "/node_modules");
    expected = false;
  };

  testNodeModulesForSimpleProjectHasLeftPad = {
    expr =
      let
        drv = npmlock2nix.v1.node_modules {
          src = ./examples-projects/single-dependency;
        };
      in
      builtins.pathExists (drv + "/node_modules/leftpad");
    expected = true;
  };
  testNodeModulesForSimpleProjectCanUseLeftPad = {
    expr =
      let
        drv = npmlock2nix.v1.node_modules {
          src = ./examples-projects/single-dependency;
        };
      in
      builtins.pathExists (
        runCommand "test-leftpad"
          {
            buildInputs = [ default-nodejs ];
          }
          ''
            ln -s ${drv}/node_modules node_modules
            node -e "require('leftpad')"
            touch $out
          ''
      );
    expected = true;
  };

  testNodeModulesAcceptsCustomNodejs = {
    expr =
      (npmlock2nix.v1.node_modules {
        src = ./examples-projects/no-dependencies;
        nodejs = {
          pname = "our-custom-nodejs-package";
          version = alternate-nodejs.version;
        };
      }).nodejs;
    expected = {
      pname = "our-custom-nodejs-package";
      version = alternate-nodejs.version;
    };
  };

  testNodeModulesPropagatesNodejs =
    let
      drv = npmlock2nix.v1.node_modules {
        src = ./examples-projects/no-dependencies;
        nodejs = alternate-nodejs;
      };
    in
    {
      expr = drv.propagatedBuildInputs;
      expected = [ alternate-nodejs ];
    };

  testHonorsPrePostBuildHook =
    let
      drv = npmlock2nix.v1.node_modules {
        src = ./examples-projects/single-dependency;
        preBuild = ''
          echo -n "preBuild" > preBuild-test
        '';
        postBuild = ''
          echo -n "postBuild" > postBuild-test
          mv *Build-test node_modules
        '';
      };
    in
    {
      expr = builtins.readFile (
        runCommand "concat" { } ''
          cat ${drv + "/node_modules/preBuild-test"} ${drv + "/node_modules/postBuild-test"} > $out
        ''
      );
      expected = "preBuildpostBuild";
    };

  testBuildsNativeExtensions =
    let
      drv = npmlock2nix.v1.node_modules {
        src = ./examples-projects/native-extensions;
        buildInputs = [ python ];
      };
    in
    {
      expr = builtins.pathExists drv.outPath;
      expected = true;
    };

  testPassesExtraParameters = {
    expr =
      (npmlock2nix.v1.node_modules {
        src = ./examples-projects/single-dependency;
        SOME_EXTRA_PARAMETER = "123";
      }).SOME_EXTRA_PARAMETER or "attribute missing";
    expected = "123";
  };

  testHonorsPassedPassthru = {
    expr =
      (npmlock2nix.v1.node_modules {
        src = ./examples-projects/single-dependency;
        passthru.test-param = 123;
      }).passthru.test-param;
    expected = 123;
  };

  testVersionAsResolvedUrl =
    let
      drv = npmlock2nix.v1.node_modules {
        src = ./examples-projects/url-as-version;
      };
    in
    {
      expr = builtins.pathExists drv.outPath;
      expected = true;
    };
}
