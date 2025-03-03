#!/bin/bash

URL="http://localhost:8000/v2/models/ensemble_mpnet/infer"
NUM_REQUESTS=1000
CONCURRENCY=50
REQUEST_DATA=$(cat <<EOF
{
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
}
EOF
)

TEMP_DIR=$(mktemp -d)
RESPONSE_FILE="$TEMP_DIR/responses.txt"
TIMING_FILE="$TEMP_DIR/timings.txt"

echo "Starting stress test with $NUM_REQUESTS requests ($CONCURRENCY concurrent)..."
echo "Target URL: $URL"
echo ""

# Run stress test
start_time=$(date +%s.%N)
seq $NUM_REQUESTS | xargs -P $CONCURRENCY -n 1 -I {} curl -s -o /dev/null -w "%{http_code}\n%{time_total}\n" \
  -X POST $URL \
  -H "Content-Type: application/json" \
  -d "$REQUEST_DATA" >> $RESPONSE_FILE
end_time=$(date +%s.%N)

# Calculate metrics
total_time=$(echo "$end_time - $start_time" | bc)
rps=$(echo "scale=2; $NUM_REQUESTS / $total_time" | bc)

# Process results
success_count=$(grep -c '^200$' $RESPONSE_FILE)
error_count=$((NUM_REQUESTS - success_count))

# Extract response times
grep -E '^[0-9]+\.[0-9]+$' $RESPONSE_FILE > $TIMING_FILE
sort -n $TIMING_FILE > $TIMING_FILE.sorted
avg_time=$(awk '{sum += $1} END {print sum/NR}' $TIMING_FILE)
p95=$(tail -n 1 $TIMING_FILE.sorted | awk 'BEGIN {n=int(0.95*NR)} NR>=n')

# Cleanup temporary files
rm -rf $TEMP_DIR

# Display results
echo "Stress Test Results:"
echo "===================="
echo "Total time:         $(printf "%.2f" $total_time) seconds"
echo "Requests/sec:      $rps"
echo "Successful requests: $success_count"
echo "Failed requests:     $error_count"
echo "Average response:   $(printf "%.3f" $avg_time)s"
echo "95th percentile:    $(printf "%.3f" $p95)s"
echo ""

# Check for errors
if [ $error_count -gt 0 ]; then
  echo "WARNING: Some requests failed. Consider checking:"
  echo "- Triton server logs"
  echo "- Model configuration"
  echo "- System resource usage (CPU/GPU/Memory)"
fi
