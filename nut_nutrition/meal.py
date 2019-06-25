import gi
gi.require_version('Gtk', '3.0')
import gettext
import logging
from pprint import pformat
from dataclasses import dataclass

_ = gettext.gettext


@dataclass
class Portion:
    """
    Class that represents a portion
    """
    quantity: float = None
    unit: str = 'g'


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
    # Can be None
    portion: Portion
    tagname: str
    nutr_desc: str
    dv_default: float
    nut_opt: float
    __db: DBMan

    @nut_opt.setter
    def set_nut_opt(self, new_value=None):
        """
        Sets the daily nutrient value in grams
        :param nutrient_desc: The nutrient number
        :param value: The new daily value, if None the limit is removed
        """
        self.__db.set_nutrient_dv(self, new_value)


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
    portion: Portion
    pro_factor: float
    fat_factor: float
    cho_factor: float
    nutrients: List[Nutrient] = field(default_factory=list)
    pcf_nutrient: Nutrient = None
    macro_pct: tuple
    __db: DBMan
    meal: Meal = None

    @property
    def nutrients(self):
        return self.__db.get_food_nutrients(self)


    @amount.setter
    def set_amount(self, new_amount: float):
        if new_amount >= 0:
            self.amount = new_amount
            self.__db.set_food_amount(self, self.meal)
        else:
            raise ValueError("The new amount must be >= 0")

    @pcf_nutrient.setter
    def set_amount(self, new_pcf_nutrient: Nutrient):
        self.pcf_nutrient = new_pcf_nutrient
        self.__db.set_food_pcf()



@dataclass
class Meal:
    """
    Class that represents a single meal
    :param meal_id: Unique meal identifier which is normally %Y%M%D%meal_no
    :param foods: List of foods in meal
    """
    meal_id: int
    _foods: List[Food] = field(default_factory=list)
    __db: DBMan

    def add_food(self, food: Food):
        self.__db.insert_food_into_meal(food, self)

    def remove_food(self, food: Food):
        self.__db.remove_food_from_meal(food, self)

    def analyze(self):
        raise NotImplementedError

