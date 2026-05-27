# Module 00 — Kafka Primer  (~15 min)

No Python yet — just the mental model and the broker's own CLI tools (run inside
the container, so nothing to install).

## The mental model

```
 producers                      KAFKA TOPIC "trades"                    consumer group
                          ┌───────────────────────────────┐
   app ──┐               │ partition 0:  [0][1][2][3]...    │──┐
   app ──┼── append ───▶ │ partition 1:  [0][1][2]...       │  ├─▶ consumer A (p0,p1)
   app ──┘               │ partition 2:  [0][1][2][3][4]... │──┘    consumer B (p2)
                          └───────────────────────────────┘
```

- **Broker** — a Kafka server. A **cluster** is several brokers (we run one).
- **Topic** — a named, append-only log of records. Split into **partitions**.
- **Partition** — the ordered, immutable sequence. Ordering exists *here only*.
- **Offset** — a record's position in its partition (0,1,2,…). Per-partition.
- **Record** — `key`, `value`, `timestamp`, `headers`.
- **Producer** — appends records; the key picks the partition.
- **Consumer group** — shares the work of a topic; each partition → one member.
- **Retention** — Kafka keeps records by time/size (default), *not* until read.
  Consumers can replay history. (Or **log compaction**: keep latest per key.)
- **Replication** — each partition has a **leader** + follower replicas; **ISR**
  = in-sync replicas. `acks=all` waits for the ISR → no data loss on leader fail.

## Hands-on with the broker CLI

Bring the cluster up from the lab root first:

```powershell
cd ..\..            # kafka/
docker compose up -d
docker compose ps   # wait for kafka = healthy
```

All commands below shell into the broker. `K` is just shorthand for the path:

```powershell
# Create a topic with 3 partitions
docker compose exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --create --topic trades --partitions 3

# Describe it — see partitions, leader, replicas, ISR
docker compose exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --describe --topic trades

# List all topics
docker compose exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --list
```

Produce and consume from the console (great for quick debugging):

```powershell
# Producer — type messages, Enter to send, Ctrl+C to quit
docker compose exec -it kafka /opt/kafka/bin/kafka-console-producer.sh --bootstrap-server localhost:9092 --topic trades

# Consumer — in another terminal, read from the beginning
docker compose exec kafka /opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic trades --from-beginning
```

Inspect consumer groups + **lag** (the key operational metric):

```powershell
docker compose exec kafka /opt/kafka/bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --list
docker compose exec kafka /opt/kafka/bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group lab-01
```

`LAG = LOG-END-OFFSET − CURRENT-OFFSET` — how far a group is behind real time.

## Visual UI

Open **http://localhost:8080** (kafka-ui) to browse topics, partitions, messages,
and consumer-group lag without the CLI.

➡ Next: [01-python-pubsub](../01-python-pubsub/README.md).
