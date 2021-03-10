
CREATE GLOBAL TEMPORARY TABLE owner_wfe.wf_tmp_file
( 
 name_workflow_file VARCHAR2(255) NOT NULL,
 text_workflow      XMLTYPE NOT NULL
)
ON COMMIT PRESERVE ROWS;
/*)
TABLESPACE wf_data;*/

-- Add comments to the table 
COMMENT ON TABLE owner_wfe.wf_tmp_file IS 'Temporary repository for workflow files during the deployment';
  
-- Add comments to the columns
COMMENT ON COLUMN owner_wfe.wf_tmp_file.name_workflow_file IS 'Name of the workflow file';
COMMENT ON COLUMN owner_wfe.wf_tmp_file.text_workflow IS 'Text of workflow definition';

-- Grant/Revoke object privileges 
GRANT SELECT ON owner_wfe.wf_tmp_file TO core_select_any_table;
