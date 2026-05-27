"""Shared trade-event domain for the Kafka lab.

Prime brokerage runs on ordered streams of per-account activity: orders, fills,
position deltas, margin events. We model a single `TradeEvent` and key Kafka
records by `account` so that everything for one account lands on one partition
(the basis of Kafka's per-key ordering guarantee — see module 02).
"""
from __future__ import annotations

import json
import random
import time
import uuid
from dataclasses import asdict, dataclass, field

ACCOUNTS = ["ACME-PRIME", "BLUEJAY-FUND", "CYGNUS-CAP", "DELPHI-AM", "EVEREST-LP"]
SYMBOLS = ["AAPL", "MSFT", "NVDA", "JPM", "GS", "TSLA", "SPY"]
SIDES = ["BUY", "SELL"]


@dataclass
class TradeEvent:
    account: str
    symbol: str
    side: str
    quantity: int
    price: float
    event_id: str = field(default_factory=lambda: str(uuid.uuid4()))
    ts_ms: int = field(default_factory=lambda: int(time.time() * 1000))

    # --- (de)serialization: Kafka moves bytes; JSON keeps the lab dependency-free.
    # In production you'd usually use Avro/Protobuf + a Schema Registry instead.
    def to_bytes(self) -> bytes:
        return json.dumps(asdict(self)).encode("utf-8")

    @staticmethod
    def from_bytes(raw: bytes) -> "TradeEvent":
        return TradeEvent(**json.loads(raw.decode("utf-8")))

    # The partition key. Same account -> same partition -> ordered delivery.
    def key_bytes(self) -> bytes:
        return self.account.encode("utf-8")

    def notional(self) -> float:
        return round(self.quantity * self.price, 2)

    def summary(self) -> str:
        return (
            f"{self.account:<13} {self.side:<4} {self.quantity:>4} {self.symbol:<5} "
            f"@ {self.price:>8.2f}  (notional {self.notional():>12,.2f})"
        )


def random_event(account: str | None = None) -> TradeEvent:
    return TradeEvent(
        account=account or random.choice(ACCOUNTS),
        symbol=random.choice(SYMBOLS),
        side=random.choice(SIDES),
        quantity=random.choice([10, 25, 50, 100, 250, 500]),
        price=round(random.uniform(50, 500), 2),
    )


def event_stream(count: int, account: str | None = None):
    """Yield `count` trade events, optionally all for one account."""
    for _ in range(count):
        yield random_event(account)
