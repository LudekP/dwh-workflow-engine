CREATE OR REPLACE PACKAGE owner_wfe.lib_wf_diagram_api IS

  ---------------------------------------------------------------------------------------------------------
  -- author:  Ludek
  -- created: 11.05.2020
  -- purpose: Provide access to workflow diagrams which can be accessible via console
  ---------------------------------------------------------------------------------------------------------

  ---------------------------------------------------------------------------------------------------------
  -- Global variables
  ---------------------------------------------------------------------------------------------------------  
  TYPE t_workflow_list       IS RECORD (id_workflow_definition INTEGER,
                                        name_workflow          VARCHAR2(255),
                                        name_workflow_super    VARCHAR2(255),
                                        text_path              VARCHAR2(4000),  
                                        num_level              INTEGER,
                                        num_version            INTEGER,
                                        code_status            VARCHAR2(30),
                                        dtime_valid_from       DATE,
                                        dtime_valid_to         DATE,
                                        user_inserted          VARCHAR2(70),
                                        name_deployment        VARCHAR2(255)); 
  
  TYPE tt_workflow_list      IS TABLE OF t_workflow_list;  

  ---------------------------------------------------------------------------------------------------------
  -- function name: GET_WORKFLOW_LIST
  -- purpose:       Get workflow list for given main workflow process
  ---------------------------------------------------------------------------------------------------------  
  FUNCTION get_workflow_list(p_name_workflow IN VARCHAR2) RETURN tt_workflow_list;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: GET_WORKFLOW
  -- purpose:        Get workflow definition
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE get_workflow(p_id_workflow_definition IN INTEGER DEFAULT NULL,
                         p_name_workflow          IN VARCHAR2 DEFAULT NULL,
                         p_text_workflow          OUT CLOB);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: GET_EXEC_WORKFLOW
  -- purpose:        Get executed workflow definition
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE get_exec_workflow(p_id_workflow_instance      IN INTEGER DEFAULT NULL,
                              p_id_workflow_activity_inst IN INTEGER DEFAULT NULL,                       
                              p_date_effective            IN DATE,
                              p_text_workflow             OUT CLOB);

