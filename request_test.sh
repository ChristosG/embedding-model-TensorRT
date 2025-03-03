#!/bin/bash

# ------------------------------
# Configuration
# ------------------------------
CONCURRENCY=64
TOTAL_REQUESTS=10000
URL="http://localhost:8000/v2/models/ensemble_mpnet/infer"

PAYLOAD='{
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

# Temporary file to store individual request metrics
TMPFILE=$(mktemp)

# ------------------------------
# Function to send one request and log its metrics
# ------------------------------
run_request() {
  local req_num=$1
  start=$(date +%s.%N)
  # Send the request; capture response (ignore the body) and HTTP code.
  response=$(curl -s -w " HTTP_CODE:%{http_code}" -X POST "$URL" \
    -H "Content-Type: application/json" -d "$PAYLOAD")
  end=$(date +%s.%N)
  elapsed=$(echo "$end - $start" | bc)

  http_code=$(echo "$response" | grep -o "HTTP_CODE:[0-9]\+" | cut -d':' -f2)
  echo "$req_num $http_code $elapsed" >> "$TMPFILE"
}

# ------------------------------
# Main loop: dispatch requests concurrently
# ------------------------------
echo "Starting stress test: $TOTAL_REQUESTS requests, concurrency: $CONCURRENCY"
global_start=$(date +%s.%N)
counter=0

for (( i=1; i<=TOTAL_REQUESTS; i++ )); do
  run_request "$i" &
  ((counter++))

  if (( counter % CONCURRENCY == 0 )); then
    wait
    echo "Sent $i requests so far..."
  fi
done

# Wait for any remaining background jobs
wait
global_end=$(date +%s.%N)
total_time=$(echo "$global_end - $global_start" | bc)

# ------------------------------
# Aggregate metrics
# ------------------------------
# Total number of requests is TOTAL_REQUESTS.
# Count successes (HTTP code 200) and failures (others).
success_count=$(awk '$2 == 200 { count++ } END { print count+0 }' "$TMPFILE")
failure_count=$(awk '$2 != 200 { count++ } END { print count+0 }' "$TMPFILE")
# Compute average response time.
avg_time=$(awk '{ total += $3 } END { if (NR > 0) print total/NR; else print 0 }' "$TMPFILE")

echo "---------------------------------------"
echo "Stress Test Completed:"
echo "Total requests:      $TOTAL_REQUESTS"
echo "Successful requests: $success_count"
echo "Failed requests:     $failure_count"
echo "Total time (sec):    $total_time"
echo "Average response time (sec): $avg_time"
echo "---------------------------------------"

rm "$TMPFILE"
