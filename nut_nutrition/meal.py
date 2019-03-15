import gi
import gettext
import logging
from pprint import pformat

gi.require_version('Gtk', '3.0')
_ = gettext.gettext

def set_float_precision(col, cell, model, iterator, func_data):
    data = model.get(iterator, func_data['column_no'])[0]
    if data:
        cell.set_property('text', '{:5.2f}'.format(data))
    else:
        cell.set_property('text', _('[No Data]'))

#xcolumn.set_cell_data_func(xrenderer, \
#    lambda col, cell, model, iter, unused:
#        cell.set_property("text", "%g" % model.get(iter, 0)[0]))

class Analysis():
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
            'Sterols':  [
                601,
                636,
                *range(638, 640),
                641
            ],
            'Minerals':  [
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
                                      tmp_ntr[4],
                                      tmp_ntr[0],
                                      0.0
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
                                          tmp_ntr[3],
                                          tmp_ntr[0],
                                          tmp_ntr[4]]

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


class Food(Analysis):
    def __init__(self, parent, NDB_No, defined_nutrients, name):
        self._parent_treestore = parent
        self._NDB_No = None
        # Name, show pcf, show spinbox, daily value, quantity
        food_to_append = [
            NDB_No,
            _(name),
            True,
            0,
            123.4,
            'lel',
            88
        ]

        top = self._parent_treestore.append(None, food_to_append)
        super(Food, self).__init__(parent, top, defined_nutrients)
