
CREATE TABLE owner_wfe.wf_rep_definition
( 
 id_workflow_definition    INTEGER NOT NULL,
 id_workflow               VARCHAR2(255) NOT NULL,
 num_version               INTEGER NOT NULL,
 id_deployment             INTEGER NOT NULL,
 name_workflow             VARCHAR2(255) NOT NULL,
 name_workflow_file        VARCHAR2(255) NOT NULL,
 dtime_valid_from          DATE NOT NULL,
 dtime_valid_to            DATE NOT NULL
)
TABLESPACE wf_data;

-- Add comments to the table 
COMMENT ON TABLE owner_wfe.wf_rep_definition IS 'Information about workflow process definition';
  
-- Add comments to the columns
COMMENT ON COLUMN owner_wfe.wf_rep_definition.id_workflow_definition IS 'Id of the workflow definition';
COMMENT ON COLUMN owner_wfe.wf_rep_definition.id_workflow IS 'Id of the workflow';
COMMENT ON COLUMN owner_wfe.wf_rep_definition.num_version IS 'Version fo the workflow';
COMMENT ON COLUMN owner_wfe.wf_rep_definition.id_deployment IS 'Id of the deployment';
COMMENT ON COLUMN owner_wfe.wf_rep_definition.name_workflow IS 'Name of the workflow';
COMMENT ON COLUMN owner_wfe.wf_rep_definition.name_workflow_file IS 'Name of the workflow file';
COMMENT ON COLUMN owner_wfe.wf_rep_definition.dtime_valid_from IS 'Start date and time of the record validity.';
COMMENT ON COLUMN owner_wfe.wf_rep_definition.dtime_valid_to IS 'End date and time of the record validity.';

-- Create index
CREATE INDEX owner_wfe.idx_wfrepdef_idwfvers ON owner_wfe.wf_rep_definition (name_workflow, dtime_valid_to, id_workflow_definition) TABLESPACE wf_index;

-- Create/Recreate primary, unique and foreign key constraints 
ALTER TABLE owner_wfe.wf_rep_definition ADD CONSTRAINT pk_wfrepdef PRIMARY KEY (id_workflow_definition) USING INDEX TABLESPACE wf_index;
ALTER TABLE owner_wfe.wf_rep_definition ADD CONSTRAINT uk_wfrepdef UNIQUE (id_workflow, num_version) USING INDEX TABLESPACE wf_index;
ALTER TABLE owner_wfe.wf_rep_definition ADD CONSTRAINT uk2_wfrepdef UNIQUE (id_workflow, dtime_valid_to) USING INDEX TABLESPACE wf_index;

-- Grant/Revoke object privileges 
GRANT SELECT ON owner_wfe.wf_rep_definition TO core_select_any_table;

