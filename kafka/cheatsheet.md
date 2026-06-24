# Apache Kafka Cheat Sheet

Quick reference for Apache Kafka CLI commands (KRaft/ZooKeeper) and configuration parameters.

---

## 🐳 Docker Broker Management

```bash
# Start Kafka broker + UI (KRaft mode)
docker compose up -d

# Check broker status
docker compose ps

# View broker logs
docker compose logs -f kafka

# Stop broker and save state
docker compose down

# Stop broker and delete all topics/data
docker compose down -v
```

---

## 🚀 Kafka CLI Topic Management
All commands are run using scripts included in the Kafka distribution. If using Docker Compose, prefix with `docker compose exec kafka`.

### Topic Administration
```bash
# Create a topic with 3 partitions and replication factor 1
kafka-topics.sh --bootstrap-server localhost:9092 --create --topic trades --partitions 3 --replication-factor 1

# List all topics
kafka-topics.sh --bootstrap-server localhost:9092 --list

# Describe a topic (shows partition leaders, replicas, ISRs)
kafka-topics.sh --bootstrap-server localhost:9092 --describe --topic trades

# Modify partition count (only increase is supported)
kafka-topics.sh --bootstrap-server localhost:9092 --alter --topic trades --partitions 5

# Delete a topic
kafka-topics.sh --bootstrap-server localhost:9092 --delete --topic trades
```

---

## 📨 Producing & Consuming Messages

### Console Producer
```bash
# Start producer (Ctrl+C to exit, Enter to send message)
kafka-console-producer.sh --bootstrap-server localhost:9092 --topic trades

# Produce with keys (key-value separated by tab or comma)
kafka-console-producer.sh --bootstrap-server localhost:9092 --topic trades \
  --property parse.key=true \
  --property key.separator=":"
```

### Console Consumer
```bash
# Consume messages from the latest offset (real-time stream)
kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic trades

# Consume all messages from the beginning of the log
kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic trades --from-beginning

# Consume with key and value printing
kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic trades \
  --from-beginning \
  --property print.key=true \
  --property key.separator=":"
```

---

## 👥 Consumer Group Management

```bash
# List all active consumer groups
kafka-consumer-groups.sh --bootstrap-server localhost:9092 --list

# Describe a group (shows active members, host, partition assignments, and LAG)
kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group prime-consumer-group

# Reset offsets for a group (to the beginning)
kafka-consumer-groups.sh --bootstrap-server localhost:9092 --group prime-consumer-group \
  --reset-offsets --to-earliest --execute --topic trades

# Reset offsets back by 10 messages
kafka-consumer-groups.sh --bootstrap-server localhost:9092 --group prime-consumer-group \
  --reset-offsets --shift-by -10 --execute --topic trades
```

---

## ⚙️ Core Configuration Ratios

### Durability vs Performance (ACKS)
- `acks=0`: Producer doesn't wait for acknowledgment. Maximum speed, high loss risk.
- `acks=1`: Producer waits for Leader partition to write to local log. Moderate risk.
- `acks=all` (or `acks=-1`): Producer waits for all In-Sync Replicas (ISR) to write. Zero data loss.

### Partitions & Consumer Scaling
- **Rule of thumb**: A partition can only be consumed by **one** member of a consumer group at a time.
- `Members == Partitions`: Optimal scaling.
- `Members > Partitions`: Excess consumers remain idle (ready to take over on failover).
- `Members < Partitions`: Some consumers process multiple partitions.

---

## 🔍 Troubleshooting Commands

```bash
# Check lag on partitions
kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group prime-consumer-group | awk 'NR==1 || $6 > 0'

# List under-replicated partitions (should return nothing if healthy)
kafka-topics.sh --bootstrap-server localhost:9092 --describe --under-replicated-partitions

# Check current version of Kafka
kafka-topics.sh --version
```
