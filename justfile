set positional-arguments


default:
    @just --list


################################
#### CI/CD
################################

@run-ci-lint:
    nix develop --command nixfmt --check .

# Run CI tests using a recent nix version and an old version of nix (v2.4 which first introduces Nix Flakes). Taken from here: https://lazamar.co.uk/nix-versions/?package=nix&version=2.4&fullName=nix-2.4&keyName=nixVersions.nix_2_4&revision=f597e7e9fcf37d8ed14a12835ede0a7d362314bd&channel=nixpkgs-unstable#instructions
@run-ci-tests:
    nix shell nixpkgs#nix --command ./test.sh
    nix shell -I nixpkgs=github:NixOS/nixpkgs/f597e7e9fcf37d8ed14a12835ede0a7d362314bd github:NixOS/nixpkgs/f597e7e9fcf37d8ed14a12835ede0a7d362314bd#nix_2_4 --command ./test.sh

@run-ci-checks:
    nix develop --command nix flake check .


################################
#### DEVELOPMENT
################################

@direnv-allow:
    direnv allow

@lock-flake:
    nix flake lock -I nixpkgs=flake:nixpkgs

# Init the Nix devenv shell
@shell:
    just not-in-nix-shell 2>/dev/null || exit 1
    nix develop .#default -I nixpkgs=flake:nixpkgs

@run-checks *args='':
    nix flake check . -I nixpkgs=flake:nixpkgs $(just get-args-from-jobs 1) --no-update-lock-file {{args}}


@run-v1-unit-tests *args='':
    nix build .#tests.$(nix eval --raw nixpkgs#system).v1-unit-tests -I nixpkgs=flake:nixpkgs $(just get-args-from-jobs 1) --no-update-lock-file {{args}}

@run-v1-integration-tests *args='':
    nix build .#tests.$(nix eval --raw nixpkgs#system).v1-integration-tests -I nixpkgs=flake:nixpkgs $(just get-args-from-jobs 1) --no-update-lock-file {{args}}

@run-v1-restricted-tests *args='':
    nix build .#tests.$(nix eval --raw nixpkgs#system).v1-restricted-tests -I . $(just get-args-from-jobs 1) --no-update-lock-file --restrict-eval --allowed-uris 'github: gitlab: git+ssh:// git+https://' {{args}}

@run-v1-tests *args='':
    nix build .#tests.$(nix eval --raw nixpkgs#system).v1-tests -I nixpkgs=flake:nixpkgs $(just get-args-from-jobs 1) --no-update-lock-file {{args}}


@run-v2-unit-tests *args='':
    nix build .#tests.$(nix eval --raw nixpkgs#system).v2-unit-tests -I nixpkgs=flake:nixpkgs $(just get-args-from-jobs 1) --no-update-lock-file {{args}}
    
@run-v2-integration-tests *args='':
    nix build .#tests.$(nix eval --raw nixpkgs#system).v2-integration-tests -I nixpkgs=flake:nixpkgs $(just get-args-from-jobs 1) --no-update-lock-file {{args}}

@run-v2-restricted-tests *args='':
    nix build .#tests.$(nix eval --raw nixpkgs#system).v2-restricted-tests -I . $(just get-args-from-jobs 1) --no-update-lock-file --restrict-eval --allowed-uris 'github: gitlab: git+ssh:// git+https://' {{args}}

@run-v2-tests *args='':
    nix build .#tests.$(nix eval --raw nixpkgs#system).v2-tests -I nixpkgs=flake:nixpkgs $(just get-args-from-jobs 1) --no-update-lock-file {{args}}


@run-unit-tests *args='':
    nix build .#tests.$(nix eval --raw nixpkgs#system).unit-tests -I nixpkgs=flake:nixpkgs $(just get-args-from-jobs 1) --no-update-lock-file {{args}}

@run-integration-tests *args='':
    nix build .#tests.$(nix eval --raw nixpkgs#system).integration-tests -I nixpkgs=flake:nixpkgs $(just get-args-from-jobs 1) --no-update-lock-file {{args}}

@run-tests *args='':
    nix build .#tests.$(nix eval --raw nixpkgs#system).all-tests -I nixpkgs=flake:nixpkgs $(just get-args-from-jobs 1) --no-update-lock-file {{args}}


@fmt *args='.':
    just in-nix-shell 2>/dev/null || exit 1
    nixfmt "{{args}}"

@fmt-check *args='.':
    just in-nix-shell 2>/dev/null || exit 1
    nixfmt --check "{{args}}"


# Updates a lock file using the shell's current nodejs without building modueles, as in creating a node_modules folder. Useful for updating `package-lock.json` files in the tests if needed
@update-lock-file:
    just in-nix-shell 2>/dev/null || exit 1
    rm -f package-lock.json
    rm -rf node_modules
    npm -i --package-lock-only


################################
#### UTILS
################################
# Deletes unused generations and then wipes out all unused packages in nix store
@gc:
    just not-in-devenv 2>/dev/null || exit 1
    nix-collect-garbage -d
    # nix-env --delete-generations old
    # nix-store --gc

# Checks current space left in all disk partitions
@check-disk-storage:
    df -h

# Displays size of all directories in the given directory that are surpass 10Mb
@check-storage-left *dir='~/.':
    du -h -BM -c -t 10M {{dir}}

# Enter an interactive Nix repl with nixpkgs set to the one set by this Nix Flake. This also sets the repl with `pkgs` already declared, so running `pkgs = import <nixpkgs> {}` isn't necessary
@nix-repl:
    nix repl -f flake:nixpkgs

@get-cores-per-job *jobs="":
    echo "$(($(getconf _NPROCESSORS_ONLN 2>/dev/null || getconf NPROCESSORS_ONLN 2>/dev/null || echo 1) / {{jobs}}))"

# Utility command to set the arguments for jobs and max cores dedicates to building derivations based on the amount of jobs expected to be done
@get-args-from-jobs *jobs="":
    echo "-j {{jobs}} --cores $(just get-cores-per-job {{jobs}})"

# Checks if current shell is running inside a nix flake shell
@in-nix-shell:
    [ -z "${IN_NIX_SHELL:-}" ] && \\
        echo "Error: Not running under a nix flake shell" && \\
        echo "You can run:" && \\
        echo "just shell" && \\
        echo "or" && \\
        echo "nix develop .#default" && \\
        exit 1 || :

# Checks if current shell is NOT running inside a nix flake shell
@not-in-nix-shell:
    [ ! -z "${IN_NIX_SHELL:-}" ] && \\
        echo "Error: Already running inside a nix flake shell" && \\
        exit 1 || :