-- Create table
CREATE TABLE owner_wfe.wf_hist_instance
(
  id_workflow_instance        INTEGER NOT NULL,
  id_workflow_instance_main   INTEGER NOT NULL,
  id_workflow_instance_super  INTEGER NOT NULL, 
  id_workflow_definition      INTEGER NOT NULL,
  id_process_instance         INTEGER NOT NULL,
  date_effective              DATE NOT NULL,
  num_process_priority        INTEGER NOT NULL,
  name_workflow               VARCHAR2(255) NOT NULL,
  dtime_start                 TIMESTAMP(6) NOT NULL,
  dtime_end                   TIMESTAMP(6) NOT NULL,
  code_status                 VARCHAR2(30) NULL
) 
TABLESPACE wf_data
PARTITION BY RANGE (date_effective) 
INTERVAL(NUMTODSINTERVAL(1, 'DAY'))
(  
 PARTITION partition_def VALUES LESS THAN (TO_DATE('1-1-2000', 'DD-MM-YYYY')) TABLESPACE wf_data
); 

-- Add comments to the table 
COMMENT ON TABLE owner_wfe.wf_hist_instance IS 'Workflow instance history';

-- Add comments to the columns 
COMMENT ON COLUMN owner_wfe.wf_hist_instance.id_workflow_instance IS 'Id of the workflow instance';
COMMENT ON COLUMN owner_wfe.wf_hist_instance.id_workflow_instance_main IS 'Id of the main workflow instance (original workflow)';
COMMENT ON COLUMN owner_wfe.wf_hist_instance.id_workflow_instance_super IS 'Id of the superior workflow instance';
COMMENT ON COLUMN owner_wfe.wf_hist_instance.id_workflow_definition IS 'Id of the workflow definition';
COMMENT ON COLUMN owner_wfe.wf_hist_instance.id_process_instance IS 'Id of the process process (master process). Value received from process manager';
COMMENT ON COLUMN owner_wfe.wf_hist_instance.date_effective IS 'Date effective (master process). Value received from process manager';
COMMENT ON COLUMN owner_wfe.wf_hist_instance.num_process_priority IS 'Severity of the process (master process). Value received from process manager';
COMMENT ON COLUMN owner_wfe.wf_hist_instance.name_workflow IS 'Name of the workflow';
COMMENT ON COLUMN owner_wfe.wf_hist_instance.dtime_start IS 'Date and time when the workflow started';
COMMENT ON COLUMN owner_wfe.wf_hist_instance.dtime_end IS 'Date and time when the workflow ended';
COMMENT ON COLUMN owner_wfe.wf_hist_instance.code_status IS 'Status of the the workflow';

-- Create/Recreate primary, unique and foreign key constraints 
ALTER TABLE owner_wfe.wf_hist_instance ADD CONSTRAINT pk_wfhinst PRIMARY KEY (date_effective, id_workflow_instance) USING INDEX TABLESPACE wf_index LOCAL;

-- Create/Recreate indexes
CREATE INDEX owner_wfe.idx_wfhinst_procinst ON owner_wfe.wf_hist_instance(id_process_instance) TABLESPACE wf_index LOCAL;
CREATE INDEX owner_wfe.idx_wfhinst_wfinstmain ON owner_wfe.wf_hist_instance(id_workflow_instance_main) TABLESPACE wf_index LOCAL;  

-- Create/Recreate check constraints 
ALTER TABLE owner_wfe.wf_hist_instance ADD CONSTRAINT c_wfhinst_status CHECK (code_status IS NULL OR code_status IN ('RUNNING', 'COMPLETE', 'CANCEL', 'ERROR', 'RESTART', 'SKIP', 'SUSPEND'));

-- Grant/Revoke object privileges 
GRANT SELECT ON owner_wfe.wf_hist_instance TO core_select_any_table;
