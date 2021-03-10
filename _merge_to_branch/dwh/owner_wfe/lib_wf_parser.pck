CREATE OR REPLACE PACKAGE owner_wfe.lib_wf_parser IS

  ---------------------------------------------------------------------------------------------------------
  -- author:  Ludek
  -- created: 11.05.2020
  -- purpose: Parse workflow files
  ---------------------------------------------------------------------------------------------------------

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: PARSE_WORKFLOW
  -- purpose:        Parse workflow processes and store elements and their attributes into tables
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE parse_workflow(p_parse_process IN BOOLEAN DEFAULT TRUE,
                           p_parse_diagram IN BOOLEAN DEFAULT FALSE,
                           p_code_result   OUT VARCHAR2,
                           p_text_message  OUT VARCHAR2);
  
END lib_wf_parser;        
/
CREATE OR REPLACE PACKAGE BODY owner_wfe.lib_wf_parser IS

  ---------------------------------------------------------------------------------------------------------
  -- Global variables
  ---------------------------------------------------------------------------------------------------------  
  c_mod_name                CONSTANT VARCHAR2(30) := 'LIB_WF_PARSER';
  c_status_complete         CONSTANT VARCHAR2(30) := owner_wfe.lib_wf_constant.c_complete;
  c_status_error            CONSTANT VARCHAR2(30) := owner_wfe.lib_wf_constant.c_error;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: PARSE_WORKFLOW
  -- purpose:        Parse workflow processes and store elements and their attributes into tables
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE parse_workflow(p_parse_process IN BOOLEAN DEFAULT TRUE,
                           p_parse_diagram IN BOOLEAN DEFAULT FALSE,
                           p_code_result   OUT VARCHAR2,
                           p_text_message  OUT VARCHAR2) IS
    
    c_proc_name CONSTANT VARCHAR2(30) := 'PARSE_WORKFLOW';
    v_step      VARCHAR2(256);

    CURSOR c_workflow IS
      SELECT 
         name_workflow_file,
         text_workflow
      FROM owner_wfe.wf_tmp_file;
    
  BEGIN
    
    IF p_parse_process THEN
      
      v_step := 'Delete data for owner_wfe.wf_tmp_definition';
      DELETE FROM owner_wfe.wf_tmp_definition;
    
      v_step := 'Delete data for owner_wfe.wf_tmp_activity';
      DELETE FROM owner_wfe.wf_tmp_activity;

      v_step := 'Delete data for owner_wfe.wf_tmp_activity_attr';
      DELETE FROM owner_wfe.wf_tmp_activity_attr;
      
    END IF;
    
    IF p_parse_diagram THEN
    
      v_step := 'Delete data for owner_wfe.wf_tmp_shape';
      DELETE FROM owner_wfe.wf_tmp_shape;
      
      v_step := 'Delete data for owner_wfe.wf_tmp_shape_attr';
      DELETE FROM owner_wfe.wf_tmp_shape_attr;
      
    END IF;
    
    -- Commit
    COMMIT;
    
    -- Loop through workflows and parse them
    FOR r IN c_workflow
    LOOP
    
      -- If workflow process should be parsed 
      IF p_parse_process THEN
    
        -- Parse 0.level (workflow definition)
        v_step := 'Parse 0.level (workflow definition)';
        INSERT INTO owner_wfe.wf_tmp_definition
          (name_workflow_file, 
           id_workflow_definition, 
           code_main_element_type, 
           id_main_element, 
           name_main_element)
        WITH workflow_definition AS (SELECT
                                        r.name_workflow_file,
                                        x.id_workflow_definition,
                                        x.text_xml_definiton
                                     FROM dual t,
                                          XMLTABLE(XMLNAMESPACES('http://www.omg.org/spec/BPMN/20100524/MODEL'   AS "bpmn",
                                                                 'http://www.omg.org/spec/BPMN/20100524/DI'      AS "bpmndi",
                                                                 'http://www.omg.org/spec/DD/20100524/DI'        AS "di",
                                                                 'http://www.omg.org/spec/DD/20100524/DC'        AS "dc",
                                                                 'http://camunda.org/schema/1.0/bpmn'            AS "camunda",
                                                                 'http://www.w3.org/2001/XMLSchema-instance'     AS "xsi",
                                                                 'http://bpmn.io/schema/bpmn/biocolor/1.0'       AS "bioc"
                                                                 ),
                                                                 '/*'
                                                                 PASSING r.text_workflow COLUMNS id_workflow_definition  VARCHAR2(255) PATH '@id',
                                                                                                 text_xml_definiton      XMLTYPE       PATH '*'
                                                   ) x
                                     )
        SELECT
           w.name_workflow_file,
           w.id_workflow_definition,
           SUBSTR(x.code_main_element_type, INSTR(x.code_main_element_type, ':', 1) + 1) AS code_main_element_type,
           x.id_main_element,
           x.name_main_element
        FROM workflow_definition w,
             XMLTABLE('*'
                      PASSING w.text_xml_definiton COLUMNS code_main_element_type VARCHAR2(255) PATH 'name(.)',
                                                           id_main_element        VARCHAR2(255) PATH '@id',
                                                           name_main_element      VARCHAR2(255) PATH '@name'     
                      ) x;
      
        -- Parse 1.level (workflow activity)
        v_step := 'Parse 1.level (workflow activity)';
        INSERT INTO owner_wfe.wf_tmp_activity
          (name_workflow_file, 
           id_workflow_activity, 
           code_activity_type, 
           name_activity, 
           id_workflow_called, 
           text_variable_mapping_class, 
           text_async_before, 
           text_async_after, 
           id_workflow_activity_source, 
           id_workflow_activity_target)
        SELECT 
           r.name_workflow_file,
           x.id_workflow_activity,
           SUBSTR(code_activity_type, INSTR(code_activity_type, ':', 1) + 1) AS code_activity_type,
           x.name_activity,
           x.id_workflow_called,
           x.text_variable_mapping_class,
           x.text_async_before,
           x.text_async_after,
           x.id_workflow_activity_source,
           x.id_workflow_activity_target
        FROM dual t,
             XMLTABLE(XMLNAMESPACES('http://www.omg.org/spec/BPMN/20100524/MODEL' AS "bpmn",
                                    'http://www.omg.org/spec/BPMN/20100524/DI'    AS "bpmndi",
                                    'http://www.omg.org/spec/DD/20100524/DI'      AS "di",
                                    'http://www.omg.org/spec/DD/20100524/DC'      AS "dc",
                                    'http://camunda.org/schema/1.0/bpmn'          AS "camunda",
                                    'http://www.w3.org/2001/XMLSchema-instance'   AS "xsi",
                                    'http://bpmn.io/schema/bpmn/biocolor/1.0'     AS "bioc"
                                    ),
                      '//bpmn:definitions/bpmn:process/*'
                      PASSING r.text_workflow COLUMNS code_activity_type          VARCHAR2(255) PATH 'name(.)',
                                                      id_workflow_activity        VARCHAR2(255) PATH '@id',
                                                      name_activity               VARCHAR2(255) PATH '@name',
                                                      id_workflow_called          VARCHAR2(255) PATH '@calledElement',
                                                      text_variable_mapping_class VARCHAR2(255) PATH '@camunda:variableMappingClass',
                                                      text_async_before           VARCHAR2(255) PATH '@camunda:asyncBefore',
                                                      text_async_after            VARCHAR2(255) PATH '@camunda:asyncAfter',
                                                      id_workflow_activity_source VARCHAR2(255) PATH '@sourceRef',
                                                      id_workflow_activity_target VARCHAR2(255) PATH '@targetRef'
                      ) x;

        -- Parse 2.level (workflow activity attribute)
        v_step := 'Parse 2.level (workflow activity attribute)';
        INSERT INTO owner_wfe.wf_tmp_activity_attr
          (name_workflow_file, 
           id_workflow_activity, 
           code_activity_type, 
           code_attribute_type, 
           name_attribute, 
           text_attribute_value)
             -- 1. Level
        WITH elements AS (SELECT 
                             x.code_activity_type,  
                             x.id_workflow_activity,
                             x.text_xml_element
                          FROM dual t,
                               XMLTABLE(XMLNAMESPACES('http://www.omg.org/spec/BPMN/20100524/MODEL' AS "bpmn",
                                                      'http://www.omg.org/spec/BPMN/20100524/DI'    AS "bpmndi",
                                                      'http://www.omg.org/spec/DD/20100524/DI'      AS "di",
                                                      'http://www.omg.org/spec/DD/20100524/DC'      AS "dc",
                                                      'http://camunda.org/schema/1.0/bpmn'          AS "camunda",
                                                      'http://www.w3.org/2001/XMLSchema-instance'   AS "xsi",
                                                      'http://bpmn.io/schema/bpmn/biocolor/1.0'     AS "bioc"
                                                      ),
                                        '//bpmn:definitions/bpmn:process/*'
                                        PASSING r.text_workflow COLUMNS code_activity_type   VARCHAR2(255) PATH 'name(.)',
                                                                        id_workflow_activity VARCHAR2(255) PATH '@id',
                                                                        text_xml_element     XMLTYPE       PATH '*'
                                        ) x
                          )
        -- 2. level
        SELECT 
           r.name_workflow_file,
           t.id_workflow_activity,
           SUBSTR(t.code_activity_type, INSTR(t.code_activity_type, ':', 1) + 1) AS code_activity_type,
           SUBSTR(x.code_attribute_type, INSTR(x.code_attribute_type, ':', 1) + 1) AS code_attribute_type,
           x.name_attribute,
           x.text_attribute_value
        FROM elements t,
             XMLTABLE('//*'
                      PASSING t.text_xml_element COLUMNS code_attribute_type  VARCHAR2(255)  PATH 'name(.)',
                                                         name_attribute       VARCHAR2(255)  PATH '@name',
                                                         text_attribute_value VARCHAR2(1000) PATH 'text()'
                      ) x;
                      
        END IF;
        
        -- If workflow diagram should be parsed
        IF p_parse_diagram THEN
          
          -- Parse 2.level (workflow activity shape)
          v_step := 'Parse 2.level (workflow activity shape)';
          INSERT INTO owner_wfe.wf_tmp_shape
            (name_workflow_file, 
             id_workflow_activity_shape, 
             code_shape_type, 
             id_workflow_activity, 
             text_stroke_color, 
             text_fill_color)
          SELECT 
             r.name_workflow_file,
             x.id_workflow_activity_shape,
             SUBSTR(code_shape_type, INSTR(code_shape_type, ':', 1) + 1) AS code_shape_type,
             x.id_workflow_activity,
             x.text_stroke_color,
             x.text_fill_color
          FROM dual t,
               XMLTABLE(XMLNAMESPACES('http://www.omg.org/spec/BPMN/20100524/MODEL' AS "bpmn",
                                      'http://www.omg.org/spec/BPMN/20100524/DI'    AS "bpmndi",
                                      'http://www.omg.org/spec/DD/20100524/DI'      AS "di",
                                      'http://www.omg.org/spec/DD/20100524/DC'      AS "dc",
                                      'http://camunda.org/schema/1.0/bpmn'          AS "camunda",
                                      'http://www.w3.org/2001/XMLSchema-instance'   AS "xsi",
                                      'http://bpmn.io/schema/bpmn/biocolor/1.0'     AS "bioc"
                                      ),
                        '//bpmn:definitions/bpmndi:BPMNDiagram/bpmndi:BPMNPlane/*'
                        PASSING r.text_workflow COLUMNS code_shape_type            VARCHAR2(255) PATH 'name(.)',
                                                        id_workflow_activity_shape VARCHAR2(255) PATH '@id',
                                                        id_workflow_activity       VARCHAR2(255) PATH '@bpmnElement',
                                                        text_stroke_color          VARCHAR2(255) PATH '@bioc:stroke',
                                                        text_fill_color            VARCHAR2(255) PATH '@bioc:fill'                      
                        ) x;
                        
          -- Parse 3.level (workflow activity shape attribute)
          v_step := 'Parse 3.level (workflow activity shape attribute)';
          INSERT INTO owner_wfe.wf_tmp_shape_attr
            (name_workflow_file, 
             id_workflow_activity_shape, 
             code_shape_type, 
             code_attribute_type, 
             text_position_x, 
             text_position_y,
             num_position_order,
             text_width, 
             text_height)
          -- 2. level
          WITH elements AS (SELECT 
                               r.name_workflow_file,
                               x.code_shape_type,  
                               x.id_workflow_activity_shape,
                               x.text_xml_element
                            FROM dual t,
                                 XMLTABLE(XMLNAMESPACES('http://www.omg.org/spec/BPMN/20100524/MODEL' AS "bpmn",
                                                        'http://www.omg.org/spec/BPMN/20100524/DI'    AS "bpmndi",
                                                        'http://www.omg.org/spec/DD/20100524/DI'      AS "di",
                                                        'http://www.omg.org/spec/DD/20100524/DC'      AS "dc",
                                                        'http://camunda.org/schema/1.0/bpmn'          AS "camunda",
                                                        'http://www.w3.org/2001/XMLSchema-instance'   AS "xsi",
                                                        'http://bpmn.io/schema/bpmn/biocolor/1.0'     AS "bioc"
                                                        ),
                                          '//bpmn:definitions/bpmndi:BPMNDiagram/bpmndi:BPMNPlane/*'
                                          PASSING r.text_workflow COLUMNS code_shape_type             VARCHAR2(255) PATH 'name(.)',
                                                                          id_workflow_activity_shape  VARCHAR2(255) PATH '@id',
                                                                          text_xml_element            XMLTYPE       PATH '*'
                                          ) x
                            )
          -- 3. level
          SELECT 
             t.name_workflow_file,
             t.id_workflow_activity_shape,
             SUBSTR(t.code_shape_type, INSTR(t.code_shape_type, ':', 1) + 1) AS code_shape_type,
             SUBSTR(x.code_attribute_type, INSTR(x.code_attribute_type, ':', 1) + 1) AS code_attribute_type,
             x.text_position_x,
             x.text_position_y,
             x.num_position_order,
             x.text_width,
             x.text_height
          FROM elements t,
               XMLTABLE('/*'
                        PASSING t.text_xml_element COLUMNS code_attribute_type VARCHAR2(255) PATH 'name(.)',
                                                           text_position_x     VARCHAR2(255) PATH '@x',
                                                           text_position_y     VARCHAR2(255) PATH '@y',
                                                           text_width          VARCHAR2(255) PATH '@width',
                                                           text_height         VARCHAR2(255) PATH '@height',
                                                           num_position_order  FOR ORDINALITY
                        ) x
          -- Label bounds are not important
          WHERE x.code_attribute_type != 'bpmndi:BPMNLabel';
          
        END IF;
         
      COMMIT;
      
    END LOOP;
    
    -- Calculate statistics
    IF p_parse_process THEN
      
      v_step := 'Calculate statistics for owner_wfe.wf_tmp_definition';
      dbms_stats.gather_table_stats(ownname          => 'OWNER_WFE',
                                    tabname          => 'WF_TMP_DEFINITION',
                                    estimate_percent => dbms_stats.auto_sample_size,
                                    method_opt       => 'FOR ALL INDEXED COLUMNS',
                                    granularity      => 'ALL',
                                    cascade          => TRUE);
                                    
      v_step := 'Calculate statistics for owner_wfe.wf_tmp_activity';
      dbms_stats.gather_table_stats(ownname          => 'OWNER_WFE',
                                    tabname          => 'WF_TMP_ACTIVITY',
                                    estimate_percent => dbms_stats.auto_sample_size,
                                    method_opt       => 'FOR ALL INDEXED COLUMNS',
                                    granularity      => 'ALL',
                                    cascade          => TRUE);

      v_step := 'Calculate statistics for owner_wfe.wf_tmp_activity_attr';
      dbms_stats.gather_table_stats(ownname          => 'OWNER_WFE',
                                    tabname          => 'WF_TMP_ACTIVITY_ATTR',
                                    estimate_percent => dbms_stats.auto_sample_size,
                                    method_opt       => 'FOR ALL INDEXED COLUMNS',
                                    granularity      => 'ALL',
                                    cascade          => TRUE);
                                    
    END IF;

    -- Set result
    p_code_result := c_status_complete;

  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK; 
      -- Set result
      p_code_result := c_status_error;
      -- Set message
      p_text_message := 'Error in '||c_mod_name||'.'||c_proc_name||' - ('||v_step||'): '||SUBSTR(dbms_utility.format_error_stack, 1, 1500);
  END parse_workflow;                       

END lib_wf_parser;
/
