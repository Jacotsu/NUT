import gettext
import zipfile
import requests
import glob
import os

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


def hide_text_if_true(col, cell, model, iterator, func_data):
    """
    Hides the DV if the row is food
    """
    data = model.get(iterator, func_data['column_no'])[0]

    if data:
        cell.set_property('text', '')


def hide_if_no_data_and_its_a_group(col, cell, model, iterator, func_data):
    """
    Hides the text if it's a nutrient group and has no data associated
    """
    data = model.get(iterator, func_data['column_no'])[0]
    if not data and model.iter_has_child(iterator):
        cell.set_property('text', '')


def hide_text_if_no_data(col, cell, model, iterator, func_data):
    """
    Hides the text if no data is present
    """
    data = model.get(iterator, func_data['column_no'])[0]

    if not data:
        cell.set_property('text', '')
    else:
        cell.set_property('text', '%')


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
        {(0, 1): 5} Selects the first column (0) and the second cell renderer
        (1) and passes the model sixth (5) column to the specified function
    """
    for view_name in views_to_set:
        view = builder.get_object(view_name)
        cols = view.get_columns()
        for view_col, data_col in columns_mapping.items():
            cols[view_col[0]].set_cell_data_func(cols[view_col[0]]
                                                 .get_cells()[view_col[1]],
                                                 function,
                                                 {'column_no': data_col})


def set_calendar_date(date, calendar):
    day = int(date[-2])
    month = int(date[-4:-2])
    year = int(date[0:-4])
    calendar.select_day(day)
    calendar.select_month(month, year)


def chain_functions(functions):
    """
    Returns a function that calls a list of functions called with the same
    parameters
    :param functions: A list of functions to call with compatible parameters
    :returns: the resulting function
    """
    def res(*args, **kwargs):
        for funct in functions:
            funct(*args, **kwargs)
    return res


def download_usda_and_unzip(dest_path):
    os.makedirs(dest_path, exist_ok=True)
    zip_path = os.path.join(dest_path, 'sr28asc.zip')

    r = requests.get('https://www.ars.usda.gov/ARSUserFiles/80400525/Data/SR/'
                     'SR28/dnload/sr28asc.zip', stream=True)
    if r.status_code == 200:
        with open(zip_path, 'wb') as f:
            for chunk in r:
                f.write(chunk)

    zip_ref = zipfile.ZipFile(zip_path, 'r')
    zip_ref.extractall(dest_path)
    zip_ref.close()


def cleanup_usda(path):
    globs = ['*.txt', '*.zip', '*.pdf']
    for gl in globs:
        for hgx in glob.glob(os.path.join(path, gl)):
            os.remove(hgx)
