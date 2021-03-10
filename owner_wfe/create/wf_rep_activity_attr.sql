
CREATE TABLE owner_wfe.wf_rep_activity_attr
( 
 id_workflow_definition INTEGER NOT NULL,
 id_workflow_activity   VARCHAR2(255) NOT NULL,
 code_attribute_type    VARCHAR2(255) NOT NULL,
 name_attribute           VARCHAR2(255),
 text_attribute_value VARCHAR2(255)
)
TABLESPACE wf_data
PARTITION BY HASH (id_workflow_definition)
SUBPARTITION BY LIST (code_attribute_type)
SUBPARTITION TEMPLATE
 (
  SUBPARTITION sub_incoming  VALUES ('incoming')       TABLESPACE wf_data,
  SUBPARTITION sub_outgoing  VALUES ('outgoing')       TABLESPACE wf_data,
  SUBPARTITION sub_input_par VALUES ('inputParameter') TABLESPACE wf_data,
  SUBPARTITION sub_default   VALUES (DEFAULT)          TABLESPACE wf_data
  )
(
 PARTITION partition_01 TABLESPACE wf_data,
 PARTITION partition_02 TABLESPACE wf_data,
 PARTITION partition_03 TABLESPACE wf_data,
 PARTITION partition_04 TABLESPACE wf_data,
 PARTITION partition_05 TABLESPACE wf_data,
 PARTITION partition_06 TABLESPACE wf_data,
 PARTITION partition_07 TABLESPACE wf_data,
 PARTITION partition_08 TABLESPACE wf_data,
 PARTITION partition_09 TABLESPACE wf_data,
 PARTITION partition_10 TABLESPACE wf_data,
 PARTITION partition_11 TABLESPACE wf_data,
 PARTITION partition_12 TABLESPACE wf_data,
 PARTITION partition_13 TABLESPACE wf_data,
 PARTITION partition_14 TABLESPACE wf_data,
 PARTITION partition_15 TABLESPACE wf_data,
 PARTITION partition_16 TABLESPACE wf_data,
 PARTITION partition_17 TABLESPACE wf_data,
 PARTITION partition_18 TABLESPACE wf_data,
 PARTITION partition_19 TABLESPACE wf_data,
 PARTITION partition_20 TABLESPACE wf_data,
 PARTITION partition_21 TABLESPACE wf_data,
 PARTITION partition_22 TABLESPACE wf_data,
 PARTITION partition_23 TABLESPACE wf_data,
 PARTITION partition_24 TABLESPACE wf_data,
 PARTITION partition_25 TABLESPACE wf_data,
 PARTITION partition_26 TABLESPACE wf_data,
 PARTITION partition_27 TABLESPACE wf_data,
 PARTITION partition_28 TABLESPACE wf_data,
 PARTITION partition_29 TABLESPACE wf_data,
 PARTITION partition_30 TABLESPACE wf_data,
 PARTITION partition_31 TABLESPACE wf_data,
 PARTITION partition_32 TABLESPACE wf_data
 );

-- Add comments to the table 
COMMENT ON TABLE owner_wfe.wf_rep_activity_attr IS 'Information about workflow activity attributes';
  
-- Add comments to the columns
COMMENT ON COLUMN owner_wfe.wf_rep_activity_attr.id_workflow_definition IS 'Id of the workflow definition';
COMMENT ON COLUMN owner_wfe.wf_rep_activity_attr.id_workflow_activity IS 'Id of the workflow activity';
COMMENT ON COLUMN owner_wfe.wf_rep_activity_attr.code_attribute_type IS 'Code of attribute type';
COMMENT ON COLUMN owner_wfe.wf_rep_activity_attr.name_attribute IS 'Name of the attribute';
COMMENT ON COLUMN owner_wfe.wf_rep_activity_attr.text_attribute_value IS 'Value of the attribute';

-- Create index 
CREATE INDEX owner_wfe.idx_wfrepactattr_attrvalue ON owner_wfe.wf_rep_activity_attr(id_workflow_definition, id_workflow_activity, code_attribute_type, text_attribute_value) TABLESPACE wf_index LOCAL;
CREATE INDEX owner_wfe.idx_wfrepactattr_attrnmvalue ON owner_wfe.wf_rep_activity_attr(id_workflow_definition, id_workflow_activity, code_attribute_type, name_attribute, text_attribute_value) TABLESPACE wf_index LOCAL;  

-- Grant/Revoke object privileges 
GRANT SELECT ON owner_wfe.wf_rep_activity_attr TO core_select_any_table;
