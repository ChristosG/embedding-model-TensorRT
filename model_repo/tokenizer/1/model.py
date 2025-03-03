import numpy as np
from transformers import AutoTokenizer
import triton_python_backend_utils as pb_utils

class TritonPythonModel:
    def initialize(self, args):
        model_name = "sentence-transformers/paraphrase-multilingual-mpnet-base-v2"
        self.tokenizer = AutoTokenizer.from_pretrained(model_name)

    def execute(self, requests):
        responses = []
        for request in requests:
            input_tensor = pb_utils.get_input_tensor_by_name(request, "sentences")
            raw_data = input_tensor.as_numpy().tolist()

            flattened = []
            for item in raw_data:
                if isinstance(item, list):
                    flattened.extend(item)
                else:
                    flattened.append(item)
            
            sentences = [s if isinstance(s, str) else s.decode("utf-8") for s in flattened]

            tokenized = self.tokenizer(
                sentences,
                padding="max_length",
                max_length=64,
                truncation=True,
                return_tensors="np"
            )
            
            input_ids = tokenized["input_ids"].astype(np.int32)
            attention_mask = tokenized["attention_mask"].astype(np.int32)
            
            out_input_ids = pb_utils.Tensor("input_ids", input_ids)
            out_attention_mask = pb_utils.Tensor("attention_mask", attention_mask)
            
            responses.append(pb_utils.InferenceResponse(output_tensors=[out_input_ids, out_attention_mask]))
        
        return responses

    def finalize(self):
        pass
