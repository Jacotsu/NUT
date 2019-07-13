# .read load
# .read logic !! ONly IF new database, it can wipe everything
# .read user
# .headers ON user for debugging

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

get_rm_analysis_header = 'SELECT * FROM rm_analysis_header;'

# need to add default values for non present nutrients
get_rm_analysis = '''
SELECT rm_analysis.Nutr_No, Nutr_val, Units, NutrDesc,
    dvpct_OFfSET + 100
FROM rm_analysis
LEFT JOIN rm_dv ON rm_analysis.Nutr_No = rm_dv.Nutr_No
NATURAL JOIN nutr_def NATURAL JOIN rm_analysis;
'''

get_am_analysis = '''
SELECT am_analysis.Nutr_No, Nutr_val, Units, NutrDesc,
    dvpct_OFfSET + 100
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
SELECT mf.NDB_No AS NDB_No, LONg_Desc, mf.Gm_Wgt, Nutr_No
FROM mealfoods mf
NATURAL JOIN food_des
LEFT JOIN pref_Gm_Wgt pGW USING (NDB_No)
LEFT JOIN nutr_def USING (Nutr_No)
WHERE meal_id = (SELECT currentmeal FROM options)
ORDER BY Shrt_Desc;
'''


get_current_meal_str = 'SELECT cm_string FROM cm_string;'
set_current_meal = 'UPDATE options SET currentmeal = ?;'
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

get_macro_pct = 'SELECT macropct
FROM am_analysis_header;'

get_omega6_3_bal = 'SELECT n6balance
FROM am_analysis_header;'

get_food_groups = 'SELECT FdGrp_Cd, FdGrp_Desc FROM fd_group;'

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

remove_food_
FROM_meal = '''
DELETE FROM mealfoods
WHERE
    CASE WHEN :meal_id IS NOT NULL THEN
        meal_id = :meal_id
    ELSE
        meal_id = (SELECT currentmeal FROM options)
    END
    AND NDB_No = :NDB_No;
'''

get_food_lISt = 'SELECT NDB_No, LONg_Desc FROM food_des;'
get_food_
FROM_NDB_No = 'SELECT * FROM food_des WHERE NDB_No = :NDB_No;'
search_food = 'SELECT NDB_No, LONg_Desc
FROM food_des
WHERE LONg_Desc'\
        ' like :lONg_desc;'
get_food_sorted_by_nutrient = """
    SELECT LONg_Desc FROM fd_group NATURAL JOIN food_des NATURAL JOIN nut_data
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
SELECT NDB_No, FdGrp_Cd, LONg_Desc, 100, 'g', Nutr_val, Units
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
SELECT NDB_No, FdGrp_Cd, LONg_Desc, Gm_Wgt, 100, Nutr_val, Units
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

# Must implement period restrictiON
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

get_weight_log = 'SELECT *
FROM wlog;'
get_weight_summary = 'SELECT verbiage FROM wlsummary;'
get_last_weight = 'SELECT weight FROM wlog ORDER BY wldate DESC LIMIT 1;'
get_last_bodyfat = 'SELECT bodyfat FROM wlog ORDER BY wldate DESC LIMIT 1;'
INSERT_weight_log = 'INSERT INTO wlog values (?, ?, NULL, NULL);'
clear_weight_log = 'INSERT INTO wlsummary SELECT \'clear\';'

get_persONal_nutrient_dv = """
SELECT dv
FROM am_dv
WHERE Nutr_No = ?;
"""

user_init_query = """
PRAGMA recursive_TRIGGERs = 1;
PRAGMA threads = 4;

BEGIN;

DROP TRIGGER IF EXISTS before_mealfoods_INSERT_pcf;


CREATE TEMP TRIGGER before_mealfoods_INSERT_pcf
BEFORE
INSERT ON mealfoods WHEN
  (SELECT block_mealfoods_INSERT_TRIGGER
   FROM z_trig_ctl) = 0 BEGIN
UPDATE z_trig_ctl
SET block_mealfoods_DELETE_TRIGGER = 1; END;

DROP TRIGGER IF EXISTS mealfoods_INSERT_pcf;


CREATE TEMP TRIGGER mealfoods_INSERT_pcf AFTER
INSERT ON mealfoods WHEN NEW.meal_id =
  (SELECT currentmeal
   FROM options)
AND
  (SELECT block_mealfoods_INSERT_TRIGGER
   FROM z_trig_ctl) = 0 BEGIN
UPDATE z_trig_ctl
SET rm_analysis = 1;
UPDATE z_trig_ctl
SET am_analysis = 1;
UPDATE z_trig_ctl
SET am_dv = 1;
UPDATE z_trig_ctl
SET PCF_processing = 1; END;

DROP TRIGGER IF EXISTS mealfoods_UPDATE_pcf;


CREATE TEMP TRIGGER mealfoods_UPDATE_pcf AFTER
UPDATE ON mealfoods WHEN OLD.meal_id =
  (SELECT currentmeal
   FROM options) BEGIN
UPDATE z_trig_ctl
SET rm_analysis = 1;
UPDATE z_trig_ctl
SET am_analysis = 1;
UPDATE z_trig_ctl
SET am_dv = 1;
UPDATE z_trig_ctl
SET PCF_processing = 1; END;

DROP TRIGGER IF EXISTS mealfoods_DELETE_pcf;


CREATE TEMP TRIGGER mealfoods_DELETE_pcf AFTER
DELETE ON mealfoods WHEN OLD.meal_id =
  (SELECT currentmeal
   FROM options)
AND
  (SELECT block_mealfoods_DELETE_TRIGGER
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

DROP TRIGGER IF EXISTS UPDATE_nutopt_pcf;


CREATE TEMP TRIGGER UPDATE_nutopt_pcf AFTER
UPDATE OF nutopt ON nutr_def BEGIN
UPDATE z_trig_ctl
SET rm_analysis = 1;
UPDATE z_trig_ctl
SET am_analysis = 1;
UPDATE z_trig_ctl
SET am_dv = 1;
UPDATE z_trig_ctl
SET PCF_processing = 1; END;


DROP TRIGGER IF EXISTS UPDATE_FAPU1_pcf;


CREATE TEMP TRIGGER UPDATE_FAPU1_pcf AFTER
UPDATE OF FAPU1 ON options BEGIN
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
                   FROM options) THEN CAST (CAST (round(mf.Gm_Wgt) AS int) AS text) || ' g'
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
     FROM options)
ORDER BY Shrt_Desc;

DROP TRIGGER IF EXISTS currentmeal_INSERT;


CREATE TEMP TRIGGER currentmeal_INSERT INSTEAD OF
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
           FROM options), NEW.NDB_No,
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

DROP TRIGGER IF EXISTS currentmeal_DELETE;


CREATE TEMP TRIGGER currentmeal_DELETE INSTEAD OF
DELETE ON currentmeal BEGIN
DELETE
FROM mealfoods
WHERE meal_id =
    (SELECT currentmeal
     FROM options)
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
     FROM options);

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
     FROM options); END;

DROP VIEW IF EXISTS theusual;


CREATE TEMP VIEW theusual AS
SELECT meal_name,
       NDB_No,
       Gm_Wgt,
       NutrDesc
FROM z_tu
NATURAL JOIN pref_Gm_Wgt
LEFT JOIN nutr_def USING (Nutr_No);

DROP TRIGGER IF EXISTS theusual_INSERT;


CREATE TEMP TRIGGER theusual_INSERT INSTEAD OF
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

DROP TRIGGER IF EXISTS theusual_DELETE;


CREATE TEMP TRIGGER theusual_DELETE INSTEAD OF
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
                    FROM options)), 1) AS Nutr_Val,
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
                              FROM options))) AS int) AS text) || '%' AS val,
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
SELECT cast(round(sum(8.0 * gm_wgt / 28.35 / mealcount * meals_per_day)) / 8.0 AS text) || ' oz ' || LONg_desc
FROM mealfoods
NATURAL JOIN food_des
JOIN am_analysis_header
WHERE meal_id BETWEEN firstmeal AND lastmeal
GROUP BY ndb_no
ORDER BY lONg_desc;


DROP VIEW IF EXISTS nut_big_cONtrib;


CREATE TEMP VIEW nut_big_cONtrib AS
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


DROP VIEW IF EXISTS nutdv_big_cONtrib;


CREATE TEMP VIEW nutdv_big_cONtrib AS
SELECT nut_big_cONtrib.*
FROM nut_big_cONtrib
NATURAL JOIN nutr_def
WHERE dv_default > 0.0
ORDER BY shrt_desc;

DROP VIEW IF EXISTS nut_in_100g;


CREATE TEMP VIEW nut_in_100g AS
SELECT NutrDesc,
       FdGrp_Cd,
       f.NDB_No,
       LONg_Desc,
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
       LONg_Desc,
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
        options) BEGIN
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
        options) BEGIN
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


DROP TRIGGER IF EXISTS autocal_cycle_END;


CREATE TEMP TRIGGER autocal_cycle_END AFTER
INSERT ON z_wl WHEN
  (SELECT autocal = 2
   AND weightn > 1
   AND fatslope > 0.0
   AND (weightslope - fatslope) < 0.0
   FROM z_wslope,
        z_fslope,
        options) BEGIN
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


DROP VIEW IF EXISTS shopview;


CREATE TEMP VIEW shopview AS
SELECT 'Shopping LISt ' || group_cONcat(n || ': ' || item || ' (' || store || ')', ' ')
FROM
  (SELECT *
   FROM shopping
   ORDER BY store,
            item);


DROP VIEW IF EXISTS food_cost;


CREATE TEMP VIEW food_cost AS
SELECT ndb_no,
       round(sum(gm_wgt / gm_size * cost * meals_per_day / mealcount), 2) AS cost,
       lONg_desc
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
JOIN options
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
       cast(cast(round(100.0 + dvpct_OFfSET) AS int) AS text) || '%'
FROM rm_analysis
NATURAL JOIN rm_dv
NATURAL JOIN nutr_def
ORDER BY dvpct_OFfSET DESC;

DROP VIEW IF EXISTS analysis;


CREATE TEMP VIEW analysis AS
SELECT NutrDesc,
       round(Nutr_Val, 1) || ' ' || Units,
       cast(cast(round(100.0 + dvpct_OFfSET) AS int) AS text) || '%'
FROM am_analysis
NATURAL JOIN am_dv
NATURAL JOIN nutr_def
ORDER BY dvpct_OFfSET DESC;


DROP VIEW IF EXISTS cm_string;


CREATE TEMP VIEW cm_string AS WITH cdate (cdate, meal) AS
  (SELECT substr(currentmeal, 1, 4) || '-' || substr(currentmeal, 5, 2) || '-'
                || substr(currentmeal, 7, 2),
          cast(substr(currentmeal, 9, 2) AS int)
   FROM options)
SELECT CASE
           WHEN w = 0 THEN 'Sun'
           WHEN w = 1 THEN 'MON'
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

PRAGMA user_versiON = 38;
"""

db_load_pt1 = """
PRAGMA journal_mode = WAL;
BEGIN;

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
     lONg_desc   TEXT,
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
create_table_structure = """
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
     lONg_desc  TEXT,
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


CREATE TABLE IF NOT EXISTS mealfoods
  (
     meal_id INT,
     ndb_no  INT,
     gm_wgt  REAL,
     nutr_no INT,
     PRIMARY KEY(meal_id, ndb_no)
  );

CREATE TABLE IF NOT EXISTS shopping
  (
     n INTEGER PRIMARY KEY,
     item TEXT,
     store TEXT
  );

CREATE TABLE IF NOT EXISTS cost
  (
      ndb_no INT PRIMARY KEY,
      gm_size REAL,
      cost REAL
  );


CREATE TABLE IF NOT EXISTS eating_plan (plan_name text);

CREATE TABLE IF NOT EXISTS archive_mealfoods
   (
      meal_id INT,
      NDB_No INT,
      Gm_Wgt REAK,
      meals_per_day INTEGER,
      primary key
        (
          meal_id desc,
          NDB_No asc,
          meals_per_day
        )
  );

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
db_load_pt2 = """

INSERT INTO tnutr_def
SELECT * FROM nutr_def;

INSERT
OR     IGNORE
INTO   tnutr_def
SELECT trim(nutr_no, '~'),
       trim(units, '~'),
       trim(tagname, '~'),
       trim(nutrdesc, '~'),
       NULL,
       NULL
FROM   ttnutr_def;

UPDATE tnutr_def
SET Tagname = 'ADPROT'
WHERE Nutr_No = 257;

