package com.jpmc.primefinance.kafka;

import java.util.Properties;
import java.util.Random;
import java.util.concurrent.ThreadLocalRandom;

import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.Producer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.serialization.StringSerializer;

/**
 * Idempotent Java producer for trade events. Mirrors the Python producer in
 * module 01/04 so you can talk to either language stack in the interview.
 *
 * Key is the account, so per-account ordering holds (see module 02).
 *
 *   mvn -q compile exec:java \
 *     -Dexec.mainClass=com.jpmc.primefinance.kafka.TradeProducer \
 *     -Dexec.args="20"
 */
public class TradeProducer {

    private static final String BOOTSTRAP =
            System.getenv().getOrDefault("KAFKA_BOOTSTRAP", "localhost:9092");
    private static final String TOPIC = "trades";

    private static final String[] ACCOUNTS =
            {"ACME-PRIME", "BLUEJAY-FUND", "CYGNUS-CAP", "DELPHI-AM", "EVEREST-LP"};
    private static final String[] SYMBOLS = {"AAPL", "MSFT", "NVDA", "JPM", "GS", "TSLA"};
    private static final String[] SIDES = {"BUY", "SELL"};

    public static void main(String[] args) {
        int count = args.length > 0 ? Integer.parseInt(args[0]) : 10;

        Properties props = new Properties();
        props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, BOOTSTRAP);
        props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
        props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
        props.put(ProducerConfig.ACKS_CONFIG, "all");
        props.put(ProducerConfig.ENABLE_IDEMPOTENCE_CONFIG, true);
        props.put(ProducerConfig.CLIENT_ID_CONFIG, "java-trade-producer");

        Random rnd = ThreadLocalRandom.current();
        System.out.printf("Producing %d events to '%s' via %s%n", count, TOPIC, BOOTSTRAP);

        try (Producer<String, String> producer = new KafkaProducer<>(props)) {
            for (int i = 0; i < count; i++) {
                String account = ACCOUNTS[rnd.nextInt(ACCOUNTS.length)];
                String value = tradeJson(account, rnd);

                ProducerRecord<String, String> record =
                        new ProducerRecord<>(TOPIC, account, value);

                producer.send(record, (meta, ex) -> {
                    if (ex != null) {
                        System.err.println("DELIVERY FAILED: " + ex.getMessage());
                    } else {
                        System.out.printf("  ack partition=%d offset=%d key=%s%n",
                                meta.partition(), meta.offset(), account);
                    }
                });
            }
            producer.flush(); // block until all acks are in
        }
        System.out.println("Done.");
    }

    private static String tradeJson(String account, Random rnd) {
        String symbol = SYMBOLS[rnd.nextInt(SYMBOLS.length)];
        String side = SIDES[rnd.nextInt(SIDES.length)];
        int qty = (rnd.nextInt(20) + 1) * 25;
        double price = Math.round((50 + rnd.nextDouble() * 450) * 100.0) / 100.0;
        return String.format(
                "{\"account\":\"%s\",\"symbol\":\"%s\",\"side\":\"%s\",\"quantity\":%d,\"price\":%.2f}",
                account, symbol, side, qty, price);
    }
}
