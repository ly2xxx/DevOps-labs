# Module 05 — Java Client  (optional, ~15 min)

The JD asks for **Java *and* Python**. This is the same trade producer/consumer
in Java so you can speak to both stacks. The Java and Python clients are fully
interoperable — produce with one, consume with the other.

## Prerequisite

Maven (the lab box has Java 11 but not Maven):

```powershell
# Windows
winget install Apache.Maven
# verify
mvn -version
```

If you'd rather not install Maven, read the source — the API maps 1:1 to the
Python modules — and demo with the Python clients instead.

## Run it

Make sure the broker is up (`docker compose up -d` from the `kafka/` root).

```powershell
# Consumer (Java) — leave running
mvn -q compile exec:java "-Dexec.mainClass=com.jpmc.primefinance.kafka.TradeConsumer" "-Dexec.args=java-group"

# Producer (Java) — another terminal
mvn -q compile exec:java "-Dexec.mainClass=com.jpmc.primefinance.kafka.TradeProducer" "-Dexec.args=20"
```

## Cross-language proof

Produce with Java, consume with Python (records are plain JSON either way):

```powershell
# this folder
mvn -q compile exec:java "-Dexec.mainClass=com.jpmc.primefinance.kafka.TradeProducer" "-Dexec.args=10"
# kafka/lab/01-python-pubsub
python consumer.py --group cross-lang
```

## Java ↔ Python config cheat-sheet

| Concept | Java (`ProducerConfig`/`ConsumerConfig`) | Python (confluent-kafka dict) |
|---------|------------------------------------------|-------------------------------|
| brokers | `BOOTSTRAP_SERVERS_CONFIG` | `bootstrap.servers` |
| durability | `ACKS_CONFIG=all` | `acks=all` |
| dedupe retries | `ENABLE_IDEMPOTENCE_CONFIG=true` | `enable.idempotence=True` |
| group | `GROUP_ID_CONFIG` | `group.id` |
| replay | `AUTO_OFFSET_RESET_CONFIG=earliest` | `auto.offset.reset=earliest` |

The Java keys are `dotted.lower.case` strings underneath (`bootstrap.servers`),
identical to Python — the `*Config` constants are just typed aliases.

➡ Back to the [lab index](../README.md).
