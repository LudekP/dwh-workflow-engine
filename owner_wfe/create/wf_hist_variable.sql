-- Create table
CREATE TABLE owner_wfe.wf_hist_variable
(
  id_workflow_instance          INTEGER NOT NULL,
  id_workflow_activity_instance INTEGER NOT NULL,
  date_effective                DATE NOT NULL,
  name_variable                 VARCHAR2(255 CHAR) NOT NULL,                 
  text_value                    VARCHAR2(4000 CHAR),
  dtime_inserted                TIMESTAMP(6) NOT NULL
) 
TABLESPACE wf_data
PARTITION BY RANGE (date_effective) 
INTERVAL(NUMTODSINTERVAL(1, 'DAY'))
(  
 PARTITION partition_def VALUES LESS THAN (TO_DATE('1-1-2000', 'DD-MM-YYYY')) TABLESPACE wf_data
); 

-- Add comments to the table 
COMMENT ON TABLE owner_wfe.wf_hist_variable IS 'Workflow instance variable history';

-- Add comments to the columns 
COMMENT ON COLUMN owner_wfe.wf_hist_variable.id_workflow_instance IS 'Id of the workflow instance';
COMMENT ON COLUMN owner_wfe.wf_hist_variable.id_workflow_activity_instance IS 'Id of the workflow activity instance';
COMMENT ON COLUMN owner_wfe.wf_hist_variable.date_effective IS 'Date effective (master process). Value received from process manager';
COMMENT ON COLUMN owner_wfe.wf_hist_variable.name_variable IS 'Name of the variable';
COMMENT ON COLUMN owner_wfe.wf_hist_variable.text_value IS 'Text value of the variable';
COMMENT ON COLUMN owner_wfe.wf_hist_variable.dtime_inserted IS 'Date and time when the record was inserted';

-- Create/Recreate indexes
CREATE INDEX owner_wfe.idx_wfhivar_wfinst ON owner_wfe.wf_hist_variable(id_workflow_instance) TABLESPACE wf_index LOCAL;  

-- Create/Recreate primary, unique and foreign key constraints 
ALTER TABLE owner_wfe.wf_hist_variable ADD CONSTRAINT pk_wfhivar PRIMARY KEY (date_effective, id_workflow_instance, id_workflow_activity_instance, name_variable) USING INDEX TABLESPACE wf_index LOCAL COMPRESS 1;

-- Grant/Revoke object privileges 
GRANT SELECT ON owner_wfe.wf_hist_variable TO core_select_any_table;
