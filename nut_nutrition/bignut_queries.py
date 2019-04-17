# .read load
# .read logic !! only if new database, it can wipe everything
# .read user
# .headers ON user for debugging

get_defined_nutrients = 'SELECT * FROM nutr_def;'

set_nutrient_dv = '''
UPDATE nutr_def
SET nutopt =
    CASE WHEN :nutopt IS NOT NULL THEN
        :nutopt
    ELSE
        0
    END
WHERE Nutr_No = :Nutr_No;
'''

set_number_of_meals_to_analyze = 'UPDATE options SET defanal_am = ?;'
get_number_of_meals_to_analyze = 'SELECT defanal_am FROM options;'
# to implement
get_day_meals = ''

get_weight_unit = 'SELECT grams FROM options;'
set_weight_unit = 'UPDATE options set grams = ?'

get_current_meal = 'SELECT currentmeal FROM options;'
get_current_meal_food = '''
SELECT mf.NDB_No AS NDB_No, Long_Desc, mf.Gm_Wgt, Nutr_No
FROM mealfoods mf
NATURAL JOIN food_des
LEFT JOIN pref_Gm_Wgt pGW USING (NDB_No)
LEFT JOIN nutr_def USING (Nutr_No)
WHERE meal_id = (SELECT currentmeal FROM OPTIONS)
ORDER BY Shrt_Desc;
'''


get_current_meal_str = 'SELECT cm_string FROM cm_string;'
set_current_meal = 'UPDATE options set currentmeal = ?;'
get_meal_from_offset_rel_to_current = """
-- This gets the nth meal id relative to the current meal
SELECT meal_id
FROM (
    SELECT dense_rank() over (order by meal_id) as offset, meal_id
    FROM mealfoods
    GROUP BY meal_id
)
WHERE offset = (
    SELECT offset+? FROM (
        SELECT dense_rank() over (order by meal_id) as offset, meal_id
        FROM mealfoods
        GROUP BY meal_id
    ) WHERE meal_id = (SELECT currentmeal FROM options)
)
GROUP BY meal_id;
"""

get_macro_pct = 'SELECT macropct from am_analysis_header;'
get_rm_analysis_header = 'SELECT * from rm_analysis_header;'
# need to add default values for non present nutrients
get_rm_analysis = '''
SELECT rm_analysis.Nutr_No, Nutr_val, Units, NutrDesc,
    dvpct_offset + 100
FROM rm_analysis
LEFT JOIN rm_dv on rm_analysis.Nutr_No = rm_dv.Nutr_No
NATURAL JOIN nutr_def NATURAL JOIN rm_analysis;
'''
get_am_analysis = '''
SELECT am_analysis.Nutr_No, Nutr_val, Units, NutrDesc,
    dvpct_offset + 100
FROM am_analysis
LEFT JOIN am_dv on am_analysis.Nutr_No = am_dv.Nutr_No
NATURAL JOIN nutr_def NATURAL JOIN am_analysis;
'''
get_am_analysis_period = 'SELECT firstmeal, lastmeal FROM am_analysis_header;'

get_omega6_3_bal = 'SELECT n6balance from am_analysis_header;'

get_food_groups = 'SELECT FdGrp_Cd, FdGrp_Desc FROM fd_group;'

set_food_pcf = '''
UPDATE mealfoods
SET Nutr_No = :Nutr_No
WHERE CASE
        WHEN :meal_id IS NULL THEN
            (SELECT currentmeal FROM OPTIONS)
        ELSE
            :meal_id
        END AND NDB_No = :NDB_No;
'''
set_food_amount = '''
UPDATE mealfoods
SET Gm_Wgt = :Gm_Wgt
WHERE CASE
        WHEN :meal_id IS NULL THEN
            (SELECT currentmeal FROM OPTIONS)
        ELSE
            :meal_id
        END AND NDB_No = :NDB_No;
'''


insert_food_into_meal = '''
INSERT OR REPLACE INTO mealfoods
    VALUES (CASE
                WHEN :meal_id IS NULL THEN
                    (SELECT currentmeal FROM OPTIONS)
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
        meal_id = (SELECT currentmeal FROM OPTIONS)
    END
    AND NDB_No = :NDB_No;
'''

get_food_list = 'SELECT NDB_No, Long_Desc FROM food_des;'
get_food_from_NDB_No = 'SELECT * FROM food_des WHERE NDB_No = :NDB_No;'
search_food = 'select NDB_No, Long_Desc from food_des where Long_Desc'\
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

# need to implement imperial version
# Parameters: nutrient id, start date, end date
# Parameters Types: Nutr_No, %Y%m%d, %Y%m%d
get_nutrient_story = '''
SELECT day, ROUND(SUM(meal_total_nutrient))
FROM (
    SELECT meal_id/100 as day,
        SUM(Gm_Wgt / 100.0 * nutrient.Nutr_Val) AS meal_total_nutrient
    FROM mealfoods JOIN nut_data nutrient USING (NDB_No)
    WHERE nutrient.Nutr_No = :Nutr_No
        AND meal_id >= :start_date || '00'
        AND meal_id <= :end_date || '99'
    GROUP by day, NDB_No)
GROUP by day;
'''

foods_ranked_per_100_grams = '''
SELECT NDB_No, FdGrp_Cd, Long_Desc, 100, 'g', Nutr_val, Units
FROM food_des
NATURAL JOIN nut_data
NATURAL JOIN nutr_def
WHERE Nutr_No = :Nutr_val AND
    CASE :FdGrp_Cd
        -- If the parameter is 0, no group filter should be applied
        WHEN 0 then 1
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
        -- If the parameter is 0, no group filter should be applied
        WHEN 0 then 1
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
    Long_desc,
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
        -- If the parameter is 0, no group filter should be applied
        WHEN 0 then 1
        ELSE FdGrp_Cd = :FdGrp_Cd
    END
ORDER BY nutrient DESC;
'''

get_nutrient_name = 'SELECT NutrDesc FROM nutr_def WHERE Nutr_No = ?;'


get_meal_by_id = 'SELECT * FROM mealfoods WHERE meal_id = ?'

get_weight_log = 'select * from wlog;'
get_weight_summary = 'SELECT verbiage FROM wlsummary;'
get_last_weight = 'SELECT weight FROM wlog ORDER BY wldate DESC LIMIT 1;'
get_last_bodyfat = 'SELECT bodyfat FROM wlog ORDER BY wldate DESC LIMIT 1;'
insert_weight_log = 'insert into wlog values (?, ?, null, null);'
clear_weight_log = 'insert into wlsummary select \'clear\';'

get_personal_nutrient_dv = """
SELECT dv
FROM am_dv
WHERE Nutr_No = ?;
"""

