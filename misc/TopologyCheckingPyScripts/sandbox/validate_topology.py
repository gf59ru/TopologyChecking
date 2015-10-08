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
        topology = arcpy.GetParameterAsText(1)
        fcs = arcpy.GetParameterAsText(2)

        arcpy.env.workspace = gdb

        arcpy.ValidateTopology_management(topology)
        arcpy.ExportTopologyErrors_management(topology, fcs, 'topology')

        arcpy.SetParameterAsText(3, 'topology_line')
        arcpy.SetParameterAsText(4, 'topology_poly')
        arcpy.SetParameterAsText(5, 'topology_point')

    except:
        tb = sys.exc_info()[2]
        tbinfo = traceback.format_tb(tb)[0]
        pymsg = "ERRORS:\nTraceback Info:\n" + tbinfo + "\nError Info:\n    " + \
                str(sys.exc_type) + ": " + str(sys.exc_value) + "\n"
        arcpy.AddError(pymsg)
