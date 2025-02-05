{ callPackage, runCommandLocal }:
let

  build = callPackage ./build.nix { };
  build-tests = callPackage ./build-tests.nix { };
  make-github-source = callPackage ./make-github-source.nix { };
  make-source = callPackage ./make-source.nix { };
  make-source-urls = callPackage ./make-source-urls.nix { };
  node-modules = callPackage ./node-modules.nix { };
  parse-github-ref = callPackage ./parse-github-ref.nix { };
  patch-lockfile = callPackage ./patch-lockfile.nix { };
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
    runCommandLocal "v1-unit-tests"
      {
        src = ./.;
        nativeBuildInputs = [
          build
          build-tests
          make-github-source
          make-source
          make-source-urls
          node-modules
          parse-github-ref
          patch-lockfile
          patch-packagefile
          read-lockfile
          shell
          source-hash-func
        ];
      }
      ''
        mkdir "$out"
      '';

  # unit-tests = build //
  #   build-tests //
  #   make-github-source //
  #   make-source //
  #   make-source-urls //
  #   node-modules //
  #   parse-github-ref //
  #   patch-lockfile //
  #   patch-packagefile //
  #   read-lockfile //
  #   shell //
  #   source-hash-func;

  inherit integration-tests restricted-tests;
}
