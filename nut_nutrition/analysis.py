from dataclasses import dataclass
from typing import List, Any
import meal


@dataclass
class Analysis:
    meals: List[meal.Meal]
    __db: Any

    @property
    def max_meals():
        """
        Total meal number
        """
        pass

    @property
    def meal_count():
        """
        Number of meals to analyze
        """
        pass

    @meal_count.setter
    def meal_count():
        pass

    @property
    def meals_per_day():
        """
        """
        pass

    @meal_count.setter
    def meals_per_day():
        pass

    @property
    def first_meal():
        """
        """
        pass

    @first_meal.setter
    def first_meal():
        pass

    @property
    def last_meal():
        """
        """
        pass

    @last_meal.setter
    def last_meal():
        pass

    @property
    def current_meal():
        """
        """
        pass

    @current_meal.setter
    def current_meal():
        pass

    @property
    def macro_pct():
        """
        """
        pass

    @property
    def n6balance():
        """
        """
        pass
