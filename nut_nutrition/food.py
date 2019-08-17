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
    __db: Any
    portion: portions.Portion
    __meal: Any = None
    nutrients: List[nutrient.Nutrient] = field(default_factory=list)
    pcf_nutrient: nutrient.Nutrient = None

    @property
    def nutrients(self):
        return self.__db.get_food_nutrients(self)

    @property
    def portion(self):
        return self.portion

    @portion.setter
    def portion(self, new_portion: portions.Portion):
        self.portion = new_portion
        self.__db.set_food_amount(self, self.meal)

    @property
    def pcf_nutrient(self):
        return self.__db.get_food_(self)

    @pcf_nutrient.setter
    def pcf_nutrient(self,
                     new_pcf_nutrient: nutrient.Nutrient):
        self.__db.set_food_pcf(self, new_pcf_nutrient)

    def get_preferred_weight(self) -> portions.Portion:
        return self.__db.get_food_preferred_weight(self)
