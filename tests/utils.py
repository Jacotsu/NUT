#!/usr/bin/env python
from nut_nutrition import utils


def test_decode_ratios():
    res = utils.decode_ratios(2.0123499)
    assert res == [12, 349]
    res = utils.decode_ratios(4.0005870770339)
    assert res == [0, 587, 77, 33]
    res = utils.decode_ratios(3.22889, 2)
    assert res == [22, 88]


def test_encode_ratios():
    res = utils.encode_ratios([12, 349])
    assert res == 2.0123499
    res = utils.encode_ratios([0, 587, 77, 33])
    assert res == 4.0005870770339
    res = utils.decode_ratios([22, 88], 2)
    assert res == 3.22889
