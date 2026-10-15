# Amazon VPC CNI FIPS downstream

This repository keeps the upstream `amazon-vpc-cni-k8s` source as a Git
submodule and applies small, reviewable FIPS patches to a clean checkout
before building. The upstream Dockerfiles remain the build definitions.

The submodule is pinned to upstream release `v1.23.0`
(`0c65d58cf2b490014e7aa19aac172a032f4e520a`). Updates should change the
submodule pointer in a reviewable commit.

The patches update the upstream Makefile's Go build flags and convert the
upstream release, init, and metrics Dockerfiles to use the Red Hat Go
toolchain and Go's native FIPS module:

- `GOFIPS140=certified`
- `strictfipsruntime,no_openssl` build tags
- `GODEBUG=fips140=auto` at runtime
- UBI9 Go builder and UBI9 minimal runtime

The actual compilation continues to use the upstream Makefile targets.

## Local build

The submodule must be initialized before building:

```bash
./prepare-upstream.sh
podman build \
  --build-arg golang_image=registry.access.redhat.com/ubi9/go-toolset:9.8-1791479310 \
  --build-arg base_image=registry.access.redhat.com/ubi9/ubi-minimal:9.8-1791765279 \
  -f upstream/scripts/dockerfiles/Dockerfile.release \
  -t amazon-vpc-cni-fips:v1.23.0 upstream
```

The init and metrics images use the same prepared context:

```bash
podman build -f upstream/scripts/dockerfiles/Dockerfile.init \
  -t amazon-vpc-cni-init-fips:v1.23.0 upstream
podman build -f upstream/scripts/dockerfiles/Dockerfile.metrics \
  -t amazon-cni-metrics-fips:v1.23.0 upstream
```

Image references should be replaced with approved immutable digests in the
release configuration. Optional build arguments are available for source
metadata and versioning:

```bash
podman build -f upstream/scripts/dockerfiles/Dockerfile.release \
  --build-arg SOURCE_REVISION=$(git -C upstream rev-parse HEAD) \
  --build-arg VERSION=$(git -C upstream describe --tags --always) \
  -t amazon-vpc-cni-fips upstream
```

Konflux must run `prepare-upstream.sh` before producing the trusted build
context. The build task should then use `upstream` as `path-context` and use
the Dockerfile path relative to that context, for example
`scripts/dockerfiles/Dockerfile.release`. The modified upstream tree must be
passed to the build task or republished as the next trusted source artifact.
The pipeline files are intentionally not included yet.