UPDATE tnutr_def
SET Tagname = 'VITD_BOTH'
WHERE Nutr_No = 328;

UPDATE tnutr_def
SET Tagname = 'LUT_ZEA'
WHERE Nutr_No = 338;

UPDATE tnutr_def
SET Tagname = 'VITE_ADDED'
WHERE Nutr_No = 573;

UPDATE tnutr_def
SET Tagname = 'VITB12_ADDED'
WHERE Nutr_No = 578;

UPDATE tnutr_def
SET Tagname = 'F22D1T'
WHERE Nutr_No = 664;

UPDATE tnutr_def
SET Tagname = 'F18D2T'
WHERE Nutr_No = 665;

UPDATE tnutr_def
SET Tagname = 'F18D2I'
WHERE Nutr_No = 666;

UPDATE tnutr_def
SET Tagname = 'F22D1C'
WHERE Nutr_No = 676;

UPDATE tnutr_def
SET Tagname = 'F18D3I'
WHERE Nutr_No = 856;

-- comment out the next line IF you want to hassle the nON-ascii micro char
UPDATE tnutr_def
SET Units = 'mcg'
WHERE hex(Units) = 'B567';

UPDATE tnutr_def
SET Units = 'kc'
WHERE Nutr_No = 208;

UPDATE tnutr_def
SET NutrDesc = 'Protein'
WHERE Nutr_No = 203;

UPDATE tnutr_def
SET NutrDesc = 'Total Fat'
WHERE Nutr_No = 204;

UPDATE tnutr_def
SET NutrDesc = 'Total Carb'
WHERE Nutr_No = 205;

UPDATE tnutr_def
SET NutrDesc = 'Ash'
WHERE Nutr_No = 207;

UPDATE tnutr_def
SET NutrDesc = 'Calories'
WHERE Nutr_No = 208;

UPDATE tnutr_def
SET NutrDesc = 'Starch'
WHERE Nutr_No = 209;

UPDATE tnutr_def
SET NutrDesc = 'Sucrose'
WHERE Nutr_No = 210;

UPDATE tnutr_def
SET NutrDesc = 'Glucose'
WHERE Nutr_No = 211;

UPDATE tnutr_def
SET NutrDesc = 'Fructose'
WHERE Nutr_No = 212;

UPDATE tnutr_def
SET NutrDesc = 'Lactose'
WHERE Nutr_No = 213;

UPDATE tnutr_def
SET NutrDesc = 'Maltose'
WHERE Nutr_No = 214;

UPDATE tnutr_def
SET NutrDesc = 'Ethyl Alcohol'
WHERE Nutr_No = 221;

UPDATE tnutr_def
SET NutrDesc = 'Water'
WHERE Nutr_No = 255;

UPDATE tnutr_def
SET NutrDesc = 'Adj. Protein'
WHERE Nutr_No = 257;

UPDATE tnutr_def
SET NutrDesc = 'Caffeine'
WHERE Nutr_No = 262;

UPDATE tnutr_def
SET NutrDesc = 'Theobromine'
WHERE Nutr_No = 263;

UPDATE tnutr_def
SET NutrDesc = 'Sugars'
WHERE Nutr_No = 269;

UPDATE tnutr_def
SET NutrDesc = 'Galactose'
WHERE Nutr_No = 287;

UPDATE tnutr_def
SET NutrDesc = 'Fiber'
WHERE Nutr_No = 291;

UPDATE tnutr_def
SET NutrDesc = 'Calcium'
WHERE Nutr_No = 301;

UPDATE tnutr_def
SET NutrDesc = 'IrON'
WHERE Nutr_No = 303;

UPDATE tnutr_def
SET NutrDesc = 'Magnesium'
WHERE Nutr_No = 304;

UPDATE tnutr_def
SET NutrDesc = 'Phosphorus'
WHERE Nutr_No = 305;

UPDATE tnutr_def
SET NutrDesc = 'Potassium'
WHERE Nutr_No = 306;

UPDATE tnutr_def
SET NutrDesc = 'Sodium'
WHERE Nutr_No = 307;

UPDATE tnutr_def
SET NutrDesc = 'Zinc'
WHERE Nutr_No = 309;

UPDATE tnutr_def
SET NutrDesc = 'Copper'
WHERE Nutr_No = 312;

UPDATE tnutr_def
SET NutrDesc = 'Fluoride'
WHERE Nutr_No = 313;

UPDATE tnutr_def
SET NutrDesc = 'Manganese'
WHERE Nutr_No = 315;

UPDATE tnutr_def
SET NutrDesc = 'Selenium'
WHERE Nutr_No = 317;

UPDATE tnutr_def
SET NutrDesc = 'Vit. A, IU'
WHERE Nutr_No = 318;

UPDATE tnutr_def
SET NutrDesc = 'Retinol'
WHERE Nutr_No = 319;

UPDATE tnutr_def
SET NutrDesc = 'Vitamin A'
WHERE Nutr_No = 320;

UPDATE tnutr_def
SET NutrDesc = 'B-Carotene'
WHERE Nutr_No = 321;

UPDATE tnutr_def
SET NutrDesc = 'A-Carotene'
WHERE Nutr_No = 322;

UPDATE tnutr_def
SET NutrDesc = 'A-Tocopherol'
WHERE Nutr_No = 323;

UPDATE tnutr_def
SET NutrDesc = 'Vit. D, IU'
WHERE Nutr_No = 324;

UPDATE tnutr_def
SET NutrDesc = 'Vitamin D2'
WHERE Nutr_No = 325;

UPDATE tnutr_def
SET NutrDesc = 'Vitamin D3'
WHERE Nutr_No = 326;

UPDATE tnutr_def
SET NutrDesc = 'Vitamin D'
WHERE Nutr_No = 328;

UPDATE tnutr_def
SET NutrDesc = 'B-Cryptoxanth.'
WHERE Nutr_No = 334;

UPDATE tnutr_def
SET NutrDesc = 'Lycopene'
WHERE Nutr_No = 337;

UPDATE tnutr_def
SET NutrDesc = 'Lutein+Zeaxan.'
WHERE Nutr_No = 338;

UPDATE tnutr_def
SET NutrDesc = 'B-Tocopherol'
WHERE Nutr_No = 341;

UPDATE tnutr_def
SET NutrDesc = 'G-Tocopherol'
WHERE Nutr_No = 342;

UPDATE tnutr_def
SET NutrDesc = 'D-Tocopherol'
WHERE Nutr_No = 343;

UPDATE tnutr_def
SET NutrDesc = 'A-Tocotrienol'
WHERE Nutr_No = 344;

UPDATE tnutr_def
SET NutrDesc = 'B-Tocotrienol'
WHERE Nutr_No = 345;

UPDATE tnutr_def
SET NutrDesc = 'G-Tocotrienol'
WHERE Nutr_No = 346;

UPDATE tnutr_def
SET NutrDesc = 'D-Tocotrienol'
WHERE Nutr_No = 347;

UPDATE tnutr_def
SET NutrDesc = 'Vitamin C'
WHERE Nutr_No = 401;

UPDATE tnutr_def
SET NutrDesc = 'Thiamin'
WHERE Nutr_No = 404;

UPDATE tnutr_def
SET NutrDesc = 'RibOFlavin'
WHERE Nutr_No = 405;

UPDATE tnutr_def
SET NutrDesc = 'Niacin'
WHERE Nutr_No = 406;

UPDATE tnutr_def
SET NutrDesc = 'Panto. Acid'
WHERE Nutr_No = 410;

UPDATE tnutr_def
SET NutrDesc = 'Vitamin B6'
WHERE Nutr_No = 415;

UPDATE tnutr_def
SET NutrDesc = 'Folate'
WHERE Nutr_No = 417;

UPDATE tnutr_def
SET NutrDesc = 'Vitamin B12'
WHERE Nutr_No = 418;

UPDATE tnutr_def
SET NutrDesc = 'Choline'
WHERE Nutr_No = 421;

UPDATE tnutr_def
SET NutrDesc = 'MenaquinONe-4'
WHERE Nutr_No = 428;

UPDATE tnutr_def
SET NutrDesc = 'Dihydro-K1'
WHERE Nutr_No = 429;

UPDATE tnutr_def
SET NutrDesc = 'Vitamin K1'
WHERE Nutr_No = 430;

UPDATE tnutr_def
SET NutrDesc = 'Folic Acid'
WHERE Nutr_No = 431;

UPDATE tnutr_def
SET NutrDesc = 'Folate, food'
WHERE Nutr_No = 432;

UPDATE tnutr_def
SET NutrDesc = 'Folate, DFE'
WHERE Nutr_No = 435;

UPDATE tnutr_def
SET NutrDesc = 'Betaine'
WHERE Nutr_No = 454;

UPDATE tnutr_def
SET NutrDesc = 'Tryptophan'
WHERE Nutr_No = 501;

UPDATE tnutr_def
SET NutrDesc = 'ThreONine'
WHERE Nutr_No = 502;

UPDATE tnutr_def
SET NutrDesc = 'Isoleucine'
WHERE Nutr_No = 503;

UPDATE tnutr_def
SET NutrDesc = 'Leucine'
WHERE Nutr_No = 504;

UPDATE tnutr_def
SET NutrDesc = 'Lysine'
WHERE Nutr_No = 505;

UPDATE tnutr_def
SET NutrDesc = 'MethiONine'
WHERE Nutr_No = 506;

UPDATE tnutr_def
SET NutrDesc = 'Cystine'
WHERE Nutr_No = 507;

UPDATE tnutr_def
SET NutrDesc = 'Phenylalanine'
WHERE Nutr_No = 508;

UPDATE tnutr_def
SET NutrDesc = 'Tyrosine'
WHERE Nutr_No = 509;

UPDATE tnutr_def
SET NutrDesc = 'Valine'
WHERE Nutr_No = 510;

UPDATE tnutr_def
SET NutrDesc = 'Arginine'
WHERE Nutr_No = 511;

UPDATE tnutr_def
SET NutrDesc = 'HIStidine'
WHERE Nutr_No = 512;

UPDATE tnutr_def
SET NutrDesc = 'Alanine'
WHERE Nutr_No = 513;

UPDATE tnutr_def
SET NutrDesc = 'Aspartic acid'
WHERE Nutr_No = 514;

UPDATE tnutr_def
SET NutrDesc = 'Glutamic acid'
WHERE Nutr_No = 515;

UPDATE tnutr_def
SET NutrDesc = 'Glycine'
WHERE Nutr_No = 516;

UPDATE tnutr_def
SET NutrDesc = 'Proline'
WHERE Nutr_No = 517;

UPDATE tnutr_def
SET NutrDesc = 'Serine'
WHERE Nutr_No = 518;

UPDATE tnutr_def
SET NutrDesc = 'Hydroxyproline'
WHERE Nutr_No = 521;

UPDATE tnutr_def
SET NutrDesc = 'Vit. E added'
WHERE Nutr_No = 573;

UPDATE tnutr_def
SET NutrDesc = 'Vit. B12 added'
WHERE Nutr_No = 578;

UPDATE tnutr_def
SET NutrDesc = 'Cholesterol'
WHERE Nutr_No = 601;

UPDATE tnutr_def
SET NutrDesc = 'Trans Fat'
WHERE Nutr_No = 605;

UPDATE tnutr_def
SET NutrDesc = 'Sat Fat'
WHERE Nutr_No = 606;

UPDATE tnutr_def
SET NutrDesc = '4:0'
WHERE Nutr_No = 607;

UPDATE tnutr_def
SET NutrDesc = '6:0'
WHERE Nutr_No = 608;

UPDATE tnutr_def
SET NutrDesc = '8:0'
WHERE Nutr_No = 609;

UPDATE tnutr_def
SET NutrDesc = '10:0'
WHERE Nutr_No = 610;

UPDATE tnutr_def
SET NutrDesc = '12:0'
WHERE Nutr_No = 611;

UPDATE tnutr_def
SET NutrDesc = '14:0'
WHERE Nutr_No = 612;

UPDATE tnutr_def
SET NutrDesc = '16:0'
WHERE Nutr_No = 613;

UPDATE tnutr_def
SET NutrDesc = '18:0'
WHERE Nutr_No = 614;

UPDATE tnutr_def
SET NutrDesc = '20:0'
WHERE Nutr_No = 615;

UPDATE tnutr_def
SET NutrDesc = '18:1'
WHERE Nutr_No = 617;

UPDATE tnutr_def
SET NutrDesc = '18:2'
WHERE Nutr_No = 618;

