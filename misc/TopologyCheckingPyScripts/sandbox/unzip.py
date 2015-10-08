import arcpy
import os
import sys
import traceback
import zipfile
import re
import logging


class LicenseError(Exception):
    pass


def unzip(zipFileName):
    try:
        path = os.path.dirname(zipFileName)
        zip = zipfile.ZipFile(zipFileName, 'r')
        gdb_name = None
        for name in zip.namelist():
            if '.gdb' in name.lower():
                gdb_name = name
                break
        if not gdb_name:
            raise Exception('zip file has no gdb')
        zip.extractall(path)
        zip.close()
        return path + os.sep + gdb_name
    except RuntimeError:
        zip.close()
        arcpy.AddWarning(get_ID_message(86133))


def get_ID_message(ID):
    return re.sub("%1|%2", "%s", arcpy.GetIDMessage(ID))


if __name__ == '__main__':
    try:
        logger = logging.getLogger('my_logger')
        logger.setLevel(logging.DEBUG)
        logger.handlers = []
        logger.info()

        # Get the Parameters
        zipFileName = arcpy.GetParameterAsText(0)
        # print 'received file: ' + zipFile
        arcpy.AddMessage('received file: %s' % (zipFileName))
        arcpy.AddWarning('file is corrupted')
        arcpy.AddError('A-A-A-A!!! SERVER IS DOWN!!!!')
        # gdb_name = unzip(zipFile)
        # arcpy.SetParameterAsText(1, gdb_name.replace('/', os.sep))
        arcpy.SetParameterAsText(1, zipFileName)

    except:
        tb = sys.exc_info()[2]
        tbinfo = traceback.format_tb(tb)[0]
        pymsg = "ERRORS:\nTraceback Info:\n" + tbinfo + "\nError Info:\n    " + \
                str(sys.exc_type) + ": " + str(sys.exc_value) + "\n"
        arcpy.AddError(pymsg)
