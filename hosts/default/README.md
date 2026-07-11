# Default Host Template

This host is the starter template for new machines. Copy it into
`hosts/<host>/`, adjust imports/hardware as needed, then track that host in git.

Quick path:

```bash
sudo ./scripts/new-host <host> <user>
sudo nixos-generate-config --root /mnt
sudo cp /mnt/etc/nixos/hardware-configuration.nix /etc/nixos/hosts/<host>/hardware-configuration.nix
./scripts/check-local
git add hosts/<host>
```

Keep reusable system pieces in `modules/`. Keep hardware-specific imports, disk
details, bus IDs, and generated hardware configuration in the local host folder.
