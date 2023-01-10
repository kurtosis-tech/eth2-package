# Changelog

## [0.3.0](https://github.com/kurtosis-tech/eth2-package/compare/0.2.0...0.3.0) (2023-01-10)


### ⚠ BREAKING CHANGES

* Uses the `plan` object. Users will have to update their Kurtosis CLI to >= 0.63.0 and restart the engine

### Bug Fixes

* update genesis generator to support netherminds new format ([#68](https://github.com/kurtosis-tech/eth2-package/issues/68)) ([094352d](https://github.com/kurtosis-tech/eth2-package/commit/094352d6666755da5de6ed3f4b78fd5f37c01f7f))
* use named artifacts ([#69](https://github.com/kurtosis-tech/eth2-package/issues/69)) ([968f073](https://github.com/kurtosis-tech/eth2-package/commit/968f0734a0ee834c75e184b758989ce1dc9d58be)), closes [#70](https://github.com/kurtosis-tech/eth2-package/issues/70)
* Use plan object ([#65](https://github.com/kurtosis-tech/eth2-package/issues/65)) ([8e5d185](https://github.com/kurtosis-tech/eth2-package/commit/8e5d18558f92a9fc71ae9a70f1ca139df406d7b7))

## 0.2.0

- Adds config variables for `genesis_delay` and `capella_fork_epoch`
- Updates genesis generator version
- Fixes genesis timestamp such that the shanghai fork can happen based on timestamps

### Breaking Change
- Introduced optional application protocol and renamed protocol to transport_protocol

## 0.1.0

### Breaking changes
- Updated `struct` to `PortSpec` for declaring port definitions

### Changes
- Change `exec` syntax

## 0.0.5

### Fixes
- Fix bug with input parsing of participants
- Fix bug with `get_enode_for_node` being assigned to two parameters

### Changes
- Updated `run(input_args)` to `run(args)`
- Refactor code to use `wait` and `request` commands
- Removed `print(output)` at the end as it is now printed by the framework
- Updates nimbus default docker image
- Updates `genesis-generator` image to include a fix for nimbus post-merge genesis
- Use the `args` argument instead of flags

## 0.0.4
### Changes
- Removed 'module' key in the 'kurtosis.yml' file

## 0.0.3
### Changes
- Replaced 'module' with 'package' where relevant
- Removed protobuf types as they are now unsupported in Kurtosis.
- Renamed `kurtotis.mod` to `kurtosis.yml`

### Fixes
- Fixed a bug in `run` of `main.star` where we'd refer to `module_io` instead of `package_io`

## 0.0.2

### Features
- Added the docs

### Fixes
- Renamed `num_validators_per_keynode` to `num_validator_keys_per_node`
- Moved away from `load` infavor of `import_module`
- Moved away from `store_files_from_service` to `store_service_files`
- Removed empty `ports` from a few service configs as passing it is now optional
- Adjusted to the new render templates config
- Moved away from passing json string to struct/dict for render templates

### Changes
- Move from `main` to `run` in `main.star`

## 0.0.1

### Features
- Changed the .circlei/config.yml to apply to Startosis
- Added genesis_constants
- Added a lot of participant_network/pre_launch_data_generator
- Added a lot of simple objects that just keep data
- Added monitoring on top of the repo
- Almost perfect parity with the eth2-merge-kurtosis-module

### Fixes
- Fixes some bugs with the initial implementation of the monitors

## 0.0.0
* Initial commit
