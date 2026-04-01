# nix-packages

> [!IMPORTANT]
> This repository is intended for internal use. No guarantees are made regarding package availability or interface stability.
>
> We recommend cloning the repository and maintaining your own copy.

## Example of a package installation

```sh
NIXPKGS_ALLOW_UNFREE=1 nix profile add --impure 'git+ssh://git@github.com/hnjae/nix-packages#obsidian'
```