user_init_query = """
PRAGMA recursive_triggers = 1;

BEGIN;

DROP TRIGGER IF EXISTS before_mealfoods_insert_pcf;


CREATE TEMP TRIGGER before_mealfoods_insert_pcf
BEFORE
INSERT ON mealfoods WHEN
  (SELECT block_mealfoods_insert_trigger
   FROM z_trig_ctl) = 0 BEGIN
UPDATE z_trig_ctl
SET block_mealfoods_delete_trigger = 1; END;

DROP TRIGGER IF EXISTS mealfoods_insert_pcf;


CREATE TEMP TRIGGER mealfoods_insert_pcf AFTER
INSERT ON mealfoods WHEN NEW.meal_id =
  (SELECT currentmeal
   FROM OPTIONS)
AND
  (SELECT block_mealfoods_insert_trigger
   FROM z_trig_ctl) = 0 BEGIN
UPDATE z_trig_ctl
SET rm_analysis = 1;
UPDATE z_trig_ctl
SET am_analysis = 1;
UPDATE z_trig_ctl
SET am_dv = 1;
UPDATE z_trig_ctl
SET PCF_processing = 1; END;

DROP TRIGGER IF EXISTS mealfoods_update_pcf;


CREATE TEMP TRIGGER mealfoods_update_pcf AFTER
UPDATE ON mealfoods WHEN OLD.meal_id =
  (SELECT currentmeal
   FROM OPTIONS) BEGIN
UPDATE z_trig_ctl
SET rm_analysis = 1;
UPDATE z_trig_ctl
SET am_analysis = 1;
UPDATE z_trig_ctl
SET am_dv = 1;
UPDATE z_trig_ctl
SET PCF_processing = 1; END;

DROP TRIGGER IF EXISTS mealfoods_delete_pcf;


CREATE TEMP TRIGGER mealfoods_delete_pcf AFTER
DELETE ON mealfoods WHEN OLD.meal_id =
  (SELECT currentmeal
   FROM OPTIONS)
AND
  (SELECT block_mealfoods_delete_trigger
   FROM z_trig_ctl) = 0 BEGIN
UPDATE z_trig_ctl
SET am_analysis_header = 1;
UPDATE z_trig_ctl
SET rm_analysis = 1;
UPDATE z_trig_ctl
SET am_analysis = 1;
UPDATE z_trig_ctl
SET am_dv = 1;
UPDATE z_trig_ctl
SET PCF_processing = 1; END;

DROP TRIGGER IF EXISTS update_nutopt_pcf;


CREATE TEMP TRIGGER update_nutopt_pcf AFTER
UPDATE OF nutopt ON nutr_def BEGIN
UPDATE z_trig_ctl
SET rm_analysis = 1;
UPDATE z_trig_ctl
SET am_analysis = 1;
UPDATE z_trig_ctl
SET am_dv = 1;
UPDATE z_trig_ctl
SET PCF_processing = 1; END;


DROP TRIGGER IF EXISTS update_FAPU1_pcf;


CREATE TEMP TRIGGER update_FAPU1_pcf AFTER
UPDATE OF FAPU1 ON OPTIONS BEGIN
UPDATE z_trig_ctl
SET rm_analysis = 1;
UPDATE z_trig_ctl
SET am_analysis = 1;
UPDATE z_trig_ctl
SET am_dv = 1;
UPDATE z_trig_ctl
SET PCF_processing = 1; END;

DROP VIEW IF EXISTS pref_Gm_Wgt;


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
NATURAL JOIN
  (SELECT NDB_No,
          min(Seq) AS Seq
   FROM weight
   GROUP BY NDB_No);

DROP TRIGGER IF EXISTS pref_weight_Gm_Wgt;


CREATE TEMP TRIGGER pref_weight_Gm_Wgt INSTEAD OF
UPDATE OF Gm_Wgt ON pref_Gm_Wgt WHEN NEW.Gm_Wgt > 0.0 BEGIN
UPDATE weight
SET Gm_Wgt = NEW.Gm_Wgt
WHERE NDB_No = NEW.NDB_No
  AND Seq =
    (SELECT min(Seq)
     FROM weight
     WHERE NDB_No = NEW.NDB_No); END;

DROP TRIGGER IF EXISTS pref_weight_Amount;


CREATE TEMP TRIGGER pref_weight_Amount INSTEAD OF
UPDATE OF Amount ON pref_Gm_Wgt WHEN NEW.Amount > 0.0 BEGIN
UPDATE weight
SET Gm_Wgt = origGm_Wgt * NEW.Amount / Amount
WHERE NDB_No = NEW.NDB_No
  AND Seq =
    (SELECT min(Seq)
     FROM weight
     WHERE NDB_No = NEW.NDB_No);
  UPDATE currentmeal
  SET Gm_Wgt = NULL WHERE NDB_No = NEW.NDB_No; END;

DROP VIEW IF EXISTS view_foods;


CREATE TEMP VIEW view_foods AS
SELECT NutrDesc,
       NDB_No,
       substr(Shrt_Desc, 1, 45),
       round(Nutr_Val * Gm_Wgt / 100.0, 1) AS Nutr_Val,
       Units,
       cast(cast(round(Nutr_Val * Gm_Wgt / dv) AS int) AS text) || '% DV' AS dv
FROM nutr_def
NATURAL JOIN nut_data
LEFT JOIN am_dv USING (Nutr_No)
NATURAL JOIN food_des
NATURAL JOIN pref_Gm_Wgt;

DROP VIEW IF EXISTS currentmeal;


CREATE TEMP VIEW currentmeal AS
SELECT mf.NDB_No AS NDB_No,
       CASE
           WHEN
                  (SELECT grams
                   FROM OPTIONS) THEN CAST (CAST (round(mf.Gm_Wgt) AS int) AS text) || ' g'
           ELSE cast(round(mf.Gm_Wgt / 28.35 * 8.0) / 8.0 AS text) || ' oz'
       END || ' (' || cast(round(CASE
                                     WHEN mf.Gm_Wgt <= 0.0
                                          OR mf.Gm_Wgt != pGW.Gm_Wgt THEN mf.Gm_Wgt / origGm_Wgt * origAmount
                                     ELSE Amount
                                 END * 8.0) / 8.0 AS text) || ' ' || Msre_Desc || ') ' || Shrt_Desc || ' ' AS Gm_Wgt,
              NutrDesc
FROM mealfoods mf
NATURAL JOIN food_des
LEFT JOIN pref_Gm_Wgt pGW USING (NDB_No)
LEFT JOIN nutr_def USING (Nutr_No)
WHERE meal_id =
    (SELECT currentmeal
     FROM OPTIONS)
ORDER BY Shrt_Desc;

DROP TRIGGER IF EXISTS currentmeal_insert;


CREATE TEMP TRIGGER currentmeal_insert INSTEAD OF
INSERT ON currentmeal BEGIN
UPDATE mealfoods
SET Nutr_No = NULL
WHERE Nutr_No =
    (SELECT Nutr_No
     FROM nutr_def
     WHERE NutrDesc = NEW.NutrDesc);
  INSERT
  OR
  REPLACE INTO mealfoods
VALUES (
          (SELECT currentmeal
           FROM OPTIONS), NEW.NDB_No,
                          CASE
                              WHEN NEW.Gm_Wgt IS NULL THEN
                                     (SELECT Gm_Wgt
                                      FROM pref_Gm_Wgt
                                      WHERE NDB_No = NEW.NDB_No)
                              ELSE NEW.Gm_Wgt
                          END,
                          CASE
                              WHEN NEW.NutrDesc IS NULL THEN NULL
                              WHEN
                                     (SELECT count(*)
                                      FROM nutr_def
                                      WHERE NutrDesc = NEW.NutrDesc
                                        AND dv_default > 0.0) = 1 THEN
                                     (SELECT Nutr_No
                                      FROM nutr_def
                                      WHERE NutrDesc = NEW.NutrDesc)
                              WHEN
                                     (SELECT count(*)
                                      FROM nutr_def
                                      WHERE Nutr_No = NEW.NutrDesc
                                        AND dv_default > 0.0) = 1 THEN NEW.NutrDesc
                              ELSE NULL
                          END);

END;

DROP TRIGGER IF EXISTS currentmeal_delete;


CREATE TEMP TRIGGER currentmeal_delete INSTEAD OF
DELETE ON currentmeal BEGIN
DELETE
FROM mealfoods
WHERE meal_id =
    (SELECT currentmeal
     FROM OPTIONS)
  AND NDB_No = OLD.NDB_No; END;

DROP TRIGGER IF EXISTS currentmeal_upd_Gm_Wgt;


CREATE TEMP TRIGGER currentmeal_upd_Gm_Wgt INSTEAD OF
UPDATE OF Gm_Wgt ON currentmeal BEGIN
UPDATE mealfoods
SET Gm_Wgt = CASE
                 WHEN NEW.Gm_Wgt IS NULL THEN
                        (SELECT Gm_Wgt
                         FROM pref_Gm_Wgt
                         WHERE NDB_No = NEW.NDB_No)
                 ELSE NEW.Gm_Wgt
             END
WHERE NDB_No = NEW.NDB_No
  AND meal_id =
    (SELECT currentmeal
     FROM OPTIONS);

END;

DROP TRIGGER IF EXISTS currentmeal_upd_pcf;


CREATE TEMP TRIGGER currentmeal_upd_pcf INSTEAD OF
UPDATE OF NutrDesc ON currentmeal BEGIN
UPDATE mealfoods
SET Nutr_No = NULL
WHERE Nutr_No =
    (SELECT Nutr_No
     FROM nutr_def
     WHERE NutrDesc = NEW.NutrDesc);
  UPDATE mealfoods
  SET Nutr_No =
    (SELECT Nutr_No
     FROM nutr_def
     WHERE NutrDesc = NEW.NutrDesc) WHERE NDB_No = NEW.NDB_No
  AND meal_id =
    (SELECT currentmeal
     FROM OPTIONS); END;

DROP VIEW IF EXISTS theusual;


CREATE TEMP VIEW theusual AS
SELECT meal_name,
       NDB_No,
       Gm_Wgt,
       NutrDesc
FROM z_tu
NATURAL JOIN pref_Gm_Wgt
LEFT JOIN nutr_def USING (Nutr_No);

DROP TRIGGER IF EXISTS theusual_insert;


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
     FROM OPTIONS); END;

DROP TRIGGER IF EXISTS theusual_delete;


CREATE TEMP TRIGGER theusual_delete INSTEAD OF
DELETE ON theusual WHEN OLD.meal_name IS NOT NULL BEGIN
DELETE
FROM z_tu
WHERE meal_name = OLD.meal_name; END;

DROP VIEW IF EXISTS nut_in_meals;


CREATE TEMP VIEW nut_in_meals AS
SELECT NutrDesc,
       round(sum(Gm_Wgt * Nutr_Val / 100.0 /
                   (SELECT mealcount
                    FROM am_analysis_header) *
                   (SELECT meals_per_day
                    FROM OPTIONS)), 1) AS Nutr_Val,
       Units,
       mf.ndb_no,
       Shrt_Desc
FROM mealfoods mf
JOIN food_des USING (NDB_No)
JOIN nutr_def nd
JOIN nut_data DATA ON mf.NDB_No = data.NDB_No
AND nd.Nutr_No = data.Nutr_No
WHERE meal_id >=
    (SELECT firstmeal
     FROM am_analysis_header)
GROUP BY mf.NDB_No,
         NutrDesc
ORDER BY Nutr_Val DESC;

DROP VIEW IF EXISTS nutdv_in_meals;


CREATE TEMP VIEW nutdv_in_meals AS
SELECT NutrDesc,
       cast(cast(round(sum(Gm_Wgt * Nutr_Val / dv /
                             (SELECT mealcount
                              FROM am_analysis_header) *
                             (SELECT meals_per_day
                              FROM OPTIONS))) AS int) AS text) || '%' AS val,
       mf.ndb_no,
       Shrt_Desc
FROM mealfoods mf
JOIN food_des USING (NDB_No)
JOIN nutr_def nd
JOIN nut_data DATA ON mf.NDB_No = data.NDB_No
AND nd.Nutr_No = data.Nutr_No
JOIN am_dv ON nd.Nutr_No = am_dv.Nutr_No
WHERE meal_id >=
    (SELECT firstmeal
     FROM am_analysis_header)
GROUP BY mf.NDB_No,
         NutrDesc
ORDER BY cast(val AS int) DESC;

DROP VIEW IF EXISTS daily_food;


CREATE TEMP VIEW daily_food AS
SELECT cast(round((sum(mf.Gm_Wgt) / mealcount * meals_per_day) / origGm_Wgt * origAmount * 8.0) / 8.0 AS text) || ' ' || Msre_Desc || ' ' || Shrt_Desc AS food
FROM mealfoods mf
NATURAL JOIN food_des
JOIN pref_Gm_Wgt USING (NDB_No)
JOIN am_analysis_header
WHERE meal_id BETWEEN firstmeal AND lastmeal
GROUP BY NDB_No
ORDER BY Shrt_Desc;


DROP VIEW IF EXISTS daily_food1;

CREATE TEMP VIEW daily_food1 AS
SELECT cast(round(sum(8.0 * gm_wgt / 28.35 / mealcount * meals_per_day)) / 8.0 AS text) || ' oz ' || Long_desc
FROM mealfoods
NATURAL JOIN food_des
JOIN am_analysis_header
WHERE meal_id BETWEEN firstmeal AND lastmeal
GROUP BY ndb_no
ORDER BY long_desc;


DROP VIEW IF EXISTS nut_big_contrib;


CREATE TEMP VIEW nut_big_contrib AS
SELECT shrt_desc,
       nutrdesc,
       max(nutr_val),
       units
FROM
  (SELECT *
   FROM nut_in_meals
   ORDER BY nutrdesc ASC, nutr_val DESC)
GROUP BY nutrdesc
ORDER BY shrt_desc;


DROP VIEW IF EXISTS nutdv_big_contrib;


CREATE TEMP VIEW nutdv_big_contrib AS
SELECT nut_big_contrib.*
FROM nut_big_contrib
NATURAL JOIN nutr_def
WHERE dv_default > 0.0
ORDER BY shrt_desc;

DROP VIEW IF EXISTS nut_in_100g;


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


DROP VIEW IF EXISTS nut_in_100cal;


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

DROP TABLE IF EXISTS wlsave;


CREATE TEMP TABLE wlsave (weight real, fat real, wldate integer, span integer, today integer);


DROP TRIGGER IF EXISTS autocal_cutting;


CREATE TEMP TRIGGER autocal_cutting AFTER
INSERT ON z_wl WHEN
  (SELECT autocal = 2
   AND weightn > 1
   AND fatslope > 0.0
   AND (weightslope - fatslope) > 0.0
   FROM z_wslope,
        z_fslope,
        OPTIONS) BEGIN
DELETE
FROM wlsave;
INSERT INTO wlsave
SELECT weightyintercept,
       fatyintercept,
       wldate,
       span,
       today
FROM z_wslope,
     z_fslope,
     z_span,
  (SELECT min(wldate) AS wldate
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
UPDATE nutr_def
SET nutopt = nutopt - 20.0
WHERE Nutr_No = 208; END;


DROP TRIGGER IF EXISTS autocal_bulking;


CREATE TEMP TRIGGER autocal_bulking AFTER
INSERT ON z_wl WHEN
  (SELECT autocal = 2
   AND weightn > 1
   AND fatslope < 0.0
   AND (weightslope - fatslope) < 0.0
   FROM z_wslope,
        z_fslope,
        OPTIONS) BEGIN
DELETE
FROM wlsave;
INSERT INTO wlsave
SELECT weightyintercept,
       fatyintercept,
       wldate,
       span,
       today
FROM z_wslope,
     z_fslope,
     z_span,
  (SELECT min(wldate) AS wldate
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
UPDATE nutr_def
SET nutopt = nutopt + 20.0
WHERE Nutr_No = 208; END;


DROP TRIGGER IF EXISTS autocal_cycle_end;


CREATE TEMP TRIGGER autocal_cycle_end AFTER
INSERT ON z_wl WHEN
  (SELECT autocal = 2
   AND weightn > 1
   AND fatslope > 0.0
   AND (weightslope - fatslope) < 0.0
   FROM z_wslope,
        z_fslope,
        OPTIONS) BEGIN
DELETE
FROM wlsave;
INSERT INTO wlsave
SELECT weightyintercept,
       fatyintercept,
       wldate,
       span,
       today
FROM z_wslope,
     z_fslope,
     z_span,
  (SELECT min(wldate) AS wldate
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
FROM wlsave; END;

CREATE TABLE IF NOT EXISTS shopping (n integer PRIMARY KEY,
                                                       item text, store text);


DROP VIEW IF EXISTS shopview;


CREATE TEMP VIEW shopview AS
SELECT 'Shopping List ' || group_concat(n || ': ' || item || ' (' || store || ')', ' ')
FROM
  (SELECT *
   FROM shopping
   ORDER BY store,
            item);

CREATE TABLE IF NOT EXISTS cost (ndb_no int PRIMARY KEY,
                                                    gm_size real, cost real);

DROP VIEW IF EXISTS food_cost;


CREATE TEMP VIEW food_cost AS
SELECT ndb_no,
       round(sum(gm_wgt / gm_size * cost * meals_per_day / mealcount), 2) AS cost,
       long_desc
FROM mealfoods
NATURAL JOIN food_des
NATURAL JOIN cost
JOIN am_analysis_header
WHERE meal_id BETWEEN firstmeal AND lastmeal
GROUP BY ndb_no
ORDER BY cost DESC;


DROP VIEW IF EXISTS food_cost_cm;


CREATE TEMP VIEW food_cost_cm AS
SELECT round(sum(gm_wgt / gm_size * cost), 2) AS cost
FROM mealfoods
NATURAL JOIN cost
JOIN OPTIONS
WHERE meal_id = currentmeal;


DROP VIEW IF EXISTS food_cost_total;


CREATE TEMP VIEW food_cost_total AS
SELECT sum(cost) AS cost
FROM food_cost;

DROP VIEW IF EXISTS max_chick;


CREATE TEMP VIEW max_chick AS WITH DATA (ndb_no,
                                         shrt_desc,
                                         pamount,
                                         famount,
                                         msre_desc) AS
  (SELECT f.NDB_No,
          Shrt_Desc,
          round(
                  (SELECT dv / 3.0 - 15.0
                   FROM am_dv
                   WHERE nutr_no = 203) / p.Nutr_Val * 100 / origGm_Wgt * Amount * 8) / 8.0,
          round(
                  (SELECT dv / 3.0 - 17.39
                   FROM am_dv
                   WHERE nutr_no = 204) / fat.Nutr_Val * 100 / origGm_Wgt * Amount * 8) / 8.0,
          Msre_Desc
   FROM food_des f
   JOIN nut_data p ON f.ndb_no = p.ndb_no
   AND p.nutr_no = 203
   JOIN nut_data fat ON f.ndb_no = fat.ndb_no
   AND fat.nutr_no = 204
   NATURAL JOIN weight
   WHERE f.NDB_No IN
       (SELECT ndb_no
        FROM food_des
        WHERE ndb_no > 99000
          AND Shrt_Desc LIKE '%chick%mic%'
        UNION SELECT 5088)
     AND Seq =
       (SELECT min(Seq)
        FROM weight
        WHERE weight.NDB_No = f.NDB_No))
SELECT ndb_no,
       shrt_desc,
       CASE
           WHEN pamount <= famount THEN pamount
           ELSE famount
       END,
       msre_desc
FROM DATA;

DROP VIEW IF EXISTS daily_macros;


CREATE TEMP VIEW daily_macros AS
SELECT DAY,
       round(sum(calories)) AS calories,
       cast(round(100.0 * sum(procals) / sum(calories)) AS int) || '/' || cast(round(100.0 * sum(chocals) / sum(calories)) AS int) || '/' || cast(round(100.0 * sum(fatcals) / sum(calories)) AS int) AS macropct,
       round(sum(protein)) AS protein,
       round(sum(nfc)) AS nfc,
       round(sum(fat)) AS fat,
       bodycomp
FROM
  (SELECT meal_id / 100 AS DAY,
          NDB_No,
          sum(Gm_Wgt / 100.0 * cals.Nutr_Val) AS calories,
          sum(Gm_Wgt / 100.0 * pro.Nutr_Val) AS protein,
          sum(Gm_Wgt / 100.0 * crb.Nutr_Val) AS nfc,
          sum(Gm_Wgt / 100.0 * totfat.Nutr_Val) AS fat,
          sum(Gm_Wgt / 100.0 * pcals.Nutr_Val) AS procals,
          sum(Gm_Wgt / 100.0 * ccals.Nutr_Val) AS chocals,
          sum(Gm_Wgt / 100.0 * fcals.Nutr_Val) AS fatcals,
          bodycomp
   FROM mealfoods
   JOIN nut_data cals USING (NDB_No)
   JOIN nut_data pro USING (NDB_No)
   JOIN nut_data crb USING (NDB_No)
   JOIN nut_data totfat USING (NDB_No)
   JOIN nut_data pcals USING (NDB_No)
   JOIN nut_data ccals USING (NDB_No)
   JOIN nut_data fcals USING (NDB_No)
   LEFT JOIN
     (SELECT *
      FROM wlview
      GROUP BY wldate) ON DAY = wldate
   WHERE cals.Nutr_No = 208
     AND pro.Nutr_No = 203
     AND crb.Nutr_No = 2000
     AND totfat.Nutr_No = 204
     AND pcals.Nutr_No = 3000
     AND ccals.Nutr_No = 3002
     AND fcals.Nutr_No = 3001
   GROUP BY DAY,
            NDB_No)
GROUP BY DAY;

DROP VIEW IF EXISTS ranalysis;


CREATE TEMP VIEW ranalysis AS
SELECT NutrDesc,
       round(Nutr_Val, 1) || ' ' || Units,
       cast(cast(round(100.0 + dvpct_offset) AS int) AS text) || '%'
FROM rm_analysis
NATURAL JOIN rm_dv
NATURAL JOIN nutr_def
ORDER BY dvpct_offset DESC;

DROP VIEW IF EXISTS analysis;


CREATE TEMP VIEW analysis AS
SELECT NutrDesc,
       round(Nutr_Val, 1) || ' ' || Units,
       cast(cast(round(100.0 + dvpct_offset) AS int) AS text) || '%'
FROM am_analysis
NATURAL JOIN am_dv
NATURAL JOIN nutr_def
ORDER BY dvpct_offset DESC;

CREATE TABLE IF NOT EXISTS eating_plan (plan_name text);

DROP VIEW IF EXISTS cm_string;


CREATE TEMP VIEW cm_string AS WITH cdate (cdate, meal) AS
  (SELECT substr(currentmeal, 1, 4) || '-' || substr(currentmeal, 5, 2) || '-'
                || substr(currentmeal, 7, 2),
          cast(substr(currentmeal, 9, 2) AS int)
   FROM OPTIONS)
SELECT CASE
           WHEN w = 0 THEN 'Sun'
           WHEN w = 1 THEN 'Mon'
           WHEN w = 2 THEN 'Tue'
           WHEN w = 3 THEN 'Wed'
           WHEN w = 4 THEN 'Thu'
           WHEN w = 5 THEN 'Fri'
           WHEN w = 6 THEN 'Sat'
       END || ' ' || CASE
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
  (SELECT cast(strftime('%w', cdate) AS int) AS w,
          cast(strftime('%m', cdate) AS int) AS m,
          cast(strftime('%d', cdate) AS int) AS d,
          strftime('%Y', cdate) AS y,
          meal
   FROM cdate);


COMMIT;

PRAGMA user_version = 38;
"""

