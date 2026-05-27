# Kafka Lab — Real-Time Streaming for Prime Finance

Hands-on Apache Kafka, built as interview prep for the **JPMorganChase — Lead
Software Engineer, Prime Finance Services** role. Every module uses a prime-brokerage
domain (trade events keyed by account) and is runnable on a laptop in minutes.

> The JD calls out *"Build and enhance real-time streaming and messaging solutions
> with Kafka"* plus **Java + Python**, **AWS**, and **distributed systems**. This lab
> hits all of those, and [INTERVIEW.md](INTERVIEW.md) drills the talking points.

## What you'll be able to discuss

- Brokers, topics, partitions, offsets, consumer groups, replication/ISR
- Partition keys and the per-partition **ordering guarantee** (and its limits)
- Consumer-group **scaling, rebalancing, and lag**
- **Delivery semantics**: at-most/at-least/exactly-once, idempotent + transactional producers
- The same pipeline in **Python and Java** (interoperable)
- Running Kafka on **AWS (MSK)** and a **Prime Finance system-design** scenario

## Prerequisites

| Tool | Why | Check |
|------|-----|-------|
| Docker + Compose | run the broker | `docker compose version` |
| Python 3.9+ | modules 01–04 | `python --version` |
| `confluent-kafka` | Python client | `pip install -r requirements.txt` |
| Maven *(optional)* | module 05 (Java) | `mvn -version` |

## Quickstart

```powershell
# 1. start a single-node Kafka (KRaft, no ZooKeeper) + web UI
docker compose up -d
docker compose ps                 # wait until kafka is "healthy"

# 2. install the Python client
pip install -r requirements.txt

# 3. first round trip (two terminals, in lab/01-python-pubsub)
python consumer.py                # terminal A
python producer.py --count 20     # terminal B

# 4. browse it visually
#    http://localhost:8080  (kafka-ui)

# when done
docker compose down               # keep data;  add -v to wipe topics
```

If a client can't connect, confirm the broker is healthy and that you're using
`localhost:9092` (override with `$env:KAFKA_BOOTSTRAP`).

## Modules

| # | Folder | Focus | Time |
|---|--------|-------|------|
| 00 | [`lab/00-primer`](lab/00-primer/README.md) | Concepts + broker CLI (topics, console produce/consume, lag) | 15 min |
| 01 | [`lab/01-python-pubsub`](lab/01-python-pubsub/README.md) | Producer → topic → consumer; offsets; pub/sub fan-out | 15 min |
| 02 | [`lab/02-keys-ordering`](lab/02-keys-ordering/README.md) | Partition keys & the ordering guarantee | 20 min |
| 03 | [`lab/03-consumer-groups`](lab/03-consumer-groups/README.md) | Scaling, rebalancing, failover, lag | 20 min |
| 04 | [`lab/04-delivery-semantics`](lab/04-delivery-semantics/README.md) | Idempotent + transactional producers, EOS | 25 min |
| 05 | [`lab/05-java-client`](lab/05-java-client/README.md) | Same pipeline in Java (optional) | 15 min |

Work them in order; each README ends with a link to the next.

## Architecture (what `docker compose up` gives you)

```
  your laptop                          docker network
 ┌───────────────┐   localhost:9092   ┌───────────────────────────┐
 │ python / java │ ─────────────────▶ │  kafka  (KRaft: broker +   │
 │   clients     │                    │         controller, 1 node)│
 └───────────────┘                    │   topic: trades (3 parts)  │
 ┌───────────────┐   localhost:8080   │   topic: trades.enriched   │
 │   browser     │ ─────────────────▶ │  kafka-ui  ── kafka:19092 ─┘
 └───────────────┘                    └───────────────────────────┘
```

Single node = fine for learning. Replication factor is 1 here; in production
you'd run ≥3 brokers with RF=3 and `min.insync.replicas=2` (see INTERVIEW.md).

## Files

```
kafka/
├── docker-compose.yml          # KRaft Kafka + kafka-ui
├── requirements.txt            # confluent-kafka
├── common/                     # shared trade-event domain + config
├── lab/00-primer .. 05-java-client
├── README.md                   # you are here
└── INTERVIEW.md                # concepts, Q&A, Prime Finance design scenario
```

## Next

➡ Start with [Module 00 — Primer](lab/00-primer/README.md), then keep
[INTERVIEW.md](INTERVIEW.md) open as you go.
