# Module 02 — Keys, Partitioning & Ordering  (~20 min)

The single most important Kafka design decision: **what is your partition key?**

## The guarantee (and its limit)

> Kafka guarantees ordering **only within a partition** — never across partitions.

A record's partition is chosen from `hash(key) % numPartitions` (null key →
sticky round-robin). So the key *is* your ordering boundary.

## Run it — keyed (correct for trading)

```powershell
# wipe prior data first so the scan is clean (optional)
# docker compose -f ../../docker-compose.yml exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --delete --topic trades

python producer.py            # key = account
python verify.py
```

Each account shows **one** partition → its events are totally ordered.

## Run it — unkeyed (broken ordering)

Recreate the topic (or just append) and send with a null key:

```powershell
python producer.py --no-key
python verify.py
```

Now accounts are **spread across partitions** (`<-- spread!`). A consumer can no
longer reconstruct the order in which that account traded — fatal for position
keeping or margin.

## Interview framing

- **Why key by account, not by symbol?** Ordering must be preserved for the unit
  you reason about transactionally. In prime brokerage that's the account/book.
- **Hot partition risk:** one whale account can overload a single partition. Trade-off
  between ordering and even load — sometimes a composite key (`account|symbol`) helps.
- **Repartitioning hazard:** changing partition count changes `hash(key) % N`, so
  existing keys move partitions and ordering breaks at the boundary. Pick partition
  count carefully up front.

➡ Next: [03-consumer-groups](../03-consumer-groups/README.md) — scaling consumers.
