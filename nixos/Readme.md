* About symlinks
> You only have to symlink configuration.nix. As you’ve realised, the crucial fact is that the relative imports are resolved from the actual location of the file. So having symlinked in configuration.nix from machines/whatever/configuration.nix, the import ./hardware-configuration.nix resolves correctly to machines/whatever/hardware-configuration.nix.
