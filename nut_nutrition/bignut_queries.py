# .read load
# .read logic !! only IF new database, it can wipe everything
# .read user
# .headers on use for debugging

# ---------------------- [NUTRIENT MANAGEMENT] --------------------------------

# Returns all the defined nutrients numbers
get_defined_nutrients = 'SELECT Nutr_No FROM nutr_def;'

# gets the specified field from the database
# the field can be ONe OF the following
# Units, Tagname, NutrDesc, dv_default, nutopt
get_nutrient_field_by_nutr_no = '''
SELECT {field}
FROM nutr_def
WHERE Nutr_No = :Nutr_No;
'''

# gets the specified field from the database
# the field can be ONe OF the following
# Units, Tagname, NutrDesc, dv_default, nutopt
set_nutrient_field_by_nutr_no = '''
UPDATE nutr_def
SET {field} =
    CASE WHEN :field_val IS NOT NULL THEN
        :field_val
    ELSE
        0
    END
WHERE Nutr_No = :Nutr_No;
'''

# need to implement generalized unit version
# Parameters: nutrient id, start date, END date
# Parameters Types: Nutr_No, %Y%m%d, %Y%m%d
get_nutrient_story = '''
SELECT day, ROUND(SUM(meal_total_nutrient))
FROM (
    SELECT meal_id/100 AS day,
        SUM(Gm_Wgt / 100.0 * nutrient.Nutr_Val) AS meal_total_nutrient
    FROM mealfoods JOIN nut_data nutrient USING (NDB_No)
    WHERE nutrient.Nutr_No = :Nutr_No
        AND meal_id >= :start_date || '00'
        AND meal_id <= :END_date || '99'
    GROUP by day, NDB_No)
GROUP by day;
'''

# ------------------------[ANALYSIS MANAGEMENT]--------------------------------
set_number_of_meals_to_analyze = 'UPDATE options SET defanal_am = ?;'
get_number_of_meals_to_analyze = 'SELECT defanal_am FROM options;'

get_max_number_of_meals = 'SELECT maxmeal FROM rm_analysis_header;'

get_rm_analysis_header = 'SELECT * FROM rm_analysis_header;'

# need to add default values for non present nutrients
get_rm_analysis = '''
SELECT rm_analysis.Nutr_No, Nutr_val, Units, NutrDesc,
    dvpct_offset + 100
FROM rm_analysis
LEFT JOIN rm_dv ON rm_analysis.Nutr_No = rm_dv.Nutr_No
NATURAL JOIN nutr_def NATURAL JOIN rm_analysis;
'''

get_am_analysis = '''
SELECT am_analysis.Nutr_No, Nutr_val, Units, NutrDesc,
    dvpct_offset + 100
FROM am_analysis
LEFT JOIN am_dv ON am_analysis.Nutr_No = am_dv.Nutr_No
NATURAL JOIN nutr_def NATURAL JOIN am_analysis;
'''
get_am_analysis_period = 'SELECT firstmeal, lastmeal FROM am_analysis_header;'


# to implement
get_day_meals = ''

get_weight_unit = 'SELECT grams FROM options;'
set_weight_unit = 'UPDATE options SET grams = ?'

get_current_meal = 'SELECT currentmeal FROM options;'
get_current_meal_food = '''
SELECT mf.NDB_No AS NDB_No, Long_Desc, mf.Gm_Wgt, Nutr_No
FROM mealfoods mf
NATURAL JOIN food_des
LEFT JOIN pref_Gm_Wgt pGW USING (NDB_No)
LEFT JOIN nutr_def USING (Nutr_No)
WHERE meal_id = (SELECT currentmeal FROM options)
ORDER BY Shrt_Desc;
'''
get_current_meal_str = 'SELECT cm_string FROM cm_string;'
set_current_meal = 'UPDATE options SET currentmeal = ?;'

get_meal_foods = '''
SELECT NDB_No, Gm_Wgt, Nutr_No as PCF_Nutr_No
FROM mealfoods
WHERE meal_id = :meal_id
'''


get_meal_from_offset_rel_to_current = """
-- ThIS gets the nth meal id relative to the current meal
SELECT meal_id
FROM (
    SELECT dense_rank() over (order by meal_id) as OFfSET, meal_id
    FROM mealfoods
    GROUP BY meal_id
)
WHERE OFfSET = (
    SELECT OFfSET+? FROM (
        SELECT dense_rank() over (order by meal_id) as OFfSET, meal_id
        FROM mealfoods
        GROUP BY meal_id
    ) WHERE meal_id = (SELECT currentmeal FROM options)
)
GROUP BY meal_id;
"""

get_macro_pct = 'SELECT carbs, proteins, fats FROM am_analysis_header;'

get_omega6_3_bal = 'SELECT omega6, omega3 FROM am_analysis_header;'

get_food_groups = 'SELECT FdGrp_Cd, FdGrp_Desc FROM fd_group;'

get_food_pcf = '''
SELECT Nutr_No
FROM mealfoods
WHERE CASE
        WHEN :meal_id IS NULL THEN
            (SELECT currentmeal FROM options)
        ELSE
            :meal_id
        END AND NDB_No = :NDB_No;
'''

set_food_pcf = '''
UPDATE mealfoods
SET Nutr_No = :Nutr_No
WHERE CASE
        WHEN :meal_id IS NULL THEN
            (SELECT currentmeal FROM options)
        ELSE
            :meal_id
        END AND NDB_No = :NDB_No;
'''
set_food_amount = '''
UPDATE mealfoods
SET Gm_Wgt = :Gm_Wgt
WHERE CASE
        WHEN :meal_id IS NULL THEN
            (SELECT currentmeal FROM options)
        ELSE
            :meal_id
        END AND NDB_No = :NDB_No;
'''


INSERT_food_INTO_meal = '''
INSERT OR REPLACE INTO mealfoods
    VALUES (CASE
                WHEN :meal_id IS NULL THEN
                    (SELECT currentmeal FROM options)
                ELSE :meal_id
            END,
            :NDB_No,
            CASE
                WHEN :Gm_Wgt IS NULL THEN
                    (SELECT Gm_Wgt
                     FROM pref_Gm_Wgt
                     WHERE NDB_No = :NDB_No)
                ELSE :Gm_Wgt
            END,
            :pcf_Nutr_No);
'''

remove_food_from_meal = '''
DELETE FROM mealfoods
WHERE
    CASE WHEN :meal_id IS NOT NULL THEN
        meal_id = :meal_id
    ELSE
        meal_id = (SELECT currentmeal FROM options)
    END
    AND NDB_No = :NDB_No;
'''

get_food_list = 'SELECT NDB_No, Long_Desc FROM food_des;'
get_food_from_ndb_no = 'SELECT * FROM food_des WHERE NDB_No = :NDB_No;'
search_food = 'SELECT NDB_No, Long_Desc FROM food_des WHERE Long_Desc'\
    ' like :long_desc;'
get_food_sorted_by_nutrient = """
    SELECT Long_Desc FROM fd_group NATURAL JOIN food_des NATURAL JOIN nut_data
    WHERE FdGrp_Desc like ? AND Nutr_No = ? ORDER BY Nutr_Val desc;
    """
get_food_preferred_weight = 'SELECT * FROM pref_Gm_Wgt WHERE NDB_No = ?;'
get_food_nutrients = '''
SELECT
    Nutr_No,
    CASE WHEN :Gm_Wgt IS NULL THEN
        Nutr_Val
    ELSE
        Nutr_Val/100*:Gm_Wgt
    END as Nutr_Val,
    Units,
    NutrDesc,
    CASE WHEN :Gm_Wgt IS NULL THEN
        Nutr_Val / am_dv.dv * 100
    ELSE
        Nutr_Val * :Gm_Wgt / am_dv.dv
    END AS dv
FROM nutr_def
NATURAL JOIN nut_data
LEFT JOIN am_dv USING (Nutr_No)
NATURAL JOIN food_des
NATURAL JOIN pref_Gm_Wgt
WHERE NDB_No = :NDB_No;
'''

get_nutrient = 'SELECT * FROM nutr_def WHERE Nutr_No = ?;'

foods_ranked_per_100_grams = '''
SELECT NDB_No, FdGrp_Cd, Long_Desc, 100, 'g', Nutr_val, Units
FROM food_des
NATURAL JOIN nut_data
NATURAL JOIN nutr_def
WHERE Nutr_No = :Nutr_val AND
    CASE :FdGrp_Cd
        -- If the parameter IS 0, no group filter should be applied
        WHEN 0 THEN 1
        ELSE FdGrp_Cd = :FdGrp_Cd
    END
ORDER BY Nutr_val DESC;
'''

foods_ranked_per_100_calories = '''
SELECT NDB_No, FdGrp_Cd, Long_Desc, Gm_Wgt, 100, Nutr_val, Units
FROM food_des
NATURAL JOIN nut_data
NATURAL JOIN nutr_def
WHERE Nutr_No = :Nutr_val AND
    CASE :FdGrp_Cd
        -- If the parameter IS 0, no group filter should be applied
        WHEN 0 THEN 1
        ELSE FdGrp_Cd = :FdGrp_Cd
    END
ORDER BY Nutr_val DESC;
'''

foods_ranked_per_1_aproximate_serving = '''
'''

# Must implement period restriction
foods_ranked_per_daily_recorded_meals = '''
SELECT mealfoods.NDB_No,
    FdGrp_Cd,
    LONg_desc,
    Gm_Wgt,
    (Gm_Wgt/100*nut_data.Nutr_Val) as nutrient,
    Units
FROM mealfoods
JOIN nut_data
ON mealfoods.NDB_No=nut_data.NDB_No
NATURAL JOIN food_des
NATURAL JOIN nutr_def
WHERE nut_data.Nutr_No = :Nutr_No AND
    CASE :FdGrp_Cd
        -- If the parameter IS 0, no group filter should be applied
        WHEN 0 THEN 1
        ELSE FdGrp_Cd = :FdGrp_Cd
    END
ORDER BY nutrient DESC;
'''

get_nutrient_name = 'SELECT NutrDesc FROM nutr_def WHERE Nutr_No = ?;'


get_nutrient_by_nutr_no = '''
SELECT Tagname, NutrDesc, dv_default, Units, nutopt
FROM nutr_def
WHERE Nutri_No = :Nutr_No
'''


get_meal_by_id = 'SELECT * FROM mealfoods WHERE meal_id = ?'

get_weight_log = 'SELECT * FROM wlog;'
get_weight_summary = 'SELECT verbiage FROM wlsummary;'
get_last_weight = 'SELECT weight FROM wlog ORDER BY wldate DESC LIMIT 1;'
get_last_bodyfat = 'SELECT bodyfat FROM wlog ORDER BY wldate DESC LIMIT 1;'
insert_weight_log = 'INSERT INTO wlog values (?, ?, NULL, NULL);'
clear_weight_log = 'INSERT INTO wlsummary SELECT \'clear\';'

get_personal_nutrient_dv = """
SELECT dv
FROM am_dv
WHERE Nutr_No = ?;
"""

# ---------------------------[DB MANAGEMENT]-----------------------------------
get_db_user_version = 'PRAGMA user_version;'

# Database initialization order
# 1. init_pragmas: Performance enhancements and recursive triggers
# 2. create_data_tables: Creates all the tables that will contain the user's
#    food data
# 3. create_logic_tables: Creates all the tables that will contain BigNut's
#    logic statuses
# 4. Load USDA data:
#   1. usda_create_temp_tables: Creates all the temporary tables necessary
#      for loading the USDA data
#   2. usda_load_process: Processes all the USDA data in the temporary tables
#      and saves the in the final tables
#   3. usda_drop_temp_tables: Deletes the temporary tables that are no longer
#      needed
# 5. create_logic_views: Creates the views necessary for data processing
# 6. init_logic: Initializes the data processing logic
# 7. Create the data processing triggers:
#   1. create_food_archive_triggers
#   2. create_weight_log_triggers
#   3. create_food_weight_triggers
#   4. create_meal_foods_triggers

# User Database initialization order
# 1. init_pragmas
# 2. create_temp_views
# 3. create_temp_data_tables
# 4. user_init_query
# 5. Create the data processing triggers:
#   1. create_temp_pcf_triggers
#   2. create_temp_pref_weight_triggers
#   3. create_temp_currentmeal_triggers
#   4. create_temp_theusual_triggers
#   5. create_temp_autocal_triggers

# Database data loading order
# --------------------------[BIG NUT QUERIES]----------------------------------
db_user_version = 39

# !!! db_user_version can inject SQL code with this substitution
init_pragmas = f"""
PRAGMA user_version = {db_user_version};

-- IMPORTANT, WITHOUT THIS NUT WON'T WORK
PRAGMA recursive_triggers = 1;

-- These pragmas enhance performance
PRAGMA journal_mode = WAL;
PRAGMA threads = 4;
"""

