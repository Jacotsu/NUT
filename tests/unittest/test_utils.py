#!/usr/bin/env python
from nut_nutrition import utils
import math


def test_decode_ratios():
    res = utils.decode_ratios(2.012000)
    assert res == [12, 0]
    res = utils.decode_ratios(2.012349)
    assert res == [12, 349]
    res = utils.decode_ratios(4.000587077033)
    assert res == [0, 587, 77, 33]
    res = utils.decode_ratios(2.2288, 2)
    assert res == [22, 88]


def test_encode_ratios():
    res = utils.encode_ratios([12, 349])
    assert math.isclose(res, 2.012349, abs_tol=1e-12)
    res = utils.encode_ratios([0, 587, 77, 33])
    assert math.isclose(res, 4.000587077033, abs_tol=1e-12)
    res = utils.encode_ratios([22, 88], 2)
    assert math.isclose(res, 2.2288, abs_tol=1e-12)
