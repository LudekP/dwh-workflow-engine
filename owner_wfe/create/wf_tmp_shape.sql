CREATE GLOBAL TEMPORARY TABLE owner_wfe.wf_tmp_shape
( 
 name_workflow_file          VARCHAR2(255) NOT NULL,
 id_workflow_activity_shape  VARCHAR2(255) NOT NULL,
 code_shape_type             VARCHAR2(255) NOT NULL,
 id_workflow_activity        VARCHAR2(255),
 text_stroke_color           VARCHAR2(255),
 text_fill_color             VARCHAR2(255)
)
ON COMMIT PRESERVE ROWS;

-- Add comments to the table 
COMMENT ON TABLE owner_wfe.wf_tmp_shape IS 'Temporary repository for parsed shapes of workflow process activities';
  
-- Add comments to the columns
COMMENT ON COLUMN owner_wfe.wf_tmp_shape.name_workflow_file IS 'Name of the worfklow file';
COMMENT ON COLUMN owner_wfe.wf_tmp_shape.id_workflow_activity_shape IS 'Id of the workflow activity shape';
COMMENT ON COLUMN owner_wfe.wf_tmp_shape.code_shape_type IS 'Code of the shape type';
COMMENT ON COLUMN owner_wfe.wf_tmp_shape.id_workflow_activity IS 'Id of the worfklow activity. It is the activity to which belong this shape';
COMMENT ON COLUMN owner_wfe.wf_tmp_shape.text_stroke_color IS 'Text value of stroke color';
COMMENT ON COLUMN owner_wfe.wf_tmp_shape.text_fill_color IS 'Text value of fill color';
  
-- Grant/Revoke object privileges 
GRANT SELECT ON owner_wfe.wf_tmp_shape TO core_select_any_table;