# -----------------------------[TEMP VIEWS]------------------------------------
create_temp_views = """
CREATE TEMP VIEW pref_Gm_Wgt AS
SELECT NDB_No,
       Seq,
       Gm_Wgt / origGm_Wgt * Amount AS Amount,
       Msre_Desc,
       Gm_Wgt,
       origSeq,
       origGm_Wgt,
       Amount AS origAmount
FROM weight
NATURAL JOIN (SELECT NDB_No, MIN(Seq) AS Seq FROM weight GROUP BY NDB_No);

-- Displays foods compositions
CREATE TEMP VIEW view_foods AS
SELECT NutrDesc,
       NDB_No,
       SUBSTR(Shrt_Desc, 1, 45),
       ROUND(Nutr_Val * Gm_Wgt / 100.0, 1) AS Nutr_Val,
       Units,
       CAST(CAST(ROUND(Nutr_Val * Gm_Wgt / dv) AS int) AS text)
         || '% DV' AS dv
FROM nutr_def
NATURAL JOIN nut_data
LEFT JOIN am_dv USING (Nutr_No)
NATURAL JOIN food_des
NATURAL JOIN pref_Gm_Wgt;

-- Dislays the current meal
CREATE TEMP VIEW currentmeal AS
SELECT mf.NDB_No AS NDB_No,
  CASE
    -- If we're using grams
    WHEN (SELECT grams FROM options) THEN
      CAST(CAST (round(mf.Gm_Wgt) AS int) AS text) || ' g'
    ELSE
    -- otherwise we're using ounces
      CAST(ROUND(mf.Gm_Wgt / 28.35 * 8.0) / 8.0 AS text) || ' oz'
    END
    || ' (' ||
    CAST(ROUND(
      CASE WHEN mf.Gm_Wgt <= 0.0 OR mf.Gm_Wgt != pGW.Gm_Wgt THEN
        mf.Gm_Wgt / origGm_Wgt * origAmount
      ELSE
        Amount
      END * 8.0) / 8.0 AS text)
      || ' ' || Msre_Desc || ') ' || Shrt_Desc || ' ' AS Gm_Wgt,
      NutrDesc
FROM mealfoods mf
NATURAL JOIN food_des
LEFT JOIN pref_Gm_Wgt pGW USING (NDB_No)
LEFT JOIN nutr_def USING (Nutr_No)
WHERE meal_id = (SELECT currentmeal FROM options)
ORDER BY Shrt_Desc;

-- Displays the food list of a saved menu
CREATE TEMP VIEW theusual AS
SELECT meal_name,
       NDB_No,
       Gm_Wgt,
       NutrDesc
FROM z_tu
NATURAL JOIN pref_Gm_Wgt
LEFT JOIN nutr_def USING (Nutr_No);

-- Displays the meals composition
CREATE TEMP VIEW nut_in_meals AS
SELECT NutrDesc,
       ROUND(SUM(
         Gm_Wgt * Nutr_Val / 100.0 /
         (SELECT mealcount FROM am_analysis_header) *
         (SELECT meals_per_day FROM options)),
       1) AS Nutr_Val,
       Units,
       mf.ndb_no,
       Shrt_Desc
FROM mealfoods mf
JOIN food_des USING (NDB_No)
JOIN nutr_def nd
JOIN nut_data DATA ON mf.NDB_No = data.NDB_No
AND nd.Nutr_No = data.Nutr_No
WHERE meal_id >= (SELECT firstmeal FROM am_analysis_header)
GROUP BY mf.NDB_No, NutrDesc
ORDER BY Nutr_Val DESC;

CREATE TEMP VIEW nutdv_in_meals AS
SELECT NutrDesc,
       CAST(CAST(ROUND(SUM(
         Gm_Wgt * Nutr_Val / dv /
         (SELECT mealcount FROM am_analysis_header) *
         (SELECT meals_per_day FROM options))) AS int)
       AS text) || '%' AS val,
       mf.ndb_no,
       Shrt_Desc
FROM mealfoods mf
JOIN food_des USING (NDB_No)
JOIN nutr_def nd
JOIN nut_data DATA ON mf.NDB_No = data.NDB_No AND nd.Nutr_No = data.Nutr_No
JOIN am_dv ON nd.Nutr_No = am_dv.Nutr_No
WHERE meal_id >= (SELECT firstmeal FROM am_analysis_header)
GROUP BY mf.NDB_No,
         NutrDesc
ORDER BY cast(val AS int) DESC;

CREATE TEMP VIEW daily_food AS
SELECT
  CAST(ROUND(
    (SUM(mf.Gm_Wgt) / mealcount * meals_per_day)
    / origGm_Wgt * origAmount * 8.0) / 8.0 AS text)
  || ' ' || Msre_Desc || ' ' || Shrt_Desc AS food
FROM mealfoods mf
NATURAL JOIN food_des
JOIN pref_Gm_Wgt USING (NDB_No)
JOIN am_analysis_header
WHERE meal_id BETWEEN firstmeal AND lastmeal
GROUP BY NDB_No
ORDER BY Shrt_Desc;

CREATE TEMP VIEW daily_food1 AS
SELECT CAST(
    ROUND(SUM(8.0 * gm_wgt / 28.35 / mealcount * meals_per_day)) / 8.0
    AS text)
  || ' oz ' || Long_desc
FROM mealfoods
NATURAL JOIN food_des
JOIN am_analysis_header
WHERE meal_id BETWEEN firstmeal AND lastmeal
GROUP BY ndb_no
ORDER BY long_desc;

CREATE TEMP VIEW nut_big_contrib AS
SELECT shrt_desc,
       nutrdesc,
       MAX(nutr_val),
       units
FROM (SELECT * FROM nut_in_meals ORDER BY nutrdesc ASC, nutr_val DESC)
GROUP BY nutrdesc
ORDER BY shrt_desc;

CREATE TEMP VIEW nutdv_big_contrib AS
SELECT nut_big_contrib.*
FROM nut_big_cONtrib
NATURAL JOIN nutr_def
WHERE dv_default > 0.0
ORDER BY shrt_desc;

CREATE TEMP VIEW nut_in_100g AS
SELECT NutrDesc,
       FdGrp_Cd,
       f.NDB_No,
       Long_Desc,
       Nutr_Val
FROM food_des f
JOIN nutr_def n
JOIN nut_data d ON f.NDB_No = d.NDB_No
  AND n.Nutr_No = d.Nutr_No
ORDER BY Nutr_Val ASC;

CREATE TEMP VIEW nut_in_100cal AS
SELECT NutrDesc,
       FdGrp_Cd,
       f.NDB_No,
       Long_Desc,
       100.0 * d.Nutr_Val / c.Nutr_Val AS Nutr_Val
FROM food_des f
JOIN nutr_def n
JOIN nut_data d ON f.NDB_No = d.NDB_No
  AND n.Nutr_No = d.Nutr_No
JOIN nut_data c ON f.NDB_No = c.NDB_No
  AND c.Nutr_No = 208
ORDER BY Nutr_Val ASC;

CREATE TEMP VIEW shopview AS
SELECT 'Shopping LISt ' || group_concat(n || ': ' || item || ' ('
  || store || ')', ' ')
FROM (SELECT * FROM shopping ORDER BY store, item);

CREATE TEMP VIEW food_cost AS
SELECT ndb_no,
       ROUND(SUM(gm_wgt / gm_size * cost * meals_per_day / mealcount),
         2) AS cost,
       long_desc
FROM mealfoods
NATURAL JOIN food_des
NATURAL JOIN cost
JOIN am_analysis_header
WHERE meal_id BETWEEN firstmeal AND lastmeal
GROUP BY ndb_no
ORDER BY cost DESC;

CREATE TEMP VIEW food_cost_cm AS
SELECT round(sum(gm_wgt / gm_size * cost), 2) AS cost
FROM mealfoods
NATURAL JOIN cost
JOIN options
WHERE meal_id = currentmeal;

CREATE TEMP VIEW food_cost_total AS
SELECT sum(cost) AS cost
FROM food_cost;

CREATE TEMP VIEW max_chick AS WITH DATA (ndb_no,
                                         shrt_desc,
                                         pamount,
                                         famount,
                                         msre_desc) AS
  (SELECT f.NDB_No,
    Shrt_Desc,
    ROUND(
      (SELECT dv / 3.0 - 15.0 FROM am_dv WHERE nutr_no = 203)
      / p.Nutr_Val * 100 / origGm_Wgt * Amount * 8) / 8.0,
    ROUND(
      (SELECT dv / 3.0 - 17.39 FROM am_dv WHERE nutr_no = 204)
      / fat.Nutr_Val * 100 / origGm_Wgt * Amount * 8) / 8.0,
    Msre_Desc
   FROM food_des f
   JOIN nut_data p ON f.ndb_no = p.ndb_no
     AND p.nutr_no = 203
   JOIN nut_data fat ON f.ndb_no = fat.ndb_no
     AND fat.nutr_no = 204
   NATURAL JOIN weight
   WHERE f.NDB_No IN
     (SELECT ndb_no FROM food_des
      WHERE ndb_no > 99000
        AND Shrt_Desc LIKE '%chick%mic%'
      UNION SELECT 5088)
     AND Seq =
       (SELECT MIN(Seq) FROM weight WHERE weight.NDB_No = f.NDB_No))
SELECT ndb_no,
  shrt_desc,
  CASE
    WHEN pamount <= famount THEN
      pamount
    ELSE
      famount
    END,
  msre_desc
FROM DATA;

CREATE TEMP VIEW daily_macros AS
SELECT DAY,
  ROUND(SUM(calories)) AS calories,
  CAST(ROUND(100.0 * SUM(procals) / SUM(calories)) AS int) || '/'
    || CAST(ROUND(100.0 * SUM(chocals) / SUM(calories)) AS int) || '/'
    || CAST(ROUND(100.0 * SUM(fatcals) / SUM(calories)) AS int) AS macropct,
  ROUND(SUM(protein)) AS protein,
  ROUND(SUM(nfc)) AS nfc,
  ROUND(SUM(fat)) AS fat,
  bodycomp
FROM
  (SELECT meal_id / 100 AS DAY,
     NDB_No,
     SUM(Gm_Wgt / 100.0 * cals.Nutr_Val) AS calories,
     SUM(Gm_Wgt / 100.0 * pro.Nutr_Val) AS protein,
     SUM(Gm_Wgt / 100.0 * crb.Nutr_Val) AS nfc,
     SUM(Gm_Wgt / 100.0 * totfat.Nutr_Val) AS fat,
     SUM(Gm_Wgt / 100.0 * pcals.Nutr_Val) AS procals,
     SUM(Gm_Wgt / 100.0 * ccals.Nutr_Val) AS chocals,
     SUM(Gm_Wgt / 100.0 * fcals.Nutr_Val) AS fatcals,
     bodycomp
   FROM mealfoods
   JOIN nut_data cals USING (NDB_No)
   JOIN nut_data pro USING (NDB_No)
   JOIN nut_data crb USING (NDB_No)
   JOIN nut_data totfat USING (NDB_No)
   JOIN nut_data pcals USING (NDB_No)
   JOIN nut_data ccals USING (NDB_No)
   JOIN nut_data fcals USING (NDB_No)
   LEFT JOIN (SELECT * FROM wlview GROUP BY wldate) ON DAY = wldate
   WHERE cals.Nutr_No = 208
     AND pro.Nutr_No = 203
     AND crb.Nutr_No = 2000
     AND totfat.Nutr_No = 204
     AND pcals.Nutr_No = 3000
     AND ccals.Nutr_No = 3002
     AND fcals.Nutr_No = 3001
   GROUP BY DAY, NDB_No)
GROUP BY DAY;

CREATE TEMP VIEW ranalysis AS
SELECT NutrDesc,
       ROUND(Nutr_Val, 1) || ' ' || Units,
       CAST(CAST(ROUND(100.0 + dvpct_offset) AS int) AS text) || '%'
FROM rm_analysis
NATURAL JOIN rm_dv
NATURAL JOIN nutr_def
ORDER BY dvpct_offset DESC;

CREATE TEMP VIEW analysis AS
SELECT NutrDesc,
       ROUND(Nutr_Val, 1) || ' ' || Units,
       CAST(CAST(ROUND(100.0 + dvpct_offset) AS int) AS text) || '%'
FROM am_analysis
NATURAL JOIN am_dv
NATURAL JOIN nutr_def
ORDER BY dvpct_offset DESC;

CREATE TEMP VIEW cm_string AS WITH cdate (cdate, meal) AS
  (SELECT SUBSTR(currentmeal, 1, 4) || '-' || SUBSTR(currentmeal, 5, 2)
     || '-' || SUBSTR(currentmeal, 7, 2),
     CAST(SUBSTR(currentmeal, 9, 2) AS int)
   FROM options)
SELECT CASE
  WHEN w = 0 THEN 'Sun'
  WHEN w = 1 THEN 'Mon'
  WHEN w = 2 THEN 'Tue'
  WHEN w = 3 THEN 'Wed'
  WHEN w = 4 THEN 'Thu'
  WHEN w = 5 THEN 'Fri'
  WHEN w = 6 THEN 'Sat'
END || ' ' ||
CASE
  WHEN m = 1 THEN 'Jan'
  WHEN m = 2 THEN 'Feb'
  WHEN m = 3 THEN 'Mar'
  WHEN m = 4 THEN 'Apr'
  WHEN m = 5 THEN 'May'
  WHEN m = 6 THEN 'Jun'
  WHEN m = 7 THEN 'Jul'
  WHEN m = 8 THEN 'Aug'
  WHEN m = 9 THEN 'Sep'
  WHEN m = 10 THEN 'Oct'
  WHEN m = 11 THEN 'Nov'
  ELSE 'Dec'
END || ' ' || d || ', ' || y || ' #' || meal AS cm_string
FROM
  (SELECT CAST(STRFTIME('%w', cdate) AS int) AS w,
          CAST(STRFTIME('%m', cdate) AS int) AS m,
          CAST(STRFTIME('%d', cdate) AS int) AS d,
          STRFTIME('%Y', cdate) AS y,
          meal
   FROM cdate);
"""

# -----------------------[LOGIC DELETION QUERIES]------------------------------

# Call when upgrading from one database version to another
drop_triggers = """
DROP TRIGGER IF EXISTS before_mealfoods_insert_pcf;
DROP TRIGGER IF EXISTS mealfoods_insert_pcf;
DROP TRIGGER IF EXISTS mealfoods_update_pcf;
DROP TRIGGER IF EXISTS mealfoods_delete_pcf;
DROP TRIGGER IF EXISTS update_nutopt_pcf;
DROP TRIGGER IF EXISTS update_fapu1_pcf;
DROP TRIGGER IF EXISTS pref_weight_gm_wgt;
DROP TRIGGER IF EXISTS pref_weight_amount;
DROP TRIGGER IF EXISTS currentmeal_insert;
DROP TRIGGER IF EXISTS currentmeal_delete;
DROP TRIGGER IF EXISTS currentmeal_upd_Gm_Wgt;
DROP TRIGGER IF EXISTS currentmeal_upd_pcf;
DROP TRIGGER IF EXISTS theusual_insert;
DROP TRIGGER IF EXISTS theusual_delete;
DROP TRIGGER IF EXISTS autocal_cutting;
DROP TRIGGER IF EXISTS autocal_bulking;
DROP TRIGGER IF EXISTS autocal_cycle_end;
DROP TRIGGER IF EXISTS autocal_initialization;
DROP TRIGGER IF EXISTS rm_analysis_trigger;
DROP TRIGGER IF EXISTS am_dv_trigger;
DROP TRIGGER IF EXISTS PCF_processing;
DROP TRIGGER IF EXISTS defanal_am_trigger;
DROP TRIGGER IF EXISTS currentmeal_trigger;
DROP TRIGGER IF EXISTS z_n6_insert_trigger;
DROP TRIGGER IF EXISTS z_n6_reduce6_trigger;
DROP TRIGGER IF EXISTS z_n6_reduce3_trigger;
DROP TRIGGER IF EXISTS insert_mealfoods_trigger;
DROP TRIGGER IF EXISTS delete_mealfoods_trigger;
DROP TRIGGER IF EXISTS update_mealfoods2weight_trigger;
DROP TRIGGER IF EXISTS insert_mealfoods2weight_trigger;
DROP TRIGGER IF EXISTS update_weight_seq;
DROP TRIGGER IF EXISTS insert_weight_seq;
DROP TRIGGER IF EXISTS wlog_insert;
DROP TRIGGER IF EXISTS clear_wlsummary;
DROP TRIGGER IF EXISTS mpd_archive;
DROP TRIGGER IF EXISTS am_analysis_header_trigger;
DROP TRIGGER IF EXISTS rm_analysis_header_trigger;
DROP TRIGGER IF EXISTS am_analysis_minus_currentmeal_trigger;
DROP TRIGGER IF EXISTS am_analysis_null_trigger;
DROP TRIGGER IF EXISTS rm_analysis_null_trigger;
DROP TRIGGER IF EXISTS am_analysis_trigger;
"""

# Call when upgrading from one database version to another
drop_views = """
DROP VIEW IF EXISTS pref_Gm_Wgt;
DROP VIEW IF EXISTS view_foods;
DROP VIEW IF EXISTS currentmeal;
DROP VIEW IF EXISTS theusual;
DROP VIEW IF EXISTS nut_in_meals;
DROP VIEW IF EXISTS nutdv_in_meals;
DROP VIEW IF EXISTS daily_food;
DROP VIEW IF EXISTS daily_food1;
DROP VIEW IF EXISTS nut_big_contrib;
DROP VIEW IF EXISTS nutdv_big_contrib;
DROP VIEW IF EXISTS nut_in_100g;
DROP VIEW IF EXISTS nut_in_100cal;
DROP VIEW IF EXISTS shopview;
DROP VIEW IF EXISTS food_cost;
DROP VIEW IF EXISTS food_cost_cm;
DROP VIEW IF EXISTS food_cost_total;
DROP VIEW IF EXISTS max_chick;
DROP VIEW IF EXISTS daily_macros;
DROP VIEW IF EXISTS ranalysis;
DROP VIEW IF EXISTS analysis;
DROP VIEW IF EXISTS cm_string;
DROP VIEW IF EXISTS am_analysis;
DROP VIEW IF EXISTS z_pcf;
DROP VIEW IF EXISTS z_wslope;
DROP VIEW IF EXISTS z_fslope;
DROP VIEW IF EXISTS z_span;
DROP VIEW IF EXISTS wlog;
DROP VIEW IF EXISTS wlview;
DROP VIEW IF EXISTS wlsummary;
"""

# Call before init logic
# !!!! THIS WILL WIPE EVERYTHING !!!
drop_logic_tables = """
DROP TABLE IF EXISTS z_vars1;
DROP TABLE IF EXISTS z_vars2;
DROP TABLE IF EXISTS z_vars3;
DROP TABLE IF EXISTS z_n6;
DROP TABLE IF EXISTS z_anal;
DROP TABLE IF EXISTS am_analysis_header;
DROP TABLE IF EXISTS am_dv;
DROP TABLE IF EXISTS rm_analysis_header;
DROP TABLE IF EXISTS rm_analysis;
DROP TABLE IF EXISTS rm_dv;
DROP TABLE IF EXISTS z_trig_ctl;
DROP TABLE IF EXISTS z_vars4;
"""

drop_user_tables = """
DROP TABLE IF EXISTS wlsave;
"""

# ---------------------------[TRIGGER CREATION]--------------------------------

