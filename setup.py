from setuptools import setup
import os
import re


here = os.path.abspath(os.path.dirname(__file__))
with open(os.path.join(here, 'README.rst'), encoding='utf-8') as f:
    long_description = f.read()


def read(*names, **kwargs):
    with open(
        os.path.join(os.path.dirname(__file__), *names),
        encoding=kwargs.get("encoding", "utf8")
    ) as fp:
        return fp.read()


def find_version(*file_paths):
    version_file = read(*file_paths)
    version_match = re.search(r"^__version__ = ['\"]([^'\"]*)['\"]",
                              version_file, re.M)
    if version_match:
        return version_match.group(1)
    raise RuntimeError("Unable to find version string.")


classifiers = [
    "Development Status :: 4 - Beta",
    "Environment :: X11 Applications :: GTK",
    "Intended Audience :: Healthcare Industry",
    "License :: OSI Approved :: GNU General Public License v2 or later "
    "(GPLv2+) ",
    "Natural Language :: English",
    "Operating System :: OS Independent",
    "Programming Language :: Python :: 3.7"
]

setup(
    name='nut_nutrition',
    version=find_version("nut_nutrition/__init__.py"),
    url="https://github.com/Jacotsu/NUT",
    author="Jim Jozwiak, Raffaele Di Campli",
    author_email="dcdrj.pub@gmail.com",
    license='GPLv2+',
    install_requires=[
        'dataclasses',
        'pytest',
        'matplotlib'
    ],
    python_requires='>=3.7',
    packages=['nut_nutrition'],
    package_data={'': ['GTK_gui.glade']},
    include_package_data=True,
    description="Track your nutrient intake",
    long_description=long_description,
    classifiers=classifiers,
    entry_points={
        'gui_scripts': [
            'nut-gui=nut_nutrition.main:main'
        ]
    }
)