END lib_wf_diagram_api;        
/
CREATE OR REPLACE PACKAGE BODY owner_wfe.lib_wf_diagram_api IS

  ---------------------------------------------------------------------------------------------------------
  -- Global variables
  ---------------------------------------------------------------------------------------------------------  
  c_mod_name                CONSTANT VARCHAR2(30) := 'LIB_WF_DIAGRAM_API';
  c_date_future             CONSTANT DATE := owner_wfe.lib_wf_constant.c_date_future;
  c_xap                     CONSTANT VARCHAR2(10) := owner_wfe.lib_wf_constant.c_xap;
  c_status_complete         CONSTANT VARCHAR2(30) := owner_wfe.lib_wf_constant.c_complete;
  c_status_cancel           CONSTANT VARCHAR2(30) := owner_wfe.lib_wf_constant.c_cancel;
  c_status_running          CONSTANT VARCHAR2(30) := owner_wfe.lib_wf_constant.c_running;
  c_status_error            CONSTANT VARCHAR2(30) := owner_wfe.lib_wf_constant.c_error;
  c_status_restart          CONSTANT VARCHAR2(30) := owner_wfe.lib_wf_constant.c_restart;
  c_status_skip             CONSTANT VARCHAR2(30) := owner_wfe.lib_wf_constant.c_skip;
  c_status_stuck            CONSTANT VARCHAR2(30) := owner_wfe.lib_wf_constant.c_stuck;
  v_text_message            VARCHAR2(4000);
    
  -- Workflow activity diagram type
  c_shape                   CONSTANT VARCHAR2(100) := owner_wfe.lib_wf_constant.c_shape;
  
  -- Workflow activity type
  c_call_activity           CONSTANT VARCHAR2(100) := owner_wfe.lib_wf_constant.c_call_activity;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: GET_WORKFLOW_FILE
  -- purpose:        Get workflow file
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE get_workflow_file(p_id_workflow_definition IN INTEGER DEFAULT NULL,
                              p_name_workflow          IN VARCHAR2 DEFAULT NULL,
                              p_name_workflow_file     OUT VARCHAR2,
                              p_text_workflow          OUT XMLTYPE) IS
    
  BEGIN

    -- Get workflow definition
    IF p_id_workflow_definition IS NOT NULL THEN
      
      SELECT
         name_workflow_file,
         text_workflow 
        INTO
         p_name_workflow_file,
         p_text_workflow
      FROM owner_wfe.wf_rep_file
      WHERE id_workflow_definition = p_id_workflow_definition;
      
    ELSIF p_name_workflow IS NOT NULL THEN
      
      SELECT
         f.name_workflow_file,
         f.text_workflow 
        INTO
         p_name_workflow_file,
         p_text_workflow
      FROM owner_wfe.wf_rep_definition p
      JOIN owner_wfe.wf_rep_file f ON f.id_workflow_definition = p.id_workflow_definition
      WHERE p.name_workflow = p_name_workflow
        AND p.dtime_valid_to = c_date_future;
    
    END IF;
      
  EXCEPTION
    WHEN no_data_found THEN
      -- Raise error
      raise_application_error(-20001, 'Unable to get workflow file! (id workflow definition - '||p_id_workflow_definition||' / name_workflow - '||p_name_workflow||')');   
    WHEN OTHERS THEN
      -- Raise error
      RAISE;  

  END get_workflow_file;  
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: GET_WORKFLOW_FILE
  -- purpose:        Get workflow file
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE parse_workflow_diagram(p_name_workflow_file  IN VARCHAR2,
                                   p_text_workflow       IN XMLTYPE,
                                   p_code_result         OUT VARCHAR2,
                                   p_text_message        OUT CLOB) IS
    
  BEGIN

    -- Remove data from tmp file table
    DELETE FROM owner_wfe.wf_tmp_file;
    
    -- Prepare workflow file for parsing
    INSERT INTO owner_wfe.wf_tmp_file
      (name_workflow_file, 
      text_workflow)
    VALUES
      (p_name_workflow_file,
       p_text_workflow);
    
    -- Commit
    COMMIT;
    
    -- Parse workflow diagram
    owner_wfe.lib_wf_parser.parse_workflow(p_parse_process => FALSE,
                                           p_parse_diagram => TRUE,
                                           p_code_result   => p_code_result,
                                           p_text_message  => p_text_message);

  END parse_workflow_diagram;  
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name:
  -- purpose:        
  ---------------------------------------------------------------------------------------------------------  
  FUNCTION gen_workflow_diagram(p_id_workflow_instance IN INTEGER,
                                p_date_effective       IN DATE,
                                p_name_workflow        IN VARCHAR2) RETURN CLOB
  IS
  
    c_workflow_diagram_templ_begin CONSTANT VARCHAR2(5000) := '  <bpmndi:BPMNDiagram id="#NAME_DIAGRAM#">
    <bpmndi:BPMNPlane id="#ID_PLANE#" bpmnElement="#NAME_WORKFLOW#">';

    c_workflow_diagram_templ_end   CONSTANT VARCHAR2(5000) := '    </bpmndi:BPMNPlane>
  </bpmndi:BPMNDiagram>';

    c_shape_template               CONSTANT VARCHAR2(5000) := '      <bpmndi:BPMNShape id="#ID_SHAPE#" bpmnElement="#ID_ACTIVITY#"#COLOR#>
        <dc:Bounds x="#X_POSITION#" y="#Y_POSITION#" width="#WIDTH#" height="#HEIGHT#" />
      </bpmndi:BPMNShape>';
      
    c_edge_template                CONSTANT VARCHAR2(5000) := '      <bpmndi:BPMNEdge id="#ID_SHAPE#" bpmnElement="#ID_ACTIVITY#"#COLOR#>
        #EDGE_POSITION#
      </bpmndi:BPMNEdge>';
      
    v_workflow_diagram             CLOB;
    v_diagram_definition           CLOB;
    v_diagram_element              VARCHAR2(32000);
    v_edge_position                VARCHAR2(32000);
  
    CURSOR c_workflow_activity IS
      WITH activity_instance_base AS (SELECT
                                         hai.id_workflow_activity,
                                         hai.id_workflow_activity_super,
                                         COALESCE(rais.code_status, hai.code_status, rai.code_status) AS code_status,
                                         CASE WHEN COALESCE(rais.code_status, hai.code_status, rai.code_status) IN (c_status_complete, c_status_running, c_status_error) THEN 1
                                              WHEN COALESCE(rais.code_status, hai.code_status, rai.code_status) = c_status_skip                                          THEN 2
                                              ELSE 3
                                         END AS num_priority
                                      FROM owner_wfe.wf_hist_activity_instance hai
                                      LEFT JOIN owner_wfe.wf_run_activity_instance rai ON rai.id_workflow_activity_instance = hai.id_workflow_activity_instance
                                                                                      AND rai.date_effective = hai.date_effective 
                                      LEFT JOIN (SELECT 
                                                    DISTINCT 
                                                     id_workflow_instance_super AS id_workflow_instance,
                                                     name_workflow              AS id_workflow_activity,
                                                     code_status                AS code_status
                                                 FROM owner_wfe.wf_run_activity_instance 
                                                 WHERE id_workflow_instance_super = p_id_workflow_instance
                                                   AND date_effective = p_date_effective
                                                   AND code_status = c_status_error
                                                 ) rais ON rais.id_workflow_instance = hai.id_workflow_instance
                                                       AND rais.id_workflow_activity = hai.id_workflow_activity    
                                      WHERE hai.id_workflow_instance = p_id_workflow_instance
                                        AND hai.date_effective = p_date_effective
                                        AND NVL(hai.code_status, c_xap) != c_status_restart
                                      ),
           activity_instance AS (SELECT
                                    id_workflow_activity,
                                    id_workflow_activity_super,
                                    code_status,
                                    num_act_inst_idx
                                 FROM (SELECT
                                          id_workflow_activity,
                                          id_workflow_activity_super,
                                          code_status,
                                          ROW_NUMBER() OVER(PARTITION BY id_workflow_activity                             ORDER BY num_priority) AS num_act_inst_idx,
                                          ROW_NUMBER() OVER(PARTITION BY id_workflow_activity, id_workflow_activity_super ORDER BY num_priority) AS num_act_inst_super_idx
                                       FROM activity_instance_base
                                       )
                                 WHERE num_act_inst_super_idx = 1
                                 ),
           activity_shape_base AS (SELECT 
                                      sh.name_workflow_file,
                                      sh.id_workflow_activity_shape,
                                      sh.code_shape_type,
                                      sh.id_workflow_activity,
                                      CASE WHEN ais.id_workflow_activity_super IS NOT NULL THEN c_status_complete
                                           ELSE ai.code_status
                                      END AS code_status
                                   FROM owner_wfe.wf_tmp_shape sh
                                   LEFT JOIN activity_instance ai ON ai.id_workflow_activity = sh.id_workflow_activity
                                                                 AND ai.num_act_inst_idx = 1 
                                   LEFT JOIN activity_instance ais ON ais.id_workflow_activity_super = sh.id_workflow_activity
                                   ),
           activity_shape AS (SELECT
                                 sb.name_workflow_file,
                                 sb.id_workflow_activity_shape,
                                 sb.code_shape_type,
                                 sb.id_workflow_activity,
                                 sa.text_position_x,
                                 sa.text_position_y,
                                 sa.text_width,
                                 sa.text_height,
                                 CASE WHEN code_status = c_status_complete THEN 'rgb(67, 160, 71)'
                                      WHEN code_status = c_status_running  THEN 'rgb(30, 136, 229)'
                                      WHEN code_status = c_status_error    THEN 'rgb(229, 57, 53)'
                                      WHEN code_status = c_status_restart  THEN 'rgb(255, 225, 0)'
                                      WHEN code_status = c_status_skip     THEN 'rgb(255, 225, 0)'
                                      WHEN code_status = c_status_cancel   THEN 'rgb(251, 140, 0)'
                                      WHEN code_status = c_status_stuck    THEN 'rgb(142, 36, 170)'
                                      ELSE NULL
                                 END AS text_stroke_color,
                                 CASE WHEN code_status = c_status_complete THEN 'rgb(200, 230, 201)'
                                      WHEN code_status = c_status_running  THEN 'rgb(187, 222, 251)'
                                      WHEN code_status = c_status_error    THEN 'rgb(255, 205, 210)'
                                      WHEN code_status = c_status_restart  THEN 'rgb(255, 255, 201)'
                                      WHEN code_status = c_status_skip     THEN 'rgb(255, 255, 201)'
                                      WHEN code_status = c_status_cancel   THEN 'rgb(255, 224, 178)'
                                      WHEN code_status = c_status_stuck    THEN 'rgb(225, 190, 231)'
                                      ELSE NULL
                                 END AS text_fill_color,
                                 COUNT(1)     OVER(PARTITION BY sb.id_workflow_activity_shape)                                    AS cnt_row,
                                 ROW_NUMBER() OVER(PARTITION BY sb.id_workflow_activity_shape ORDER BY sa.num_position_order ASC) AS num_row
                              FROM activity_shape_base sb
                              LEFT JOIN owner_wfe.wf_tmp_shape_attr sa ON sa.id_workflow_activity_shape = sb.id_workflow_activity_shape
                              )
      SELECT
         name_workflow_file,
         id_workflow_activity_shape,
         code_shape_type,
         id_workflow_activity,
         text_position_x,
         text_position_y,
         text_width,
         text_height,
         text_stroke_color,
         text_fill_color,
         cnt_row,
         num_row
      FROM activity_shape
      ORDER BY code_shape_type DESC,
               id_workflow_activity_shape ASC,
               num_row ASC;
  
  BEGIN
  
    -- Loop through  activities
    FOR a_workflow_activity IN c_workflow_activity
    LOOP
           
      -- If it is shape       
      IF a_workflow_activity.code_shape_type = c_shape THEN
        
        -- Replace attributes
        v_diagram_element := REPLACE(c_shape_template,  '#ID_SHAPE#',    a_workflow_activity.id_workflow_activity_shape);
        v_diagram_element := REPLACE(v_diagram_element, '#ID_ACTIVITY#', a_workflow_activity.id_workflow_activity);
        v_diagram_element := REPLACE(v_diagram_element, '#X_POSITION#',  a_workflow_activity.text_position_x);
        v_diagram_element := REPLACE(v_diagram_element, '#Y_POSITION#',  a_workflow_activity.text_position_y);
        v_diagram_element := REPLACE(v_diagram_element, '#WIDTH#',       a_workflow_activity.text_width);
        v_diagram_element := REPLACE(v_diagram_element, '#HEIGHT#',      a_workflow_activity.text_height);
        IF a_workflow_activity.text_stroke_color IS NOT NULL AND a_workflow_activity.text_fill_color IS NOT NULL THEN
          v_diagram_element := REPLACE(v_diagram_element, '#COLOR#', ' bioc:stroke="'||a_workflow_activity.text_stroke_color||'" bioc:fill="'||a_workflow_activity.text_fill_color||'"');   
        ELSE                              
          v_diagram_element := REPLACE(v_diagram_element, '#COLOR#', '');
        END IF;
        
        -- Set diagram definition
        v_diagram_definition := v_diagram_definition||CHR(10)||v_diagram_element;
        
      -- Otherwise it is edge
      ELSE
        
        -- If it is first row for edge element then reset position
        IF a_workflow_activity.num_row = 1 THEN
          v_edge_position := NULL;
        END IF;
        
        -- Set edge position
        v_edge_position := v_edge_position||CHR(10)||'        <di:waypoint x="'||a_workflow_activity.text_position_x||'" y="'||a_workflow_activity.text_position_y||'" />';        
        
        -- If it is last row for edge element then set attributes
        IF a_workflow_activity.num_row = a_workflow_activity.cnt_row THEN
          v_diagram_element := REPLACE(c_edge_template, '#ID_SHAPE#', a_workflow_activity.id_workflow_activity_shape);
          v_diagram_element := REPLACE(v_diagram_element, '#ID_ACTIVITY#', a_workflow_activity.id_workflow_activity);
          v_diagram_element := REPLACE(v_diagram_element, '#EDGE_POSITION#', SUBSTR(v_edge_position, 10));
          IF a_workflow_activity.text_stroke_color IS NOT NULL AND a_workflow_activity.text_fill_color IS NOT NULL THEN
            v_diagram_element := REPLACE(v_diagram_element, '#COLOR#', ' bioc:stroke="'||a_workflow_activity.text_stroke_color||'" bioc:fill="'||a_workflow_activity.text_fill_color||'"');   
          ELSE                              
            v_diagram_element := REPLACE(v_diagram_element, '#COLOR#', '');
          END IF;          
        
          -- Set diagram definition
          v_diagram_definition := v_diagram_definition||CHR(10)||v_diagram_element;
          
        END IF;
        
      END IF;
    
    END LOOP; 
    
    -- Remove first line feed
    v_diagram_definition := SUBSTR(v_diagram_definition, 2);
    
    -- Set process workflow
    v_workflow_diagram := REPLACE(c_workflow_diagram_templ_begin, '#NAME_DIAGRAM#', p_name_workflow||'_di');
    v_workflow_diagram := REPLACE(v_workflow_diagram, '#ID_PLANE#', p_name_workflow||'_pl');
    v_workflow_diagram := REPLACE(v_workflow_diagram, '#NAME_WORKFLOW#', p_name_workflow);
    
    -- Due to a 32k limit i cannot use replace
    dbms_lob.append(v_workflow_diagram, CHR(10)||v_diagram_definition);
    dbms_lob.append(v_workflow_diagram, CHR(10)||c_workflow_diagram_templ_end);
    
    -- Return workflow diagram
    RETURN v_workflow_diagram;

  END gen_workflow_diagram;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: UPDATE_WORKFLOW_DIAGRAM
  -- purpose:        Update workflow diagram
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE update_workflow_diagram(p_text_workflow         IN OUT CLOB,
                                    p_text_workflow_diagram IN CLOB) IS

    v_text           CLOB;
    v_chunk_size     PLS_INTEGER := 32000;
    v_end_position   PLS_INTEGER;
    v_offset         PLS_INTEGER := 1;
    v_length         PLS_INTEGER;
    v_text_workflow  CLOB;

  BEGIN
    
    -- Get end position for workflow process (start position for workflow diagram)
    v_end_position := dbms_lob.instr(p_text_workflow,'<bpmndi:BPMNDiagram') -3;

    -- Create temporary lobs
    dbms_lob.createtemporary(v_text_workflow, TRUE);
    dbms_lob.createtemporary(v_text, TRUE);
    
    -- Loop throught lob and take only process part
    LOOP
     
      -- If end position is smaller then chunk size set new value of chunk size
      IF v_end_position <= v_chunk_size + v_offset THEN
        v_chunk_size := v_end_position - v_offset;
      END IF;
      
      -- Extract part of lob
      v_text := dbms_lob.substr(p_text_workflow, v_chunk_size, v_offset);
      v_length := LENGTH(v_text);
      v_offset := v_offset + v_length;

      -- Append data into new workflow lob
      dbms_lob.append(v_text_workflow, v_text);
      
      -- Exit when end position is smaller then chunk size with offset
      EXIT WHEN v_end_position <= v_offset;
      
    END LOOP;
    
    -- Append diagram
    dbms_lob.append(v_text_workflow, CHR(10)||p_text_workflow_diagram);
    
    -- Append end of definition
    v_text := CHR(10)||'</bpmn:definitions>';
    dbms_lob.append(v_text_workflow, v_text);
    
    -- Set result
    p_text_workflow := v_text_workflow;

  END update_workflow_diagram;  

  ---------------------------------------------------------------------------------------------------------
  -- function name: GET_WORKFLOW_LIST
  -- purpose:       Get workflow list for given main workflow process
  ---------------------------------------------------------------------------------------------------------  
  FUNCTION get_workflow_list(p_name_workflow IN VARCHAR2) RETURN tt_workflow_list IS
    
    c_proc_name             CONSTANT VARCHAR2(30) := 'GET_WORKFLOW_LIST';
    a_workflow_list         tt_workflow_list;
    
    CURSOR c_workflow_list IS
      WITH workflow AS (SELECT 
                           name_workflow         AS name_workflow,
                           NULL                  AS name_workflow_super,
                           p_name_workflow       AS text_path,
                           0                     AS num_level
                        FROM owner_wfe.wf_rep_definition
                        WHERE dtime_valid_to = c_date_future
                          AND name_workflow = p_name_workflow
                          
                          UNION
                          
                        SELECT
                           a.id_workflow_activity                                            AS name_workflow,
                           d.name_workflow                                                   AS name_workflow_super,
                           p_name_workflow||SYS_CONNECT_BY_PATH(a.id_workflow_activity, '/') AS text_path,
                           LEVEL                                                             AS num_level
                        FROM owner_wfe.wf_rep_definition d
                        JOIN owner_wfe.wf_rep_activity a ON a.id_workflow_definition = d.id_workflow_definition
                                                        AND a.code_activity_type = c_call_activity
                        WHERE d.dtime_valid_to = c_date_future
                        START WITH d.name_workflow = p_name_workflow
                        CONNECT BY PRIOR a.id_workflow_activity = d.name_workflow
                        )
      SELECT
         wfdef.id_workflow_definition,
         wf.name_workflow,
         wf.name_workflow_super,
         wf.text_path,
         wf.num_level,
         wfdef.num_version,
         CASE WHEN wfdef.dtime_valid_to = c_date_future THEN 'VALID'
              ELSE 'INVALID'
         END AS code_status,
         wfdef.dtime_valid_from,
         wfdef.dtime_valid_to,
         wfdep.user_inserted,
         wfdep.name_deployment
      FROM workflow wf
      JOIN owner_wfe.wf_rep_definition wfdef ON wfdef.name_workflow = wf.name_workflow
      JOIN owner_wfe.wf_rep_deployment wfdep ON wfdep.id_deployment = wfdef.id_deployment;
        
  BEGIN

    -- Get workflow list for given main workflow process
    -- Open cursor and fetch data
    OPEN c_workflow_list;
      FETCH c_workflow_list BULK COLLECT INTO a_workflow_list;
    CLOSE c_workflow_list;      
    
    -- Return result
    RETURN a_workflow_list;

  EXCEPTION
    WHEN OTHERS THEN
      -- Close cursor
      IF c_workflow_list%ISOPEN THEN CLOSE c_workflow_list; END IF;
      -- Set message
      v_text_message := 'Error in '||c_mod_name||'.'||c_proc_name||': '||SUBSTR(dbms_utility.format_error_stack, 1, 3000);
      -- Raise error
      raise_application_error(-20001, v_text_message);
  
  END get_workflow_list;
                          
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: GET_WORKFLOW
  -- purpose:        Get workflow definition
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE get_workflow(p_id_workflow_definition IN INTEGER DEFAULT NULL,
                         p_name_workflow          IN VARCHAR2 DEFAULT NULL,
                         p_text_workflow          OUT CLOB) IS
    
    c_proc_name             CONSTANT VARCHAR2(30) := 'GET_WORKFLOW';
    v_step                  VARCHAR2(256);
    v_name_workflow_file    VARCHAR2(255);
    v_text_workflow         XMLTYPE;
        
  BEGIN

    -- Get workflow file
    v_step := 'Get workflow file';
    get_workflow_file(p_id_workflow_definition => p_id_workflow_definition,
                      p_name_workflow          => p_name_workflow,
                      p_name_workflow_file     => v_name_workflow_file,
                      p_text_workflow          => v_text_workflow);
    
   
    -- Set result 
    p_text_workflow := v_text_workflow.getClobVal();

  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK; 
      -- Set message
      v_text_message := 'Error in '||c_mod_name||'.'||c_proc_name||' ('||v_step||'): '||SUBSTR(dbms_utility.format_error_stack, 1, 3000);
      -- Raise error
      raise_application_error(-20003, v_text_message);
      
  END get_workflow;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: GET_EXEC_WORKFLOW
  -- purpose:        Get executed workflow definition
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE get_exec_workflow(p_id_workflow_instance      IN INTEGER DEFAULT NULL,
                              p_id_workflow_activity_inst IN INTEGER DEFAULT NULL,                       
                              p_date_effective            IN DATE,
                              p_text_workflow             OUT CLOB) IS
    
    c_proc_name              CONSTANT VARCHAR2(30) := 'GET_EXEC_WORKFLOW';
    v_step                   VARCHAR2(256);
    
    v_code_result            VARCHAR2(30);
    v_text_message_clob      CLOB;
    v_id_workflow_instance   INTEGER;
    v_id_workflow_definition INTEGER;
    v_name_workflow          VARCHAR2(255);
    v_name_workflow_file     VARCHAR2(255);
    v_text_workflow          XMLTYPE;
    v_text_workflow_clob     CLOB;
    v_text_workflow_diagram  CLOB;

    ex_empty_input_param     EXCEPTION;
    ex_nonexistent_workflow  EXCEPTION;
    ex_parse_workflow        EXCEPTION;
    
  BEGIN

    -- Check if input parameters were provided
    v_step := 'Check if input parameters were provided';
    IF p_id_workflow_instance IS NULL AND p_id_workflow_activity_inst IS NULL THEN
      RAISE ex_empty_input_param;
    END IF;

    -- Get workflow version
    v_step := 'Get workflow version';
    BEGIN
      
      IF p_id_workflow_instance IS NOT NULL THEN
        
        -- Get executed workflow directly by its workflow instance
        SELECT
           id_workflow_definition,
           name_workflow
          INTO
           v_id_workflow_definition,
           v_name_workflow
        FROM owner_wfe.wf_hist_instance 
        WHERE id_workflow_instance = p_id_workflow_instance
          AND date_effective = p_date_effective;
          
        -- Set id workflow instance
        v_id_workflow_instance := p_id_workflow_instance;
          
      ELSE
        
        -- Get inferior executed workflow based on superior id workflow activity instance 
        SELECT 
           wfi.id_workflow_instance, 
           wfi.id_workflow_definition, 
           wfi.name_workflow
          INTO
           v_id_workflow_instance, 
           v_id_workflow_definition,
           v_name_workflow
        FROM owner_wfe.wf_hist_activity_instance wfai
        JOIN owner_wfe.wf_hist_instance wfi ON wfi.id_workflow_instance_main = wfai.id_workflow_instance_main
                                           AND wfi.id_workflow_instance_super = wfai.id_workflow_instance
                                           AND wfi.date_effective = wfai.date_effective
                                           AND wfi.name_Workflow = wfai.name_activity
        WHERE wfai.id_workflow_activity_instance = p_id_workflow_activity_inst
          AND wfai.date_effective = p_date_effective;
      
      END IF;
        
    EXCEPTION
      WHEN no_data_found THEN
        -- Raise exception
        RAISE ex_nonexistent_workflow;
        
    END;
    
    -- Get workflow file
    v_step := 'Get workflow file';
    get_workflow_file(p_id_workflow_definition => v_id_workflow_definition,
                      p_name_workflow_file     => v_name_workflow_file,
                      p_text_workflow          => v_text_workflow);
    
    -- Parse workflow diagram
    v_step := 'Parse workflow diagram';
    parse_workflow_diagram(p_name_workflow_file  => v_name_workflow_file,
                           p_text_workflow       => v_text_workflow,
                           p_code_result         => v_code_result,
                           p_text_message        => v_text_message_clob);
                                           
    -- In case of error during parsing dont proceeed and return message
    IF v_code_result = c_status_error THEN
      -- Raise error
      RAISE ex_parse_workflow;
    END IF;
                
    -- Generate workflow diagram
    v_step := 'Generate workflow diagram';
    v_text_workflow_diagram := gen_workflow_diagram(p_id_workflow_instance => v_id_workflow_instance,
                                                    p_date_effective       => p_date_effective,
                                                    p_name_workflow        => v_name_workflow);
                                                    
    -- Convert workflow text to clob
    v_step := 'Convert workflow text to clob';
    v_text_workflow_clob := v_text_workflow.getClobVal();
    
    -- Update worfklow diagram
    v_step := 'Update worfklow diagram';
    update_workflow_diagram(p_text_workflow         => v_text_workflow_clob,
                            p_text_workflow_diagram => v_text_workflow_diagram);

    -- Set result 
    p_text_workflow := v_text_workflow_clob;

  EXCEPTION
    WHEN ex_empty_input_param THEN
      -- Set message
      v_text_message := 'Input parameters were not provided. You need to set p_id_workflow_instance or p_id_workflow_activity_inst!';
      -- Raise error
      raise_application_error(-20004, v_text_message);
      
    WHEN ex_nonexistent_workflow THEN
      -- Set message
      v_text_message := 'Unable to found workflow version in repository!';
      -- Raise error
      raise_application_error(-20004, v_text_message);
      
    WHEN ex_parse_workflow THEN
      -- Set message
      v_text_message := 'Unable to parse workflow diagram: '||SUBSTR(v_text_message_clob, 1, 3000);
      -- Raise error
      raise_application_error(-20005, v_text_message);
      
    WHEN OTHERS THEN
      ROLLBACK; 
      -- Set message
      v_text_message := 'Error in '||c_mod_name||'.'||c_proc_name||' ('||v_step||'): '||SUBSTR(dbms_utility.format_error_stack, 1, 3000);
      -- Raise error
      raise_application_error(-20006, v_text_message);
      
  END get_exec_workflow;
  
END lib_wf_diagram_api;
/
