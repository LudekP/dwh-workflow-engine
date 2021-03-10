
CREATE TABLE owner_wfe.wf_rep_activity
( 
 id_workflow_definition      INTEGER NOT NULL,
 id_workflow_activity        VARCHAR2(255) NOT NULL,
 code_activity_type          VARCHAR2(255) NOT NULL,
 name_activity               VARCHAR2(255),
 id_workflow_called          VARCHAR2(255),              
 id_workflow_activity_source VARCHAR2(255),
 id_workflow_activity_target VARCHAR2(255)
)
TABLESPACE wf_data
PARTITION BY HASH (id_workflow_definition)
(
 PARTITION PARTITION_01 TABLESPACE wf_data,
 PARTITION PARTITION_02 TABLESPACE wf_data,
 PARTITION PARTITION_03 TABLESPACE wf_data,
 PARTITION PARTITION_04 TABLESPACE wf_data,
 PARTITION PARTITION_05 TABLESPACE wf_data,
 PARTITION PARTITION_06 TABLESPACE wf_data,
 PARTITION PARTITION_07 TABLESPACE wf_data,
 PARTITION PARTITION_08 TABLESPACE wf_data,
 PARTITION PARTITION_09 TABLESPACE wf_data,
 PARTITION PARTITION_10 TABLESPACE wf_data,
 PARTITION PARTITION_11 TABLESPACE wf_data,
 PARTITION PARTITION_12 TABLESPACE wf_data,
 PARTITION PARTITION_13 TABLESPACE wf_data,
 PARTITION PARTITION_14 TABLESPACE wf_data,
 PARTITION PARTITION_15 TABLESPACE wf_data,
 PARTITION PARTITION_16 TABLESPACE wf_data,
 PARTITION PARTITION_17 TABLESPACE wf_data,
 PARTITION PARTITION_18 TABLESPACE wf_data,
 PARTITION PARTITION_19 TABLESPACE wf_data,
 PARTITION PARTITION_20 TABLESPACE wf_data,
 PARTITION PARTITION_21 TABLESPACE wf_data,
 PARTITION PARTITION_22 TABLESPACE wf_data,
 PARTITION PARTITION_23 TABLESPACE wf_data,
 PARTITION PARTITION_24 TABLESPACE wf_data,
 PARTITION PARTITION_25 TABLESPACE wf_data,
 PARTITION PARTITION_26 TABLESPACE wf_data,
 PARTITION PARTITION_27 TABLESPACE wf_data,
 PARTITION PARTITION_28 TABLESPACE wf_data,
 PARTITION PARTITION_29 TABLESPACE wf_data,
 PARTITION PARTITION_30 TABLESPACE wf_data,
 PARTITION PARTITION_31 TABLESPACE wf_data,
 PARTITION PARTITION_32 TABLESPACE wf_data
 );

-- Add comments to the table 
COMMENT ON TABLE owner_wfe.wf_rep_activity IS 'Information about activities within workflow process';
  
-- Add comments to the columns
COMMENT ON COLUMN owner_wfe.wf_rep_activity.id_workflow_definition IS 'Id of the workflow definition';
COMMENT ON COLUMN owner_wfe.wf_rep_activity.id_workflow_activity IS 'Id of the workflow activity';
COMMENT ON COLUMN owner_wfe.wf_rep_activity.code_activity_type IS 'Code of the activity type';
COMMENT ON COLUMN owner_wfe.wf_rep_activity.name_activity IS 'Name of the activity';
COMMENT ON COLUMN owner_wfe.wf_rep_activity.id_workflow_called IS 'Id of the worfklow called by this activity';
COMMENT ON COLUMN owner_wfe.wf_rep_activity.id_workflow_activity_source IS 'Id of the source workflow activity (filled only for the sequence flow -> it is only element which can have only one source activity)';
COMMENT ON COLUMN owner_wfe.wf_rep_activity.id_workflow_activity_target IS 'Id of the target workflow activity (filled only for the sequence flow -> it is only element which can have only one source activity)';

-- Create/Recreate primary, unique and foreign key constraints
ALTER TABLE owner_wfe.wf_rep_activity ADD CONSTRAINT pk_wfrepact PRIMARY KEY (id_workflow_definition, id_workflow_activity) USING INDEX TABLESPACE wf_index LOCAL;

-- Create/Recreate indexes
-- ??? Proverit index
CREATE INDEX owner_wfe.idx_wfrepact_idvers_idtrg ON owner_wfe.wf_rep_activity(id_workflow_definition, id_workflow_activity_target) TABLESPACE wf_index LOCAL;  
CREATE INDEX owner_wfe.idx_wfrepact_trgact ON owner_wfe.wf_rep_activity(id_workflow_definition, id_workflow_activity, code_activity_type, name_activity, id_workflow_activity_target) TABLESPACE wf_index LOCAL;  

-- Grant/Revoke object privileges 
GRANT SELECT ON owner_wfe.wf_rep_activity TO core_select_any_table;
