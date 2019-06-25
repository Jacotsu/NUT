import sqlite3
import bignut_queries
import logging
import os
from utils import download_usda_and_unzip, cleanup_usda
from appdirs import user_data_dir
from datetime import datetime
from meal import Nutrient, Food, Meal, Portion

appname = 'nut_nutrition'


class DBMan:
    def __init__(self, db_name=os.path.join(user_data_dir(appname),
                                            'nut.db')):
        os.makedirs(user_data_dir(appname), exist_ok=True)
        try:
            self._conn = sqlite3.connect(db_name)
            self._conn.text_factory = self.decode_non_UTF_strings
        except sqlite3.Error as e:
            logging.error(e)

        self.time_format = "%Y%m%d"

        self.weight_units = {0: 'oz',
                             1: 'g',
                             'oz': 0,
                             'g': 1}

        with self._conn as con:
            cur = con.cursor()
            try:
                cur.executescript(bignut_queries.user_init_query)
            except sqlite3.OperationalError:
                logging.warning('Database empty or corrupted initializing'
                                ' a new one')
                # Loads the USDA and initializes the logic
                download_usda_and_unzip(user_data_dir(appname))
                self.load_db(user_data_dir(appname))
                cur.executescript(bignut_queries.init_logic)
                cleanup_usda(user_data_dir(appname))

            cur.executescript(bignut_queries.user_init_query)

    @staticmethod
    def decode_non_UTF_strings(bytes_array):
        try:
            return bytes_array.decode('UTF-8')
        except UnicodeDecodeError as decode_error:
            decoded = bytes_array.decode('windows-1252')
            logging.error(decoded)
            logging.error(decode_error)
            return decoded

    @property
    def calories(self) -> float:
        """
        :return: The personal option calories
        :rtype: float
        """
        cur = self._conn.cursor()
        cur.execute(bignut_queries.get_defined_nutrients)
        return {nutrient[0]: nutrient[1:]
                for nutrient in cur}

    @property
    def rm_analysis_header(self):
        """
        :return: The record meals analysis header
        :rtype: Tuple
        """
        cur = self._conn.cursor()
        cur.execute(bignut_queries.get_rm_analysis_header)
        return cur.fetchone()

    @property
    def rm_analysis_nutrients(self):
        """
        :return: The record meals analysis nutrients
        :rtype: dict
        """
        cur = self._conn.cursor()
        cur.execute(bignut_queries.get_rm_analysis)
        return {nutrient[0]: nutrient[1:]
                for nutrient in cur}

    @property
    def am_analysis_nutrients(self):
        """
        :return: The record meals analysis nutrients
        :rtype: dict
        """
        cur = self._conn.cursor()
        cur.execute(bignut_queries.get_am_analysis)
        return {nutrient[0]: nutrient[1:]
                for nutrient in cur}

    @property
    def am_analysis_period(self):
        """
        :return: A tuple that contains the start date and the end date
        :rtype: tuple
        """
        cur = self._conn.cursor()
        cur.execute(bignut_queries.get_am_analysis_period)
        return cur.fetchone()

    @property
    def weight_summary(self):
        """
        :return: The weight log summary
        :rtype: Str
        """
        cur = self._conn.cursor()
        cur.execute(bignut_queries.get_weight_summary)
        return cur.fetchone()[0]

    @property
    def last_weight(self):
        """
        :return: The last weight
        :rtype: float
        """
        cur = self._conn.cursor()
        cur.execute(bignut_queries.get_last_weight)
        try:
            return cur.fetchone()[0]
        except TypeError:
            # If there are no last weights return 0
            return 0

    @property
    def last_bodyfat(self):
        """
        :return: The last bodyfat
        :rtype: float
        """
        cur = self._conn.cursor()
        cur.execute(bignut_queries.get_last_bodyfat)
        try:
            return cur.fetchone()[0]
        except TypeError:
            # If there are no last bodyfat return 0
            return 0

    @property
    def defined_nutrients(self):
        """
        Selects
        Nutr_No|Units|Tagname|NutrDesc|dv_default|nutopt
        from nutr_def

        :return: A list of Nutrient objects
        :rtype: list
        """
        cur = self._conn.cursor()
        cur.execute(bignut_queries.get_defined_nutrients)
        return [Nutrient(nutr_no=nut[0],
                         units=nut[1],
                         tagname=nut[2],
                         nutr_desc=[3],
                         dv_default=nut[4],
                         nut_opt=nut[5]) for nut in cur]

    @property
    def am_analysis_meal_no(self) -> int:
        """
        :return: The number of meals that will be analyzed
        :rtype: int
        """
        cur = self._conn.cursor()
        cur.execute(bignut_queries.get_number_of_meals_to_analyze)
        no = cur.fetchone()[0]
        return no

    @am_analysis_meal_no.setter
    def am_analysis_meal_no(self, number_of_meals):
        """
        :param number_of_meals: The number of meals to set
        """
        with self._conn as con:
            cur = con.cursor()
            cur.execute(bignut_queries.set_number_of_meals_to_analyze,
                        (number_of_meals,))

    def get_day_meals(self, day):
        raise NotImplementedError

    @property
    def weight_unit(self):
        """
        :return: The active weight measure unit
        :rtype: String
        """
        cur = self._conn.cursor()
        cur.execute(bignut_queries.get_weight_unit)
        unit = cur.fetchone()[0]
        return self.weight_units[unit]

    @weight_unit.setter
    def weight_unit(self, unit):
        """
        :param unit: The weight measure unit chose from self.weight_units
        """
        with self._conn as con:
            cur = con.cursor()
            cur.execute(bignut_queries.set_weight_unit,
                        (self.weight_units[unit],))

    @property
    def current_meal(self):
        """
        :return: The meal id in this format %Y%m%d%meal_no
        :rtype: String
        """
        cur = self._conn.cursor()
        cur.execute(bignut_queries.get_current_meal)
        meal = cur.fetchone()[0]
        return meal

    @current_meal.setter
    def current_meal(self, meal_id):
        """
        :param date: A datetime object that contains the meal's datetime
        :param meal_no: The day meal number (first meal is 1)
        """

        with self._conn as con:
            cur = con.cursor()
            cur.execute(bignut_queries.set_current_meal,
                        (meal_id,))


    @property
    def current_meal_string(self):
        """
        :return: The current meal string
        :rtype: str
        """
        cur = self._conn.cursor()
        cur.execute(bignut_queries.get_current_meal_str)
        return cur.fetchone()[0]

    @property
    def current_meal_menu(self):
        """
        :return: The current meal menu
        :rtype: cursor
        """
        cur = self._conn.cursor()
        cur.execute(bignut_queries.get_current_meal_food)
        return cur

    def get_meal_from_offset_rel_to_current(self, offset):
        """
        :return: The meal id in this format %Y%m%d%meal_no
                 the current meal if none is found
        :rtype: String
        """
        cur = self._conn.cursor()
        cur.execute(bignut_queries.get_meal_from_offset_rel_to_current,
                    (offset, ))
        meal = cur.fetchone()
        if meal:
            return meal[0]
        else:
            return self.current_meal

    @property
    def macro_pct(self):
        """
        :return: The macro percents in this format (carbs,protein,fat)
        :rtype: Tuple
        """
        cur = self._conn.cursor()
        cur.execute(bignut_queries.get_macro_pct)
        pcts = cur.fetchone()[0]
        return tuple(pcts.split('/'))

    @property
    def omega6_3_balance(self):
        """
        :return: The omega-6/3 balance in this format (Omega6,Omega3)
        :rtype: Tuple
        """
        cur = self._conn.cursor()
        cur.execute(bignut_queries.get_omega6_3_bal)
        bal = cur.fetchone()[0]
        return tuple(bal.replace(" ", "").split('/'))

    @property
    def settings_omega6_3_balance(self):
        """
        :return: The omega-6/3 balance in this format (Omega6,Omega3) from
            personal settings
        :rtype: Tuple
        """
        cur = self._conn.cursor()
        cur.execute(bignut_queries.get_omega6_3_bal)
        bal = cur.fetchone()[0]
        return tuple(bal.replace(" ", "").split('/'))

    @omega6_3_balance.setter
    def set_settings_omega6_3_balance(self, data):
        """
        :param data: A tuple that contains the omega6 and omega3 ratio
        """



    @property
    def food_list(self):
        """
        :return: The food's list
        :rtype: Iterator of tuples
        """
        cur = self._conn.cursor()
        cur.execute(bignut_queries.get_food_list)
        return cur

    @property
    def food_groups(self):
        """
        :return: The defined food groups as (FdGrp_Cd, FdGrp_Desc)
        :rtype: Iterator of tuples
        """
        cur = self._conn.cursor()
        cur.execute(bignut_queries.get_food_groups)
        return cur

    def get_ranked_foods(self, Nutr_val, rank_choice=0, FdGrp_Cd=0):
        """
        :return: The foods belonging to the FdGrp_Cd
        :rtype: Iterator of tuples
        """
        cur = self._conn.cursor()
        rank_choices = {
            0: bignut_queries.foods_ranked_per_100_grams,
            1: bignut_queries.foods_ranked_per_100_calories,
            2: bignut_queries.foods_ranked_per_daily_recorded_meals,
            3: bignut_queries.foods_ranked_per_1_aproximate_serving
        }
        query_params = {'Nutr_val': Nutr_val, 'FdGrp_Cd': FdGrp_Cd}
        cur.execute(rank_choices[rank_choice], query_params)
        return cur

    def search_food(self, long_desc):
        """
        :param long_desc: A string that contains the partial or complete
                          food description
        :return: The sql cursor
        :rtype: Sql cursor
        """
        sql_like_string = f'%{long_desc}%'.replace(' ', '%')
        with self._conn as con:
            cur = con.cursor()
            cur.execute(bignut_queries.search_food,
                        {'long_desc': sql_like_string})
            return cur

    def get_weight_log(self):
        """
        :return: The sql cursor
        :rtype: Sql cursor
        """
        cur = self._conn.cursor()
        cur.execute(bignut_queries.get_weight_log)
        return cur

    def insert_weight_into_log(self, weight, body_fat_perc):
        """
        :param weight: The weight in kilograms
        :param body_fat_perc: The body fat percentage
        :return: The sql cursor
        :rtype: Sql cursor
        """
        with self._conn as con:
            cur = con.cursor()
            cur.execute(bignut_queries.insert_weight_log,
                        (weight,
                         body_fat_perc))

    def clear_weight_log(self):
        """
        Clears the weight log
        """
        with self._conn as con:
            cur = con.cursor()
            cur.execute(bignut_queries.clear_weight_log)

    def set_nutrient_dv(self, nutrient: Nutrient, value=None):
        """
        Sets the daily nutrient value in grams
        :param nutrient_desc: The nutrient number
        :param value: The new daily value, if None the limit is removed
        """
        with self._conn as con:
            cur = con.cursor()
            query_params = {'nutopt': value,
                            'Nutr_No': nutrient.nutr_no}
            cur.execute(bignut_queries.set_nutrient_dv,
                        query_params)

    def get_meal_by_id(self, meal_id):
        """
        :param meal_id: The meal id in the following format %Y%m%d%meal_no
        :return: A list containing the foods
        :rtype: list
        """
        cur = self._conn.cursor()
        cur.execute(bignut_queries.get_meal_by_id, (meal_id,))

        return [Food(*x[:3]) for x in cur]


    def get_food_preferred_weight(self, food: Food) -> float:
        """
        :param food: Food that you want to know the preferred weight
        :return: The food's preferred weight in grams
        :rtype: float
        """
        cur = self._conn.cursor()
        cur.execute(bignut_queries.get_food_preferred_weight, (food.ndb_no,))

        return cur.fetchone()[0]

    def set_food_pcf(self,
                     food: Food,
                     pcf_nutrient: Nutrient=None,
                     meal: Meal=None):
        """
        :param food: Food that needs to change the pcf
        :param pcf_nutrient: The nutrient to be set as new pcf
        :param meal: The meal which contains the food
        """
        with self._conn as con:
            cur = con.cursor()
            query_params = {'NDB_No': food.ndb_no,
                            'meal_id': meal.meal_id if meal else None,
                            'Nutr_No': pcf_nutrient.nutr_no}
            cur.execute(bignut_queries.set_food_pcf,
                        query_params)

    def set_food_amount(self,
                        food: Food,
                        meal: Meal=None):
        """
        :param food: Food to change the amount
        :param meal_id: The meal id, if None defaults to the current meal
        """
        with self._conn as con:
            cur = con.cursor()
            query_params = {'NDB_No': food.ndb_no,
                            'meal_id': meal.meal_id if meal else None,
                            'Gm_Wgt': food.portion.quantity}
            cur.execute(bignut_queries.set_food_amount,
                        query_params)


    def insert_food_into_meal(self,
                              food: Food,
                              meal: Meal=None):
        """
        :param food: Food to insert into the meal
        :param meal: Meal to modify, if None the current meal is assumed
        """
        with self._conn as con:
            cur = con.cursor()
            query_params = {'NDB_No': food.ndb_no,
                            'meal_id': meal.meal_id if meal else None,
                            'Gm_Wgt': food.portion.quantity if food.portion
                                else None,
                            'pcf_Nutr_No': food.pcf_nutrient.nutr_no if
                                food.pcf_nutrient else None}
            cur.execute(bignut_queries.insert_food_into_meal,
                        query_params)

    def remove_food_from_meal(self,
                              food: Food,
                              meal: Meal=None):
        """
        :param food: Food to remove
        :param meal: Meal to remove the food from, if None the current meal
            is assumed
        """
        with self._conn as con:
            cur = con.cursor()
            query_params = {'NDB_No': food.ndb_no,
                            'meal_id': meal.meal_id if meal else None}
            cur.execute(bignut_queries.remove_food_from_meal,
                        query_params)

    def get_nutrient_name_by_nutr_no(self, nutr_no):
        """
        :return: Name of the nutrient specified by nutr_no
        :rtype: str
        """
        cur = self._conn.cursor()
        cur.execute(bignut_queries.get_nutrient_name, (Nutr_No,))

        return str(cur.fetchone()[0])

    def get_food_by_NDB_No(self,
                           NDB_No,
                           portion: Portion = Portion()):
        """
        :param NDB_No: Unique food identifier number
        :param portion: Specifies the portion of the food, if None
            the default portion is assumed
        :return: The food with the NDB_No
        :rtype: Food
        """
        cur = self._conn.cursor()
        cur.execute(bignut_queries.get_food_from_NDB_No,
                    {'NDB_No': NDB_No})

        data = cur.fetchone()
        return Food(ndb_no=data[0]
                     fdgrp_cd=data[1]
                     long_desc=data[2]
                     shrt_desc=data[3]
                     ref_desc=data[4]
                     refuse=data[5]
                     portion=portion
                     pro_factor=data[6]
                     fat_factor=data[7]
                     cho_factor=data[8]
                     )

    def get_nutrient_story(self,
                           nutrient: Nutrient,
                           start_date: datetime,
                           end_date: datetime) -> map:
        """
        Retrieves the story of a nutrient. The story of a nutrient is the
        association between meals and the nutrient's value

        :param nutrient: The nutrient number that you want to fetch the story
            from
        :param start_date: The start date
        :param end_date: The end date
        :return: An iterable of the following tuples
            (meal_id, nutrient_value)
        :rtype: map
        """
        if start_date > end_date:
            raise ValueError("The start date must be before the end date")
        if end_date < start_date:
            raise ValueError("The end date must be after the start date")

        cur = self._conn.cursor()
        query_params = {'Nutr_No': nutrient.nutr_no,
                        'start_date': start_date.strftime(self.time_format),
                        'end_date': end_date.strftime(self.time_format)}
        cur.execute(bignut_queries.get_nutrient_story,
                    query_params)
        return map(lambda x: (datetime.strptime(str(x[0]), '%Y%m%d'), x[1]),
                   cur)

    def get_food_nutrients(self, food: Food) -> map:
        """
        Retrieves the nutrients of a food.
        If a portion of food is not specified it assumes the default portion

        :param food: Food from which retrieve the nutrients
        :return: Iterable of nutrients
        :rtype: map
        """
        cur = self._conn.cursor()

        cur.execute(bignut_queries.get_food_nutrients,
                    {'NDB_No': food.ndb_no,
                     'Gm_Wgt': food.portion.quantity if food.portion
                        else None})
        return map(lambda x: Nutrient(nutr_no=x[0],
                                      units=x[1],
                                      tagname=x[2],
                                      nutr_desc=[3],
                                      dv_default=x[4],
                                      nutr_opt=x[5]), cur)

    def load_db(self, path):
        with self._conn as con:
            cur = con.cursor()
            logging.info(f'Started database loading from {path}')
            cur.executescript(bignut_queries.db_load_pt1)

            separator = '^'
            table_mapping = {'NUTR_DEF.txt': 'ttnutr_def',
                             'FD_GROUP.txt': 'tfd_group',
                             'FOOD_DES.txt': 'tfood_des',
                             'WEIGHT.txt': 'tweight',
                             'NUT_DATA.txt': 'tnut_data'}

            for USDA_file, table in table_mapping.items():
                with open(os.path.join(path, USDA_file),
                          'r', encoding='iso-8859-1') as tbl:
                    values = map(lambda x: x.rstrip().split(separator), tbl)
                    # !!! UNSAFE CODE !!!
                    # as long as you don't take user input it should work
                    # fine.
                    data = next(values)
                    query = f'INSERT INTO {table} VALUES'\
                        f'({",".join("?"*len(data))})'
                    cur.execute(query, data)
                    cur.executemany(query,
                                    values)
                    logging.info(f'Imported {USDA_file}')

        with self._conn as con:
            # Using a new connection so we are sure that the changes are
            # committed
            cur.executescript(bignut_queries.db_load_pt2)
