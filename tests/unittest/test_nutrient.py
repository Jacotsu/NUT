import pytest
import logging
from nut_nutrition import nutrient
from db import DBMan
import bignut_queries


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
    conn = None
    try:
        conn = sqlite3.connect(':memory:')
        conn.text_factory = decode_non_UTF_strings
        with conn as con:
            cur = con.cursor()
            # Initializes db structure
            cur.execute(bignut_queries.init_logic)
            cur.execute(bignut_queries.db_load_pt2)
            cur.execute(bignut_queries.user_init_query)

    except sqlite3.Error as e:
        logging.error(e)

    return conn


@pytest.fixture
def db_man():
    return db.DBMan(':memory:')


@pytest.fixture
def test_nutrient(db_man):
    return nutrient.Nutrient(2500, db_man)


class TestNutrient:
    def test_constructor_invalid_nutr_no():
        try:
            nutrient.Nutrient(-1, 'db')
            assert False
        except ValueError:
            assert True

    def test_get_nut_opt(db_conn):
