import arcpy
import sys
import traceback
import re
import json
import datetime

class LicenseError(Exception):
    pass


def get_ID_message(ID):
    return re.sub("%1|%2", "%s", arcpy.GetIDMessage(ID))


def now():
    return datetime.datetime.now()

if __name__ == '__main__':
    try:
        gdb = arcpy.GetParameterAsText(0)

        arcpy.env.workspace = gdb
        # get feature classes
        data_sets = arcpy.ListDatasets('*', 'Feature')

        res = []
        total_count = 0
        for ds in data_sets:

            # feature classes enumeration
            fcs = arcpy.ListFeatureClasses('*', 'All', ds)

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

                total_count += count

                res_ds.append({'fc': fc.encode('utf-8'), 'count': count, 'shapeType': desc.shapeType})

                del fc
                del desc

            res.append({'class_set': ds.encode('utf-8'), 'fcs': res_ds})

            del fcs
            del ds

        if len(res) > 0:
            arcpy.SetParameterAsText(1, json.dumps(res))
        else:
            arcpy.AddWarning('gdb has no class sets')

        del data_sets
        del gdb

        arcpy.AddWarning('total vertices: {}'.format(total_count))

    except:
        tb = sys.exc_info()[2]
        tbinfo = traceback.format_tb(tb)[0]
        pymsg = "ERRORS:\nTraceback Info:\n" + tbinfo + "\nError Info:\n    " + \
                str(sys.exc_type) + ": " + str(sys.exc_value) + "\n"
        arcpy.AddError(pymsg)