create_analysis_triggers = """
---------------------------[ANALYSIS TRIGGERS]---------------------------------
-------------------------------[CHECKED]---------------------------------------
CREATE TRIGGER am_dv_trigger
  AFTER UPDATE OF am_dv ON z_trig_ctl WHEN NEW.am_dv = 1
  BEGIN
    UPDATE z_trig_ctl SET am_dv = 0;

    DELETE FROM am_dv;

    INSERT INTO am_dv SELECT Nutr_No, dv, 100.0 * Nutr_Val / dv - 100.0
    FROM (
      SELECT
        Nutr_No,
        Nutr_Val,
        CASE
          WHEN nutopt = 0.0 THEN
            dv_default
          WHEN nutopt = -1.0 AND Nutr_Val > 0.0 THEN
            Nutr_Val
          WHEN nutopt = -1.0 AND Nutr_Val <= 0.0 THEN
            dv_default
          ELSE
            nutopt
        END AS dv
    FROM nutr_def
    NATURAL JOIN am_analysis
    WHERE dv_default > 0.0
      AND (Nutr_No = 208 OR Nutr_No BETWEEN 301 AND 601 OR Nutr_No = 2008));

    INSERT INTO am_dv SELECT Nutr_No, dv, 100.0 * Nutr_Val / dv - 100.0
    FROM (SELECT Nutr_No, Nutr_Val, CASE WHEN nutopt = 0.0 AND (SELECT dv
    FROM am_dv
    WHERE Nutr_No = 208) > 0.0 THEN (SELECT dv
    FROM am_dv
    WHERE Nutr_No = 208) / 2000.0 * dv_default WHEN nutopt = 0.0 THEN dv_default WHEN nutopt = -1.0 AND Nutr_Val > 0.0 THEN Nutr_Val WHEN nutopt = -1.0 AND Nutr_Val <= 0.0 THEN (SELECT dv
    FROM am_dv
    WHERE Nutr_No = 208) / 2000.0 * dv_default ELSE nutopt END as dv
    FROM nutr_def NATURAL JOIN am_analysis
    WHERE Nutr_No = 291);
    DELETE
    FROM z_vars1;

    INSERT INTO z_vars1
    SELECT
      IFNULL(PROT_KCAL.Nutr_Val / PROCNT.Nutr_Val, 4.0),
      IFNULL(FAT_KCAL.Nutr_Val / FAT.Nutr_Val, 9.0),
      IFNULL(CHO_KCAL.Nutr_Val / CHOCDF.Nutr_Val, 4.0),
      IFNULL(ALC.Nutr_Val * 6.93, 0.0),
      IFNULL((FASAT.Nutr_Val + FAMS.Nutr_Val + FAPU.Nutr_Val) /
        FAT.Nutr_Val, 0.94615385),
      CASE
        WHEN ENERC_KCALopt.nutopt = -1 THEN
          208
        WHEN FATopt.nutopt <= 0.0 AND CHO_NONFIBopt.nutopt = 0.0 THEN
          2000
        ELSE
          204
      END
    FROM am_analysis PROT_KCAL
    JOIN am_analysis PROCNT
      ON PROT_KCAL.Nutr_No = 3000
      AND PROCNT.Nutr_No = 203
    JOIN am_analysis FAT_KCAL
      ON FAT_KCAL.Nutr_No = 3001
    JOIN am_analysis FAT
      ON FAT.Nutr_No = 204
    JOIN am_analysis CHO_KCAL
      ON CHO_KCAL.Nutr_No = 3002
    JOIN am_analysis CHOCDF
      ON CHOCDF.Nutr_No = 205
    JOIN am_analysis ALC
      ON ALC.Nutr_No = 221
    JOIN am_analysis FASAT
      ON FASAT.Nutr_No = 606
    JOIN am_analysis FAMS
      ON FAMS.Nutr_No = 645
    JOIN am_analysis FAPU
      ON FAPU.Nutr_No = 646
    JOIN nutr_def ENERC_KCALopt
      ON ENERC_KCALopt.Nutr_No = 208
    JOIN nutr_def FATopt
      ON FATopt.Nutr_No = 204
    JOIN nutr_def CHO_NONFIBopt
      ON CHO_NONFIBopt.Nutr_No = 2000;

    INSERT INTO am_dv
    SELECT Nutr_No, dv, 100.0 * Nutr_Val / dv - 100.0
    FROM (
      SELECT
        PROCNTnd.Nutr_No,
        CASE
          WHEN (PROCNTnd.nutopt = 0.0 AND ENERC_KCAL.dv > 0.0)
            OR (PROCNTnd.nutopt = -1.0 AND PROCNT.Nutr_Val <= 0.0) THEN
            PROCNTnd.dv_default * ENERC_KCAL.dv / 2000.0
        WHEN PROCNTnd.nutopt > 0.0 THEN
          PROCNTnd.nutopt
        ELSE
          PROCNT.Nutr_Val
        END AS dv, PROCNT.Nutr_Val
    FROM nutr_def PROCNTnd
    NATURAL JOIN am_analysis PROCNT
    JOIN z_vars1
    JOIN am_dv ENERC_KCAL
      ON ENERC_KCAL.Nutr_No = 208
    WHERE PROCNTnd.Nutr_No = 203);

    DELETE FROM z_vars2;

    INSERT INTO z_vars2
    SELECT
      am_fat_dv_not_boc,
      am_cho_nONfib_dv_not_boc,
      am_cho_nONfib_dv_not_boc + FIBTGdv
    FROM (
      SELECT
        CASE
          WHEN FATnd.nutopt = -1 AND FAT.Nutr_Val > 0.0 THEN
            FAT.Nutr_Val
          WHEN FATnd.nutopt > 0.0 THEN
            FATnd.nutopt
          ELSE
            FATnd.dv_default * ENERC_KCAL.dv / 2000.0
        END AS am_fat_dv_not_boc,
        CASE
          WHEN CHO_NONFIBnd.nutopt = -1 AND CHO_NONFIB.Nutr_Val > 0.0 THEN
            CHO_NONFIB.Nutr_Val
          WHEN CHO_NONFIBnd.nutopt > 0.0 THEN
            CHO_NONFIBnd.nutopt
          ELSE
            (CHOCDFnd.dv_default * ENERC_KCAL.dv / 2000.0) - FIBTG.dv
        END as am_cho_nONfib_dv_not_boc, FIBTG.dv as FIBTGdv
    FROM z_vars1
    JOIN am_analysis FAT ON FAT.Nutr_No = 204
    JOIN am_dv ENERC_KCAL ON ENERC_KCAL.Nutr_No = 208
    JOIN nutr_def FATnd ON FATnd.Nutr_No = 204
    JOIN nutr_def CHOCDFnd ON CHOCDFnd.Nutr_No = 205
    JOIN nutr_def CHO_NONFIBnd ON CHO_NONFIBnd.Nutr_No = 2000
    JOIN am_analysis CHO_NONFIB ON CHO_NONFIB.Nutr_No = 2000
    JOIN am_dv FIBTG ON FIBTG.Nutr_No = 291);

    DELETE FROM z_vars3;

    INSERT INTO z_vars3
    SELECT
      am_fat_dv_boc,
      am_chocdf_dv_boc,
      am_chocdf_dv_boc - FIBTGdv
    FROM (
      SELECT
        (ENERC_KCAL.dv - (PROCNT.dv * am_cals2gram_pro) -
          (am_chocdf_dv_not_boc * am_cals2gram_cho)) /
          am_cals2gram_fat as am_fat_dv_boc,
        (ENERC_KCAL.dv - (PROCNT.dv * am_cals2gram_pro) -
          (am_fat_dv_not_boc * am_cals2gram_fat)) /
          am_cals2gram_cho as am_chocdf_dv_boc,
        FIBTG.dv as FIBTGdv
    FROM z_vars1
    JOIN z_vars2
    JOIN am_dv ENERC_KCAL
      ON ENERC_KCAL.Nutr_No = 208
    JOIN am_dv PROCNT ON PROCNT.Nutr_No = 203
    JOIN am_dv FIBTG ON FIBTG.Nutr_No = 291);

    INSERT INTO am_dv
    SELECT
      Nutr_No,
      CASE
        WHEN balance_of_calories = 204 THEN
          am_fat_dv_boc
        ELSE
          am_fat_dv_not_boc
      END,
      CASE
        WHEN balance_of_calories = 204 THEN
          100.0 * Nutr_Val / am_fat_dv_boc - 100.0
        ELSE
          100.0 * Nutr_Val / am_fat_dv_not_boc - 100.0
        END
    FROM z_vars1
    JOIN z_vars2
    JOIN z_vars3
    JOIN nutr_def
      ON Nutr_No = 204
    NATURAL JOIN am_analysis;

    INSERT INTO am_dv
    SELECT
      Nutr_No,
      CASE
        WHEN balance_of_calories = 2000 THEN
          am_cho_nonfib_dv_boc
        ELSE
          am_cho_nONfib_dv_not_boc
      END,
      CASE
        WHEN balance_of_calories = 2000 THEN
          100.0 * Nutr_Val / am_cho_nonfib_dv_boc - 100.0
        ELSE
          100.0 * Nutr_Val / am_cho_nONfib_dv_not_boc - 100.0
        END
    FROM z_vars1
    JOIN z_vars2
    JOIN z_vars3
    JOIN nutr_def
      ON Nutr_No = 2000
    NATURAL JOIN am_analysis;

    INSERT INTO am_dv
    SELECT
      Nutr_No,
      CASE
        WHEN balance_of_calories = 2000 THEN
          am_chocdf_dv_boc
        ELSE
          am_chocdf_dv_not_boc
      END,
      CASE
        WHEN balance_of_calories = 2000 THEN
          100.0 * Nutr_Val / am_chocdf_dv_boc - 100.0
        ELSE
          100.0 * Nutr_Val / am_chocdf_dv_not_boc - 100.0
        END
    FROM z_vars1
    JOIN z_vars2
    JOIN z_vars3
    JOIN nutr_def
      ON Nutr_No = 205
    NATURAL JOIN am_analysis;

    INSERT INTO am_dv
    SELECT
      FASATnd.Nutr_No,
      CASE
        WHEN FASATnd.nutopt = -1.0 AND FASAT.Nutr_Val > 0.0 THEN
          FASAT.Nutr_Val
        WHEN FASATnd.nutopt > 0.0 THEN
          FASATnd.nutopt
        ELSE
          ENERC_KCAL.dv / 2000.0 * FASATnd.dv_default
      END,
      CASE
        WHEN FASATnd.nutopt = -1.0 AND FASAT.Nutr_Val > 0.0 THEN
          0.0
        WHEN FASATnd.nutopt > 0.0 THEN
          100.0 * FASAT.Nutr_Val / FASATnd.nutopt - 100.0
        ELSE
          100.0 * FASAT.Nutr_Val /
          (ENERC_KCAL.dv / 2000.0 * FASATnd.dv_default) - 100.0
        END
    FROM z_vars1
    JOIN nutr_def FASATnd
      ON FASATnd.Nutr_No = 606
    JOIN am_dv ENERC_KCAL
      ON ENERC_KCAL.Nutr_No = 208
    JOIN am_analysis FASAT
      ON FASAT.Nutr_No = 606;

    INSERT INTO am_dv
    SELECT
      FAPUnd.Nutr_No,
      CASE
        WHEN FAPUnd.nutopt = -1.0 AND FAPU.Nutr_Val > 0.0 THEN
          FAPU.Nutr_Val
        WHEN FAPUnd.nutopt > 0.0 THEN
          FAPUnd.nutopt
        ELSE
          ENERC_KCAL.dv * 0.04 / am_cals2gram_fat
        END,
      CASE
        WHEN FAPUnd.nutopt = -1.0 AND FAPU.Nutr_Val > 0.0 THEN
          0.0
        WHEN FAPUnd.nutopt > 0.0 THEN
          100.0 * FAPU.Nutr_Val / FAPUnd.nutopt - 100.0
        ELSE
          100.0 * FAPU.Nutr_Val / (ENERC_KCAL.dv * 0.04 /
          am_cals2gram_fat) - 100.0
        END
    FROM z_vars1
    JOIN nutr_def FAPUnd
      ON FAPUnd.Nutr_No = 646
    JOIN am_dv ENERC_KCAL
      ON ENERC_KCAL.Nutr_No = 208
    JOIN am_analysis FAPU
      ON FAPU.Nutr_No = 646;

    INSERT INTO am_dv
    SELECT
      FAMSnd.Nutr_No,
      (FAT.dv * am_fa2fat) - FASAT.dv - FAPU.dv, 100.0 * FAMS.Nutr_Val /
        ((FAT.dv * am_fa2fat) - FASAT.dv - FAPU.dv) - 100.0
    FROM z_vars1
    JOIN am_dv FAT
      ON FAT.Nutr_No = 204
    JOIN am_dv FASAT
      ON FASAT.Nutr_No = 606
    JOIN am_dv FAPU
      ON FAPU.Nutr_No = 646
    JOIN nutr_def FAMSnd
      ON FAMSnd.Nutr_No = 645
    JOIN am_analysis FAMS
      ON FAMS.Nutr_No = 645;

    DELETE FROM z_n6;

    INSERT INTO z_n6
    SELECT
      NULL,
        CASE
          WHEN FAPU1 = 0.0 THEN
            50.0
          WHEN FAPU1 < 15.0 THEN
            15.0
          WHEN FAPU1 > 90.0 THEN
            90.0
          ELSE
            FAPU1
        END,
        CASE
          WHEN FAPUval.Nutr_Val / FAPU.dv >= 1.0 THEN
            FAPUval.Nutr_Val / FAPU.dv
          ELSE
            1.0
        END,
        1,
        0,
        900.0 * MAX(SHORT3.Nutr_Val, 0.000000001),
        900.0 * MAX(SHORT6.Nutr_Val, 0.000000001)/ENERC_KCAL.dv/
        MAX(FAPUval.Nutr_Val / FAPU.dv, 1.0),
        900.0 * MAX(LONG3.Nutr_Val, 0.000000001)/ENERC_KCAL.dv,
        900.0 * MAX(LONG6.Nutr_Val, 0.000000001)/ENERC_KCAL.dv/
        MAX(FAPUval.Nutr_Val / FAPU.dv, 1.0),
        900.0 * (FASAT.dv + FAMS.dv + FAPU.dv -
          MAX(SHORT3.Nutr_Val,0.000000001) - MAX(SHORT6.Nutr_Val,0.000000001) -
          MAX(LONG3.Nutr_Val,0.000000001) - MAX(LONG6.Nutr_Val,0.000000001)) /
          ENERC_KCAL.dv
    FROM am_analysis SHORT3
    JOIN am_analysis SHORT6
      ON SHORT3.Nutr_No = 3005
      AND SHORT6.Nutr_No = 3003
    JOIN am_analysis LONG3
      ON LONG3.Nutr_No = 3006
    JOIN am_analysis LONG6
      ON LONG6.Nutr_No = 3004
    JOIN am_analysis FAPUval
      ON FAPUval.Nutr_No = 646
    JOIN am_dv FASAT
      ON FASAT.Nutr_No = 606
    JOIN am_dv FAMS
      ON FAMS.Nutr_No = 645
    JOIN am_dv FAPU
      ON FAPU.Nutr_No = 646
    JOIN am_dv ENERC_KCAL
      ON ENERC_KCAL.Nutr_No = 208
    JOIN options;

    DELETE FROM z_vars4;

    INSERT INTO z_vars4
    SELECT
      Nutr_No,
      CASE
        WHEN Nutr_Val > 0.0 AND reduce = 3 THEN
          Nutr_Val / pufa_reduction
        WHEN Nutr_Val > 0.0 AND reduce = 6 THEN
          Nutr_Val / pufa_reduction - Nutr_Val / pufa_reduction * 0.01 *
          (iter - 1)
        ELSE
          dv_default
      END,
      Nutr_Val
    FROM nutr_def
    NATURAL JOIN am_analysis
    JOIN z_n6
    WHERE Nutr_No in (2006, 2001, 2002);

    INSERT INTO z_vars4
    SELECT
      Nutr_No,
      CASE
        WHEN Nutr_Val > 0.0 AND reduce = 6 THEN
          Nutr_Val
        WHEN Nutr_Val > 0.0 AND reduce = 3 THEN
          Nutr_Val - Nutr_Val * 0.01 * (iter - 2)
        ELSE
          dv_default
      END,
      Nutr_Val
    FROM nutr_def
    NATURAL JOIN am_analysis
    JOIN z_n6
    WHERE Nutr_No in (2007, 2003, 2004, 2005);

    INSERT INTO am_dv
    SELECT
      Nutr_No,
      dv,
      100.0 * Nutr_Val / dv - 100.0
    FROM z_vars4;

    UPDATE am_analysis_header
    SET calories = (SELECT CAST (ROUND(dv) AS REAL)
      FROM am_dv
      WHERE Nutr_No = 208);

    DELETE FROM rm_dv;

    INSERT INTO rm_dv
    SELECT
      Nutr_No,
      dv,
      100.0 * Nutr_Val / dv - 100.0
    FROM rm_analysis
    NATURAL JOIN am_dv;

    REPLACE INTO mealfoods
    SELECT
      meal_id,
      NDB_No,
      Gm_Wgt - dv * dvpct_offset / (SELECT meals_per_day
        FROM options) / Nutr_Val,
      Nutr_No
    FROM rm_dv
    NATURAL JOIN nut_data
    NATURAL JOIN mealfoods
    WHERE ABS(dvpct_offset) > 0.001
    ORDER BY ABS(dvpct_offset) DESC LIMIT 1;

  END;


CREATE TRIGGER rm_analysis_trigger
  AFTER UPDATE OF rm_analysis ON z_trig_ctl
  WHEN NEW.rm_analysis = 1
  BEGIN
    UPDATE z_trig_ctl SET rm_analysis = 0;

    DELETE FROM rm_analysis;

    INSERT INTO rm_analysis
    SELECT
      Nutr_No,
      CASE
        WHEN SUM(mhectograms * Nutr_Val) IS NULL THEN
          1
        ELSE
          0
      END,
      IFNULL(SUM(mhectograms * Nutr_Val), 0.0)
      FROM (SELECT NDB_No, total(Gm_Wgt / 100.0 * meals_per_day) AS mhectograms
    FROM mealfoods
    JOIN am_analysis_header
    WHERE meal_id = currentmeal GROUP BY NDB_No)
    JOIN nutr_def
    NATURAL LEFT JOIN nut_data GROUP BY Nutr_No;

    UPDATE rm_analysis_header
    SET
      calories = (
        SELECT calories
        FROM am_analysis_header
      ),
      proteins = (
        SELECT CAST(IFNULL(
          ROUND(100 * PROT_KCAL.Nutr_Val / ENERC_KCAL.Nutr_Val, 0), 0) AS REAL)
        FROM rm_analysis ENERC_KCAL
        JOIN rm_analysis PROT_KCAL
          ON ENERC_KCAL.Nutr_No = 208 AND PROT_KCAL.Nutr_No = 3000
        JOIN rm_analysis CHO_KCAL
          ON CHO_KCAL.Nutr_No = 3002
        JOIN rm_analysis FAT_KCAL
          ON FAT_KCAL.Nutr_No = 3001)
      ),
      carbs = (
        SELECT CAST(IFNULL(
          ROUND(100 * CHO_KCAL.Nutr_Val / ENERC_KCAL.Nutr_Val, 0), 0) as REAL)
        FROM rm_analysis ENERC_KCAL
        JOIN rm_analysis PROT_KCAL
          ON ENERC_KCAL.Nutr_No = 208 AND PROT_KCAL.Nutr_No = 3000
        JOIN rm_analysis CHO_KCAL
          ON CHO_KCAL.Nutr_No = 3002
        JOIN rm_analysis FAT_KCAL
          ON FAT_KCAL.Nutr_No = 3001)
          ),
      fats = (
        SELECT CAST(IFNULL(
          ROUND(100 * FAT_KCAL.Nutr_Val / ENERC_KCAL.Nutr_Val, 0), 0) as REAL)
          FROM rm_analysis ENERC_KCAL
        JOIN rm_analysis PROT_KCAL
          ON ENERC_KCAL.Nutr_No = 208 AND PROT_KCAL.Nutr_No = 3000
        JOIN rm_analysis CHO_KCAL
          ON CHO_KCAL.Nutr_No = 3002
        JOIN rm_analysis FAT_KCAL
          ON FAT_KCAL.Nutr_No = 3001);



CREATE TRIGGER defanal_am_trigger
  AFTER UPDATE OF defanal_am
  ON options
  BEGIN
    UPDATE z_trig_ctl
    SET
      am_analysis_header = 1,
      am_analysis = 1,
      am_dv = 1,
      PCF_processing = 1,
      am_analysis_minus_currentmeal =
        CASE
          WHEN (SELECT mealcount FROM am_analysis_header) > 1 THEN
            1
          WHEN (SELECT mealcount FROM am_analysis_header) = 1
            AND (SELECT lastmeal FROM am_analysis_header) !=
            (SELECT currentmeal FROM am_analysis_header) THEN
            1
          ELSE
            0
        END,
      am_analysis_null =
        CASE
          WHEN (SELECT mealcount FROM am_analysis_header) > 1 THEN
            0
          WHEN (SELECT mealcount FROM am_analysis_header) = 1
            AND (SELECT lastmeal FROM am_analysis_header) !=
            (SELECT currentmeal FROM am_analysis_header) THEN
            0
          ELSE
            1
        END;
  END;

CREATE TRIGGER am_analysis_header_trigger
AFTER UPDATE OF am_analysis_header ON z_trig_ctl
WHEN NEW.am_analysis_header = 1
BEGIN
  UPDATE z_trig_ctl
  SET am_analysis_header = 0;

  DELETE FROM am_analysis_header;

  INSERT INTO am_analysis_header
  SELECT (
      SELECT COUNT(DISTINCT meal_id) FROM mealfoods
    ) AS maxmeal,
    COUNT(meal_id) AS mealcount,
    meals_per_day,
    IFNULL(MIN(meal_id), 0) AS firstmeal,
    IFNULL(MAX(meal_id), 0) AS lastmeal,
    currentmeal,
    NULL AS calories,
    NULL AS proteins,
    NULL AS carbs,
    NULL AS fats,
    NULL AS omega6,
    NULL AS omega3,
  FROM options
  LEFT JOIN (
      SELECT DISTINCT meal_id
      FROM mealfoods
      ORDER BY meal_id DESC
      LIMIT (SELECT defanal_am FROM options)
    );
END;

CREATE TRIGGER rm_analysis_header_trigger
AFTER UPDATE OF rm_analysis_header ON z_trig_ctl
WHEN NEW.rm_analysis_header = 1
BEGIN
  UPDATE z_trig_ctl
  SET rm_analysis_header = 0;

  DELETE FROM rm_analysis_header;

  INSERT INTO rm_analysis_header
  SELECT
    maxmeal,
    CASE
      WHEN NOT (SELECT COUNT(*) FROM mealfoods
        WHERE meal_id = currentmeal) THEN
        0
      ELSE
        1
    END AS mealcount,
    meals_per_day,
    currentmeal AS firstmeal,
    currentmeal AS lastmeal,
    currentmeal AS currentmeal,
    NULL AS calories,
    0 AS proteins,
    0 AS carbs,
    0 AS fats,
    0 AS omega6,
    0 AS omega3,
  FROM am_analysis_header;
END;

CREATE TRIGGER am_analysis_minus_currentmeal_trigger
AFTER UPDATE OF am_analysis_minus_currentmeal ON z_trig_ctl
WHEN NEW.am_analysis_minus_currentmeal = 1
BEGIN
  UPDATE z_trig_ctl
  SET am_analysis_minus_currentmeal = 0;

  DELETE FROM z_anal;

  INSERT INTO z_anal
    SELECT
      Nutr_No,
      CASE
        WHEN SUM(mhectograms * Nutr_Val) IS NULL THEN
          1
        ELSE
          0
      END,
      IFNULL(SUM(mhectograms * Nutr_Val), 0.0)
    FROM
      (
        SELECT
          NDB_No,
          total(Gm_Wgt / 100.0 / mealcount * meals_per_day) AS mhectograms
        FROM mealfoods
        JOIN am_analysis_header
        WHERE meal_id BETWEEN firstmeal AND lastmeal
          AND meal_id != currentmeal GROUP BY NDB_No
      )
    JOIN nutr_def
    NATURAL LEFT JOIN nut_data
    GROUP BY Nutr_No;
END;

CREATE TRIGGER am_analysis_null_trigger
AFTER UPDATE OF am_analysis_null ON z_trig_ctl
WHEN NEW.am_analysis_null = 1
BEGIN
  UPDATE z_trig_ctl
  SET am_analysis_null = 0;

  DELETE FROM z_anal;

  INSERT INTO z_anal
  VALUES
    SELECT
      nutr_no,
      1,
      0.0
    FROM nutr_def
    JOIN am_analysis_header
    WHERE firstmeal = currentmeal
      AND lastmeal = currentmeal,

    SELECT nutr_no, 0, 0.0
    FROM nutr_def
    JOIN am_analysis_header
    WHERE firstmeal != currentmeal
      OR lastmeal != currentmeal;

  UPDATE am_analysis_header
  SET proteins = 0,
    carbs = 0,
    fats = 0,
    omega6 = 0,
    omega3 = 0;
END;

CREATE TRIGGER rm_analysis_null_trigger
AFTER UPDATE OF rm_analysis_null ON z_trig_ctl
WHEN NEW.rm_analysis_null = 1
BEGIN
  UPDATE z_trig_ctl
  SET rm_analysis_null = 0;

  DELETE FROM rm_analysis;

  INSERT INTO rm_analysis
  SELECT
    Nutr_No,
    0,
    0.0
  FROM nutr_def;

  UPDATE rm_analysis_header
  SET
    calories = (SELECT calories FROM am_analysis_header),
    proteins = 0,
    carbs = 0,
    fats = 0,
    omega6 = 0,
    omega3 = 0;
END;


CREATE TRIGGER am_analysis_trigger
AFTER UPDATE OF am_analysis
ON z_trig_ctl
WHEN NEW.am_analysis = 1
BEGIN
  UPDATE z_trig_ctl
  SET am_analysis = 0;

  UPDATE am_analysis_header
    SET
      proteins = (
        SELECT
          CAST(
            IFNULL(ROUND(100 * PROT_KCAL.Nutr_Val / ENERC_KCAL.Nutr_Val, 0), 0)
            AS REAL
           )
        FROM am_analysis ENERC_KCAL
        JOIN am_analysis PROT_KCAL
          ON ENERC_KCAL.Nutr_No = 208 AND PROT_KCAL.Nutr_No = 3000
        JOIN am_analysis CHO_KCAL
          ON CHO_KCAL.Nutr_No = 3002
        JOIN am_analysis FAT_KCAL ON FAT_KCAL.Nutr_No = 3001
      ),
      carbs = (
        SELECT
          CAST(
            IFNULL(ROUND(100 * CHO_KCAL.Nutr_Val / ENERC_KCAL.Nutr_Val,0), 0)
            AS REAL
          )
        FROM am_analysis ENERC_KCAL
        JOIN am_analysis PROT_KCAL
          ON ENERC_KCAL.Nutr_No = 208
            AND PROT_KCAL.Nutr_No = 3000
        JOIN am_analysis CHO_KCAL
          ON CHO_KCAL.Nutr_No = 3002
        JOIN am_analysis FAT_KCAL ON FAT_KCAL.Nutr_No = 3001
      )
     fats = (
        SELECT
          CAST(
            IFNULL(round(100 * FAT_KCAL.Nutr_Val / ENERC_KCAL.Nutr_Val,0), 0)
            AS REAL
          )
        FROM am_analysis ENERC_KCAL
        JOIN am_analysis PROT_KCAL
          ON ENERC_KCAL.Nutr_No = 208
            AND PROT_KCAL.Nutr_No = 3000
        JOIN am_analysis CHO_KCAL
          ON CHO_KCAL.Nutr_No = 3002
        JOIN am_analysis FAT_KCAL ON FAT_KCAL.Nutr_No = 3001
      )
"""


