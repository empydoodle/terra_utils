# Changelog for terra_utils

## v1.0.0 (2025-XX-XX)

### Features

* Add command aliasing with separate config (`lib/terra_utils/terra_alias`)
* (`lib/terragrunt_o_matic/key_env_vars`) Extract secrets (e.g. NR / PD) from 1Password
* (`bin/tg`) New options / switches for turning off features / providing separate config
* (`lib/terragrunt_o_matic`) Allow multiple project dirs (for local module usage)
* (`lib/terragrunt_o_matic`) Include `TG_LOG` and `TG_LOG_LEVEL` variables in debug mode

## Fixes

* (`bin/tg`) Replace broken `-?` option in executable (with `-h`)
* (`lib/danger_zone`) Fix broken name `lib_name` logic

## Refactors

* (`lib`) Complete refactor of lib structure to follow module/class hierarchy
* (`*`) Move as much configuration as possible to separate TerraUtils-specific config
  * Move large features (e.g. environment variable autofill) to dedicated config
  * Default / template config provided in `config` dir
  * Update install file to populate new config
* (`*`) Whitelabel all config and libraries
* (`bin/tg`) Executable options logic moved to separate library
  * Additional information in `--help` regarding new configuration
* (`lib/t_g_helpers`) Give `TGHelpers` a better name
* (`setup.thor`) Overhaul installation with config generation - additional libraries created in `lib/terra_utils/setup`

### Docs

* (`README`) Update with new setup and config options

### Other

## v0.3.1 (2025-01-15)

### Features

### Fixes

### Refactors

* (`lib`) Further minor refactoring
* (`bin/tg`) Change `-s` option to `-p` in executable (replacing "don't" logic with "do")

### Docs

### Other

* (`.gitignore`) Remove redundant entries from `.gitignore`

## v0.3.0 (2025-01-15)

### Features

* Improved setup script using `Thor`

### Fixes

* (`lib/terragrunt_o_matic`) Workaround allow passing of terragrunt command args if given in string (e.g. tg 'apply -target X')
* (`*`) Amended references to New Relic to align with `new_relic`

### Refactors

* (`lib`) Refactor of code to multiple libraries

### Docs

### Other

## v0.2.0 (2024-10-17)

### Features

* Setup script created to automate installation and config (`setup.rb`)
* (`lib/terragrunt_o_matic`) Increased compatibility with Terragrunt dirs that do not include namespace in dir structure
* (`lib/terragrunt_o_matic`) Automatic AWS auth (via `saml2aws`)
* (`lib/terragrunt_o_matic`) Boolean switch to delete Terragrunt cache (`.terragrunt-cache`)
* (`bin/tg`) Version output in executable

### Fixes

### Refactors

* (`lib/terragrunt_o_matic`) Separated output-only mode from debug mode
* (`lib/terragrunt_o_matic`) Instance variable refactoring

### Docs

* (`README`) Installation instructions updated

### Other

## v0.1.0 (2024-10-15)

### Features

* Quick / easy NewRelic and PagerDuty env variable retrieval
* Turn on `--terragrunt-source` with a boolean switch
* Easier provider upgrade and lock
* Executable created (`tg.rb`)

### Fixes

## Refactors

* `DangerZone` logging library 'imported' and repurposed

### Docs

* `README` including installation, setup and usage

### Other
