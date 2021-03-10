
-- Create table
CREATE TABLE owner_wfe.wf_run_activity_instance
(
  id_workflow_activity_instance INTEGER NOT NULL,  
  id_workflow_instance          INTEGER NOT NULL,
  id_workflow_instance_main     INTEGER NOT NULL,
  id_workflow_instance_super    INTEGER NOT NULL,
  id_workflow_definition        INTEGER NOT NULL,
  id_workflow_activity          VARCHAR2(255) NOT NULL,
  id_workflow_activity_super    VARCHAR2(255) NOT NULL,
  id_process_instance           INTEGER NOT NULL,
  date_effective                DATE NOT NULL,
  num_process_priority          INTEGER NOT NULL,
  name_workflow                 VARCHAR2(255) NOT NULL,
  code_activity_type            VARCHAR2(255) NOT NULL,
  name_activity                 VARCHAR2(255),
  dtime_start                   TIMESTAMP(6) NOT NULL,
  code_status                   VARCHAR2(30) NULL
) 
TABLESPACE wf_data; 

-- Add comments to the table 
COMMENT ON TABLE owner_wfe.wf_run_activity_instance IS 'Workflow activity instance history';

-- Add comments to the columns 
COMMENT ON COLUMN owner_wfe.wf_run_activity_instance.id_workflow_activity_instance IS 'Id of the workflow activity instance';
COMMENT ON COLUMN owner_wfe.wf_run_activity_instance.id_workflow_instance IS 'Id of the workflow instance';
COMMENT ON COLUMN owner_wfe.wf_run_activity_instance.id_workflow_instance_main IS 'Id of the main workflow instance (original workflow)';
COMMENT ON COLUMN owner_wfe.wf_run_activity_instance.id_workflow_instance_super IS 'Id of the superior workflow instance';
COMMENT ON COLUMN owner_wfe.wf_run_activity_instance.id_workflow_definition IS 'Id of the workflow definition';
COMMENT ON COLUMN owner_wfe.wf_run_activity_instance.id_workflow_activity IS 'Id of the workflow activity';
COMMENT ON COLUMN owner_wfe.wf_run_activity_instance.id_workflow_activity_super IS 'Id of the superior workflow activity';
COMMENT ON COLUMN owner_wfe.wf_run_activity_instance.id_process_instance IS 'Id of the process process (master process). Value received from process manager';
COMMENT ON COLUMN owner_wfe.wf_run_activity_instance.date_effective IS 'Date effective (master process). Value received from process manager';
COMMENT ON COLUMN owner_wfe.wf_run_activity_instance.num_process_priority IS 'Priority of the process (master process). Value received from process manager';
COMMENT ON COLUMN owner_wfe.wf_run_activity_instance.name_workflow IS 'Name of the workflow';
COMMENT ON COLUMN owner_wfe.wf_run_activity_instance.code_activity_type IS 'Code of the activity type';
COMMENT ON COLUMN owner_wfe.wf_run_activity_instance.name_activity IS 'Name of the activity';
COMMENT ON COLUMN owner_wfe.wf_run_activity_instance.dtime_start IS 'Date and time when the workflow activity started';
COMMENT ON COLUMN owner_wfe.wf_run_activity_instance.code_status IS 'Status of the the workflow activity';

-- Create/Recreate primary, unique and foreign key constraints 
ALTER TABLE owner_wfe.wf_run_activity_instance ADD CONSTRAINT pk_wfractinst PRIMARY KEY (id_workflow_activity_instance) USING INDEX TABLESPACE wf_index;

-- Create/Recreate check constraints 
ALTER TABLE owner_wfe.wf_run_activity_instance ADD CONSTRAINT c_wfractinst_status CHECK (code_status IN ('RUNNING', 'COMPLETE', 'CANCEL', 'ERROR', 'RESTART', 'SKIP', 'SUSPEND'));

-- Grant/Revoke object privileges 
GRANT SELECT ON owner_wfe.wf_run_activity_instance TO core_select_any_table;
