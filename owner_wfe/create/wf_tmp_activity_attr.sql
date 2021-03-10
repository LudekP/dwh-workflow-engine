
CREATE GLOBAL TEMPORARY TABLE owner_wfe.wf_tmp_activity_attr
(
 name_workflow_file   VARCHAR2(255)  NOT NULL,
 id_workflow_activity VARCHAR2(255)  NOT NULL,
 code_activity_type   VARCHAR2(255)  NOT NULL,
 code_attribute_type  VARCHAR2(255),
 name_attribute       VARCHAR2(255),
 text_attribute_value VARCHAR2(1000)
)
ON COMMIT PRESERVE ROWS;
/*PARTITION BY LIST (code_activity_type) 
SUBPARTITION BY LIST (code_attribute_type)
(
 PARTITION partition_callact VALUES ('callActivity')
 (
  SUBPARTITION partition_callact_sub_inout   VALUES ('incoming', 'outgoing') TABLESPACE wf_data,
  SUBPARTITION partition_callact_sub_default VALUES (DEFAULT)                TABLESPACE wf_data
 ),
 PARTITION partition_rectask VALUES ('receiveTask')
 (
  SUBPARTITION partition_rectask_sub_inout   VALUES ('incoming', 'outgoing') TABLESPACE wf_data,
  SUBPARTITION partition_rectask_sub_inpar   VALUES ('inputParameter')       TABLESPACE wf_data,
  SUBPARTITION partition_rectask_sub_default VALUES (DEFAULT)                TABLESPACE wf_data
 ),
 PARTITION partition_gateway VALUES ('parallelGateway', 'inclusiveGateway')
 (
  SUBPARTITION partition_gateway_sub_default VALUES (DEFAULT)                TABLESPACE wf_data
 ),
 PARTITION partition_default VALUES (DEFAULT)                                TABLESPACE wf_data
 (
  SUBPARTITION partition_default_sub_default VALUES (DEFAULT)                TABLESPACE wf_data
 )
);*/

-- Add comments to the table 
COMMENT ON TABLE owner_wfe.wf_tmp_activity_attr IS 'Temporary repository for parsed workflow process activity attributes during the deployment';

-- Add comments to the columns
COMMENT ON COLUMN owner_wfe.wf_tmp_activity_attr.name_workflow_file IS 'Name of the worfklow file';
COMMENT ON COLUMN owner_wfe.wf_tmp_activity_attr.id_workflow_activity IS 'Id of the workflow activity';
COMMENT ON COLUMN owner_wfe.wf_tmp_activity_attr.code_activity_type IS 'Code of the activity type';
COMMENT ON COLUMN owner_wfe.wf_tmp_activity_attr.code_attribute_type IS 'Code of the activity attribute type';
COMMENT ON COLUMN owner_wfe.wf_tmp_activity_attr.name_attribute IS 'Name of the activity attribute';
COMMENT ON COLUMN owner_wfe.wf_tmp_activity_attr.text_attribute_value IS 'Text value of the activity attribute';

-- Grant/Revoke object privileges 
GRANT SELECT ON owner_wfe.wf_tmp_activity_attr TO core_select_any_table;

