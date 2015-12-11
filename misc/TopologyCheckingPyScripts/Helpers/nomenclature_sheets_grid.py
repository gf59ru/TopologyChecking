# coding=UTF-8
import arcpy
import sys
import traceback
import os
import math

# Стандартные масштабы
SCALE_1_000_000 = 1000000  # 1 : 1 000 000
SCALE_500_000 = 500000  # 1 : 500 000
SCALE_300_000 = 300000  # 1 : 300 000
SCALE_200_000 = 200000  # 1 : 200 000
SCALE_100_000 = 100000  # 1 : 100 000
SCALE_50_000 = 50000  # 1 : 50 000
SCALE_25_000 = 25000  # 1 : 25 000
SCALE_10_000 = 10000  # 1 : 10 000
SCALE_5_000 = 5000  # 1 : 5 000
SCALE_2_000 = 2000  # 1 : 2 000
# Типы координатных осей
AXIS_LONGITUDE = 0  # Долгота
AXIS_LATITUDE = 1  # Широта


def sub_zones_count(for_scale):
    if for_scale == SCALE_500_000:
        return 4
    elif for_scale == SCALE_300_000:
        return 9
    elif for_scale == SCALE_200_000:
        return 36
    elif for_scale == SCALE_100_000:
        return 144
    elif for_scale == SCALE_50_000:
        return 4
    elif for_scale == SCALE_25_000:
        return 4
    elif for_scale == SCALE_10_000:
        return 4
    elif for_scale == SCALE_5_000:
        return 256
    elif for_scale == SCALE_2_000:
        return 9


def degrees_to_decimal_degrees(degrees, minutes=0, seconds=.0):
    if minutes >= 60:
        raise ValueError('В градусе должно быть менее 60 минут')
    if seconds >= 60:
        raise ValueError('В минуте должно быть менее 60 секунд')
    if seconds < 0:
        raise ValueError('Секунды не могут быть отрицательными')
    return degrees + minutes / 60.0 + seconds / 3600.0


def sheet_width(axis_type, for_scale):
    if for_scale == SCALE_1_000_000:
        return 6 if axis_type == AXIS_LONGITUDE else 4  # 6° or 4°
    elif for_scale == SCALE_500_000:
        return 3 if axis_type == AXIS_LONGITUDE else 2  # 3° or 2°
    elif for_scale == SCALE_300_000:
        return 2 if axis_type == AXIS_LONGITUDE else \
            degrees_to_decimal_degrees(1, 20)  # 2° or 1°20`
    elif for_scale == SCALE_200_000:
        return 1 if axis_type == AXIS_LONGITUDE else \
            degrees_to_decimal_degrees(0, 40)  # 1° or 0°40`
    elif for_scale == SCALE_100_000:
        return degrees_to_decimal_degrees(0, 30) if axis_type == AXIS_LONGITUDE else \
            degrees_to_decimal_degrees(0, 20)  # 0°30` or 0°20`
    elif for_scale == SCALE_50_000:
        return degrees_to_decimal_degrees(0, 15) if axis_type == AXIS_LONGITUDE else \
            degrees_to_decimal_degrees(0, 10)  # 0°15` or 0°10`
    elif for_scale == SCALE_25_000:
        return degrees_to_decimal_degrees(0, 7, 30) if axis_type == AXIS_LONGITUDE else \
            degrees_to_decimal_degrees(0, 5)  # 0°7`30`` or 0°5`
    elif for_scale == SCALE_10_000:
        return degrees_to_decimal_degrees(0, 3, 45) if axis_type == AXIS_LONGITUDE else \
            degrees_to_decimal_degrees(0, 2, 30)  # 0°3`45`` or 0°2`30``
    elif for_scale == SCALE_5_000:
        return degrees_to_decimal_degrees(0, 1, 52.5) if axis_type == AXIS_LONGITUDE else \
            degrees_to_decimal_degrees(0, 1, 15)  # 0°1`52.5`` or 0°1`15``
    elif for_scale == SCALE_2_000:
        return degrees_to_decimal_degrees(0, 0, 37.5) if axis_type == AXIS_LONGITUDE else \
            degrees_to_decimal_degrees(0, 0, 25)  # 0°0`37.5`` or 0°0`25``
    return None


def check_float_parameter(param_value, default_value):
    if param_value == '':
        return default_value
    else:
        return float(param_value)


def min_axis_value(axis_type):
    return -90 if axis_type == AXIS_LATITUDE else -180


def max_axis_value(axis_type):
    return 90 if axis_type == AXIS_LATITUDE else 180


