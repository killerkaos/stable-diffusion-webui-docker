#!/bin/bash

set -Eeuo pipefail

CUSTOM_NODES="/data/config/comfy/custom_nodes"
mkdir -vp "${CUSTOM_NODES}"

declare -A MOUNTS

MOUNTS["${CACHE}"]="/data/.cache"
MOUNTS["${ROOT}/input"]="/data/config/comfy/input"
MOUNTS["${ROOT}/output"]="/output/comfy"

for to_path in "${!MOUNTS[@]}"; do
  set -Eeuo pipefail
  from_path="${MOUNTS[${to_path}]}"
  rm -rf "${to_path}"
  if [ ! -f "$from_path" ]; then
    mkdir -vp "$from_path"
  fi
  mkdir -vp "$(dirname "${to_path}")"
  ln -sT "${from_path}" "${to_path}"
  echo Mounted $(basename "${from_path}")
done

if [ "${UPDATE_CUSTOM_NODES:-false}" = "true" ]; then
  find /data/config/comfy/custom_nodes/ -mindepth 1 -maxdepth 1 -type d | while read NODE
    do echo "---- ${NODE##*/} ----"
    set +e
    cd "$NODE" && git pull; cd ..;
    set -e
  done
fi

if [ "${USE_KRITA}" = "true" ]; then
  [ -d "${ROOT}/models/upscale_models" ] && rm -rf "${ROOT}/models/upscale_models"
  if [ ! -L "${ROOT}/models/upscale_models" ]; then
    cd "${ROOT}/models"
    ln -sfT /data/models/upscale_models upscale_models && cd ..
  fi
  if [ "${KRITA_DOWNLOAD_MODELS:-false}" = "true" ]; then
    cd "${ROOT}/krita-ai-diffusion/scripts" && python3 download_models.py --verbose --retry-attempts 10 --continue-on-error --recommended /data && cd -
  fi
fi
if [ "${USE_GGUF}" = "true" ]; then
  [ ! -e "${CUSTOM_NODES}/ComfyUI-GGUF" ] && cp -a "${ROOT}/ComfyUI-GGUF" "${CUSTOM_NODES}"/
fi
if [ "${USE_XFLUX}" = "true" ]; then
  [ ! -e "${CUSTOM_NODES}/x-flux-comfyui" ] && cp -a "${ROOT}/x-flux-comfyui" "${CUSTOM_NODES}"/
  [ ! -e "/data/models/clip_vision" ] && mkdir -p /data/models/clip_vision
  [ ! -e "/data/models/clip_vision/model.safetensors" ] && cd /data/models/clip_vision && \
    python3 -c 'import sys; from urllib.request import urlopen; from pathlib import Path; Path(sys.argv[2]).write_bytes(urlopen(sys.argv[1]).read())' \
      "https://huggingface.co/openai/clip-vit-large-patch14/resolve/main/model.safetensors" "model.safetensors"
  [ ! -e "/data/models/xlabs" ] && mkdir -p /data/models/xlabs/{ipadapters,loras,controlnets}
  [ ! -e "/data/models/xlabs/ipadapters/flux-ip-adapter.safetensors" ] && cd /data/models/xlabs/ipadapters && \
    python3 -c 'import sys; from urllib.request import urlopen; from pathlib import Path; Path(sys.argv[2]).write_bytes(urlopen(sys.argv[1]).read())' \
      "https://huggingface.co/XLabs-AI/flux-ip-adapter/resolve/main/ip_adapter.safetensors" "flux-ip-adapter.safetensors"
  [ -d "${ROOT}/models/xlabs" ] && rm -rf "${ROOT}/models/xlabs"
  [ ! -e "${ROOT}/models/xlabs" ] && cd "${ROOT}/models" && ln -sT /data/models/xlabs xlabs && cd ..
fi
if [ "${USE_CNAUX}" = "true" ] || [ "${USE_KRITA}" = "true" ]; then
  [ ! -e "${CUSTOM_NODES}/comfyui_controlnet_aux" ] && cp -a "${ROOT}/comfyui_controlnet_aux" "${CUSTOM_NODES}"/
fi
if [ "${USE_IPAPLUS}" = "true" ] || [ "${USE_KRITA}" = "true" ]; then
  [ ! -e "${CUSTOM_NODES}/ComfyUI_IPAdapter_plus" ] && cp -a "${ROOT}/ComfyUI_IPAdapter_plus" "${CUSTOM_NODES}"/
fi
if [ "${USE_INPAINT}" = "true" ] || [ "${USE_KRITA}" = "true" ]; then
  [ ! -e "${CUSTOM_NODES}/comfyui-inpaint-nodes" ] && cp -a "${ROOT}/comfyui-inpaint-nodes" "${CUSTOM_NODES}"/
fi
if [ "${USE_TOOLING}" = "true" ] || [ "${USE_KRITA}" = "true" ]; then
  [ ! -e "${CUSTOM_NODES}/comfyui-tooling-nodes" ] && cp -a "${ROOT}/comfyui-tooling-nodes" "${CUSTOM_NODES}"/
fi

if [ -f "/data/config/comfy/startup.sh" ]; then
  pushd "${ROOT}"
  . /data/config/comfy/startup.sh
  popd
fi

exec "$@"
