
CREATE TABLE owner_wfe.wf_tmp_file2deployment
( 
 id_deployment      INTEGER NOT NULL,
 name_workflow_file VARCHAR2(255) NOT NULL,
 text_workflow      CLOB NOT NULL,
 dtime_inserted     DATE DEFAULT SYSDATE NOT NULL,  
 user_inserted      VARCHAR2(70) DEFAULT USER NOT NULL
)
TABLESPACE wf_data;

-- Add comments to the table 
COMMENT ON TABLE owner_wfe.wf_tmp_file2deployment IS 'Temporary repository for workflow files during the deployment';
  
-- Add comments to the columns
COMMENT ON COLUMN owner_wfe.wf_tmp_file2deployment.id_deployment IS 'Id of the deployment';
COMMENT ON COLUMN owner_wfe.wf_tmp_file2deployment.name_workflow_file IS 'Name of the workflow file';
COMMENT ON COLUMN owner_wfe.wf_tmp_file2deployment.text_workflow IS 'Text of workflow definition';
COMMENT ON COLUMN owner_wfe.wf_tmp_file2deployment.dtime_inserted IS 'Date and time when the record was inserted';
COMMENT ON COLUMN owner_wfe.wf_tmp_file2deployment.user_inserted IS 'User who inserted the record';

-- Grant/Revoke object privileges 
GRANT SELECT ON owner_wfe.wf_tmp_file2deployment TO core_select_any_table;
