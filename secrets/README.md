# Local Secrets

This directory is intentionally ignored except for this README. Put machine-local
secret material here after cloning the repo.

Expected files used by the default modules:

```text
secrets/<user>.password.hash
secrets/aws/credentials
secrets/restic/password
secrets/restic/rclone.conf
```

Create a NixOS password hash with:

```bash
mkpasswd -m sha-512
```

Do not commit real secrets. If a file in this directory appears in `git status`,
stop and check `.gitignore` before adding it.
