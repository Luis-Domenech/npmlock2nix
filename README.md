
<!-- badges -->
[![License][license-shield]][license-url]
[![Contributors][contributors-shield]][contributors-url]
[![Issues][issues-shield]][issues-url]
[![PRs][pr-shield]][pr-url]
[![Tests][test-shield]][test-url]

<!-- teaser -->
<br />
<p align="center">
  <h2 align="center">npmlock2nix</h2>
  <p align="center">
    Simple and unit tested solution to nixify npm based packages.
  </p>
</p>

## About

_npmlock2nix_ is a Nix based library that parses the `package.json` and `package-lock.json` files in order to provide different outputs:

- A `shell` environment
- A `node_modules` derivation
- A custom `build` derivation

### Fork Details
This is a personal fork of [npmlock2nix][npmlock2nix-url] to fix some issues with the package since the the package is currently in a state of low maintenance.

This fork:
1. Fixes the [issue](https://github.com/nix-community/npmlock2nix/issues/194) that prevented the package from building due to `nodejs_16` being removed in nixpkgs v25.05 and `nodejs_16` being an expected input for the API internals.
   - I opted with making the nodejs versions overrideable and making a clear distrinction between the nodejs version used for the v1 API and the v2 API since the v1 API requires an old  nodejs version to work.
   - Additionally, I also made the v1 API's nodejs version fallback to an old nodejs version from an old nixpkgs version. This occurs if no nodejs version is passed and the default nodejs package of the user's nixpkgs is too recent.
2. Adds Nix Flake support with [flake-utils][flake-utils-url] for Development, Testing and Usage.
    - Although the package was updated to be a Nix Flake, the package can still be used like before since [default.nix](/default.nix) still works as expected 
3. Overhauls testing to work with the Nix Flake update.
4. Development setup and workflow was overhauled to work with the Nix Flake devShell.
    - Development workflow mostly revolves around the use of [just][just-url] (a command runner) since all important commands are there.
5. Dependency versions are pinned for development and testing purposes, but easily overrideable due to the Nix Flake support.
   - Reliance on [niv][niv-url] was removed since pinning of nixpkgs and depdencies is now handled with the Nix Flake support.
6. All tests for the v1 and v2 APIs have been made to work with the Nix Flake devShell, without it and in the Github Actions CI/CD pipeline.
7. All dependencies have been updated and broken urls have been and typos have been fixed


### Features

- No auto-generated code :heavy_check_mark:
- Works in restricted evaluation :heavy_check_mark:
- GitHub dependencies :heavy_check_mark:
- Unit Tests :heavy_check_mark:
- Integration Tests :heavy_check_mark:

## Getting Started

Since `npmlock2nix` is written entirely in Nix, there aren't any additional prerequisites, it just needs to be imported into your project.

### Installation

Just add the following to your Nix Flake inputs:
```nix
npmlock2nix = {
  url = "github:Luis-Domenech/npmlock2nix";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

#### Example with `flake-utils`
```nix
# flake.nix
{
  description = "npmlock2nix";
  inputs = {
    # NixOS unstable v25.05 from 12/03/2024 (MM/DD/YYYY)
    nixpkgs.url = "github:NixOS/nixpkgs/55d15ad12a74eb7d4646254e13638ad0c4128776";

    flake-utils = {
      url = "github:numtide/flake-utils";
    };

    npmlock2nix = {
      url = "github:Luis-Domenech/npmlock2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      npmlock2nix,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        some-nodejs-project = npmlock2nix.v2.build {
          src = ./.;
          installPhase = "cp -r dist $out";
          buildCommands = [ "npm run build" ];
        };
      in
      {
        packages = {
          inherit some-nodejs-project;
        };
      }
    );
}
```

## Usage

The following sections outline the main use-case scenarios of _npmlock2nix_.

**Note**: All examples only reflect the most basic scenarios and mandatory arguments. For more details please refer to the [API documentation][api-url].

**Note**: All code snippets provided below assume that _npmlock2nix_ has been imported and is in scope and that there are valid `package.json` and `package-lock.json` files in the project root.

### Providing A Shell

```nix
npmlock2nix.shell {
  src = ./.;
}
```
The `shell` function creates an environment with the `node_modules` installed that can be used for development purposes.

Please refer to the [API documentation][api-url] for additional information on `shell`.


### Building `node_modules`

```nix
npmlock2nix.node_modules {
  src = ./.;
}
```
The `node_modules` function creates a derivation containing the equivalent of running `npm install` in an impure environment.

Please refer to the [API documentation][api-url] for additional information on `node_modules`.


### Building A Project

```nix
npmlock2nix.build {
  src = ./.;
  installPhase = "cp -r dist $out";
  buildCommands = [ "npm run build" ];
}
```
The `build` function can be used to package arbitrary npm based projects. In order for this to work,
_npmlock2nix_ must be told how to build the project (`buildCommands`) and how to install it (`installPhase`).

Please refer to the [API documentation][api-url] for additional information on `build`.

## Contributing

Contributions to this project are welcome in the form of GitHub Issues or PRs. Please consider the following before creating PRs:

- This project uses [nixfmt][nixfmt-url] for formatting the Nix code and [just][just-url] for running commands. You can use `just fmt .` to format everything.
- If you are planning to make any considerable changes, you should first present your plans in a GitHub issue so it can be discussed
- _npmlock2nix_ is developed with a strong emphasis on testing. Please consider providing tests along with your contributions and don't hesitate to ask for support.

## Development

When working on _npmlock2nix_, it's highly recommended to use [direnv][direnv-url] and the project's default flake devShell which provides:

- A commit hook for code formatting via [nix-pre-commit-hooks][nix-pre-commit-hooks-url].
- A `test-runner` script that watches the source tree and runs the unit tests on changes.

### Setting Up Development Environment
1. Install [Nix][nix-url]
    - Linux
    ```bash
    curl -L https://nixos.org/nix/install | sh -s -- --daemon
    ```
    - MacOS
    ```bash
    curl -L https://nixos.org/nix/install | sh
    ```
2. Install [just][just-url]
```bash
brew install just
```
3. (OPTIONAL) Install [direnv][direnv-url]
4. Enter Nix Dev Shell (will take a while on first run)
```bash
just shell
```

Once in the dev shell, you can start developing.

You can exit the Nix dev shell by simply running `exit`

The unit tests (for both v1 and v2 APIs) can be executed via `just run-unit-tests`.

The integration tests (for both v1 and v2 APIs) can be executed via `just run-integration-tests`.


### `direnv` Notes
If [direnv][direnv-url] is installed and `direnv allow` or `just direnv-allow` has been ran in project directory at least once, everytime you cd to the project directory, the [`.envrc`](/.envrc) will be executed and you will automatically be loaded into the Nix dev shell.

If you also have your IDE setup to work with [direnv][direnv-url] (like the [direnv VSCode Extensions][direnv-ext-url]), your IDE will automatically enter the dev shell too. For example, if you don't have [nixd][nixd-url] (a Nix LSP) installed, then your IDE entering the dev shell will install it and thus will be able to provide LSP features for your Nix code.


## License

Distributed under the Apache 2.0 License. See [license][license-url] for more details

## Acknowledgements

- [direnv][direnv-url]
- [entr][entr-url]
- [flake-utils][flake-utils-url]
- [just][just-url]
- [nixd][nixd-url]
- [nixfmt][nixfmt-url]
- [nix-pre-commit-hooks][nix-pre-commit-hooks-url]
- [npmlock2nix][npmlock2nix-url]
- [smoke][smoke-url]


<!-- MARKDOWN LINKS & IMAGES -->
[contributors-shield]: https://img.shields.io/github/contributors/Luis-Domenech/npmlock2nix?style=for-the-badge
[contributors-url]: https://github.com/Luis-Domenech/npmlock2nix/graphs/contributors
[issues-shield]: https://img.shields.io/github/issues/Luis-Domenech/npmlock2nix?style=for-the-badge
[issues-url]: https://github.com/Luis-Domenech/npmlock2nix/issues
[license-shield]: https://img.shields.io/github/license/Luis-Domenech/npmlock2nix?style=for-the-badge
[license-url]: https://github.com/Luis-Domenech/npmlock2nix/blob/main/LICENSE
[test-shield]: https://img.shields.io/github/actions/workflow/status/Luis-Domenech/npmlock2nix/run_ci.yml?branch=main&style=for-the-badge
[test-url]: https://github.com/Luis-Domenech/npmlock2nix/actions
[pr-shield]: https://img.shields.io/github/issues-pr/Luis-Domenech/npmlock2nix?style=for-the-badge
[pr-url]: https://github.com/Luis-Domenech/npmlock2nix/pulls


<!--Other external links -->
[api-url]: ./API.md
[direnv-url]: https://github.com/direnv/direnv
[direnv-ext-url]: https://github.com/direnv/direnv-vscode.git
[entr-url]: https://github.com/eradman/entr
[flake-utils-url]: https://github.com/numtide/flake-utils
[just-url]: https://github.com/casey/just
[nix-url]: https://github.com/NixOS/nix
[nixd-url]: https://github.com/nix-community/nixd
[nixfmt-url]: https://github.com/NixOS/nixfmt
[nix-pre-commit-hooks-url]: https://github.com/cachix/git-hook.nix
[niv-url]: https://github.com/nmattia/niv
[npmlock2nix-url]: https://github.com/nix-community/npmlock2nix
[smoke-url]: https://github.com/SamirTalwar/Smoke
