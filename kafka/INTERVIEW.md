# Kafka Interview Prep — JPMorganChase, Prime Finance Services

Talking points mapped to the JD. Pair each section with the matching lab module.

---

## 1. Core concepts (the 60-second whiteboard)

- **Topic** = append-only log, split into **partitions**. Partitions are the unit
  of parallelism *and* of ordering.
- **Offset** = monotonic position within a partition. Per-partition, never global.
- **Producer** picks a partition by `hash(key) % partitions` (null key → sticky
  round-robin). **Key = ordering boundary.** (Module 02)
- **Consumer group** = consumers sharing a `group.id`; each partition is owned by
  exactly one member. Scale ≤ partition count. (Module 03)
- **Replication**: each partition has a **leader** + followers. **ISR** = in-sync
  replicas. `acks=all` + `min.insync.replicas=2` = no data loss if a broker dies.
- **Retention**: records persist by time/size regardless of consumption →
  **replayable**. **Log compaction** keeps only the latest value per key (great for
  "current state" topics like positions).
- **KRaft**: modern Kafka drops ZooKeeper; brokers self-manage metadata via a Raft
  quorum of controllers (this lab runs combined broker+controller on one node).

---

## 2. Rapid-fire Q&A

**Q: How does Kafka guarantee ordering?**
Only within a partition. Same key → same partition → ordered. Across partitions:
no ordering. Design your key around the entity you need ordered (account/book).

**Q: at-least-once vs at-most-once vs exactly-once?**
- *At-most-once*: commit offset before processing → loss on crash.
- *At-least-once*: commit after processing → duplicates on crash (the default
  workhorse; pair with idempotent downstream writes).
- *Exactly-once (EOS)*: idempotent producer + transactions binding outputs and
  consumed offsets atomically; readers use `read_committed`. (Module 04)

**Q: Is "exactly-once" real?**
Yes — *within Kafka* (Kafka-to-Kafka). The instant you write to an external system,
EOS depends on that sink being idempotent (upsert by a dedupe key) or transactional.
In practice: at-least-once + idempotent sink for most things; EOS for stream jobs.

**Q: `acks=0/1/all`?**
`0` = fire-and-forget (fastest, lossy). `1` = leader ack only (loss if leader dies
pre-replication). `all` = ISR ack (durable). Finance → `all` + `min.insync.replicas=2`.

**Q: What is consumer lag and why care?**
`log-end-offset − committed-offset` per partition. It's *the* health/SLA signal:
rising lag = consumers falling behind. Alert on it.