db_load_pt1 = """
PRAGMA journal_mode = WAL;
begin;

CREATE temp TABLE ttnutr_def
  (
     nutr_no  TEXT,
     units    TEXT,
     tagname  TEXT,
     nutrdesc TEXT,
     num_dec  TEXT,
     sr_order INT
  );

CREATE temp TABLE tnutr_def
  (
     nutr_no    INT PRIMARY KEY,
     units      TEXT,
     tagname    TEXT,
     nutrdesc   TEXT,
     dv_default REAL,
     nutopt     REAL
  );

CREATE temp TABLE tfd_group
  (
     fdgrp_cd   INT,
     fdgrp_desc TEXT
  );

CREATE temp TABLE tfood_des
  (
     ndb_no      TEXT,
     fdgrp_cd    TEXT,
     long_desc   TEXT,
     shrt_desc   TEXT,
     comname     TEXT,
     manufacname TEXT,
     survey      TEXT,
     ref_desc    TEXT,
     refuse      INTEGER,
     sciname     TEXT,
     n_factor    REAL,
     pro_factor  REAL,
     fat_factor  REAL,
     cho_factor  REAL
  );

CREATE temp TABLE tweight
  (
     ndb_no     TEXT,
     seq        TEXT,
     amount     REAL,
     msre_desc  TEXT,
     gm_wgt     REAL,
     num_data_p INT,
     std_dev    REAL
  );

CREATE temp TABLE zweight
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

CREATE temp TABLE tnut_data
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
"""
db_load_pt2 = """
CREATE TABLE IF NOT EXISTS nutr_def
  (
     nutr_no    INT PRIMARY KEY,
     units      TEXT,
     tagname    TEXT,
     nutrdesc   TEXT,
     dv_default REAL,
     nutopt     REAL
  );

CREATE TABLE IF NOT EXISTS fd_group
  (
     fdgrp_cd   INT PRIMARY KEY,
     fdgrp_desc TEXT
  );

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

CREATE TABLE IF NOT EXISTS nut_data
  (
     ndb_no   INT,
     nutr_no  INT,
     nutr_val REAL,
     PRIMARY KEY(ndb_no, nutr_no)
  );

insert into tnutr_def select * from nutr_def;
INSERT
or     ignore
into   tnutr_def
SELECT trim(nutr_no, '~'),
       trim(units, '~'),
       trim(tagname, '~'),
       trim(nutrdesc, '~'),
       NULL,
       NULL
FROM   ttnutr_def;
update tnutr_def set Tagname = 'ADPROT' where Nutr_No = 257;
update tnutr_def set Tagname = 'VITD_BOTH' where Nutr_No = 328;
update tnutr_def set Tagname = 'LUT_ZEA' where Nutr_No = 338;
update tnutr_def set Tagname = 'VITE_ADDED' where Nutr_No = 573;
update tnutr_def set Tagname = 'VITB12_ADDED' where Nutr_No = 578;
update tnutr_def set Tagname = 'F22D1T' where Nutr_No = 664;
update tnutr_def set Tagname = 'F18D2T' where Nutr_No = 665;
update tnutr_def set Tagname = 'F18D2I' where Nutr_No = 666;
update tnutr_def set Tagname = 'F22D1C' where Nutr_No = 676;
update tnutr_def set Tagname = 'F18D3I' where Nutr_No = 856;
-- comment out the next line if you want to hassle the non-ascii micro char
update tnutr_def set Units = 'mcg' where hex(Units) = 'B567';
update tnutr_def set Units = 'kc' where Nutr_No = 208;
update tnutr_def set NutrDesc = 'Protein' where Nutr_No = 203;
update tnutr_def set NutrDesc = 'Total Fat' where Nutr_No = 204;
update tnutr_def set NutrDesc = 'Total Carb' where Nutr_No = 205;
update tnutr_def set NutrDesc = 'Ash' where Nutr_No = 207;
update tnutr_def set NutrDesc = 'Calories' where Nutr_No = 208;
update tnutr_def set NutrDesc = 'Starch' where Nutr_No = 209;
update tnutr_def set NutrDesc = 'Sucrose' where Nutr_No = 210;
update tnutr_def set NutrDesc = 'Glucose' where Nutr_No = 211;
update tnutr_def set NutrDesc = 'Fructose' where Nutr_No = 212;
update tnutr_def set NutrDesc = 'Lactose' where Nutr_No = 213;
update tnutr_def set NutrDesc = 'Maltose' where Nutr_No = 214;
update tnutr_def set NutrDesc = 'Ethyl Alcohol' where Nutr_No = 221;
update tnutr_def set NutrDesc = 'Water' where Nutr_No = 255;
update tnutr_def set NutrDesc = 'Adj. Protein' where Nutr_No = 257;
update tnutr_def set NutrDesc = 'Caffeine' where Nutr_No = 262;
update tnutr_def set NutrDesc = 'Theobromine' where Nutr_No = 263;
update tnutr_def set NutrDesc = 'Sugars' where Nutr_No = 269;
update tnutr_def set NutrDesc = 'Galactose' where Nutr_No = 287;
update tnutr_def set NutrDesc = 'Fiber' where Nutr_No = 291;
update tnutr_def set NutrDesc = 'Calcium' where Nutr_No = 301;
update tnutr_def set NutrDesc = 'Iron' where Nutr_No = 303;
update tnutr_def set NutrDesc = 'Magnesium' where Nutr_No = 304;
update tnutr_def set NutrDesc = 'Phosphorus' where Nutr_No = 305;
update tnutr_def set NutrDesc = 'Potassium' where Nutr_No = 306;
update tnutr_def set NutrDesc = 'Sodium' where Nutr_No = 307;
update tnutr_def set NutrDesc = 'Zinc' where Nutr_No = 309;
update tnutr_def set NutrDesc = 'Copper' where Nutr_No = 312;
update tnutr_def set NutrDesc = 'Fluoride' where Nutr_No = 313;
update tnutr_def set NutrDesc = 'Manganese' where Nutr_No = 315;
update tnutr_def set NutrDesc = 'Selenium' where Nutr_No = 317;
update tnutr_def set NutrDesc = 'Vit. A, IU' where Nutr_No = 318;
update tnutr_def set NutrDesc = 'Retinol' where Nutr_No = 319;
update tnutr_def set NutrDesc = 'Vitamin A' where Nutr_No = 320;
update tnutr_def set NutrDesc = 'B-Carotene' where Nutr_No = 321;
update tnutr_def set NutrDesc = 'A-Carotene' where Nutr_No = 322;
update tnutr_def set NutrDesc = 'A-Tocopherol' where Nutr_No = 323;
update tnutr_def set NutrDesc = 'Vit. D, IU' where Nutr_No = 324;
update tnutr_def set NutrDesc = 'Vitamin D2' where Nutr_No = 325;
update tnutr_def set NutrDesc = 'Vitamin D3' where Nutr_No = 326;
update tnutr_def set NutrDesc = 'Vitamin D' where Nutr_No = 328;
update tnutr_def set NutrDesc = 'B-Cryptoxanth.' where Nutr_No = 334;
update tnutr_def set NutrDesc = 'Lycopene' where Nutr_No = 337;
update tnutr_def set NutrDesc = 'Lutein+Zeaxan.' where Nutr_No = 338;
update tnutr_def set NutrDesc = 'B-Tocopherol' where Nutr_No = 341;
update tnutr_def set NutrDesc = 'G-Tocopherol' where Nutr_No = 342;
update tnutr_def set NutrDesc = 'D-Tocopherol' where Nutr_No = 343;
update tnutr_def set NutrDesc = 'A-Tocotrienol' where Nutr_No = 344;
update tnutr_def set NutrDesc = 'B-Tocotrienol' where Nutr_No = 345;
update tnutr_def set NutrDesc = 'G-Tocotrienol' where Nutr_No = 346;
update tnutr_def set NutrDesc = 'D-Tocotrienol' where Nutr_No = 347;
update tnutr_def set NutrDesc = 'Vitamin C' where Nutr_No = 401;
update tnutr_def set NutrDesc = 'Thiamin' where Nutr_No = 404;
update tnutr_def set NutrDesc = 'Riboflavin' where Nutr_No = 405;
update tnutr_def set NutrDesc = 'Niacin' where Nutr_No = 406;
update tnutr_def set NutrDesc = 'Panto. Acid' where Nutr_No = 410;
update tnutr_def set NutrDesc = 'Vitamin B6' where Nutr_No = 415;
update tnutr_def set NutrDesc = 'Folate' where Nutr_No = 417;
update tnutr_def set NutrDesc = 'Vitamin B12' where Nutr_No = 418;
update tnutr_def set NutrDesc = 'Choline' where Nutr_No = 421;
update tnutr_def set NutrDesc = 'Menaquinone-4' where Nutr_No = 428;
update tnutr_def set NutrDesc = 'Dihydro-K1' where Nutr_No = 429;
update tnutr_def set NutrDesc = 'Vitamin K1' where Nutr_No = 430;
update tnutr_def set NutrDesc = 'Folic Acid' where Nutr_No = 431;
update tnutr_def set NutrDesc = 'Folate, food' where Nutr_No = 432;
update tnutr_def set NutrDesc = 'Folate, DFE' where Nutr_No = 435;
update tnutr_def set NutrDesc = 'Betaine' where Nutr_No = 454;
update tnutr_def set NutrDesc = 'Tryptophan' where Nutr_No = 501;
update tnutr_def set NutrDesc = 'Threonine' where Nutr_No = 502;
update tnutr_def set NutrDesc = 'Isoleucine' where Nutr_No = 503;
update tnutr_def set NutrDesc = 'Leucine' where Nutr_No = 504;
update tnutr_def set NutrDesc = 'Lysine' where Nutr_No = 505;
update tnutr_def set NutrDesc = 'Methionine' where Nutr_No = 506;
update tnutr_def set NutrDesc = 'Cystine' where Nutr_No = 507;
update tnutr_def set NutrDesc = 'Phenylalanine' where Nutr_No = 508;
update tnutr_def set NutrDesc = 'Tyrosine' where Nutr_No = 509;
update tnutr_def set NutrDesc = 'Valine' where Nutr_No = 510;
update tnutr_def set NutrDesc = 'Arginine' where Nutr_No = 511;
update tnutr_def set NutrDesc = 'Histidine' where Nutr_No = 512;
update tnutr_def set NutrDesc = 'Alanine' where Nutr_No = 513;
update tnutr_def set NutrDesc = 'Aspartic acid' where Nutr_No = 514;
update tnutr_def set NutrDesc = 'Glutamic acid' where Nutr_No = 515;
update tnutr_def set NutrDesc = 'Glycine' where Nutr_No = 516;
update tnutr_def set NutrDesc = 'Proline' where Nutr_No = 517;
update tnutr_def set NutrDesc = 'Serine' where Nutr_No = 518;
update tnutr_def set NutrDesc = 'Hydroxyproline' where Nutr_No = 521;
update tnutr_def set NutrDesc = 'Vit. E added' where Nutr_No = 573;
update tnutr_def set NutrDesc = 'Vit. B12 added' where Nutr_No = 578;
update tnutr_def set NutrDesc = 'Cholesterol' where Nutr_No = 601;
update tnutr_def set NutrDesc = 'Trans Fat' where Nutr_No = 605;
update tnutr_def set NutrDesc = 'Sat Fat' where Nutr_No = 606;
update tnutr_def set NutrDesc = '4:0' where Nutr_No = 607;
update tnutr_def set NutrDesc = '6:0' where Nutr_No = 608;
update tnutr_def set NutrDesc = '8:0' where Nutr_No = 609;
update tnutr_def set NutrDesc = '10:0' where Nutr_No = 610;
update tnutr_def set NutrDesc = '12:0' where Nutr_No = 611;
update tnutr_def set NutrDesc = '14:0' where Nutr_No = 612;
update tnutr_def set NutrDesc = '16:0' where Nutr_No = 613;
update tnutr_def set NutrDesc = '18:0' where Nutr_No = 614;
update tnutr_def set NutrDesc = '20:0' where Nutr_No = 615;
update tnutr_def set NutrDesc = '18:1' where Nutr_No = 617;
update tnutr_def set NutrDesc = '18:2' where Nutr_No = 618;
update tnutr_def set NutrDesc = '18:3' where Nutr_No = 619;
update tnutr_def set NutrDesc = '20:4' where Nutr_No = 620;
update tnutr_def set NutrDesc = '22:6n-3' where Nutr_No = 621;
update tnutr_def set NutrDesc = '22:0' where Nutr_No = 624;
update tnutr_def set NutrDesc = '14:1' where Nutr_No = 625;
update tnutr_def set NutrDesc = '16:1' where Nutr_No = 626;
update tnutr_def set NutrDesc = '18:4' where Nutr_No = 627;
update tnutr_def set NutrDesc = '20:1' where Nutr_No = 628;
update tnutr_def set NutrDesc = '20:5n-3' where Nutr_No = 629;
update tnutr_def set NutrDesc = '22:1' where Nutr_No = 630;
update tnutr_def set NutrDesc = '22:5n-3' where Nutr_No = 631;
update tnutr_def set NutrDesc = 'Phytosterols' where Nutr_No = 636;
update tnutr_def set NutrDesc = 'Stigmasterol' where Nutr_No = 638;
update tnutr_def set NutrDesc = 'Campesterol' where Nutr_No = 639;
update tnutr_def set NutrDesc = 'BetaSitosterol' where Nutr_No = 641;
update tnutr_def set NutrDesc = 'Mono Fat' where Nutr_No = 645;
update tnutr_def set NutrDesc = 'Poly Fat' where Nutr_No = 646;
update tnutr_def set NutrDesc = '15:0' where Nutr_No = 652;
update tnutr_def set NutrDesc = '17:0' where Nutr_No = 653;
update tnutr_def set NutrDesc = '24:0' where Nutr_No = 654;
update tnutr_def set NutrDesc = '16:1t' where Nutr_No = 662;
update tnutr_def set NutrDesc = '18:1t' where Nutr_No = 663;
update tnutr_def set NutrDesc = '22:1t' where Nutr_No = 664;
update tnutr_def set NutrDesc = '18:2t' where Nutr_No = 665;
update tnutr_def set NutrDesc = '18:2i' where Nutr_No = 666;
update tnutr_def set NutrDesc = '18:2t,t' where Nutr_No = 669;
update tnutr_def set NutrDesc = '18:2CLA' where Nutr_No = 670;
update tnutr_def set NutrDesc = '24:1c' where Nutr_No = 671;
update tnutr_def set NutrDesc = '20:2n-6c,c' where Nutr_No = 672;
update tnutr_def set NutrDesc = '16:1c' where Nutr_No = 673;
update tnutr_def set NutrDesc = '18:1c' where Nutr_No = 674;
update tnutr_def set NutrDesc = '18:2n-6c,c' where Nutr_No = 675;
update tnutr_def set NutrDesc = '22:1c' where Nutr_No = 676;
update tnutr_def set NutrDesc = '18:3n-6c,c,c' where Nutr_No = 685;
update tnutr_def set NutrDesc = '17:1' where Nutr_No = 687;
update tnutr_def set NutrDesc = '20:3' where Nutr_No = 689;
update tnutr_def set NutrDesc = 'TransMonoenoic' where Nutr_No = 693;
update tnutr_def set NutrDesc = 'TransPolyenoic' where Nutr_No = 695;
update tnutr_def set NutrDesc = '13:0' where Nutr_No = 696;
update tnutr_def set NutrDesc = '15:1' where Nutr_No = 697;
update tnutr_def set NutrDesc = '18:3n-3c,c,c' where Nutr_No = 851;
update tnutr_def set NutrDesc = '20:3n-3' where Nutr_No = 852;
update tnutr_def set NutrDesc = '20:3n-6' where Nutr_No = 853;
update tnutr_def set NutrDesc = '20:4n-6' where Nutr_No = 855;
update tnutr_def set NutrDesc = '18:3i' where Nutr_No = 856;
update tnutr_def set NutrDesc = '21:5' where Nutr_No = 857;
update tnutr_def set NutrDesc = '22:4' where Nutr_No = 858;
update tnutr_def set NutrDesc = '18:1n-7t' where Nutr_No = 859;
insert or ignore into tnutr_def values(3000,'kc','PROT_KCAL','Protein Calories', NULL, NULL);
insert or ignore into tnutr_def values(3001,'kc','FAT_KCAL','Fat Calories', NULL, NULL);
insert or ignore into tnutr_def values(3002,'kc','CHO_KCAL','Carb Calories', NULL, NULL);
insert or ignore into tnutr_def values(2000,'g','CHO_NONFIB','Non-Fiber Carb', NULL, NULL);
insert or ignore into tnutr_def values(2001,'g','LA','LA', NULL, NULL);
insert or ignore into tnutr_def values(2002,'g','AA','AA', NULL, NULL);
insert or ignore into tnutr_def values(2003,'g','ALA','ALA', NULL, NULL);
insert or ignore into tnutr_def values(2004,'g','EPA','EPA', NULL, NULL);
insert or ignore into tnutr_def values(2005,'g','DHA','DHA', NULL, NULL);
insert or ignore into tnutr_def values(2006,'g','OMEGA6','Omega-6', NULL, NULL);
insert or ignore into tnutr_def values(3003,'g','SHORT6','Short-chain Omega-6', NULL, NULL);
insert or ignore into tnutr_def values(3004,'g','LONG6','Long-chain Omega-6', NULL, NULL);
insert or ignore into tnutr_def values(2007,'g','OMEGA3','Omega-3', NULL, NULL);
insert or ignore into tnutr_def values(3005,'g','SHORT3','Short-chain Omega-3', NULL, NULL);
insert or ignore into tnutr_def values(3006,'g','LONG3','Long-chain Omega-3', NULL, NULL);

-- These are the new "daily value" labeling standards minus "ADDED SUGARS" which
-- have not yet appeared in the USDA data.

insert or ignore into tnutr_def values(2008,'mg','VITE','Vitamin E', NULL, NULL);
update tnutr_def set dv_default = 2000.0 where Tagname = 'ENERC_KCAL';
update tnutr_def set dv_default = 50.0 where Tagname = 'PROCNT';
update tnutr_def set dv_default = 78.0 where Tagname = 'FAT';
update tnutr_def set dv_default = 275.0 where Tagname = 'CHOCDF';
update tnutr_def set dv_default = 28.0 where Tagname = 'FIBTG';
update tnutr_def set dv_default = 247.0 where Tagname = 'CHO_NONFIB';
update tnutr_def set dv_default = 1300.0 where Tagname = 'CA';
update tnutr_def set dv_default = 1250.0 where Tagname = 'P';
update tnutr_def set dv_default = 18.0 where Tagname = 'FE';
update tnutr_def set dv_default = 2300.0 where Tagname = 'NA';
update tnutr_def set dv_default = 4700.0 where Tagname = 'K';
update tnutr_def set dv_default = 420.0 where Tagname = 'MG';
update tnutr_def set dv_default = 11.0 where Tagname = 'ZN';
update tnutr_def set dv_default = 0.9 where Tagname = 'CU';
update tnutr_def set dv_default = 2.3 where Tagname = 'MN';
update tnutr_def set dv_default = 55.0 where Tagname = 'SE';
update tnutr_def set dv_default = null where Tagname = 'VITA_IU';
update tnutr_def set dv_default = 900.0 where Tagname = 'VITA_RAE';
update tnutr_def set dv_default = 15.0 where Tagname = 'VITE';
update tnutr_def set dv_default = 120.0 where Tagname = 'VITK1';
update tnutr_def set dv_default = 1.2 where Tagname = 'THIA';
update tnutr_def set dv_default = 1.3 where Tagname = 'RIBF';
update tnutr_def set dv_default = 16.0 where Tagname = 'NIA';
update tnutr_def set dv_default = 5.0 where Tagname = 'PANTAC';
update tnutr_def set dv_default = 1.7 where Tagname = 'VITB6A';
update tnutr_def set dv_default = 400.0 where Tagname = 'FOL';
update tnutr_def set dv_default = 2.4 where Tagname = 'VITB12';
update tnutr_def set dv_default = 550.0 where Tagname = 'CHOLN';
update tnutr_def set dv_default = 90.0 where Tagname = 'VITC';
update tnutr_def set dv_default = 20.0 where Tagname = 'FASAT';
update tnutr_def set dv_default = 300.0 where Tagname = 'CHOLE';
update tnutr_def set dv_default = null where Tagname = 'VITD';
update tnutr_def set dv_default = 20.0 where Tagname = 'VITD_BOTH';
update tnutr_def set dv_default = 8.9 where Tagname = 'FAPU';
update tnutr_def set dv_default = 0.2 where Tagname = 'AA';
update tnutr_def set dv_default = 3.8 where Tagname = 'ALA';
update tnutr_def set dv_default = 0.1 where Tagname = 'EPA';
update tnutr_def set dv_default = 0.1 where Tagname = 'DHA';
update tnutr_def set dv_default = 4.7 where Tagname = 'LA';
update tnutr_def set dv_default = 4.0 where Tagname = 'OMEGA3';
update tnutr_def set dv_default = 4.9 where Tagname = 'OMEGA6';
update tnutr_def set dv_default = 32.6 where Tagname = 'FAMS';
update tnutr_def set nutopt = 0.0 where dv_default > 0.0 and nutopt is null;
delete from nutr_def;
insert into nutr_def select * from tnutr_def;
create index if not exists tagname_index on nutr_def (Tagname asc);
drop table ttnutr_def;
drop table tnutr_def;

INSERT
or     REPLACE
into   fd_group
SELECT trim(fdgrp_cd, '~'),
       trim(fdgrp_desc, '~')
FROM   tfd_group;INSERT
or     REPLACE
into   fd_group VALUES
       (
              9999,
              'Added Recipes'
       );drop table tfd_group;

INSERT
or     REPLACE
into   food_des
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
SELECT trim(ndb_no, '~'),
       trim(fdgrp_cd, '~'),
       replace(trim(trim(long_desc, '~')
              || ' ('
              || trim(sciname, '~')
              || ')',' ('),' ()',''),
       upper(substr(trim(shrt_desc, '~'),1,1))
              || lower(substr(trim(shrt_desc, '~'),2)),
       trim(ref_desc, '~'),
       refuse,
       pro_factor,
       fat_factor,
       cho_factor
FROM   tfood_des;update food_des set Shrt_Desc = Long_Desc where length(Long_Desc) <= 60;

drop table tfood_des;

update tweight set NDB_No = trim(NDB_No,'~');
update tweight set Seq = trim(Seq,'~');
update tweight set Msre_Desc = trim(Msre_Desc,'~');

--We want every food to have a weight, so we make a '100 grams' weight
insert or replace into zweight select NDB_No, 99, 100, 'grams', 100, 99, 100 from food_des;

--Now we update zweight with the user's existing weight preferences
insert or replace into zweight select * from weight where Seq != origSeq or Gm_Wgt != origGm_Wgt;

--We overwrite real weight table with new USDA records
INSERT OR REPLACE INTO weight select NDB_No, Seq, Amount, Msre_Desc, Gm_Wgt, Seq, Gm_Wgt from tweight;

--We overwrite the real weight table with the original user mods
insert or replace into weight select * from zweight;
drop table tweight;
drop table zweight;


insert or replace into nut_data select trim(NDB_No, '~'), trim(Nutr_No, '~'), Nutr_Val from tnut_data;
drop table tnut_data;

  --insert VITE records into nut_data
INSERT
or     REPLACE
into   nut_data
SELECT    f.ndb_no,
          2008,
          ifnull(tocpha.nutr_val, 0.0)
FROM      food_des f
LEFT JOIN nut_data tocpha
ON        f.ndb_no = tocpha.ndb_no
AND       tocpha.nutr_no = 323
WHERE     tocpha.nutr_val IS NOT NULL;
  --insert LA records into nut_data
INSERT
or     REPLACE
into   nut_data
SELECT    f.ndb_no,
          2001,
          CASE
                    WHEN f18d2cn6.nutr_val IS NOT NULL THEN f18d2cn6.nutr_val
                    WHEN f18d2.nutr_val IS NOT NULL THEN f18d2.nutr_val - ifnull(f18d2t.nutr_val, 0.0) - ifnull(f18d2tt.nutr_val, 0.0) - ifnull(f18d2i.nutr_val, 0.0) - ifnull(f18d2cla.nutr_val, 0.0)
          END
FROM      food_des f
LEFT JOIN nut_data f18d2
ON        f.ndb_no = f18d2.ndb_no
AND       f18d2.nutr_no = 618
LEFT JOIN nut_data f18d2cn6
ON        f.ndb_no = f18d2cn6.ndb_no
AND       f18d2cn6.nutr_no = 675
LEFT JOIN nut_data f18d2t
ON        f.ndb_no = f18d2t.ndb_no
AND       f18d2t.nutr_no = 665
LEFT JOIN nut_data f18d2tt
ON        f.ndb_no = f18d2tt.ndb_no
AND       f18d2tt.nutr_no = 669
LEFT JOIN nut_data f18d2i
ON        f.ndb_no = f18d2i.ndb_no
AND       f18d2i.nutr_no = 666
LEFT JOIN nut_data f18d2cla
ON        f.ndb_no = f18d2cla.ndb_no
AND       f18d2cla.nutr_no = 670
WHERE     f18d2.nutr_val IS NOT NULL
OR        f18d2cn6.nutr_val IS NOT NULL
OR        f18d2t.nutr_val IS NOT NULL
OR        f18d2tt.nutr_val IS NOT NULL
OR        f18d2i.nutr_val IS NOT NULL
OR        f18d2cla.nutr_val IS NOT NULL;


--insert ALA records into nut_data
INSERT
or     REPLACE
into   nut_data
SELECT    f.ndb_no,
          2003,
          CASE
                    WHEN f18d3cn3.nutr_val IS NOT NULL THEN f18d3cn3.nutr_val
                    WHEN f18d3.nutr_val IS NOT NULL THEN f18d3.nutr_val - ifnull(f18d3cn6.nutr_val, 0.0) - ifnull(f18d3i.nutr_val, 0.0)
          END
FROM      food_des f
LEFT JOIN nut_data f18d3
ON        f.ndb_no = f18d3.ndb_no
AND       f18d3.nutr_no = 619
LEFT JOIN nut_data f18d3cn3
ON        f.ndb_no = f18d3cn3.ndb_no
AND       f18d3cn3.nutr_no = 851
LEFT JOIN nut_data f18d3cn6
ON        f.ndb_no = f18d3cn6.ndb_no
AND       f18d3cn6.nutr_no = 685
LEFT JOIN nut_data f18d3i
ON        f.ndb_no = f18d3i.ndb_no
AND       f18d3i.nutr_no = 856
WHERE     f18d3.nutr_val IS NOT NULL
OR        f18d3cn3.nutr_val IS NOT NULL
OR        f18d3cn6.nutr_val IS NOT NULL
OR        f18d3i.nutr_val IS NOT NULL;

--insert SHORT6 records into nut_data
INSERT
or     REPLACE
into   nut_data
SELECT    f.ndb_no,
          3003,
          ifnull(la.nutr_val, 0.0) + ifnull(f18d3cn6.nutr_val, 0.0)
FROM      food_des f
LEFT JOIN nut_data la
ON        f.ndb_no = la.ndb_no
AND       la.nutr_no = 2001
LEFT JOIN nut_data f18d3cn6
ON        f.ndb_no = f18d3cn6.ndb_no
AND       f18d3cn6.nutr_no = 685
WHERE     la.nutr_val IS NOT NULL
OR        f18d3cn6.nutr_val IS NOT NULL;

--insert SHORT3 records into nut_data
INSERT
or     REPLACE
into   nut_data
SELECT    f.ndb_no,
          3005,
          ifnull(ala.nutr_val, 0.0) + ifnull(f18d4.nutr_val, 0.0)
FROM      food_des f
LEFT JOIN nut_data ala
ON        f.ndb_no = ala.ndb_no
AND       ala.nutr_no = 2003
LEFT JOIN nut_data f18d4
ON        f.ndb_no = f18d4.ndb_no
AND       f18d4.nutr_no = 627
WHERE     ala.nutr_val IS NOT NULL
OR        f18d4.nutr_val IS NOT NULL;

--insert AA records into nut_data
INSERT
or     REPLACE
into   nut_data
SELECT    f.ndb_no,
          2002,
          CASE
                    WHEN f20d4n6.nutr_val IS NOT NULL THEN f20d4n6.nutr_val
                    ELSE f20d4.nutr_val
          END
FROM      food_des f
LEFT JOIN nut_data f20d4
ON        f.ndb_no = f20d4.ndb_no
AND       f20d4.nutr_no = 620
LEFT JOIN nut_data f20d4n6
ON        f.ndb_no = f20d4n6.ndb_no
AND       f20d4n6.nutr_no = 855
WHERE     f20d4.nutr_val IS NOT NULL
OR        f20d4n6.nutr_val IS NOT NULL;

--insert LONG6 records into nut_data
INSERT
or     REPLACE
into   nut_data
SELECT    f.ndb_no,
          3004,
          CASE
                    WHEN f20d3n6.nutr_val IS NOT NULL THEN ifnull(aa.nutr_val,0.0) + f20d3n6.nutr_val + ifnull(f22d4.nutr_val,0.0)
                    ELSE ifnull(aa.nutr_val,0.0)                                   + ifnull(f20d3.nutr_val,0.0) + ifnull(f22d4.nutr_val, 0.0)
          END
FROM      food_des f
LEFT JOIN nut_data aa
ON        f.ndb_no = aa.ndb_no
AND       aa.nutr_no = 2002
LEFT JOIN nut_data f20d3n6
ON        f.ndb_no = f20d3n6.ndb_no
AND       f20d3n6.nutr_no = 853
LEFT JOIN nut_data f20d3
ON        f.ndb_no = f20d3.ndb_no
AND       f20d3.nutr_no = 689
LEFT JOIN nut_data f22d4
ON        f.ndb_no = f22d4.ndb_no
AND       f22d4.nutr_no = 858
WHERE     aa.nutr_val IS NOT NULL
OR        f20d3n6.nutr_val IS NOT NULL
OR        f20d3.nutr_val IS NOT NULL
OR        f22d4.nutr_val IS NOT NULL;

--insert EPA records into nut_data
INSERT
or     REPLACE
into   nut_data
SELECT    f.ndb_no,
          2004,
          f20d5.nutr_val
FROM      food_des f
LEFT JOIN nut_data f20d5
ON        f.ndb_no = f20d5.ndb_no
AND       f20d5.nutr_no = 629
WHERE     f20d5.nutr_val IS NOT NULL;

--insert DHA records into nut_data
INSERT
or     REPLACE
into   nut_data
SELECT    f.ndb_no,
          2005,
          f22d6.nutr_val
FROM      food_des f
LEFT JOIN nut_data f22d6
ON        f.ndb_no = f22d6.ndb_no
AND       f22d6.nutr_no = 621
WHERE     f22d6.nutr_val IS NOT NULL;

--insert LONG3 records into nut_data
INSERT
or     REPLACE
into   nut_data
SELECT    f.ndb_no,
          3006,
          ifnull(epa.nutr_val, 0.0) + ifnull(dha.nutr_val, 0.0) + ifnull(f20d3n3.nutr_val, 0.0) + ifnull(f22d5.nutr_val, 0.0)
FROM      food_des f
LEFT JOIN nut_data epa
ON        f.ndb_no = epa.ndb_no
AND       epa.nutr_no = 2004
LEFT JOIN nut_data dha
ON        f.ndb_no = dha.ndb_no
AND       dha.nutr_no = 2005
LEFT JOIN nut_data f20d3n3
ON        f.ndb_no = f20d3n3.ndb_no
AND       f20d3n3.nutr_no = 852
LEFT JOIN nut_data f22d5
ON        f.ndb_no = f22d5.ndb_no
AND       f22d5.nutr_no = 631
WHERE     epa.nutr_val IS NOT NULL
OR        dha.nutr_val IS NOT NULL
OR        f20d3n3.nutr_val IS NOT NULL
OR        f22d5.nutr_val IS NOT NULL;

--insert OMEGA6 records into nut_data
INSERT
or     REPLACE
into   nut_data
SELECT    f.ndb_no,
          2006,
          ifnull(short6.nutr_val, 0.0) + ifnull(long6.nutr_val, 0.0)
FROM      food_des f
LEFT JOIN nut_data short6
ON        f.ndb_no = short6.ndb_no
AND       short6.nutr_no = 3003
LEFT JOIN nut_data long6
ON        f.ndb_no = long6.ndb_no
AND       long6.nutr_no = 3004
WHERE     short6.nutr_val IS NOT NULL
OR        long6.nutr_val IS NOT NULL;

--insert OMEGA3 records into nut_data
INSERT
or     REPLACE
into   nut_data
SELECT    f.ndb_no,
          2007,
          ifnull(short3.nutr_val, 0.0) + ifnull(long3.nutr_val, 0.0)
FROM      food_des f
LEFT JOIN nut_data short3
ON        f.ndb_no = short3.ndb_no
AND       short3.nutr_no = 3005
LEFT JOIN nut_data long3
ON        f.ndb_no = long3.ndb_no
AND       long3.nutr_no = 3006
WHERE     short3.nutr_val IS NOT NULL
OR        long3.nutr_val IS NOT NULL;

--insert CHO_NONFIB records into nut_data
INSERT
or     REPLACE
into   nut_data
SELECT    f.ndb_no,
          2000,
          CASE
                    WHEN chocdf.nutr_val - ifnull(fibtg.nutr_val, 0.0) < 0.0 THEN 0.0
                    ELSE chocdf.nutr_val - ifnull(fibtg.nutr_val, 0.0)
          END
FROM      food_des f
LEFT JOIN nut_data chocdf
ON        f.ndb_no = chocdf.ndb_no
AND       chocdf.nutr_no = 205
LEFT JOIN nut_data fibtg
ON        f.ndb_no = fibtg.ndb_no
AND       fibtg.nutr_no = 291
WHERE     chocdf.nutr_val IS NOT NULL;

--replace empty strings with values for macronutrient factors in food_des
UPDATE food_des
SET    pro_factor = 4.0
WHERE  pro_factor = ''
OR     pro_factor IS NULL;UPDATE food_des
SET    fat_factor = 9.0
WHERE  fat_factor = ''
OR     fat_factor IS NULL;UPDATE food_des
SET    cho_factor = 4.0
WHERE  cho_factor = ''
OR     cho_factor IS NULL;

--insert calories from macronutrients into nut_data
INSERT
or     REPLACE
into   nut_data
SELECT f.ndb_no,
       3000,
       f.pro_factor * procnt.nutr_val
FROM   food_des f
JOIN   nut_data procnt
ON     f.ndb_no = procnt.ndb_no
AND    procnt.nutr_no = 203;INSERT
or     REPLACE
into   nut_data
SELECT f.ndb_no,
       3001,
       f.fat_factor * fat.nutr_val
FROM   food_des f
JOIN   nut_data fat
ON     f.ndb_no = fat.ndb_no
AND    fat.nutr_no = 204;INSERT
or     REPLACE
into   nut_data
SELECT f.ndb_no,
       3002,
       f.cho_factor * chocdf.nutr_val
FROM   food_des f
JOIN   nut_data chocdf
ON     f.ndb_no = chocdf.ndb_no
AND    chocdf.nutr_no = 205;



CREATE TABLE IF NOT EXISTS options
  (
     protect       INTEGER PRIMARY KEY,
     defanal_am    INTEGER DEFAULT 2147123119,
     fapu1         REAL DEFAULT 0.0,
     meals_per_day INT DEFAULT 3,
     grams         INT DEFAULT 1,
     currentmeal   INT DEFAULT 0,
     wltweak       INTEGER DEFAULT 0,
     wlpolarity    INTEGER DEFAULT 0,
     autocal       INTEGER DEFAULT 0
  );


CREATE TABLE IF NOT EXISTS mealfoods
  (
     meal_id INT,
     ndb_no  INT,
     gm_wgt  REAL,
     nutr_no INT,
     PRIMARY KEY(meal_id, ndb_no)
  );

create table if not exists archive_mealfoods(meal_id int, NDB_No int, Gm_Wgt real, meals_per_day integer, primary key(meal_id desc, NDB_No asc, meals_per_day));

create table if not exists z_tu(meal_name text, NDB_No int, Nutr_No int, primary key(meal_name, NDB_No), unique(meal_name, Nutr_No));

create table if not exists z_wl(weight real, bodyfat real, wldate int, cleardate int, primary key(wldate, cleardate));

drop trigger if exists protect_options;
create trigger protect_options after insert on options begin delete from options where protect != 1; end;

insert into options default values;

drop trigger protect_options;

UPDATE options
SET currentmeal = CAST(STRFTIME('%Y%m%d01', DATE('now')) AS INTEGER);

--commit;
vacuum;
"""

