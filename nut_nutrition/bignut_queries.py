# .read load
# .read logic !! only if new database, it can wipe everything
# .read user
# .headers ON user for debugging

get_defined_nutrients = 'SELECT * FROM nutr_def;'

set_nutrient_DV = 'UPDATE nutr_def SET nutopt = ? where NutrDesc = ?;'

set_number_of_meals_to_analyze = 'UPDATE options SET defanal_am = ?;'
get_number_of_meals_to_analyze = 'SELECT defanal_am FROM options;'
# to implement
get_day_meals = ''

get_weight_unit = 'SELECT grams FROM options;'
set_weight_unit = 'UPDATE options set grams = ?'

get_current_meal = 'SELECT currentmeal FROM options;'
get_current_meal_food = 'SELECT * FROM currentmeal;'
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
SELECT rm_analysis.Nutr_No, Units, Tagname, NutrDesc,
    dvpct_offset + 100, Nutr_val
FROM rm_analysis
LEFT JOIN rm_dv on rm_analysis.Nutr_No = rm_dv.Nutr_No
NATURAL JOIN nutr_def NATURAL JOIN rm_analysis;
'''
get_am_analysis = '''
SELECT am_analysis.Nutr_No, Units, Tagname, NutrDesc,
    dvpct_offset + 100, Nutr_val
FROM am_analysis
LEFT JOIN am_dv on am_analysis.Nutr_No = am_dv.Nutr_No
NATURAL JOIN nutr_def NATURAL JOIN am_analysis;
'''
get_am_analysis_period = 'SELECT firstmeal, lastmeal FROM am_analysis_header;'

get_omega6_3_bal = 'SELECT n6balance from am_analysis_header;'

get_food_groups = 'SELECT FdGrp_Cd, FdGrp_Desc FROM fd_group;'

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
WHERE meal_id = :meal_id AND NDB_No = :NDB_No;
'''


get_food_list = 'SELECT NDB_No, Long_Desc FROM food_des;'
get_food_from_NDB_No = 'SELECT * FROM food_des WHERE NDB_No = ?;'
search_food = 'select NDB_No, Long_Desc from food_des where Long_Desc'\
              ' like ?;'
get_food_sorted_by_nutrient = """
    SELECT Long_Desc FROM fd_group NATURAL JOIN food_des NATURAL JOIN nut_data
    WHERE FdGrp_Desc like ? AND Nutr_No = ? ORDER BY Nutr_Val desc;
    """
get_food_preferred_weight = 'SELECT * FROM pref_Gm_Wgt WHERE NDB_No = ?;'
get_food_nutrients = 'SELECT * FROM nut_data WHERE NDB_No = ?;'
get_food_nutrients_at_pref_weight = """
SELECT
    NDB_No,
    Nutr_Val,
    NutrDesc,
    Nutr_Val,
    Units,
    dv
FROM view_foods
WHERE NDB_No = :NDB_No;
"""
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
    WHERE nutrient.Nutr_No = ?
        AND meal_id >= ? || '00'
        AND meal_id <= ? || '99'
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
/*
  User initiated stuff goes here.  The following PRAGMA is essential at each
  invocation, but most of the stuff in this file isn't strictly necessary.  If it is
  necessary, with the exception of automatic portion control and weight log, it should go into 
  logic.sqlite3.  Just about everything in this init file is and should be "temp" so
  it goes away for you if you close the database connection, but it doesn't go away for the
  other connections that came in with the same user init.  The only exceptions are the
  shopping list and cost table which need to be persistent and therefore real tables.
*/ PRAGMA recursive_triggers = 1;

BEGIN;

/*
  HEERE BEGYNNETH AUTOMATIC PORTION CONTROL (PCF)
*/ /*
  If a mealfoods replace causes the delete trigger to start, we get a
  recursive nightmare.  So we need a before insert trigger.
*/
DROP TRIGGER IF EXISTS before_mealfoods_insert_pcf;