class Analysis():
    # To allow for dynamic updates a nutrient:GTKModelIterator dictionary
    # should be compiled, so that the view can be updated witouth recreating
    # it
    def __init__(self, parent, tree_iter, defined_nutrients):
        self._parent_treestore = parent
        self._defined_nutrients = defined_nutrients

        tree = {
            # Calories
            208: None,
            'Prot/Carb/Fat': None,
            'Omega-6/3 Balance': {
                # Omega-6
                2006: [
                    2001,
                    2002
                ],
                # Omega-3
                2007: [*range(2003, 2006)]
            },
            # Total Carb
            205: [
                2000,  # Non fiber carb
                291,  # Fiber
                209,  # Starch
            ],
            # Sugars
            269: [
                # Sucrose, Glucose, Fructose, Lactose, Maltose
                *range(210, 215),
                287  # Galactose
            ],
            # Proteins
            203: [
                # Adjusted Protein
                257,
                *range(501, 518),
                521  # Hydroxyproline
            ],
            # Total fat
            204: {
                # Sat Fat
                606: [
                    607,  # 4:0
                    608,  # 6:0
                    609,  # 8:0
                    610,  # 10:0
                    611,  # 12:0
                    696,  # 13:0
                    612,  # 14:0
                    652,  # 15:0
                    613,  # 16:0
                    653,  # 17:0
                    614,  # 18:0
                    615,  # 20:0
                    624,  # 22:0
                    654,  # 24:0
                ],
                #  Mono Fat
                645: [
                    625,  # 14:1
                    697,  # 15:1
                    626,  # 16:1
                    673,  # 16:1c
                    687,  # 17:1
                    617,  # 18:1
                    674,  # 18:1c
                    628,  # 20:1
                    630,  # 22:1
                    676,  # 22:1c
                    671,  # 24:1c
                ],
                # Poly Fat
                646: [
                    618,
                    675,
                    617,
                    851,
                    685,
                    627,
                    672,
                    689,
                    852,
                    853,
                    620,
                    855,
                    629,
                    857,
                    858,
                    631,
                    621
                ],
                # Trans fat
                605: {
                    # TransMonoenoic
                    693: [
                        *range(662, 665),
                        859
                    ],
                    # Transpolyenoic
                    695: [
                        666,
                        665,
                        669,
                        670,
                        856
                    ]

                }

            },
            # Miscellaneous
            'Misc': {
                268: None,  # Energy
                207: None,  # Ash
                255: None,  # Water
                221: None,  # Ethyl Alcohol
                404: None,  # Thiamin
                # Caffeine and Theobromine
                'Alkaloids': [*range(262, 264)]
            },
            'Vitamins': [
                *range(318, 327),
                328,
                334,
                *range(337, 339),
                *range(341, 348),
                401,
                *range(404, 407),
                410,
                415,
                417,
                418,
                421,
                *range(428, 433),
                435,
                454
            ],
            'Sterols': [
                601,
                636,
                *range(638, 640),
                641
            ],
            'Minerals': [
                301,  # Calcium
                # Iron Magnesium Phosphorous Potassium Sodium
                *range(303, 308),
                309,  # Zinc
                *range(312, 314),  # Copper Fluoride
                315,  # Manganese
                317,  # Selenium
            ]
        }
        logging.debug(pformat(tree))
        self._build_tree(tree_iter, tree)

    def _build_tree(self, tree_iter, dictionary):
        # ('g', 'F24D1C', '24:1c', None, 0.0)
        for key, item in dictionary.items():
            next_tree_iter = None
            if key in self._defined_nutrients:
                tmp_ntr = self._defined_nutrients[key]
                data_to_append = []
                try:
                    data_to_append = [key,
                                      _(tmp_ntr[2]),
                                      False,
                                      0,
                                      tmp_ntr[0],
                                      tmp_ntr[1],
                                      tmp_ntr[3]
                                      ]
                except TypeError:
                    data_to_append = [key,
                                      _(tmp_ntr[2]),
                                      False,
                                      0,
                                      None,
                                      '',
                                      None]
                logging.debug(f'Adding: {pformat(data_to_append)}')
                next_tree_iter = self._parent_treestore.append(tree_iter,
                                                               data_to_append)
            else:
                next_tree_iter = self._parent_treestore.append(tree_iter,
                                                               [0,
                                                                _(f'{key}'),
                                                                False,
                                                                0,
                                                                0.0,
                                                                '',
                                                                0.0])
            if type(item) is dict:
                self._build_tree(next_tree_iter, item)
            elif type(item) is list:
                for nutr in item:
                    try:
                        tmp_ntr = self._defined_nutrients[nutr]
                        data_to_append = [nutr,
                                          _(tmp_ntr[2]),
                                          False,
                                          0,
                                          tmp_ntr[0],
                                          tmp_ntr[1],
                                          tmp_ntr[3]]

                        logging.debug(f'Adding: {pformat(data_to_append)}')
                        self._parent_treestore.append(next_tree_iter,
                                                      data_to_append)
                    except KeyError:
                        pass

# NDB_No|Gm_Wgt|Nutr_No   in mealfoods
# Nutr_No|Units|Tagname|NutrDesc|dv_default|nutopt    in nutr_def
# NDB_No|FdGrp_Cd|Long_Desc|Shrt_Desc|Ref_desc|Refuse|Pro_Factor|Fat_Factor|CHO_Factor
# in food des

# in treestore
# NDB_No|Nutr_No|Description|PCF_Nutr_No|Gm_Wgt|'g'|Volume|'cm3'|Nutr_Val|nutr_def.Units
# select * from mealfoods JOIN nut_data on mealfoods.NDB_No

# If Nutr_No == 0 then this is not a nutrient, it's a nutrient group or food
# if NDB_No == 0 then this is not food, it's probably a nutrient group
# if PCF_Nutr_No == 0 then PCF is disabled for this food


class FoodAnal(Analysis):
    def __init__(self, parent, ndb_no, defined_nutrients, name, weight,
                 pcf_Nutr_No=0):
        self._parent_treestore = parent
        self._ndb_no = None
        food_to_append = [
            ndb_no,
            # Food Name
            _(name),
            # Is food
            True,
            # PCF
            pcf_Nutr_No,
            # Weight
            weight,
            # Weights unit
            'g',
            # Daily value, unused for food
            0
        ]

        top = self._parent_treestore.append(None, food_to_append)
        super(Food, self).__init__(parent, top, defined_nutrients)
