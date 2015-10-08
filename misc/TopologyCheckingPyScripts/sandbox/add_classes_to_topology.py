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
        gdb = arcpy.GetParameter(0)
        topology = arcpy.GetParameter(1)
        fcs = arcpy.GetParameter(2)

        arcpy.env.workspace = str(gdb)
        for fc in fcs:
            arcpy.AddFeatureClassToTopology_management(topology, fc)

        arcpy.SetParameter(3, topology)

    except:
        tb = sys.exc_info()[2]
        tbinfo = traceback.format_tb(tb)[0]
        pymsg = "ERRORS:\nTraceback Info:\n" + tbinfo + "\nError Info:\n    " + \
                str(sys.exc_type) + ": " + str(sys.exc_value) + "\n"
        arcpy.AddError(pymsg)
