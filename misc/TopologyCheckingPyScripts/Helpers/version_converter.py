import arcpy
import sys
import traceback
import os

if __name__ == '__main__':
    try:
        mxd = arcpy.GetParameterAsText(0)
        folder = arcpy.GetParameterAsText(1)
        version = arcpy.GetParameterAsText(2)
        new_name = folder.encode('utf-8') + os.sep + (os.path.basename(mxd)).encode('utf-8')
        mxd = arcpy.mapping.MapDocument(mxd)
        mxd.saveACopy(new_name, version)

    except:
        tb = sys.exc_info()[2]
        tbinfo = traceback.format_tb(tb)[0]
        pymsg = "ERRORS:\nTraceback Info:\n" + tbinfo + "\nError Info:\n    " + \
                str(sys.exc_type) + ": " + str(sys.exc_value) + "\n"
        arcpy.AddError(pymsg)
