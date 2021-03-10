CREATE GLOBAL TEMPORARY TABLE owner_wfe.wf_tmp_shape_attr
( 
 name_workflow_file         VARCHAR2(255) NOT NULL,
 id_workflow_activity_shape VARCHAR2(255) NOT NULL,
 code_shape_type            VARCHAR2(255) NOT NULL,
 code_attribute_type        VARCHAR2(255) NOT NULL,
 text_position_x            VARCHAR2(255),
 text_position_y            VARCHAR2(255),
 num_position_order         INTEGER,
 text_width                 VARCHAR2(255),
 text_height                VARCHAR2(255)
)
ON COMMIT PRESERVE ROWS;

-- Add comments to the table 
COMMENT ON TABLE owner_wfe.wf_tmp_shape_attr IS 'Temporary repository for parsed shape attributes of workflow process activities';
  
-- Add comments to the columns
COMMENT ON COLUMN owner_wfe.wf_tmp_shape_attr.name_workflow_file IS 'Name of the worfklow file';
COMMENT ON COLUMN owner_wfe.wf_tmp_shape_attr.id_workflow_activity_shape IS 'Id of the workflow activity shape';
COMMENT ON COLUMN owner_wfe.wf_tmp_shape_attr.code_shape_type IS 'Code of the shape type';
COMMENT ON COLUMN owner_wfe.wf_tmp_shape_attr.code_attribute_type IS 'Code of the attribute type';
COMMENT ON COLUMN owner_wfe.wf_tmp_shape_attr.text_position_x IS 'Position X';
COMMENT ON COLUMN owner_wfe.wf_tmp_shape_attr.text_position_y IS 'Position Y';
COMMENT ON COLUMN owner_wfe.wf_tmp_shape_attr.num_position_order IS 'Position order';
COMMENT ON COLUMN owner_wfe.wf_tmp_shape_attr.text_width IS 'Width';
COMMENT ON COLUMN owner_wfe.wf_tmp_shape_attr.text_height IS 'Height';

-- Grant/Revoke object privileges 
GRANT SELECT ON owner_wfe.wf_tmp_shape_attr TO core_select_any_table;
