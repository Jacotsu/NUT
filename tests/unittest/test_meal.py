#!/usr/bin/env python
import pytest
import logging
from nut_nutrition import db, bignut_queries, meal


def decode_non_UTF_strings(bytes_array):
    try:
        return bytes_array.decode('UTF-8')
    except UnicodeDecodeError as decode_error:
        decoded = bytes_array.decode('windows-1252')
        logging.error(decoded)
        logging.error(decode_error)
        return decoded


@pytest.fixture
def db_conn(tmpdir, request):
    import sqlite3
    tmp_db_path = tmpdir.join("nut_test.db")
    conn = None
    try:
        conn = sqlite3.connect(tmp_db_path)
        conn.text_factory = decode_non_UTF_strings
    except sqlite3.Error as e:
        logging.error(e)

    with conn as con:
        cur = con.cursor()
        # Database init code
        yield cur


def test_current_meal(db_conn):
    # Get test
    # Must implement set test
    current_meal = meal.Meal(2019031902)
    db_conn.execute(bignut_queries.set_current_meal, (current_meal.meal_id))
    data = db_conn.execute(bignut_queries.get_current_meal)
    assert data[0] == current_meal.meal_id
