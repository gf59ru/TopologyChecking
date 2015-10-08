# -- coding: utf-8 --
import arcpy
import os
import sys
import traceback
import re


class LicenseError(Exception):
    pass


def get_ID_message(ID):
    return re.sub("%1|%2", "%s", arcpy.GetIDMessage(ID))


if __name__ == '__main__':
    try:
        # Get the Parameters
        gdb = arcpy.GetParameterAsText(0)

        arcpy.env.workspace = gdb
        data_sets = arcpy.ListDatasets('*', 'Feature')
        result = None
        for ds in data_sets:
            fcs = arcpy.ListFeatureClasses('*', 'All', os.path.basename(ds))
            for fc in fcs:
                count = 0
                cursor = arcpy.SearchCursor(fc)
                row = cursor.next()
                for row in cursor:
                    count += 1
                desc = arcpy.Describe(fc)
                if result:
                    result += ','
                else:
                    result = '['
                result += '{"fc": "' + fc + '","count": ' + str(count) + ',"shapeType": "' + desc.shapeType + '"}'

        if result:
            result += ']'
            arcpy.SetParameter(1, result)

    except:
        tb = sys.exc_info()[2]
        tbinfo = traceback.format_tb(tb)[0]
        pymsg = "ERRORS:\nTraceback Info:\n" + tbinfo + "\nError Info:\n    " + \
                str(sys.exc_type) + ": " + str(sys.exc_value) + "\n"
        arcpy.AddError(pymsg)
