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
        class_set = arcpy.GetParameter(1)
        topology_name = arcpy.GetParameterAsText(2)

        arcpy.env.workspace = gdb
        if class_set:
            topology = arcpy.CreateTopology_management(class_set, topology_name)
            arcpy.SetParameterAsText(3, str(topology))

    except:
        tb = sys.exc_info()[2]
        tbinfo = traceback.format_tb(tb)[0]
        pymsg = "ERRORS:\nTraceback Info:\n" + tbinfo + "\nError Info:\n    " + \
                str(sys.exc_type) + ": " + str(sys.exc_value) + "\n"
        arcpy.AddError(pymsg)
