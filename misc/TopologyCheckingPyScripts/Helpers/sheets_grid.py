# coding=UTF-8
import arcpy
import sys
import traceback
import os
import math
import datetime
import tempfile
import json
from sys import platform
from ctypes import *
from collections import OrderedDict

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

RUSSIAN_A = 'А'
RUSSIAN_A_SMALL = 'а'


def time_stamp():
    return '_{:%Y%m%d_%H%M%S}'.format(datetime.datetime.now())


def msg_time_stamp():
    return '{:%H:%M:%S.%f}'.format(datetime.datetime.now())
    # return '{:%d.%m.%Y %H:%M:%S.%f}'.format(datetime.datetime.now())


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


def roman_number(num):
    roman = OrderedDict()
    roman[1000] = "M"
    roman[900] = "CM"
    roman[500] = "D"
    roman[400] = "CD"
    roman[100] = "C"
    roman[90] = "XC"
    roman[50] = "L"
    roman[40] = "XL"
    roman[10] = "X"
    roman[9] = "IX"
    roman[5] = "V"
    roman[4] = "IV"
    roman[1] = "I"

    def roman_num(n):
        for r in roman.keys():
            x, y = divmod(n, r)
            yield roman[r] * x
            n -= (r * x)
            if n > 0:
                roman_num(n)
            else:
                break

    return "".join([a for a in roman_num(num)])


def russian_letter(number, small=False):
    if hasattr(sys.stdout, 'encoding'):
        if number == 1:
            return 'a' if small else 'A'
        elif number == 2:
            return 'b' if small else 'B'
        elif number == 3:
            return 'v' if small else 'V'
        elif number == 4:
            return 'g' if small else 'G'
        elif number == 5:
            return 'd' if small else 'D'
        elif number == 6:
            return 'e' if small else 'E'
        elif number == 7:
            return 'zh' if small else 'ZH'
        elif number == 8:
            return 'z' if small else 'Z'
        elif number == 9:
            return 'i' if small else 'I'
    else:
        if number == 1:
            return u'а'.encode('windows-1251') if small else u'А'.encode('windows-1251')
        elif number == 2:
            return u'б'.encode('windows-1251') if small else u'Б'.encode('windows-1251')
        elif number == 3:
            return u'в'.encode('windows-1251') if small else u'В'.encode('windows-1251')
        elif number == 4:
            return u'г'.encode('windows-1251') if small else u'Г'.encode('windows-1251')
        elif number == 5:
            return u'д'.encode('windows-1251') if small else u'Д'.encode('windows-1251')
        elif number == 6:
            return u'е'.encode('windows-1251') if small else u'Е'.encode('windows-1251')
        elif number == 7:
            return u'ж'.encode('windows-1251') if small else u'Ж'.encode('windows-1251')
        elif number == 8:
            return u'з'.encode('windows-1251') if small else u'З'.encode('windows-1251')
        elif number == 9:
            return u'и'.encode('windows-1251') if small else u'И'.encode('windows-1251')


def zone_name(for_scale, long_zones, lat_zones):
    long_zone = long_zones[for_scale]
    lat_zone = lat_zones[for_scale]

    def calc_sub_zone_number():
        return int(math.sqrt(sub_zones_count(for_scale)) * lat_zone + long_zone)

    if for_scale == SCALE_1_000_000:
        return '{}-{}'.format(chr(ord('A') + lat_zone), long_zone + 30)
    elif for_scale == SCALE_500_000:
        return '{}'.format(russian_letter(calc_sub_zone_number()))
    elif for_scale == SCALE_300_000:
        return '{}'.format(roman_number(calc_sub_zone_number()))
    elif for_scale == SCALE_200_000:
        return '{}'.format(roman_number(calc_sub_zone_number()))
    elif for_scale == SCALE_100_000:
        return '{}'.format(calc_sub_zone_number())
    elif for_scale == SCALE_50_000:
        return '{}'.format(russian_letter(calc_sub_zone_number()))
    elif for_scale == SCALE_25_000:
        return '{}'.format(russian_letter(calc_sub_zone_number(), True))
    elif for_scale == SCALE_10_000:
        return '{}'.format(calc_sub_zone_number())
    elif for_scale == SCALE_5_000:
        return '{}'.format(calc_sub_zone_number())
    elif for_scale == SCALE_2_000:
        return '{}'.format(russian_letter(calc_sub_zone_number(), True))


