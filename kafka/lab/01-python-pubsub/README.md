# Module 01 — Python Pub/Sub  (~15 min)

Your first end-to-end producer → topic → consumer round trip.

## Run it

Two terminals, both from this folder (`kafka/lab/01-python-pubsub`):

```powershell
# Terminal 1 — start the consumer first so it sees everything
python consumer.py

# Terminal 2 — produce some trade events
python producer.py --count 20
```

You'll see the consumer print each trade with its `[partition@offset]`.

## What to notice

| Observation | Concept |
|-------------|---------|
| Producer prints an `ack` per message with partition + offset | The broker assigns offsets; `acks=all` waits for replicas |
| Offsets increase per partition, not globally | **Offsets are per-partition**, not per-topic |
| Re-running the consumer with the *same* group reads nothing new | Committed offsets are remembered per group |
| Running with `--group fresh` re-reads everything | New group + `auto.offset.reset=earliest` replays from the start |

## Try this

```powershell
python consumer.py --group analytics      # a second, independent group...
python producer.py --count 5              # ...gets its OWN copy of every event
```

Two groups each receive the full stream — this is **pub/sub fan-out**. Within a
single group, each event goes to exactly one member (queue semantics, module 03).

➡ Next: [02-keys-ordering](../02-keys-ordering/README.md) — why we key by account.
