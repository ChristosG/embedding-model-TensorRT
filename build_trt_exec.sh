trtexec --onnx=model.onnx --saveEngine=model.plan --fp16 \
  --minShapes=input_ids:1x64,attention_mask:1x64 \
  --optShapes=input_ids:16x64,attention_mask:16x64 \
  --maxShapes=input_ids:64x64,attention_mask:64x64
