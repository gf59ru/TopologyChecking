import arcpy
import os
import sys
import traceback
import re
import json
import datetime

class LicenseError(Exception):
    pass


def get_ID_message(ID):
    return re.sub("%1|%2", "%s", arcpy.GetIDMessage(ID))


if __name__ == '__main__':
    try:
        # get parameters
        gdb = arcpy.GetParameterAsText(0)
        new_gdb_name = arcpy.GetParameterAsText(1)
        params_file = arcpy.GetParameterAsText(2)

        arcpy.env.workspace = gdb
        data_sets = arcpy.ListDatasets('*', 'Feature')

        f = open(params_file, 'r')
        s = f.read()
        transform_data = json.loads(s)
        f.close()
        new_gdb = arcpy.CreateFileGDB_management(os.path.dirname(gdb), new_gdb_name)

        arcpy.AddMessage('{}: Transformation started'.format(datetime.datetime.now()))

        for ds in data_sets:
            arcpy.AddMessage('{}: ds {} begin transforming'.format(datetime.datetime.now(),
                                                                   unicode(ds).encode('utf-8')))

            desc = arcpy.Describe(str(gdb) + os.sep + ds)
            sr = desc.spatialReference
            new_sr = None
            temp_ds = None
            arcpy.AddMessage('{}: ds {} has {} coordinate system'.format(datetime.datetime.now(),
                                                                         unicode(ds).encode('utf-8'), sr.type))
            temp_sr = arcpy.SpatialReference()
            temp_sr.loadFromString(transform_data[ds]['new_cs'])
            arcpy.DefineProjection_management(str(gdb) + os.sep + ds, temp_sr)
            new_sr = transform_data[ds]['cs']
            if temp_ds:
                arcpy.Project_management(temp_ds, str(new_gdb) + os.sep + ds, new_sr)
                arcpy.Delete_management(temp_ds)
            else:
                arcpy.Project_management(ds, str(new_gdb) + os.sep + ds, new_sr)
            arcpy.AddMessage('{}: ds {} transformed'.format(datetime.datetime.now(),
                                                            unicode(ds).encode('utf-8')))

    except:
        tb = sys.exc_info()[2]
        tbinfo = traceback.format_tb(tb)[0]
        pymsg = "ERRORS:\nTraceback Info:\n" + tbinfo + "\nError Info:\n    " + \
                str(sys.exc_type) + ": " + str(sys.exc_value) + "\n"
        arcpy.AddError(pymsg)