CREATE TEMP TRIGGER before_mealfoods_insert_pcf
BEFORE
INSERT ON mealfoods WHEN
  (SELECT block_mealfoods_insert_trigger
   FROM z_trig_ctl) = 0 BEGIN
UPDATE z_trig_ctl
SET block_mealfoods_delete_trigger = 1; END;

/*
  A mealfoods insert trigger
*/
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

/*
  A mealfoods update trigger
*/
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

/*
  A mealfoods delete trigger.  One of the bizarre consequences of these
  inscrutable recursive triggers is that if you want to delete everything
  in the current meal, you can't delete from the table mealfoods unless you
  first set the Nutr_No column to null for all rows.  Frankly, I don't yet
  understand why this is so; however an unconditional delete of everything
  from the view currentmeal does seem to work properly without having to
  null out the NutrDesc column.
*/
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

/*
  Another thing that can start automatic portion control is changing the
  nutopt in nutr_def which will change the Daily Values.  And then the same
  thing for FAPU1 in options.
*/
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

/*
  HEERE ENDETH AUTOMATIC PORTION CONTROL (PCF)
*/ /*
  We often want to grab the preferred weight for a food so we create a special
  view that dishes it up!  This view delivers the preferred Gm_Wgt and the
  newly computed Amount of the serving unit.  The preferred weight is never
  zero or negative, so if the Gm_Wgt might not be > 0.0 you need special logic.
*/
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

/*
  Here's an "INSTEAD OF" trigger to allow updating the Gm_Wgt of the
  preferred weight record.
*/
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

/*
  This is a variant of the previous trigger to change the preferred Gm_Wgt
  of a food by specifying the Amount of the serving unit, the Msre_Desc.
  In addition, it proffers an update to the Gm_Wgt of the food in the
  current meal, just in case that is the reason for the update.
*/
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

/*
  Using the preferred weight, we can View Foods in various ways.
*/
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

/*
  We create a convenience view of the current meal, aka mealfoods.
*/
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

/*
  OK, now the INSTEAD OF trigger to simplify somewhat the insertion of a
  meal food:
*/
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

/*
  It's simpler to delete a mealfood with currentmeal than to just delete
  it from mealfoods because you don't have to specify the meal_id.
*/
DROP TRIGGER IF EXISTS currentmeal_delete;


CREATE TEMP TRIGGER currentmeal_delete INSTEAD OF
DELETE ON currentmeal BEGIN
DELETE
FROM mealfoods
WHERE meal_id =
    (SELECT currentmeal
     FROM OPTIONS)
  AND NDB_No = OLD.NDB_No; END;

/*
  We often want to update a Gm_Wgt in the current meal.
*/
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

/*
  And finally, we often want to modify automatic portion control on the
  current meal.
*/
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

/*
  Here's a convenience view of customary meals, aka theusual
*/
DROP VIEW IF EXISTS theusual;


CREATE TEMP VIEW theusual AS
SELECT meal_name,
       NDB_No,
       Gm_Wgt,
       NutrDesc
FROM z_tu
NATURAL JOIN pref_Gm_Wgt
LEFT JOIN nutr_def USING (Nutr_No);

/*
  We have the view, now we need the triggers.

  First, we handle inserts from the current meal.
*/
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

/*
  Now we allow customary meals to be deleted.
*/
DROP TRIGGER IF EXISTS theusual_delete;


CREATE TEMP TRIGGER theusual_delete INSTEAD OF
DELETE ON theusual WHEN OLD.meal_name IS NOT NULL BEGIN
DELETE
FROM z_tu
WHERE meal_name = OLD.meal_name; END;