**Q: How do you avoid a rebalance storm / its pause?**
Cooperative-sticky assignor (incremental, doesn't stop the world), **static
membership** (`group.instance.id`) to survive rolling restarts, and tuned
`session.timeout.ms` / `max.poll.interval.ms` so slow processing doesn't eject members.

**Q: How do you add throughput?**
More partitions → more consumer parallelism (up to the partition count). But more
partitions = more open files, longer leader-election, and you can't easily *reduce*
them, and adding them reshuffles key→partition mapping. Size for peak up front.

**Q: Compaction vs deletion retention?**
Deletion: drop old records by age/size. Compaction: keep the latest record per key
forever (tombstone = null value deletes a key). Use compaction for changelog/state
topics; deletion for event streams.

**Q: How do you handle poison messages / processing failures?**
Retry with backoff, then route to a **dead-letter topic** (DLT) and continue, so one
bad record can't block a partition. Keep enough context (headers) to reprocess.

**Q: Schema evolution?**
Don't ship raw JSON in prod. Use Avro/Protobuf + a **Schema Registry** enforcing
backward/forward compatibility so producers and consumers can evolve independently.

---

## 3. Kafka on AWS (the JD's "AWS + cloud-native")

- **Amazon MSK** = managed Kafka (provisioned or **MSK Serverless**). AWS runs the
  brokers, KRaft/ZooKeeper, patching, and multi-AZ replication.
- **Resiliency**: brokers spread across 3 AZs; RF=3, `min.insync.replicas=2` so a
  full-AZ loss keeps you writable.
- **Security**: IAM auth (MSK IAM SASL), TLS in transit, KMS at rest, private subnets
  + security groups. Critical for a bank.
- **Glue Schema Registry** for Avro/Protobuf governance; **MSK Connect** (managed
  Kafka Connect) for source/sink connectors (S3, JDBC, OpenSearch).
- **Scaling/cost**: Serverless autoscales throughput; provisioned lets you tune
  broker type, storage, and tiered storage for cheap long retention.
- **Monitoring**: CloudWatch + Prometheus/JMX → Grafana. Watch under-replicated
  partitions, ISR shrink, consumer lag, request latency, disk.

---

## 4. Ecosystem you should name-drop

| Tool | One-liner | When |
|------|-----------|------|
| **Kafka Connect** | Config-driven source/sink connectors, no code | Ingest DB CDC, sink to S3/warehouse |
| **Kafka Streams** | JVM library for stateful stream processing (joins, windows, aggregations) | In-app transforms, EOS built in |
| **ksqlDB / Flink** | SQL / heavy stream processing | Complex analytics over streams |
| **Schema Registry** | Centralised Avro/Protobuf + compatibility rules | Any multi-team prod topic |
| **Spark Structured Streaming** | Batch+stream unification (JD lists Spark) | Large-scale pipelines, ML features |

**Kafka Streams vs a plain consumer:** reach for Streams when you need *stateful*
operations (windowed aggregations, stream-stream/stream-table joins, local state
stores with changelog topics) and want EOS without hand-rolling transactions. A
plain consumer is fine for stateless consume-and-write.

---

## 5. System-design scenario — Prime Brokerage real-time risk

> *"Design a service that ingests trade executions and keeps near-real-time margin /
> position per account, alerting risk when an account breaches limits."*

**Topics**
- `trades` — raw executions, **keyed by account** (ordering per account), RF=3,
  partitioned for peak throughput (e.g. 24).
- `positions` — **compacted** changelog of current position per `account|symbol`
  (latest state, replayable to rebuild).
- `margin.alerts` — breaches for the risk desk.
- `trades.dlt` — dead-letter for unparseable/failed records.

**Pipeline**
1. Gateways produce to `trades` with `acks=all`, idempotent producer.
2. A **Kafka Streams** (or consumer-group) app keyed by account:
   - maintains a local **state store** of positions + margin,
   - on each trade, updates position, recomputes margin,
   - emits to `positions` (compacted) and, on breach, to `margin.alerts`.
   - EOS so a restart doesn't double-count.
3. **Connect S3 sink** archives `trades` for audit/replay (regulatory).
4. Risk UI/alerting consumes `margin.alerts`.

**Why these choices**
- *Key = account* → per-account ordering, correct running position. Hot-account
  risk → consider `account|symbol` composite or sub-partitioning.
- *Compaction on `positions`* → cheap "current state" + full rebuild by replay.
- *EOS* → margin numbers can't double-count; this is money.
- *RF=3 / min ISR=2 / 3 AZs* → survive a broker/AZ loss without loss or downtime.
- *DLT* → one malformed message never stalls a partition (no head-of-line block).
- *Replayability* → reprocess history after a bug fix by resetting consumer offsets.

**Scaling & ops**
- Partition count caps consumer parallelism — size for peak market-open volume.
- Alert on **consumer lag**, under-replicated partitions, ISR shrink.
- Backpressure: if a downstream (DB) slows, lag grows but nothing is lost; scale
  consumers up to partition count, then scale partitions (carefully).

**Trade-offs to volunteer**
- More partitions = parallelism *but* more metadata/open files and slower failover.
- EOS adds latency vs at-least-once + idempotent upsert — justify per use case.
- Tight `session.timeout` detects failures fast but risks false-positive rebalances.

---

## 6. Performance / resiliency tuning checklist (JD: "performance tuning, resiliency")

**Producer**: `acks=all`, `enable.idempotence=true`, `linger.ms` + `batch.size` for
throughput, `compression.type=lz4/zstd`, bounded `delivery.timeout.ms`.
**Consumer**: right-size `max.poll.records` vs `max.poll.interval.ms`, manual commit
for at-least-once, cooperative-sticky assignor, static membership.
**Broker/topic**: RF=3, `min.insync.replicas=2`, partition count for peak, retention
+ compaction per topic's purpose, rack/AZ awareness.
**Operate**: monitor lag, URP, ISR, request latency, disk; DLT for poison messages;
replay via offset reset; capacity-test at market-open peaks.

---

## 7. Map back to the lab

| JD phrase | Prove it with |
|-----------|---------------|
| "real-time streaming & messaging with Kafka" | Modules 01–04 + this doc |
| "Java and Python" | Module 01–04 (Py) + Module 05 (Java), interoperable |
| "distributed applications… resiliency" | RF/ISR/acks discussion, §5–6 |
| "AWS, cloud-native" | §3 MSK |
| "performance tuning" | §6 checklist, partition/ordering trade-offs |
| "monitoring, alerting, incident learnings" | consumer lag, URP, DLT, replay |
| "Spark data pipelines" (preferred) | §4 Spark Structured Streaming |
| "Docker / Kubernetes" (preferred) | this lab is Docker; MSK/Strimzi on K8s |
