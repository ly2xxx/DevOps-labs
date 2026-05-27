"""Module 01 - produce trade events to the `trades` topic.

    python producer.py            # send 10 events
    python producer.py --count 50

Key ideas shown here:
  * The producer batches in the background; produce() is non-blocking.
  * Delivery is confirmed asynchronously via a callback (acks).
  * flush() blocks until every outstanding message is acknowledged or fails.
"""
import argparse
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[2]))

from confluent_kafka import Producer

from common.config import BOOTSTRAP, TOPIC_TRADES
from common.trades import event_stream


def on_delivery(err, msg):
    """Called once per message from poll()/flush() — this is your ack."""
    if err is not None:
        print(f"DELIVERY FAILED: {err}")
        return
    print(
        f"  ack  topic={msg.topic()} partition={msg.partition()} "
        f"offset={msg.offset()} key={msg.key().decode()}"
    )


def main(count: int) -> None:
    producer = Producer(
        {
            "bootstrap.servers": BOOTSTRAP,
            "acks": "all",            # wait for all in-sync replicas (durability)
            "linger.ms": 5,           # tiny wait to batch records together
            "client.id": "lab-01-producer",
        }
    )

    print(f"Producing {count} events to '{TOPIC_TRADES}' via {BOOTSTRAP}\n")
    for event in event_stream(count):
        producer.produce(
            topic=TOPIC_TRADES,
            key=event.key_bytes(),
            value=event.to_bytes(),
            on_delivery=on_delivery,
        )
        # poll(0) services delivery callbacks without blocking the produce loop.
        producer.poll(0)

    remaining = producer.flush(timeout=10)
    if remaining:
        print(f"\nWARNING: {remaining} messages were not delivered")
    else:
        print(f"\nAll {count} events delivered.")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--count", type=int, default=10)
    main(ap.parse_args().count)
