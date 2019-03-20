import gettext

_ = gettext.gettext


def set_float_precision(col, cell, model, iterator, func_data):
    data = model.get(iterator, func_data['column_no'])[0]
    if data:
        cell.set_property('text', '{:5.2f}'.format(data))
    else:
        cell.set_property('text', _('[No Data]'))


def set_pcf_combobox_text(col, cell, model, iterator, func_data):
    data = model.get(iterator, func_data['column_no'])[0]
    nutrient_list = cell.props.model
    # Probably there's a more efficient search method other than
    # iterate through the list
    for row in nutrient_list:
        if row[0] == data:
            cell.set_property('text', row[1])


def set_pcf_combobox_cells_data_func(builder, views_to_set):
    """
    Sets the column data function, useful for changing the displayed
    precision of floats
    """
    for view_name in views_to_set:
        view = builder.get_object(view_name)
        cols = view.get_columns()
        cols[0].set_cell_data_func(cols[0].get_cells()[1],
                                   set_pcf_combobox_text,
                                   {'column_no': 3})


def set_cells_data_func(builder, views_to_set):
    """
    Sets the column data function, useful for changing the displayed
    precision of floats
    """
    for view_name in views_to_set:
        view = builder.get_object(view_name)
        cols = view.get_columns()
        cols[1].set_cell_data_func(cols[1].get_cells()[0],
                                   set_float_precision,
                                   {'column_no': 6})
        cols[2].set_cell_data_func(cols[2].get_cells()[0],
                                   set_float_precision,
                                   {'column_no': 4})
