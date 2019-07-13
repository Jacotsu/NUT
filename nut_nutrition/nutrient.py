import gettext
from dataclasses import dataclass
from typing import Any
import portion

_ = gettext.gettext


@dataclass
class Nutrient:
    """
    Class that represents a single nutrient
    :param nutr_no: Unique nutrient number
    :param units: Weight measure unit of the nutrient
    :param quantity: Quantity of nutrient
    :param tagname: Unique short nutrient tag
    :param nutr_desc: Description of the nutrient
    :param dv_default: Default daily value of the nutrient
    :param nut_opt: User's selected daily value
    """
    nutr_no: int
    # Should be a DBMan instance
    __db: Any

    def __init__(self, nutr_no: int, db):
        if nutr_no >= 0:
            self.nutr_no = nutr_no
            self.__db = db
        else:
            raise ValueError("Nutrient number must be >= 0")

    @property
    def nut_opt(self) -> float:
        return self.__db.get_nutrient_field(self, 'nutopt')

    @nut_opt.setter
    def nut_opt(self, new_value: float = None):
        """
        Sets the daily nutrient value in grams
        :param nutrient_desc: The nutrient number
        :param value: The new daily value, if None the limit is removed
        """
        if new_value < 0:
            raise ValueError("The new daily value must be >= 0 or None")
        self.__db.set_nutrient_field(self,
                                     'nutopt',
                                     new_value)

    # Can be None
    @property
    def tagname(self) -> str:
        return self.__db.get_nutrient_field(self, 'Tagname')

    @tagname.setter
    def tagname(self, new_value: str = None):
        """
        Sets the nutrient's tagname
        :param new_value: The new tagname
        """
        if new_value < 0:
            raise ValueError("The new daily value must be >= 0 or None")
        self.__db.set_nutrient_field(self,
                                     'Tagname',
                                     new_value)

    @property
    def nutr_desc(self) -> str:
        return self.__db.get_nutrient_field(self, 'NutrDesc')

    @nutr_desc.setter
    def nutr_desc(self, new_value: str = None):
        """
        Sets the nutrient's nutr_desc
        :param new_value: The new nutr_desc
        """
        if new_value < 0:
            raise ValueError("The new daily value must be >= 0 or None")
        self.__db.set_nutrient_field(self,
                                     'NutrDesc',
                                     new_value)

    @property
    def dv_default(self) -> float:
        return self.__db.get_nutrient_field(self, 'dv_default')

    @dv_default.setter
    def dv_default(self, new_value: float = None):
        """
        Sets the nutrient's default daily value
        :param new_value: The new default daily value
        """
        if new_value < 0:
            raise ValueError("The new daily value must be >= 0 or None")
        self.__db.set_nutrient_field(self,
                                     'dv_default',
                                     new_value)

    @property
    def portion_value(self) -> portion.Portion:
        return portion.Portion(None,
                               self.__db.get_nutrient_field(self, 'Units'))

    @portion_value.setter
    def portion_value(self, new_value: portion.Portion):
        """
        Sets the nutrient's portion (just the portion units)
        :param new_value: The new portion
        """
        if new_value.quantity < 0:
            raise ValueError("The portion quantity must be >= 0 or None")
        elif not new_value.unit:
            raise ValueError("The portion unit must not None")
        else:
            self.__db.set_nutrient_field(self,
                                         'Units',
                                         new_value)
