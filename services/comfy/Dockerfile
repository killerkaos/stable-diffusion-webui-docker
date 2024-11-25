FROM pytorch/pytorch:2.5.1-cuda12.4-cudnn9-runtime

# Limited system user UID
ARG USE_UID=0
# Limited system user GID
ARG USE_GID=0
# System user name
ARG USE_USER=root
# System group name
ARG USE_GROUP=root
# Latest tag or bleeding edge commit
ARG USE_EDGE=false
# ComfyUI-GGUF
ARG USE_GGUF=false
# x-flux-comfyui
ARG USE_XFLUX=false
# comfyui_controlnet_aux
ARG USE_CNAUX=false
# krita-ai-diffusion
ARG USE_KRITA=false
# ComfyUI_IPAdapter_plus
ARG USE_IPAPLUS=false
# comfyui-inpaint-nodes
ARG USE_INPAINT=false
# comfyui-tooling-nodes
ARG USE_TOOLING=false

ENV USE_CNAUX=$USE_CNAUX USE_IPAPLUS=$USE_IPAPLUS
ENV USE_INPAINT=$USE_INPAINT USE_TOOLING=$USE_TOOLING
ENV DEBIAN_FRONTEND=noninteractive PIP_PREFER_BINARY=1 USE_EDGE=$USE_EDGE
ENV USE_GGUF=$USE_GGUF USE_XFLUX=$USE_XFLUX ROOT=/stable-diffusion
ENV CACHE=/home/$USE_USER/.cache USE_KRITA=$USE_KRITA

RUN mkdir -p ${ROOT} ${CACHE}/pip /home/${USE_USER}

# User/Group
RUN if [ ${USE_GID} -ne 0 ]; then \
    groupadd -r ${USE_GROUP} -g ${USE_GID}; \
  fi; \
  if [ ${USE_GID} -ne 0 ]; then \
    useradd --no-log-init -m -r -g ${USE_GROUP} ${USE_USER} -u ${USE_UID}; \
  fi; \
  chown -R ${USE_UID}:${USE_GID} ${ROOT} ${CACHE} /home/${USE_USER}

RUN apt-get update && apt-get install -y git python3-pip
RUN if [ "${USE_XFLUX}" = "true" ] || [ "${USE_KRITA}" = "true" ] || [ "${USE_CNAUX}" = "true" ]; then \
    apt-get install -y libgl1-mesa-glx python3-opencv; \
  fi
RUN apt-get clean

USER ${USE_USER}:${USE_GROUP}
ENV PATH="${PATH}:/home/${USE_USER}/.local/bin"

RUN --mount=type=cache,uid=${USE_UID},gid=${USE_GID},target=${CACHE} pip --cache-dir=${CACHE}/pip install -U pip

RUN --mount=type=cache,uid=${USE_UID},gid=${USE_GID},target=${CACHE} \
  git clone https://github.com/comfyanonymous/ComfyUI.git ${ROOT} && \
  cd ${ROOT} && \
  git checkout master && \
  bash -c 'VERSION=$(git describe --tags --abbrev=0) && \
  if [ "${USE_EDGE}" = "true" ]; then VERSION=$(git describe --abbrev=7); fi && \
  git reset --hard ${VERSION}' && \
  pip --cache-dir=${CACHE}/pip install -r requirements.txt && \
  if [ "${USE_KRITA}" = "true" ]; then \
    git clone https://github.com/Acly/krita-ai-diffusion.git && \
    cd krita-ai-diffusion && git checkout main && \
    git submodule update --init && \
    pip --cache-dir=${CACHE}/pip install aiohttp tqdm && cd ..; \
  fi; \
  if [ "${USE_GGUF}" = "true" ]; then \
    git clone https://github.com/city96/ComfyUI-GGUF.git && \
    cd ComfyUI-GGUF && git checkout main && \
    pip --cache-dir=${CACHE}/pip install -r requirements.txt && cd ..; \
  fi; \
  if [ "${USE_XFLUX}" = "true" ]; then \
    git clone https://github.com/XLabs-AI/x-flux-comfyui.git && \
    cd x-flux-comfyui && git checkout main && \
    pip --cache-dir=${CACHE}/pip install -r requirements.txt && cd ..; \
  fi; \
  if [ "${USE_CNAUX}" = "true" ] || [ "${USE_KRITA}" = "true" ]; then \
    git clone https://github.com/Fannovel16/comfyui_controlnet_aux.git && \
    cd comfyui_controlnet_aux && git checkout main && \
    pip --cache-dir=${CACHE}/pip install -r requirements.txt && \
    # This extra step to separate onnxruntime installation is required to restore onnx cuda support \
    pip --cache-dir=${CACHE}/pip install onnxruntime && pip --cache-dir=${CACHE}/pip install onnxruntime-gpu && cd ..; \
  fi; \
  if [ "${USE_IPAPLUS}" = "true" ] || [ "${USE_KRITA}" = "true" ]; then \
    git clone https://github.com/cubiq/ComfyUI_IPAdapter_plus.git && \
    cd ComfyUI_IPAdapter_plus && git checkout main && cd ..; \
  fi; \
  if [ "${USE_INPAINT}" = "true" ] || [ "${USE_KRITA}" = "true" ]; then \
    git clone https://github.com/Acly/comfyui-inpaint-nodes.git && \
    cd comfyui-inpaint-nodes && git checkout main && \
    pip --cache-dir=${CACHE}/pip install opencv-python && cd ..; \
  fi; \
  if [ "${USE_TOOLING}" = "true" ] || [ "${USE_KRITA}" = "true" ]; then \
    git clone https://github.com/Acly/comfyui-tooling-nodes.git && \
    cd comfyui-tooling-nodes && git checkout main && cd ..; \
  fi

WORKDIR ${ROOT}
COPY --chown=${USE_UID}:${USE_GID} . /docker/
RUN chmod u+x /docker/entrypoint.sh && cp /docker/extra_model_paths.yaml ${ROOT}

ENV NVIDIA_VISIBLE_DEVICES=all PYTHONPATH="${PYTHONPATH}:${PWD}" CLI_ARGS=""
EXPOSE 7860
ENTRYPOINT ["/docker/entrypoint.sh"]
CMD python3 -u main.py --listen --port 7860 ${CLI_ARGS}
