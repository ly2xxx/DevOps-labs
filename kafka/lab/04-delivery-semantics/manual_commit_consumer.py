"""Module 04b - at-least-once consumer with MANUAL offset commits.

    python manual_commit_consumer.py

Default auto-commit can commit an offset *before* you finish processing — if you
crash in between, that record is silently skipped (at-most-once, data loss).

The safe pattern for money: disable auto-commit and commit only AFTER the work
is durably done. If you crash before the commit, you reprocess the record on
restart (at-least-once). Duplicates are possible, so downstream handling must be
idempotent (e.g. upsert by event_id).
"""
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[2]))

from confluent_kafka import Consumer

from common.config import BOOTSTRAP, TOPIC_TRADES
from common.trades import TradeEvent


def process(event: TradeEvent) -> None:
    # Pretend this writes to a ledger / risk system. Must be idempotent.
    print(f"  processed {event.event_id[:8]}  {event.summary()}")


def main() -> None:
    consumer = Consumer(
        {
            "bootstrap.servers": BOOTSTRAP,
            "group.id": "lab-04-manual",
            "auto.offset.reset": "earliest",
            "enable.auto.commit": False,   # WE decide when an offset is safe
        }
    )
    consumer.subscribe([TOPIC_TRADES])
    print("Manual-commit consumer (at-least-once). Ctrl+C to stop.\n")

    try:
        while True:
            msg = consumer.poll(1.0)
            if msg is None or msg.error():
                continue
            event = TradeEvent.from_bytes(msg.value())
            process(event)                 # 1. do the work first
            consumer.commit(msg, asynchronous=False)  # 2. THEN record progress
    except KeyboardInterrupt:
        print("\nStopped.")
    finally:
        consumer.close()


if __name__ == "__main__":
    main()