# This query will wipe everything USE WITH CARE
init_logic = """
begin;

DROP TABLE if exists z_vars1;
CREATE TABLE z_vars1 (am_cals2gram_pro real, am_cals2gram_fat real, am_cals2gram_cho real, am_alccals real, am_fa2fat real, balance_of_calories int);

DROP TABLE if exists z_vars2;
CREATE TABLE z_vars2 (am_fat_dv_not_boc real, am_cho_nonfib_dv_not_boc real, am_chocdf_dv_not_boc real);

DROP TABLE if exists z_vars3;
CREATE TABLE z_vars3 (am_fat_dv_boc real, am_chocdf_dv_boc real, am_cho_nonfib_dv_boc real);

DROP TABLE if exists z_vars4;
CREATE TABLE z_vars4 (Nutr_No int, dv real, Nutr_Val real);


DROP TABLE if exists z_n6;
CREATE TABLE z_n6 (n6hufa real, FAPU1 real, pufa_reduction real, iter int, reduce int, p3 real, p6 real, h3 real, h6 real, o real);


drop table if exists z_anal;
create table z_anal (Nutr_No int primary key, null_value int, Nutr_Val real);


drop table if exists am_analysis_header;
create table am_analysis_header (maxmeal int, mealcount int, meals_per_day int, firstmeal integer, lastmeal integer, currentmeal integer, caloriebutton text, macropct text, n6balance text);


drop table if exists am_dv;
create table am_dv (Nutr_No int primary key asc, dv real, dvpct_offset real);

drop table if exists rm_analysis_header;
create table rm_analysis_header (maxmeal int, mealcount int, meals_per_day int, firstmeal integer, lastmeal integer, currentmeal integer, caloriebutton text, macropct text, n6balance text);

drop table if exists rm_analysis;
create table rm_analysis (Nutr_No int primary key asc, null_value int, Nutr_Val real);

drop table if exists rm_dv;
create table rm_dv (Nutr_No int primary key asc, dv real, dvpct_offset real);

drop view if exists am_analysis;
create view am_analysis as select am.Nutr_No as Nutr_No, case when currentmeal between firstmeal and lastmeal and am.null_value = 1 and rm.null_value = 1 then 1 when currentmeal not between firstmeal and lastmeal and am.null_value = 1 then 1 else 0 end as null_value, case when currentmeal between firstmeal and lastmeal then ifnull(am.Nutr_Val,0.0) + 1.0 / mealcount * ifnull(rm.Nutr_Val, 0.0) else am.Nutr_Val end as Nutr_Val from z_anal am left join rm_analysis rm on am.Nutr_No = rm.Nutr_No join am_analysis_header;


drop table if exists z_trig_ctl;
CREATE TABLE z_trig_ctl(am_analysis_header integer default 0, rm_analysis_header integer default 0, am_analysis_minus_currentmeal integer default 0, am_analysis_null integer default 0, am_analysis integer default 0, rm_analysis integer default 0, rm_analysis_null integer default 0, am_dv integer default 0, PCF_processing integer default 0, block_setting_preferred_weight integer default 0, block_mealfoods_insert_trigger default 0, block_mealfoods_delete_trigger integer default 0);
insert into z_trig_ctl default values;

drop trigger if exists am_analysis_header_trigger;
CREATE TRIGGER am_analysis_header_trigger after update of am_analysis_header on z_trig_ctl when NEW.am_analysis_header = 1 begin
update z_trig_ctl set am_analysis_header = 0;
delete from am_analysis_header;
insert into am_analysis_header select (select count(distinct meal_id) from mealfoods) as maxmeal, count(meal_id) as mealcount, meals_per_day, ifnull(min(meal_id),0) as firstmeal, ifnull(max(meal_id),0) as lastmeal, currentmeal, NULL as caloriebutton, NULL as macropct, NULL as n6balance from options left join (select distinct meal_id from mealfoods order by meal_id desc limit (select defanal_am from options));
end;

drop trigger if exists rm_analysis_header_trigger;
CREATE TRIGGER rm_analysis_header_trigger after update of rm_analysis_header on z_trig_ctl when NEW.rm_analysis_header = 1 begin
update z_trig_ctl set rm_analysis_header = 0;
delete from rm_analysis_header;
insert into rm_analysis_header select maxmeal, case when (select count(*) from mealfoods where meal_id = currentmeal) = 0 then 0 else 1 end as mealcount, meals_per_day, currentmeal as firstmeal, currentmeal as lastmeal, currentmeal as currentmeal, NULL as caloriebutton, '0 / 0 / 0' as macropct, '0 / 0' as n6balance from am_analysis_header;
end;

drop trigger if exists am_analysis_minus_currentmeal_trigger;
CREATE TRIGGER am_analysis_minus_currentmeal_trigger after update of am_analysis_minus_currentmeal on z_trig_ctl when NEW.am_analysis_minus_currentmeal = 1 begin
update z_trig_ctl set am_analysis_minus_currentmeal = 0;
delete from z_anal;
insert into z_anal select Nutr_No, case when sum(mhectograms * Nutr_Val) is null then 1 else 0 end, ifnull(sum(mhectograms * Nutr_Val), 0.0) from (select NDB_No, total(Gm_Wgt / 100.0 / mealcount * meals_per_day) as mhectograms from mealfoods join am_analysis_header where meal_id between firstmeal and lastmeal and meal_id != currentmeal group by NDB_No) join nutr_def natural left join nut_data group by Nutr_No;
end;


drop trigger if exists am_analysis_null_trigger;
CREATE TRIGGER am_analysis_null_trigger after update of am_analysis_null on z_trig_ctl when NEW.am_analysis_null = 1 begin
update z_trig_ctl set am_analysis_null = 0;
delete from z_anal;
insert into z_anal select nutr_no, 1, 0.0 from nutr_def join am_analysis_header where firstmeal = currentmeal and lastmeal = currentmeal;
insert into z_anal select nutr_no, 0, 0.0 from nutr_def join am_analysis_header where firstmeal != currentmeal or lastmeal != currentmeal;
update am_analysis_header set macropct = '0 / 0 / 0', n6balance = '0 / 0';
end;

drop trigger if exists rm_analysis_null_trigger;
CREATE TRIGGER rm_analysis_null_trigger after update of rm_analysis_null on z_trig_ctl when NEW.rm_analysis_null = 1 begin
update z_trig_ctl set rm_analysis_null = 0;
delete from rm_analysis;
insert into rm_analysis select Nutr_No, 0, 0.0 from nutr_def;
update rm_analysis_header set caloriebutton = (select caloriebutton from am_analysis_header), macropct = '0 / 0 / 0', n6balance = '0 / 0';
end;


drop trigger if exists am_analysis_trigger;
CREATE TRIGGER am_analysis_trigger after update of am_analysis on z_trig_ctl when NEW.am_analysis = 1 begin
update z_trig_ctl set am_analysis = 0;
update am_analysis_header set macropct = (select cast (ifnull(round(100 * PROT_KCAL.Nutr_Val / ENERC_KCAL.Nutr_Val,0),0) as int) || ' / ' || cast (ifnull(round(100 * CHO_KCAL.Nutr_Val / ENERC_KCAL.Nutr_Val,0),0) as int) || ' / ' || cast (ifnull(round(100 * FAT_KCAL.Nutr_Val / ENERC_KCAL.Nutr_Val,0),0) as int) from am_analysis ENERC_KCAL join am_analysis PROT_KCAL on ENERC_KCAL.Nutr_No = 208 and PROT_KCAL.Nutr_No = 3000 join am_analysis CHO_KCAL on CHO_KCAL.Nutr_No = 3002 join am_analysis FAT_KCAL on FAT_KCAL.Nutr_No = 3001);
delete from z_n6;
insert into z_n6 select NULL, NULL, NULL, 1, 1, 900.0 * case when SHORT3.Nutr_Val > 0.0 then SHORT3.Nutr_Val else 0.000000001 end / case when ENERC_KCAL.Nutr_Val > 0.0 then ENERC_KCAL.Nutr_Val else 0.000000001 end, 900.0 * case when SHORT6.Nutr_Val > 0.0 then SHORT6.Nutr_Val else 0.000000001 end / case when ENERC_KCAL.Nutr_Val > 0.0 then ENERC_KCAL.Nutr_Val else 0.000000001 end, 900.0 * case when LONG3.Nutr_Val > 0.0 then LONG3.Nutr_Val else 0.000000001 end / case when ENERC_KCAL.Nutr_Val > 0.0 then ENERC_KCAL.Nutr_Val else 0.000000001 end, 900.0 * case when LONG6.Nutr_Val > 0.0 then LONG6.Nutr_Val else 0.000000001 end / case when ENERC_KCAL.Nutr_Val > 0.0 then ENERC_KCAL.Nutr_Val else 0.000000001 end, 900.0 * (FASAT.Nutr_Val + FAMS.Nutr_Val + FAPU.Nutr_Val - max(SHORT3.Nutr_Val,0.000000001) - max(SHORT6.Nutr_Val,0.000000001) - max(LONG3.Nutr_Val,0.000000001) - max(LONG6.Nutr_Val,0.000000001)) / case when ENERC_KCAL.Nutr_Val > 0.0 then ENERC_KCAL.Nutr_Val else 0.000000001 end from am_analysis SHORT3 join am_analysis SHORT6 on SHORT3.Nutr_No = 3005 and SHORT6.Nutr_No = 3003 join am_analysis LONG3 on LONG3.Nutr_No = 3006 join am_analysis LONG6 on LONG6.Nutr_No = 3004 join am_analysis FAPUval on FAPUval.Nutr_No = 646 join am_analysis FASAT on FASAT.Nutr_No = 606 join am_analysis FAMS on FAMS.Nutr_No = 645 join am_analysis FAPU on FAPU.Nutr_No = 646 join am_analysis ENERC_KCAL on ENERC_KCAL.Nutr_No = 208;
update am_analysis_header set n6balance = (select case when n6hufa_int = 0 or n6hufa_int is null then 0 when n6hufa_int between 1 and 14 then 15 when n6hufa_int > 90 then 90 else n6hufa_int end || ' / ' || (100 - case when n6hufa_int = 0 then 100 when n6hufa_int between 1 and 14 then 15 when n6hufa_int > 90 then 90 else n6hufa_int end) from (select cast (round(n6hufa,0) as int) as n6hufa_int from z_n6));
update am_analysis_header set n6balance = case when n6balance is null then '0 / 0' else n6balance end;
end;

drop trigger if exists rm_analysis_trigger;
CREATE TRIGGER rm_analysis_trigger after update of rm_analysis on z_trig_ctl when NEW.rm_analysis = 1 begin
update z_trig_ctl set rm_analysis = 0;
delete from rm_analysis;
insert into rm_analysis select Nutr_No, case when sum(mhectograms * Nutr_Val) is null then 1 else 0 end, ifnull(sum(mhectograms * Nutr_Val), 0.0) from (select NDB_No, total(Gm_Wgt / 100.0 * meals_per_day) as mhectograms from mealfoods join am_analysis_header where meal_id = currentmeal group by NDB_No) join nutr_def natural left join nut_data group by Nutr_No;
update rm_analysis_header set caloriebutton = (select caloriebutton from am_analysis_header), macropct = (select cast (ifnull(round(100 * PROT_KCAL.Nutr_Val / ENERC_KCAL.Nutr_Val,0),0) as int) || ' / ' || cast (ifnull(round(100 * CHO_KCAL.Nutr_Val / ENERC_KCAL.Nutr_Val,0),0) as int) || ' / ' || cast (ifnull(round(100 * FAT_KCAL.Nutr_Val / ENERC_KCAL.Nutr_Val,0),0) as int) from rm_analysis ENERC_KCAL join rm_analysis PROT_KCAL on ENERC_KCAL.Nutr_No = 208 and PROT_KCAL.Nutr_No = 3000 join rm_analysis CHO_KCAL on CHO_KCAL.Nutr_No = 3002 join rm_analysis FAT_KCAL on FAT_KCAL.Nutr_No = 3001);
delete from z_n6;
insert into z_n6 select NULL, NULL, NULL, 1, 1, 900.0 * case when SHORT3.Nutr_Val > 0.0 then SHORT3.Nutr_Val else 0.000000001 end / case when ENERC_KCAL.Nutr_Val > 0.0 then ENERC_KCAL.Nutr_Val else 0.000000001 end, 900.0 * case when SHORT6.Nutr_Val > 0.0 then SHORT6.Nutr_Val else 0.000000001 end / case when ENERC_KCAL.Nutr_Val > 0.0 then ENERC_KCAL.Nutr_Val else 0.000000001 end, 900.0 * case when LONG3.Nutr_Val > 0.0 then LONG3.Nutr_Val else 0.000000001 end / case when ENERC_KCAL.Nutr_Val > 0.0 then ENERC_KCAL.Nutr_Val else 0.000000001 end, 900.0 * case when LONG6.Nutr_Val > 0.0 then LONG6.Nutr_Val else 0.000000001 end / case when ENERC_KCAL.Nutr_Val > 0.0 then ENERC_KCAL.Nutr_Val else 0.000000001 end, 900.0 * (FASAT.Nutr_Val + FAMS.Nutr_Val + FAPU.Nutr_Val - max(SHORT3.Nutr_Val,0.000000001) - max(SHORT6.Nutr_Val,0.000000001) - max(LONG3.Nutr_Val,0.000000001) - max(LONG6.Nutr_Val,0.000000001)) / case when ENERC_KCAL.Nutr_Val > 0.0 then ENERC_KCAL.Nutr_Val else 0.000000001 end from rm_analysis SHORT3 join rm_analysis SHORT6 on SHORT3.Nutr_No = 3005 and SHORT6.Nutr_No = 3003 join rm_analysis LONG3 on LONG3.Nutr_No = 3006 join rm_analysis LONG6 on LONG6.Nutr_No = 3004 join rm_analysis FAPUval on FAPUval.Nutr_No = 646 join rm_analysis FASAT on FASAT.Nutr_No = 606 join rm_analysis FAMS on FAMS.Nutr_No = 645 join rm_analysis FAPU on FAPU.Nutr_No = 646 join rm_analysis ENERC_KCAL on ENERC_KCAL.Nutr_No = 208;
update rm_analysis_header set n6balance = (select case when n6hufa_int = 0 or n6hufa_int is null then 0 when n6hufa_int between 1 and 14 then 15 when n6hufa_int > 90 then 90 else n6hufa_int end || ' / ' || (100 - case when n6hufa_int = 0 then 100 when n6hufa_int between 1 and 14 then 15 when n6hufa_int > 90 then 90 else n6hufa_int end) from (select cast (round(n6hufa,0) as int) as n6hufa_int from z_n6));
end;

drop trigger if exists am_dv_trigger;
CREATE TRIGGER am_dv_trigger after update of am_dv on z_trig_ctl when NEW.am_dv = 1 begin
update z_trig_ctl set am_dv = 0;
delete from am_dv;
insert into am_dv select Nutr_No, dv, 100.0 * Nutr_Val / dv - 100.0 from (select Nutr_No, Nutr_Val, case when nutopt = 0.0 then dv_default when nutopt = -1.0 and Nutr_Val > 0.0 then Nutr_Val when nutopt = -1.0 and Nutr_Val <= 0.0 then dv_default else nutopt end as dv from nutr_def natural join am_analysis where dv_default > 0.0 and (Nutr_No = 208 or Nutr_No between 301 and 601 or Nutr_No = 2008));
insert into am_dv select Nutr_No, dv, 100.0 * Nutr_Val / dv - 100.0 from (select Nutr_No, Nutr_Val, case when nutopt = 0.0 and (select dv from am_dv where Nutr_No = 208) > 0.0 then (select dv from am_dv where Nutr_No = 208) / 2000.0 * dv_default when nutopt = 0.0 then dv_default when nutopt = -1.0 and Nutr_Val > 0.0 then Nutr_Val when nutopt = -1.0 and Nutr_Val <= 0.0 then (select dv from am_dv where Nutr_No = 208) / 2000.0 * dv_default else nutopt end as dv from nutr_def natural join am_analysis where Nutr_No = 291);
delete from z_vars1;
insert into z_vars1 select ifnull(PROT_KCAL.Nutr_Val / PROCNT.Nutr_Val, 4.0), ifnull(FAT_KCAL.Nutr_Val / FAT.Nutr_Val, 9.0), ifnull(CHO_KCAL.Nutr_Val / CHOCDF.Nutr_Val, 4.0), ifnull(ALC.Nutr_Val * 6.93, 0.0), ifnull((FASAT.Nutr_Val + FAMS.Nutr_Val + FAPU.Nutr_Val) / FAT.Nutr_Val, 0.94615385), case when ENERC_KCALopt.nutopt = -1 then 208 when FATopt.nutopt <= 0.0 and CHO_NONFIBopt.nutopt = 0.0 then 2000 else 204 end from am_analysis PROT_KCAL join am_analysis PROCNT on PROT_KCAL.Nutr_No = 3000 and PROCNT.Nutr_No = 203 join am_analysis FAT_KCAL on FAT_KCAL.Nutr_No = 3001 join am_analysis FAT on FAT.Nutr_No = 204 join am_analysis CHO_KCAL on CHO_KCAL.Nutr_No = 3002 join am_analysis CHOCDF on CHOCDF.Nutr_No = 205 join am_analysis ALC on ALC.Nutr_No = 221 join am_analysis FASAT on FASAT.Nutr_No = 606 join am_analysis FAMS on FAMS.Nutr_No = 645 join am_analysis FAPU on FAPU.Nutr_No = 646 join nutr_def ENERC_KCALopt on ENERC_KCALopt.Nutr_No = 208 join nutr_def FATopt on FATopt.Nutr_No = 204 join nutr_def CHO_NONFIBopt on CHO_NONFIBopt.Nutr_No = 2000;
insert into am_dv select Nutr_No, dv, 100.0 * Nutr_Val / dv - 100.0 from (select PROCNTnd.Nutr_No, case when (PROCNTnd.nutopt = 0.0 and ENERC_KCAL.dv > 0.0) or (PROCNTnd.nutopt = -1.0 and PROCNT.Nutr_Val <= 0.0) then PROCNTnd.dv_default * ENERC_KCAL.dv / 2000.0 when PROCNTnd.nutopt > 0.0 then PROCNTnd.nutopt else PROCNT.Nutr_Val end as dv, PROCNT.Nutr_Val from nutr_def PROCNTnd natural join am_analysis PROCNT join z_vars1 join am_dv ENERC_KCAL on ENERC_KCAL.Nutr_No = 208 where PROCNTnd.Nutr_No = 203);
delete from z_vars2;
insert into z_vars2 select am_fat_dv_not_boc, am_cho_nonfib_dv_not_boc, am_cho_nonfib_dv_not_boc + FIBTGdv from (select case when FATnd.nutopt = -1 and FAT.Nutr_Val > 0.0 then FAT.Nutr_Val when FATnd.nutopt > 0.0 then FATnd.nutopt else FATnd.dv_default * ENERC_KCAL.dv / 2000.0 end as am_fat_dv_not_boc, case when CHO_NONFIBnd.nutopt = -1 and CHO_NONFIB.Nutr_Val > 0.0 then CHO_NONFIB.Nutr_Val when CHO_NONFIBnd.nutopt > 0.0 then CHO_NONFIBnd.nutopt else (CHOCDFnd.dv_default * ENERC_KCAL.dv / 2000.0) - FIBTG.dv end as am_cho_nonfib_dv_not_boc, FIBTG.dv as FIBTGdv from z_vars1 join am_analysis FAT on FAT.Nutr_No = 204 join am_dv ENERC_KCAL on ENERC_KCAL.Nutr_No = 208 join nutr_def FATnd on FATnd.Nutr_No = 204 join nutr_def CHOCDFnd on CHOCDFnd.Nutr_No = 205 join nutr_def CHO_NONFIBnd on CHO_NONFIBnd.Nutr_No = 2000 join am_analysis CHO_NONFIB on CHO_NONFIB.Nutr_No = 2000 join am_dv FIBTG on FIBTG.Nutr_No = 291);
delete from z_vars3;
insert into z_vars3 select am_fat_dv_boc, am_chocdf_dv_boc, am_chocdf_dv_boc - FIBTGdv from (select (ENERC_KCAL.dv - (PROCNT.dv * am_cals2gram_pro) - (am_chocdf_dv_not_boc * am_cals2gram_cho)) / am_cals2gram_fat as am_fat_dv_boc, (ENERC_KCAL.dv - (PROCNT.dv * am_cals2gram_pro) - (am_fat_dv_not_boc * am_cals2gram_fat)) / am_cals2gram_cho as am_chocdf_dv_boc, FIBTG.dv as FIBTGdv from z_vars1 join z_vars2 join am_dv ENERC_KCAL on ENERC_KCAL.Nutr_No = 208 join am_dv PROCNT on PROCNT.Nutr_No = 203 join am_dv FIBTG on FIBTG.Nutr_No = 291);
insert into am_dv select Nutr_No, case when balance_of_calories = 204 then am_fat_dv_boc else am_fat_dv_not_boc end, case when balance_of_calories = 204 then 100.0 * Nutr_Val / am_fat_dv_boc - 100.0 else 100.0 * Nutr_Val / am_fat_dv_not_boc - 100.0 end from z_vars1 join z_vars2 join z_vars3 join nutr_def on Nutr_No = 204 natural join am_analysis;
insert into am_dv select Nutr_No, case when balance_of_calories = 2000 then am_cho_nonfib_dv_boc else am_cho_nonfib_dv_not_boc end, case when balance_of_calories = 2000 then 100.0 * Nutr_Val / am_cho_nonfib_dv_boc - 100.0 else 100.0 * Nutr_Val / am_cho_nonfib_dv_not_boc - 100.0 end from z_vars1 join z_vars2 join z_vars3 join nutr_def on Nutr_No = 2000 natural join am_analysis;
insert into am_dv select Nutr_No, case when balance_of_calories = 2000 then am_chocdf_dv_boc else am_chocdf_dv_not_boc end, case when balance_of_calories = 2000 then 100.0 * Nutr_Val / am_chocdf_dv_boc - 100.0 else 100.0 * Nutr_Val / am_chocdf_dv_not_boc - 100.0 end from z_vars1 join z_vars2 join z_vars3 join nutr_def on Nutr_No = 205 natural join am_analysis;
insert into am_dv select FASATnd.Nutr_No, case when FASATnd.nutopt = -1.0 and FASAT.Nutr_Val > 0.0 then FASAT.Nutr_Val when FASATnd.nutopt > 0.0 then FASATnd.nutopt else ENERC_KCAL.dv / 2000.0 * FASATnd.dv_default end, case when FASATnd.nutopt = -1.0 and FASAT.Nutr_Val > 0.0 then 0.0 when FASATnd.nutopt > 0.0 then 100.0 * FASAT.Nutr_Val / FASATnd.nutopt - 100.0 else 100.0 * FASAT.Nutr_Val / (ENERC_KCAL.dv / 2000.0 * FASATnd.dv_default) - 100.0 end from z_vars1 join nutr_def FASATnd on FASATnd.Nutr_No = 606 join am_dv ENERC_KCAL on ENERC_KCAL.Nutr_No = 208 join am_analysis FASAT on FASAT.Nutr_No = 606;
insert into am_dv select FAPUnd.Nutr_No, case when FAPUnd.nutopt = -1.0 and FAPU.Nutr_Val > 0.0 then FAPU.Nutr_Val when FAPUnd.nutopt > 0.0 then FAPUnd.nutopt else ENERC_KCAL.dv * 0.04 / am_cals2gram_fat end, case when FAPUnd.nutopt = -1.0 and FAPU.Nutr_Val > 0.0 then 0.0 when FAPUnd.nutopt > 0.0 then 100.0 * FAPU.Nutr_Val / FAPUnd.nutopt - 100.0 else 100.0 * FAPU.Nutr_Val / (ENERC_KCAL.dv * 0.04 / am_cals2gram_fat) - 100.0 end from z_vars1 join nutr_def FAPUnd on FAPUnd.Nutr_No = 646 join am_dv ENERC_KCAL on ENERC_KCAL.Nutr_No = 208 join am_analysis FAPU on FAPU.Nutr_No = 646;
insert into am_dv select FAMSnd.Nutr_No, (FAT.dv * am_fa2fat) - FASAT.dv - FAPU.dv, 100.0 * FAMS.Nutr_Val / ((FAT.dv * am_fa2fat) - FASAT.dv - FAPU.dv) - 100.0 from z_vars1 join am_dv FAT on FAT.Nutr_No = 204 join am_dv FASAT on FASAT.Nutr_No = 606 join am_dv FAPU on FAPU.Nutr_No = 646 join nutr_def FAMSnd on FAMSnd.Nutr_No = 645 join am_analysis FAMS on FAMS.Nutr_No = 645;
delete from z_n6;
insert into z_n6 select NULL, case when FAPU1 = 0.0 then 50.0 when FAPU1 < 15.0 then 15.0 when FAPU1 > 90.0 then 90.0 else FAPU1 end, case when FAPUval.Nutr_Val / FAPU.dv >= 1.0 then FAPUval.Nutr_Val / FAPU.dv else 1.0 end, 1, 0, 900.0 * case when SHORT3.Nutr_Val > 0.0 then SHORT3.Nutr_Val else 0.000000001 end / ENERC_KCAL.dv, 900.0 * case when SHORT6.Nutr_Val > 0.0 then SHORT6.Nutr_Val else 0.000000001 end / ENERC_KCAL.dv / case when FAPUval.Nutr_Val / FAPU.dv >= 1.0 then FAPUval.Nutr_Val / FAPU.dv else 1.0 end, 900.0 * case when LONG3.Nutr_Val > 0.0 then LONG3.Nutr_Val else 0.000000001 end / ENERC_KCAL.dv, 900.0 * case when LONG6.Nutr_Val > 0.0 then LONG6.Nutr_Val else 0.000000001 end / ENERC_KCAL.dv / case when FAPUval.Nutr_Val / FAPU.dv >= 1.0 then FAPUval.Nutr_Val / FAPU.dv else 1.0 end, 900.0 * (FASAT.dv + FAMS.dv + FAPU.dv - max(SHORT3.Nutr_Val,0.000000001) - max(SHORT6.Nutr_Val,0.000000001) - max(LONG3.Nutr_Val,0.000000001) - max(LONG6.Nutr_Val,0.000000001)) / ENERC_KCAL.dv from am_analysis SHORT3 join am_analysis SHORT6 on SHORT3.Nutr_No = 3005 and SHORT6.Nutr_No = 3003 join am_analysis LONG3 on LONG3.Nutr_No = 3006 join am_analysis LONG6 on LONG6.Nutr_No = 3004 join am_analysis FAPUval on FAPUval.Nutr_No = 646 join am_dv FASAT on FASAT.Nutr_No = 606 join am_dv FAMS on FAMS.Nutr_No = 645 join am_dv FAPU on FAPU.Nutr_No = 646 join am_dv ENERC_KCAL on ENERC_KCAL.Nutr_No = 208 join options;
delete from z_vars4;
insert into z_vars4 select Nutr_No, case when Nutr_Val > 0.0 and reduce = 3 then Nutr_Val / pufa_reduction when Nutr_Val > 0.0 and reduce = 6 then Nutr_Val / pufa_reduction - Nutr_Val / pufa_reduction * 0.01 * (iter - 1) else dv_default end, Nutr_Val from nutr_def natural join am_analysis join z_n6 where Nutr_No in (2006, 2001, 2002);
insert into z_vars4 select Nutr_No, case when Nutr_Val > 0.0 and reduce = 6 then Nutr_Val when Nutr_Val > 0.0 and reduce = 3 then Nutr_Val - Nutr_Val * 0.01 * (iter - 2) else dv_default end, Nutr_Val from nutr_def natural join am_analysis join z_n6 where Nutr_No in (2007, 2003, 2004, 2005);
insert into am_dv select Nutr_No, dv, 100.0 * Nutr_Val / dv - 100.0 from z_vars4;
update am_analysis_header set caloriebutton = 'Calories (' || (select cast (round(dv) as int) from am_dv where Nutr_No = 208) || ')';
delete from rm_dv;
insert into rm_dv select Nutr_No, dv, 100.0 * Nutr_Val / dv - 100.0 from rm_analysis natural join am_dv;
insert or replace into mealfoods select meal_id, NDB_No, Gm_Wgt - dv * dvpct_offset / (select meals_per_day from options) / Nutr_Val, Nutr_No from rm_dv natural join nut_data natural join mealfoods where abs(dvpct_offset) > 0.001 order by abs(dvpct_offset) desc limit 1;
end;

drop view if exists z_pcf;
create view z_pcf as select meal_id,
NDB_No, Gm_Wgt + dv / meals_per_day * dvpct_offset / Nutr_Val * -1.0 as Gm_Wgt, Nutr_No
from mealfoods natural join rm_dv natural join nut_data join options
where abs(dvpct_offset) >= 0.05 order by abs(dvpct_offset);

drop trigger if exists PCF_processing;
CREATE TRIGGER PCF_processing after update of PCF_processing on z_trig_ctl when NEW.PCF_processing = 1 begin
update z_trig_ctl set PCF_processing = 0;
replace into mealfoods select * from z_pcf limit 1;
update z_trig_ctl set block_mealfoods_delete_trigger = 0;
end;

drop trigger if exists defanal_am_trigger;
CREATE TRIGGER defanal_am_trigger after update of defanal_am on options begin
update z_trig_ctl set am_analysis_header = 1;
update z_trig_ctl set am_analysis_minus_currentmeal = case when (select mealcount from am_analysis_header) > 1 then 1 when (select mealcount from am_analysis_header) = 1 and (select lastmeal from am_analysis_header) != (select currentmeal from am_analysis_header) then 1 else 0 end;
update z_trig_ctl set am_analysis_null = case when (select mealcount from am_analysis_header) > 1 then 0 when (select mealcount from am_analysis_header) = 1 and (select lastmeal from am_analysis_header) != (select currentmeal from am_analysis_header) then 0 else 1 end;
update z_trig_ctl set am_analysis = 1;
update z_trig_ctl set am_dv = 1;
update z_trig_ctl set PCF_processing = 1;
end;

drop trigger if exists currentmeal_trigger;
CREATE TRIGGER currentmeal_trigger after update of currentmeal on options begin
update mealfoods set Nutr_No = null where Nutr_No is not null;
update z_trig_ctl set am_analysis_header = 1;
update z_trig_ctl set am_analysis_minus_currentmeal = case when (select mealcount from am_analysis_header) > 1 then 1 when (select mealcount from am_analysis_header) = 1 and (select lastmeal from am_analysis_header) != (select currentmeal from am_analysis_header) then 1 else 0 end;
update z_trig_ctl set am_analysis_null = case when (select mealcount from am_analysis_header) > 1 then 0 when (select mealcount from am_analysis_header) = 1 and (select lastmeal from am_analysis_header) != (select currentmeal from am_analysis_header) then 0 else 1 end;
update z_trig_ctl set rm_analysis_header = 1;
update z_trig_ctl set rm_analysis = case when (select mealcount from rm_analysis_header) = 1 then 1 else 0 end;
update z_trig_ctl set rm_analysis_null = case when (select mealcount from rm_analysis_header) = 0 then 1 else 0 end;
update z_trig_ctl set am_analysis = 1;
update z_trig_ctl set am_dv = 1;
end;

drop trigger if exists z_n6_insert_trigger;
CREATE TRIGGER z_n6_insert_trigger after insert on z_n6 begin
update z_n6 set n6hufa = (select 100.0 / (1.0 + 0.0441 / p6 * (1.0 + p3 / 0.0555 + h3 / 0.005 + o / 5.0 + p6 / 0.175)) + 100.0 / (1.0 + 0.7 / h6 * (1.0 + h3 / 3.0))), reduce = 0, iter = 0;
end;

drop trigger if exists z_n6_reduce6_trigger;
CREATE TRIGGER z_n6_reduce6_trigger after update on z_n6 when NEW.n6hufa > OLD.FAPU1 and NEW.iter < 100 and NEW.reduce in (0, 6) begin
update z_n6 set iter = iter + 1, reduce = 6, n6hufa = (select 100.0 / (1.0 + 0.0441 / (p6 - iter * .01 * p6) * (1.0 + p3 / 0.0555 + h3 / 0.005 + o / 5.0 + p6 / 0.175)) + 100.0 / (1.0 + 0.7 / (h6 - iter * .01 * h6) * (1.0 + h3 / 3.0)));
end;

drop trigger if exists z_n6_reduce3_trigger;
CREATE TRIGGER z_n6_reduce3_trigger after update of n6hufa on z_n6 when NEW.n6hufa < OLD.FAPU1 and NEW.iter < 100 and NEW.reduce in (0, 3) begin
update z_n6 set iter = iter + 1, reduce = 3, n6hufa = (select 100.0 / (1.0 + 0.0441 / p6 * (1.0 + (p3 - iter * .01 * p3) / 0.0555 + (h3 - iter * .01 * h3) / 0.005 + o / 5.0 + p6 / 0.175)) + 100.0 / (1.0 + 0.7 / h6 * (1.0 + (h3 - iter * .01 * h3) / 3.0)));
end;

drop trigger if exists insert_mealfoods_trigger;

CREATE TRIGGER insert_mealfoods_trigger after insert on mealfoods when NEW.meal_id = (select currentmeal from options) and (select count(*) from mealfoods where meal_id = NEW.meal_id) = 1 begin
update z_trig_ctl set am_analysis_header = 1;
update z_trig_ctl set am_analysis_minus_currentmeal = case when (select mealcount from am_analysis_header) > 1 then 1 when (select mealcount from am_analysis_header) = 1 and (select lastmeal from am_analysis_header) != (select currentmeal from am_analysis_header) then 1 else 0 end;
update z_trig_ctl set am_analysis_null = case when (select mealcount from am_analysis_header) > 1 then 0 when (select mealcount from am_analysis_header) = 1 and (select lastmeal from am_analysis_header) != (select currentmeal from am_analysis_header) then 0 else 1 end;
update z_trig_ctl set rm_analysis_header = 1;
update z_trig_ctl set rm_analysis = case when (select mealcount from rm_analysis_header) = 1 then 1 else 0 end;
update z_trig_ctl set rm_analysis_null = case when (select mealcount from rm_analysis_header) = 0 then 1 else 0 end;
update z_trig_ctl set am_analysis = 1;
update z_trig_ctl set am_dv = 1;
end;

drop trigger if exists delete_mealfoods_trigger;
CREATE TRIGGER delete_mealfoods_trigger after delete on mealfoods when OLD.meal_id = (select currentmeal from options) and (select count(*) from mealfoods where meal_id = OLD.meal_id) = 0 begin
update mealfoods set Nutr_No = null where Nutr_No is not null;
update z_trig_ctl set am_analysis_header = 1;
update z_trig_ctl set am_analysis_minus_currentmeal = case when (select mealcount from am_analysis_header) > 1 then 1 when (select mealcount from am_analysis_header) = 1 and (select lastmeal from am_analysis_header) != (select currentmeal from am_analysis_header) then 1 else 0 end;
update z_trig_ctl set am_analysis_null = case when (select mealcount from am_analysis_header) > 1 then 0 when (select mealcount from am_analysis_header) = 1 and (select lastmeal from am_analysis_header) != (select currentmeal from am_analysis_header) then 0 else 1 end;
update z_trig_ctl set rm_analysis_header = 1;
update z_trig_ctl set rm_analysis = case when (select mealcount from rm_analysis_header) = 1 then 1 else 0 end;
update z_trig_ctl set rm_analysis_null = case when (select mealcount from rm_analysis_header) = 0 then 1 else 0 end;
update z_trig_ctl set am_analysis = 1;
update z_trig_ctl set am_dv = 1;
end;

drop trigger if exists update_mealfoods2weight_trigger;
CREATE TRIGGER update_mealfoods2weight_trigger AFTER UPDATE ON mealfoods when NEW.Gm_Wgt > 0.0 and (select block_setting_preferred_weight from z_trig_ctl) = 0 BEGIN
update weight set Gm_Wgt = NEW.Gm_Wgt where NDB_No = NEW.NDB_No and Seq = (select min(Seq) from weight where NDB_No = NEW.NDB_No) ;
end;

drop trigger if exists insert_mealfoods2weight_trigger;
CREATE TRIGGER insert_mealfoods2weight_trigger AFTER INSERT ON mealfoods when NEW.Gm_Wgt > 0.0 and (select block_setting_preferred_weight from z_trig_ctl) = 0 BEGIN
update weight set Gm_Wgt = NEW.Gm_Wgt where NDB_No = NEW.NDB_No and Seq = (select min(Seq) from weight where NDB_No = NEW.NDB_No) ;
end;


drop trigger if exists update_weight_Seq;
create trigger update_weight_Seq BEFORE update of Seq on weight when NEW.Seq = 0 BEGIN
update weight set Seq = origSeq, Gm_Wgt = origGm_Wgt where NDB_No = NEW.NDB_No;
end;

drop trigger if exists insert_weight_Seq;
create trigger insert_weight_Seq BEFORE insert on weight when NEW.Seq = 0 BEGIN
update weight set Seq = origSeq, Gm_Wgt = origGm_Wgt where NDB_No = NEW.NDB_No;
end;

drop view if exists z_wslope;
CREATE VIEW z_wslope as select ifnull(weightslope,0.0) as "weightslope", ifnull(round(sumy / n - weightslope * sumx / n,1),0.0) as "weightyintercept", n as "weightn" from (select (sumxy - (sumx * sumy / n)) / (sumxx - (sumx * sumx / n)) as weightslope, sumy, n, sumx from (select sum(x) as sumx, sum(y) as sumy, sum(x*y) as sumxy, sum(x*x) as sumxx, n from (select cast (cast (julianday(substr(wldate,1,4) || '-' || substr(wldate,5,2) || '-' || substr(wldate,7,2)) - julianday('now', 'localtime') as int) as real) as x, weight as y, cast ((select count(*) from z_wl where cleardate is null) as real) as n from z_wl where cleardate is null)));

/*
  Basically the same thing for the slope, y-intercept, and "n" of fat mass.
*/

drop view if exists z_fslope;
CREATE VIEW z_fslope as select ifnull(fatslope,0.0) as "fatslope", ifnull(round(sumy / n - fatslope * sumx / n,1),0.0) as "fatyintercept", n as "fatn" from (select (sumxy - (sumx * sumy / n)) / (sumxx - (sumx * sumx / n)) as fatslope, sumy, n, sumx from (select sum(x) as sumx, sum(y) as sumy, sum(x*y) as sumxy, sum(x*x) as sumxx, n from (select cast (cast (julianday(substr(wldate,1,4) || '-' || substr(wldate,5,2) || '-' || substr(wldate,7,2)) - julianday('now', 'localtime') as int) as real) as x, bodyfat * weight / 100.0 as y, cast ((select count(*) from z_wl where ifnull(bodyfat,0.0) > 0.0 and cleardate is null) as real) as n from z_wl where ifnull(bodyfat,0.0) > 0.0 and cleardate is null)));

drop view if exists z_span;
create view z_span as select abs(min(cast (julianday(substr(wldate,1,4) || '-' || substr(wldate,5,2) || '-' || substr(wldate,7,2)) - julianday('now', 'localtime') as int))) as span from z_wl where cleardate is null;

drop view if exists wlog;
create view wlog as select * from z_wl;

drop trigger if exists wlog_insert;
create trigger wlog_insert instead of insert on wlog begin
insert or replace into z_wl values (NEW.weight, NEW.bodyfat, (select strftime('%Y%m%d', 'now', 'localtime')), null);
end;

drop view if exists wlview;
CREATE VIEW wlview as select wldate, weight, bodyfat, round(weight - weight * bodyfat / 100, 1) as leanmass, round(weight * bodyfat / 100, 1) as fatmass, round(weight - 2 * weight * bodyfat / 100) as bodycomp, cleardate from z_wl;

drop view if exists wlsummary;
create view wlsummary as select case
when (select weightn from z_wslope) > 1 then
'Weight:  ' || (select round(weightyintercept,1) from z_wslope) || char(13) || char(10) ||
'Bodyfat:  ' || case when (select weightyintercept from z_wslope) > 0.0 then round(1000.0 * (select fatyintercept from z_fslope) / (select weightyintercept from z_wslope)) / 10.0 else 0.0 end || '%' || char(13) || char(10)
when (select weightn from z_wslope) = 1 then
'Weight:  ' || (select weight from z_wl where cleardate is null) || char(13) || char(10) ||
'Bodyfat:  ' || (select bodyfat from z_wl where cleardate is null) || '%'
else
'Weight:  0.0' || char(13) || char(10) ||
'Bodyfat:  0.0%'
end || char(13) || char(10) ||
'Today' || "'" || 's Calorie level = ' || (select cast(round(nutopt) as int) from nutr_def where Nutr_No = 208)
|| char(13) || char(10)
|| char(13) || char(10) ||
case when (select weightn from z_wslope) = 0 then '0 data points so far...'
when (select weightn from z_wslope) = 1 then '1 data point so far...'
else
'Based on the trend of ' || (select cast(cast(weightn as int) as text) from z_wslope) || ' data points so far...' || char(13) || char(10) || char(10) ||
'Predicted lean mass today = ' ||
(select cast(round(10.0 * (weightyintercept - fatyintercept)) / 10.0 as text) from z_wslope, z_fslope) || char(13) || char(10) ||
'Predicted fat mass today  =  ' ||
(select cast(round(fatyintercept, 1) as text) from z_fslope) || char(13) || char(10) || char(10) ||
'If the predictions are correct, you ' ||
case when (select weightslope - fatslope from z_wslope, z_fslope) >= 0.0 then 'gained ' else 'lost ' end ||
(select cast(abs(round((weightslope - fatslope) * span * 1000.0) / 1000.0) as text) from z_wslope, z_fslope, z_span) ||
' lean mass over ' ||
(select span from z_span) ||
case when (select span from z_span) = 1 then ' day' else ' days' end || char(13) || char(10) ||
case when (select fatslope from z_fslope) > 0.0 then 'and gained ' else 'and lost ' end ||
(select cast(abs(round(fatslope * span * 1000.0) / 1000.0) as text) from z_fslope, z_span) || ' fat mass.'

end
as verbiage;

drop trigger if exists clear_wlsummary;
create trigger clear_wlsummary instead of insert on wlsummary
when (select autocal from options) = 0
begin
update z_wl set cleardate = (select strftime('%Y%m%d', 'now', 'localtime'))
where cleardate is null;
insert into z_wl select weight, bodyfat, wldate, null from z_wl
where wldate = (select max(wldate) from z_wl);
end;

drop trigger if exists autocal_initialization;
create trigger autocal_initialization after update of autocal on options
when NEW.autocal in (1, 2, 3) and OLD.autocal not in (1, 2, 3)
begin
update options set wltweak = 0, wlpolarity = 0;
end;

drop trigger if exists mpd_archive;
create trigger mpd_archive after update of meals_per_day on options
when NEW.meals_per_day != OLD.meals_per_day
begin
insert or ignore into archive_mealfoods select meal_id, NDB_No, Gm_Wgt, OLD.meals_per_day from mealfoods;
delete from mealfoods;
insert or ignore into mealfoods select meal_id, NDB_No, Gm_Wgt, null from archive_mealfoods where meals_per_day = NEW.meals_per_day;
delete from archive_mealfoods where meals_per_day = NEW.meals_per_day;
update options set defanal_am = (select count(distinct meal_id) from mealfoods);
end;

update nutr_def set nutopt = 0.0 where nutopt is null;
update options set currentmeal = case when currentmeal is null then 0 else currentmeal end;
update options set defanal_am = case when defanal_am is null then 0 else defanal_am end;

--commit;
analyze main;
"""
