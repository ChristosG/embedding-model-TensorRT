docker run --rm -it --net host --ulimit memlock=-1 --ulimit stack=67108864 \
    --security-opt=label=disable --security-opt seccomp=unconfined \
    --tmpfs /tmp:exec --user root \
    --gpus "device=all" \
    --ipc=host \
    -p5991:5991 -p5992:5992 -p5993:5993 \
    --name triton_embeddings \
    -v ./:/teback \
    tensorrt_only   /bin/bash
