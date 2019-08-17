from dataclasses import dataclass


@dataclass
class Portion:
    """
    Class that represents a portion
    """
    quantity: float = None
    unit: str = 'g'

    def __str__(self):
        return f"{self.quantity:5.2f} {self.unit}"
