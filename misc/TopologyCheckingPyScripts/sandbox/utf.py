import arcpy

a = arcpy.GetParameterAsText(0)
arcpy.SetParameterAsText(1, a.encode('utf-8') + 'ÀÁÂÃÄ')
