import arcgisscripting
import os
import sys
import traceback

gp = arcgisscripting.create(10.1)

class LicenseError(Exception):
    pass

if __name__ == '__main__':
    try:
        # Get the Parameters
        class_set = gp.getparameter(0)
        object_class = gp.getparameter(1)
        a = '123' + '456'

    except:
        tb = sys.exc_info()[2]
        tbinfo = traceback.format_tb(tb)[0]
        pymsg = "ERRORS:\nTraceback Info:\n" + tbinfo + "\nError Info:\n    " + \
                str(sys.exc_type)+ ": " + str(sys.exc_value) + "\n"
        gp.AddError(pymsg)