create_pcf_views = """
CREATE VIEW z_pcf
AS SELECT
  meal_id,
  NDB_No,
  Gm_Wgt + dv / meals_per_day * dvpct_offset / Nutr_Val * -1.0 AS Gm_Wgt,
  Nutr_No
FROM mealfoods
NATURAL JOIN rm_dv
NATURAL JOIN nut_data
JOIN options
WHERE ABS(dvpct_offset) >= 0.05
ORDER BY ABS(dvpct_offset);
"""

create_pcf_triggers = """
CREATE TRIGGER PCF_processing
  AFTER UPDATE OF PCF_processing
  ON z_trig_ctl
  WHEN NEW.PCF_processing = 1
  BEGIN
    UPDATE z_trig_ctl
    SET PCF_processing = 0;

    REPLACE INTO mealfoods SELECT *
    FROM z_pcf limit 1;

    UPDATE z_trig_ctl
    SET block_mealfoods_delete_trigger = 0;
  END;
"""

create_omega_balance_triggers = """
-----------------------[OMEGA BALANCE TRIGGERS]--------------------------------

  CREATE TRIGGER z_n6_insert_trigger
  AFTER INSERT ON z_n6
  BEGIN
    UPDATE z_n6
    SET
      n6hufa = (SELECT 100.0 / (1.0 + 0.0441 / p6 *
        (1.0 + p3 / 0.0555 + h3 / 0.005 + o / 5.0 + p6 / 0.175)) + 100.0 /
        (1.0 + 0.7 / h6 * (1.0 + h3 / 3.0))),
      reduce = 0,
      iter = 0;
  END;

  CREATE TRIGGER z_n6_reduce6_trigger
  AFTER UPDATE ON z_n6
  WHEN NEW.n6hufa > OLD.FAPU1 AND NEW.iter < 100 AND NEW.reduce in (0, 6)
  BEGIN
    UPDATE z_n6
    SET
      iter = iter + 1,
      reduce = 6,
      n6hufa = (SELECT 100.0 / (1.0 + 0.0441 / (p6 - iter * .01 * p6) *
      (1.0 + p3 / 0.0555 + h3 / 0.005 + o / 5.0 + p6 / 0.175)) + 100.0 /
      (1.0 + 0.7 / (h6 - iter * .01 * h6) * (1.0 + h3 / 3.0)));
  END;

  CREATE TRIGGER z_n6_reduce3_trigger
  AFTER UPDATE OF n6hufa ON z_n6
  WHEN NEW.n6hufa < OLD.FAPU1 AND NEW.iter < 100 AND NEW.reduce in (0, 3)
  BEGIN
    UPDATE z_n6
    SET
      iter = iter + 1,
      reduce = 3,
      n6hufa = (SELECT 100.0 / (1.0 + 0.0441 / p6 *
      (1.0 + (p3 - iter * .01 * p3) / 0.0555 + (h3 - iter * .01 * h3) /
      0.005 + o / 5.0 + p6 / 0.175)) + 100.0 / (1.0 + 0.7 / h6 * (1.0 +
      (h3 - iter * .01 * h3) / 3.0)));
  END;


"""

create_temp_pcf_triggers = """
--------------------------------[PCF TRIGGERS]---------------------------------

CREATE TEMP TRIGGER before_mealfoods_insert_pcf
BEFORE INSERT ON mealfoods
WHEN NOT (SELECT block_mealfoods_insert_trigger FROM z_trig_ctl)
BEGIN
  UPDATE z_trig_ctl
  SET block_mealfoods_delete_trigger = 1;
END;

CREATE TEMP TRIGGER mealfoods_insert_pcf
AFTER INSERT ON mealfoods
WHEN NEW.meal_id = (SELECT currentmeal FROM options)
  AND NOT (SELECT block_mealfoods_insert_trigger FROM z_trig_ctl)
BEGIN
  UPDATE z_trig_ctl
  SET rm_analysis = 1,
    am_analysis = 1,
    am_dv = 1,
    PCF_processing = 1;
END;

CREATE TEMP TRIGGER mealfoods_update_pcf
AFTER UPDATE ON mealfoods
WHEN OLD.meal_id = (SELECT currentmeal FROM options)
BEGIN
  UPDATE z_trig_ctl
  SET rm_analysis = 1,
    am_analysis = 1,
    am_dv = 1,
    PCF_processing = 1;
END;

CREATE TEMP TRIGGER mealfoods_delete_pcf
AFTER DELETE ON mealfoods
WHEN OLD.meal_id = (SELECT currentmeal FROM options)
  AND NOT (SELECT block_mealfoods_delete_trigger FROM z_trig_ctl)
BEGIN
  UPDATE z_trig_ctl
  SET am_analysis_header = 1,
    rm_analysis = 1,
    am_analysis = 1,
    am_dv = 1,
    PCF_processing = 1;
END;

CREATE TEMP TRIGGER update_nutopt_pcf
AFTER UPDATE OF nutopt ON nutr_def
BEGIN
  UPDATE z_trig_ctl
  SET rm_analysis = 1,
    am_analysis = 1,
    am_dv = 1,
    PCF_processing = 1;
END;

CREATE TEMP TRIGGER update_FAPU1_pcf
AFTER UPDATE OF FAPU1 ON options
BEGIN
  UPDATE z_trig_ctl
  SET rm_analysis = 1,
    am_analysis = 1,
    am_dv = 1,
    PCF_processing = 1;
END;
"""

