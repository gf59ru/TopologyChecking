# -- coding: utf-8 --
import arcpy
import os
import sys
import traceback
import re
import json
import math
import numpy as np

class LicenseError(Exception):
    pass


def get_ID_message(ID):
    return re.sub("%1|%2", "%s", arcpy.GetIDMessage(ID))

def create_point(x, y):
    result = arcpy.Point()
    result.X = x
    result.Y = y
    return result


if __name__ == '__main__':
    try:
        a = [[1, 2], [3, 4]]
        b = [[5, 6], [7, 8]]
        arcpy.AddMessage(json.dumps(np.dot(a, b)))
        exit(None, None)
        # Get the Parameters
        gdb = arcpy.GetParameterAsText(0)
        new_gdb_name = arcpy.GetParameterAsText(1)
        reverse = arcpy.GetParameter(2)
        x_offset = arcpy.GetParameter(3)
        y_offset = arcpy.GetParameter(4)

        if reverse:
            x_offset = -x_offset
            y_offset = -y_offset

        if arcpy.Exists(os.path.dirname(gdb) + os.sep + new_gdb_name):
            arcpy.Delete_management(os.path.dirname(gdb) + os.sep + new_gdb_name)

        new_gdb = arcpy.CreateFileGDB_management(os.path.dirname(gdb), new_gdb_name)

        arcpy.env.workspace = gdb
        data_sets = arcpy.ListDatasets('*', 'Feature')
        for ds in data_sets:
            desc = arcpy.Describe(str(gdb) + os.sep + ds)
            sr = desc.spatialReference
            new_ds = arcpy.CreateFeatureDataset_management(new_gdb, ds, sr)
            fcs = arcpy.ListFeatureClasses('*', 'All', os.path.basename(ds))
            for fc in fcs:
                desc = arcpy.Describe(str(gdb) + os.sep + ds + os.sep + fc)
                shape_type = desc.shapeType
                new_fc = arcpy.CreateFeatureclass_management(str(new_gdb) + os.sep + ds, fc, shape_type)
                with arcpy.da.SearchCursor(fc, ["SHAPE@"]) as cursor:
                    for row in cursor:
                        try:
                            geometry = json.loads(row[0].JSON)
                            geometry_type = row[0].type
                            spatial_reference = geometry['spatialReference']
                            if geometry_type == 'polygon':
                                if 'rings' in geometry:
                                    rings = arcpy.Array()
                                    for ring in geometry['rings']:
                                        new_ring = arcpy.Array()
                                        for point in ring:
                                            new_ring.append(create_point(point[0] + x_offset, point[1] + y_offset))
                                        rings.append(new_ring)
                                    with arcpy.da.InsertCursor(new_fc, ['SHAPE@JSON']) as ins_cursor:
                                        ins_cursor.insertRow([arcpy.Polygon(rings, spatial_reference).JSON])
                            elif geometry_type == 'polyline':
                                if 'paths' in geometry:
                                    paths = arcpy.Array()
                                    for path in geometry['paths']:
                                        new_path = arcpy.Array()
                                        for point in path:
                                            new_path.append(create_point(point[0] + x_offset, point[1] + y_offset))
                                        paths.append(new_path)
                                    with arcpy.da.InsertCursor(new_fc, ['SHAPE@JSON']) as ins_cursor:
                                        ins_cursor.insertRow([arcpy.Polyline(paths, spatial_reference).JSON])
                            elif geometry_type == 'point':
                                with arcpy.da.InsertCursor(new_fc, ['SHAPE@JSON']) as ins_cursor:
                                    p = create_point(geometry['x'] + x_offset, geometry['y'] + y_offset)
                                    ins_cursor.insertRow([arcpy.PointGeometry(p, spatial_reference).JSON])
                            else:
                                arcpy.AddMessage(geometry_type)
                        except:
                            arcpy.AddWarning('{} class has unknown type object'.format(fc))


    except:
        tb = sys.exc_info()[2]
        tbinfo = traceback.format_tb(tb)[0]
        pymsg = "ERRORS:\nTraceback Info:\n" + tbinfo + "\nError Info:\n    " + \
                str(sys.exc_type) + ": " + str(sys.exc_value) + "\n"
        arcpy.AddError(pymsg)
