import gettext
from dataclasses import dataclass, field
from typing import List, Any
import portions
import nutrient

_ = gettext.gettext


@dataclass
class Food:
    """
    Class that represents a single food
    """
    ndb_no: int
    __db: Any
    meal: Any

    fdgrp_cd: int

    long_desc: str
    shrt_desc: str
    ref_desc: str
    refuse: float
    # Can be None
    pro_factor: float
    fat_factor: float
    cho_factor: float
    macro_pct: tuple
    portion: portions.Portion

    nutrients: List[nutrient.Nutrient] = field(default_factory=list)
    pcf_nutrient: nutrient.Nutrient = None

    def __init__(self,
                 ndb_no: int,
                 db,
                 meal=None,
                 pcf_nutrient: nutrient.Nutrient = None,
                 portion: portions.Portion = None):
        if ndb_no >= 0:
            self.ndb_no = ndb_no
            self.__db = db

            # meal is None it means that we're viewing the food
            if meal:
                self.meal = meal
                meal.append_food(self)

            self.portion = portion
            self.pcf_nutrient = pcf_nutrient
        else:
            raise ValueError("Food number must be >= 0")

    @property
    def nutrients(self):
        return self.__db.get_food_nutrients(self)

    @property
    def portion(self):
        return self.__db.get_food_amount(self)

    @portion.setter
    def portion(self, new_portion: portions.Portion):
        self.__db.set_food_amount(self)

    @property
    def pcf_nutrient(self):
        return self.__db.get_food_pcf(self)

    @pcf_nutrient.setter
    def pcf_nutrient(self,
                     new_pcf_nutrient: nutrient.Nutrient):
        self.__db.set_food_pcf(self, new_pcf_nutrient)

    def get_preferred_weight(self) -> portions.Portion:
        return self.__db.get_food_preferred_weight(self)
