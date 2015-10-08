import arcpy
import sys
import traceback
import re


class LicenseError(Exception):
    pass


def get_ID_message(ID):
    return re.sub("%1|%2", "%s", arcpy.GetIDMessage(ID))


def add_class_to_topology(topo, fc):
    try:
        arcpy.AddFeatureClassToTopology_management(topo, fc)
        arcpy.AddMessage('Добавлен класс {}'.format(fc).decode('utf-8'))
    except:
        arcpy.AddMessage('Класс {} уже участвует в топологии'.format(fc).decode('utf-8'))


if __name__ == '__main__':
    try:
        # Get the Parameters
        gdb = arcpy.GetParameterAsText(0)
        topology = arcpy.GetParameterAsText(1)
        fc1 = arcpy.GetParameterAsText(2)
        fc2 = arcpy.GetParameterAsText(3)
        rule = arcpy.GetParameterAsText(4)


        arcpy.AddMessage('Используется база {} c топологией {}'.format(gdb, topology).decode('utf-8'))
        if fc2 == '#':
            arcpy.AddMessage('Добавляется правило {} для класса {}'.format(rule, fc1).decode('utf-8'))
        else:
            arcpy.AddMessage('Добавляется правило {} для классов {} и {}'.format(rule, fc1, fc2).decode('utf-8'))

        arcpy.env.workspace = gdb

        add_class_to_topology(topology, fc1)

        if fc2 == '#':
            try:
                arcpy.AddRuleToTopology_management(topology, rule, fc1)
                arcpy.AddMessage('Добавлено правило {} для одного класса'.format(rule).decode('utf-8'))
            except:
                arcpy.AddError('Ошибка при добавлении правила с классом {} в топологию: {}'.format(fc1, traceback.format_exc()).decode('utf-8'))

        else:
            add_class_to_topology(topology, fc2)

            try:
                arcpy.AddRuleToTopology_management(topology, rule, fc1, None, fc2)
                arcpy.AddMessage('Добавлено правило {} для двух классов'.format(rule).decode('utf-8'))
            except:
                arcpy.AddError('Ошибка при добавлении правила с классами {} и {} в топологию: {}'.format(fc1, fc2, traceback.format_exc()).decode('utf-8'))


        arcpy.SetParameterAsText(5, str(topology))

    except:
        tb = sys.exc_info()[2]
        tbinfo = traceback.format_tb(tb)[0]
        pymsg = "ERRORS:\nTraceback Info:\n" + tbinfo + "\nError Info:\n    " + \
                str(sys.exc_type) + ": " + str(sys.exc_value) + "\n"
        arcpy.AddError(pymsg)
