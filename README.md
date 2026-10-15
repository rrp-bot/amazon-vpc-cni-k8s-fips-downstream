# Amazon VPC CNI FIPS downstream

This repository keeps the upstream `amazon-vpc-cni-k8s` source as a Git
submodule and owns the container build definition. The upstream Dockerfiles
are intentionally not modified.

The submodule is pinned to upstream release `v1.23.0`
(`0c65d58cf2b490014e7aa19aac172a032f4e520a`). Updates should change the
submodule pointer in a reviewable commit.

The root `Containerfile` builds the primary CNI image with the Red Hat Go
toolchain and Go's native FIPS module:

- `GOFIPS140=certified`
- `strictfipsruntime,no_openssl` build tags
- `GODEBUG=fips140=auto` at runtime
- UBI9 Go builder and UBI9 minimal runtime

The builder compiles the same five binaries and copies the runtime data used
by the upstream release image. The init and metrics images can be added as
separate downstream components using the same pattern.

## Local build

The submodule must be initialized before building:

```bash
git submodule update --init --recursive
podman build -f Containerfile -t amazon-vpc-cni-fips .
```

Image references should be replaced with approved immutable digests in the
release configuration. Optional build arguments are available for source
metadata and versioning:

```bash
podman build -f Containerfile \
  --build-arg SOURCE_REVISION=$(git -C upstream rev-parse HEAD) \
  --build-arg VERSION=$(git -C upstream describe --tags --always) \
  -t amazon-vpc-cni-fips .
```

Konflux must initialize the submodule before producing the trusted build
context. The pipeline files are intentionally not included yet.
