set -e

cores_per_job() {
    echo "$(($(getconf _NPROCESSORS_ONLN 2>/dev/null || getconf NPROCESSORS_ONLN 2>/dev/null || echo 1) / $1))"
}

cores_jobs_args() {
    echo "-j $1 --cores $(cores_per_job $1)"
}

arch=$(nix eval --raw nixpkgs#system)

echo "========================================"
echo "Running test suite for V1 npm lockfiles"
echo "========================================"

echo -e "Running unit tests and integration tests for V1 lockfiles\n"
nix build .#tests.$arch.v1-tests $(cores_jobs_args 1) --no-keep-outputs --no-link --show-trace

echo -e "\n\nRunning restricted mode tests for V1 lockfiles\n"
nix build .#tests.$arch.v1-restricted-tests -I . $(cores_jobs_args 1) --restrict-eval --allowed-uris 'https://github.com/NixOS/nixpkgs/ github: gitlab: git+ssh:// git+https://' --show-trace

echo "========================================"
echo "Running test suite for V2 npm lockfiles"
echo "========================================"

echo -e "Running unit tests and integration tests for V2 lockfiles\n"
nix build .#tests.$arch.v2-tests $(cores_jobs_args 1) --no-keep-outputs --no-link --show-trace

echo -e "\n\nRunning restricted mode tests for V2 lockfiles\n"
nix build .#tests.$arch.v2-restricted-tests -I . $(cores_jobs_args 1) --restrict-eval --allowed-uris 'https://github.com/NixOS/nixpkgs/ github: gitlab: git+ssh:// git+https://' --show-trace