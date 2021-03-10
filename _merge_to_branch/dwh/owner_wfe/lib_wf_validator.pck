CREATE OR REPLACE PACKAGE owner_wfe.lib_wf_validator IS

  ---------------------------------------------------------------------------------------------------------
  -- author:  Ludek
  -- created: 14.05.2020
  -- purpose: Validate workflow files
  ---------------------------------------------------------------------------------------------------------

  ---------------------------------------------------------------------------------------------------------
  -- Global variables
  ---------------------------------------------------------------------------------------------------------
                                                  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: VALIDATE_WORKFLOW
  -- purpose:        Validate workflow files before deployment (check if everything is in place)       
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE validate_workflow(p_code_result  OUT VARCHAR2,
                              p_text_message OUT CLOB);
  
END lib_wf_validator;        
/
CREATE OR REPLACE PACKAGE BODY owner_wfe.lib_wf_validator IS

  ---------------------------------------------------------------------------------------------------------
  -- Global variables
  ---------------------------------------------------------------------------------------------------------  
  c_mod_name                CONSTANT VARCHAR2(30) := 'LIB_WF_VALIDATOR';
  c_status_complete         CONSTANT VARCHAR2(30) := owner_wfe.lib_wf_constant.c_complete;
  c_status_warning          CONSTANT VARCHAR2(30) := owner_wfe.lib_wf_constant.c_warning;
  c_status_error            CONSTANT VARCHAR2(30) := owner_wfe.lib_wf_constant.c_error;
  c_int_status_complete     CONSTANT INTEGER := owner_wfe.lib_wf_constant.c_int_complete;
  c_int_status_warning      CONSTANT INTEGER := owner_wfe.lib_wf_constant.c_int_warning;
  c_int_status_error        CONSTANT INTEGER := owner_wfe.lib_wf_constant.c_int_error;
  c_xap                     CONSTANT VARCHAR2(10) := owner_wfe.lib_wf_constant.c_xap;
  
  -- Workflow main element type
  c_process                 CONSTANT VARCHAR2(100) := owner_wfe.lib_wf_constant.c_process;
  c_diagram                 CONSTANT VARCHAR2(100) := owner_wfe.lib_wf_constant.c_diagram;

  -- Workflow activity type
  c_start_event             CONSTANT VARCHAR2(100) := owner_wfe.lib_wf_constant.c_start_event;
  c_end_event               CONSTANT VARCHAR2(100) := owner_wfe.lib_wf_constant.c_end_event;
  c_wait_event              CONSTANT VARCHAR2(100) := owner_wfe.lib_wf_constant.c_wait_event;
  c_sequence_flow           CONSTANT VARCHAR2(100) := owner_wfe.lib_wf_constant.c_sequence_flow;
  c_parallel_gateway        CONSTANT VARCHAR2(100) := owner_wfe.lib_wf_constant.c_parallel_gateway;
  c_inclusive_gateway       CONSTANT VARCHAR2(100) := owner_wfe.lib_wf_constant.c_inclusive_gateway;
  c_receive_task            CONSTANT VARCHAR2(100) := owner_wfe.lib_wf_constant.c_receive_task;
  c_call_activity           CONSTANT VARCHAR2(100) := owner_wfe.lib_wf_constant.c_call_activity;
  
  -- Workflow activity attribute type
  c_outgoing_attr           CONSTANT VARCHAR2(100) := owner_wfe.lib_wf_constant.c_outgoing_attr;
  c_incoming_attr           CONSTANT VARCHAR2(100) := owner_wfe.lib_wf_constant.c_incoming_attr;
  c_timer_definition_attr   CONSTANT VARCHAR2(100) := owner_wfe.lib_wf_constant.c_timer_definition_attr;
  c_timer_duration_attr     CONSTANT VARCHAR2(100) := owner_wfe.lib_wf_constant.c_timer_duration_attr;
  c_extension_elements_attr CONSTANT VARCHAR2(100) := owner_wfe.lib_wf_constant.c_extension_elements_attr;
  c_input_output_attr       CONSTANT VARCHAR2(100) := owner_wfe.lib_wf_constant.c_input_output_attr;
  c_input_parameter_attr    CONSTANT VARCHAR2(100) := owner_wfe.lib_wf_constant.c_input_parameter_attr;
  c_condition_expression    CONSTANT VARCHAR2(100) := owner_wfe.lib_wf_constant.c_condition_expression;
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: get_code_result
  -- purpose:        Get code result
  ---------------------------------------------------------------------------------------------------------  
  FUNCTION get_code_result(p_int_result IN INTEGER) RETURN VARCHAR2
  IS
    
  BEGIN
    
    IF p_int_result = c_int_status_error THEN
      RETURN c_status_error;
    ELSIF p_int_result = c_int_status_warning THEN
      RETURN c_status_warning;
    ELSE
      RETURN c_status_complete;
    END IF;    

  END get_code_result;
 
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CHECK_BASIC_RULES
  -- purpose:        Check basic rules for workflow processes      
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE check_basic_rules(p_code_result  OUT VARCHAR2,
                              p_text_message OUT CLOB)
  IS
 
    c_proc_name    CONSTANT VARCHAR2(30) := 'CHECK_BASIC_RULES';  
    v_step         VARCHAR2(256);
    v_code_result  VARCHAR2(30);
    v_text_message CLOB;

    CURSOR c_unsup_main_elemenet_type IS
      SELECT 
        DISTINCT
         name_workflow_file,
         code_main_element_type 
      FROM owner_wfe.wf_tmp_definition
      WHERE code_main_element_type NOT IN (c_process,
                                           c_diagram);
    
    CURSOR c_unsup_activity_type IS
      SELECT 
        DISTINCT
         name_workflow_file,
         code_activity_type 
      FROM owner_wfe.wf_tmp_activity 
      WHERE code_activity_type NOT IN (c_start_event,
                                      c_end_event,
                                      c_wait_event,
                                      c_sequence_flow,
                                      c_parallel_gateway,
                                      c_inclusive_gateway,
                                      c_receive_task,
                                      c_call_activity);
                                      
    CURSOR c_unsup_activity_attr_type IS
      SELECT 
        DISTINCT
         name_workflow_file,
         code_activity_type,
         id_workflow_activity,
         code_attribute_type
      FROM owner_wfe.wf_tmp_activity_attr
      WHERE (code_activity_type = c_start_event       AND code_attribute_type NOT IN (c_outgoing_attr))
         OR (code_activity_type = c_end_event         AND code_attribute_type NOT IN (c_incoming_attr))
         OR (code_activity_type = c_wait_event        AND code_attribute_type NOT IN (c_incoming_attr, c_outgoing_attr, c_timer_definition_attr, c_timer_duration_attr))
         OR (code_activity_type = c_sequence_flow     AND code_attribute_type NOT IN (c_incoming_attr, c_outgoing_attr, c_condition_expression))
         OR (code_activity_type = c_parallel_gateway  AND code_attribute_type NOT IN (c_incoming_attr, c_outgoing_attr))
         OR (code_activity_type = c_inclusive_gateway AND code_attribute_type NOT IN (c_incoming_attr, c_outgoing_attr))
         OR (code_activity_type = c_call_activity     AND code_attribute_type NOT IN (c_incoming_attr, c_outgoing_attr))
         OR (code_activity_type = c_receive_task      AND code_attribute_type NOT IN (c_incoming_attr, c_outgoing_attr, c_extension_elements_attr, c_input_output_attr, c_input_parameter_attr));
       
    CURSOR c_process_main_element IS
      SELECT 
         name_workflow_file,
         id_workflow_definition,
         id_main_element,
         name_main_element 
      FROM owner_wfe.wf_tmp_definition
      WHERE code_main_element_type = c_process
        AND (REPLACE(name_workflow_file, '.bpmn', '') != id_main_element
             OR id_workflow_definition != 'WF_'||id_main_element
             OR id_main_element != name_main_element
             OR name_main_element IS NULL);

    CURSOR c_diagram_main_element IS
      SELECT 
         name_workflow_file,
         id_workflow_definition,
         id_main_element
      FROM owner_wfe.wf_tmp_definition
      WHERE code_main_element_type = c_diagram
        AND (REPLACE(name_workflow_file, '.bpmn', '')||'_di' != id_main_element
             OR id_workflow_definition||'_di' != 'WF_'||id_main_element);

  BEGIN
  
    -- Set result to default
    v_code_result := c_status_complete; 
    
    -- Check existence of unsupported main element type
    v_step := 'Check existence of unsupported main element type';
    FOR i IN c_unsup_main_elemenet_type
    LOOP
      
      -- Set result
      v_code_result := c_status_error;
      
      -- Set message
      v_text_message := v_text_message||CHR(10)||c_status_error||' - '||'Process '||i.name_workflow_file||' contains unsupported main element type '||i.code_main_element_type||'!';
    
    END LOOP;
  
    -- Check existence of unsupported activity type
    v_step := 'Check existence of unsupported activity type';
    FOR i IN c_unsup_activity_type
    LOOP
      
      -- Set result
      v_code_result := c_status_error;
      
      -- Set message
      v_text_message := v_text_message||CHR(10)||c_status_error||' - '||'Process '||i.name_workflow_file||' contains unsupported activity type '||i.code_activity_type||'!';
    
    END LOOP;

    -- Check existence of unsupported activity attribute type
    v_step := 'Check existence of unsupported activity attribute type';
    FOR i IN c_unsup_activity_attr_type
    LOOP
      
      -- Set result
      v_code_result := c_status_error;
      
      -- Set message
      v_text_message := v_text_message||CHR(10)||c_status_error||' - '||'Process activity '||i.code_activity_type||' (id - "'||i.id_workflow_activity||'" in workflow process '||i.name_workflow_file||' contains unsupported attribute type '||i.code_attribute_type||'!';
    
    END LOOP;
    
    -- Check if workflow name, process id and process name are same
    v_step := 'Check if workflow name, definition id, process id and process name are same';
    FOR i IN c_process_main_element
    LOOP
      
      -- Set result
      v_code_result := c_status_error;
      
      -- Set message
      v_text_message := v_text_message||CHR(10)||c_status_error||' - '||'Process main element (id - "'||i.id_main_element||'") in workflow process "'||i.name_workflow_file||'" doesn''t have same "root" value in process id - "'||i.id_main_element||'", process name - "'||i.name_main_element||'", definition id - "'||i.id_workflow_definition||'" and workflow name - "'||i.name_workflow_file||'"!';

    END LOOP;
    
    -- Check if workflow name, definition id and diagram id are same
    v_step := 'Check if workflow name, definition id and diagram id are same';
    FOR i IN c_diagram_main_element
    LOOP
      
      -- Set result
      v_code_result := c_status_error;
      
      -- Set message
      v_text_message := v_text_message||CHR(10)||c_status_error||' - '||'Diagram main element (id - "'||i.id_main_element||'") in workflow process "'||i.name_workflow_file||'" doesn''t have same "root" value in diagram id - "'||i.id_main_element||'", definition id - "'||i.id_workflow_definition||'" and workflow name - "'||i.name_workflow_file||'"!';

    END LOOP;
    
    -- Set result to output
    v_step := 'Set result to output';
    p_code_result := v_code_result;
    IF v_text_message IS NOT NULL THEN
      v_text_message := 'Check for basic rules found following issues:'||v_text_message;
      p_text_message := v_text_message;
    END IF;
  
  EXCEPTION
    WHEN OTHERS THEN
      -- Set result
      p_code_result := c_status_error;
      -- Set message
      p_text_message := 'Error in '||c_mod_name||'.'||c_proc_name||' - ('||v_step||'): '||SUBSTR(dbms_utility.format_error_stack, 1, 1500);
      
  END check_basic_rules; 

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CHECK_NAMING_CONVENTION
  -- purpose:        Check naming conventions
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE check_naming_convention(p_name_workflow_file   IN VARCHAR2,
                                    p_code_activity_type   IN VARCHAR2,
                                    p_id_workflow_activity IN VARCHAR2,
                                    p_name_activity        IN VARCHAR2,
                                    p_id_workflow_called   IN VARCHAR2 DEFAULT c_xap,               
                                    p_int_result           OUT INTEGER,
                                    p_text_message         OUT VARCHAR2)
  IS

  BEGIN
    
    -- Set default result
    p_int_result := c_int_status_complete;
    
    -- Check naming rules -> id and name must have same value
    IF (p_id_workflow_activity != p_name_activity OR p_name_activity IS NULL) THEN
      
      -- Set result
      p_int_result := c_int_status_error;
    
      -- Set message
      p_text_message := p_text_message||CHR(10)||c_status_error||' - '||p_code_activity_type||' activity (id - "'||p_id_workflow_activity||'") in workflow process "'||p_name_workflow_file||'" doesn''t have same value in id - "'||
                          p_id_workflow_activity||'" and name - "'||p_name_activity||'"!';
    
    END IF;
    
    -- Check naming rules -> id and id workflow called must have same value 
    IF (p_id_workflow_activity != p_id_workflow_called OR p_id_workflow_called IS NULL) AND p_code_activity_type = c_call_activity THEN
      
      -- Set result
      p_int_result := c_int_status_error;
    
      -- Set message
      p_text_message := p_text_message||CHR(10)||c_status_error||' - '||p_code_activity_type||' activity (id - "'||p_id_workflow_activity||'") in workflow process "'||p_name_workflow_file||'" doesn''t have same value in id - "'||
                          p_id_workflow_activity||'" and calledElement - "'||p_id_workflow_called||'"!';
    
    END IF;  

  END check_naming_convention;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CHECK_TRANSITION
  -- purpose:        Check transitions
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE check_transition(p_name_workflow_file   IN VARCHAR2,
                             p_code_activity_type   IN VARCHAR2,
                             p_id_workflow_activity IN VARCHAR2,
                             p_cnt_incoming_trans   IN INTEGER,
                             p_cnt_outgoing_trans   IN INTEGER,
                             p_int_result           OUT INTEGER,
                             p_text_message         OUT VARCHAR2)
  IS
        
  BEGIN

    -- Set default result
    p_int_result := c_int_status_complete;

    -- Check 0 incoming transition
    IF p_cnt_incoming_trans = 0 AND p_code_activity_type IN (c_call_activity, c_receive_task, c_parallel_gateway, c_inclusive_gateway, c_end_event, c_wait_event) THEN
      
      -- Set result
      p_int_result := c_int_status_error;

      -- Set message
      p_text_message := p_text_message||CHR(10)||c_status_error||' - '||p_code_activity_type||' activity (id - "'||p_id_workflow_activity||'") in workflow process "'||p_name_workflow_file||'" is not connected properly, it is missing incoming transition (Incoming transition - '||TO_CHAR(p_cnt_incoming_trans)||')!';
    
    END IF;

    -- Check 0 outgoing transition
    IF p_cnt_outgoing_trans = 0 AND p_code_activity_type IN (c_call_activity, c_receive_task, c_parallel_gateway, c_inclusive_gateway, c_start_event, c_wait_event) THEN
      
      -- Set result
      p_int_result := c_int_status_error;

      -- Set message
      p_text_message := p_text_message||CHR(10)||c_status_error||' - '||p_code_activity_type||' activity (id - "'||p_id_workflow_activity||'") in workflow process "'||p_name_workflow_file||'" is not connected properly, it is missing outgoing transition (Outgoing transition - '||TO_CHAR(p_cnt_outgoing_trans)||')!';

    END IF;

    -- Check more then 1 incoming transition
    IF p_cnt_incoming_trans > 1 AND p_code_activity_type IN (c_call_activity, c_receive_task, c_end_event, c_wait_event) THEN

      -- Set result
      p_int_result := c_int_status_error;

      -- Set message
      p_text_message := p_text_message||CHR(10)||c_status_error||' - '||p_code_activity_type||' activity (id - "'||p_id_workflow_activity||'") in workflow process "'||p_name_workflow_file||'" is not connected properly, it has more then one incoming transition (Incoming transitions - '||TO_CHAR(p_cnt_incoming_trans)||')!';

    END IF;

    -- Check more then 1 outgoing transition
    IF p_cnt_outgoing_trans > 1 AND p_code_activity_type IN (c_wait_event) THEN

      -- Set result
      p_int_result := c_int_status_error;

      -- Set message
      p_text_message := p_text_message||CHR(10)||c_status_error||' - '||p_code_activity_type||' activity (id - "'||p_id_workflow_activity||'") in workflow process "'||p_name_workflow_file||'" is not connected properly, it has more then one outgoing transition (Outgoing transitions - '||TO_CHAR(p_cnt_outgoing_trans)||')!';
                          
    END IF;
   
  END check_transition;
 
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CHECK_ASYNC_OPTION
  -- purpose:        Check asynchronous option
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE check_async_option(p_name_workflow_file   IN VARCHAR2,
                               p_code_activity_type   IN VARCHAR2,
                               p_id_workflow_activity IN VARCHAR2,
                               p_text_async_before    IN INTEGER,
                               p_text_async_after     IN INTEGER,
                               p_int_result           OUT INTEGER,
                               p_text_message         OUT VARCHAR2)
  IS

  BEGIN
 
    -- Set default result
    p_int_result := c_int_status_complete;
 
    IF p_text_async_before IS NOT NULL OR p_text_async_after IS NOT NULL THEN
      
      -- Set result
      p_int_result := c_int_status_error;

      -- Set message
      p_text_message := p_text_message||CHR(10)||c_status_error||' - '||p_code_activity_type||' activity (id - "'||p_id_workflow_activity||'") in workflow process "'||p_name_workflow_file||'" has enabled asynchronous option (Value of attribute Asynchronouse Before - "'||p_text_async_before||'" and Asynchronouse After - "'||p_text_async_after||'" -> you need to uncheck it in modeler)!';
                          
    END IF;

  END check_async_option;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CHECK_CALL_ACTIVITY
  -- purpose:        Check call activity activity
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE check_call_activity(p_code_result  OUT VARCHAR2,
                                p_text_message OUT CLOB)
  IS
 
    c_proc_name        CONSTANT VARCHAR2(30) := 'CHECK_CALL_ACTIVITY';  
    v_step             VARCHAR2(256);
    v_int_result       INTEGER;
    v_int_result_tmp   INTEGER;
    v_text_message     CLOB;
    v_text_message_tmp VARCHAR2(32000);
    
    CURSOR c_call_activity_activity IS
      SELECT 
         e.name_workflow_file,
         e.code_activity_type,
         e.id_workflow_activity,
         e.name_activity,
         e.id_workflow_called,
         e.text_variable_mapping_class,
         e.text_async_before,
         e.text_async_after,
         SUM(CASE WHEN ea.code_attribute_type = c_incoming_attr THEN 1 ELSE 0 END) AS cnt_incoming_trans,
         SUM(CASE WHEN ea.code_attribute_type = c_outgoing_attr THEN 1 ELSE 0 END) AS cnt_outgoing_trans
      FROM owner_wfe.wf_tmp_activity e
      LEFT JOIN owner_wfe.wf_tmp_activity_attr ea ON ea.name_workflow_file = e.name_workflow_file 
                                                 AND ea.id_workflow_activity = e.id_workflow_activity
                                                 AND ea.code_activity_type = c_call_activity
                                                 AND ea.code_attribute_type IN (c_incoming_attr, c_outgoing_attr)
      WHERE e.code_activity_type = c_call_activity
      GROUP BY e.name_workflow_file,
               e.code_activity_type,
               e.id_workflow_activity,
               e.name_activity,
               e.id_workflow_called,
               e.text_variable_mapping_class,
               e.text_async_before,
               e.text_async_after;
      
    CURSOR c_workflow_list IS
      SELECT
         id_main_element AS name_workflow
      FROM owner_wfe.wf_tmp_definition
      WHERE code_main_element_type = c_process
       UNION 
      SELECT 
         id_workflow     AS name_workflow
      FROM owner_wfe.wf_rep_definition;

    TYPE t_workflow_list IS TABLE OF VARCHAR2(255);
    a_workflow_list      t_workflow_list; 
    
  BEGIN
  
    -- Set result to default
    v_int_result := c_int_status_complete; 
    
    -- Open cursor with workflow information and fetch data into array
    v_step := 'Open cursor with workflow information and fetch data into array';
    OPEN c_workflow_list;
      FETCH c_workflow_list BULK COLLECT INTO a_workflow_list;
    CLOSE c_workflow_list;
  
    -- Check call activity activity
    v_step := 'Check call activity activity';
    FOR i IN c_call_activity_activity
    LOOP
      
      -- Check naming rules -> id, name and calledElement must have same value
      v_step := 'Check naming rules -> id, name and calledElement must have same value';
      check_naming_convention(p_name_workflow_file   => i.name_workflow_file,
                              p_code_activity_type   => i.code_activity_type,
                              p_id_workflow_activity => i.id_workflow_activity,
                              p_name_activity        => i.name_activity,
                              p_id_workflow_called   => i.id_workflow_called,               
                              p_int_result           => v_int_result_tmp,
                              p_text_message         => v_text_message_tmp);

      -- Set int result                    
      v_int_result := GREATEST(v_int_result, v_int_result_tmp);
          
      -- Set text message                    
      IF v_text_message_tmp IS NOT NULL THEN
        v_text_message := v_text_message||v_text_message_tmp;
      END IF;                        
      
      -- Check incoming/outgoing transitions
      v_step := 'Check incoming/outgoing transitions';
      check_transition(p_name_workflow_file   => i.name_workflow_file,
                       p_code_activity_type   => i.code_activity_type,
                       p_id_workflow_activity => i.id_workflow_activity,
                       p_cnt_incoming_trans   => i.cnt_incoming_trans,
                       p_cnt_outgoing_trans   => i.cnt_outgoing_trans,
                       p_int_result           => v_int_result_tmp,
                       p_text_message         => v_text_message_tmp);

      -- Set int result                    
      v_int_result := GREATEST(v_int_result, v_int_result_tmp);
      
      -- Set text message                    
      IF v_text_message_tmp IS NOT NULL THEN
        v_text_message := v_text_message||v_text_message_tmp;
      END IF;   
      
      -- Check async options
      v_step := 'Check async option';
      check_async_option(p_name_workflow_file   => i.name_workflow_file,
                         p_code_activity_type   => i.code_activity_type,
                         p_id_workflow_activity => i.id_workflow_activity,
                         p_text_async_before    => i.text_async_before,
                         p_text_async_after     => i.text_async_after,
                         p_int_result           => v_int_result_tmp,
                         p_text_message         => v_text_message_tmp);
           
      -- Set int result                    
      v_int_result := GREATEST(v_int_result, v_int_result_tmp);

      -- Set text message                    
      IF v_text_message_tmp IS NOT NULL THEN
        v_text_message := v_text_message||v_text_message_tmp;
      END IF;   
      
      -- Check value of variableMappingClass
      v_step := 'Check value of variableMappingClass';
      IF i.text_variable_mapping_class IS NULL
         OR i.text_variable_mapping_class != 'net.homecredit.cn.dwh.service.VariableMapper' THEN
     
        -- Set result
        v_int_result := c_int_status_error;
        
        -- Set message
        v_text_message := v_text_message||CHR(10)||c_status_error||' - '||i.code_activity_type||' activity (id - "'||i.id_workflow_activity||'") in workflow process "'||i.name_workflow_file||'" doesn''t have correct value in variableMappingClass - "'||
                            i.text_variable_mapping_class||'". Correct value is only "net.homecredit.cn.dwh.service.VariableMapper"!';
      
      END IF;
      
      -- Check if called element (workflow process) is in repository or in this deployment
      v_step := 'Check if called element (workflow process) is in repository or in this deployment';
      IF i.id_workflow_called IS NOT NULL THEN
       
        IF i.id_workflow_called MEMBER OF a_workflow_list THEN 
          
          NULL;
          
        ELSE
          
          -- Set result
          v_int_result := c_int_status_error;
          
          -- Set message
          v_text_message := v_text_message||CHR(10)||c_status_error||' - '||i.code_activity_type||' activity (id - "'||i.id_workflow_activity||'") in workflow process "'||i.name_workflow_file||'" cannot call workflow process "'||i.id_workflow_called||'"! Such workflow process is neither part of this deployement nor in the database repository!'; 
                        
        END IF;  
            
      END IF;
 
    END LOOP; 
    
    -- Set result to output
    v_step := 'Set result to output';
    p_code_result := get_code_result(v_int_result);
    IF v_text_message IS NOT NULL THEN
      v_text_message := 'Check for call activity activity found following issues:'||v_text_message;
      p_text_message := v_text_message;
    END IF;
      
  EXCEPTION
    WHEN OTHERS THEN
      -- Close cursor
      IF c_workflow_list%ISOPEN THEN CLOSE c_workflow_list; END IF;
      -- Set result
      p_code_result := c_status_error;
      -- Set message
      p_text_message := 'Error in '||c_mod_name||'.'||c_proc_name||' - ('||v_step||'): '||SUBSTR(dbms_utility.format_error_stack, 1, 1500);
      
  END check_call_activity;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CHECK_RECEIVE_TASK
  -- purpose:        Check recieve task activity
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE check_receive_task(p_code_result  OUT VARCHAR2,
                               p_text_message OUT CLOB)
  IS
 
    c_proc_name        CONSTANT VARCHAR2(30) := 'CHECK_RECEIVE_TASK';  
    v_step             VARCHAR2(256);
    v_int_result       INTEGER;
    v_int_result_tmp   INTEGER;
    v_text_message     CLOB;
    v_text_message_tmp VARCHAR2(32000);
    
    CURSOR c_receive_task_activity IS
      SELECT 
         e.name_workflow_file,
         e.code_activity_type,
         e.id_workflow_activity,
         e.name_activity,
         e.text_async_before,
         e.text_async_after,
         SUM(CASE WHEN ea.code_attribute_type = c_incoming_attr  THEN 1                    ELSE 0    END) AS cnt_incoming_trans,
         SUM(CASE WHEN ea.code_attribute_type = c_outgoing_attr  THEN 1                    ELSE 0    END) AS cnt_outgoing_trans,
         SUM(CASE WHEN ea.code_attribute_type = 'inputParameter' THEN 1                    ELSE 0    END) AS cnt_parameter,
         SUM(CASE WHEN ea.name_attribute      = 'MODULE_NAME'    THEN 1                    ELSE 0    END) AS cnt_parameter_mod_name,
         SUM(CASE WHEN ea.name_attribute      = 'DATA_TYPE'      THEN 1                    ELSE 0    END) AS cnt_parameter_data_type,
         MAX(CASE WHEN ea.name_attribute      = 'MODULE_NAME'    THEN text_attribute_value ELSE NULL END) AS name_module
      FROM owner_wfe.wf_tmp_activity e 
      LEFT JOIN owner_wfe.wf_tmp_activity_attr ea ON ea.name_workflow_file = e.name_workflow_file 
                                                 AND ea.id_workflow_activity = e.id_workflow_activity
                                                 AND ea.code_activity_type = c_receive_task
                                                 AND ea.code_attribute_type IN (c_input_parameter_attr, c_incoming_attr, c_outgoing_attr)
      WHERE e.code_activity_type = c_receive_task
      GROUP BY e.name_workflow_file,
               e.code_activity_type,
               e.id_workflow_activity,
               e.name_activity,
               e.text_async_before,
               e.text_async_after
      ORDER BY e.name_workflow_file,
               e.id_workflow_activity;
               
    CURSOR c_module_list IS
      SELECT
         name_module
      FROM owner_wfm.etl_module;
      
    TYPE t_module_list   IS TABLE OF VARCHAR2(80);
    a_module_list        t_module_list; 
    
  BEGIN
  
    -- Set result to default
    v_int_result := c_int_status_complete; 
    
    -- Open cursor with module information and fetch data into array
    v_step := 'Open cursor with module information and fetch data into array';
    OPEN c_module_list;
      FETCH c_module_list BULK COLLECT INTO a_module_list;
    CLOSE c_module_list;

    -- Check receive task activity
    v_step := 'Check receive task activity';
    FOR i IN c_receive_task_activity
    LOOP
      
      -- Check naming rules -> id and name must have same value
      v_step := 'Check naming rules -> id and name must have same value';
      check_naming_convention(p_name_workflow_file   => i.name_workflow_file,
                              p_code_activity_type   => i.code_activity_type,
                              p_id_workflow_activity => i.id_workflow_activity,
                              p_name_activity        => i.name_activity,
                              p_int_result           => v_int_result_tmp,
                              p_text_message         => v_text_message_tmp);

      -- Set int result                    
      v_int_result := GREATEST(v_int_result, v_int_result_tmp);
          
      -- Set text message                    
      IF v_text_message_tmp IS NOT NULL THEN
        v_text_message := v_text_message||v_text_message_tmp;
      END IF;                        
      
      -- Check incoming/outgoing transitions
      v_step := 'Check incoming/outgoing transitions';
      check_transition(p_name_workflow_file   => i.name_workflow_file,
                       p_code_activity_type   => i.code_activity_type,
                       p_id_workflow_activity => i.id_workflow_activity,
                       p_cnt_incoming_trans   => i.cnt_incoming_trans,
                       p_cnt_outgoing_trans   => i.cnt_outgoing_trans,
                       p_int_result           => v_int_result_tmp,
                       p_text_message         => v_text_message_tmp);

      -- Set int result                    
      v_int_result := GREATEST(v_int_result, v_int_result_tmp);
      
      -- Set text message                    
      IF v_text_message_tmp IS NOT NULL THEN
        v_text_message := v_text_message||v_text_message_tmp;
      END IF;   
      
      -- Check async options
      v_step := 'Check async option';
      check_async_option(p_name_workflow_file   => i.name_workflow_file,
                         p_code_activity_type   => i.code_activity_type,
                         p_id_workflow_activity => i.id_workflow_activity,
                         p_text_async_before    => i.text_async_before,
                         p_text_async_after     => i.text_async_after,
                         p_int_result           => v_int_result_tmp,
                         p_text_message         => v_text_message_tmp);
           
      -- Set int result                    
      v_int_result := GREATEST(v_int_result, v_int_result_tmp);

      -- Set text message                    
      IF v_text_message_tmp IS NOT NULL THEN
        v_text_message := v_text_message||v_text_message_tmp;
      END IF;
      
      -- Check correct number of input parameters
      v_step := 'Check correct number of input parameters';
      IF i.cnt_parameter != 2 THEN
        
        -- Set result
        v_int_result := c_int_status_error;
      
        -- Set message
        v_text_message := v_text_message||CHR(10)||c_status_error||' - '||i.code_activity_type||' activity (id - "'||i.id_workflow_activity||'") in workflow process "'||i.name_workflow_file||'" doesn''t have correct number of input parameters! Count of input parameters is - "'||i.cnt_parameter||'", correct is - 2!';
                            
      END IF; 
      
      -- Check parameter module name
      v_step := 'Check parameter module name';
      IF i.cnt_parameter_mod_name < 1 THEN
        
        -- Set result
        v_int_result := c_int_status_error;
      
        -- Set message
        v_text_message := v_text_message||CHR(10)||c_status_error||' - '||i.code_activity_type||' activity (id - "'||i.id_workflow_activity||'") in workflow process "'||i.name_workflow_file||'" doesn''t have input parameter "MODULE_NAME"!';

       ELSIF i.cnt_parameter_mod_name = 1 THEN
         
         -- If value of parameter module name
         IF i.name_module IS NOT NULL THEN
           
           -- If name module is not in etl modules 
           IF i.name_module MEMBER OF a_module_list THEN
             
             NULL;
             
           ELSE
             
             -- Set result
             IF v_int_result = c_int_status_complete THEN
               v_int_result := c_int_status_warning;
             END IF;
             
             -- Set message
             v_text_message := v_text_message||CHR(10)||c_status_warning||' - '||i.code_activity_type||' activity (id - "'||i.id_workflow_activity||'") in workflow process "'||i.name_workflow_file||'" doesn''t have corresponding value for input parameter "MODULE_NAME" in table owner_wfm.etl_module. Module name is - "'||i.name_module||'"';
             
           END IF;
           
           -- If name module doesnt have same name with name activity without suffix (with exception of ignored modules where its name and name of element doesnt match)
           IF i.name_module != SUBSTR(i.name_activity, 1, LENGTH(i.name_module))
             AND i.name_module NOT IN (-- Start process
                                       'START_PROCESS',
                                       -- Notification
                                       'REFRESH_AND_NOTIFY_ALL',
                                       'NOTIFY_ALL',
                                       'NOTIFY_SINGLE_OBJECT',
                                       -- Transfer
                                       'REMOTE_TRANSFER_PROCESS_EVENTS',
                                       'REMOTE_TRANSFER_MV_INCR_GRP',
                                       'PREPROD_COPY_PROC_METADATA',
                                       -- Table replication
                                       'TRU_RUN_REFRESH_GROUP',
                                       'TRU_SKIP_OLD_RECORDS_GROUP',
                                       'TRU_GATHER_STATISTICS_ALL',
                                       -- Mview replication
                                       'MVIEW_UTILS_REFRESH_GROUP',
                                       'MVIEW_UTILS_SKIP_REC_GROUP',
                                       'MV_PURGE_GRP_OPR',
                                       -- IDI
                                       'REFERENCE_GROUP_RUN_PAR_GROUPS') THEN
                                       
             -- Set result
             v_int_result := c_int_status_error;
             
             -- Set message
             v_text_message := v_text_message||CHR(10)||c_status_error||' - '||i.code_activity_type||' activity (id - "'||i.id_workflow_activity||'") in workflow process "'||i.name_workflow_file||'" doesn''t have same value in name without suffix ("'||SUBSTR(i.name_activity, 1, LENGTH(i.name_module))||'") and input parameter "MODULE_NAME" - "'||i.name_module||'".';             
           
           END IF;
           
         ELSE
           
           -- Set result
           v_int_result := c_int_status_error;
           
           -- Set message
           v_text_message := v_text_message||CHR(10)||c_status_error||' - '||i.code_activity_type||' activity (id - "'||i.id_workflow_activity||'") in workflow process "'||i.name_workflow_file||'" doesn''t have value in input parameter "MODULE_NAME"!';
           
         
         END IF;
       
       ELSE

          -- Set message
          v_text_message := v_text_message||CHR(10)||c_status_error||' - '||i.code_activity_type||' activity (id - "'||i.id_workflow_activity||'") in workflow process "'||i.name_workflow_file||'" has more then one input parameter with name "MODULE_NAME"!';         
                           
      END IF; 
      
      -- Check parameter data type
      v_step := 'Check parameter data type';
      IF i.cnt_parameter_data_type != 1 THEN
        
        -- Set result
        v_int_result := c_int_status_error;
      
        IF i.cnt_parameter_data_type < 1 THEN
      
          -- Set message
          v_text_message := v_text_message||CHR(10)||c_status_error||' - '||i.code_activity_type||' activity (id - "'||i.id_workflow_activity||'") in workflow process "'||i.name_workflow_file||'" doesn''t have input parameter "DATA_TYPE"!';
         
        ELSE
          
          -- Set message
          v_text_message := v_text_message||CHR(10)||c_status_error||' - '||i.code_activity_type||' activity (id - "'||i.id_workflow_activity||'") in workflow process "'||i.name_workflow_file||'" has more then one input parameter with name "DATA_TYPE"!';         
        
        END IF;
                           
      END IF; 
 
    END LOOP; 
    
    -- Set result to output
    v_step := 'Set result to output';
    p_code_result := get_code_result(v_int_result);
    IF v_text_message IS NOT NULL THEN
      v_text_message := 'Check for receive task activity found following issues:'||v_text_message;
      p_text_message := v_text_message;
    END IF;
  
  EXCEPTION
    WHEN OTHERS THEN
      -- Close cursor
      IF c_module_list%ISOPEN THEN CLOSE c_module_list; END IF;
      -- Set result
      p_code_result := c_status_error;
      -- Set message
      p_text_message := 'Error in '||c_mod_name||'.'||c_proc_name||' - ('||v_step||'): '||SUBSTR(dbms_utility.format_error_stack, 1, 1500);
      
  END check_receive_task;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CHECK_EVENT
  -- purpose:        Check event element
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE check_event(p_code_result  OUT VARCHAR2,
                        p_text_message OUT CLOB)
  IS
 
    c_proc_name        CONSTANT VARCHAR2(30) := 'CHECK_EVENT';  
    v_step             VARCHAR2(256);
    v_int_result       INTEGER;
    v_int_result_tmp   INTEGER;
    v_text_message     CLOB;
    v_text_message_tmp VARCHAR2(3000);
        
    CURSOR c_event_activity IS
      SELECT 
         e.name_workflow_file,
         e.code_activity_type,
         e.id_workflow_activity,
         e.name_activity,
         e.text_async_before,
         e.text_async_after,
         SUM(CASE WHEN ea.code_attribute_type = c_incoming_attr THEN 1 ELSE 0 END) AS cnt_incoming_trans,
         SUM(CASE WHEN ea.code_attribute_type = c_outgoing_attr THEN 1 ELSE 0 END) AS cnt_outgoing_trans
      FROM owner_wfe.wf_tmp_activity e 
      LEFT JOIN owner_wfe.wf_tmp_activity_attr ea ON ea.name_workflow_file = e.name_workflow_file 
                                                 AND ea.id_workflow_activity = e.id_workflow_activity
                                                 AND ea.code_activity_type IN (c_start_event, c_end_event, c_wait_event)
                                                 AND ea.code_attribute_type IN (c_incoming_attr, c_outgoing_attr)
      WHERE e.code_activity_type IN (c_start_event, c_end_event, c_wait_event)
      GROUP BY e.name_workflow_file,
               e.code_activity_type,
               e.id_workflow_activity,
               e.name_activity,
               e.text_async_before,
               e.text_async_after
      ORDER BY e.name_workflow_file,
               e.code_activity_type,
               e.id_workflow_activity;
    
  BEGIN
  
    -- Set result to default
    v_int_result := c_int_status_complete; 

    -- Check event activity
    v_step := 'Check event activity';
    FOR i IN c_event_activity
    LOOP

      -- Check naming rules -> id and name must have same value
      v_step := 'Check naming rules -> id and name must have same value';
      check_naming_convention(p_name_workflow_file   => i.name_workflow_file,
                              p_code_activity_type   => i.code_activity_type,
                              p_id_workflow_activity => i.id_workflow_activity,
                              p_name_activity        => i.name_activity,
                              p_int_result           => v_int_result_tmp,
                              p_text_message         => v_text_message_tmp);

      -- Set int result                    
      v_int_result := GREATEST(v_int_result, v_int_result_tmp);
          
      -- Set text message                    
      IF v_text_message_tmp IS NOT NULL THEN
        v_text_message := v_text_message||v_text_message_tmp;
      END IF;                        
      
      -- Check incoming/outgoing transitions
      v_step := 'Check incoming/outgoing transitions';
      check_transition(p_name_workflow_file   => i.name_workflow_file,
                       p_code_activity_type   => i.code_activity_type,
                       p_id_workflow_activity => i.id_workflow_activity,
                       p_cnt_incoming_trans   => i.cnt_incoming_trans,
                       p_cnt_outgoing_trans   => i.cnt_outgoing_trans,
                       p_int_result           => v_int_result_tmp,
                       p_text_message         => v_text_message_tmp);

      -- Set int result                    
      v_int_result := GREATEST(v_int_result, v_int_result_tmp);
      
      -- Set text message                    
      IF v_text_message_tmp IS NOT NULL THEN
        v_text_message := v_text_message||v_text_message_tmp;
      END IF;   
      
      -- Check async options
      v_step := 'Check async option';
      check_async_option(p_name_workflow_file   => i.name_workflow_file,
                         p_code_activity_type   => i.code_activity_type,
                         p_id_workflow_activity => i.id_workflow_activity,
                         p_text_async_before    => i.text_async_before,
                         p_text_async_after     => i.text_async_after,
                         p_int_result           => v_int_result_tmp,
                         p_text_message         => v_text_message_tmp);
           
      -- Set int result                    
      v_int_result := GREATEST(v_int_result, v_int_result_tmp);

      -- Set text message                    
      IF v_text_message_tmp IS NOT NULL THEN
        v_text_message := v_text_message||v_text_message_tmp;
      END IF; 
                             
    END LOOP; 
    
    -- Set result to output
    v_step := 'Set result to output';
    p_code_result := get_code_result(v_int_result);
    IF v_text_message IS NOT NULL THEN
      v_text_message := 'Check for event activity found following issues:'||v_text_message;
      p_text_message := v_text_message;
    END IF;
  
  EXCEPTION
    WHEN OTHERS THEN
      -- Set result
      p_code_result := c_status_error;
      -- Set message
      p_text_message := 'Error in '||c_mod_name||'.'||c_proc_name||' - ('||v_step||'): '||SUBSTR(dbms_utility.format_error_stack, 1, 1500);
      
  END check_event;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CHECK_GATEWAY
  -- purpose:        Check parallel/inclusive gateway
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE check_gateway(p_code_result  OUT VARCHAR2,
                          p_text_message OUT CLOB)
  IS
 
    c_proc_name        CONSTANT VARCHAR2(30) := 'CHECK_EVENT';  
    v_step             VARCHAR2(256);
    v_int_result       INTEGER;
    v_int_result_tmp   INTEGER;
    v_text_message     CLOB;
    v_text_message_tmp VARCHAR2(3000);
    
    CURSOR c_gateway_activity IS
      SELECT 
         e.name_workflow_file,
         e.code_activity_type,
         e.id_workflow_activity,
         e.name_activity,
         e.text_async_before,
         e.text_async_after,
         SUM(CASE WHEN ea.code_attribute_type = c_incoming_attr THEN 1 ELSE 0 END) AS cnt_incoming_trans,
         SUM(CASE WHEN ea.code_attribute_type = c_outgoing_attr THEN 1 ELSE 0 END) AS cnt_outgoing_trans
      FROM owner_wfe.wf_tmp_activity e 
      LEFT JOIN owner_wfe.wf_tmp_activity_attr ea ON ea.name_workflow_file = e.name_workflow_file 
                                                 AND ea.id_workflow_activity = e.id_workflow_activity
                                                 AND ea.code_activity_type IN (c_parallel_gateway, c_inclusive_gateway)
                                                 AND ea.code_attribute_type IN (c_incoming_attr, c_outgoing_attr)
      WHERE e.code_activity_type IN (c_parallel_gateway, c_inclusive_gateway)
      GROUP BY e.name_workflow_file,
               e.code_activity_type,
               e.id_workflow_activity,
               e.name_activity,
               e.text_async_before,
               e.text_async_after
      ORDER BY e.name_workflow_file,
               e.id_workflow_activity;
    
  BEGIN
  
    -- Set result to default
    v_int_result := c_int_status_complete; 

    -- Check gateway activity
    v_step := 'Check gateway activity';
    FOR i IN c_gateway_activity
    LOOP                  
      
      -- Check incoming/outgoing transitions
      v_step := 'Check incoming/outgoing transitions';
      check_transition(p_name_workflow_file   => i.name_workflow_file,
                       p_code_activity_type   => i.code_activity_type,
                       p_id_workflow_activity => i.id_workflow_activity,
                       p_cnt_incoming_trans   => i.cnt_incoming_trans,
                       p_cnt_outgoing_trans   => i.cnt_outgoing_trans,
                       p_int_result           => v_int_result_tmp,
                       p_text_message         => v_text_message_tmp);

      -- Set int result                    
      v_int_result := GREATEST(v_int_result, v_int_result_tmp);
      
      -- Set text message                    
      IF v_text_message_tmp IS NOT NULL THEN
        v_text_message := v_text_message||v_text_message_tmp;
      END IF;   
      
      -- Check async options
      v_step := 'Check async option';
      check_async_option(p_name_workflow_file   => i.name_workflow_file,
                         p_code_activity_type   => i.code_activity_type,
                         p_id_workflow_activity => i.id_workflow_activity,
                         p_text_async_before    => i.text_async_before,
                         p_text_async_after     => i.text_async_after,
                         p_int_result           => v_int_result_tmp,
                         p_text_message         => v_text_message_tmp);
           
      -- Set int result                    
      v_int_result := GREATEST(v_int_result, v_int_result_tmp);

      -- Set text message                    
      IF v_text_message_tmp IS NOT NULL THEN
        v_text_message := v_text_message||v_text_message_tmp;
      END IF; 

    END LOOP; 
    
    -- Set result to output
    v_step := 'Set result to output';
    p_code_result := get_code_result(v_int_result);
    IF v_text_message IS NOT NULL THEN
      v_text_message := 'Check for gateway activity found following issues:'||v_text_message;
      p_text_message := v_text_message;
    END IF;
  
  EXCEPTION
    WHEN OTHERS THEN
      -- Set result
      p_code_result := c_status_error;
      -- Set message
      p_text_message := 'Error in '||c_mod_name||'.'||c_proc_name||' - ('||v_step||'): '||SUBSTR(dbms_utility.format_error_stack, 1, 1500);
      
  END check_gateway;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: VALIDATE_WORKFLOW
  -- purpose:        Validate workflow files before deployment (check if everything is in place)       
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE validate_workflow(p_code_result  OUT VARCHAR2,
                              p_text_message OUT CLOB)
  IS
 
    c_proc_name           CONSTANT VARCHAR2(30) := 'VALIDATE_WORKFLOW';  
    v_step                VARCHAR2(256);
    v_code_result_brules  VARCHAR2(30);
    v_code_result_callact VARCHAR2(30);
    v_code_result_rectask VARCHAR2(30);
    v_code_result_event   VARCHAR2(30);
    v_code_result_gateway VARCHAR2(30);
    v_code_result_final   VARCHAR2(30);
    v_text_message        CLOB;
    v_text_message_final  CLOB;
        
  BEGIN
  
    -- Check basic rules
    v_step := 'Check basic rules';
    check_basic_rules(p_code_result  => v_code_result_brules,
                      p_text_message => v_text_message);
    
    -- Set final text message
    IF v_text_message IS NOT NULL THEN
      v_text_message_final := v_text_message_final||v_text_message||CHR(10);
    END IF;
 
    -- Check process activity call activity
    v_step := 'Check process activity call activity';
    check_call_activity(p_code_result  => v_code_result_callact,
                        p_text_message => v_text_message);
                      
    -- Set final text message
    IF v_text_message IS NOT NULL THEN
      v_text_message_final := v_text_message_final||v_text_message||CHR(10);
    END IF;

    -- Check process activity receive task
    v_step := 'Check process activity receive task';
    check_receive_task(p_code_result  => v_code_result_rectask,
                       p_text_message => v_text_message);

    -- Set final text message
    IF v_text_message IS NOT NULL THEN
      v_text_message_final := v_text_message_final||v_text_message||CHR(10);
    END IF;
    
    -- Check process activity event
    v_step := 'Check process activity event';
    check_event(p_code_result  => v_code_result_event,
                p_text_message => v_text_message);

    -- Set final text message
    IF v_text_message IS NOT NULL THEN
      v_text_message_final := v_text_message_final||v_text_message||CHR(10);
    END IF;
    
    -- Check process activity gateway
    v_step := 'CCheck process activity gateway';
    check_gateway(p_code_result  => v_code_result_gateway,
                  p_text_message => v_text_message);

    -- Set final text message
    IF v_text_message IS NOT NULL THEN
      v_text_message_final := v_text_message_final||v_text_message||CHR(10);
    END IF;
                      
    -- Set final code result
    IF v_code_result_brules = c_status_error
      OR v_code_result_callact = c_status_error
      OR v_code_result_rectask = c_status_error
      OR v_code_result_event = c_status_error
      OR v_code_result_gateway = c_status_error THEN
      
      v_code_result_final := c_status_error;
      
    ELSIF v_code_result_brules = c_status_warning
         OR v_code_result_callact = c_status_warning
         OR v_code_result_rectask = c_status_warning
         OR v_code_result_event = c_status_warning
         OR v_code_result_gateway = c_status_warning THEN
       
      v_code_result_final := c_status_warning;
      
    ELSE
      
      v_code_result_final := c_status_complete;
    
    END IF;
    
    -- Set result
    p_code_result := v_code_result_final;
    p_text_message := v_text_message_final;
 
  EXCEPTION
    WHEN OTHERS THEN
      -- Set result
      p_code_result := c_status_error;
      -- Set message
      p_text_message := 'Error in '||c_mod_name||'.'||c_proc_name||' - ('||v_step||'): '||SUBSTR(dbms_utility.format_error_stack, 1, 1500);
      
  END validate_workflow;                          

END lib_wf_validator;
/
