import torch
from transformers import AutoTokenizer, AutoModel

# Define a wrapper that performs inference and mean pooling.
class SentenceTransformerWrapper(torch.nn.Module):
    def __init__(self, model_name: str):
        super().__init__()
        self.model = AutoModel.from_pretrained(model_name)

    def forward(self, input_ids, attention_mask):
        outputs = self.model(input_ids=input_ids, attention_mask=attention_mask)
        token_embeddings = outputs.last_hidden_state  # shape: (B, T, H)
        # Perform mask-aware mean pooling:
        mask = attention_mask.unsqueeze(-1).expand(token_embeddings.size()).float()
        sum_embeddings = torch.sum(token_embeddings * mask, dim=1)
        sum_mask = torch.clamp(mask.sum(dim=1), min=1e-9)
        sentence_embeddings = sum_embeddings / sum_mask
        return sentence_embeddings

if __name__ == "__main__":
    model_name = "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"
    wrapper = SentenceTransformerWrapper(model_name)
    tokenizer = AutoTokenizer.from_pretrained(model_name)

    # Prepare a dummy input for export.
    dummy_text = "This is a dummy sentence."
    dummy_inputs = tokenizer(dummy_text,
                             padding="max_length",
                             max_length=64,
                             truncation=True,
                             return_tensors="pt")
        # Cast the inputs to int32 so that the exported ONNX model has int32 inputs.
    dummy_inputs["input_ids"] = dummy_inputs["input_ids"].to(torch.int32)
    dummy_inputs["attention_mask"] = dummy_inputs["attention_mask"].to(torch.int32)

    # Export to ONNX using opset version 14.
    torch.onnx.export(
        wrapper,
        (dummy_inputs["input_ids"], dummy_inputs["attention_mask"]),
        "model.onnx",
        input_names=["input_ids", "attention_mask"],
        output_names=["embeddings"],
        dynamic_axes={
            "input_ids": {0: "batch_size", 1: "seq_len"},
            "attention_mask": {0: "batch_size", 1: "seq_len"},
            "embeddings": {0: "batch_size"}
        },
        opset_version=14,
        do_constant_folding=True,
    )

    print("Exported model.onnx successfully.")
