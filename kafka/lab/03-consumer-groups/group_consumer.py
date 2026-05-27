"""Module 03 - a consumer that prints partition assignment as the group rebalances.

    python group_consumer.py                 # member of group "lab-03"
    python group_consumer.py --name c2       # run more copies in other terminals

Start one, then start a second and third while a producer streams events. Watch
the on_assign / on_revoke callbacks fire: the group automatically redistributes
the topic's partitions across live members. Kill one and its partitions move to
the survivors. That is consumer-group scaling + fault tolerance in action.

Rule: a partition is owned by AT MOST one consumer in a group, so a group can
scale to at most `partition count` active consumers (extras sit idle).
"""
import argparse
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[2]))

from confluent_kafka import Consumer, KafkaError

from common.config import BOOTSTRAP, TOPIC_TRADES
from common.trades import TradeEvent


def main(name: str, group: str) -> None:
    def on_assign(_consumer, partitions):
        parts = sorted(p.partition for p in partitions)
        print(f"\n>>> [{name}] ASSIGNED partitions {parts}\n")

    def on_revoke(_consumer, partitions):
        parts = sorted(p.partition for p in partitions)
        print(f"\n<<< [{name}] REVOKED  partitions {parts}\n")

    consumer = Consumer(
        {
            "bootstrap.servers": BOOTSTRAP,
            "group.id": group,
            "auto.offset.reset": "earliest",
            # Lower so a dead consumer is detected quickly in the demo.
            "session.timeout.ms": 10000,
        }
    )
    consumer.subscribe([TOPIC_TRADES], on_assign=on_assign, on_revoke=on_revoke)
    print(f"[{name}] joined group '{group}'. Ctrl+C to leave.")

    try:
        while True:
            msg = consumer.poll(1.0)
            if msg is None or msg.error():
                continue
            event = TradeEvent.from_bytes(msg.value())
            print(f"[{name}] p{msg.partition()}@{msg.offset()}  {event.account} {event.side} {event.symbol}")
    except KeyboardInterrupt:
        print(f"\n[{name}] leaving group.")
    finally:
        consumer.close()


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--name", default="c1")
    ap.add_argument("--group", default="lab-03")
    args = ap.parse_args()
    main(args.name, args.group)
