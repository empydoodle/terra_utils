# Terra Utils
Easier Terraform / Terragrunt usage

# Features

## Auto-Insert Environment Variables
Configure automatic passing of provider-required environment variables, which can sometimes be a pain.

Using config files containing each environment's / instance's IDs and tokens, `TerragruntOMatic` automates this step.

## Quality of Life Shortcuts
* Boolean switch for using local Terraform modules (`--terragrunt-source`).
  * Looks for the source in component config (`terragrunt.hcl`) and specifies the module from local storage.
* Boolean switch for upgrading Terraform lock file.
* Boolean switch for deleting Terragrunt cache (`.terragrunt-cache`) prior to running action.
* Automatic authentication with Terraform state provider (e.g. with AWS via `saml2aws`)
  * Can be disabled with a boolean switch.

# Usage

Executables contain reasonably detailed help prompts with suggested usage, e.g.

```
$ tg --help
```

# Installation

1. Install dependencies:

```
$ cd /path/to/terra_utils
$ ./install_dependencies.sh
```

2. Install dependent Ruby gems:

```
$ cd /path/to/terra_utils
$ bundle install
```

3. Run the setup utility to setup config / executable files:

```
$ thor setup
```

This will:

* Generate the primary config file (`terra_utils.json`) in `$HOME/.config/terra_utils` with configuration provided by user prompts.
  * An alternative config directory can be used by passing the path with `--config_dir`.
* Generate feature-specific config files as necessary for each project scope with configuration provided by user prompts.
  * `TerraAlias` copies from a standard template, which can be edited manually as required.
* Creates symlinks to executables in `/usr/local/bin` (alternative executable directory can be used by passing the path with `--exe_dir`):
  * `tg`
