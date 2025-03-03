docker run --rm -it --net host --ulimit memlock=-1 --ulimit stack=67108864  \
                --security-opt=label=disable --security-opt seccomp=unconfined \
                --gpus "device=all"  \
                --ipc=host \
                --name triton_trt \
                --tmpfs /tmp:exec \
 		 -v $(pwd):/workspace nvcr.io/nvidia/tensorrt:24.12-py3 /bin/bash
