#!/bin/sh
# the next line restarts using tclsh \
exec tclsh "$0" "$@"

# NUT nutrition software
# Copyright (C) 1996-2015 by Jim Jozwiak.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA

#
# Change the following two code lines to show the locations of your NUTsqlite
# and NUTsqlheavy databases then run this script to copy your personal data
# from the former to the latter.
#

set lite [file nativename ~/src/nut/nut.sqlite]
set big [file nativename ~/src/bigNUT/nut.db]

package require sqlite3
sqlite3 db $big

db eval {ATTACH $lite AS lite}
db eval {begin}
db eval {update options set currentmeal = 0}
db eval {delete from mealfoods; insert into mealfoods select meal_date * 100 + meal, NDB_No, mhectograms * 100, null from lite.mealfoods}
db eval {delete from archive_mealfoods; insert into archive_mealfoods select meal_date * 100 + meal, NDB_No, mhectograms * 100, meals_per_day from lite.archive_mealfoods}
db eval {delete from z_wl; insert into z_wl select * from lite.wlog order by wldate, cleardate}
db eval {delete from z_tu; insert into z_tu select meal_name, NDB_No, Nutr_No from lite.theusual left join lite.nutr_def on NutrDesc = PCF}
db eval {select Tagname, Nutr_No, nutopt from lite.nutr_def} {
 db eval "insert or ignore into nut_data select NDB_No, $Nutr_No, $Tagname from lite.food_des where NDB_No >= 99000 and $Tagname is not null"
 db eval {update nutr_def set nutopt = $nutopt where Nutr_No = $Nutr_No}
 }
db eval {insert or ignore into food_des select NDB_No, FdGrp_Cd, Long_Desc, Shrt_Desc, Ref_desc, Refuse, Pro_Factor, Fat_Factor, CHO_Factor from lite.food_des where NDB_No >= 99000}
db eval {create temp table zweight (NDB_No int, Seq int, Amount real, Msre_Desc text, Gm_Wgt real, origSeq int, origGm_Wgt, primary key(NDB_No, origSeq))}
db eval {insert or ignore into zweight select * from weight}
db eval {insert or replace into zweight select NDB_No, Seq, origAmount, Msre_Desc, whectograms * 100.0, origSeq, orighectograms * 100.0 from lite.weight where NDB_No >= 99000 or Seq != origSeq or whectograms != orighectograms}
db eval {insert or replace into weight select * from zweight}
db eval {drop table zweight}
db eval {PRAGMA recursive_triggers = 1; analyze main}
db eval {update options set defanal_am = case when (select defanal_am from lite.options) = 0 then 2147123119 else (select defanal_am from lite.options) end, currentmeal = (select lastmeal_rm from lite.options), FAPU1 = (select FAPU1 from lite.options), grams = (select grams from lite.options), wltweak = (select wltweak from lite.options), wlpolarity = (select wlpolarity from lite.options), autocal = (select autocal from lite.options)}
db eval {delete from shopping; insert into shopping select * from lite.shopping}
db eval {commit}

db close
