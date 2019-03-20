## To Do

### Analysis

- [ ] Suggest food based on distance between ideal value and actual value
    d = \sum{x_{desiderata} (x_{cibo} + x_{pasto})^{\alpha_{n}}}

- [ ] Highlight missing/excess nutrients

- [X] Custom cell renderer for treeviews (Now float precision is properly set)

- [ ] Let user choose analysis period from calendars

- [ ] Fix tree store data columns

### Record meals

- [ ] Set food weight from both side view and view food

- [ ] Allow to set food weight and food volume from the same interface

### Recipe management

- [ ] Allow custom recipe deletion

- [ ] Implement recipe save

### View nutrient story

- [X] Add inlined food search in food story
  - [X] Implement food group filtering as TreeListStoreFilter (Implemented as search widget)

- [X] Let user choose nutrient story period from calendars
  - [ ] Clamp calendar to only valid values

- [X] Plot nutrient data with mathplotlib
  - [X] Fix Mathplotlib canvas drawing

### Personal options

- [ ] Add weight graph

### Internals

- [ ] Parametrize file load in db load query

- [ ] Normalize all query results

- [ ] Replace inline string formatting with format method so that gettext can work properly

- [ ] Increase performance by parallelizing queries

- [ ] Keep all the logic in SQL
  - [ ] Properly parametrize queries
  - [ ] Harden db manager and queries
  - [ ] Fix `database or disk is full` errors

- [ ] Write tests

### Misc

- [ ] Write docs

- [ ] Reimplement toggleable high contrast/color (like old tcl version)

- [ ] Make spacer tab non clickable
