# coding=UTF-8

import arcpy
import os
import sys
import traceback
import zipfile
import re
import json
import datetime

class LicenseError(Exception):
    pass


def unzip(zipFileName, folder=None):
    try:
        path = os.path.dirname(zipFileName)
        if folder:
            path += '/' + folder
        zip = zipfile.ZipFile(zipFileName, 'r')
        gdb_name = None
        for name in zip.namelist():
            if '.gdb' in name.lower():
                gdb_index = name.lower().index('.gdb') + 4
                gdb_name = name[0:gdb_index]
                break
        if not gdb_name:
            arcpy.AddError('<i18n timestamp="{}">zip_archive_without_gdb</i18n>'.
                           decode('utf-8').format(now(), zipFile))
            # raise Exception('{}: zip file has no gdb'.format(now()))
        zip.extractall(path)
        zip.close()
        if path.endswith('/'):
            return path + gdb_name
        else:
            return path + '/' + gdb_name
    except RuntimeError:
        zip.close()
        arcpy.AddWarning(get_ID_message(86133))


def get_ID_message(ID):
    return re.sub("%1|%2", "%s", arcpy.GetIDMessage(ID))


def now():
    return datetime.datetime.now()

if __name__ == '__main__':
    try:
        zipFile = arcpy.GetParameterAsText(0)
        arcpy.AddMessage('<i18n timestamp="{}" file="{}">file_received_and_unpacking</i18n>'.
                         decode('utf-8').format(now(), os.path.basename(zipFile)))
        # Распаковка
        gdb = unzip(zipFile)
        arcpy.SetParameterAsText(1, gdb)
        gdb = gdb.replace('/', '/')
        temp_gdb = unzip(zipFile, 'tmp')
        os.remove(zipFile)

        arcpy.AddMessage('<i18n timestamp="{}" gdb="{}">gdb_unpacked</i18n>'.
                         decode('utf-8').format(now(), os.path.basename(gdb)))

        arcpy.env.workspace = temp_gdb
        # Получение классов
        data_sets = arcpy.ListDatasets('*', 'Feature')

        res = []
        for ds in data_sets:

            # Перечисление классов
            fcs = arcpy.ListFeatureClasses('*', 'All', ds)
            arcpy.AddMessage('<i18n timestamp="{}" class_set="{}" count="{}">class_set_found</i18n>'.
                             decode('utf-8').format(now(), ds, len(fcs)))

            res_ds = []
            for fc in fcs:

                count = 0
                desc = arcpy.Describe(fc)
                if desc.shapeType == 'Point':
                    count = int(arcpy.GetCount_management(fc).getOutput(0))
                else:
                    with arcpy.da.SearchCursor(fc.encode('utf-8'), ["SHAPE@"]) as cursor:
                        for row in cursor:
                            try:
                                geometry = json.loads(row[0].JSON)
                                geometry_type = row[0].type
                                if geometry_type == 'polygon':
                                    if 'rings' in geometry:
                                        for ring in geometry['rings']:
                                            count += len(ring)
                                    if 'curveRings' in geometry:
                                        for ring in geometry['curveRings']:
                                            count += len(ring)
                                elif geometry_type == 'polyline':
                                    if 'paths' in geometry:
                                        for path in geometry['paths']:
                                            count += len(path)
                                    if 'curvePaths' in geometry:
                                        for path in geometry['curvePaths']:
                                            count += len(path)
                                # elif geometry_type == 'point':
                                #     count += 1
                            except:
                                arcpy.AddWarning('{} class has unknown type object'.format(fc))

                res_ds.append({'fc': fc.encode('utf-8'), 'count': count, 'shapeType': desc.shapeType})

                try:
                    arcpy.Delete_management(fc)
                except:
                    arcpy.AddWarning('<i18n timestamp="{}" class="{}">error_class_removing</i18n>'.
                                     format(now(), fc).decode('utf-8'))

                del fc
                del desc

            desc = arcpy.Describe(str(gdb) + os.sep + ds)
            res.append({
                'class_set': ds.encode('utf-8'),
                'tolerance': desc.spatialReference.XYTolerance,
                'fcs': res_ds
            })

            del desc

            try:
                arcpy.Delete_management(ds)
            except:
                arcpy.AddWarning('<i18n timestamp="{}" class_set="{}"></i18n>'.
                                 format(now(), ds).decode('utf-8'))
            del fcs
            del ds

        if len(res) > 0:
            arcpy.SetParameterAsText(2, json.dumps(res))
        else:
            arcpy.AddWarning('<i18n timestamp="{}">gdb_has_no_class_sets</i18n>'.
                             format(now()).decode('utf-8'))

        del data_sets

        try:
            arcpy.Delete_management(temp_gdb)
            os.removedirs(os.path.dirname(zipFile) + '/' + 'tmp')
        except:
            arcpy.AddWarning('<i18n timestamp="{}" gdb="{}">error_gdb_removing</i18n>'.
                             format(now(), os.path.basename(temp_gdb)).decode('utf-8'))

        del temp_gdb
        del gdb

    except:
        tb = sys.exc_info()[2]
        tbinfo = traceback.format_tb(tb)[0]
        pymsg = "ERRORS:\nTraceback Info:\n" + tbinfo + "\nError Info:\n    " + \
                str(sys.exc_type) + ": " + str(sys.exc_value) + "\n"
        arcpy.AddError(pymsg)
