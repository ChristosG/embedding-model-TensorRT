curl -X POST http://localhost:8000/v2/models/ensemble_mpnet/infer \
  -H "Content-Type: application/json" \
  -d '{
    "inputs": [
      {
        "name": "sentences",
        "shape": [1, 1],
        "datatype": "BYTES",
        "data": [["This is a test sentence."]]
      }
    ],
    "outputs": [
      {"name": "embeddings"}
    ]
  }'
