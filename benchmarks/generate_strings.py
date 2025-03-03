#!/usr/bin/env python3
import sys
import json
import random
from faker import Faker
from transformers import AutoTokenizer

def main(num_requests):
    fake = Faker()
    tokenizer = AutoTokenizer.from_pretrained("sentence-transformers/paraphrase-multilingual-mpnet-base-v2")
    
    sentences = []
    for _ in range(num_requests):
        text = fake.paragraph(nb_sentences=random.randint(1, 5))
        
        tokens = tokenizer.encode(text, add_special_tokens=False, max_length=128, truncation=True)
        truncated = tokenizer.decode(tokens, skip_special_tokens=True)
        sentences.append(truncated)
    
    with open("payloads.jsonl", "w") as f:
        for sentence in sentences:
            payload = {
                "inputs": [
                    {
                        "name": "sentences",
                        "shape": [1, 1],
                        "datatype": "BYTES",
                        "data": [[sentence]]
                    }
                ],
                "outputs": [{"name": "embeddings"}]
            }
            f.write(json.dumps(payload) + "\n")

if __name__ == "__main__":
    num_requests = int(sys.argv[1]) if len(sys.argv) > 1 else 1000
    main(num_requests)
