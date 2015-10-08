import arcpy
import os
import sys
import traceback
import zipfile
import re


class LicenseError(Exception):
    pass


def zipUpFolder(folder, outZipFile):
    # zip the data
    try:
        path = os.path.dirname(folder)
        name, ext = os.path.splitext(filename)
        if not ext:
            ext = '.zip'
        name_ext = path + os.sep + name + ext
        zip = zipfile.ZipFile(name_ext, 'w', zipfile.ZIP_STORED)  # zipfile.ZIP_DEFLATED
        zipws(folder, zip, "CONTENTS_ONLY")
        zip.close()
        return name_ext
    except RuntimeError:
        # Delete zip file if exists
        if os.path.exists(outZipFile):
            os.unlink(outZipFile)
        zip = zipfile.ZipFile(outZipFile, 'w', zipfile.ZIP_STORED)
        zipws(folder, zip, "CONTENTS_ONLY")
        zip.close()
        # Message"  Unable to compress zip file contents."
        arcpy.AddWarning(get_ID_message(86133))


def zipws(path, zip, keep):
    path = os.path.normpath(path)
    # os.walk visits every subdirectory, returning a 3-tuple
    #  of directory name, subdirectories in it, and filenames
    #  in it.
    for (dirpath, dirnames, filenames) in os.walk(path):
        # Iterate over every filename
        for file in filenames:
            # Ignore .lock files
            if not file.endswith('.lock'):
                # arcpy.AddMessage("Adding %s..." % os.path.join(path, dirpath, file))
                try:
                    if keep:
                        zip.write(os.path.join(dirpath, file),
                                  os.path.join(os.path.basename(path),
                                               os.path.join(dirpath, file)[len(path) + len(os.sep):]))
                    else:
                        zip.write(os.path.join(dirpath, file),
                                  os.path.join(dirpath[len(path):], file))

                except Exception as e:
                    # Message "    Error adding %s: %s"
                    arcpy.AddWarning(get_ID_message(86134) % (file, e[0]))
    return None


def get_ID_message(ID):
    return re.sub("%1|%2", "%s", arcpy.GetIDMessage(ID))


if __name__ == '__main__':
    try:
        # Get the Parameters
        gdb = arcpy.GetParameterAsText(0)
        filename = arcpy.GetParameterAsText(1)

        zip_path = zipUpFolder(str(gdb), filename)
        arcpy.SetParameterAsText(2, zip_path)

    except:
        tb = sys.exc_info()[2]
        tbinfo = traceback.format_tb(tb)[0]
        pymsg = "ERRORS:\nTraceback Info:\n" + tbinfo + "\nError Info:\n    " + \
                str(sys.exc_type) + ": " + str(sys.exc_value) + "\n"
        arcpy.AddError(pymsg)