UPDATE tnutr_def
SET NutrDesc = '18:3'
WHERE Nutr_No = 619;

UPDATE tnutr_def
SET NutrDesc = '20:4'
WHERE Nutr_No = 620;

UPDATE tnutr_def
SET NutrDesc = '22:6n-3'
WHERE Nutr_No = 621;

UPDATE tnutr_def
SET NutrDesc = '22:0'
WHERE Nutr_No = 624;

UPDATE tnutr_def
SET NutrDesc = '14:1'
WHERE Nutr_No = 625;

UPDATE tnutr_def
SET NutrDesc = '16:1'
WHERE Nutr_No = 626;

UPDATE tnutr_def
SET NutrDesc = '18:4'
WHERE Nutr_No = 627;

UPDATE tnutr_def
SET NutrDesc = '20:1'
WHERE Nutr_No = 628;

UPDATE tnutr_def
SET NutrDesc = '20:5n-3'
WHERE Nutr_No = 629;

UPDATE tnutr_def
SET NutrDesc = '22:1'
WHERE Nutr_No = 630;

UPDATE tnutr_def
SET NutrDesc = '22:5n-3'
WHERE Nutr_No = 631;

UPDATE tnutr_def
SET NutrDesc = 'Phytosterols'
WHERE Nutr_No = 636;

UPDATE tnutr_def
SET NutrDesc = 'Stigmasterol'
WHERE Nutr_No = 638;

UPDATE tnutr_def
SET NutrDesc = 'Campesterol'
WHERE Nutr_No = 639;

UPDATE tnutr_def
SET NutrDesc = 'BetaSitosterol'
WHERE Nutr_No = 641;

UPDATE tnutr_def
SET NutrDesc = 'MONo Fat'
WHERE Nutr_No = 645;

UPDATE tnutr_def
SET NutrDesc = 'Poly Fat'
WHERE Nutr_No = 646;

UPDATE tnutr_def
SET NutrDesc = '15:0'
WHERE Nutr_No = 652;

UPDATE tnutr_def
SET NutrDesc = '17:0'
WHERE Nutr_No = 653;

UPDATE tnutr_def
SET NutrDesc = '24:0'
WHERE Nutr_No = 654;

UPDATE tnutr_def
SET NutrDesc = '16:1t'
WHERE Nutr_No = 662;

UPDATE tnutr_def
SET NutrDesc = '18:1t'
WHERE Nutr_No = 663;

UPDATE tnutr_def
SET NutrDesc = '22:1t'
WHERE Nutr_No = 664;

UPDATE tnutr_def
SET NutrDesc = '18:2t'
WHERE Nutr_No = 665;

UPDATE tnutr_def
SET NutrDesc = '18:2i'
WHERE Nutr_No = 666;

UPDATE tnutr_def
SET NutrDesc = '18:2t,t'
WHERE Nutr_No = 669;

UPDATE tnutr_def
SET NutrDesc = '18:2CLA'
WHERE Nutr_No = 670;

UPDATE tnutr_def
SET NutrDesc = '24:1c'
WHERE Nutr_No = 671;

UPDATE tnutr_def
SET NutrDesc = '20:2n-6c,c'
WHERE Nutr_No = 672;

UPDATE tnutr_def
SET NutrDesc = '16:1c'
WHERE Nutr_No = 673;

UPDATE tnutr_def
SET NutrDesc = '18:1c'
WHERE Nutr_No = 674;

UPDATE tnutr_def
SET NutrDesc = '18:2n-6c,c'
WHERE Nutr_No = 675;

UPDATE tnutr_def
SET NutrDesc = '22:1c'
WHERE Nutr_No = 676;

UPDATE tnutr_def
SET NutrDesc = '18:3n-6c,c,c'
WHERE Nutr_No = 685;

UPDATE tnutr_def
SET NutrDesc = '17:1'
WHERE Nutr_No = 687;

UPDATE tnutr_def
SET NutrDesc = '20:3'
WHERE Nutr_No = 689;

UPDATE tnutr_def
SET NutrDesc = 'TransMONoenoic'
WHERE Nutr_No = 693;

UPDATE tnutr_def
SET NutrDesc = 'TransPolyenoic'
WHERE Nutr_No = 695;

UPDATE tnutr_def
SET NutrDesc = '13:0'
WHERE Nutr_No = 696;

UPDATE tnutr_def
SET NutrDesc = '15:1'
WHERE Nutr_No = 697;

UPDATE tnutr_def
SET NutrDesc = '18:3n-3c,c,c'
WHERE Nutr_No = 851;

UPDATE tnutr_def
SET NutrDesc = '20:3n-3'
WHERE Nutr_No = 852;

UPDATE tnutr_def
SET NutrDesc = '20:3n-6'
WHERE Nutr_No = 853;

UPDATE tnutr_def
SET NutrDesc = '20:4n-6'
WHERE Nutr_No = 855;

UPDATE tnutr_def
SET NutrDesc = '18:3i'
WHERE Nutr_No = 856;

UPDATE tnutr_def
SET NutrDesc = '21:5'
WHERE Nutr_No = 857;

UPDATE tnutr_def
SET NutrDesc = '22:4'
WHERE Nutr_No = 858;

UPDATE tnutr_def
SET NutrDesc = '18:1n-7t'
WHERE Nutr_No = 859;

INSERT OR IGNORE INTO tnutr_def
VALUES(3000,'kc','PROT_KCAL','Protein Calories', NULL, NULL);

INSERT OR IGNORE INTO tnutr_def
VALUES(3001,'kc','FAT_KCAL','Fat Calories', NULL, NULL);

INSERT OR IGNORE INTO tnutr_def
VALUES(3002,'kc','CHO_KCAL','Carb Calories', NULL, NULL);

INSERT OR IGNORE INTO tnutr_def
VALUES(2000,'g','CHO_NONFIB','NON-Fiber Carb', NULL, NULL);

INSERT OR IGNORE INTO tnutr_def
VALUES(2001,'g','LA','LA', NULL, NULL);

INSERT OR IGNORE INTO tnutr_def
VALUES(2002,'g','AA','AA', NULL, NULL);

INSERT OR IGNORE INTO tnutr_def
VALUES(2003,'g','ALA','ALA', NULL, NULL);

INSERT OR IGNORE INTO tnutr_def
VALUES(2004,'g','EPA','EPA', NULL, NULL);

INSERT OR IGNORE INTO tnutr_def
VALUES(2005,'g','DHA','DHA', NULL, NULL);

INSERT OR IGNORE INTO tnutr_def
VALUES(2006,'g','OMEGA6','Omega-6', NULL, NULL);

INSERT OR IGNORE INTO tnutr_def
VALUES(3003,'g','SHORT6','Short-chain Omega-6', NULL, NULL);

INSERT OR IGNORE INTO tnutr_def
VALUES(3004,'g','LONG6','LONg-chain Omega-6', NULL, NULL);

INSERT OR IGNORE INTO tnutr_def
VALUES(2007,'g','OMEGA3','Omega-3', NULL, NULL);

INSERT OR IGNORE INTO tnutr_def
VALUES(3005,'g','SHORT3','Short-chain Omega-3', NULL, NULL);

INSERT OR IGNORE INTO tnutr_def
VALUES(3006,'g','LONG3','LONg-chain Omega-3', NULL, NULL);

-- These are the new "daily value" labeling standards minus "ADDED SUGARS" which
-- have not yet appeared in the USDA data.

INSERT OR IGNORE INTO tnutr_def
VALUES(2008,'mg','VITE','Vitamin E', NULL, NULL);

UPDATE tnutr_def SET dv_default = 2000.0
WHERE Tagname = 'ENERC_KCAL';

UPDATE tnutr_def SET dv_default = 50.0
WHERE Tagname = 'PROCNT';

UPDATE tnutr_def SET dv_default = 78.0
WHERE Tagname = 'FAT';

UPDATE tnutr_def SET dv_default = 275.0
WHERE Tagname = 'CHOCDF';

UPDATE tnutr_def SET dv_default = 28.0
WHERE Tagname = 'FIBTG';

UPDATE tnutr_def SET dv_default = 247.0
WHERE Tagname = 'CHO_NONFIB';

UPDATE tnutr_def SET dv_default = 1300.0
WHERE Tagname = 'CA';

UPDATE tnutr_def SET dv_default = 1250.0
WHERE Tagname = 'P';

UPDATE tnutr_def SET dv_default = 18.0
WHERE Tagname = 'FE';

UPDATE tnutr_def SET dv_default = 2300.0
WHERE Tagname = 'NA';

UPDATE tnutr_def SET dv_default = 4700.0
WHERE Tagname = 'K';

UPDATE tnutr_def SET dv_default = 420.0
WHERE Tagname = 'MG';

UPDATE tnutr_def SET dv_default = 11.0
WHERE Tagname = 'ZN';

UPDATE tnutr_def SET dv_default = 0.9
WHERE Tagname = 'CU';

UPDATE tnutr_def SET dv_default = 2.3
WHERE Tagname = 'MN';

UPDATE tnutr_def SET dv_default = 55.0
WHERE Tagname = 'SE';

UPDATE tnutr_def SET dv_default = NULL
WHERE Tagname = 'VITA_IU';

UPDATE tnutr_def SET dv_default = 900.0
WHERE Tagname = 'VITA_RAE';

UPDATE tnutr_def SET dv_default = 15.0
WHERE Tagname = 'VITE';

UPDATE tnutr_def SET dv_default = 120.0
WHERE Tagname = 'VITK1';

UPDATE tnutr_def SET dv_default = 1.2
WHERE Tagname = 'THIA';

UPDATE tnutr_def SET dv_default = 1.3
WHERE Tagname = 'RIBF';

UPDATE tnutr_def SET dv_default = 16.0
WHERE Tagname = 'NIA';

UPDATE tnutr_def SET dv_default = 5.0
WHERE Tagname = 'PANTAC';

UPDATE tnutr_def SET dv_default = 1.7
WHERE Tagname = 'VITB6A';

UPDATE tnutr_def SET dv_default = 400.0
WHERE Tagname = 'FOL';

UPDATE tnutr_def SET dv_default = 2.4
WHERE Tagname = 'VITB12';

UPDATE tnutr_def SET dv_default = 550.0
WHERE Tagname = 'CHOLN';

UPDATE tnutr_def SET dv_default = 90.0
WHERE Tagname = 'VITC';

UPDATE tnutr_def SET dv_default = 20.0
WHERE Tagname = 'FASAT';

UPDATE tnutr_def SET dv_default = 300.0
WHERE Tagname = 'CHOLE';

UPDATE tnutr_def SET dv_default = NULL
WHERE Tagname = 'VITD';

UPDATE tnutr_def SET dv_default = 20.0
WHERE Tagname = 'VITD_BOTH';

UPDATE tnutr_def SET dv_default = 8.9
WHERE Tagname = 'FAPU';

UPDATE tnutr_def SET dv_default = 0.2
WHERE Tagname = 'AA';

UPDATE tnutr_def SET dv_default = 3.8
WHERE Tagname = 'ALA';

UPDATE tnutr_def SET dv_default = 0.1
WHERE Tagname = 'EPA';

UPDATE tnutr_def SET dv_default = 0.1
WHERE Tagname = 'DHA';

UPDATE tnutr_def SET dv_default = 4.7
WHERE Tagname = 'LA';

UPDATE tnutr_def SET dv_default = 4.0
WHERE Tagname = 'OMEGA3';

UPDATE tnutr_def SET dv_default = 4.9
WHERE Tagname = 'OMEGA6';

UPDATE tnutr_def SET dv_default = 32.6
WHERE Tagname = 'FAMS';

UPDATE tnutr_def SET nutopt = 0.0
WHERE dv_default > 0.0 and nutopt IS NULL;

DELETE
FROM nutr_def;

INSERT INTO nutr_def SELECT *
FROM tnutr_def;

CREATE INDEX IF NOT EXISTS tagname_index ON nutr_def (Tagname asc);

DROP TABLE ttnutr_def;
DROP TABLE tnutr_def;

INSERT
OR     REPLACE
INTO   fd_group
SELECT trim(fdgrp_cd, '~'),
       trim(fdgrp_desc, '~')
FROM   tfd_group;INSERT
or     REPLACE
INTO   fd_group VALUES
       (
              9999,
              'Added Recipes'
       );

DROP TABLE tfd_group;

INSERT
or     REPLACE
INTO   food_des
       (
              ndb_no,
              fdgrp_cd,
              lONg_desc,
              shrt_desc,
              ref_desc,
              refuse,
              pro_factor,
              fat_factor,
              cho_factor
       )