current_meal_triggers = """
CREATE TRIGGER currentmeal_trigger
  AFTER UPDATE OF currentmeal
  ON options
  BEGIN
    UPDATE mealfoods
    SET Nutr_No = NULL
    WHERE Nutr_No IS not NULL;

    UPDATE z_trig_ctl
      am_dv = 1,
      am_analysis_header = 1,
      am_analysis = 1,
      rm_analysis_header = 1,
      am_analysis_minus_currentmeal =
      CASE
        WHEN (SELECT mealcount FROM am_analysis_header) > 1 THEN
          1
        WHEN (SELECT mealcount FROM am_analysis_header) = 1
          AND (SELECT lastmeal FROM am_analysis_header) != (SELECT currentmeal
          FROM am_analysis_header) THEN
          1
        ELSE
          0
      END,
    am_analysis_null =
      CASE
        WHEN (SELECT mealcount FROM am_analysis_header) > 1 THEN
          0
        WHEN (SELECT mealcount FROM am_analysis_header) = 1 AND
          (SELECT lastmeal FROM am_analysis_header) != (SELECT currentmeal
          FROM am_analysis_header) THEN
          0
        ELSE
          1
        END,
    rm_analysis =
      CASE
        WHEN (SELECT mealcount FROM rm_analysis_header) = 1 THEN
          1
        ELSE
          0
        END,
    rm_analysis_null =
      CASE
        WHEN (SELECT mealcount FROM rm_analysis_header) = 0 THEN
          1
        ELSE
          0
        END;
  END;
"""

create_temp_pref_weight_triggers = """
CREATE TEMP TRIGGER pref_weight_Gm_Wgt
INSTEAD OF UPDATE OF Gm_Wgt ON pref_Gm_Wgt
WHEN NEW.Gm_Wgt > 0.0
BEGIN
  UPDATE weight
  SET Gm_Wgt = NEW.Gm_Wgt
  WHERE NDB_No = NEW.NDB_No
    AND Seq = (SELECT MIN(Seq) FROM weight WHERE NDB_No = NEW.NDB_No);
END;

CREATE TEMP TRIGGER pref_weight_Amount INSTEAD OF
UPDATE OF Amount ON pref_Gm_Wgt WHEN NEW.Amount > 0.0
BEGIN
  UPDATE weight
  SET Gm_Wgt = origGm_Wgt * NEW.Amount / Amount
  WHERE NDB_No = NEW.NDB_No
    AND Seq =
      (SELECT MIN(Seq) FROM weight WHERE NDB_No = NEW.NDB_No);

  UPDATE currentmeal
  SET Gm_Wgt = NULL
  WHERE NDB_No = NEW.NDB_No;
END;
"""

create_temp_currentmeal_triggers = """
CREATE TEMP TRIGGER currentmeal_INSERT INSTEAD OF
INSERT ON currentmeal
BEGIN
  UPDATE mealfoods
  SET Nutr_No = NULL
  WHERE Nutr_No = (
    SELECT Nutr_No
    FROM nutr_def
    WHERE NutrDesc = NEW.NutrDesc);

  INSERT OR REPLACE INTO mealfoods
  VALUES (
    (SELECT currentmeal FROM options),
    NEW.NDB_No,
    CASE
      WHEN NEW.Gm_Wgt IS NULL THEN
        (SELECT Gm_Wgt FROM pref_Gm_Wgt WHERE NDB_No = NEW.NDB_No)
      ELSE
        NEW.Gm_Wgt
    END,
    CASE
      WHEN NEW.NutrDesc IS NULL THEN
        NULL
    WHEN (SELECT count(*) FROM nutr_def WHERE NutrDesc = NEW.NutrDesc
      AND dv_default > 0.0) = 1 THEN
      (SELECT Nutr_No FROM nutr_def WHERE NutrDesc = NEW.NutrDesc)
    WHEN
      (SELECT count(*) FROM nutr_def WHERE Nutr_No = NEW.NutrDesc
      AND dv_default > 0.0) = 1 THEN
        NEW.NutrDesc
    ELSE
      NULL
    END);
END;

CREATE TEMP TRIGGER currentmeal_delete INSTEAD OF
DELETE ON currentmeal
BEGIN
  DELETE
  FROM mealfoods
  WHERE meal_id = (SELECT currentmeal FROM options) AND NDB_No = OLD.NDB_No;
END;

CREATE TEMP TRIGGER currentmeal_upd_Gm_Wgt INSTEAD OF
UPDATE OF Gm_Wgt ON currentmeal
BEGIN
  UPDATE mealfoods
  SET Gm_Wgt = CASE
    WHEN NEW.Gm_Wgt IS NULL THEN
      (SELECT Gm_Wgt FROM pref_Gm_Wgt WHERE NDB_No = NEW.NDB_No)
    ELSE
      NEW.Gm_Wgt
    END
  WHERE NDB_No = NEW.NDB_No
    AND meal_id = (SELECT currentmeal FROM options);
END;

CREATE TEMP TRIGGER currentmeal_upd_pcf INSTEAD OF
UPDATE OF NutrDesc ON currentmeal BEGIN
UPDATE mealfoods
SET Nutr_No = NULL
WHERE Nutr_No = (SELECT Nutr_No FROM nutr_def WHERE NutrDesc = NEW.NutrDesc);
  UPDATE mealfoods
  SET Nutr_No = (SELECT Nutr_No FROM nutr_def WHERE NutrDesc = NEW.NutrDesc)
  WHERE NDB_No = NEW.NDB_No
  AND meal_id =
    (SELECT currentmeal
     FROM options); END;
"""

create_temp_theusual_triggers = """
CREATE TEMP TRIGGER theusual_insert INSTEAD OF
INSERT ON theusual WHEN NEW.meal_name IS NOT NULL
AND NEW.NDB_No IS NULL
AND NEW.Gm_Wgt IS NULL
AND NEW.NutrDesc IS NULL BEGIN
DELETE
FROM z_tu
WHERE meal_name = NEW.meal_name;
  INSERT
  OR
  IGNORE INTO z_tu
SELECT NEW.meal_name,
       mf.NDB_No,
       mf.Nutr_No
FROM mealfoods mf
LEFT JOIN nutr_def
WHERE meal_id =
    (SELECT currentmeal
     FROM options); END;

CREATE TEMP TRIGGER theusual_delete INSTEAD OF
DELETE ON theusual WHEN OLD.meal_name IS NOT NULL BEGIN
DELETE
FROM z_tu
WHERE meal_name = OLD.meal_name; END;
"""

create_temp_autocal_triggers = """
CREATE TEMP TRIGGER autocal_cutting
AFTER INSERT
ON z_wl
WHEN (SELECT autocal = 2 and weightn > 1 and fatslope > 0.0
  and (weightslope - fatslope) > 0.0 from z_wslope, z_fslope, options)
BEGIN
  DELETE FROM wlsave;

  INSERT INTO wlsave
  SELECT
    weightyintercept,
    fatyintercept,
    wldate,
    span,
    today from z_wslope,
    z_fslope,
    z_span,
    (SELECT min(wldate) as wldate from z_wl where cleardate is null),
    (SELECT strftime('%Y%m%d', 'now', 'localtime') as today);

  UPDATE z_wl
  SET cleardate = (SELECT today FROM wlsave)
  WHERE cleardate IS NULL;

  INSERT INTO z_wl
  SELECT
    weight,
    ROUND(100.0 * fat / weight,1),
    today,
    NULL FROM wlsave;

  UPDATE nutr_def
  SET nutopt = nutopt - 20.0
  WHERE Nutr_No = 208;
END;


CREATE TEMP TRIGGER autocal_bulking AFTER
INSERT ON z_wl WHEN
  (SELECT autocal = 2
   AND weightn > 1
   AND fatslope < 0.0
   AND (weightslope - fatslope) < 0.0
   FROM z_wslope,
        z_fslope,
        options)
BEGIN
  DELETE FROM wlsave;

  INSERT INTO wlsave
  SELECT weightyintercept,
         fatyintercept,
         wldate,
         span,
         today
  FROM z_wslope,
       z_fslope,
       z_span,
    (SELECT MIN(wldate) AS wldate
     FROM z_wl
     WHERE cleardate IS NULL),
    (SELECT STRFTIME('%Y%m%d', 'now', 'localtime') AS today);

  UPDATE z_wl
  SET cleardate =
    (SELECT today
     FROM wlsave)
  WHERE cleardate IS NULL;
    INSERT INTO z_wl
  SELECT weight,
         round(100.0 * fat / weight, 1),
         today,
         NULL
  FROM wlsave;

  UPDATE nutr_def
  SET nutopt = nutopt + 20.0
  WHERE Nutr_No = 208;
END;

CREATE TEMP TRIGGER autocal_cycle_end
AFTER INSERT
ON z_wl
WHEN
  (SELECT autocal = 2
   AND weightn > 1
   AND fatslope > 0.0
   AND (weightslope - fatslope) < 0.0
   FROM z_wslope,
        z_fslope,
        options)
BEGIN
  DELETE FROM wlsave;
  INSERT INTO wlsave
  SELECT weightyintercept,
         fatyintercept,
         wldate,
         span,
         today
  FROM z_wslope,
       z_fslope,
       z_span,
    (SELECT MIN(wldate) AS wldate
     FROM z_wl
     WHERE cleardate IS NULL),
    (SELECT strftime('%Y%m%d', 'now', 'localtime') AS today);
  UPDATE z_wl
  SET cleardate =
    (SELECT today
     FROM wlsave)
  WHERE cleardate IS NULL;
    INSERT INTO z_wl
  SELECT weight,
         round(100.0 * fat / weight, 1),
         today,
         NULL
  FROM wlsave;
END;
"""

init_temp_triggers = """
---------------------------[VIEWS TRIGGERS]----------------------------------


"""

create_temp_data_tables = """
CREATE TEMP TABLE wlsave (
  weight REAL,
  fat REAL,
  wldate INTEGER,
  span INTEGER,
  today INTEGER
);
"""

create_data_tables = """
-- Nutrients definitions
CREATE TABLE IF NOT EXISTS nutr_def
  (
     nutr_no    INT PRIMARY KEY,
     units      TEXT,
     tagname    TEXT,
     nutrdesc   TEXT,
     dv_default REAL,
     nutopt     REAL
  );

-- Food groups
CREATE TABLE IF NOT EXISTS fd_group
  (
     fdgrp_cd   INT PRIMARY KEY,
     fdgrp_desc TEXT
  );

-- Food descriptions
CREATE TABLE IF NOT EXISTS food_des
  (
     ndb_no     INT PRIMARY KEY,
     fdgrp_cd   INT,
     long_desc  TEXT,
     shrt_desc  TEXT,
     ref_desc   TEXT,
     refuse     INTEGER,
     pro_factor REAL,
     fat_factor REAL,
     cho_factor REAL
  );

-- Food weights
CREATE TABLE IF NOT EXISTS weight
  (
     ndb_no     INT,
     seq        INT,
     amount     REAL,
     msre_desc  TEXT,
     gm_wgt     REAL,
     origseq    INT,
     origgm_wgt REAL,
     PRIMARY KEY(ndb_no, origseq)
  );

-- Foods compositions
CREATE TABLE IF NOT EXISTS nut_data
  (
     ndb_no   INT,
     nutr_no  INT,
     nutr_val REAL,
     PRIMARY KEY(ndb_no, nutr_no)
  );

-- User options
CREATE TABLE IF NOT EXISTS options
  (
     protect       INTEGER PRIMARY KEY,
     defanal_am    INTEGER DEFAULT 3,
     fapu1         REAL DEFAULT 0.0,
     meals_per_day INT DEFAULT 3,
     grams         INT DEFAULT 1,
     currentmeal   INT DEFAULT 0,
     wltweak       INTEGER DEFAULT 0,
     wlpolarity    INTEGER DEFAULT 0,
     autocal       INTEGER DEFAULT 0
  );

-- Current Meal foods
CREATE TABLE IF NOT EXISTS mealfoods
  (
     meal_id INT,
     ndb_no  INT,
     gm_wgt  REAL,
     nutr_no INT,
     PRIMARY KEY(meal_id, ndb_no)
  );

-- Shopping list (Not implemented)
/*
CREATE TABLE IF NOT EXISTS shopping
  (
     n INTEGER PRIMARY KEY,
     item TEXT,
     store TEXT
  );

-- Food cost list (Not implemented)
CREATE TABLE IF NOT EXISTS cost
  (
      ndb_no INT PRIMARY KEY,
      gm_size REAL,
      cost REAL
  );


-- Eating plans (Not implemented)
CREATE TABLE IF NOT EXISTS eating_plan (plan_name TEXT);

*/

-- Archived meal foods
CREATE TABLE IF NOT EXISTS archive_mealfoods
   (
      meal_id INT,
      NDB_No INT,
      Gm_Wgt REAL,
      meals_per_day INTEGER,
      PRIMARY KEY
        (
          meal_id DESC,
          NDB_No ASC,
          meals_per_day
        )
  );

-- Usual meal menu
CREATE TABLE IF NOT EXISTS z_tu
  (
    meal_name text,
    NDB_No int,
    Nutr_No int,
    primary key
      (
        meal_name,
        NDB_No
      ),
    UNIQUE
      (
        meal_name,
        Nutr_No
      )
  );

-- User's weight log
CREATE TABLE IF NOT EXISTS z_wl
  (
    weight real,
    bodyfat real,
    wldate int,
    cleardate int,
    primary key
      (
        wldate,
        cleardate
      )
  );
"""

create_logic_tables = """
CREATE TABLE z_vars1 (
  am_cals2gram_pro REAL,
  am_cals2gram_fat REAL,
  am_cals2gram_cho REAL,
  am_alccals REAL,
  am_fa2fat REAL,
  balance_of_calories INT
);

CREATE TABLE z_vars2 (
  am_fat_dv_not_boc REAL,
  am_cho_nONfib_dv_not_boc REAL,
  am_chocdf_dv_not_boc REAL
);

CREATE TABLE z_vars3 (
  am_fat_dv_boc REAL,
  am_chocdf_dv_boc REAL,
  am_cho_nonfib_dv_boc REAL
);

CREATE TABLE z_vars4 (
  Nutr_No INT,
  dv REAL,
  Nutr_Val REAL
);

-- Used for the calculation of the omega-6/omega-3 balance
CREATE TABLE z_n6 (
  n6hufa REAL,
  FAPU1 REAL,
  pufa_reduction REAL,
  iter INT,
  reduce INT,
  p3 REAL,
  p6 REAL,
  h3 REAL,
  h6 REAL,
  o REAL
);

CREATE TABLE z_anal (
  Nutr_No INT PRIMARY KEY,
  null_value INT,
  Nutr_Val REAL
);


CREATE TABLE am_analysis_header (
  maxmeal int,
  mealcount int,
  meals_per_day int,
  firstmeal integer,
  lastmeal integer,
  currentmeal integer,
  calories REAL,
  proteins REAL,
  carbs REAL,
  fats REAL,
  omega6 REAL,
  omega3 REAL
);


CREATE TABLE am_dv (
  Nutr_No int primary key asc,
  dv real,
  dvpct_offset real
);

CREATE TABLE rm_analysis_header (
  maxmeal int,
  mealcount int,
  meals_per_day int,
  firstmeal integer,
  lastmeal integer,
  currentmeal integer,
  calories REAL,
  proteins REAL,
  carbs REAL,
  fats REAL,
  omega6 REAL,
  omega3 REAL
);

CREATE TABLE rm_analysis (
  Nutr_No int primary key asc,
  null_value int,
  Nutr_Val real
);

CREATE TABLE rm_dv (
  Nutr_No int primary key asc,
  dv real,
  dvpct_offset real
);

CREATE TABLE z_trig_ctl (
  am_analysis_header INT DEFAULT 0,
  rm_analysis_header INT DEFAULT 0,
  am_analysis_minus_currentmeal INT DEFAULT 0,
  am_analysis_null INT DEFAULT 0,
  am_analysis INT DEFAULT 0,
  rm_analysis INT DEFAULT 0,
  rm_analysis_null int default 0,
  am_dv INT DEFAULT 0,
  PCF_processing INT DEFAULT 0,
  block_setting_preferred_weight INT DEFAULT 0,
  block_mealfoods_insert_trigger INT DEFAULT 0,
  block_mealfoods_delete_trigger INT DEFAULT 0
);
"""

