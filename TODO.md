## To Do

### Analysis

- [ ] Suggest food based on distance between ideal value and actual value
    d = \sum{x_{desiderata} (x_{cibo} + x_{pasto})^{\alpha_{n}}}

- [ ] Highlight missing/excess nutrients

- [ ] Custom cell renderer for treeviews

- [ ] Let user choose analysis period from calendars

- [ ] Fix tree store data columns

### Record meals

- [ ] Set food weight from both side view and view food

- [ ] Allow to set food weight and food volume from the same interface

### Recipe management

- [ ] Allow custom recipe deletion

### View nutrient story

- [ ] Plot nutrient data with mathplotlib
  - [ ] Fix Mathplotlib canvas drawing

- [ ] Add inlined food filter in food story

- [ ] Let user choose analysis period from story section

### Personal options

- [ ] Add weight graph

### Internals

- [ ] Parametrize file load in db load query

- [ ] Replace inline string formatting with format method so that gettext can work properly

- [ ] Keep all the logic in SQL

- [ ] Write tests

### Misc

- [ ] Write docs

- [ ] Reimplement toggleable high contrast/color (like old tcl version)

- [ ] Make spacer tab non clickable
