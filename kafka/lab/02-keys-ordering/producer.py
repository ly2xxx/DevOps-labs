"""Module 02 - demonstrate how the record KEY controls partitioning.

    python producer.py             # key = account  (ordered per account)
    python producer.py --no-key    # key = None     (round-robin, order lost)

Kafka's only ordering guarantee is *within a single partition*. The producer
chooses a partition from the key hash, so:

    same key  -> same partition -> messages stay in send order
    null key  -> sticky/round-robin spread -> no cross-partition order

For prime brokerage that means: key by `account` and every order, fill and
margin event for that account is processed in the exact order it happened.
"""
import argparse
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[2]))

from confluent_kafka import Producer

from common.config import BOOTSTRAP, TOPIC_TRADES
from common.trades import ACCOUNTS, random_event


def main(per_account: int, use_key: bool) -> None:
    producer = Producer({"bootstrap.servers": BOOTSTRAP, "acks": "all"})
    mode = "KEYED by account" if use_key else "NULL key (round-robin)"
    print(f"Producing {per_account} events x {len(ACCOUNTS)} accounts — {mode}\n")

    for account in ACCOUNTS:
        for _ in range(per_account):
            event = random_event(account)
            producer.produce(
                topic=TOPIC_TRADES,
                key=event.key_bytes() if use_key else None,
                value=event.to_bytes(),
            )
        producer.poll(0)

    producer.flush(10)
    print("Done. Now run:  python verify.py")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--per-account", type=int, default=5)
    ap.add_argument("--no-key", action="store_true", help="send with a null key")
    args = ap.parse_args()
    main(args.per_account, use_key=not args.no_key)
