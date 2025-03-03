# Embedding Model Deployment with TensorRT and Triton

This repository demonstrates how to export a Huggingface embedding model to ONNX, build a TensorRT engine, and deploy it using Triton Inference Server.

## Workflow

1. **Build the Container**  
   Build a Docker container that includes Triton and TensorRT:  
   ```bash
   docker build -t tensorrt_only .
   ```

2. **Start Triton**  
   Enter the container and start Triton using:
   ```bash
   ./start_triton.sh
   ```

3. **Export the Model to ONNX**  
   Inside the container, run `expo.py` which loads the Sentence Transformer model (default: `"sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"`) and exports it to ONNX.

4. **Build the TensorRT Engine**  
   Run `tensorRT.sh` to create a container with a pre-built `trtexec`. Inside this container, `build_trt_exec.sh` is executed with:
   ```bash
   trtexec --onnx=model.onnx --saveEngine=model.plan --fp16 \
     --minShapes=input_ids:1x64,attention_mask:1x64 \
     --optShapes=input_ids:16x64,attention_mask:16x64 \
     --maxShapes=input_ids:64x64,attention_mask:64x64
   ```
   This command creates an engine (`model.plan`) with a batch size of 64.

5. **Prepare the Model Repository**  
   After a successful engine build, move the engine to the Triton model repository:
   ```bash
   mv model.plan model_repo/trt_model/1/model.plan
   ```

6. **Launch Triton Server**  
   With the engine in place, start Triton:
   ```bash
   tritonserver --model-repository=model_repo/
   ```

7. **Test and Benchmark**  
   - Test the deployment with:
     ```bash
     ./curl_test.sh
     ```
   - Benchmark the model using the scripts in the `benchmarks/` directory.  
   Ensure all shell scripts are executable:
   ```bash
   chmod +x *.sh
   ```

## Repository Structure

```
.
├── Dockerfile                # Builds the container with Triton and TensorRT
├── expo.py                   # Exports the Huggingface Sentence Transformer to ONNX
├── tensorRT.sh               # Creates a container to compile the ONNX model
├── build_trt_exec.sh         # Executes trtexec to convert ONNX to TensorRT engine
├── start_triton.sh           # Starts the Triton container and server
├── curl_test.sh              # Script to test the deployed model via CURL
├── model_repo/               # Directory for Triton model repository
│   └── trt_model/
│       └── 1/
│           └── model.plan    # TensorRT engine file (after compilation)
└── benchmarks/               # Benchmarking scripts and configurations
```


