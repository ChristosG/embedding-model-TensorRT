#!/bin/bash

URL="http://localhost:8000/v2/models/ensemble_mpnet/infer"
NUM_REQUESTS=1000
CONCURRENCY=64

if [ ! -f "payloads.jsonl" ]; then
    echo "Error: payloads.jsonl not found. Generate it first with generate_sentences.py"
    exit 1
fi

TEMP_DIR=$(mktemp -d)
RESPONSE_FILE="$TEMP_DIR/responses.txt"
TIMING_FILE="$TEMP_DIR/timings.txt"

echo "Starting stress test with $NUM_REQUESTS requests ($CONCURRENCY concurrent)..."
echo "Target URL: $URL"

# Run stress test with proper payload handling
start_time=$(date +%s.%N)
seq $NUM_REQUESTS | xargs -P $CONCURRENCY -n 1 -I {} bash -c \
    "line=\$(sed -n '{}p' payloads.jsonl) && \
    curl -s -o /dev/null -w '%{http_code}\n%{time_total}\n' \
    -X POST '$URL' \
    -H 'Content-Type: application/json' \
    --data-binary \"\$line\"" >> "$RESPONSE_FILE"
end_time=$(date +%s.%N)

# Calculate metrics
total_time=$(echo "$end_time - $start_time" | bc)
rps=$(echo "scale=2; $NUM_REQUESTS / $total_time" | bc)

# Process results
success_count=$(grep -c '^200$' "$RESPONSE_FILE")
error_count=$((NUM_REQUESTS - success_count))

# Extract response times
grep -E '^[0-9]+\.[0-9]+$' "$RESPONSE_FILE" > "$TIMING_FILE"
sort -n "$TIMING_FILE" > "$TIMING_FILE.sorted"
avg_time=$(awk '{sum += $1} END {print sum/NR}' "$TIMING_FILE")
p95=$(awk 'BEGIN {n=int(0.95*NR)} NR>=n' "$TIMING_FILE.sorted" | head -1)

# Cleanup temporary files
rm -rf "$TEMP_DIR"

# Display results
echo -e "\nStress Test Results:"
echo "===================="
printf "Total time:         %.2f seconds\n" "$total_time"
printf "Requests/sec:       %.2f\n" "$rps"
echo "Successful requests: $success_count"
echo "Failed requests:     $error_count"
printf "Average response:   %.3fs\n" "$avg_time"
printf "95th percentile:    %.3fs\n" "$p95"
echo ""

# Check for errors
if [ $error_count -gt 0 ]; then
    echo "WARNING: Some requests failed. Consider checking:"
    echo "- Triton server logs"
    echo "- Model configuration"
    echo "- System resource usage (CPU/GPU/Memory)"
fi
