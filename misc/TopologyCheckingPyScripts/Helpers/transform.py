# -- coding: utf-8 --
import arcpy
import os
import sys
import traceback
import re
import json
import datetime
import random


class LicenseError(Exception):
    pass


def get_ID_message(ID):
    return re.sub("%1|%2", "%s", arcpy.GetIDMessage(ID))


# def affine(x, y, matrix):
#     ax = x * matrix[0][0] + y * matrix[0][1] + matrix[0][2]
#     ay = x * matrix[1][0] + y * matrix[1][1] + matrix[1][2]
#     return [ax, ay]
#
#
# def create_point(x, y):
#     result = arcpy.Point()
#     transformed = np.dot(transform_matrix, [x, y, 1.0])
#     # transformed = affine(x, y, transform_matrix)
#     result.X = transformed[0]
#     result.Y = transformed[1]
#     return result
#
#
# def print_matrix(name, matrix):
#     arcpy.AddMessage('Matrix {}:'.format(name))
#     arcpy.AddMessage('[[ {}; {}; {} ];'.format(matrix[0][0], matrix[0][1], matrix[0][2]))
#     arcpy.AddMessage('[ {}; {}; {} ];'.format(matrix[1][0], matrix[1][1], matrix[1][2]))
#     arcpy.AddMessage('[ {}; {}; {} ]]'.format(matrix[2][0], matrix[2][1], matrix[2][2]))


def gcs_link_string(gcs):
    strings = re.findall('GEOGCS\[[\w\'.,\[\]]*\];', gcs.exportToString())
    if len(strings) == 1:
        return strings[0]
    else:
        return None


def create_pcs(project_name, cs_string,
               false_easting, false_northing, central_meridian, scale_factor, latitude_of_origin):
    # GEOGCS[
    #   'GCS_WGS_1984',
    #   DATUM[
    #       'D_WGS_1984',
    #       SPHEROID[
    #           'WGS_1984',
    #           6378137.0,
    #           298.257223563
    #       ]
    #   ],
    #   PRIMEM[
    #       'Greenwich',
    #       0.0
    #   ],
    #   UNIT[
    #       'Degree',
    #       0.0174532925199433
    #   ]
    # ];
    # -400 -400 1000000000;
    # -100000 10000;
    # -100000 10000;
    # 8,98315284119522E-09;
    # 0,001;
    # 0,001;
    # IsHighPrecision

    # PROJCS['PROJECTED_GCS_WGS_1984_2015117115644',GEOGCS['GCS_WGS_1984',DATUM['D_WGS_1984',SPHEROID['WGS_1984',6378137.0,298.257223563]],PRIMEM['Greenwich',0.0],UNIT['Degree',0.0174532925199433]],PROJECTION['Transverse_Mercator'],PARAMETER['False_Easting',178203.0],PARAMETER['False_Northing',-460018.0],PARAMETER['Central_Meridian',216.662064074],PARAMETER['Scale_Factor',5.43451057438],PARAMETER['Latitude_Of_Origin',117.431203124],UNIT['Meter',1.0]];
    # -30380300 -125810300 10000;
    # -100000 10000;
    # -100000 10000;
    # 0,001;
    # 0,001;
    # 0,001;
    # IsHighPrecision
    pcs_string = 'PROJCS[\'{}\',{},\
PROJECTION[\'Mercator_Auxiliary_Sphere\'],\
PARAMETER[\'False_Easting\',{}],\
PARAMETER[\'False_Northing\',{}],\
PARAMETER[\'Standard_Parallel_1\',60,0],\
PARAMETER[\'Auxiliary_Sphere_Type\',0,0],\
PARAMETER[\'Central_Meridian\',{}],\
PARAMETER[\'Scale_Factor\',{}],\
PARAMETER[\'Latitude_Of_Origin\',{}],\
UNIT[\'Meter\',1.0]]' \
        .format(project_name,
                cs_string,
                false_easting,
                false_northing,
                central_meridian,
                scale_factor,
                latitude_of_origin)
    result = arcpy.SpatialReference()
    result.loadFromString(pcs_string)
    return result


def time_stamp():
    return '_{:%Y%m%d_%H%M%S}'.format(datetime.datetime.now())


def check_float_parameter(param_value, default_value):
    if param_value == '':
        return default_value
    else:
        return float(param_value)