def zone_numbers(value, axis_type):
    def process(process_scale, min_v):
        w = sheet_width(axis_type, process_scale)
        process_zone = (value - min_v) // w
        min_v += process_zone * w
        if axis_type == AXIS_LONGITUDE:
            process_zone += 1
        else:
            process_zone = math.sqrt(sub_zones_count(process_scale)) - 1 - process_zone
        return {'zone': int(process_zone), 'min': min_v}

    result = {}
    # 1 : 1 000 000
    width = sheet_width(axis_type, SCALE_1_000_000)
    zone = int(value / width)
    min_million = zone * width
    if axis_type == AXIS_LONGITUDE:
        zone += 1
    result[SCALE_1_000_000] = zone
    # 1 : 500 000
    proc = process(SCALE_500_000, min_million)
    result[SCALE_500_000] = proc['zone']
    # 1 : 300 000
    proc = process(SCALE_300_000, min_million)
    result[SCALE_300_000] = proc['zone']
    # 1 : 200 000
    proc = process(SCALE_200_000, min_million)
    result[SCALE_200_000] = proc['zone']
    # 1 : 100 000
    proc = process(SCALE_100_000, min_million)
    result[SCALE_100_000] = proc['zone']
    min_100 = proc['min']
    # 1 : 50 000
    proc = process(SCALE_50_000, min_100)
    result[SCALE_50_000] = proc['zone']
    min_50 = proc['min']
    # 1 : 25 000
    proc = process(SCALE_25_000, min_50)
    result[SCALE_25_000] = proc['zone']
    min_25 = proc['min']
    # 1 : 10 000
    proc = process(SCALE_10_000, min_25)
    result[SCALE_10_000] = proc['zone']
    # 1 : 5 000
    proc = process(SCALE_5_000, min_100)
    result[SCALE_5_000] = proc['zone']
    min_5 = proc['min']
    # 1 : 2 000
    proc = process(SCALE_2_000, min_5)
    result[SCALE_2_000] = proc['zone']
    return result



def zone_name(for_scale, long_zones, lat_zones):
    long_zone = long_zones[for_scale]
    lat_zone = lat_zones[for_scale]
    def calc_sub_zone_number():
        return int(math.sqrt(sub_zones_count(for_scale)) * lat_zone + long_zone)

    if for_scale == SCALE_1_000_000:
        return '{}-{}'.format(chr(ord('A') + lat_zone), long_zone)  # латинская A
    elif for_scale == SCALE_500_000:
        return '{}'.format(chr(ord('A') + calc_sub_zone_number()))  # латинская A?
    elif for_scale == SCALE_300_000:
        return '{}'.format(chr(ord('А') + calc_sub_zone_number()))  # fix it!
    elif for_scale == SCALE_200_000:
        return '{}'.format(chr(ord('А') + calc_sub_zone_number()))  # fix it!
    elif for_scale == SCALE_100_000:
        return '{}'.format(calc_sub_zone_number())
    elif for_scale == SCALE_50_000:
        return '{}'.format(chr(ord('А') + calc_sub_zone_number()))  # русские
    elif for_scale == SCALE_25_000:
        return '{}'.format(chr(ord('а') + calc_sub_zone_number()))  # русские
    elif for_scale == SCALE_10_000:
        return '{}'.format(calc_sub_zone_number())
    elif for_scale == SCALE_5_000:
        return '{}'.format(calc_sub_zone_number())
    elif for_scale == SCALE_2_000:
        return '{}'.format(chr(ord('а') + calc_sub_zone_number()))  # русские


