import arcpy
import os
import sys
import zipfile
import traceback
import re
import json
import datetime

class LicenseError(Exception):
    pass

def now():
    return datetime.datetime.now()

def get_ID_message(ID):
    return re.sub("%1|%2", "%s", arcpy.GetIDMessage(ID))


def zipUpFolder(folder, filename):
    # zip the data
    try:
        zip = zipfile.ZipFile(filename, 'w', zipfile.ZIP_STORED)  # zipfile.ZIP_DEFLATED
        zipws(folder, zip, "CONTENTS_ONLY")
        zip.close()
    except RuntimeError:
        # Delete zip file if exists
        if os.path.exists(filename):
            os.unlink(filename)
        zip = zipfile.ZipFile(filename, 'w', zipfile.ZIP_STORED)
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
                                               os.path.join(dirpath, file)[len(path) + len('/'):]))
                    else:
                        zip.write(os.path.join(dirpath, file),
                                  os.path.join(dirpath[len(path):], file))

                except Exception as e:
                    # Message "    Error adding %s: %s"
                    arcpy.AddWarning(get_ID_message(86134) % (file, e[0]))
    return None


def validate_topology(topology):
    arcpy.AddMessage('<i18n timestamp="{}" topology="{}">topology_is_validating</i18n>'.
                     decode('utf-8').format(now(), os.path.basename(topology)))
    arcpy.ValidateTopology_management(topology)
    arcpy.AddMessage('<i18n timestamp="{}" topology="{}">topology_validated</i18n>'.
                     decode('utf-8').format(now(), os.path.basename(topology)))


def export_topology_results(topology, feature_classes, gdb):
    arcpy.AddMessage('<i18n timestamp="{}" topology="{}">topology_validating_results_exporting</i18n>'.
                     decode('utf-8').format(now(), os.path.basename(topology)))
    try:
        arcpy.ExportTopologyErrors_management(gdb + '/' + feature_classes + '/' + topology, feature_classes, topology)
        arcpy.AddMessage('<i18n timestamp="{}" topology="{}">topology_validating_results_exported</i18n>'.
                         decode('utf-8').format(now(), os.path.basename(topology)))
    except:
        arcpy.AddWarning('<i18n timestamp="{}" topology="{}">cannot_export_topology_validating_results</i18n>'.
                         decode('utf-8').format(now(), os.path.basename(topology)))


def add_class_to_topology(topology, feature_class):
    try:
        arcpy.AddFeatureClassToTopology_management(topology, feature_class)
        arcpy.AddMessage('<i18n timestamp="{}" class="{}">class_added</i18n>'.
                         decode('utf-8').format(now(), feature_class))
    except:
        arcpy.AddMessage('<i18n timestamp="{}" class="{}">class_is_already_exists</i18n>'.
                         decode('utf-8').format(now(), feature_class))


def create_topology(class_set_name, topology_name, cluster_tolerance=None):
    try:
        if cluster_tolerance:
            topology = arcpy.CreateTopology_management(class_set_name, topology_name, cluster_tolerance)
        else:
            topology = arcpy.CreateTopology_management(class_set_name, topology_name)
        arcpy.AddMessage('<i18n timestamp="{}" topology="{}">topology_created</i18n>'.
                         decode('utf-8').format(now(), topology))
        return topology
    except:
        arcpy.AddWarning('<i18n timestamp="{}" class_set="{}">class_set_already_has_topology</i18n>'.
                         decode('utf-8').format(now(), class_set_name))
        return class_set_name + '/' + topology_name


