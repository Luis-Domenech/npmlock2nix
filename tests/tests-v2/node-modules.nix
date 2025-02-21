{
  npmlock2nix,
  default-nodejs,
  alternate-nodejs,
  testLib,
  runCommand,
  python3,
}:
testLib.runTests {
  testNodeModulesForEmptyDependencies = {
    expr =
      let
        drv = npmlock2nix.v2.node_modules {
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
        drv = npmlock2nix.v2.node_modules {
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
        drv = npmlock2nix.v2.node_modules {
          src = ./examples-projects/no-dependencies;
        };
      in
      builtins.pathExists (drv + "/node_modules");
    expected = false;
  };

  testNodeModulesForSimpleProjectHasLeftPad = {
    expr =
      let
        drv = npmlock2nix.v2.node_modules {
          src = ./examples-projects/single-dependency;
        };
      in
      builtins.pathExists (drv + "/node_modules/leftpad");
    expected = true;
  };
  testNodeModulesForSimpleProjectCanUseLeftPad = {
    expr =
      let
        drv = npmlock2nix.v2.node_modules {
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
      (npmlock2nix.v2.node_modules {
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
      drv = npmlock2nix.v2.node_modules {
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
      drv = npmlock2nix.v2.node_modules {
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
      drv = npmlock2nix.v2.node_modules {
        src = ./examples-projects/native-extensions;
        buildInputs = [ python3 ];
        sourceOverrides = with npmlock2nix.v2; {
          "@mapbox/node-pre-gyp" = packageRequirePatchShebangs;
        };
      };
    in
    {
      expr = builtins.pathExists drv.outPath;
      expected = true;
    };

  testPassesExtraParameters = {
    expr =
      (npmlock2nix.v2.node_modules {
        src = ./examples-projects/single-dependency;
        SOME_EXTRA_PARAMETER = "123";
      }).SOME_EXTRA_PARAMETER or "attribute missing";
    expected = "123";
  };

  testHonorsPassedPassthru = {
    expr =
      (npmlock2nix.v2.node_modules {
        src = ./examples-projects/single-dependency;
        passthru.test-param = 123;
      }).passthru.test-param;
    expected = 123;
  };

  testVersionAsResolvedUrl =
    let
      drv = npmlock2nix.v2.node_modules {
        src = ./examples-projects/url-as-version;
      };
    in
    {
      expr = builtins.pathExists drv.outPath;
      expected = true;
    };
}