if __name__ == '__main__':
    try:
        shape_file = arcpy.GetParameter(0)
        scale = check_float_parameter(arcpy.GetParameterAsText(1), 5000)
        out_shape_file = arcpy.GetParameterAsText(2)

        arcpy.Describe(shape_file)
        desc = arcpy.Describe(shape_file)
        ext = desc.extent
        ll_corner = ext.lowerLeft
        ur_corner = ext.upperRight

        cs = desc.spatialReference
        # Проецирование углов в географическую СК
        ll_corner = arcpy.PointGeometry(ll_corner, desc.spatialReference). \
            projectAs(desc.spatialReference.GCS).firstPoint
        ur_corner = arcpy.PointGeometry(ur_corner, desc.spatialReference). \
            projectAs(desc.spatialReference.GCS).firstPoint
        west = ll_corner.X
        east = ur_corner.X
        north = ur_corner.Y
        south = ll_corner.Y
        # Размеры листв
        long_sheet_width = sheet_width(AXIS_LONGITUDE, scale)
        lat_sheet_width = sheet_width(AXIS_LATITUDE, scale)
        # Угловые номера зон
        west_zone = int(west / long_sheet_width)
        east_zone = int(east / long_sheet_width)
        north_zone = int(north / lat_sheet_width)
        south_zone = int(south / lat_sheet_width)
        # Угловые координаты зон
        min_long = west_zone * long_sheet_width
        max_long = (east_zone + 1) * long_sheet_width
        min_lat = south_zone * lat_sheet_width
        max_lat = (north_zone + 1) * lat_sheet_width
        # Количество зон
        long_zones_count = int((max_long - min_long) / long_sheet_width)
        lat_zones_count = int((max_lat - min_lat) / lat_sheet_width)
        # Создание shape-файла с результатами
        if arcpy.Exists(out_shape_file):
            arcpy.Delete_management(out_shape_file)
        out_path = os.path.dirname(out_shape_file)
        out_name = os.path.basename(out_shape_file)
        fc = arcpy.CreateFeatureclass_management(out_path, out_name, 'POLYGON', spatial_reference=desc.spatialReference)
        arcpy.AddField_management(out_shape_file, 'Sheet', 'TEXT')
        # Создание результирующей геометрии
        c = arcpy.da.InsertCursor(out_shape_file, ['SHAPE@', 'Sheet'])
        for i in range(0, long_zones_count):
            for j in range(0, lat_zones_count + 1):
                points = arcpy.Array()
                x1 = min_long + long_sheet_width * i
                x2 = min_long + long_sheet_width * (i + 1)
                y1 = min_lat + lat_sheet_width * j
                y2 = min_lat + lat_sheet_width * (j + 1)
                points.add(arcpy.Point(x1, y1))
                points.add(arcpy.Point(x2, y1))
                points.add(arcpy.Point(x2, y2))
                points.add(arcpy.Point(x1, y2))

                zone_long = zone_numbers((x1 + x2) / 2, AXIS_LONGITUDE)
                zone_lat = zone_numbers((y1 + y2) / 2, AXIS_LATITUDE)
                poly_zone_name = zone_name(SCALE_1_000_000, zone_long, zone_lat)
                if scale == SCALE_500_000:
                    poly_zone_name += '-{}'.format(zone_name(scale, zone_long, zone_lat))
                elif scale == SCALE_300_000:
                    poly_zone_name += '-{}'.format(zone_name(scale, zone_long, zone_lat))  # ???
                if scale == SCALE_200_000:
                    poly_zone_name += '-{}'.format(zone_name(scale, zone_long, zone_lat))  # !!Сделать римские!!
                if scale == SCALE_100_000:
                    poly_zone_name += '-{}'.format(zone_name(scale, zone_long, zone_lat))
                if scale == SCALE_50_000:
                    poly_zone_name += '-{}'.format(zone_name(SCALE_100_000, zone_long, zone_lat))
                    poly_zone_name += '-{}'.format(zone_name(scale, zone_long, zone_lat))
                if scale == SCALE_25_000:
                    poly_zone_name += '-{}'.format(zone_name(SCALE_100_000, zone_long, zone_lat))
                    poly_zone_name += '-{}'.format(zone_name(SCALE_50_000, zone_long, zone_lat))
                    poly_zone_name += '-{}'.format(zone_name(scale, zone_long, zone_lat))
                if scale == SCALE_10_000:
                    poly_zone_name += '-{}'.format(zone_name(SCALE_100_000, zone_long, zone_lat))
                    poly_zone_name += '-{}'.format(zone_name(SCALE_50_000, zone_long, zone_lat))
                    poly_zone_name += '-{}'.format(zone_name(SCALE_25_000, zone_long, zone_lat))
                    poly_zone_name += '-{}'.format(zone_name(scale, zone_long, zone_lat))
                if scale == SCALE_5_000:
                    poly_zone_name += '-{}'.format(zone_name(SCALE_100_000, zone_long, zone_lat))
                    poly_zone_name += '-({})'.format(zone_name(scale, zone_long, zone_lat))
                if scale == SCALE_2_000:
                    poly_zone_name += '-{}'.format(zone_name(SCALE_100_000, zone_long, zone_lat))
                    poly_zone_name += '-({}'.format(zone_name(SCALE_5_000, zone_long, zone_lat))
                    poly_zone_name += '-{})'.format(zone_name(scale, zone_long, zone_lat))

                poly = arcpy.Polygon(points, desc.spatialReference.GCS)
                # poly.Sheet = poly_zone_name
                c.insertRow([poly, poly_zone_name])
                # arcpy.Append_management(poly, out_shape_file)
        del c
        arcpy.AddMessage('done')

    except:
        tb = sys.exc_info()[2]
        tbinfo = traceback.format_tb(tb)[0]
        pymsg = "ERRORS:\nTraceback Info:\n" + tbinfo + "\nError Info:\n    " + \
                str(sys.exc_type) + ": " + str(sys.exc_value) + "\n"
        arcpy.AddError(pymsg)
