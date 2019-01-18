# .read load
# .read logic !! only if new database, it can wipe everything
# .read user
# .headers ON user for debugging

get_defined_nutrients = 'SELECT * FROM nutr_def;'

set_nutrient_DV = 'UPDATE nutr_def SET nutopt = ? where NutrDesc = ?;'

set_number_of_meals_to_analyze = 'UPDATED options SET defanal_am = 3;'
get_number_of_meals_to_analyze = 'SELECT defanal_am FROM options;'

get_weight_unit = 'SELECT grams FROM options;'
set_weight_unit = 'UPDATE options set grams = ?'

get_current_meal = 'SELECT currentmeal FROM options;'
set_current_meal = 'UPDATE options set currentmeal = ?;'

get_macro_pct = 'SELECT macropct from am_analysis_header;'

get_omega6_3_bal = 'SELECT n6balance from am_analysis_header;'

search_food = 'select NDB_No, Long_Desc from food_des where Long_Desc'\
              ' like ?;'
get_food_sorted_by_nutrient = """
    SELECT Long_Desc FROM fd_group NATURAL JOIN food_des NATURAL JOIN nut_data
    WHERE FdGrp_Desc like ? AND Nutr_No = ? ORDER BY Nutr_Val desc;
    """
get_food_preferred_weight = 'SELECT * FROM pref_Gm_Wgt WHERE NDB_No = ?;'
get_food_nutrients = 'SELECT * FROM nut_data WHERE NDB_No = ?;'
get_food_nutrients_based_on_weight = """
    SELECT
        meal_id,
        NDB_No,
        Gm_Wgt,
        nut_data.Nutr_No,
        Nutr_Val/100*Gm_Wgt
    FROM mealfoods JOIN nut_data USING (NDB_No)
    WHERE meal_id = ? and NDB_No = ?;
    """

get_meal_by_id = 'SELECT * FROM mealfoods WHERE meal_id = ?'

get_weight_log = 'select * from wlog;'
insert_weight_log = 'insert into wlog values (?, ?, null, null);'
clear_weight_log = 'insert into wlsummary select \'clear\';'
