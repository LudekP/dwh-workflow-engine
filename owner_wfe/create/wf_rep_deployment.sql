
CREATE TABLE owner_wfe.wf_rep_deployment
( 
 id_deployment                INTEGER NOT NULL,
 name_deployment              VARCHAR2(255) NOT NULL,
 dtime_inserted               DATE DEFAULT SYSDATE NOT NULL,  
 user_inserted                VARCHAR2(70) DEFAULT USER NOT NULL
)
TABLESPACE wf_data;

-- Add comments to the table 
COMMENT ON TABLE owner_wfe.wf_rep_deployment IS 'Information about workflow deployment';
  
-- Add comments to the columns
COMMENT ON COLUMN owner_wfe.wf_rep_deployment.id_deployment IS 'Id of the deployment';
COMMENT ON COLUMN owner_wfe.wf_rep_deployment.name_deployment IS 'Name of the deployment';
COMMENT ON COLUMN owner_wfe.wf_rep_deployment.dtime_inserted IS 'Date and time when the record was inserted';
COMMENT ON COLUMN owner_wfe.wf_rep_deployment.user_inserted IS 'User who inserted the record';

-- Create/Recreate primary, unique and foreign key constraints 
ALTER TABLE owner_wfe.wf_rep_deployment ADD CONSTRAINT pk_wfrepdepl PRIMARY KEY (id_deployment) USING INDEX TABLESPACE wf_index;

-- Grant/Revoke object privileges 
GRANT SELECT ON owner_wfe.wf_rep_deployment TO core_select_any_table;
