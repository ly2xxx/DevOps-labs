"""Module 02 - read the whole topic and show which partitions each account used.

    python verify.py

Reads every record currently in `trades` (a bounded drain, not a live tail),
then prints, per account, the set of partitions its events landed on.

  * After `producer.py`        -> each account uses exactly ONE partition.
  * After `producer.py --no-key` -> accounts are smeared across partitions,
    so their global order is no longer recoverable.
"""
import pathlib
import sys
from collections import defaultdict

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[2]))

from confluent_kafka import Consumer

from common.config import BOOTSTRAP, TOPIC_TRADES
from common.trades import TradeEvent


def main() -> None:
    consumer = Consumer(
        {
            "bootstrap.servers": BOOTSTRAP,
            "group.id": "lab-02-verify",
            "auto.offset.reset": "earliest",
            "enable.auto.commit": False,
        }
    )
    consumer.subscribe([TOPIC_TRADES])

    partitions_by_account: dict[str, set[int]] = defaultdict(set)
    total = 0
    idle = 0
    # Drain until the topic goes quiet for ~2s.
    while idle < 4:
        msg = consumer.poll(0.5)
        if msg is None:
            idle += 1
            continue
        if msg.error():
            continue
        idle = 0
        total += 1
        event = TradeEvent.from_bytes(msg.value())
        partitions_by_account[event.account].add(msg.partition())
    consumer.close()

    print(f"\nScanned {total} events.\n")
    print(f"{'account':<14} partitions used")
    print("-" * 32)
    for account in sorted(partitions_by_account):
        parts = sorted(partitions_by_account[account])
        flag = "  <-- spread!" if len(parts) > 1 else ""
        print(f"{account:<14} {parts}{flag}")
    print(
        "\nOne partition per account => per-account ordering is guaranteed.\n"
        "Multiple partitions per account => order across them is NOT guaranteed."
    )


if __name__ == "__main__":
    main()
