"""Module 04a - idempotent producer (no duplicates on retry).

    python idempotent_producer.py

`enable.idempotence=True` makes the producer tag each record with a producer-id
+ sequence number. If a network blip causes a retry, the broker recognises the
duplicate and drops it — so a transient failure no longer turns one trade into
two. This is the cheap, always-on baseline for any financial producer.

It implies: acks=all, retries>0, max.in.flight<=5. confluent-kafka sets these
for you and will error if you contradict them.
"""
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[2]))

from confluent_kafka import Producer

from common.config import BOOTSTRAP, TOPIC_TRADES
from common.trades import event_stream


def main() -> None:
    producer = Producer(
        {
            "bootstrap.servers": BOOTSTRAP,
            "enable.idempotence": True,   # the one line that matters here
            "client.id": "lab-04-idempotent",
        }
    )
    print("Idempotent producer: acks=all + dedupe on retry (exactly-once *per partition*).")
    for event in event_stream(15):
        producer.produce(TOPIC_TRADES, key=event.key_bytes(), value=event.to_bytes())
        producer.poll(0)
    producer.flush(10)
    print("Sent 15 events; any internal retries were de-duplicated by the broker.")


if __name__ == "__main__":
    main()