/*
  Sorry I didn't write triggers to handle each theusual eventuality,
  but you can always work directly on z_tu for your intricate updating needs.
*/ /*
  We create convenience views to report which foods in the meal analysis are
  contributing to a nutrient intake.  Use it like this (for example):
	select * from nut_in_meals where NutrDesc = 'Protein';
	select * from nutdv_in_meals where NutrDesc = 'Zinc';
	select * from nutdv_in_meals where ndb_no = 'xxxxx' order by cast(val as int);

  nutdv_in_meals returns nothing if nutrient has no DV

  Then 2 views of average daily food consumption over the analysis period.

  Then a really interesting view.  We find, for each nutrient, the food that
  contributed the highest amount of the nutrient, and sort the output by food
  so you can really see which foods make a big contribution to your nutrition
  in this amazing view "nut_big_contrib".  And if you don't want to see every
  fatty acid, etc., just the daily value nutrients, the "nutdv_big_contrib"
  view will do it.

*/
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

/*
   Now, the same as previous but for the database as a whole, both for 100 gm
   and 100 calorie portions.  So, for example, most glycine in sweets would
   be:
	select * from nut_in_100g where NutrDesc = 'Glycine' and FdGrp_Cd =
        1900;
*/
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

/*
  The actual autocal triggers that run the weight log application have to be
  invoked by the user because they would really run amok during bulk updates.

  The autocal feature is kicked off by an insert to z_wl, the actual weight
  log table.  There are many combinations of responses, each implemented by
  a different trigger.

  First, the proceed or do nothing trigger.
*/ /*
drop trigger if exists autocal_proceed;
create temp trigger autocal_proceed after insert on z_wl
when (select autocal = 2 and weightn > 1 and (weightslope - fatslope) >= 0.0 and fatslope <= 0.0 from z_wslope, z_fslope, z_span, options)
begin
select null;
end;
*/ /*
  Just joking!  It doesn't do anything so we don't need it!  But as we change
  the conditions, the action changes.

  For instance, lean mass is going down or fat mass is going up, so we give up
  on this cycle and clear the weightlog to move to the next cycle.
  We always add a new entry to get a head start on the next cycle, but in this
  case we save the last y-intercepts as the new start.  We also make an
  adjustment to calories:  up 20 calories if both lean mass and fat mass are
  going down, or down 20 calories if they were both going up.

  If fat was going up and and lean was going down we make no adjustment because,
  well, we just don't know!
*/
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

/*
  We create a shopping list where the "n" column automatically gives a serial
  number for easy deletion of obtained items, or we can delete by store.
  Insert into the table this way:
	INSERT into shopping values (null, 'potatoes', 'tj');
*/
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

/*
  A persistent table for food cost.  There are at least three different situations:
  1) food serving weight is just a percentage of the package and therefore its cost;
     for instance if 454 grams (1 pound) of almonds costs $6.00 then gm_size = 454,
     cost = 6.0
  2) food serving weight is only distantly related to the cost; for instance, coffee
     costs 10.00 a pound (454 grams) but 7 grams of coffee makes 30 grams of espresso,
     so gm_size = (454.0 / 7.0) * 30.0, cost = 10.0
  3) food weight as bought has a lot of refuse; for instance, chicken is 3.50 a pound
     but has 30% refuse, so gm_size = 454 * 0.7, cost = 3.50.
*/
CREATE TABLE IF NOT EXISTS cost (ndb_no int PRIMARY KEY,
                                                    gm_size real, cost real);

/*
  Views of the daily food cost:  listing by food per day and grand total per day
  over the whole analysis period; plus total for currentmeal.
*/
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

/*
  A purely personal view.  max_chick is about portion control for various parts
  of a raw cut-up chicken based on protein and fat values that will fit into the meal.
*/
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

/*
  View showing daily macros and body composition index
*/
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

/*
  This is the select that I use to look at the nutrient values for the current meal.
*/
DROP VIEW IF EXISTS ranalysis;


CREATE TEMP VIEW ranalysis AS
SELECT NutrDesc,
       round(Nutr_Val, 1) || ' ' || Units,
       cast(cast(round(100.0 + dvpct_offset) AS int) AS text) || '%'