usda_create_temp_tables = """
-- Temporary food groups table
CREATE TEMP TABLE tfd_group
  (
     fdgrp_cd   INT,
     fdgrp_desc TEXT
  );

-- Temporary food descriptions table
CREATE TEMP TABLE tfood_des
  (
     ndb_no      TEXT,
     fdgrp_cd    TEXT,
     long_desc   TEXT,
     shrt_desc   TEXT,
     comname     TEXT,
     manufacname TEXT,
     survey      TEXT,
     ref_desc    TEXT,
     refuse      INT,
     sciname     TEXT,
     n_factor    REAL,
     pro_factor  REAL,
     fat_factor  REAL,
     cho_factor  REAL
  );

-- Temporary food weights table
CREATE TEMP TABLE tweight
  (
     ndb_no     TEXT,
     seq        TEXT,
     amount     REAL,
     msre_desc  TEXT,
     gm_wgt     REAL,
     num_data_p INT,
     std_dev    REAL
  );

-- Temporary nutrient data
CREATE TEMP TABLE tnut_data
  (
     ndb_no        TEXT,
     nutr_no       TEXT,
     nutr_val      REAL,
     num_data_pts  INT,
     std_error     REAL,
     src_cd        TEXT,
     deriv_cd      TEXT,
     ref_ndb_no    TEXT,
     add_nutr_mark TEXT,
     num_studies   INT,
     min           REAL,
     max           REAL,
     df            INT,
     low_eb        REAL,
     up_eb         REAL,
     stat_cmt      TEXT,
     addmod_date   TEXT,
     cc            TEXT
  );

CREATE TEMP TABLE ttnutr_def
  (
     nutr_no  TEXT,
     units    TEXT,
     tagname  TEXT,
     nutrdesc TEXT,
     num_dec  TEXT,
     sr_order INT
  );

CREATE TEMP TABLE tnutr_def
  (
     nutr_no    INT PRIMARY KEY,
     units      TEXT,
     tagname    TEXT,
     nutrdesc   TEXT,
     dv_default REAL,
     nutopt     REAL
  );

CREATE TEMP TABLE zweight
  (
     ndb_no     INT,
     seq        INT,
     amount     REAL,
     msre_desc  TEXT,
     gm_wgt     REAL,
     origseq    INT,
     origgm_wgt REAL,
     PRIMARY KEY(ndb_no, origseq)
  );
"""

usda_drop_temp_tables = """
DROP TABLE tfd_group;
DROP TABLE tfood_des;
DROP TABLE tweight;
DROP TABLE zweight;
DROP TABLE tnut_data;
DROP TABLE ttnutr_def;
DROP TABLE tnutr_def;
"""

