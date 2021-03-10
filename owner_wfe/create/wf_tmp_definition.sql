
CREATE GLOBAL TEMPORARY TABLE owner_wfe.wf_tmp_definition
( 
 name_workflow_file        VARCHAR2(255) NOT NULL,
 id_workflow_definition    VARCHAR2(255) NOT NULL,        
 code_main_element_type    VARCHAR2(255) NOT NULL,
 id_main_element           VARCHAR2(255) NOT NULL,
 name_main_element         VARCHAR2(255)
)
ON COMMIT PRESERVE ROWS;
/*)
TABLESPACE wf_data
PARTITION BY LIST (code_main_element_type) 
(
 PARTITION partition_process VALUES ('process')     TABLESPACE wf_data,
 PARTITION partition_diagram VALUES ('BPMNDiagram') TABLESPACE wf_data,
 PARTITION partition_default VALUES (DEFAULT)       TABLESPACE wf_data
);*/

-- Add comments to the table 
COMMENT ON TABLE owner_wfe.wf_tmp_definition IS 'Temporary repository for parsed workflow definition during the deployment';
  
-- Add comments to the columns
COMMENT ON COLUMN owner_wfe.wf_tmp_definition.name_workflow_file IS 'Name of the workflow file';
COMMENT ON COLUMN owner_wfe.wf_tmp_definition.id_workflow_definition IS 'Id of the workflow definition';
COMMENT ON COLUMN owner_wfe.wf_tmp_definition.code_main_element_type IS 'Code of the main element type';
COMMENT ON COLUMN owner_wfe.wf_tmp_definition.id_main_element IS 'Id of the main element';
COMMENT ON COLUMN owner_wfe.wf_tmp_definition.name_main_element IS 'Name of the main element';

-- Grant/Revoke object privileges 
GRANT SELECT ON owner_wfe.wf_tmp_definition TO core_select_any_table;
