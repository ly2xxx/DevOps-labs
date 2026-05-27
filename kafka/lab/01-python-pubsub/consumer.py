"""Module 01 - consume trade events from the `trades` topic.

    python consumer.py                       # group "lab-01", from earliest
    python consumer.py --group my-group

Key ideas shown here:
  * A consumer belongs to a consumer group; the group tracks committed offsets.
  * poll() returns one message at a time (or None on timeout).
  * auto.offset.reset=earliest means "if this group has no committed offset,
    start from the beginning" — handy for replaying the whole topic.
Press Ctrl+C to stop; close() triggers a clean group leave + offset commit.
"""
import argparse
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[2]))

from confluent_kafka import Consumer, KafkaError

from common.config import BOOTSTRAP, TOPIC_TRADES
from common.trades import TradeEvent


def main(group: str) -> None:
    consumer = Consumer(
        {
            "bootstrap.servers": BOOTSTRAP,
            "group.id": group,
            "auto.offset.reset": "earliest",
            "enable.auto.commit": True,   # offsets committed periodically in the background
        }
    )
    consumer.subscribe([TOPIC_TRADES])
    print(f"Consuming '{TOPIC_TRADES}' as group '{group}' — Ctrl+C to stop\n")

    count = 0
    try:
        while True:
            msg = consumer.poll(timeout=1.0)
            if msg is None:
                continue
            if msg.error():
                if msg.error().code() == KafkaError._PARTITION_EOF:
                    continue
                print(f"ERROR: {msg.error()}")
                continue
            event = TradeEvent.from_bytes(msg.value())
            count += 1
            print(f"[p{msg.partition()}@{msg.offset()}] {event.summary()}")
    except KeyboardInterrupt:
        print(f"\nStopping. Consumed {count} events.")
    finally:
        consumer.close()


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--group", default="lab-01")
    main(ap.parse_args().group)