FROM rm_analysis
NATURAL JOIN rm_dv
NATURAL JOIN nutr_def
ORDER BY dvpct_offset DESC;

/*
  This is the select that I use to look at the nutrient values for the
  whole analysis period.
*/
DROP VIEW IF EXISTS analysis;


CREATE TEMP VIEW analysis AS
SELECT NutrDesc,
       round(Nutr_Val, 1) || ' ' || Units,
       cast(cast(round(100.0 + dvpct_offset) AS int) AS text) || '%'
FROM am_analysis
NATURAL JOIN am_dv
NATURAL JOIN nutr_def
ORDER BY dvpct_offset DESC;

/*
  A totally unneccesary bit of fluff:  a persistent table to hold a name for the
  current eating plan.
*/
CREATE TABLE IF NOT EXISTS eating_plan (plan_name text);

/*
  This view spells out a more easily readable string for the current meal as defined
  in the options table.
*/
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

db_load = """
/* Especially when you add a GUI and a second thread to handle the database, the
   application runs much faster with write-ahead logging.  However, to put the
   database back into one file, issue the command "pragma journal_mode = delete;".
   You would do this if you wanted to move the database to another system.  If
   you delete nut.db-wal and/or nut.db-shm manually, you will corrupt the database.

PRAGMA journal_mode = WAL;
*/

begin;

/* These temp tables must start out corresponding exactly to the USDA schemas
   for import from the USDA's distributed files but in some cases we need
   transitional temp tables to safely add what's new from the USDA to what the
   user already has.
*/

/* For NUTR_DEF, we get rid of the tildes which escape non-numeric USDA fields,
   and add two fields:  dv_default to use when Daily Value is undefined, and
   nutopt which has three basic values:  -1 which means DV is whatever is in
   the user's analysis unless null or <= 0.0 in which case the dv_default is
   used; 0.0 which means the default Daily Value or computation; and > 0.0 which
   is a specific gram amount of the nutrient.

   We also shorten the names of nutrients so they can better fit on the screen
   and add some nutrients that are derived from USDA values.
*/

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
/* FD_GROUP
*/

CREATE temp TABLE tfd_group
  (
     fdgrp_cd   INT,
     fdgrp_desc TEXT
  );

/* FOOD_DES gets a new Long_Desc which is the USDA Long_Desc with the SciName
   appended in parenthesis.  If the new Long_Desc is <= 60 characters, it
   replaces the USDA's Shrt_Desc, which is sometimes unnecessarily cryptic.
*/

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
/* WEIGHT gets two new fields, origSeq and origGm_Wgt.  USDA Seq numbers start
   at one, so we change the Seq to 0 when we want to save the user's serving
   unit preference.  origSeq allows us to put the record back to normal if the
   user later chooses another Serving Unit.  The first record for a food when
   ordered by Seq can have its Gm_Wgt changed, and later we will define views
   that present the Amount of the serving unit as Gm_Wgt / origGm_Wgt * Amount.
*/

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
/* The USDA uses a caret as a column separator and has no special end-of-line */

.separator "^"

/* We import the USDA data to the temp tables */
-- need to parametrize

.import NUTR_DEF.txt ttnutr_def
.import FD_GROUP.txt tfd_group
.import FOOD_DES.txt tfood_des
.import WEIGHT.txt tweight
.import NUT_DATA.txt tnut_data

/* These real NUT tables may already exist and contain user data */

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
/* Update table nutr_def. */

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

/* Update table fg_group */

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

/* Update table food_des. */

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

/*
   the weight table is next, and needs a little explanation.  The Seq
   column is a key and starts at 1 from the USDA; however, we want
   the user to be able to select his own serving unit, and we do that
   by changing the serving unit the user wants to Seq = 0, while saving
   what the original Seq was in the origSeq column so that we can get back
   later.  Furthermore, a min(Seq) as grouped by NDB_No can have its weight
   modified in order to save a preferred serving size, so we also make a copy
   of the original weight of the serving unit called origGm_Wgt.  Thus we
   always get the Amount of the serving to be displayed by the equation:
	Amount displayed = Gm_Wgt / origGm_Wgt * Amount
*/

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

/* Update table nut_data */

insert or replace into nut_data select trim(NDB_No, '~'), trim(Nutr_No, '~'), Nutr_Val from tnut_data;
drop table tnut_data;

/* NUT has derived nutrient values that are handled as if they are
   USDA nutrients to save a lot of computation and confusion at runtime
   because the values are already there */

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


/* NUT needs some additional permanent tables for options, mealfoods, archive
   of mealfoods if meals per day changes, customary meals (theusual), and
   the weight log */

/* This table is global options:
    defanal_am    how many meals to analyze starting at the latest and going
                  back in time
    FAPU1         the "target" for Omega-6/3 balance
    meals_per_day yes, meals per day
    grams         boolean true means grams, false means ounces avoirdupois and
                  never means fluid ounces
    currentmeal   10 digit integer YYYYMMDDxx where xx is daily meal number
    wltweak       Part of the automatic calorie set feature.  If NUT moves the
                  calories during a cycle to attempt better body composition,
                  wltweak is true.  It is always changed to false at the
                  beginning of a cycle.  However, current algorithm doesn't use it.
    wlpolarity    In order not to favor gaining lean mass over losing fat mass,
                  NUT cycles this between true and false to alternate strategies.
                  However, current algorithm doesn't use it.
    autocal       0 means no autocal feature, 2 means feature turned on.
                  The autocal feature moves calories to try to achieve
                  a calorie level that allows both fat mass loss and lean mass
                  gain.
*/
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

/*
   The table of what and how much eaten at each meal, plus a place for a
   nutrient number to signify automatic portion control on this serving.
   Automatic portion control (PCF) means add up everything from this meal
   for this single nutrient and then adjust the quantity of this particular
   food so that the daily value is exactly satisfied.
*/
CREATE TABLE IF NOT EXISTS mealfoods
  (
     meal_id INT,
     ndb_no  INT,
     gm_wgt  REAL,
     nutr_no INT,
     PRIMARY KEY(meal_id, ndb_no)
  );

/*
   There is no easy way to analyze a meal where each day can have a
   different number of meals per day because you have to do a lot of computation
   to combine the meals, and for any particular meal, you cannot provide
   guidance because you don't know how many more meals are coming for the day.
   So, when the user changes meals_per_day we archive the non-compliant meals
   (different number of meals per day from new setting)  and restore the
   compliant ones (same number of meals per day as new setting).
*/

create table if not exists archive_mealfoods(meal_id int, NDB_No int, Gm_Wgt real, meals_per_day integer, primary key(meal_id desc, NDB_No asc, meals_per_day));

/* Table of customary meals which also has a Nutr_No for specification of
   PCF or automatic portion control.  We call it z_tu so we can define a
   "theusual" view later to better control user interaction.
*/

create table if not exists z_tu(meal_name text, NDB_No int, Nutr_No int, primary key(meal_name, NDB_No), unique(meal_name, Nutr_No));

/* The weight log.  When the weight log is "cleared" the info is not erased.
   Null cleardates identify the current log.  As we have been doing, we call
   the real table z_wl, so we can have a couple of views that allow us to
   control user interaction, wlog and wlsummary.
*/

create table if not exists z_wl(weight real, bodyfat real, wldate int, cleardate int, primary key(wldate, cleardate));

/* To protect table options from extraneous inserts we create a trigger */

drop trigger if exists protect_options;
create trigger protect_options after insert on options begin delete from options where protect != 1; end;

/* This insert will have no effect if options are already there */

insert into options default values;

drop trigger protect_options;
commit;
vacuum;
"""
