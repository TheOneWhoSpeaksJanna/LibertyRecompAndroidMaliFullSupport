#!/bin/bash
# Host shader tools the gta4-native override cache needs at build time.
#   - DXC: the copy bundled in tools/XenosRecomp (1.8.2407) crashes on the
#     Bink pixel shaders, so a newer official release is used.
#   - glslangValidator: GLSL overrides (motion blur).
#   - spirv-val ships with the NDK and needs no download.
# Everything lands in out/host-tools inside the repository.
set -euo pipefail
. "$(dirname "$0")/env.sh"
DEST="$REPO/out/host-tools"
DXC_URL="https://github.com/microsoft/DirectXShaderCompiler/releases/download/v1.9.2609/dxc_2026_09_29.zip"
GLSLANG_URL="https://github.com/KhronosGroup/glslang/releases/download/16.6.0/glslang-16.6.0-windows-x86_64-release.zip"
mkdir -p "$DEST"
cd "$DEST"

# GitHub's large release-asset endpoint sometimes responds with HTTP 500.
# Retry transient failures and fall back to GitHub CLI's authenticated API
# download. Never accept a partial ZIP as a successful tool download.
download_release_asset() {
  local url="$1" output="$2" repository="$3" tag="$4"
  rm -f "$output.part"
  if curl --fail --location --silent --show-error --retry 7 \
      --retry-delay 5 --retry-all-errors --connect-timeout 25 \
      --output "$output.part" "$url"; then
    mv -f "$output.part" "$output"
    return 0
  fi
  rm -f "$output.part"
  if command -v gh >/dev/null 2>&1 && [ -n "${GH_TOKEN:-}" ]; then
    echo "== direct GitHub release download failed; retrying via the GitHub API"
    gh release download "$tag" --repo "$repository" \
      --pattern "$(basename "$output")" --dir . --clobber
    test -s "$output" && return 0
  fi
  echo "!! failed to download $(basename "$output") from $repository@$tag" >&2
  return 1
}

if [ ! -x dxc/bin/x64/dxc.exe ]; then
  download_release_asset "$DXC_URL" dxc.zip microsoft/DirectXShaderCompiler v1.9.2609
  # The archive uses backslash separators, which unzip mangles.
  powershell -NoProfile -Command "Expand-Archive -Force dxc.zip dxc"
fi
if [ ! -x glslang/bin/glslangValidator.exe ]; then
  download_release_asset "$GLSLANG_URL" glslang.zip KhronosGroup/glslang 16.6.0
  unzip -q -o glslang.zip -d glslang
  cp glslang/bin/glslang.exe glslang/bin/glslangValidator.exe
fi
dxc/bin/x64/dxc.exe --version
glslang/bin/glslangValidator.exe --version | head -1
