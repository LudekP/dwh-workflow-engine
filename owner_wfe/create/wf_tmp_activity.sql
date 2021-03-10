
CREATE GLOBAL TEMPORARY TABLE owner_wfe.wf_tmp_activity
( 
 name_workflow_file          VARCHAR2(255) NOT NULL,
 id_workflow_activity        VARCHAR2(255) NOT NULL,
 code_activity_type          VARCHAR2(255) NOT NULL,
 name_activity               VARCHAR2(255),
 id_workflow_called          VARCHAR2(255),
 text_variable_mapping_class VARCHAR2(255),
 text_async_before           VARCHAR2(255),
 text_async_after            VARCHAR2(255),            
 id_workflow_activity_source VARCHAR2(255),
 id_workflow_activity_target VARCHAR2(255)
)
ON COMMIT PRESERVE ROWS;
/*)
TABLESPACE wf_data
PARTITION BY LIST (code_activity_type)
(
 PARTITION partition_callact VALUES ('callActivity') TABLESPACE wf_data,
 PARTITION partition_rectask VALUES ('receiveTask') TABLESPACE wf_data,
 PARTITION partition_gateway VALUES ('parallelGateway', 'inclusiveGateway') TABLESPACE wf_data,
 PARTITION partition_seqflow VALUES ('sequenceFlow') TABLESPACE wf_data,
 PARTITION partition_default VALUES (DEFAULT) TABLESPACE wf_data
);*/

-- Add comments to the table 
COMMENT ON TABLE owner_wfe.wf_tmp_activity IS 'Temporary repository for parsed workflow process activities during the deployment';
  
-- Add comments to the columns
COMMENT ON COLUMN owner_wfe.wf_tmp_activity.name_workflow_file IS 'Name of the worfklow file';
COMMENT ON COLUMN owner_wfe.wf_tmp_activity.id_workflow_activity IS 'Id of the workflow activity';
COMMENT ON COLUMN owner_wfe.wf_tmp_activity.code_activity_type IS 'Code of the activity type';
COMMENT ON COLUMN owner_wfe.wf_tmp_activity.name_activity IS 'Name of the activity';
COMMENT ON COLUMN owner_wfe.wf_tmp_activity.id_workflow_called IS 'Id of the worfklow called by this activity';
COMMENT ON COLUMN owner_wfe.wf_tmp_activity.text_variable_mapping_class IS 'Text value of variable mapping class.  Attributte will be filled only for "callActivity" element type';
COMMENT ON COLUMN owner_wfe.wf_tmp_activity.text_async_before IS 'Text value of asynchronouse before option';
COMMENT ON COLUMN owner_wfe.wf_tmp_activity.text_async_after IS 'Text value of asynchronouse before option';
COMMENT ON COLUMN owner_wfe.wf_tmp_activity.id_workflow_activity_source IS 'Id of the source workflow activity (filled only for the sequence flow -> it is only element which can have only one source activity)';
COMMENT ON COLUMN owner_wfe.wf_tmp_activity.id_workflow_activity_target IS 'Id of the target workflow activity (filled only for the sequence flow -> it is only element which can have only one source activity)';
  
-- Grant/Revoke object privileges 
GRANT SELECT ON owner_wfe.wf_tmp_activity TO core_select_any_table;