usda_load_process = """
-- Remove tildes from USDA
INSERT OR IGNORE
INTO   tnutr_def
SELECT TRIM(nutr_no, '~'),
       TRIM(units, '~'),
       TRIM(tagname, '~'),
       TRIM(nutrdesc, '~'),
       NULL,
       NULL
FROM ttnutr_def;

-- Insert or replace default values
-- to read the USDA a trigger should be put that trims '~' AND doesn't
-- overwrite default values
-- Create a trigger to avoid overwriting the user's nutopt
REPLACE INTO nutr_def (
  Nutr_No,
  Units,
  Tagname,
  NutrDesc,
  dv_default,
  nutopt
)
VALUES
  (203, 'g', 'PROCNT', 'Protein', 50.0, 0),
  (204, 'g', 'FAT', 'Total Fat', 78.0, 0),
  (205, 'g', 'CHOCDF', 'Total Carb', 275.0, 0),
  (207, 'g', NULL, 'Ash', NULL, 0),
  (208, 'kc', 'ENERC_KCAL', 'Calories', 2000.0, 0),
  (209, 'g', NULL, 'Starch', NULL, 0),
  (210, 'g', NULL, 'Sucrose', NULL, 0),
  (211, 'g', NULL, 'Glucose', NULL, 0),
  (212, 'g', NULL, 'Fructose', NULL, 0),
  (213, 'g', NULL, 'Lactose', NULL, 0),
  (214, 'g', NULL, 'Maltose', NULL, 0),
  (221, 'g', NULL, 'Ethyl Alcohol', NULL, 0),
  (255, 'g', NULL, 'Water', NULL, 0),
  (257, 'g', 'ADPROT', '', NULL, 0),
  (257, 'g', NULL, 'Adj. Protein', NULL, 0),
  (262, 'mg', NULL, 'Caffeine', NULL, 0),
  (263, 'mg', NULL, 'Theobromine', NULL, 0),
  (269, 'g', NULL, 'Sugars', NULL, 0),
  (287, 'g', NULL, 'Galactose', NULL, 0),
  (291, 'g', 'FIBTG', 'Fiber', 28.0, 0),
  (301, 'mg', 'CA', 'Calcium', 1300.0, 0),
  (303, 'mg', 'FE', 'Iron', 18.0, 0),
  (304, 'mg', 'MG', 'Magnesium', 420.0, 0),
  (305, 'mg', 'P', 'Phosphorus', 1250.0, 0),
  (306, 'mg', 'K', 'Potassium', 4700.0, 0),
  (307, 'mg', 'NA', 'Sodium', 2300.0, 0),
  (309, 'mg', 'ZN', 'Zinc', 11.0, 0),
  (312, 'mg', 'CU', 'Copper', 0.9, 0),
  (313, 'mcg', NULL, 'Fluoride', NULL, 0),
  (315, 'mg', 'MN', 'Manganese', 2.3, 0),
  (317, 'mcg', 'SE', 'Selenium', 55.0, 0),
  (318, 'IU', NULL, 'Vit. A, IU', NULL, 0),
  (319, 'mcg', NULL, 'Retinol', NULL, 0),
  (320, 'mcg', 'VITA_RAE', 'Vitamin A', 900.0, 0),
  (321, 'mcg', NULL, 'B-Carotene', NULL, 0),
  (322, 'mcg', NULL, 'A-Carotene', NULL, 0),
  (323, 'mg', NULL, 'A-Tocopherol', NULL, 0),
  (324, 'IU', 'VITD', 'Vit. D, IU', NULL, 0),
  (325, 'mcg', NULL, 'Vitamin D2', NULL, 0),
  (326, 'mcg', NULL, 'Vitamin D3', NULL, 0),
  (328, 'mcg', 'VITD_BOTH', 'Vitamin D', 20.0, 0),
  (334, 'mcg', NULL, 'B-Cryptoxanth', NULL, 0),
  (337, 'mcg', NULL, 'Lycopene', NULL, 0),
  (338, 'mcg', NULL, 'Lutein+Zeaxan', NULL, 0),
  (341, 'mg', NULL, 'B-Tocopherol', NULL, 0),
  (342, 'mg', NULL, 'G-Tocopherol', NULL, 0),
  (343, 'mg', NULL, 'D-Tocopherol', NULL, 0),
  (344, 'mg', NULL, 'A-Tocotrienol', NULL, 0),
  (345, 'mg', NULL, 'B-Tocotrienol', NULL, 0),
  (346, 'mg', NULL, 'G-Tocotrienol', NULL, 0),
  (347, 'mg', NULL, 'D-Tocotrienol', NULL, 0),
  (401, 'mg', 'VITC', 'Vitamin C', 90.0, 0),
  (404, 'mg', 'THIA', 'Thiamin', 1.2, 0),
  (405, 'mg', 'RIBF', 'Riboflavin', 1.3, 0),
  (406, 'mg', 'NIA', 'Niacin', 16.0, 0),
  (410, 'mg', 'PANTAC', 'Panto. Acid', 5.0, 0),
  (415, 'mg', 'VITB6A', 'Vitamin B6', 1.7, 0),
  (417, 'mcg', 'FOL', 'Folate', 400.0, 0),
  (418, 'mcg', 'VITB12?, 'Vitamin B12', 2.4, 0),
  (421, 'mg', 'CHOLN', 'Choline', 550.0, 0),
  (428, 'mcg', NULL, 'Menaquinone-4', NULL, 0),
  (429, 'mcg', NULL, 'Dihydro-K1', NULL, 0),
  (430, 'mcg', 'VITK1', 'Vitamin K1', 120.0, 0),
  (431, 'mcg', NULL, 'Folic Acid', NULL, 0),
  (432, 'mcg', NULL, 'Folate, food', NULL, 0),
  (435, 'mcg', NULL, 'Folate, DFE', NULL, 0),
  (454, 'mg', NULL, 'Betaine', NULL, 0),
  (501, 'g', NULL, 'Tryptophan', NULL, 0),
  (502, 'g', NULL, 'Threonine', NULL, 0),
  (503, 'g', NULL, 'Isoleucine', NULL, 0),
  (504, 'g', NULL, 'Leucine', NULL, 0),
  (505, 'g', NULL, 'Lysine', NULL, 0),
  (506, 'g', NULL, 'Methionine', NULL, 0),
  (507, 'g', NULL, 'Cystine', NULL, 0),
  (508, 'g', NULL, 'Phenylalanine', NULL, 0),
  (509, 'g', NULL, 'Tyrosine', NULL, 0),
  (510, 'g', NULL, 'Valine', NULL, 0),
  (511, 'g', NULL, 'Arginine', NULL, 0),
  (512, 'g', NULL, 'Histidine', NULL, 0),
  (513, 'g', NULL, 'Alanine', NULL, 0),
  (514, 'g', NULL, 'Aspartic acid', NULL, 0),
  (515, 'g', NULL, 'Glutamic acid', NULL, 0),
  (516, 'g', NULL, 'Glycine', NULL, 0),
  (517, 'g', NULL, 'Proline', NULL, 0),
  (518, 'g', NULL, 'Serine', NULL, 0),
  (521, 'g', NULL, 'Hydroxyroline', NULL, 0),
  (573, 'mg', 'VITE_ADDED', 'Vit. E added', NULL, 0),
  (578, 'mcg', 'VITB12_ADDED', 'Vit. B12 added', NULL, 0),
  (601, 'mg', 'CHOLE', 'Cholesterol', 300.0, 0),
  (605, 'g', NULL, 'Trans Fat', NULL, 0),
  (606, 'g', 'FASAT', 'Sat Fat', NULL, 0),
  (607, 'g', NULL, '4:0', NULL, 0),
  (608, 'g', NULL, '6:0', NULL, 0),
  (609, 'g', NULL, '8:0', NULL, 0),
  (610, 'g', NULL, '10:0', NULL, 0),
  (611, 'g', NULL, '12:0', NULL, 0),
  (612, 'g', NULL, '14:0', NULL, 0),
  (613, 'g', NULL, '16:0', NULL, 0),
  (614, 'g', NULL, '18:0', NULL, 0),
  (615, 'g', NULL, '20:0', NULL, 0),
  (617, 'g', NULL, '18:1', NULL, 0),
  (618, 'g', NULL, '18:2', NULL, 0),
  (619, 'g', NULL, '18:3', NULL, 0),
  (620, 'g', NULL, '20:4', NULL, 0),
  (621, 'g', NULL, ''22:6n-3, NULL, 0),
  (624, 'g', NULL, '22:0', NULL, 0),
  (625, 'g', NULL, '14:1', NULL, 0),
  (626, 'g', NULL, '16:1', NULL, 0),
  (627, 'g', NULL, '18:4', NULL, 0),
  (628, 'g', NULL, '20:1', NULL, 0),
  (629, 'g', NULL, '20:5n-3', NULL, 0),
  (630, 'g', NULL, '22:1', NULL, 0),
  (631, 'g', NULL, '22:5n-3', NULL, 0),
  (636, 'mg', NULL, 'Phytosterols', NULL, 0),
  (638, 'mg', NULL, 'Stigmasterol', NULL, 0),
  (639, 'mg', NULL, 'Campesterol', NULL, 0),
  (641, 'mg', NULL, 'BetaSitosterol', NULL, 0),
  (645, 'g', 'FAMS', 'Mono Fat', 32.6, 0),
  (646, 'g', 'FAPU', 'Poly Fat', 8.9, 0),
  (652, 'g', NULL, '15:0', NULL, 0),
  (653, 'g', NULL, '17:0', NULL, 0),
  (654, 'g', NULL, '24:0', NULL, 0),
  (662, 'g', NULL, '16:1t', NULL, 0),
  (663, 'g', NULL, '18:1t', NULL, 0),
  (664, 'g', 'F22D1T', '', NULL, 0),
  (664, 'g', NULL, '22:1t', NULL, 0),
  (665, 'g', 'F18D2T', '', NULL, 0),
  (665, 'g', NULL, '18:2t', NULL, 0),
  (666, 'g', 'F18D2I', '', NULL, 0),
  (666, 'g', NULL, '18:2i', NULL, 0),
  (669, 'g', NULL, '18:2t,t', NULL, 0),
  (670, 'g', NULL, '18:2CLA', NULL, 0),
  (671, 'g', NULL, '24:1c', NULL, 0),
  (672, 'g', NULL, '20:2n-6c,c', NULL, 0),
  (673, 'g', NULL, '16:1c', NULL, 0),
  (674, 'g', NULL, '18:1c', NULL, 0),
  (675, 'g', NULL, '18:2n-6c,c', NULL, 0),
  (676, 'g', 'F22D1C', '', NULL, 0),
  (685, 'g', NULL, '18:3n-6c,c,c', NULL, 0),
  (687, 'g', NULL, '17:1', NULL, 0),
  (689, 'g', NULL, '20:3', NULL, 0),
  (693, 'g', NULL, 'TransMonoenoic', NULL, 0),
  (695, 'g', NULL, 'TransPolyenoic', NULL, 0),
  (696, 'g', NULL, '13:0', NULL, 0),
  (697, 'g', NULL, '15:1', NULL, 0),
  (767, 'g', NULL, '22:1c', NULL, 0),
  (851, 'g', NULL, '18:3n-3c,c,c', NULL, 0),
  (852, 'g', NULL, '20:3n-3', NULL, 0),
  (853, 'g', NULL, '20:3n-6', NULL, 0),
  (855, 'g', NULL, '20:4n-6', NULL, 0),
  (856, 'g', 'F18D3I', '', NULL, 0),
  (856, 'g', NULL, '18:3i', NULL, 0),
  (857, 'g', NULL, '21:5', NULL, 0),
  (858, 'g', NULL, '22:4', NULL, 0),
  (859, 'g', NULL, '18:1n-7t', NULL, 0),

-- These are the new "daily value" labeling standards minus "ADDED SUGARS"
-- which have not yet appeared in the USDA data.

  (2000, 'g', 'CHO_NONFIB', 'Non-Fiber Carb', 247.0, NULL),
  (2001, 'g', 'LA', 'LA', 4.7, NULL),
  (2002, 'g', 'AA', 'AA', 0.2, NULL),
  (2003, 'g', 'ALA', 'ALA', 3.8, NULL),
  (2004, 'g', 'EPA', 'EPA', 0.1, NULL),
  (2005, 'g', 'DHA', 'DHA', 0.1, NULL),
  (2006, 'g', 'OMEGA6', 'Omega-6', 4.9, NULL),
  (2007, 'g', 'OMEGA3', 'Omega-3', 4.0, NULL),
  (2008, 'mg', 'VITE', 'Vitamin E', 15.0, NULL),
  (3000, 'kc', 'PROT_KCAL', 'Protein Calories', NULL, NULL),
  (3001, 'kc', 'FAT_KCAL', 'Fat Calories', NULL, NULL),
  (3002, 'kc', 'CHO_KCAL', 'Carb Calories', NULL, NULL),
  (3003, 'g', 'SHORT6', 'Short-chain Omega-6', NULL, NULL),
  (3004, 'g', 'LONG6', 'Long-chain Omega-6', NULL, NULL),
  (3005, 'g', 'SHORT3', 'Short-chain Omega-3', NULL, NULL),
  (3006, 'g', 'LONG3', 'Long-chain Omega-3', NULL, NULL);


-- comment out the next statement if you want to hassle
-- the non-ascii micro char
UPDATE nutr_def
SET Units = 'mcg'
WHERE HEX(Units) = 'B567';

UPDATE nutr_def SET nutopt = 0.0
WHERE dv_default > 0.0 AND nutopt IS NULL;

CREATE INDEX IF NOT EXISTS tagname_index ON nutr_def (Tagname ASC);

REPLACE INTO fd_group
SELECT TRIM(fdgrp_cd, '~'),
       TRIM(fdgrp_desc, '~')
FROM   tfd_group;

REPLACE INTO fd_group
VALUES (9999, 'Added Recipes');


-----------[LOAD TEMPORARY FOOD DESCRIPTIONS INTO FINAL TABLE]-----------------

REPLACE INTO food_des
(
  ndb_no,
  fdgrp_cd,
  long_desc,
  shrt_desc,
  ref_desc,
  refuse,
  pro_factor,
  fat_factor,
  cho_factor
)
SELECT TRIM(ndb_no, '~'),
       TRIM(fdgrp_cd, '~'),
       REPLACE(TRIM(TRIM(long_desc, '~')
              || ' ('
              || TRIM(sciname, '~')
              || ')',' ('),' ()',''),
       SUBSTR(SUBSTR(TRIM(shrt_desc, '~'),1,1))
              || LOWER(SUBSTR(TRIM(shrt_desc, '~'),2)),
       TRIM(ref_desc, '~'),
       refuse,
       pro_factor,
       fat_factor,
       cho_factor
FROM   tfood_des;

UPDATE food_des
SET Shrt_Desc = Long_Desc
WHERE LENGTH(Long_Desc) <= 60;


-------------------------------------------------------------------------------
----------------------------[FOOD WEIGHT LOADING]------------------------------

UPDATE tweight
SET
  NDB_No = TRIM(NDB_No, '~'),
  Seq = TRIM(Seq, '~'),
  Msre_Desc = TRIM(Msre_Desc, '~');

--We want every food to have a weight, so we make a '100 grams' default weight
REPLACE INTO zweight
SELECT NDB_No, 99, 100, 'grams', 100, 99, 100
FROM food_des;

--Now we UPDATE zweight with the user's existing weight preferences
REPLACE INTO zweight
SELECT *
FROM weight
WHERE Seq != origSeq OR Gm_Wgt != origGm_Wgt;

--We overwrite real weight TABLE with new USDA records
REPLACE INTO weight
SELECT NDB_No, Seq, Amount, Msre_Desc, Gm_Wgt, Seq, Gm_Wgt
FROM tweight;

--We overwrite the real weight TABLE with the original user mods
INSERT OR replace INTO weight SELECT *
FROM zweight;


-- Load data into the final table
REPLACE INTO nut_data
SELECT TRIM(NDB_No, '~'), TRIM(Nutr_No, '~'), Nutr_Val
FROM tnut_data;


-- insert VITE records INTO nut_data
REPLACE INTO nut_data
SELECT    f.ndb_no,
          2008,
          IFNULL(tocpha.nutr_val, 0.0)
FROM      food_des f
LEFT JOIN nut_data tocpha
  ON f.ndb_no = tocpha.ndb_no
  AND tocpha.nutr_no = 323
WHERE tocpha.nutr_val IS NOT NULL;

-- insert LA records INTO nut_data
REPLACE INTO nut_data
SELECT f.ndb_no,
  2001,
  CASE
    WHEN f18d2cn6.nutr_val IS NOT NULL THEN
      f18d2cn6.nutr_val
    WHEN f18d2.nutr_val IS NOT NULL THEN
      f18d2.nutr_val - IFNULL(f18d2t.nutr_val, 0.0) -
      IFNULL(f18d2tt.nutr_val, 0.0) - IFNULL(f18d2i.nutr_val, 0.0) -
      IFNULL(f18d2cla.nutr_val, 0.0)
    END
FROM food_des f
LEFT JOIN nut_data f18d2
  ON f.ndb_no = f18d2.ndb_no
  AND f18d2.nutr_no = 618
LEFT JOIN nut_data f18d2cn6
  ON f.ndb_no = f18d2cn6.ndb_no
  AND f18d2cn6.nutr_no = 675
LEFT JOIN nut_data f18d2t
  ON f.ndb_no = f18d2t.ndb_no
  AND f18d2t.nutr_no = 665
LEFT JOIN nut_data f18d2tt
  ON f.ndb_no = f18d2tt.ndb_no
  AND f18d2tt.nutr_no = 669
LEFT JOIN nut_data f18d2i
  ON f.ndb_no = f18d2i.ndb_no
  AND f18d2i.nutr_no = 666
LEFT JOIN nut_data f18d2cla
  ON f.ndb_no = f18d2cla.ndb_no
  AND f18d2cla.nutr_no = 670
WHERE f18d2.nutr_val IS NOT NULL
  OR f18d2cn6.nutr_val IS NOT NULL
  OR f18d2t.nutr_val IS NOT NULL
  OR f18d2tt.nutr_val IS NOT NULL
  OR f18d2i.nutr_val IS NOT NULL
  OR f18d2cla.nutr_val IS NOT NULL;


--INSERT ALA records INTO nut_data
REPLACE INTO nut_data
SELECT f.ndb_no,
  2003,
  CASE
    WHEN f18d3cn3.nutr_val IS NOT NULL THEN
      f18d3cn3.nutr_val
    WHEN f18d3.nutr_val IS NOT NULL THEN
      f18d3.nutr_val - IFNULL(f18d3cn6.nutr_val, 0.0) -
      IFNULL(f18d3i.nutr_val, 0.0)
    END
FROM food_des f
LEFT JOIN nut_data f18d3
  ON f.ndb_no = f18d3.ndb_no
  AND f18d3.nutr_no = 619
LEFT JOIN nut_data f18d3cn3
  ON f.ndb_no = f18d3cn3.ndb_no
  AND f18d3cn3.nutr_no = 851
LEFT JOIN nut_data f18d3cn6
  ON f.ndb_no = f18d3cn6.ndb_no
  AND f18d3cn6.nutr_no = 685
LEFT JOIN nut_data f18d3i
  ON f.ndb_no = f18d3i.ndb_no
  AND f18d3i.nutr_no = 856
WHERE     f18d3.nutr_val IS NOT NULL
  OR f18d3cn3.nutr_val IS NOT NULL
  OR f18d3cn6.nutr_val IS NOT NULL
  OR f18d3i.nutr_val IS NOT NULL;

--INSERT SHORT6 records INTO nut_data
INSERT
or     REPLACE
INTO   nut_data
SELECT    f.ndb_no,
          3003,
          IFNULL(la.nutr_val, 0.0) + IFNULL(f18d3cn6.nutr_val, 0.0)
FROM      food_des f
LEFT JOIN nut_data la
ON        f.ndb_no = la.ndb_no
AND       la.nutr_no = 2001
LEFT JOIN nut_data f18d3cn6
ON        f.ndb_no = f18d3cn6.ndb_no
AND       f18d3cn6.nutr_no = 685
WHERE     la.nutr_val IS NOT NULL
OR        f18d3cn6.nutr_val IS NOT NULL;

--INSERT SHORT3 records INTO nut_data
REPLACE INTO nut_data
SELECT
  f.ndb_no,
  3005,
  IFNULL(ala.nutr_val, 0.0) + IFNULL(f18d4.nutr_val, 0.0)
FROM food_des f
LEFT JOIN nut_data ala
  ON f.ndb_no = ala.ndb_no
  AND ala.nutr_no = 2003
LEFT JOIN nut_data f18d4
  ON f.ndb_no = f18d4.ndb_no
  AND f18d4.nutr_no = 627
WHERE ala.nutr_val IS NOT NULL
  OR f18d4.nutr_val IS NOT NULL;

--INSERT AA records INTO nut_data
REPLACE INTO nut_data
SELECT f.ndb_no,
  2002,
  CASE
    WHEN f20d4n6.nutr_val IS NOT NULL THEN
      f20d4n6.nutr_val
    ELSE
      f20d4.nutr_val
  END
FROM food_des f
LEFT JOIN nut_data f20d4
  ON f.ndb_no = f20d4.ndb_no
  AND f20d4.nutr_no = 620
LEFT JOIN nut_data f20d4n6
  ON f.ndb_no = f20d4n6.ndb_no
  AND f20d4n6.nutr_no = 855
WHERE f20d4.nutr_val IS NOT NULL
  OR f20d4n6.nutr_val IS NOT NULL;

--INSERT LONG6 records INTO nut_data
REPLACE INTO nut_data
SELECT f.ndb_no,
  3004,
  CASE
    WHEN f20d3n6.nutr_val IS NOT NULL THEN
      IFNULL(aa.nutr_val,0.0) + f20d3n6.nutr_val + IFNULL(f22d4.nutr_val,0.0)
    ELSE
      IFNULL(aa.nutr_val,0.0) + IFNULL(f20d3.nutr_val,0.0) +
      IFNULL(f22d4.nutr_val, 0.0)
    END
FROM food_des f
LEFT JOIN nut_data aa
  ON f.ndb_no = aa.ndb_no
  AND aa.nutr_no = 2002
LEFT JOIN nut_data f20d3n6
  ON f.ndb_no = f20d3n6.ndb_no
  AND f20d3n6.nutr_no = 853
LEFT JOIN nut_data f20d3
  ON f.ndb_no = f20d3.ndb_no
  AND f20d3.nutr_no = 689
LEFT JOIN nut_data f22d4
  ON f.ndb_no = f22d4.ndb_no
  AND f22d4.nutr_no = 858
WHERE     aa.nutr_val IS NOT NULL
  OR f20d3n6.nutr_val IS NOT NULL
  OR f20d3.nutr_val IS NOT NULL
  OR f22d4.nutr_val IS NOT NULL;

--INSERT EPA records INTO nut_data
REPLACE
INTO   nut_data
SELECT f.ndb_no,
  2004,
  f20d5.nutr_val
FROM  food_des f
LEFT JOIN nut_data f20d5
  ON f.ndb_no = f20d5.ndb_no
  AND f20d5.nutr_no = 629
WHERE f20d5.nutr_val IS NOT NULL;

--INSERT DHA records INTO nut_data
REPLACE INTO nut_data
SELECT f.ndb_no,
  2005,
  f22d6.nutr_val
FROM food_des f
LEFT JOIN nut_data f22d6
  ON f.ndb_no = f22d6.ndb_no
  AND f22d6.nutr_no = 621
WHERE f22d6.nutr_val IS NOT NULL;

--INSERT LONG3 records INTO nut_data
REPLACE INTO nut_data
SELECT f.ndb_no,
  3006,
  IFNULL(epa.nutr_val, 0.0) + IFNULL(dha.nutr_val, 0.0) +
  IFNULL(f20d3n3.nutr_val, 0.0) + IFNULL(f22d5.nutr_val, 0.0)
FROM food_des f
LEFT JOIN nut_data epa
  ON f.ndb_no = epa.ndb_no
  AND epa.nutr_no = 2004
LEFT JOIN nut_data dha
  ON f.ndb_no = dha.ndb_no
  AND dha.nutr_no = 2005
LEFT JOIN nut_data f20d3n3
  ON f.ndb_no = f20d3n3.ndb_no
  AND f20d3n3.nutr_no = 852
LEFT JOIN nut_data f22d5
  ON f.ndb_no = f22d5.ndb_no
  AND f22d5.nutr_no = 631
WHERE     epa.nutr_val IS NOT NULL
  OR dha.nutr_val IS NOT NULL
  OR f20d3n3.nutr_val IS NOT NULL
  OR f22d5.nutr_val IS NOT NULL;

--INSERT OMEGA6 records INTO nut_data
REPLACE INTO   nut_data
SELECT f.ndb_no,
  2006,
  IFNULL(short6.nutr_val, 0.0) + IFNULL(long6.nutr_val, 0.0)
FROM food_des f
LEFT JOIN nut_data short6
  ON f.ndb_no = short6.ndb_no
  AND short6.nutr_no = 3003
LEFT JOIN nut_data long6
  ON f.ndb_no = long6.ndb_no
  AND long6.nutr_no = 3004
WHERE short6.nutr_val IS NOT NULL
  OR long6.nutr_val IS NOT NULL;

-- Insert OMEGA3 records into nut_data
REPLACE INTO nut_data
SELECT
  f.ndb_no,
  2007,
  IFNULL(short3.nutr_val, 0.0) + IFNULL(long3.nutr_val, 0.0)
FROM food_des f
LEFT JOIN nut_data short3
  ON f.ndb_no = short3.ndb_no
  AND short3.nutr_no = 3005
LEFT JOIN nut_data long3
  ON f.ndb_no = long3.ndb_no
  AND long3.nutr_no = 3006
WHERE short3.nutr_val IS NOT NULL
  OR long3.nutr_val IS NOT NULL;

-- Insert CHO_NONFIB records into nut_data
INSERT OR REPLACE
INTO nut_data
SELECT
  f.ndb_no,
  2000,
  CASE
    WHEN chocdf.nutr_val - IFNULL(fibtg.nutr_val, 0.0) < 0.0 THEN
      0.0
    ELSE
      chocdf.nutr_val - IFNULL(fibtg.nutr_val, 0.0)
    END
FROM food_des f
LEFT JOIN nut_data chocdf
  ON f.ndb_no = chocdf.ndb_no
  AND chocdf.nutr_no = 205
LEFT JOIN nut_data fibtg
  ON f.ndb_no = fibtg.ndb_no
  AND fibtg.nutr_no = 291
WHERE chocdf.nutr_val IS NOT NULL;

-- Replace empty strings with values for macronutrient factors in food_des
UPDATE food_des
SET    pro_factor = 4.0
WHERE  pro_factor = '' OR pro_factor IS NULL;

UPDATE food_des
SET    fat_factor = 9.0
WHERE  fat_factor = '' OR fat_factor IS NULL;

UPDATE food_des
SET    cho_factor = 4.0
WHERE  cho_factor = '' OR cho_factor IS NULL;

-- insert calories
FROM macronutrients INTO nut_data
REPLACE INTO   nut_data
SELECT f.ndb_no,
       3000,
       f.pro_factor * procnt.nutr_val
FROM food_des f
JOIN nut_data procnt
  ON     f.ndb_no = procnt.ndb_no
  AND    procnt.nutr_no = 203;

REPLACE INTO nut_data
SELECT f.ndb_no,
  3001,
  f.fat_factor * fat.nutr_val
FROM   food_des f
JOIN   nut_data fat
  ON     f.ndb_no = fat.ndb_no
  AND    fat.nutr_no = 204;

REPLACE INTO   nut_data
SELECT f.ndb_no,
       3002,
       f.cho_factor * chocdf.nutr_val
FROM   food_des f
JOIN   nut_data chocdf
  ON     f.ndb_no = chocdf.ndb_no
  AND    chocdf.nutr_no = 205;


DROP TRIGGER IF EXISTS protect_options;

CREATE TRIGGER protect_options
AFTER INSERT ON options
  BEGIN DELETE FROM options
WHERE protect != 1;
END;

INSERT INTO options default values;

DROP TRIGGER protect_options;

UPDATE options
SET currentmeal = CAST(STRFTIME('%Y%m%d01', DATE('now')) AS INTEGER);

COMMIT;
VACUUM;
"""

