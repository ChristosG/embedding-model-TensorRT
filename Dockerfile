FROM nvcr.io/nvidia/tritonserver:24.12-py3

RUN pip install torch
RUN pip install transformers
RUN pip install sentence-transformers onnx

CMD ["/bin/bash"]


