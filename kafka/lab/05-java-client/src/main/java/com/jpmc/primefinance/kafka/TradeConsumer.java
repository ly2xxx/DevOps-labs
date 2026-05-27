package com.jpmc.primefinance.kafka;

import java.time.Duration;
import java.util.Collections;
import java.util.Properties;

import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.KafkaConsumer;
import org.apache.kafka.common.serialization.StringDeserializer;

/**
 * Java consumer for the `trades` topic. Run several copies with the same
 * --group to watch consumer-group rebalancing, exactly like module 03.
 *
 *   mvn -q compile exec:java \
 *     -Dexec.mainClass=com.jpmc.primefinance.kafka.TradeConsumer \
 *     -Dexec.args="java-group"
 */
public class TradeConsumer {

    private static final String BOOTSTRAP =
            System.getenv().getOrDefault("KAFKA_BOOTSTRAP", "localhost:9092");
    private static final String TOPIC = "trades";

    public static void main(String[] args) {
        String group = args.length > 0 ? args[0] : "java-consumer";

        Properties props = new Properties();
        props.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, BOOTSTRAP);
        props.put(ConsumerConfig.GROUP_ID_CONFIG, group);
        props.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getName());
        props.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getName());
        props.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");

        System.out.printf("Consuming '%s' as group '%s' — Ctrl+C to stop%n", TOPIC, group);

        try (KafkaConsumer<String, String> consumer = new KafkaConsumer<>(props)) {
            consumer.subscribe(Collections.singletonList(TOPIC));
            while (true) {
                ConsumerRecords<String, String> records = consumer.poll(Duration.ofSeconds(1));
                for (ConsumerRecord<String, String> rec : records) {
                    System.out.printf("[p%d@%d] key=%s value=%s%n",
                            rec.partition(), rec.offset(), rec.key(), rec.value());
                }
            }
        }
    }
}
