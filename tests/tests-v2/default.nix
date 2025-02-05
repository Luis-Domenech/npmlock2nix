{ callPackage, runCommandLocal }:
let

  build = callPackage ./build.nix { };
  build-tests = callPackage ./build-tests.nix { };
  bundle-shebang-tests = callPackage ./examples-projects/bundled-dep-require-patch-shebang { };
  _in-bundle-dep-test = callPackage ./examples-projects/in-bundle-dependency { };
  make-url-source = callPackage ./make-url-source.nix { };
  node-modules = callPackage ./node-modules.nix { };
  parse-github-ref = callPackage ./parse-github-ref.nix { };
  patch-package = callPackage ./patch-package.nix { };
  patch-packagefile = callPackage ./patch-packagefile.nix { };
  read-lockfile = callPackage ./read-lockfile { };
  shell = callPackage ./shell.nix { };
  source-hash-func = callPackage ./source-hash-func.nix { };

  integration-tests = callPackage ./integration-tests { };

  restricted-tests = callPackage ./examples-projects/github-dependency { };

in
{
  # Variant of runCommand intended for commands that run quickly and will be slowed down by the network round-trip.
  unit-tests =
    runCommandLocal "v2-unit-tests"
      {
        src = ./.;
        nativeBuildInputs = [
          build
          build-tests
          bundle-shebang-tests
          _in-bundle-dep-test
          make-url-source
          node-modules
          parse-github-ref
          patch-package
          patch-packagefile
          read-lockfile
          shell
          source-hash-func
        ];
      }
      ''
        mkdir "$out"
      '';

  # unit-tests =  build //
  #   build-tests //
  #   bundle-shebang-tests //
  #   _in-bundle-dep-test //
  #   make-url-source //
  #   node-modules //
  #   parse-github-ref //
  #   patch-package //
  #   patch-packagefile //
  #   read-lockfile //
  #   shell //
  #   source-hash-func;

  inherit integration-tests restricted-tests;
}
