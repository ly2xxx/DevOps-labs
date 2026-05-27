"""Module 04c - exactly-once read-process-write with a Kafka transaction.

    python transactional_eos.py

The classic streaming pattern: consume from `trades`, enrich each event, and
produce to `trades.enriched`. The hard part is making "I consumed it" and
"I produced the result" atomic — otherwise a crash double-counts or drops.

A Kafka transaction binds the *output records* AND the *input offset commit*
into one atomic unit:

    begin_transaction()
        produce(enriched...)
        send_offsets_to_transaction(consumer offsets, group metadata)
    commit_transaction()        # outputs + offsets commit together, or neither

Downstream readers using isolation.level=read_committed never see records from
an aborted transaction. That is end-to-end exactly-once (EOS).

Run a reader in another terminal to watch only committed output appear:
    python ..\01-python-pubsub\consumer.py --group eos-reader
  (then point it at trades.enriched — or use kafka-ui at http://localhost:8080)
"""
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[2]))

from confluent_kafka import Consumer, Producer, TopicPartition

from common.config import BOOTSTRAP, TOPIC_ENRICHED, TOPIC_TRADES
from common.trades import TradeEvent


def enrich(event: TradeEvent) -> bytes:
    # Add a derived field a risk/PnL consumer would want.
    import json

    record = {
        "event_id": event.event_id,
        "account": event.account,
        "symbol": event.symbol,
        "side": event.side,
        "notional": event.notional(),
        "direction": 1 if event.side == "BUY" else -1,
    }
    return json.dumps(record).encode("utf-8")


def main() -> None:
    consumer = Consumer(
        {
            "bootstrap.servers": BOOTSTRAP,
            "group.id": "lab-04-eos",
            "auto.offset.reset": "earliest",
            "enable.auto.commit": False,          # offsets are committed via the txn
            "isolation.level": "read_committed",  # ignore aborted upstream txns
        }
    )
    producer = Producer(
        {
            "bootstrap.servers": BOOTSTRAP,
            "transactional.id": "lab-04-eos-tx",  # required; identifies this producer across restarts
        }
    )
    producer.init_transactions()
    consumer.subscribe([TOPIC_TRADES])
    print(f"EOS pipeline: {TOPIC_TRADES} -> enrich -> {TOPIC_ENRICHED}. Ctrl+C to stop.\n")

    try:
        while True:
            msgs = consumer.consume(num_messages=50, timeout=1.0)
            msgs = [m for m in msgs if m is not None and not m.error()]
            if not msgs:
                continue

            producer.begin_transaction()
            for m in msgs:
                event = TradeEvent.from_bytes(m.value())
                producer.produce(TOPIC_ENRICHED, key=m.key(), value=enrich(event))

            # Commit the *input* offsets as part of THIS transaction.
            positions = [
                TopicPartition(m.topic(), m.partition(), m.offset() + 1) for m in msgs
            ]
            producer.send_offsets_to_transaction(
                positions, consumer.consumer_group_metadata()
            )
            producer.commit_transaction()
            print(f"  committed batch of {len(msgs)} (outputs + offsets, atomically)")
    except KeyboardInterrupt:
        print("\nStopping; aborting any open transaction.")
        try:
            producer.abort_transaction()
        except Exception:
            pass
    finally:
        consumer.close()


if __name__ == "__main__":
    main()