def full_zone_name(for_scale, for_zone_long, for_zone_lat):
    result = zone_name(SCALE_1_000_000, for_zone_long, for_zone_lat)
    if for_scale == SCALE_500_000:
        result += '-{}'.format(zone_name(for_scale, for_zone_long, for_zone_lat))
    elif for_scale == SCALE_300_000:
        result = '{}-'.format(zone_name(for_scale, for_zone_long, for_zone_lat)) + result
    if for_scale == SCALE_200_000:
        result += '-{}'.format(zone_name(for_scale, for_zone_long, for_zone_lat))
    if for_scale == SCALE_100_000:
        result += '-{}'.format(zone_name(for_scale, for_zone_long, for_zone_lat))
    if for_scale == SCALE_50_000:
        result += '-{}'.format(zone_name(SCALE_100_000, for_zone_long, for_zone_lat))
        result += '-{}'.format(zone_name(for_scale, for_zone_long, for_zone_lat))
    if for_scale == SCALE_25_000:
        result += '-{}'.format(zone_name(SCALE_100_000, for_zone_long, for_zone_lat))
        result += '-{}'.format(zone_name(SCALE_50_000, for_zone_long, for_zone_lat))
        result += '-{}'.format(zone_name(for_scale, for_zone_long, for_zone_lat))
    if for_scale == SCALE_10_000:
        result += '-{}'.format(zone_name(SCALE_100_000, for_zone_long, for_zone_lat))
        result += '-{}'.format(zone_name(SCALE_50_000, for_zone_long, for_zone_lat))
        result += '-{}'.format(zone_name(SCALE_25_000, for_zone_long, for_zone_lat))
        result += '-{}'.format(zone_name(for_scale, for_zone_long, for_zone_lat))
    if for_scale == SCALE_5_000:
        result += '-{}'.format(zone_name(SCALE_100_000, for_zone_long, for_zone_lat))
        result += '-({})'.format(zone_name(for_scale, for_zone_long, for_zone_lat))
    if for_scale == SCALE_2_000:
        result += '-{}'.format(zone_name(SCALE_100_000, for_zone_long, for_zone_lat))
        result += '-({}'.format(zone_name(SCALE_5_000, for_zone_long, for_zone_lat))
        result += '-{})'.format(zone_name(for_scale, for_zone_long, for_zone_lat))
    return result