SELECT trim(ndb_no, '~'),
       trim(fdgrp_cd, '~'),
       replace(trim(trim(lONg_desc, '~')
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
FROM   tfood_des;

UPDATE food_des
SET Shrt_Desc = LONg_Desc
WHERE length(LONg_Desc) <= 60;

DROP TABLE tfood_des;

UPDATE tweight SET NDB_No = trim(NDB_No,'~');
UPDATE tweight SET Seq = trim(Seq,'~');
UPDATE tweight SET Msre_Desc = trim(Msre_Desc,'~');

--We want every food to have a weight, so we make a '100 grams' default weight
INSERT OR REPLACE INTO zweight
SELECT NDB_No, 99, 100, 'grams', 100, 99, 100
FROM food_des;

--Now we UPDATE zweight with the user's existing weight preferences
INSERT OR REPLACE INTO zweight
SELECT *
FROM weight
WHERE Seq != origSeq OR Gm_Wgt != origGm_Wgt;

--We overwrite real weight TABLE with new USDA records
INSERT OR REPLACE INTO weight
SELECT NDB_No, Seq, Amount, Msre_Desc, Gm_Wgt, Seq, Gm_Wgt
FROM tweight;

--We overwrite the real weight TABLE with the original user mods
INSERT OR replace INTO weight SELECT *
FROM zweight;
DROP TABLE tweight;
DROP TABLE zweight;


INSERT OR replace INTO nut_data
SELECT trim(NDB_No, '~'), trim(Nutr_No, '~'), Nutr_Val
FROM tnut_data;
DROP TABLE tnut_data;

  --INSERT VITE records INTO nut_data
INSERT
or     REPLACE
INTO   nut_data
SELECT    f.ndb_no,
          2008,
          IFNULL(tocpha.nutr_val, 0.0)
FROM      food_des f
LEFT JOIN nut_data tocpha
ON        f.ndb_no = tocpha.ndb_no
AND       tocpha.nutr_no = 323
WHERE     tocpha.nutr_val IS NOT NULL;
  --INSERT LA records INTO nut_data
INSERT
or     REPLACE
INTO   nut_data
SELECT    f.ndb_no,
          2001,
          CASE
                    WHEN f18d2cn6.nutr_val IS NOT NULL THEN f18d2cn6.nutr_val
                    WHEN f18d2.nutr_val IS NOT NULL THEN f18d2.nutr_val - IFNULL(f18d2t.nutr_val, 0.0) - IFNULL(f18d2tt.nutr_val, 0.0) - IFNULL(f18d2i.nutr_val, 0.0) - IFNULL(f18d2cla.nutr_val, 0.0)
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


--INSERT ALA records INTO nut_data
INSERT
or     REPLACE
INTO   nut_data
SELECT    f.ndb_no,
          2003,
          CASE
                    WHEN f18d3cn3.nutr_val IS NOT NULL THEN f18d3cn3.nutr_val
                    WHEN f18d3.nutr_val IS NOT NULL THEN f18d3.nutr_val - IFNULL(f18d3cn6.nutr_val, 0.0) - IFNULL(f18d3i.nutr_val, 0.0)
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
INSERT
or     REPLACE
INTO   nut_data
SELECT    f.ndb_no,
          3005,
          IFNULL(ala.nutr_val, 0.0) + IFNULL(f18d4.nutr_val, 0.0)
FROM      food_des f
LEFT JOIN nut_data ala
ON        f.ndb_no = ala.ndb_no
AND       ala.nutr_no = 2003
LEFT JOIN nut_data f18d4
ON        f.ndb_no = f18d4.ndb_no
AND       f18d4.nutr_no = 627
WHERE     ala.nutr_val IS NOT NULL
OR        f18d4.nutr_val IS NOT NULL;

--INSERT AA records INTO nut_data
INSERT
or     REPLACE
INTO   nut_data
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

--INSERT LONG6 records INTO nut_data
INSERT
or     REPLACE
INTO   nut_data
SELECT    f.ndb_no,
          3004,
          CASE
                    WHEN f20d3n6.nutr_val IS NOT NULL THEN IFNULL(aa.nutr_val,0.0) + f20d3n6.nutr_val + IFNULL(f22d4.nutr_val,0.0)
                    ELSE IFNULL(aa.nutr_val,0.0)                                   + IFNULL(f20d3.nutr_val,0.0) + IFNULL(f22d4.nutr_val, 0.0)
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

--INSERT EPA records INTO nut_data
INSERT
or     REPLACE
INTO   nut_data
SELECT    f.ndb_no,
          2004,
          f20d5.nutr_val
FROM      food_des f
LEFT JOIN nut_data f20d5
ON        f.ndb_no = f20d5.ndb_no
AND       f20d5.nutr_no = 629
WHERE     f20d5.nutr_val IS NOT NULL;

--INSERT DHA records INTO nut_data
INSERT
or     REPLACE
INTO   nut_data
SELECT    f.ndb_no,
          2005,
          f22d6.nutr_val
FROM      food_des f
LEFT JOIN nut_data f22d6
ON        f.ndb_no = f22d6.ndb_no
AND       f22d6.nutr_no = 621
WHERE     f22d6.nutr_val IS NOT NULL;

--INSERT LONG3 records INTO nut_data
INSERT
or     REPLACE
INTO   nut_data
SELECT    f.ndb_no,
          3006,
          IFNULL(epa.nutr_val, 0.0) + IFNULL(dha.nutr_val, 0.0) + IFNULL(f20d3n3.nutr_val, 0.0) + IFNULL(f22d5.nutr_val, 0.0)
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

--INSERT OMEGA6 records INTO nut_data
INSERT
or     REPLACE
INTO   nut_data
SELECT    f.ndb_no,
          2006,
          IFNULL(short6.nutr_val, 0.0) + IFNULL(lONg6.nutr_val, 0.0)
FROM      food_des f
LEFT JOIN nut_data short6
ON        f.ndb_no = short6.ndb_no
AND       short6.nutr_no = 3003
LEFT JOIN nut_data lONg6
ON        f.ndb_no = lONg6.ndb_no
AND       lONg6.nutr_no = 3004
WHERE     short6.nutr_val IS NOT NULL
OR        lONg6.nutr_val IS NOT NULL;

--INSERT OMEGA3 records INTO nut_data
INSERT
or     REPLACE
INTO   nut_data
SELECT    f.ndb_no,
          2007,
          IFNULL(short3.nutr_val, 0.0) + IFNULL(lONg3.nutr_val, 0.0)
FROM      food_des f
LEFT JOIN nut_data short3
ON        f.ndb_no = short3.ndb_no
AND       short3.nutr_no = 3005
LEFT JOIN nut_data lONg3
ON        f.ndb_no = lONg3.ndb_no
AND       lONg3.nutr_no = 3006
WHERE     short3.nutr_val IS NOT NULL
OR        lONg3.nutr_val IS NOT NULL;

--INSERT CHO_NONFIB records INTO nut_data
INSERT
or     REPLACE
INTO   nut_data
SELECT    f.ndb_no,
          2000,
          CASE
                    WHEN chocdf.nutr_val - IFNULL(fibtg.nutr_val, 0.0) < 0.0 THEN 0.0
                    ELSE chocdf.nutr_val - IFNULL(fibtg.nutr_val, 0.0)
          END
FROM      food_des f
LEFT JOIN nut_data chocdf
ON        f.ndb_no = chocdf.ndb_no
AND       chocdf.nutr_no = 205
LEFT JOIN nut_data fibtg
ON        f.ndb_no = fibtg.ndb_no
AND       fibtg.nutr_no = 291
WHERE     chocdf.nutr_val IS NOT NULL;

--replace empty strings with values for macrONutrient factors in food_des
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

--INSERT calories
FROM macrONutrients INTO nut_data
INSERT
or     REPLACE
INTO   nut_data
SELECT f.ndb_no,
       3000,
       f.pro_factor * procnt.nutr_val
FROM   food_des f
JOIN   nut_data procnt
ON     f.ndb_no = procnt.ndb_no
AND    procnt.nutr_no = 203;INSERT
or     REPLACE
INTO   nut_data
SELECT f.ndb_no,
       3001,
       f.fat_factor * fat.nutr_val
FROM   food_des f
JOIN   nut_data fat
ON     f.ndb_no = fat.ndb_no
AND    fat.nutr_no = 204;INSERT
or     REPLACE
INTO   nut_data
SELECT f.ndb_no,
       3002,
       f.cho_factor * chocdf.nutr_val
FROM   food_des f
JOIN   nut_data chocdf
ON     f.ndb_no = chocdf.ndb_no
AND    chocdf.nutr_no = 205;



DROP TRIGGER IF EXISTS protect_options;
CREATE TRIGGER protect_options AFTER INSERT ON options BEGIN DELETE
FROM options
WHERE protect != 1; END;

INSERT INTO options default values;

DROP TRIGGER protect_options;

UPDATE options
SET currentmeal = CAST(STRFTIME('%Y%m%d01', DATE('now')) AS INTEGER);

--commit;
VACUUM;
"""

# ThIS query will wipe everything USE WITH CARE
init_logic = """
BEGIN;

DROP TABLE IF EXISTS z_vars1;
CREATE TABLE z_vars1 (am_cals2gram_pro real, am_cals2gram_fat real, am_cals2gram_cho real, am_alccals real, am_fa2fat real, balance_of_calories int);

DROP TABLE IF EXISTS z_vars2;
CREATE TABLE z_vars2 (am_fat_dv_not_boc real, am_cho_nONfib_dv_not_boc real, am_chocdf_dv_not_boc real);

DROP TABLE IF EXISTS z_vars3;
CREATE TABLE z_vars3 (am_fat_dv_boc real, am_chocdf_dv_boc real, am_cho_nONfib_dv_boc real);

DROP TABLE IF EXISTS z_vars4;
CREATE TABLE z_vars4 (Nutr_No int, dv real, Nutr_Val real);


DROP TABLE IF EXISTS z_n6;
CREATE TABLE z_n6 (n6hufa real, FAPU1 real, pufa_reductiON real, iter int, reduce int, p3 real, p6 real, h3 real, h6 real, o real);


DROP TABLE IF EXISTS z_anal;
CREATE TABLE z_anal (Nutr_No int primary key, NULL_value int, Nutr_Val real);


DROP TABLE IF EXISTS am_analysis_header;
CREATE TABLE am_analysis_header (maxmeal int, mealcount int, meals_per_day int, firstmeal integer, lastmeal integer, currentmeal integer, caloriebuttON text, macropct text, n6balance text);


DROP TABLE IF EXISTS am_dv;
CREATE TABLE am_dv (Nutr_No int primary key asc, dv real, dvpct_OFfSET real);

DROP TABLE IF EXISTS rm_analysis_header;
CREATE TABLE rm_analysis_header (maxmeal int, mealcount int, meals_per_day int, firstmeal integer, lastmeal integer, currentmeal integer, caloriebuttON text, macropct text, n6balance text);

DROP TABLE IF EXISTS rm_analysis;
CREATE TABLE rm_analysis (Nutr_No int primary key asc, NULL_value int, Nutr_Val real);

DROP TABLE IF EXISTS rm_dv;
CREATE TABLE rm_dv (Nutr_No int primary key asc, dv real, dvpct_OFfSET real);

DROP view IF EXISTS am_analysis;
CREATE view am_analysis as SELECT am.Nutr_No as Nutr_No, CASE WHEN currentmeal between firstmeal and lastmeal and am.NULL_value = 1 and rm.NULL_value = 1 THEN 1 WHEN currentmeal not between firstmeal and lastmeal and am.NULL_value = 1 THEN 1 ELSE 0 END as NULL_value, CASE WHEN currentmeal between firstmeal and lastmeal THEN IFNULL(am.Nutr_Val,0.0) + 1.0 / mealcount * IFNULL(rm.Nutr_Val, 0.0) ELSE am.Nutr_Val END as Nutr_Val
FROM z_anal am left join rm_analysis rm ON am.Nutr_No = rm.Nutr_No join am_analysis_header;


DROP TABLE IF EXISTS z_trig_ctl;
CREATE TABLE z_trig_ctl(am_analysis_header integer default 0, rm_analysis_header integer default 0, am_analysis_minus_currentmeal integer default 0, am_analysis_NULL integer default 0, am_analysis integer default 0, rm_analysis integer default 0, rm_analysis_NULL integer default 0, am_dv integer default 0, PCF_processing integer default 0, block_SETting_preferred_weight integer default 0, block_mealfoods_INSERT_TRIGGER default 0, block_mealfoods_DELETE_TRIGGER integer default 0);
INSERT INTO z_trig_ctl default values;


DELETE
FROM z_n6;
INSERT INTO z_n6 SELECT NULL, NULL, NULL, 1, 1, 900.0 * CASE WHEN SHORT3.Nutr_Val > 0.0 THEN SHORT3.Nutr_Val ELSE 0.000000001 END / CASE WHEN ENERC_KCAL.Nutr_Val > 0.0 THEN ENERC_KCAL.Nutr_Val ELSE 0.000000001 END, 900.0 * CASE WHEN SHORT6.Nutr_Val > 0.0 THEN SHORT6.Nutr_Val ELSE 0.000000001 END / CASE WHEN ENERC_KCAL.Nutr_Val > 0.0 THEN ENERC_KCAL.Nutr_Val ELSE 0.000000001 END, 900.0 * CASE WHEN LONG3.Nutr_Val > 0.0 THEN LONG3.Nutr_Val ELSE 0.000000001 END / CASE WHEN ENERC_KCAL.Nutr_Val > 0.0 THEN ENERC_KCAL.Nutr_Val ELSE 0.000000001 END, 900.0 * CASE WHEN LONG6.Nutr_Val > 0.0 THEN LONG6.Nutr_Val ELSE 0.000000001 END / CASE WHEN ENERC_KCAL.Nutr_Val > 0.0 THEN ENERC_KCAL.Nutr_Val ELSE 0.000000001 END, 900.0 * (FASAT.Nutr_Val + FAMS.Nutr_Val + FAPU.Nutr_Val - max(SHORT3.Nutr_Val,0.000000001) - max(SHORT6.Nutr_Val,0.000000001) - max(LONG3.Nutr_Val,0.000000001) - max(LONG6.Nutr_Val,0.000000001)) / CASE WHEN ENERC_KCAL.Nutr_Val > 0.0 THEN ENERC_KCAL.Nutr_Val ELSE 0.000000001 END
FROM am_analysis SHORT3 join am_analysis SHORT6 ON SHORT3.Nutr_No = 3005 and SHORT6.Nutr_No = 3003 join am_analysis LONG3 ON LONG3.Nutr_No = 3006 join am_analysis LONG6 ON LONG6.Nutr_No = 3004 join am_analysis FAPUval ON FAPUval.Nutr_No = 646 join am_analysis FASAT ON FASAT.Nutr_No = 606 join am_analysis FAMS ON FAMS.Nutr_No = 645 join am_analysis FAPU ON FAPU.Nutr_No = 646 join am_analysis ENERC_KCAL ON ENERC_KCAL.Nutr_No = 208;
UPDATE am_analysis_header SET n6balance = (SELECT CASE WHEN n6hufa_int = 0 OR n6hufa_int IS NULL THEN 0 WHEN n6hufa_int between 1 and 14 THEN 15 WHEN n6hufa_int > 90 THEN 90 ELSE n6hufa_int END || ' / ' || (100 - CASE WHEN n6hufa_int = 0 THEN 100 WHEN n6hufa_int between 1 and 14 THEN 15 WHEN n6hufa_int > 90 THEN 90 ELSE n6hufa_int END)
FROM (SELECT cast (round(n6hufa,0) as int) as n6hufa_int
FROM z_n6));
UPDATE am_analysis_header SET n6balance = CASE WHEN n6balance IS NULL THEN '0 / 0' ELSE n6balance END;
END;

DROP TRIGGER IF EXISTS rm_analysis_TRIGGER;
CREATE TRIGGER rm_analysis_TRIGGER AFTER UPDATE OF rm_analysis ON z_trig_ctl WHEN NEW.rm_analysis = 1 BEGIN
UPDATE z_trig_ctl SET rm_analysis = 0;
DELETE
FROM rm_analysis;
INSERT INTO rm_analysis SELECT Nutr_No, CASE WHEN sum(mhectograms * Nutr_Val) IS NULL THEN 1 ELSE 0 END, IFNULL(sum(mhectograms * Nutr_Val), 0.0)
FROM (SELECT NDB_No, total(Gm_Wgt / 100.0 * meals_per_day) as mhectograms
FROM mealfoods join am_analysis_header
WHERE meal_id = currentmeal group by NDB_No) join nutr_def natural left join nut_data group by Nutr_No;
UPDATE rm_analysis_header SET caloriebuttON = (SELECT caloriebuttON
FROM am_analysis_header), macropct = (SELECT cast (IFNULL(round(100 * PROT_KCAL.Nutr_Val / ENERC_KCAL.Nutr_Val,0),0) as int) || ' / ' || cast (IFNULL(round(100 * CHO_KCAL.Nutr_Val / ENERC_KCAL.Nutr_Val,0),0) as int) || ' / ' || cast (IFNULL(round(100 * FAT_KCAL.Nutr_Val / ENERC_KCAL.Nutr_Val,0),0) as int)
FROM rm_analysis ENERC_KCAL join rm_analysis PROT_KCAL ON ENERC_KCAL.Nutr_No = 208 and PROT_KCAL.Nutr_No = 3000 join rm_analysis CHO_KCAL ON CHO_KCAL.Nutr_No = 3002 join rm_analysis FAT_KCAL ON FAT_KCAL.Nutr_No = 3001);
DELETE
FROM z_n6;
INSERT INTO z_n6 SELECT NULL, NULL, NULL, 1, 1, 900.0 * CASE WHEN SHORT3.Nutr_Val > 0.0 THEN SHORT3.Nutr_Val ELSE 0.000000001 END / CASE WHEN ENERC_KCAL.Nutr_Val > 0.0 THEN ENERC_KCAL.Nutr_Val ELSE 0.000000001 END, 900.0 * CASE WHEN SHORT6.Nutr_Val > 0.0 THEN SHORT6.Nutr_Val ELSE 0.000000001 END / CASE WHEN ENERC_KCAL.Nutr_Val > 0.0 THEN ENERC_KCAL.Nutr_Val ELSE 0.000000001 END, 900.0 * CASE WHEN LONG3.Nutr_Val > 0.0 THEN LONG3.Nutr_Val ELSE 0.000000001 END / CASE WHEN ENERC_KCAL.Nutr_Val > 0.0 THEN ENERC_KCAL.Nutr_Val ELSE 0.000000001 END, 900.0 * CASE WHEN LONG6.Nutr_Val > 0.0 THEN LONG6.Nutr_Val ELSE 0.000000001 END / CASE WHEN ENERC_KCAL.Nutr_Val > 0.0 THEN ENERC_KCAL.Nutr_Val ELSE 0.000000001 END, 900.0 * (FASAT.Nutr_Val + FAMS.Nutr_Val + FAPU.Nutr_Val - max(SHORT3.Nutr_Val,0.000000001) - max(SHORT6.Nutr_Val,0.000000001) - max(LONG3.Nutr_Val,0.000000001) - max(LONG6.Nutr_Val,0.000000001)) / CASE WHEN ENERC_KCAL.Nutr_Val > 0.0 THEN ENERC_KCAL.Nutr_Val ELSE 0.000000001 END
FROM rm_analysis SHORT3 join rm_analysis SHORT6 ON SHORT3.Nutr_No = 3005 and SHORT6.Nutr_No = 3003 join rm_analysis LONG3 ON LONG3.Nutr_No = 3006 join rm_analysis LONG6 ON LONG6.Nutr_No = 3004 join rm_analysis FAPUval ON FAPUval.Nutr_No = 646 join rm_analysis FASAT ON FASAT.Nutr_No = 606 join rm_analysis FAMS ON FAMS.Nutr_No = 645 join rm_analysis FAPU ON FAPU.Nutr_No = 646 join rm_analysis ENERC_KCAL ON ENERC_KCAL.Nutr_No = 208;
UPDATE rm_analysis_header SET n6balance = (SELECT CASE WHEN n6hufa_int = 0 OR n6hufa_int IS NULL THEN 0 WHEN n6hufa_int between 1 and 14 THEN 15 WHEN n6hufa_int > 90 THEN 90 ELSE n6hufa_int END || ' / ' || (100 - CASE WHEN n6hufa_int = 0 THEN 100 WHEN n6hufa_int between 1 and 14 THEN 15 WHEN n6hufa_int > 90 THEN 90 ELSE n6hufa_int END)
FROM (SELECT cast (round(n6hufa,0) as int) as n6hufa_int
FROM z_n6));
END;

DROP TRIGGER IF EXISTS am_dv_TRIGGER;
CREATE TRIGGER am_dv_TRIGGER AFTER UPDATE OF am_dv ON z_trig_ctl WHEN NEW.am_dv = 1 BEGIN
UPDATE z_trig_ctl SET am_dv = 0;
DELETE
FROM am_dv;
INSERT INTO am_dv SELECT Nutr_No, dv, 100.0 * Nutr_Val / dv - 100.0
FROM (SELECT Nutr_No, Nutr_Val, CASE WHEN nutopt = 0.0 THEN dv_default WHEN nutopt = -1.0 and Nutr_Val > 0.0 THEN Nutr_Val WHEN nutopt = -1.0 and Nutr_Val <= 0.0 THEN dv_default ELSE nutopt END as dv
FROM nutr_def natural join am_analysis
WHERE dv_default > 0.0 and (Nutr_No = 208 OR Nutr_No between 301 and 601 OR Nutr_No = 2008));
INSERT INTO am_dv SELECT Nutr_No, dv, 100.0 * Nutr_Val / dv - 100.0
FROM (SELECT Nutr_No, Nutr_Val, CASE WHEN nutopt = 0.0 and (SELECT dv
FROM am_dv
WHERE Nutr_No = 208) > 0.0 THEN (SELECT dv
FROM am_dv
WHERE Nutr_No = 208) / 2000.0 * dv_default WHEN nutopt = 0.0 THEN dv_default WHEN nutopt = -1.0 and Nutr_Val > 0.0 THEN Nutr_Val WHEN nutopt = -1.0 and Nutr_Val <= 0.0 THEN (SELECT dv
FROM am_dv
WHERE Nutr_No = 208) / 2000.0 * dv_default ELSE nutopt END as dv
FROM nutr_def natural join am_analysis
WHERE Nutr_No = 291);
DELETE
FROM z_vars1;
INSERT INTO z_vars1 SELECT IFNULL(PROT_KCAL.Nutr_Val / PROCNT.Nutr_Val, 4.0), IFNULL(FAT_KCAL.Nutr_Val / FAT.Nutr_Val, 9.0), IFNULL(CHO_KCAL.Nutr_Val / CHOCDF.Nutr_Val, 4.0), IFNULL(ALC.Nutr_Val * 6.93, 0.0), IFNULL((FASAT.Nutr_Val + FAMS.Nutr_Val + FAPU.Nutr_Val) / FAT.Nutr_Val, 0.94615385), CASE WHEN ENERC_KCALopt.nutopt = -1 THEN 208 WHEN FATopt.nutopt <= 0.0 and CHO_NONFIBopt.nutopt = 0.0 THEN 2000 ELSE 204 END
FROM am_analysis PROT_KCAL join am_analysis PROCNT ON PROT_KCAL.Nutr_No = 3000 and PROCNT.Nutr_No = 203 join am_analysis FAT_KCAL ON FAT_KCAL.Nutr_No = 3001 join am_analysis FAT ON FAT.Nutr_No = 204 join am_analysis CHO_KCAL ON CHO_KCAL.Nutr_No = 3002 join am_analysis CHOCDF ON CHOCDF.Nutr_No = 205 join am_analysis ALC ON ALC.Nutr_No = 221 join am_analysis FASAT ON FASAT.Nutr_No = 606 join am_analysis FAMS ON FAMS.Nutr_No = 645 join am_analysis FAPU ON FAPU.Nutr_No = 646 join nutr_def ENERC_KCALopt ON ENERC_KCALopt.Nutr_No = 208 join nutr_def FATopt ON FATopt.Nutr_No = 204 join nutr_def CHO_NONFIBopt ON CHO_NONFIBopt.Nutr_No = 2000;
INSERT INTO am_dv SELECT Nutr_No, dv, 100.0 * Nutr_Val / dv - 100.0
FROM (SELECT PROCNTnd.Nutr_No, CASE WHEN (PROCNTnd.nutopt = 0.0 and ENERC_KCAL.dv > 0.0) OR (PROCNTnd.nutopt = -1.0 and PROCNT.Nutr_Val <= 0.0) THEN PROCNTnd.dv_default * ENERC_KCAL.dv / 2000.0 WHEN PROCNTnd.nutopt > 0.0 THEN PROCNTnd.nutopt ELSE PROCNT.Nutr_Val END as dv, PROCNT.Nutr_Val
FROM nutr_def PROCNTnd natural join am_analysis PROCNT join z_vars1 join am_dv ENERC_KCAL ON ENERC_KCAL.Nutr_No = 208
WHERE PROCNTnd.Nutr_No = 203);
DELETE
FROM z_vars2;
INSERT INTO z_vars2 SELECT am_fat_dv_not_boc, am_cho_nONfib_dv_not_boc, am_cho_nONfib_dv_not_boc + FIBTGdv
FROM (SELECT CASE WHEN FATnd.nutopt = -1 and FAT.Nutr_Val > 0.0 THEN FAT.Nutr_Val WHEN FATnd.nutopt > 0.0 THEN FATnd.nutopt ELSE FATnd.dv_default * ENERC_KCAL.dv / 2000.0 END as am_fat_dv_not_boc, CASE WHEN CHO_NONFIBnd.nutopt = -1 and CHO_NONFIB.Nutr_Val > 0.0 THEN CHO_NONFIB.Nutr_Val WHEN CHO_NONFIBnd.nutopt > 0.0 THEN CHO_NONFIBnd.nutopt ELSE (CHOCDFnd.dv_default * ENERC_KCAL.dv / 2000.0) - FIBTG.dv END as am_cho_nONfib_dv_not_boc, FIBTG.dv as FIBTGdv
FROM z_vars1 join am_analysis FAT ON FAT.Nutr_No = 204 join am_dv ENERC_KCAL ON ENERC_KCAL.Nutr_No = 208 join nutr_def FATnd ON FATnd.Nutr_No = 204 join nutr_def CHOCDFnd ON CHOCDFnd.Nutr_No = 205 join nutr_def CHO_NONFIBnd ON CHO_NONFIBnd.Nutr_No = 2000 join am_analysis CHO_NONFIB ON CHO_NONFIB.Nutr_No = 2000 join am_dv FIBTG ON FIBTG.Nutr_No = 291);
DELETE
FROM z_vars3;
INSERT INTO z_vars3 SELECT am_fat_dv_boc, am_chocdf_dv_boc, am_chocdf_dv_boc - FIBTGdv
FROM (SELECT (ENERC_KCAL.dv - (PROCNT.dv * am_cals2gram_pro) - (am_chocdf_dv_not_boc * am_cals2gram_cho)) / am_cals2gram_fat as am_fat_dv_boc, (ENERC_KCAL.dv - (PROCNT.dv * am_cals2gram_pro) - (am_fat_dv_not_boc * am_cals2gram_fat)) / am_cals2gram_cho as am_chocdf_dv_boc, FIBTG.dv as FIBTGdv
FROM z_vars1 join z_vars2 join am_dv ENERC_KCAL ON ENERC_KCAL.Nutr_No = 208 join am_dv PROCNT ON PROCNT.Nutr_No = 203 join am_dv FIBTG ON FIBTG.Nutr_No = 291);
INSERT INTO am_dv SELECT Nutr_No, CASE WHEN balance_of_calories = 204 THEN am_fat_dv_boc ELSE am_fat_dv_not_boc END, CASE WHEN balance_of_calories = 204 THEN 100.0 * Nutr_Val / am_fat_dv_boc - 100.0 ELSE 100.0 * Nutr_Val / am_fat_dv_not_boc - 100.0 END
FROM z_vars1 join z_vars2 join z_vars3 join nutr_def ON Nutr_No = 204 natural join am_analysis;
INSERT INTO am_dv SELECT Nutr_No, CASE WHEN balance_of_calories = 2000 THEN am_cho_nONfib_dv_boc ELSE am_cho_nONfib_dv_not_boc END, CASE WHEN balance_of_calories = 2000 THEN 100.0 * Nutr_Val / am_cho_nONfib_dv_boc - 100.0 ELSE 100.0 * Nutr_Val / am_cho_nONfib_dv_not_boc - 100.0 END
FROM z_vars1 join z_vars2 join z_vars3 join nutr_def ON Nutr_No = 2000 natural join am_analysis;
INSERT INTO am_dv SELECT Nutr_No, CASE WHEN balance_of_calories = 2000 THEN am_chocdf_dv_boc ELSE am_chocdf_dv_not_boc END, CASE WHEN balance_of_calories = 2000 THEN 100.0 * Nutr_Val / am_chocdf_dv_boc - 100.0 ELSE 100.0 * Nutr_Val / am_chocdf_dv_not_boc - 100.0 END
FROM z_vars1 join z_vars2 join z_vars3 join nutr_def ON Nutr_No = 205 natural join am_analysis;
INSERT INTO am_dv SELECT FASATnd.Nutr_No, CASE WHEN FASATnd.nutopt = -1.0 and FASAT.Nutr_Val > 0.0 THEN FASAT.Nutr_Val WHEN FASATnd.nutopt > 0.0 THEN FASATnd.nutopt ELSE ENERC_KCAL.dv / 2000.0 * FASATnd.dv_default END, CASE WHEN FASATnd.nutopt = -1.0 and FASAT.Nutr_Val > 0.0 THEN 0.0 WHEN FASATnd.nutopt > 0.0 THEN 100.0 * FASAT.Nutr_Val / FASATnd.nutopt - 100.0 ELSE 100.0 * FASAT.Nutr_Val / (ENERC_KCAL.dv / 2000.0 * FASATnd.dv_default) - 100.0 END
FROM z_vars1 join nutr_def FASATnd ON FASATnd.Nutr_No = 606 join am_dv ENERC_KCAL ON ENERC_KCAL.Nutr_No = 208 join am_analysis FASAT ON FASAT.Nutr_No = 606;
INSERT INTO am_dv SELECT FAPUnd.Nutr_No, CASE WHEN FAPUnd.nutopt = -1.0 and FAPU.Nutr_Val > 0.0 THEN FAPU.Nutr_Val WHEN FAPUnd.nutopt > 0.0 THEN FAPUnd.nutopt ELSE ENERC_KCAL.dv * 0.04 / am_cals2gram_fat END, CASE WHEN FAPUnd.nutopt = -1.0 and FAPU.Nutr_Val > 0.0 THEN 0.0 WHEN FAPUnd.nutopt > 0.0 THEN 100.0 * FAPU.Nutr_Val / FAPUnd.nutopt - 100.0 ELSE 100.0 * FAPU.Nutr_Val / (ENERC_KCAL.dv * 0.04 / am_cals2gram_fat) - 100.0 END
FROM z_vars1 join nutr_def FAPUnd ON FAPUnd.Nutr_No = 646 join am_dv ENERC_KCAL ON ENERC_KCAL.Nutr_No = 208 join am_analysis FAPU ON FAPU.Nutr_No = 646;
INSERT INTO am_dv SELECT FAMSnd.Nutr_No, (FAT.dv * am_fa2fat) - FASAT.dv - FAPU.dv, 100.0 * FAMS.Nutr_Val / ((FAT.dv * am_fa2fat) - FASAT.dv - FAPU.dv) - 100.0
FROM z_vars1 join am_dv FAT ON FAT.Nutr_No = 204 join am_dv FASAT ON FASAT.Nutr_No = 606 join am_dv FAPU ON FAPU.Nutr_No = 646 join nutr_def FAMSnd ON FAMSnd.Nutr_No = 645 join am_analysis FAMS ON FAMS.Nutr_No = 645;
DELETE
FROM z_n6;
INSERT INTO z_n6 SELECT NULL, CASE WHEN FAPU1 = 0.0 THEN 50.0 WHEN FAPU1 < 15.0 THEN 15.0 WHEN FAPU1 > 90.0 THEN 90.0 ELSE FAPU1 END, CASE WHEN FAPUval.Nutr_Val / FAPU.dv >= 1.0 THEN FAPUval.Nutr_Val / FAPU.dv ELSE 1.0 END, 1, 0, 900.0 * CASE WHEN SHORT3.Nutr_Val > 0.0 THEN SHORT3.Nutr_Val ELSE 0.000000001 END / ENERC_KCAL.dv, 900.0 * CASE WHEN SHORT6.Nutr_Val > 0.0 THEN SHORT6.Nutr_Val ELSE 0.000000001 END / ENERC_KCAL.dv / CASE WHEN FAPUval.Nutr_Val / FAPU.dv >= 1.0 THEN FAPUval.Nutr_Val / FAPU.dv ELSE 1.0 END, 900.0 * CASE WHEN LONG3.Nutr_Val > 0.0 THEN LONG3.Nutr_Val ELSE 0.000000001 END / ENERC_KCAL.dv, 900.0 * CASE WHEN LONG6.Nutr_Val > 0.0 THEN LONG6.Nutr_Val ELSE 0.000000001 END / ENERC_KCAL.dv / CASE WHEN FAPUval.Nutr_Val / FAPU.dv >= 1.0 THEN FAPUval.Nutr_Val / FAPU.dv ELSE 1.0 END, 900.0 * (FASAT.dv + FAMS.dv + FAPU.dv - max(SHORT3.Nutr_Val,0.000000001) - max(SHORT6.Nutr_Val,0.000000001) - max(LONG3.Nutr_Val,0.000000001) - max(LONG6.Nutr_Val,0.000000001)) / ENERC_KCAL.dv
FROM am_analysis SHORT3 join am_analysis SHORT6 ON SHORT3.Nutr_No = 3005 and SHORT6.Nutr_No = 3003 join am_analysis LONG3 ON LONG3.Nutr_No = 3006 join am_analysis LONG6 ON LONG6.Nutr_No = 3004 join am_analysis FAPUval ON FAPUval.Nutr_No = 646 join am_dv FASAT ON FASAT.Nutr_No = 606 join am_dv FAMS ON FAMS.Nutr_No = 645 join am_dv FAPU ON FAPU.Nutr_No = 646 join am_dv ENERC_KCAL ON ENERC_KCAL.Nutr_No = 208 join options;
DELETE
FROM z_vars4;
INSERT INTO z_vars4 SELECT Nutr_No, CASE WHEN Nutr_Val > 0.0 and reduce = 3 THEN Nutr_Val / pufa_reductiON WHEN Nutr_Val > 0.0 and reduce = 6 THEN Nutr_Val / pufa_reductiON - Nutr_Val / pufa_reductiON * 0.01 * (iter - 1) ELSE dv_default END, Nutr_Val
FROM nutr_def natural join am_analysis join z_n6
WHERE Nutr_No in (2006, 2001, 2002);
INSERT INTO z_vars4 SELECT Nutr_No, CASE WHEN Nutr_Val > 0.0 and reduce = 6 THEN Nutr_Val WHEN Nutr_Val > 0.0 and reduce = 3 THEN Nutr_Val - Nutr_Val * 0.01 * (iter - 2) ELSE dv_default END, Nutr_Val
FROM nutr_def natural join am_analysis join z_n6
WHERE Nutr_No in (2007, 2003, 2004, 2005);
INSERT INTO am_dv SELECT Nutr_No, dv, 100.0 * Nutr_Val / dv - 100.0
FROM z_vars4;
UPDATE am_analysis_header SET caloriebuttON = 'Calories (' || (SELECT cast (round(dv) as int)
FROM am_dv
WHERE Nutr_No = 208) || ')';
DELETE
FROM rm_dv;
INSERT INTO rm_dv SELECT Nutr_No, dv, 100.0 * Nutr_Val / dv - 100.0
FROM rm_analysis natural join am_dv;
INSERT OR replace INTO mealfoods SELECT meal_id, NDB_No, Gm_Wgt - dv * dvpct_OFfSET / (SELECT meals_per_day
FROM options) / Nutr_Val, Nutr_No
FROM rm_dv natural join nut_data natural join mealfoods
WHERE abs(dvpct_OFfSET) > 0.001 order by abs(dvpct_OFfSET) desc limit 1;
END;

DROP view IF EXISTS z_pcf;
CREATE view z_pcf as SELECT meal_id,
NDB_No, Gm_Wgt + dv / meals_per_day * dvpct_OFfSET / Nutr_Val * -1.0 as Gm_Wgt, Nutr_No

FROM mealfoods natural join rm_dv natural join nut_data join options

WHERE abs(dvpct_OFfSET) >= 0.05 order by abs(dvpct_OFfSET);

DROP TRIGGER IF EXISTS PCF_processing;
CREATE TRIGGER PCF_processing AFTER UPDATE OF PCF_processing ON z_trig_ctl WHEN NEW.PCF_processing = 1 BEGIN
UPDATE z_trig_ctl SET PCF_processing = 0;
replace INTO mealfoods SELECT *
FROM z_pcf limit 1;
UPDATE z_trig_ctl SET block_mealfoods_DELETE_TRIGGER = 0;
END;

DROP TRIGGER IF EXISTS defanal_am_TRIGGER;
CREATE TRIGGER defanal_am_TRIGGER AFTER UPDATE OF defanal_am ON options BEGIN
UPDATE z_trig_ctl SET am_analysis_header = 1;
UPDATE z_trig_ctl SET am_analysis_minus_currentmeal = CASE WHEN (SELECT mealcount
FROM am_analysis_header) > 1 THEN 1 WHEN (SELECT mealcount
FROM am_analysis_header) = 1 and (SELECT lastmeal
FROM am_analysis_header) != (SELECT currentmeal
FROM am_analysis_header) THEN 1 ELSE 0 END;
UPDATE z_trig_ctl SET am_analysis_NULL = CASE WHEN (SELECT mealcount
FROM am_analysis_header) > 1 THEN 0 WHEN (SELECT mealcount
FROM am_analysis_header) = 1 and (SELECT lastmeal
FROM am_analysis_header) != (SELECT currentmeal
FROM am_analysis_header) THEN 0 ELSE 1 END;
UPDATE z_trig_ctl SET am_analysis = 1;
UPDATE z_trig_ctl SET am_dv = 1;
UPDATE z_trig_ctl SET PCF_processing = 1;
END;

DROP TRIGGER IF EXISTS currentmeal_TRIGGER;
CREATE TRIGGER currentmeal_TRIGGER AFTER UPDATE OF currentmeal ON options BEGIN
UPDATE mealfoods SET Nutr_No = NULL
WHERE Nutr_No IS not NULL;
UPDATE z_trig_ctl SET am_analysis_header = 1;
UPDATE z_trig_ctl SET am_analysis_minus_currentmeal = CASE WHEN (SELECT mealcount
FROM am_analysis_header) > 1 THEN 1 WHEN (SELECT mealcount
FROM am_analysis_header) = 1 and (SELECT lastmeal
FROM am_analysis_header) != (SELECT currentmeal
FROM am_analysis_header) THEN 1 ELSE 0 END;
UPDATE z_trig_ctl SET am_analysis_NULL = CASE WHEN (SELECT mealcount
FROM am_analysis_header) > 1 THEN 0 WHEN (SELECT mealcount
FROM am_analysis_header) = 1 and (SELECT lastmeal
FROM am_analysis_header) != (SELECT currentmeal
FROM am_analysis_header) THEN 0 ELSE 1 END;
UPDATE z_trig_ctl SET rm_analysis_header = 1;
UPDATE z_trig_ctl SET rm_analysis = CASE WHEN (SELECT mealcount
FROM rm_analysis_header) = 1 THEN 1 ELSE 0 END;
UPDATE z_trig_ctl SET rm_analysis_NULL = CASE WHEN (SELECT mealcount
FROM rm_analysis_header) = 0 THEN 1 ELSE 0 END;
UPDATE z_trig_ctl SET am_analysis = 1;
UPDATE z_trig_ctl SET am_dv = 1;
END;

DROP TRIGGER IF EXISTS z_n6_INSERT_TRIGGER;
CREATE TRIGGER z_n6_INSERT_TRIGGER AFTER INSERT ON z_n6 BEGIN
UPDATE z_n6 SET n6hufa = (SELECT 100.0 / (1.0 + 0.0441 / p6 * (1.0 + p3 / 0.0555 + h3 / 0.005 + o / 5.0 + p6 / 0.175)) + 100.0 / (1.0 + 0.7 / h6 * (1.0 + h3 / 3.0))), reduce = 0, iter = 0;
END;

DROP TRIGGER IF EXISTS z_n6_reduce6_TRIGGER;
CREATE TRIGGER z_n6_reduce6_TRIGGER AFTER UPDATE ON z_n6 WHEN NEW.n6hufa > OLD.FAPU1 and NEW.iter < 100 and NEW.reduce in (0, 6) BEGIN
UPDATE z_n6 SET iter = iter + 1, reduce = 6, n6hufa = (SELECT 100.0 / (1.0 + 0.0441 / (p6 - iter * .01 * p6) * (1.0 + p3 / 0.0555 + h3 / 0.005 + o / 5.0 + p6 / 0.175)) + 100.0 / (1.0 + 0.7 / (h6 - iter * .01 * h6) * (1.0 + h3 / 3.0)));
END;

DROP TRIGGER IF EXISTS z_n6_reduce3_TRIGGER;
CREATE TRIGGER z_n6_reduce3_TRIGGER AFTER UPDATE OF n6hufa ON z_n6 WHEN NEW.n6hufa < OLD.FAPU1 and NEW.iter < 100 and NEW.reduce in (0, 3) BEGIN
UPDATE z_n6 SET iter = iter + 1, reduce = 3, n6hufa = (SELECT 100.0 / (1.0 + 0.0441 / p6 * (1.0 + (p3 - iter * .01 * p3) / 0.0555 + (h3 - iter * .01 * h3) / 0.005 + o / 5.0 + p6 / 0.175)) + 100.0 / (1.0 + 0.7 / h6 * (1.0 + (h3 - iter * .01 * h3) / 3.0)));
END;

DROP TRIGGER IF EXISTS INSERT_mealfoods_TRIGGER;

CREATE TRIGGER INSERT_mealfoods_TRIGGER AFTER INSERT ON mealfoods WHEN NEW.meal_id = (SELECT currentmeal
FROM options) and (SELECT count(*)
FROM mealfoods
WHERE meal_id = NEW.meal_id) = 1 BEGIN
UPDATE z_trig_ctl SET am_analysis_header = 1;
UPDATE z_trig_ctl SET am_analysis_minus_currentmeal = CASE WHEN (SELECT mealcount
FROM am_analysis_header) > 1 THEN 1 WHEN (SELECT mealcount
FROM am_analysis_header) = 1 and (SELECT lastmeal
FROM am_analysis_header) != (SELECT currentmeal
FROM am_analysis_header) THEN 1 ELSE 0 END;
UPDATE z_trig_ctl SET am_analysis_NULL = CASE WHEN (SELECT mealcount
FROM am_analysis_header) > 1 THEN 0 WHEN (SELECT mealcount
FROM am_analysis_header) = 1 and (SELECT lastmeal
FROM am_analysis_header) != (SELECT currentmeal
FROM am_analysis_header) THEN 0 ELSE 1 END;
UPDATE z_trig_ctl SET rm_analysis_header = 1;
UPDATE z_trig_ctl SET rm_analysis = CASE WHEN (SELECT mealcount
FROM rm_analysis_header) = 1 THEN 1 ELSE 0 END;
UPDATE z_trig_ctl SET rm_analysis_NULL = CASE WHEN (SELECT mealcount
FROM rm_analysis_header) = 0 THEN 1 ELSE 0 END;
UPDATE z_trig_ctl SET am_analysis = 1;
UPDATE z_trig_ctl SET am_dv = 1;
END;

DROP TRIGGER IF EXISTS DELETE_mealfoods_TRIGGER;
CREATE TRIGGER DELETE_mealfoods_TRIGGER AFTER DELETE ON mealfoods WHEN OLD.meal_id = (SELECT currentmeal
FROM options) and (SELECT count(*)
FROM mealfoods
WHERE meal_id = OLD.meal_id) = 0 BEGIN
UPDATE mealfoods SET Nutr_No = NULL
WHERE Nutr_No IS not NULL;
UPDATE z_trig_ctl SET am_analysis_header = 1;
UPDATE z_trig_ctl SET am_analysis_minus_currentmeal = CASE WHEN (SELECT mealcount
FROM am_analysis_header) > 1 THEN 1 WHEN (SELECT mealcount
FROM am_analysis_header) = 1 and (SELECT lastmeal
FROM am_analysis_header) != (SELECT currentmeal
FROM am_analysis_header) THEN 1 ELSE 0 END;
UPDATE z_trig_ctl SET am_analysis_NULL = CASE WHEN (SELECT mealcount
FROM am_analysis_header) > 1 THEN 0 WHEN (SELECT mealcount
FROM am_analysis_header) = 1 and (SELECT lastmeal
FROM am_analysis_header) != (SELECT currentmeal
FROM am_analysis_header) THEN 0 ELSE 1 END;
UPDATE z_trig_ctl SET rm_analysis_header = 1;
UPDATE z_trig_ctl SET rm_analysis = CASE WHEN (SELECT mealcount
FROM rm_analysis_header) = 1 THEN 1 ELSE 0 END;
UPDATE z_trig_ctl SET rm_analysis_NULL = CASE WHEN (SELECT mealcount
FROM rm_analysis_header) = 0 THEN 1 ELSE 0 END;
UPDATE z_trig_ctl SET am_analysis = 1;
UPDATE z_trig_ctl SET am_dv = 1;
END;

DROP TRIGGER IF EXISTS UPDATE_mealfoods2weight_TRIGGER;
CREATE TRIGGER UPDATE_mealfoods2weight_TRIGGER AFTER UPDATE ON mealfoods WHEN NEW.Gm_Wgt > 0.0 and (SELECT block_SETting_preferred_weight
FROM z_trig_ctl) = 0 BEGIN
UPDATE weight SET Gm_Wgt = NEW.Gm_Wgt
WHERE NDB_No = NEW.NDB_No and Seq = (SELECT min(Seq)
FROM weight
WHERE NDB_No = NEW.NDB_No) ;
END;

DROP TRIGGER IF EXISTS INSERT_mealfoods2weight_TRIGGER;
CREATE TRIGGER INSERT_mealfoods2weight_TRIGGER AFTER INSERT ON mealfoods WHEN NEW.Gm_Wgt > 0.0 and (SELECT block_SETting_preferred_weight
FROM z_trig_ctl) = 0 BEGIN
UPDATE weight SET Gm_Wgt = NEW.Gm_Wgt
WHERE NDB_No = NEW.NDB_No and Seq = (SELECT min(Seq)
FROM weight
WHERE NDB_No = NEW.NDB_No) ;
END;


DROP TRIGGER IF EXISTS UPDATE_weight_Seq;
CREATE TRIGGER UPDATE_weight_Seq BEFORE UPDATE OF Seq ON weight WHEN NEW.Seq = 0 BEGIN
UPDATE weight SET Seq = origSeq, Gm_Wgt = origGm_Wgt
WHERE NDB_No = NEW.NDB_No;
END;

DROP TRIGGER IF EXISTS INSERT_weight_Seq;
CREATE TRIGGER INSERT_weight_Seq BEFORE INSERT ON weight WHEN NEW.Seq = 0 BEGIN
UPDATE weight SET Seq = origSeq, Gm_Wgt = origGm_Wgt
WHERE NDB_No = NEW.NDB_No;
END;

DROP view IF EXISTS z_wslope;
CREATE VIEW z_wslope as SELECT IFNULL(weightslope,0.0) as "weightslope", IFNULL(round(sumy / n - weightslope * sumx / n,1),0.0) as "weightyintercept", n as "weightn"
FROM (SELECT (sumxy - (sumx * sumy / n)) / (sumxx - (sumx * sumx / n)) as weightslope, sumy, n, sumx
FROM (SELECT sum(x) as sumx, sum(y) as sumy, sum(x*y) as sumxy, sum(x*x) as sumxx, n
FROM (SELECT cast (cast (julianday(substr(wldate,1,4) || '-' || substr(wldate,5,2) || '-' || substr(wldate,7,2)) - julianday('now', 'localtime') as int) as real) as x, weight as y, cast ((SELECT count(*)
FROM z_wl
WHERE cleardate IS NULL) as real) as n
FROM z_wl
WHERE cleardate IS NULL)));

/*
  Basically the same thing for the slope, y-intercept, and "n" OF fat mass.
*/

DROP view IF EXISTS z_fslope;
CREATE VIEW z_fslope as SELECT IFNULL(fatslope,0.0) as "fatslope", IFNULL(round(sumy / n - fatslope * sumx / n,1),0.0) as "fatyintercept", n as "fatn"
FROM (SELECT (sumxy - (sumx * sumy / n)) / (sumxx - (sumx * sumx / n)) as fatslope, sumy, n, sumx
FROM (SELECT sum(x) as sumx, sum(y) as sumy, sum(x*y) as sumxy, sum(x*x) as sumxx, n
FROM (SELECT cast (cast (julianday(substr(wldate,1,4) || '-' || substr(wldate,5,2) || '-' || substr(wldate,7,2)) - julianday('now', 'localtime') as int) as real) as x, bodyfat * weight / 100.0 as y, cast ((SELECT count(*)
FROM z_wl
WHERE IFNULL(bodyfat,0.0) > 0.0 and cleardate IS NULL) as real) as n
FROM z_wl
WHERE IFNULL(bodyfat,0.0) > 0.0 and cleardate IS NULL)));

DROP view IF EXISTS z_span;
CREATE view z_span as SELECT abs(min(cast (julianday(substr(wldate,1,4) || '-' || substr(wldate,5,2) || '-' || substr(wldate,7,2)) - julianday('now', 'localtime') as int))) as span
FROM z_wl
WHERE cleardate IS NULL;

DROP view IF EXISTS wlog;
CREATE view wlog as SELECT *
FROM z_wl;

DROP TRIGGER IF EXISTS wlog_INSERT;
CREATE TRIGGER wlog_INSERT instead OF INSERT ON wlog BEGIN
INSERT OR replace INTO z_wl values (NEW.weight, NEW.bodyfat, (SELECT strftime('%Y%m%d', 'now', 'localtime')), NULL);
END;

DROP view IF EXISTS wlview;
CREATE VIEW wlview as SELECT wldate, weight, bodyfat, round(weight - weight * bodyfat / 100, 1) as leanmass, round(weight * bodyfat / 100, 1) as fatmass, round(weight - 2 * weight * bodyfat / 100) as bodycomp, cleardate
FROM z_wl;

DROP view IF EXISTS wlsummary;
CREATE view wlsummary as SELECT CASE
WHEN (SELECT weightn
FROM z_wslope) > 1 THEN
'Weight:  ' || (SELECT round(weightyintercept,1)
FROM z_wslope) || char(13) || char(10) ||
'Bodyfat:  ' || CASE WHEN (SELECT weightyintercept
FROM z_wslope) > 0.0 THEN round(1000.0 * (SELECT fatyintercept
FROM z_fslope) / (SELECT weightyintercept
FROM z_wslope)) / 10.0 ELSE 0.0 END || '%' || char(13) || char(10)
WHEN (SELECT weightn
FROM z_wslope) = 1 THEN
'Weight:  ' || (SELECT weight
FROM z_wl
WHERE cleardate IS NULL) || char(13) || char(10) ||
'Bodyfat:  ' || (SELECT bodyfat
FROM z_wl
WHERE cleardate IS NULL) || '%'
ELSE
'Weight:  0.0' || char(13) || char(10) ||
'Bodyfat:  0.0%'
END || char(13) || char(10) ||
'Today' || "'" || 's Calorie level = ' || (SELECT cast(round(nutopt) as int)
FROM nutr_def
WHERE Nutr_No = 208)
|| char(13) || char(10)
|| char(13) || char(10) ||
CASE WHEN (SELECT weightn
FROM z_wslope) = 0 THEN '0 data points so far...'
WHEN (SELECT weightn
FROM z_wslope) = 1 THEN '1 data point so far...'
ELSE
'Based ON the trEND OF ' || (SELECT cast(cast(weightn as int) as text)
FROM z_wslope) || ' data points so far...' || char(13) || char(10) || char(10) ||
'Predicted lean mass today = ' ||
(SELECT cast(round(10.0 * (weightyintercept - fatyintercept)) / 10.0 as text)
FROM z_wslope, z_fslope) || char(13) || char(10) ||
'Predicted fat mass today  =  ' ||
(SELECT cast(round(fatyintercept, 1) as text)
FROM z_fslope) || char(13) || char(10) || char(10) ||
'If the predictiONs are correct, you ' ||
CASE WHEN (SELECT weightslope - fatslope
FROM z_wslope, z_fslope) >= 0.0 THEN 'gained ' ELSE 'lost ' END ||
(SELECT cast(abs(round((weightslope - fatslope) * span * 1000.0) / 1000.0) as text)
FROM z_wslope, z_fslope, z_span) ||
' lean mass over ' ||
(SELECT span
FROM z_span) ||
CASE WHEN (SELECT span
FROM z_span) = 1 THEN ' day' ELSE ' days' END || char(13) || char(10) ||
CASE WHEN (SELECT fatslope
FROM z_fslope) > 0.0 THEN 'and gained ' ELSE 'and lost ' END ||
(SELECT cast(abs(round(fatslope * span * 1000.0) / 1000.0) as text)
FROM z_fslope, z_span) || ' fat mass.'

END
AS VERBIAGE;

DROP TRIGGER IF EXISTS clear_wlsummary;
CREATE TRIGGER clear_wlsummary INSTEAD OF INSERT ON wlsummary
WHEN
    (
        SELECT autocal
        FROM options
    ) = 0
BEGIN
    UPDATE z_wl SET cleardate = (SELECT strftime('%Y%m%d', 'now', 'localtime'))
    WHERE cleardate IS NULL;

    INSERT INTO z_wl SELECT weight, bodyfat, wldate, NULL
    FROM z_wl
    WHERE wldate = (SELECT max(wldate) FROM z_wl);
END;

DROP TRIGGER IF EXISTS autocal_initializatiON;
CREATE TRIGGER autocal_initialization
AFTER UPDATE OF autocal
ON options
WHEN NEW.autocal IN (1, 2, 3) AND OLD.autocal NOT IN (1, 2, 3)
BEGIN
    UPDATE options SET wltweak = 0, wlpolarity = 0;
END;

DROP TRIGGER IF EXISTS mpd_archive;
CREATE TRIGGER mpd_archive
AFTER UPDATE OF meals_per_day
ON options
WHEN NEW.meals_per_day != OLD.meals_per_day
BEGIN

INSERT OR IGNORE INTO archive_mealfoods
SELECT meal_id, NDB_No, Gm_Wgt, OLD.meals_per_day
FROM mealfoods;

DELETE
FROM mealfoods;

INSERT OR IGNORE INTO mealfoods
SELECT meal_id, NDB_No, Gm_Wgt, NULL
FROM archive_mealfoods
WHERE meals_per_day = NEW.meals_per_day;

DELETE
FROM archive_mealfoods
WHERE meals_per_day = NEW.meals_per_day;

UPDATE options
SET defanal_am =
    (
        SELECT count(dIStinct meal_id)
        FROM mealfoods
    );
END;

UPDATE nutr_def SET nutopt = 0.0
WHERE nutopt IS NULL;

UPDATE options
SET currentmeal =
    CASE
        WHEN currentmeal IS NULL THEN
            0
        ELSE
            currentmeal
    END;

UPDATE options
SET defanal_am =
    CASE
        WHEN defanal_am IS NULL THEN
            0
        ELSE
            defanal_am
    END;

--commit;
ANALYZE main;
"""
trigger_init = '''
DROP TRIGGER IF EXISTS am_analysis_header_trigger;
CREATE TRIGGER am_analysis_header_trigger
AFTER UPDATE OF am_analysis_header ON z_trig_ctl
WHEN NEW.am_analysis_header = 1
BEGIN
  UPDATE z_trig_ctl SET am_analysis_header = 0;

  DELETE
  FROM am_analysis_header;

  INSERT INTO am_analysis_header
  SELECT
    (
      SELECT count(dIStinct meal_id)
      FROM mealfoods
    ) AS maxmeal,
    count(meal_id) AS mealcount,
    meals_per_day,
    IFNULL(min(meal_id),0) AS firstmeal,
    IFNULL(max(meal_id),0) AS lastmeal,
    currentmeal,
    NULL AS caloriebutton,
    NULL AS macropct,
    NULL AS n6balance
  FROM options LEFT JOIN
    (
      SELECT dIStinct meal_id
      FROM mealfoods
      ORDER BY meal_id DESC
      LIMIT
        (
          SELECT defanal_am
          FROM options
        )
    );
END;

DROP TRIGGER IF EXISTS rm_analysis_header_trigger;
CREATE TRIGGER rm_analysis_header_trigger
AFTER UPDATE OF rm_analysis_header ON z_trig_ctl
WHEN NEW.rm_analysis_header = 1
BEGIN
  UPDATE z_trig_ctl SET rm_analysis_header = 0;

  DELETE
  FROM rm_analysis_header;

  INSERT INTO rm_analysis_header
  SELECT maxmeal, CASE WHEN
    (
      SELECT count(*)
      FROM mealfoods
      WHERE meal_id = currentmeal
    ) = 0 THEN
      0
    ELSE
      1
    END AS mealcount,
    meals_per_day,
    currentmeal AS firstmeal,
    currentmeal AS lastmeal,
    currentmeal AS currentmeal,
    NULL AS caloriebuttON,
    '0 / 0 / 0' AS macropct,
    '0 / 0' AS n6balance
  FROM am_analysis_header;
END;

DROP TRIGGER IF EXISTS am_analysis_minus_currentmeal_trigger;
CREATE TRIGGER am_analysis_minus_currentmeal_trigger AFTER UPDATE OF am_analysis_minus_currentmeal ON z_trig_ctl WHEN NEW.am_analysis_minus_currentmeal = 1 BEGIN
UPDATE z_trig_ctl SET am_analysis_minus_currentmeal = 0;
DELETE
FROM z_anal;
INSERT INTO z_anal SELECT Nutr_No, CASE WHEN sum(mhectograms * Nutr_Val) IS NULL THEN 1 ELSE 0 END, IFNULL(sum(mhectograms * Nutr_Val), 0.0)
FROM (SELECT NDB_No, total(Gm_Wgt / 100.0 / mealcount * meals_per_day) as mhectograms
FROM mealfoods join am_analysis_header
WHERE meal_id between firstmeal and lastmeal and meal_id != currentmeal group by NDB_No) join nutr_def natural left join nut_data group by Nutr_No;
END;


DROP TRIGGER IF EXISTS am_analysis_NULL_TRIGGER;
CREATE TRIGGER am_analysis_NULL_TRIGGER AFTER UPDATE OF am_analysis_NULL ON z_trig_ctl WHEN NEW.am_analysis_NULL = 1 BEGIN
UPDATE z_trig_ctl SET am_analysis_NULL = 0;
DELETE
FROM z_anal;
INSERT INTO z_anal SELECT nutr_no, 1, 0.0
FROM nutr_def join am_analysis_header
WHERE firstmeal = currentmeal and lastmeal = currentmeal;
INSERT INTO z_anal SELECT nutr_no, 0, 0.0
FROM nutr_def join am_analysis_header
WHERE firstmeal != currentmeal OR lastmeal != currentmeal;
UPDATE am_analysis_header SET macropct = '0 / 0 / 0', n6balance = '0 / 0';
END;

DROP TRIGGER IF EXISTS rm_analysis_NULL_TRIGGER;
CREATE TRIGGER rm_analysis_NULL_TRIGGER AFTER UPDATE OF rm_analysis_NULL ON z_trig_ctl WHEN NEW.rm_analysis_NULL = 1 BEGIN
UPDATE z_trig_ctl SET rm_analysis_NULL = 0;
DELETE
FROM rm_analysis;
INSERT INTO rm_analysis SELECT Nutr_No, 0, 0.0
FROM nutr_def;
UPDATE rm_analysis_header SET caloriebuttON = (SELECT caloriebuttON
FROM am_analysis_header), macropct = '0 / 0 / 0', n6balance = '0 / 0';
END;


DROP TRIGGER IF EXISTS am_analysis_TRIGGER;
CREATE TRIGGER am_analysis_TRIGGER AFTER UPDATE OF am_analysis ON z_trig_ctl WHEN NEW.am_analysis = 1 BEGIN
UPDATE z_trig_ctl SET am_analysis = 0;
UPDATE am_analysis_header SET macropct = (SELECT cast (IFNULL(round(100 * PROT_KCAL.Nutr_Val / ENERC_KCAL.Nutr_Val,0),0) as int) || ' / ' || cast (IFNULL(round(100 * CHO_KCAL.Nutr_Val / ENERC_KCAL.Nutr_Val,0),0) as int) || ' / ' || cast (IFNULL(round(100 * FAT_KCAL.Nutr_Val / ENERC_KCAL.Nutr_Val,0),0) as int)
FROM am_analysis ENERC_KCAL join am_analysis PROT_KCAL ON ENERC_KCAL.Nutr_No = 208 and PROT_KCAL.Nutr_No = 3000 join am_analysis CHO_KCAL ON CHO_KCAL.Nutr_No = 3002 join am_analysis FAT_KCAL ON FAT_KCAL.Nutr_No = 3001);

'''