if __name__ == '__main__':
    try:
        # Get the Parameters
        in_gdb = arcpy.GetParameterAsText(0)
        in_rules = arcpy.GetParameterAsText(1)

        arcpy.AddMessage('<i18n timestamp="{}" gdb="{}">uses_gdb</i18n>'.
                         decode('utf-8').format(now(), os.path.basename(in_gdb)))
        arcpy.env.workspace = in_gdb

        topology_rules = json.loads(in_rules)
        arcpy.AddMessage('<i18n timestamp="{}" count="{}">n_rules_will_add</i18n>'.
                         decode('utf-8').format(now(), len(topology_rules)))
        created_topologies = []
        for tr in topology_rules:

            class_set = tr['class_set']
            rule = tr['rule']
            fc1 = tr['fc1']
            fc2 = None
            if 'fc2' in tr:
                fc2 = tr['fc2']
            cs_cluster_tolerance = None
            if 'cluster_tolerance' in tr:
                cs_cluster_tolerance = tr['cluster_tolerance']

            arcpy.AddMessage('<i18n timestamp="{}" class_set="{}">class_set</i18n>'.
                             decode('utf-8').format(now(), class_set))

            if fc2:
                arcpy.AddMessage('<i18n timestamp="{}" rule="{}" class1="{}" class2="{}">\
rule_will_be_add_for_classes</i18n>'.
                                 decode('utf-8').format(now(), rule, fc1, fc2))
            else:
                arcpy.AddMessage('<i18n timestamp="{}" rule="{}" class="{}">rule_will_be_add_for_class</i18n>'.
                                 decode('utf-8').format(now(), rule, fc1))

            if cs_cluster_tolerance:
                arcpy.AddMessage('<i18n timestamp="{}" cluster_tolerance="{}">cluster_tolerance_value</i18n>'.
                                 decode('utf-8').format(now(), cs_cluster_tolerance))
            else:
                arcpy.AddMessage('<i18n timestamp="{}">cluster_tolerance_default</i18n>'.
                                 decode('utf-8').format(now()))

            cs_name = in_gdb + '/' + class_set

            if class_set + '_topology' in created_topologies:
                topology_index = created_topologies.index(class_set + '_topology')
                new_topology = in_gdb + '/' + class_set + '/' + created_topologies[topology_index]
            else:
                new_topology = create_topology(cs_name, class_set + '_topology', cs_cluster_tolerance)
                created_topologies.append(class_set + '_topology')
                fcs = arcpy.ListFeatureClasses('*', 'All', class_set)
                for fc in fcs:
                    add_class_to_topology(new_topology, fc)

            if fc2:
                try:
                    arcpy.AddRuleToTopology_management(new_topology, rule, cs_name + '/' + fc1,
                                                       None, cs_name + '/' + fc2)
                    arcpy.AddMessage('<i18n timestamp="{}" rule="{}" class1="{}" class2="{}" class_set="{}">\
rule_added_for_classes</i18n>'.
                                     decode('utf-8').format(now(), rule, fc1, fc2, class_set))
                except:
                    arcpy.AddError('<i18n timestamp="{}" rule="{}" class1="{}" class2="{}" class_set="{}">\
cannot_add_rule_for_classes</i18n>'.
                                   decode('utf-8').format(now(), rule, fc1, fc2, class_set, traceback.format_exc()))

            else:
                try:
                    arcpy.AddRuleToTopology_management(new_topology, rule, cs_name + '/' + fc1)
                    arcpy.AddMessage('<i18n timestamp="{}" rule="{}" class="{}" class_set="{}">\
rule_added_for_class</i18n>'.
                                     decode('utf-8').format(now(), rule, fc1, class_set))
                except:
                    arcpy.AddError('<i18n timestamp="{}" rule="{}" class="{}" class_set="{}">\
cannot_add_rule_for_class</i18n>'.
                                   decode('utf-8').format(now(), fc1, class_set, traceback.format_exc()))

        if len(created_topologies) > 0:
            arcpy.AddMessage('<i18n timestamp="{}" count="{}">n_topologies_will_validate_and_export</i18n>'.
                             decode('utf-8').format(now(), len(created_topologies)))
            path = os.path.dirname(in_gdb)
            basename = os.path.basename(in_gdb)
            name, ext = os.path.splitext(basename)
            result_gdb = name + '_result' + ext
            arcpy.AddMessage('<i18n timestamp="{}">creating_results_gdb</i18n>'.decode('utf-8').format(now()))
            arcpy.CreateFileGDB_management(path, result_gdb)
            arcpy.AddMessage('<i18n timestamp="{}">results_gdb_created</i18n>'.decode('utf-8').format(now()))

            result_gdb_path = path + '/' + result_gdb
            for topo in created_topologies:
                class_set = topo[0:topo.index('_topology')]
                if not arcpy.Exists(result_gdb_path + '/' + class_set):
                    try:
                        arcpy.CreateFeatureDataset_management(result_gdb_path, class_set, in_gdb + '/' + class_set)
                    except:
                        arcpy.AddMessage('<i18n timestamp="{}" class_set="{}">\
class_set_already_exists_in_results_gdb</i18n>'.decode('utf-8').format(now(), class_set))
                full_topo_name = in_gdb + '/' + class_set + '/' + topo
                validate_topology(full_topo_name)
                export_topology_results(topo, class_set, in_gdb)
                arcpy.AddMessage('<i18n timestamp="{}" topology="{}">exporting_validating_results</i18n>'.
                                 decode('utf-8').format(now(), topo))
                arcpy.Copy_management(full_topo_name + '_line',
                                      result_gdb_path + '/' + class_set + '/' + topo + '_line')
                arcpy.Copy_management(full_topo_name + '_poly',
                                      result_gdb_path + '/' + class_set + '/' + topo + '_poly')
                arcpy.Copy_management(full_topo_name + '_point',
                                      result_gdb_path + '/' + class_set + '/' + topo + '_point')
                arcpy.AddMessage('<i18n timestamp="{}" topology="{}">validating_results_exported</i18n>'.
                                 decode('utf-8').format(now(), topo))

            zip_path = result_gdb_path + '.zip'
            arcpy.AddMessage('<i18n timestamp="{}">packing_validating_results</i18n>'.
                             decode('utf-8').format(now()))
            zipUpFolder(result_gdb_path, zip_path)
            arcpy.AddMessage('<i18n timestamp="{}" file="{}">validating_results_packed_to</i18n>'.
                             decode('utf-8').format(now(), os.path.basename(zip_path)))
            arcpy.SetParameterAsText(2, zip_path)

            try:
                arcpy.Delete_management(result_gdb_path)
            except:
                arcpy.AddWarning('<i18n timestamp="{}" gdb="{}">cannot_remove_temp_gdb</i18n>'.
                                 decode('utf-8').format(now(), os.path.basename(result_gdb)))

        else:
            arcpy.AddMessage('<i18n timestamp="{}">no_results</i18n>'.decode('utf-8').format(now()))


        try:
            arcpy.Delete_management(in_gdb)
        except:
            arcpy.AddWarning('<i18n timestamp="{}" gdb="{}">cannot_remove_temp_gdb</i18n>'.
                             decode('utf-8').format(now(), os.path.basename(in_gdb)))


    except:
        tb = sys.exc_info()[2]
        tbinfo = traceback.format_tb(tb)[0]
        pymsg = "ERRORS:\nTraceback Info:\n" + tbinfo + "\nError Info:\n    " + \
                str(sys.exc_type) + ": " + str(sys.exc_value) + "\n"
        arcpy.AddError(pymsg)
