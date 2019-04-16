import gettext

_ = gettext.gettext


def get_selected_food(menu):
    """
    :param menu: Is a GTKTreeView with selected items
    """
    # When you edit the pcf, the gtk treeview should select only
    # the row that you're editing, so this code seems to be rialiable
    selection = menu.get_selection()
    treestore, selected_treepaths = selection.get_selected_rows()
    food = treestore[selected_treepaths[0]]
    return food


def set_float_precision(col, cell, model, iterator, func_data):
    """
    Sets the float precision to 2 decimal digits
    """
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


def set_cells_data_func(builder,
                        views_to_set,
                        function,
                        columns_mapping):
    """
    Sets the column data function, useful for changing the displayed
    precision of floats
    :param function: The rendering function that should be applied to the data
    :param columns_mapping: dictionary that maps the view model to the data
        model, the key is a tuple that contains the column id and the cell id
    """
    for view_name in views_to_set:
        view = builder.get_object(view_name)
        cols = view.get_columns()
        for view_col, data_col in columns_mapping.items():
            cols[view_col[0]].set_cell_data_func(cols[view_col[0]]
                                                 .get_cells()[view_col[1]],
                                                 function,
                                                 {'column_no': data_col})
