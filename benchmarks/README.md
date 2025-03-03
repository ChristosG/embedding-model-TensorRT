# Benchmarks

This folder contains scripts for generating test payloads and running benchmark tests.

## Generate Test Payloads

Generate 1000 examples with different words by running:

```bash
python3 generate_strings.py 1000
```

This will create a `payloads.jsonl` file, which is used in the benchmark tests.

## Run Benchmarks

After generating the payloads, execute the benchmark tests with:

```bash
./req_test_with_different_queries.sh
```

Ensure all scripts are executable:

```bash
chmod +x *.sh
```