create_logic_views = """
CREATE VIEW am_analysis
AS SELECT
  am.Nutr_No AS Nutr_No,
  CASE
    WHEN currentmeal BETWEEN firstmeal AND lastmeal
      AND am.null_value AND rm.null_value THEN
      1
    WHEN currentmeal NOT BETWEEN firstmeal AND lastmeal
      AND am.null_value THEN
      1
    ELSE
      0
  END AS null_value,
  CASE
    WHEN currentmeal BETWEEN firstmeal AND lastmeal THEN
      IFNULL(am.Nutr_Val, 0.0) + 1.0 / mealcount * IFNULL(rm.Nutr_Val, 0.0)
    ELSE
      am.Nutr_Val
  END AS Nutr_Val
FROM z_anal am
LEFT JOIN rm_analysis rm
  ON am.Nutr_No = rm.Nutr_No
JOIN am_analysis_header;


CREATE VIEW z_wslope
AS SELECT
  IFNULL(weightslope,0.0) AS "weightslope",
  IFNULL(round(sumy / n - weightslope * sumx / n,1),0.0) AS "weightyintercept",
  n AS "weightn"
FROM (
  SELECT
    (sumxy - (sumx * sumy / n)) / (sumxx - (sumx * sumx / n)) AS weightslope,
    sumy,
    n,
    sumx
  FROM (
    SELECT
      sum(x) as sumx,
      sum(y) as sumy,
      sum(x*y) as sumxy,
      sum(x*x) as sumxx,
      n
    FROM (
      SELECT
        CAST (CAST (JULIANDAY(SUBSTR(wldate,1,4) || '-' || SUBSTR(wldate,5,2)
        || '-' || SUBSTR(wldate,7,2)) - JULIANDAY('now', 'localtime') AS INT)
        AS REAL) AS x,
        weight AS y,
        CAST((SELECT COUNT(*) FROM z_wl WHERE cleardate IS NULL) AS REAL) AS n
      FROM z_wl
      WHERE cleardate IS NULL)));

  /*
    Basically the same thing for the slope, y-intercept, AND "n" OF fat mass.
  */


CREATE VIEW z_fslope
AS SELECT
  IFNULL(fatslope, 0.0) AS "fatslope",
  IFNULL(round(sumy / n - fatslope * sumx / n,1),0.0) AS "fatyintercept",
  n AS "fatn"
  FROM (
    SELECT
      (sumxy - (sumx * sumy / n)) /(sumxx - (sumx * sumx / n)) as fatslope,
      sumy,
      n,
      sumx
    FROM (
      SELECT
        sum(x) as sumx,
        sum(y) as sumy,
        sum(x*y) as sumxy,
        sum(x*x) as sumxx,
        n
      FROM (
        SELECT
          cast (cast (julianday(SUBSTR(wldate,1,4) || '-' ||
            SUBSTR(wldate,5,2) || '-' || SUBSTR(wldate,7,2)) -
            julianday('now', 'localtime') as int) as real) as x,
          bodyfat * weight / 100.0 as y,
          cast ((SELECT count(*) FROM z_wl WHERE IFNULL(bodyfat,0.0) > 0.0
            AND cleardate IS NULL) as real) as n
        FROM z_wl
        WHERE IFNULL(bodyfat,0.0) > 0.0 AND cleardate IS NULL)));

CREATE VIEW z_span
AS SELECT
  ABS(MIN(cast (julianday(SUBSTR(wldate,1,4) || '-' || SUBSTR(wldate,5,2)
  || '-' || SUBSTR(wldate,7,2)) -
  julianday('now', 'localtime') as int))) as span
FROM z_wl
WHERE cleardate IS NULL;

CREATE VIEW wlog
AS SELECT *
FROM z_wl;


CREATE VIEW wlview
AS SELECT
  wldate,
  weight,
  bodyfat,
  round(weight - weight * bodyfat / 100, 1) as leanmass,
  round(weight * bodyfat / 100, 1) as fatmass,
  round(weight - 2 * weight * bodyfat / 100) as bodycomp,
  cleardate
FROM z_wl;


CREATE VIEW wlsummary
AS SELECT
  CASE
    WHEN weightn > 1 THEN
      'Weight:  ' || ROUND(weightyintercept, 1) || char(13) || char(10) ||
      'Bodyfat:  ' ||
      CASE
        WHEN weightyintercept > 0.0 THEN
          ROUND(1000.0 * fatyintercept / weightyintercept) / 10.0
        ELSE
          0.0
      END || '%' || char(13) || char(10)
    WHEN weightn = 1 THEN
      'Weight:  ' || (SELECT weight FROM z_wl WHERE cleardate IS NULL) ||
      char(13) || char(10) ||
      'Bodyfat:  ' || (SELECT bodyfat FROM z_wl WHERE cleardate IS NULL) || '%'
    ELSE
      'Weight:  0.0' || char(13) || char(10) || 'Bodyfat:  0.0%'
  END || char(13) || char(10) || 'Today' || "'" || 's Calorie level = ' ||
  (SELECT ROUND(nutopt) FROM nutr_def WHERE Nutr_No = 208)
    || char(13) || char(10) || char(13) || char(10) ||
  CASE
    WHEN weightn = 0 THEN
      '0 data points so far...'
    WHEN weightn = 1 THEN
      '1 data point so far...'
    ELSE
      'Based on the trend of ' || weightn || ' data points so far...' ||
      char(13) || char(10) || char(10) || 'Predicted lean mass today = ' ||
      ROUND(10.0 * (weightyintercept - fatyintercept)) / 10.0
      || char(13) || char(10) || 'Predicted fat mass today  =  ' ||
      ROUND(fatyintercept, 1) || char(13) || char(10) || char(10) ||
      'If the predictions are correct, you '
  END ||
  CASE
    WHEN weightslope - fatslope >= 0.0 THEN
      'gained '
    ELSE
      'lost '
  END || ABS(ROUND((weightslope - fatslope) * span * 1000.0) / 1000.0)||
    ' lean mass over ' || span||
  CASE
    WHEN span = 1 THEN
      ' day'
    ELSE
      ' days'
  END || char(13) || char(10) ||
  CASE
    WHEN fatslope > 0.0 THEN
        'and gained '
    ELSE
      'and lost '
  END || ABS(ROUND(fatslope * span * 1000.0) / 1000.0) || ' fat mass.'
  AS verbiage
FROM z_wslope, z_fslope, z_span;
"""

init_logic = """
  INSERT INTO z_trig_ctl default values;

  DELETE FROM z_n6;

  INSERT INTO z_n6
  SELECT
    NULL,
    NULL,
    NULL,
    1,
    1,
    900.0 * MAX(SHORT3.Nutr_Val, 0.000000001) /
      MAX(ENERC_KCAL.Nutr_Val, 0.000000001),
    900.0 * MAX(SHORT6.Nutr_Val, 0.000000001) /
      MAX(ENERC_KCAL.Nutr_Val, 0.000000001),
    900.0 * MAX(LONG3.Nutr_Val, 0.000000001) /
      MAX(ENERC_KCAL.Nutr_Val, 0.000000001),
    900.0 * MAX(LONG6.Nutr_Val, 0.000000001) /
      MAX(ENERC_KCAL.Nutr_Val, 0.000000001),
    900.0 *
    (FASAT.Nutr_Val + FAMS.Nutr_Val + FAPU.Nutr_Val -
      MAX(SHORT3.Nutr_Val, 0.000000001) - MAX(SHORT6.Nutr_Val, 0.000000001) -
      MAX(LONG3.Nutr_Val, 0.000000001) - MAX(LONG6.Nutr_Val, 0.000000001)) /
    MAX(ENERC_KCAL.Nutr_Val, 0.000000001)
  FROM am_analysis SHORT3
  JOIN am_analysis SHORT6
    ON SHORT3.Nutr_No = 3005 AND SHORT6.Nutr_No = 3003
  JOIN am_analysis LONG3
    ON LONG3.Nutr_No = 3006
  JOIN am_analysis LONG6
    ON LONG6.Nutr_No = 3004
  JOIN am_analysis FAPUval
    ON FAPUval.Nutr_No = 646
  JOIN am_analysis FASAT
    ON FASAT.Nutr_No = 606
  JOIN am_analysis FAMS
    ON FAMS.Nutr_No = 645
  JOIN am_analysis FAPU
    ON FAPU.Nutr_No = 646
  JOIN am_analysis ENERC_KCAL
    ON ENERC_KCAL.Nutr_No = 208;


  UPDATE am_analysis_header
  SET omega6 = IFNULL((
    SELECT
      CASE
        WHEN n6hufa_int = 0 OR n6hufa_int IS NULL THEN
          0
        WHEN n6hufa_int between 1 AND 14 THEN
          15
        WHEN n6hufa_int > 90 THEN
          90
        ELSE
          n6hufa_int
      END
    FROM (SELECT CAST(ROUND(n6hufa, 0) AS REAL) AS n6hufa_int FROM z_n6)),
    0.0),
    omega3 = IFNULL((100 - (SELECT
      CASE
        WHEN n6hufa_int = 0 OR n6hufa_int IS NULL THEN
          0
        WHEN n6hufa_int between 1 AND 14 THEN
          15
        WHEN n6hufa_int > 90 THEN
          90
        ELSE
          n6hufa_int
      END
    FROM (SELECT CAST(ROUND(n6hufa, 0) AS REAL) AS n6hufa_int FROM z_n6))),
    0.0);

  UPDATE rm_analysis_header
  SET omega6 = (
    SELECT
      CASE
        WHEN n6hufa_int = 0 OR n6hufa_int IS NULL THEN
          0
        WHEN n6hufa_int BETWEEN 1 AND 14 THEN
          15
        WHEN n6hufa_int > 90 THEN
          90
        ELSE
          n6hufa_int
      END
    FROM (SELECT CAST(ROUND(n6hufa, 0) AS INT) AS n6hufa_int FROM z_n6)),
  omega3 = (
    SELECT
      (100 - CASE
        WHEN n6hufa_int = 0 OR n6hufa_int IS NULL THEN
          0
        WHEN n6hufa_int BETWEEN 1 AND 14 THEN
          15
        WHEN n6hufa_int > 90 THEN
          90
        ELSE
          n6hufa_int
      END)
    FROM (SELECT CAST(ROUND(n6hufa, 0) AS INT) AS n6hufa_int FROM z_n6));

  UPDATE nutr_def
  SET nutopt = 0.0
  WHERE nutopt IS NULL;

  UPDATE options
  SET
    defanal_am = CASE
      WHEN defanal_am IS NULL THEN
        0
      ELSE
        defanal_am
      END,
    currentmeal = CASE
      WHEN currentmeal IS NULL THEN
        0
      ELSE
        currentmeal
      END;

--- remember to commit and optimize the database at the end
-- COMMIT;
ANALYZE main;
"""


create_food_archive_triggers = """
-----------------------------[ARCHIVE TRIGGERS]--------------------------------

-- Triggered when the meals per day are changed
CREATE TRIGGER mpd_archive
AFTER UPDATE OF meals_per_day
ON options
WHEN NEW.meals_per_day != OLD.meals_per_day
BEGIN

  INSERT OR IGNORE INTO archive_mealfoods
  SELECT meal_id, NDB_No, Gm_Wgt, OLD.meals_per_day
  FROM mealfoods;

  DELETE FROM mealfoods;

  INSERT OR IGNORE INTO mealfoods
  SELECT meal_id, NDB_No, Gm_Wgt, NULL
  FROM archive_mealfoods
  WHERE meals_per_day = NEW.meals_per_day;

  DELETE FROM archive_mealfoods
  WHERE meals_per_day = NEW.meals_per_day;

  UPDATE options
  SET defanal_am = (SELECT COUNT(DISTINCT meal_id) FROM mealfoods);
END;
"""

create_weight_log_triggers = """
----------------------------[WEIGHT LOG TRIGGERS]------------------------------

-- Triggered when a new weight log is inserted
CREATE TRIGGER wlog_insert
INSTEAD OF INSERT
ON wlog
BEGIN
  REPLACE INTO z_wl
  VALUES (
    NEW.weight,
    NEW.bodyfat,
    (SELECT STRFTIME('%Y%m%d', 'now', 'localtime')),
    NULL);
END;

-- Triggered when an insertion in the wlsummary is attempted
CREATE TRIGGER clear_wlsummary
INSTEAD OF INSERT
ON wlsummary
WHEN NOT (SELECT autocal FROM options)
BEGIN
    UPDATE z_wl
    SET cleardate = (SELECT STRFTIME('%Y%m%d', 'now', 'localtime'))
    WHERE cleardate IS NULL;

    INSERT INTO z_wl
    SELECT weight, bodyfat, wldate, NULL
    FROM z_wl
    WHERE wldate = (SELECT MAX(wldate) FROM z_wl);
END;

-- Autocal managemente trigger
CREATE TRIGGER autocal_initialization
AFTER UPDATE OF autocal
ON options
WHEN NEW.autocal IN (1, 2, 3) AND OLD.autocal NOT IN (1, 2, 3)
BEGIN
    UPDATE options
    SET
      wltweak = 0,
      wlpolarity = 0;
END;
"""

create_food_weight_triggers = """
-- Triggered when a food weight Seq is inserted or updated
CREATE TRIGGER update_weight_seq
BEFORE UPDATE OF Seq
ON weight
WHEN NEW.Seq = 0
BEGIN
  UPDATE weight
  SET
    Seq = origSeq,
    Gm_Wgt = origGm_Wgt
  WHERE NDB_No = NEW.NDB_No;
END;

CREATE TRIGGER insert_weight_Seq
BEFORE INSERT
ON weight
WHEN NEW.Seq = 0
BEGIN
  UPDATE weight
  SET
    Seq = origSeq,
    Gm_Wgt = origGm_Wgt
  WHERE NDB_No = NEW.NDB_No;
END;

------------------------[MEAL FOODS WEIGHT TRIGGER]----------------------------

CREATE TRIGGER update_mealfoods2weight_trigger
AFTER UPDATE ON mealfoods
WHEN NEW.Gm_Wgt > 0.0
  AND NOT (SELECT block_setting_preferred_weight FROM z_trig_ctl)
BEGIN
  UPDATE weight
  SET
    Gm_Wgt = NEW.Gm_Wgt
  WHERE NDB_No = NEW.NDB_No
    AND Seq = (SELECT MIN(Seq) FROM weight WHERE NDB_No = NEW.NDB_No);
END;

CREATE TRIGGER insert_mealfoods2weight_trigger
AFTER INSERT ON mealfoods
WHEN NEW.Gm_Wgt > 0.0
  AND NOT (SELECT block_setting_preferred_weight FROM z_trig_ctl)
BEGIN
  UPDATE weight
  SET Gm_Wgt = NEW.Gm_Wgt
  WHERE NDB_No = NEW.NDB_No
    AND Seq = (SELECT MIN(Seq) FROM weight WHERE NDB_No = NEW.NDB_No) ;
END;
"""

create_meal_foods_triggers = """
-----------------[MEAL FOODS INSERT AND DELETE TRIGGERS]-----------------------

CREATE TRIGGER insert_mealfoods_trigger
AFTER INSERT ON mealfoods
WHEN NEW.meal_id = (SELECT currentmeal FROM options)
  AND (SELECT count(*) FROM mealfoods WHERE meal_id = NEW.meal_id) = 1
BEGIN
  UPDATE z_trig_ctl
  SET
    am_analysis_header = 1,
    am_analysis = 1,
    am_dv = 1,
    rm_analysis_header = 1,
    am_analysis_minus_currentmeal = CASE
      WHEN (SELECT mealcount FROM am_analysis_header) > 1 THEN
        1
      WHEN (SELECT mealcount FROM am_analysis_header) = 1 AND
        (SELECT lastmeal FROM am_analysis_header) != (SELECT currentmeal
        FROM am_analysis_header) THEN
        1
      ELSE
        0
    END,
    am_analysis_null = CASE
      WHEN (SELECT mealcount FROM am_analysis_header) > 1 THEN
        0
      WHEN (SELECT mealcount FROM am_analysis_header) = 1 AND
        (SELECT lastmeal FROM am_analysis_header) != (SELECT currentmeal
        FROM am_analysis_header) THEN
        0
      ELSE
        1
      END,
    rm_analysis = CASE
      WHEN (SELECT mealcount FROM rm_analysis_header) = 1 THEN
        1
      ELSE
        0
    END,
    rm_analysis_null = CASE
      WHEN (SELECT mealcount FROM rm_analysis_header) = 0 THEN
        1
      ELSE
        0
    END;
END;

CREATE TRIGGER delete_mealfoods_trigger
AFTER DELETE ON mealfoods
WHEN OLD.meal_id = (SELECT currentmeal FROM options)
  AND (SELECT count(*) FROM mealfoods
WHERE meal_id = OLD.meal_id) = 0
BEGIN
  UPDATE mealfoods SET Nutr_No = NULL
  WHERE Nutr_No IS NOT NULL;

  UPDATE z_trig_ctl
  SET
    am_analysis_header = 1,
    am_analysis = 1,
    am_dv = 1,
    rm_analysis_header = 1,
    am_analysis_minus_currentmeal = CASE
      WHEN (SELECT mealcount FROM am_analysis_header) > 1 THEN
        1
      WHEN (SELECT mealcount FROM am_analysis_header) = 1 AND
        (SELECT lastmeal FROM am_analysis_header) != (SELECT currentmeal
        FROM am_analysis_header) THEN
        1
      ELSE
        0
      END,
    am_analysis_null = CASE
      WHEN (SELECT mealcount FROM am_analysis_header) > 1 THEN
        0
      WHEN (SELECT mealcount FROM am_analysis_header) = 1 AND
        (SELECT lastmeal FROM am_analysis_header) != (SELECT currentmeal
        FROM am_analysis_header) THEN
        0
      ELSE
        1
      END,
    rm_analysis = CASE
      WHEN (SELECT mealcount FROM rm_analysis_header) = 1 THEN
        1
      ELSE
        0
      END,
    rm_analysis_null = CASE
      WHEN (SELECT mealcount FROM rm_analysis_header) = 0 THEN
        1
      ELSE
        0
      END;
END;
"""
