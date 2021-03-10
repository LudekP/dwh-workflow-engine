
-- Create table
CREATE TABLE owner_wfe.wf_run_instance_suspend
(
  id_workflow_instance_main INTEGER NOT NULL,
  dtime_inserted            TIMESTAMP(6) NOT NULL
) 
TABLESPACE wf_data; 

-- Add comments to the table 
COMMENT ON TABLE owner_wfe.wf_run_instance_suspend IS 'Suspended workflow instance';

-- Add comments to the columns 
COMMENT ON COLUMN owner_wfe.wf_run_instance_suspend.id_workflow_instance_main IS 'Id of the main workflow instance';
COMMENT ON COLUMN owner_wfe.wf_run_instance_suspend.dtime_inserted IS 'Date and time when the record was inserted';

-- Create/Recreate primary, unique and foreign key constraints 
ALTER TABLE owner_wfe.wf_run_instance_suspend ADD CONSTRAINT pk_wfruinstsusp PRIMARY KEY (id_workflow_instance_main) USING INDEX TABLESPACE wf_index;

-- Grant/Revoke object privileges 
GRANT SELECT ON owner_wfe.wf_run_instance_suspend TO core_select_any_table;
