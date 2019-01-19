import sqlite3
import bignut_queries
import logging
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
    def defined_nutrients(self):
        """
        :return: The defined nutrients
        :rtype: Sql cursor
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
        return tuple(bal.split('/'))

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


    def get_food_preferred_weight(self, NDB_No):
        """
        :param NDB_No: The food NDB_No
        :return: The food's preferred weight
        :rtype: float
        """
        cur = self._conn.cursor()
        cur.execute(bignut_queries.get_food_preferred_weight, (NDB_No,))

        return cur.fetchone()[0]

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
