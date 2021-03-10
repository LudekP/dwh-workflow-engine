
CREATE TABLE owner_wfe.wf_rep_file
( 
 id_workflow_definition INTEGER NOT NULL,
 name_workflow_file     VARCHAR2(255) NOT NULL,
 text_workflow          XMLTYPE NOT NULL
)
TABLESPACE wf_data;

-- Add comments to the table 
COMMENT ON TABLE owner_wfe.wf_rep_file IS 'Information about the workflow files';
  
-- Add comments to the columns
COMMENT ON COLUMN owner_wfe.wf_rep_file.id_workflow_definition IS 'Id of the workflow definition';
COMMENT ON COLUMN owner_wfe.wf_rep_file.name_workflow_file IS 'Name of the workflow file';
COMMENT ON COLUMN owner_wfe.wf_rep_file.text_workflow IS 'Text definition of the workflow';

-- Create/Recreate primary, unique and foreign key constraints 
ALTER TABLE owner_wfe.wf_rep_file ADD CONSTRAINT pk_wfrepfile PRIMARY KEY (id_workflow_definition) USING INDEX TABLESPACE wf_index;

-- Grant/Revoke object privileges 
GRANT SELECT ON owner_wfe.wf_rep_file TO core_select_any_table;