if __name__ == '__main__':
    try:
        shape_file = arcpy.GetParameterAsText(0)
        scale = check_float_parameter(arcpy.GetParameterAsText(1), 5000)
        out_shape_file = arcpy.GetParameterAsText(2)
        remove_unwanted_sheets = arcpy.GetParameterAsText(3) in ['true', 'True']

        arcpy.env.workspace = os.path.dirname(shape_file)

        desc1 = arcpy.Describe(shape_file)

        if hasattr(desc1.spatialReference, 'GCS'):

            arcpy.AddMessage('{}: Script started, geometry has coordinate system'.format(msg_time_stamp()))
            tmp = tempfile.gettempdir()
            if platform == 'win32':
                buf = create_unicode_buffer(500)
                WinPath = windll.kernel32.GetLongPathNameW
                WinPath(unicode(tmp), buf, 500)
                tmp = buf.value

            temp_shape_file = tmp + '\\shp' + time_stamp() + '.shp'
            arcpy.Project_management(shape_file, temp_shape_file, desc1.spatialReference.GCS)
            arcpy.AddMessage('{}: Geometry projected to geographical coordinate system'.format(msg_time_stamp()))
            arcpy.env.workspace = tmp
            desc = arcpy.Describe(temp_shape_file)
            min_x = None
            min_y = None
            max_x = None
            max_y = None

            for row in arcpy.da.SearchCursor(temp_shape_file, ["SHAPE@"]):
                ext = row[0].extent
                if min_x is None or min_x > ext.XMin:
                    min_x = ext.XMin
                if min_y is None or min_y > ext.YMin:
                    min_y = ext.YMin
                if max_x is None or max_x < ext.XMax:
                    max_x = ext.XMax
                if max_y is None or max_y < ext.YMax:
                    max_y = ext.YMax
            try:
                del row
            except:
                arcpy.AddWarning('Shape file does not contain geometry')
            arcpy.AddMessage('{}: Extent = {}:{} - {}:{}'.format(msg_time_stamp(), min_x, min_y, max_x, max_y))
            ext = arcpy.Extent(min_x, min_y, max_x, max_y, None, None, None, None)
            ll_corner = ext.lowerLeft
            ur_corner = ext.upperRight
            ll_corner = arcpy.PointGeometry(ll_corner, desc.spatialReference). \
                projectAs(desc.spatialReference.GCS).firstPoint
            ur_corner = arcpy.PointGeometry(ur_corner, desc.spatialReference). \
                projectAs(desc.spatialReference.GCS).firstPoint
            west = ll_corner.X
            east = ur_corner.X
            north = ur_corner.Y
            south = ll_corner.Y
            arcpy.AddMessage('{}: Projected extent = {}:{} - {}:{}'.format(msg_time_stamp(), west, south, east, north))
            # Размеры листов
            long_sheet_width = sheet_width(AXIS_LONGITUDE, scale)
            lat_sheet_width = sheet_width(AXIS_LATITUDE, scale)
            arcpy.AddMessage('{}: Sheet size = {} long * {} lat'.
                             format(msg_time_stamp(), long_sheet_width, lat_sheet_width))
            # Угловые номера зон
            west_zone = int(west / long_sheet_width)
            east_zone = int(east / long_sheet_width)
            north_zone = int(north / lat_sheet_width)
            south_zone = int(south / lat_sheet_width)
            arcpy.AddMessage('{}: Corner zones: west {}, east {}, south {}, north {}'.
                             format(msg_time_stamp(), west_zone, east_zone, south_zone, north_zone))
            # Угловые координаты зон
            min_long = west_zone * long_sheet_width
            max_long = (east_zone + 1) * long_sheet_width
            min_lat = south_zone * lat_sheet_width
            max_lat = (north_zone + 1) * lat_sheet_width
            arcpy.AddMessage('{}: Corner coordinates: west {}, east {}, south {}, north {}'.
                             format(msg_time_stamp(), min_long, max_long, min_lat, max_lat))
            # Количество зон
            long_zones_count = int(round((max_long - min_long) / long_sheet_width))
            lat_zones_count = int(round((max_lat - min_lat) / lat_sheet_width))
            arcpy.AddMessage('{} longitude zones, {} latitude zones'.format(long_zones_count, lat_zones_count))
            # Создание shape-файла с результатами
            if arcpy.Exists(out_shape_file):
                arcpy.Delete_management(out_shape_file)
            out_path = os.path.dirname(out_shape_file)
            out_name = os.path.basename(out_shape_file)

            if remove_unwanted_sheets:
                temp_result = arcpy.CreateFeatureclass_management(tmp, 'shp' + time_stamp() + '.shp', 'POLYGON',
                                                                  spatial_reference=desc.spatialReference)
                result_shapefile = unicode(temp_result).encode('utf-8')
            else:
                out_shape_file = arcpy.CreateFeatureclass_management(out_path, out_name, 'POLYGON',
                                                                     spatial_reference=desc.spatialReference)
                result_shapefile = unicode(out_shape_file).encode('utf-8')

            arcpy.AddField_management(result_shapefile, 'Sheet', 'TEXT')
            arcpy.AddField_management(result_shapefile, 'X_NE', 'DOUBLE')
            arcpy.AddField_management(result_shapefile, 'Y_NE', 'DOUBLE')
            arcpy.AddField_management(result_shapefile, 'X_NW', 'DOUBLE')
            arcpy.AddField_management(result_shapefile, 'Y_NW', 'DOUBLE')
            arcpy.AddField_management(result_shapefile, 'X_SW', 'DOUBLE')
            arcpy.AddField_management(result_shapefile, 'Y_SW', 'DOUBLE')
            arcpy.AddField_management(result_shapefile, 'X_SE', 'DOUBLE')
            arcpy.AddField_management(result_shapefile, 'Y_SE', 'DOUBLE')

            arcpy.AddField_management(result_shapefile, 'Neighbor_E', 'TEXT')
            arcpy.AddField_management(result_shapefile, 'Neighbor_W', 'TEXT')
            arcpy.AddField_management(result_shapefile, 'Neighbor_N', 'TEXT')
            arcpy.AddField_management(result_shapefile, 'Neighbor_S', 'TEXT')
            arcpy.AddMessage('{}: Result shapefile created'.format(msg_time_stamp()))
            # Создание результирующей геометрии
            c = arcpy.da.InsertCursor(result_shapefile, ['SHAPE@', 'Sheet',
                                                         'X_NE', 'Y_NE',
                                                         'X_NW', 'Y_NW',
                                                         'X_SW', 'Y_SW',
                                                         'X_SE', 'Y_SE',
                                                         'Neighbor_E',
                                                         'Neighbor_W',
                                                         'Neighbor_N',
                                                         'Neighbor_S'])

            for i in range(0, long_zones_count):
                for j in range(0, lat_zones_count):
                    points = arcpy.Array()
                    x1 = min_long + long_sheet_width * i
                    x2 = min_long + long_sheet_width * (i + 1)
                    y1 = min_lat + lat_sheet_width * j
                    y2 = min_lat + lat_sheet_width * (j + 1)
                    points.add(arcpy.Point(x1, y1))
                    points.add(arcpy.Point(x2, y1))
                    points.add(arcpy.Point(x2, y2))
                    points.add(arcpy.Point(x1, y2))

                    long_middle = x1 + x2
                    lat_middle = y1 + y2
                    zone_long = zone_numbers(long_middle / 2, AXIS_LONGITUDE)
                    zone_lat = zone_numbers(lat_middle / 2, AXIS_LATITUDE)
                    poly_zone_name = full_zone_name(scale, zone_long, zone_lat)

                    neighbor_east = full_zone_name(scale,
                                                   zone_numbers(long_middle / 2 + long_sheet_width, AXIS_LONGITUDE),
                                                   zone_lat)  # \
                    # if i < long_zones_count - 1 else ''
                    neighbor_west = full_zone_name(scale,
                                                   zone_numbers(long_middle / 2 - long_sheet_width, AXIS_LONGITUDE),
                                                   zone_lat)  # \
                    # if i > 0 else ''
                    neighbor_north = full_zone_name(scale,
                                                    zone_long,
                                                    zone_numbers(lat_middle / 2 + lat_sheet_width, AXIS_LATITUDE))  # \
                    # if j < lat_zones_count - 1 else ''
                    neighbor_south = full_zone_name(scale,
                                                    zone_long,
                                                    zone_numbers(lat_middle / 2 - lat_sheet_width, AXIS_LATITUDE))  # \
                    # if j > 0 else ''

                    poly = arcpy.Polygon(points, desc.spatialReference.GCS)
                    poly = poly.projectAs(desc1.spatialReference)
                    poly_json = json.loads(poly.JSON)
                    if 'rings' in poly_json:
                        ring = poly_json['rings'][0]
                    elif 'curveRings' in poly_json:
                        ring = poly_json['curveRings'][0]
                    c.insertRow([poly, poly_zone_name, ring[0][0], ring[0][1],
                                 ring[1][0], ring[1][1],
                                 ring[2][0], ring[2][1],
                                 ring[3][0], ring[3][1],
                                 neighbor_east,
                                 neighbor_west,
                                 neighbor_north,
                                 neighbor_south])

            del c
            arcpy.AddMessage('{}: Sheets grid created'.format(msg_time_stamp()))

            if remove_unwanted_sheets:
                arcpy.MakeFeatureLayer_management(temp_result, 'temp')
                arcpy.SelectLayerByLocation_management('temp', select_features=shape_file)
                arcpy.CopyFeatures_management('temp', out_shape_file)
                arcpy.AddMessage('{}: Unwanted sheets removed'.format(msg_time_stamp()))
                arcpy.Delete_management(temp_result)

            arcpy.Delete_management(temp_shape_file)

            arcpy.AddMessage('{}: Done'.format(msg_time_stamp()))
        else:
            arcpy.AddWarning('Shapefile has unknown coordinate system.'
                             'CS must be geographical or projected for sheets grid creation possibility.')

    except:
        tb = sys.exc_info()[2]
        tbinfo = traceback.format_tb(tb)[0]
        pymsg = "ERRORS:\nTraceback Info:\n" + tbinfo + "\nError Info:\n    " + \
                str(sys.exc_type) + ": " + str(sys.exc_value) + "\n"
        arcpy.AddError(pymsg)
