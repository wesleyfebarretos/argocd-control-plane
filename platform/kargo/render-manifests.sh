#!/usr/bin/env bash
# Renders every platform/<component>/kustomization.yaml into
# <outPath>/<component>/manifests.yaml.
#
# Kargo runs this in the promotion workspace, after git-clone and git-clear.
# SRC_PATH is the freight checkout (./src). OUT_PATH is the stage branch (./out).
set -euo pipefail

: "${SRC_PATH:?SRC_PATH is required}"
: "${OUT_PATH:?OUT_PATH is required}"

# The step container runs as uid 65532. Its default home is not writable.
mkdir -p "${HOME}/bin"
bindir="${HOME}/bin"

case "$(uname -m)" in
  x86_64) arch=amd64 ;;
  aarch64 | arm64) arch=arm64 ;;
  *)
    echo "Unsupported architecture: $(uname -m)" >&2
    exit 1
    ;;
esac

kustomize_version=v5.8.1
helm_version=v3.17.4

curl -fsSL -o "${HOME}/kustomize.tar.gz" \
  "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F${kustomize_version}/kustomize_${kustomize_version}_linux_${arch}.tar.gz"
tar -xzf "${HOME}/kustomize.tar.gz" -C "${bindir}"
chmod +x "${bindir}/kustomize"

curl -fsSL -o "${HOME}/helm.tar.gz" \
  "https://get.helm.sh/helm-${helm_version}-linux-${arch}.tar.gz"
tar -xzf "${HOME}/helm.tar.gz" -C "${HOME}"
mv "${HOME}/linux-${arch}/helm" "${bindir}/helm"
chmod +x "${bindir}/helm"

export PATH="${bindir}:${PATH}"

platform="${SRC_PATH%/}/platform"
if [[ ! -d "${platform}" ]]; then
  echo "Platform directory not found: ${platform}" >&2
  exit 1
fi

shopt -s nullglob
kustomizations=("${platform}"/*/kustomization.yaml)
if ((${#kustomizations[@]} == 0)); then
  echo "No component kustomization.yaml files under ${platform}" >&2
  exit 1
fi

pids=()
names=()
for kust in "${kustomizations[@]}"; do
  component="$(basename "$(dirname "${kust}")")"
  (
    echo "Rendering ${component}"
    mkdir -p "${OUT_PATH}/${component}"
    # stdout is the manifest. kustomize logs stay on stderr.
    kustomize build "${platform}/${component}" --enable-helm > "${OUT_PATH}/${component}/manifests.yaml"
    if [[ ! -s "${OUT_PATH}/${component}/manifests.yaml" ]]; then
      echo "kustomize produced an empty manifest for ${component}" >&2
      exit 1
    fi
    echo "Rendered ${component} -> ${OUT_PATH}/${component}/manifests.yaml"
  ) &
  pids+=("$!")
  names+=("${component}")
done

failed=0
for i in "${!pids[@]}"; do
  if ! wait "${pids[$i]}"; then
    echo "Render failed for ${names[$i]}" >&2
    failed=1
  fi
done

if ((failed != 0)); then
  exit 1
fi