if __name__ == '__main__':
    try:
        # get parameters
        gdb = arcpy.GetParameterAsText(0)
        new_gdb_name = arcpy.GetParameterAsText(1)
        params_file = arcpy.GetParameterAsText(2)

        min_scale_factor = check_float_parameter(arcpy.GetParameterAsText(3), 0.1)
        max_scale_factor = check_float_parameter(arcpy.GetParameterAsText(4), 1.5)

        min_parallel_offset = check_float_parameter(arcpy.GetParameterAsText(5), 1.0)
        max_parallel_offset = check_float_parameter(arcpy.GetParameterAsText(6), 5.0)

        min_meridian_offset = check_float_parameter(arcpy.GetParameterAsText(7), 5.0)
        max_meridian_offset = check_float_parameter(arcpy.GetParameterAsText(8), 20.0)

        min_easting_northing = check_float_parameter(arcpy.GetParameterAsText(9), 10000.0)
        max_easting_northing = check_float_parameter(arcpy.GetParameterAsText(10), 500000.0)

        # transformation parameters
        # x_offset = float(arcpy.GetParameter(3))
        # y_offset = float(arcpy.GetParameter(4))
        # angle = float(arcpy.GetParameter(5))
        # x_scale = float(arcpy.GetParameter(6))
        # y_scale = float(arcpy.GetParameter(7))

        # matrices
        # rotation_matrix = [[math.cos(angle), math.sin(angle), 0.0],
        #                    [-math.sin(angle), math.cos(angle), 0.0],
        #                    [0.0, 0.0, 1.0]]
        # scale_matrix = [[x_scale, 0.0, 0.0],
        #                 [0.0, y_scale, 0.0],
        #                 [0.0, 0.0, 1.0]]
        # moving_matrix = [[1.0, 0.0, x_offset],
        #                  [0.0, 1.0, y_offset],
        #                  [0.0, 0.0, 1.0]]
        #
        # print_matrix('rotation', rotation_matrix)
        # print_matrix('scale', scale_matrix)
        # print_matrix('moving', moving_matrix)
        #
        # transform_matrix = np.dot(rotation_matrix, scale_matrix)
        # print_matrix('rotation * scale', transform_matrix)
        # transform_matrix = np.dot(transform_matrix, moving_matrix)
        # print_matrix('rotation * scale * moving', transform_matrix)
        # if reverse:
        #     transform_matrix = la.inv(transform_matrix)
        #     print_matrix('inverted', transform_matrix)

        arcpy.env.workspace = gdb
        data_sets = arcpy.ListDatasets('*', 'Feature')

        ds_extents = {}
        transform_data = {}
        for ds in data_sets:
            fcs = arcpy.ListFeatureClasses('*', 'All', os.path.basename(ds))

            max_x = None
            max_y = None
            min_x = None
            min_y = None

            for fc in fcs:
                desc = arcpy.Describe(str(gdb) + os.sep + ds + os.sep + fc)
                extent = desc.extent
                if max_x is None or max_x <= extent.XMax:
                    max_x = extent.XMax
                if max_y is None or max_y <= extent.YMax:
                    max_y = extent.YMax
                if min_x is None or min_x >= extent.XMin:
                    min_x = extent.XMin
                if min_y is None or min_y >= extent.YMin:
                    min_y = extent.YMin

            ds_extents[ds.encode('utf-8')] = {
                'max_x': max_x,
                'max_y': max_y,
                'min_x': min_x,
                'min_y': min_y
            }

        # arcpy.AddMessage(json.dumps(ds_extents))

        # exit(None)

        # if arcpy.Exists(os.path.dirname(gdb) + os.sep + new_gdb_name):
        #     arcpy.Delete_management(os.path.dirname(gdb) + os.sep + new_gdb_name)

        new_gdb = arcpy.CreateFileGDB_management(os.path.dirname(gdb), new_gdb_name)
        unknown_gcs_feature_dataset = arcpy.CreateFeatureDataset_management(new_gdb, 'unknown_gcs_feature_dataset')
        unknown_gsc_desc = arcpy.Describe(unknown_gcs_feature_dataset)
        unknown_sr = unknown_gsc_desc.spatialReference
        arcpy.Delete_management(unknown_gcs_feature_dataset)

        # objects = 0
        # vertices = 0

        arcpy.AddMessage('{}: Transformation started'.format(datetime.datetime.now()))

        for ds in data_sets:
            arcpy.AddMessage('{}: ds {} begin transforming'.format(datetime.datetime.now(),
                                                                   unicode(ds).encode('utf-8')))
            extent = ds_extents[ds.encode('utf-8')]
            max_x = extent['max_x']
            max_y = extent['max_y']
            min_x = extent['min_x']
            min_y = extent['min_y']

            desc = arcpy.Describe(str(gdb) + os.sep + ds)
            sr = desc.spatialReference
            # domain = sr.domain.replace(',', '.').split(' ')
            # domain_min_x = (float(domain[0]) - float(domain[2])) / 2
            # domain_max_x = -domain_min_x
            # domain_min_y = (float(domain[1]) - float(domain[3])) / 2
            # domain_max_y = -domain_min_y
            # sr.setDomain(domain_min_x, domain_max_x, domain_min_y, domain_max_y)

            # new_ds = arcpy.CreateFeatureDataset_management(new_gdb, ds, sr)
            # arcpy.DefineProjection_management(str(new_gdb) + os.sep + ds, unknown_sr)

            # resolution_ratio = new_sr.XYResolution / sr.XYResolution
            # GEOGCS\[[\w'.,\[\]]*\];
            new_sr = None
            temp_ds = None
            temp_gdb = None
            arcpy.AddMessage('{}: ds {} has {} coordinate system'.format(datetime.datetime.now(),
                                                                         unicode(ds).encode('utf-8'), sr.type))
            sr_string = sr.exportToString()
            if sr.type == u'Geographic':
                gcs_string = gcs_link_string(sr)  # find GCS description
                sr_name = 'PROJECTED_' + sr.name + time_stamp()
                average_x = (max_x + min_x) / 2
                average_y = (max_y + min_y) / 2
                false_e = random.randint(-max_easting_northing, max_easting_northing)
                false_n = random.randint(-max_easting_northing, max_easting_northing)
                cm = 0  # random.uniform(average_x - max_meridian_offset, average_x + max_meridian_offset)
                lo = 0  # random.uniform(average_y - max_parallel_offset, average_y + max_parallel_offset)
                sf = random.uniform(min_scale_factor, max_scale_factor)
                new_sr = create_pcs(sr_name, gcs_string[:-1], false_e, false_n, cm, sf, lo)
                # ratio = new_sr.XYResolution / sr.XYResolution
                # domain = new_sr.domain.replace(',', '.').split(' ')
                # new_sr.setDomain(float(domain[0]) / ratio,
                #                  float(domain[1]) / ratio,
                #                  float(domain[2]) / ratio,
                #                  float(domain[3]) / ratio)
                # parameters = new_sr.exportToString().split(';')
                # power = int(math.log10(sr.XYResolution))
                # if power < 0:
                #     mask = '{:.' + str(-power) + 'f}'
                #     parameters[4] = mask.format(sr.XYResolution).replace('.', ',')
                #     new_sr.loadFromString(';'.join(parameters))
                transform_data[ds.encode('utf-8')] = {
                    'cs': sr_string,
                    'new_cs': new_sr.exportToString()
                }
            elif sr.type == u'Projected':
                new_sr = sr


                def change_parameter(_sr, parameter, value):
                    pattern = 'PARAMETER\[\'{}\'\,.+?]'.format(parameter)
                    value = 'PARAMETER[\'{}\',{}]'.format(parameter, value)
                    _sr.loadFromString(re.sub(pattern, value, _sr.exportToString()))


                false_e = random.randint(sr.falseEasting - max_easting_northing,
                                         sr.falseEasting + max_easting_northing)
                false_n = random.randint(sr.falseNorthing - max_easting_northing,
                                         sr.falseNorthing + max_easting_northing)
                cm = random.uniform(sr.centralMeridian - max_meridian_offset,
                                    sr.centralMeridian + max_meridian_offset)
                lo = random.uniform(sr.centralParallel - max_parallel_offset,
                                    sr.centralParallel + max_parallel_offset)
                sf = random.uniform(min_scale_factor, max_scale_factor)

                change_parameter(new_sr, 'False_Easting', false_e)
                change_parameter(new_sr, 'False_Northing', false_n)
                change_parameter(new_sr, 'Central_Meridian', cm)
                change_parameter(new_sr, 'Scale_Factor', sf)
                change_parameter(new_sr, 'Latitude_Of_Origin', lo)

                new_sr.loadFromString(re.sub('PROJCS\[\'.+?\'',
                                             'PROJCS[\'ALTERED_PROJECT{}\''.format(time_stamp()),
                                             new_sr.exportToString()))
                transform_data[ds.encode('utf-8')] = {
                    'cs': sr_string,
                    'new_cs': new_sr.exportToString()
                }

            elif sr.type == u'Unknown':
                temp_gdb = arcpy.CreateFileGDB_management(os.path.dirname(gdb), new_gdb_name + time_stamp())
                temp_ds = str(temp_gdb) + os.sep + ds + time_stamp()
                arcpy.Copy_management(str(gdb) + os.sep + ds, temp_ds)

                in_degrees = max_x <= 180 and min_x >= -180 and max_y <= 180 and min_y >= -180
                wgs = arcpy.SpatialReference(4326)
                gcs_string = gcs_link_string(wgs)
                if in_degrees:
                    temp_sr = wgs
                    arcpy.DefineProjection_management(temp_ds, temp_sr)
                    cm = 0
                    lo = 0
                    sr_name = 'FROM_UNKNOWN'

                else:
                    sr_name = re.findall('{.*}', sr.exportToString())
                    if len(sr_name) > 0:
                        sr_name = sr_name[0][1:-1].replace('-', '_')
                    else:
                        sr_name = 'FROM_UNKNOWN'
                    if (max_x - min_x) > 0:
                        false_e = random.randint(-max_easting_northing, -min_easting_northing)
                    else:
                        false_e = random.randint(min_easting_northing, max_easting_northing)
                    if (max_y - min_y) > 0:
                        false_n = random.randint(-max_easting_northing, -min_easting_northing)
                    else:
                        false_n = random.randint(min_easting_northing, max_easting_northing)

                    temp_sr = create_pcs(sr_name, gcs_string[:-1], false_e, false_n, 0, 1, 0)
                    arcpy.DefineProjection_management(temp_ds, temp_sr)
                    cm = random.randint(-max_meridian_offset, max_meridian_offset)
                    lo = random.randint(-max_parallel_offset, max_parallel_offset)

                sr_name = 'PROJECTED_' + sr_name
                false_e = random.randint(-max_easting_northing, max_easting_northing)
                false_n = random.randint(-max_easting_northing, max_easting_northing)
                sf = random.uniform(min_scale_factor, max_scale_factor)
                new_sr = create_pcs(sr_name, gcs_string[:-1], false_e, false_n, cm, sf, lo)

                transform_data[ds.encode('utf-8')] = {
                    'cs': temp_sr.exportToString(),
                    'new_cs': new_sr.exportToString()
                }

            # if not new_sr:
            #     new_sr = sr
            if new_sr:
                # new_ds = arcpy.CreateFeatureDataset_management(new_gdb, ds, new_sr)
                if temp_ds:
                    arcpy.Project_management(temp_ds, str(new_gdb) + os.sep + ds, new_sr)
                    arcpy.Delete_management(temp_ds)
                else:
                    arcpy.Project_management(ds, str(new_gdb) + os.sep + ds, new_sr)
                # arcpy.DefineProjection_management(str(new_gdb) + os.sep + ds,
                #                                   arcpy.CreateSpatialReference_management())
                arcpy.AddMessage('{}: ds {} transformed'.format(datetime.datetime.now(),
                                                                unicode(ds).encode('utf-8')))
                arcpy.DefineProjection_management(str(new_gdb) + os.sep + ds, unknown_sr)
                fcs = arcpy.ListFeatureClasses('*', 'All', ds)
                for fc in fcs:
                    fields = arcpy.ListFields(fc)
                    for field in fields:
                        if field.name.upper() not in ['OBJECTID', 'SHAPE', 'SHAPE_LENGTH', 'SHAPE_AREA']:
                            try:
                                fc_utf8 = str(new_gdb) + os.sep + ds.encode('utf-8') + os.sep + fc.encode('utf-8')
                                arcpy.DeleteField_management(fc_utf8, [field.name.encode('utf-8')])
                                arcpy.AddMessage('{} field deleted'.format(field.name.encode('utf-8')))
                            except:
                                arcpy.AddMessage('Can not delete {} field'.format(field.name.encode('utf-8')))
            else:
                arcpy.AddMessage('{}: !ds {} not transformed!'.format(datetime.datetime.now(),
                                                                      unicode(ds).encode('utf-8')))
            if temp_gdb:
                try:
                    arcpy.Delete_management(temp_gdb)
                except:
                    arcpy.AddWarning('Can not delete temporary geodatabase {}'.format(temp_gdb.encode('utf-8')))

        try:
            f = open(params_file + os.sep + os.path.basename(gdb) + '.json', 'w')
            f.write(json.dumps(transform_data))
            f.close()
            arcpy.AddMessage('Transformation data saved to file {}'.format(params_file))
        except:
            arcpy.AddWarning('Can not save transformation data to file {}'.format(params_file))

        # width = max_y - min_y  # data extent width
        # height = max_x - min_x  # data extent length
        #
        # new_max_x = width / 2
        # new_max_y = height / 2
        #
        # x_offset = new_max_x - max_x
        # y_offset = new_max_y - max_y
        # offset_matrix = [[1, 0, 0], [0, 1, 0], [x_offset, y_offset, 1]]

        # if sr.exportToString() == sr.GCS.exportToString():
        #     arcpy.AddMessage('geographic')
        #     new_sr = arcpy.CreateSpatialReference_management()

        # x_ratio = (domain_max_x - domain_min_x) / width
        # y_ratio = (domain_max_y - domain_min_y) / height
        # max_ratio = max(x_ratio, y_ratio)

        # fcs = arcpy.ListFeatureClasses('*', 'All', os.path.basename(ds))
        # for fc in fcs:
        #     desc = arcpy.Describe(str(gdb) + os.sep + ds + os.sep + fc)
        #     shape_type = desc.shapeType
        #     new_fc = arcpy.CreateFeatureclass_management(str(new_gdb) + os.sep + ds, fc, shape_type)
        #     with arcpy.da.SearchCursor(fc, ["SHAPE@"]) as cursor:
        #         for row in cursor:
        #             try:
        #                 geometry = json.loads(row[0].JSON)
        #                 geometry_type = row[0].type
        #                 spatial_reference = geometry['spatialReference']
        #                 if geometry_type == 'polygon':
        #                     if 'rings' in geometry:
        #                         rings = arcpy.Array()
        #                         for ring in geometry['rings']:
        #                             new_ring = arcpy.Array()
        #                             for point in ring:
        #                                 new_ring.append(create_point(point[0], point[1]))
        #                             # vertices += len(ring)
        #                             rings.append(new_ring)
        #                         with arcpy.da.InsertCursor(new_fc, ['SHAPE@JSON']) as ins_cursor:
        #                             ins_cursor.insertRow([arcpy.Polygon(rings, spatial_reference).JSON])
        #                 elif geometry_type == 'polyline':
        #                     if 'paths' in geometry:
        #                         paths = arcpy.Array()
        #                         for path in geometry['paths']:
        #                             new_path = arcpy.Array()
        #                             for point in path:
        #                                 new_path.append(create_point(point[0], point[1]))
        #                             # vertices += len(path)
        #                             paths.append(new_path)
        #                         with arcpy.da.InsertCursor(new_fc, ['SHAPE@JSON']) as ins_cursor:
        #                             ins_cursor.insertRow([arcpy.Polyline(paths, spatial_reference).JSON])
        #                 elif geometry_type == 'point':
        #                     with arcpy.da.InsertCursor(new_fc, ['SHAPE@JSON']) as ins_cursor:
        #                         p = create_point(geometry['x'], geometry['y'])
        #                         ins_cursor.insertRow([arcpy.PointGeometry(p, spatial_reference).JSON])
        #                     # vertices += 1
        #                 else:
        #                     arcpy.AddMessage(geometry_type)
        #                 # objects += 1
        #                 # if objects % 1000 == 0:
        #                 #     arcpy.AddMessage('{}: {} objects with {} vertices'.format(datetime.datetime.now(),
        #                 #                                                               objects,
        #                 #                                                               vertices))
        #             except:
        #                 arcpy.AddWarning('Possible {} class has unknown type object'.encode('utf-8').format(fc))
        #                 tb = sys.exc_info()[2]
        #                 tbinfo = traceback.format_tb(tb)[0]
        #                 pymsg = "ERRORS:\nTraceback Info:\n" + tbinfo + "\nError Info:\n    " + \
        #                         str(sys.exc_type) + ": " + str(sys.exc_value) + "\n"
        #                 arcpy.AddWarning(pymsg)
        # arcpy.AddMessage('{}: Done, {} objects with {} vertices'.format(datetime.datetime.now(),
        #                                                           objects,
        #                                                           vertices))

    except:
        tb = sys.exc_info()[2]
        tbinfo = traceback.format_tb(tb)[0]
        pymsg = "ERRORS:\nTraceback Info:\n" + tbinfo + "\nError Info:\n    " + \
                str(sys.exc_type) + ": " + str(sys.exc_value) + "\n"
        arcpy.AddError(pymsg)
