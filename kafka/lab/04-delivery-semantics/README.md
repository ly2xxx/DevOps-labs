# Module 04 — Delivery Semantics  (~25 min)

The question every interviewer asks: *"at-least-once, at-most-once, or exactly-once?"*
This module makes all three concrete.

| Semantic | How you get it | Risk | When to use |
|----------|----------------|------|-------------|
| **At-most-once** | commit offset *before* processing | data **loss** | metrics you can drop |
| **At-least-once** | commit offset *after* processing | **duplicates** | most systems (+ idempotent writes) |
| **Exactly-once (EOS)** | idempotent producer + transactions | none (within Kafka) | money: ledgers, positions, PnL |

## a) Idempotent producer — dedupe on retry

```powershell
python idempotent_producer.py
```

`enable.idempotence=True` stops a network retry from creating a duplicate record.
Always-on baseline. **Note:** this dedupes *producer retries*; it is not the same
as end-to-end exactly-once.

## b) Manual-commit consumer — at-least-once done right

```powershell
python manual_commit_consumer.py
```

Auto-commit can acknowledge a record before you've processed it → silent loss on
crash. Here we **process first, commit second**. Crash before the commit → reprocess
on restart (a duplicate), which is safe *if* downstream writes are idempotent
(upsert by `event_id`).

## c) Exactly-once read-process-write — transactions

```powershell
python transactional_eos.py
# leave it running, produce upstream events in another terminal:
python ..\01-python-pubsub\producer.py --count 100
```

This consumes `trades`, enriches, and produces to `trades.enriched`. The output
records **and** the input offset commit are wrapped in one Kafka transaction, so
they succeed or fail together. Open **kafka-ui** (http://localhost:8080) to see
`trades.enriched` fill up only with committed batches.

The two ingredients of EOS:
1. **Idempotent producer** — no duplicate outputs on retry.
2. **Transactions** + `send_offsets_to_transaction` — outputs and consumed
   offsets commit atomically; readers set `isolation.level=read_committed`.

## Interview framing

- **"Is Kafka exactly-once?"** Yes, *within Kafka*, via idempotence + transactions.
  The moment you write to an external system (DB, S3), you need either that
  system in the transaction (you can't, with Kafka txns) or an **idempotent sink**
  (upsert / dedupe key). So in practice: at-least-once + idempotent writes is the
  workhorse; EOS for Kafka-to-Kafka stream processing.
- **Cost of EOS:** transactions add latency and broker overhead — don't reach for
  them when an idempotent upsert downstream is simpler.

➡ Back to the [lab index](../README.md) · optional [05-java-client](../05-java-client/README.md).
