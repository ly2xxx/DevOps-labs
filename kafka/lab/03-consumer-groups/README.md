# Module 03 — Consumer Groups, Scaling & Rebalancing  (~20 min)

How Kafka turns one topic into a horizontally scalable, fault-tolerant work queue.

## The model

- A **consumer group** is a set of consumers sharing one `group.id`.
- Kafka assigns each partition to **exactly one** member of the group.
- Add members → partitions redistribute (**rebalance**) → throughput scales.
- A member dies → its partitions move to survivors → no message lost.
- **Ceiling:** active consumers ≤ partition count. Extra consumers idle.

## Run it

The `trades` topic has 3 partitions. Open three terminals here
(`kafka/lab/03-consumer-groups`):

```powershell
# Terminal 1
python group_consumer.py --name c1

# Terminal 2 (start a few seconds later — watch c1 get REVOKED then re-ASSIGNED)
python group_consumer.py --name c2

# Terminal 3 — keep events flowing
python ..\01-python-pubsub\producer.py --count 200
```

Now experiment:

1. Start a **third** consumer → 3 consumers, 3 partitions, one each.
2. Start a **fourth** → it sits idle (no free partition).
3. **Ctrl+C** one consumer → watch its partitions reassign within ~10s
   (`session.timeout.ms`).

## What to notice

| Observation | Concept |
|-------------|---------|
| `ASSIGNED` / `REVOKED` callbacks fire on join/leave | Group coordinator drives **rebalancing** |
| Each partition appears under exactly one consumer | Partition = unit of parallelism |
| 4th consumer gets nothing | Parallelism capped by partition count |
| Killed consumer's partitions reappear elsewhere | Automatic failover |

## Interview framing

- **Rebalance pain:** during a stop-the-world rebalance, consumption pauses.
  Mitigations: **cooperative-sticky** assignor (incremental rebalances),
  `static membership` (`group.instance.id`) to survive restarts without churn.
- **Sizing partitions:** pick partition count for *peak* required consumer
  parallelism — you can add partitions later but not reduce, and adding them
  breaks key→partition stability (module 02).
- **Lag** is the metric that matters operationally: `log-end-offset − committed-offset`.

➡ Next: [04-delivery-semantics](../04-delivery-semantics/README.md) — at-least-once vs exactly-once.
