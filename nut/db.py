import sqlite3
import bignut_queries
import logging
from datetime import datetime
from food import Food


class DBMan:
    def __init__(self, db_name='nut.db'):
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
    def current_meal_string(self):
        """
        :return: The current meal string
        :rtype: str
        """
        cur = self._conn.cursor()
        cur.execute(bignut_queries.get_current_meal_str)
        return cur.fetchone()[0]


    @property
    def calories(self):
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
        return cur.fetchone()[0]

    @property
    def last_bodyfat(self):
        """
        :return: The last bodyfat
        :rtype: float
        """
        cur = self._conn.cursor()
        cur.execute(bignut_queries.get_last_bodyfat)
        return cur.fetchone()[0]

    @property
    def defined_nutrients(self):
        """
        Selects
        Nutr_No|Units|Tagname|NutrDesc|dv_default|nutopt
        from nutr_def

        :return: A list of dictionaries containing the nutrients in the
            following form {'Nutr_No': (Units,
                Tagname, NutrDesc, dv_default, nutopt)}
        :rtype: list
        """
        cur = self._conn.cursor()
        cur.execute(bignut_queries.get_defined_nutrients)
        return {nutrient[0]: nutrient[1:]
                for nutrient in cur}

    @property
    def am_analysis_meal_no(self):
        """
        :return: The number of meals that will be analyzed
        :rtype: Int
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
        :param data: A tuple that contains the omega6 and omega3 ration
        """


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
            cur.execute(bignut_queries.search_food, (sql_like_string,))
            return cur

    def get_weight_log(self):
        """
        :return: The sql cursor
        :rtype: Sql cursor
        """
        cur = self._conn.cursor()
        cur.execute(bignut_queries.get_weight_log)
        return cur

    def insert_weight_log(self, weight, body_fat_perc):
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

    def set_nutrient_DV(self, nutrient_desc, value):
        """
        :param nutrient_desc: The nutrient description
        :param value: The new daily value
        """
        with self._conn as con:
            cur = con.cursor()
            cur.execute(bignut_queries.set_nutrient_DV,
                        (value, nutrient_desc))

    def get_meal_by_id(self, meal_id):
        """
        :param meal_id: The meal id in the following format %Y%m%d%meal_no
        :return: A list containing the foods
        :rtype: list
        """
        cur = self._conn.cursor()
        cur.execute(bignut_queries.get_meal_by_id, (meal_id,))

        return [Food(*x[:3]) for x in cur]

    @property
    def food_list(self):
        """
        :return: The food's list
        :rtype: List of tuples
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


    def get_food_preferred_weight(self, NDB_No):
        """
        :param NDB_No: The food NDB_No
        :return: The food's preferred weight
        :rtype: float
        """
        cur = self._conn.cursor()
        cur.execute(bignut_queries.get_food_preferred_weight, (NDB_No,))

        return cur.fetchone()[0]

    def get_nutrient_name(self, Nutr_No):
        cur = self._conn.cursor()
        cur.execute(bignut_queries.get_nutrient_name, (Nutr_No,))

        return str(cur.fetchone()[0])

    def get_food_nutrients_based_on_weight(self, NDB_No, weight):
        """
        :param NDB_No: The food NDB_no
        :param weight: The weight in grams
        :return: The sql cursor with the nutrients
        :rtype: Sql cursor
        """
        cur = self._conn.cursor()
        cur.execute(bignut_queries.get_food_nutrients_based_on_weight,
                    (NDB_No, weight))

        return cur

    def get_food_by_NDB_No(self, NDB_No):
        """
        :param NDB_No: The food NDB_no
        :return: The food with the fNDB_No
        :rtype: Tuple
        """
        cur = self._conn.cursor()
        cur.execute(bignut_queries.get_food_from_NDB_No,
                    (NDB_No,))

        return cur.fetchone()[0]

    def get_nutrient_story(self, Nutr_No, start_date, end_date):
        """
        :param Nutr_No: The nutrient number
        :param start_date: The start date in %Y%m%d format
        :param end_date: The end date in %Y%m%d format
        :return: An iterator that returns the following tuples
            (meal_id, nutrient_value)
        :rtype: Iterator
        """
        cur = self._conn.cursor()
        cur.execute(bignut_queries.get_nutrient_story,
                    (Nutr_No, start_date, end_date))
        return map(lambda x: (datetime.strptime(str(x[0]), '%Y%m%d'), x[1]),
                   cur)

    def get_food_nutrients_at_pref_weight(self, NDB_No):
        cur = self._conn.cursor()
        cur.execute(bignut_queries.get_food_nutrients_at_pref_weight,
                    (NDB_No,))

        return {x[0]: x[1:] for x in cur}

    def load_db(self, path):
        with self._conn as con:
            cur = con.cursor()
            cur.executescript(bignut_queries.db_load)
