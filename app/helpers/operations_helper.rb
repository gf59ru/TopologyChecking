module OperationsHelper

  def rule_types
    {
        0 => {
            :rule => 'Must Not Have Gaps (Area)',
            :first_class => 'Area',
            :rule_i18n_name => 'must_not_have_gaps_area'
        },
        1 => {
            :rule => 'Must Not Overlap (Area)',
            :first_class => 'Area',
            :rule_i18n_name => 'must_not_overlap_area'
        },
        2 => {
            :rule => 'Must Be Covered By Feature Class Of (Area-Area)',
            :first_class => 'Area',
            :second_class => 'Area',
            :rule_i18n_name => 'must_be_covered_by_feature_class_of_area_area'
        },
        3 => {
            :rule => 'Must Cover Each Other (Area-Area)',
            :first_class => 'Area',
            :second_class => 'Area',
            :rule_i18n_name => 'must_cover_each_other_area_area'
        },
        4 => {
            :rule => 'Must Be Covered By (Area-Area)',
            :first_class => 'Area',
            :second_class => 'Area',
            :rule_i18n_name => 'must_be_covered_by_area_area'
        },
        5 => {
            :rule => 'Must Not Overlap With (Area-Area)',
            :first_class => 'Area',
            :second_class => 'Area',
            :rule_i18n_name => 'must_not_overlap_with_area_area'
        },
        6 => {
            :rule => 'Must Be Covered By Boundary Of (Line-Area)',
            :first_class => 'Line',
            :second_class => 'Area',
            :rule_i18n_name => 'must_be_covered_by_boundary_of_line_area'
        },
        7 => {
            :rule => 'Must Be Covered By Boundary Of (Point-Area)',
            :first_class => 'Point',
            :second_class => 'Area',
            :rule_i18n_name => 'must_be_covered_by_boundary_of_point_area'
        },
        8 => {
            :rule => 'Must Be Properly Inside (Point-Area)',
            :first_class => 'Point',
            :second_class => 'Area',
            :rule_i18n_name => 'must_be_properly_inside_point_area'
        },
        9 => {
            :rule => 'Must Not Overlap (Line)',
            :first_class => 'Line',
            :rule_i18n_name => 'must_not_overlap_line'
        },
        10 => {
            :rule => 'Must Not Intersect (Line)',
            :first_class => 'Line',
            :rule_i18n_name => 'must_not_intersect_line'
        },
        11 => {
            :rule => 'Must Not Have Dangles (Line)',
            :first_class => 'Line',
            :rule_i18n_name => 'must_not_have_dangles_line'
        },
        12 => {
            :rule => 'Must Not Have Pseudo-Nodes (Line)',
            :first_class => 'Line',
            :rule_i18n_name => 'must_not_have_pseudo_nodes_line'
        },
        13 => {
            :rule => 'Must Be Covered By Feature Class Of (Line-Line)',
            :first_class => 'Line',
            :second_class => 'Line',
            :rule_i18n_name => 'must_be_covered_by_feature_class_of_line_line'
        },
        14 => {
            :rule => 'Must Not Overlap With (Line-Line)',
            :first_class => 'Line',
            :second_class => 'Line',
            :rule_i18n_name => 'must_not_overlap_with_line_line'
        },
        15 => {
            :rule => 'Must Be Covered By (Point-Line)',
            :first_class => 'Point',
            :second_class => 'Line',
            :rule_i18n_name => 'must_be_covered_by_point_line'
        },
        16 => {
            :rule => 'Must Be Covered By Endpoint Of (Point-Line)',
            :first_class => 'Point',
            :second_class => 'Line',
            :rule_i18n_name => 'must_be_covered_by_endpoint_of_point_line'
        },
        17 => {
            :rule => 'Boundary Must Be Covered By (Area-Line)',
            :first_class => 'Area',
            :second_class => 'Line',
            :rule_i18n_name => 'boundary_must_be_covered_by_area_line'
        },
        18 => {
            :rule => 'Boundary Must Be Covered By Boundary Of (Area-Area)',
            :first_class => 'Area',
            :second_class => 'Area',
            :rule_i18n_name => 'boundary_must_be_covered_by_boundary_of_area_area'
        },
        19 => {
            :rule => 'Must Not Self-Overlap (Line)',
            :first_class => 'Line',
            :rule_i18n_name => 'must_not_self_overlap_line'
        },
        20 => {
            :rule => 'Must Not Self-Intersect (Line)',
            :first_class => 'Line',
            :rule_i18n_name => 'must_not_self_intersect_line'
        },
        21 => {
            :rule => 'Must Not Intersect Or Touch Interior (Line)',
            :first_class => 'Line',
            :rule_i18n_name => 'must_not_intersect_or_touch_interior_line'
        },
        22 => {
            :rule => 'Endpoint Must Be Covered By (Line-Point)',
            :first_class => 'Line',
            :second_class => 'Point',
            :rule_i18n_name => 'endpoint_must_be_covered_by_line_point'
        },
        23 => {
            :rule => 'Contains Point (Area-Point)',
            :first_class => 'Area',
            :second_class => 'Point',
            :rule_i18n_name => 'contains_point_area_point'
        },
        24 => {
            :rule => 'Must Be Single Part (Line)',
            :first_class => 'Line',
            :rule_i18n_name => 'must_be_single_part_line'
        },
        25 => {
            :rule => 'Must Coincide With (Point-Point)',
            :first_class => 'Point',
            :second_class => 'Point',
            :rule_i18n_name => 'must_coincide_with_point_point'
        },
        26 => {
            :rule => 'Must Be Disjoint (Point)',
            :first_class => 'Point',
            :rule_i18n_name => 'must_be_disjoint_point'
        },
        27 => {
            :rule => 'Must Not Intersect With (Line-Line)',
            :first_class => 'Line',
            :second_class => 'Line',
            :rule_i18n_name => 'must_not_intersect_with_line_line'
        },
        28 => {
            :rule => 'Must Not Intersect or Touch Interior With (Line-Line)',
            :first_class => 'Line',
            :second_class => 'Line',
            :rule_i18n_name => 'must_not_intersect_or_touch_interior_with_line_line'
        },
        29 => {
            :rule => 'Must Be Inside (Line-Area)',
            :first_class => 'Line',
            :second_class => 'Area',
            :rule_i18n_name => 'must_be_inside_line_area'
        },
        30 => {
            :rule => 'Contains One Point (Area-Point)',
            :first_class => 'Area',
            :second_class => 'Point',
            :rule_i18n_name => 'contains_one_point_area_point'
        }
    }
  end

  def rule_is_filled(rule_json, check_added = true)
    rule = JSON.parse rule_json unless rule_json.nil?
    rule_type = rule_types.values.select { |rt| rt[:rule] == rule['rule'] }[0] unless rule.nil? || rule['rule'].nil?
    need_second_class = !rule_type[:second_class].nil? unless rule_type.nil?
    if rule.nil?
      false
    elsif check_added && (rule['added'].nil? || !rule['added'])
      false
    elsif rule['class_set'].nil?
      false
    elsif rule['rule'].nil?
      false
    elsif rule['fc1'].nil?
      false
    elsif need_second_class && rule['fc2'].nil?
      false
    else
      true
    end
  end

  def rule_class_list(operation, class_name)
    OperationValue.where('operation_id = ? and operation_parameter_id = ?', operation.id, rule_class_id(class_name)).to_a
  end

  def rule_class_id(class_name)
    case class_name
      when 'Area'
        OperationParameter::PARAM_FEATURE_CLASS_POLYGON
      when 'Line'
        OperationParameter::PARAM_FEATURE_CLASS_LINE
      when 'Point'
        OperationParameter::PARAM_FEATURE_CLASS_POINT
    end
  end

  def add_operation_value(operation, param_value, param_id, order = nil)
    value = OperationValue.new
    value.operation_id = operation.id
    value.operation_parameter_id = param_id
    value.value_order = order
    value.value = param_value
    value.save
  end

  def set_operation_value(operation, new_value, param_id, order = nil)
    if order.nil?
      value = (OperationValue.where 'operation_id = ? and operation_parameter_id = ?', operation.id, param_id).first
    else
      value = (OperationValue.where 'operation_id = ? and operation_parameter_id = ? and value_order = ?', operation.id, param_id, order).first
    end
    if value.nil?
      add_operation_value operation, new_value, param_id, order
    else
      value.value = new_value
      value.save
    end
  end

  def remove_operation_value(operation, param_id, order = nil)
    if order.nil?
      OperationValue.delete_all ['operation_id = ? and operation_parameter_id = ?', operation.id, param_id]
    else
      OperationValue.delete_all ['operation_id = ? and operation_parameter_id = ? and value_order = ?', operation.id, param_id, order]
    end
  end

  def operation_value(operation, param_id, order = nil)
    if order.nil?
      value = (OperationValue.where 'operation_id = ? and operation_parameter_id = ?', operation.id, param_id).first
    else
      value = (OperationValue.where 'operation_id = ? and operation_parameter_id = ? and value_order = ?', operation.id, param_id, order).first
    end
    value.value unless value.nil?
  end

  def operation_values(operation, param_types)
    (OperationValue.where 'operation_id = ? and operation_parameter_id in (?)', operation.id, param_types)
  end

  def arcgis_services_folder
    ENV['TOPOLOGY_CHECKING_SERVICES_FOLDER']
  end

  def shape_type_for_rule(shape_type)
    case shape_type
      when 'Polygon'
        'Area'
      when 'Polyline'
        'Line'
      when 'Point'
        'Point'
    end
  end

  def shape_type_from_rule(shape_type)
    case shape_type
      when 'Area'
        'Polygon'
      when 'Line'
        'Polyline'
      when 'Point'
        'Point'
    end
  end

end
