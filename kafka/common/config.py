"""Shared client config. Override the broker without editing code:

    PowerShell:  $env:KAFKA_BOOTSTRAP = "localhost:9092"
    bash:        export KAFKA_BOOTSTRAP=localhost:9092
"""
import os

BOOTSTRAP = os.environ.get("KAFKA_BOOTSTRAP", "localhost:9092")

# Topic names used across the lab.
TOPIC_TRADES = "trades"
TOPIC_ENRICHED = "trades.enriched"
