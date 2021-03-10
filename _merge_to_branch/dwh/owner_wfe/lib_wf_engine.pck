CREATE OR REPLACE PACKAGE owner_wfe.lib_wf_engine IS

  ---------------------------------------------------------------------------------------------------------
  -- author:  Ludek
  -- created: 11.05.2020
  -- purpose: Execute workflow process
  ---------------------------------------------------------------------------------------------------------

  ---------------------------------------------------------------------------------------------------------
  -- Global variables
  ---------------------------------------------------------------------------------------------------------  
  c_minus_two               CONSTANT INTEGER := owner_wfe.lib_wf_constant.c_minus_two;

  TYPE t_wf_activity IS RECORD 
    (
     id_workflow_activity          VARCHAR2(255),
     code_activity_type            VARCHAR2(255),
     name_activity                 VARCHAR2(255)
    );

  TYPE t_wf_instance IS RECORD 
    (
     id_workflow_instance        INTEGER,
     id_workflow_instance_main   INTEGER,
     id_workflow_instance_super  INTEGER, 
     id_workflow_definition      INTEGER,
     id_process_instance         INTEGER,
     date_effective              DATE,
     num_process_priority        INTEGER,
     name_workflow               VARCHAR2(255),
     code_status                 VARCHAR2(30)
    );

  TYPE t_wf_activity_instance IS RECORD 
    (
     id_workflow_activity_instance INTEGER,   
     id_workflow_instance          INTEGER,
     id_workflow_instance_main     INTEGER,
     id_workflow_instance_super    INTEGER,
     id_workflow_definition        INTEGER,
     id_workflow_activity          VARCHAR2(255),
     id_workflow_activity_super    VARCHAR2(255),
     id_process_instance           INTEGER,
     date_effective                DATE,
     num_process_priority          INTEGER,
     name_workflow                 VARCHAR2(255 CHAR),
     code_activity_type            VARCHAR2(255),
     name_activity                 VARCHAR2(255),
     name_module                   VARCHAR2(255 CHAR),
     text_data                     VARCHAR2(1000 CHAR),
     name_parameter                VARCHAR2(255 CHAR),
     text_parameter_value          VARCHAR2(255 CHAR),
     text_message                  VARCHAR2(4000 CHAR),
     code_status                   VARCHAR2(30)     
    );

  ---------------------------------------------------------------------------------------------------------
  -- function name: IS_WF_INSTANCE_SUSPEND
  -- purpose:       Find out if parallel gateway is complete (all incoming activities vere processed)
  ---------------------------------------------------------------------------------------------------------  
  FUNCTION is_wf_instance_suspend(p_id_workflow_instance_main IN INTEGER) RETURN BOOLEAN RESULT_CACHE;

  ---------------------------------------------------------------------------------------------------------
  -- function name: GET_ID_WORKFLOW_ACT_INST_SEQ
  -- purpose:       Get id workflow activity instance from sequence
  ---------------------------------------------------------------------------------------------------------  
  FUNCTION get_id_workflow_act_inst_seq RETURN INTEGER;

  ---------------------------------------------------------------------------------------------------------
  -- function name: GET_WF_ACTIVITY_INFO
  -- purpose:       Get information about workflow activity based on definition id and activity id
  ---------------------------------------------------------------------------------------------------------  
  FUNCTION get_wf_activity_info(p_id_workflow_definition IN INTEGER,
                                p_id_workflow_activity   IN VARCHAR2 DEFAULT NULL,
                                p_code_activity_type     IN VARCHAR2 DEFAULT NULL) RETURN t_wf_activity;

  ---------------------------------------------------------------------------------------------------------
  -- function name: GET_INF_WF_INSTANCE_INFO
  -- purpose:       Get information about inferior workflow instance based on superior id and workflow name
  ---------------------------------------------------------------------------------------------------------  
  FUNCTION get_inf_wf_instance_info(p_id_workflow_instance_main  IN INTEGER,    
                                    p_id_workflow_instance_super IN INTEGER,
                                    p_date_effective             IN DATE,
                                    p_name_workflow              IN VARCHAR2) RETURN t_wf_instance;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: GET_WF_ACTIVITY_INST_INFO
  -- purpose:        Get information about workflow activity instance based on id
  ---------------------------------------------------------------------------------------------------------  
  FUNCTION get_wf_activity_inst_info(p_id_workflow_activity_inst IN INTEGER,
                                     p_date_effective            IN DATE) RETURN t_wf_activity_instance;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: ENQ_TARGET_WF_ACTIVITY_INST
  -- purpose:        Enqueue target workflow  activity instance
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE enq_target_wf_activity_inst(p_wf_activity_instance IN t_wf_activity_instance);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: START_WF_INSTANCE
  -- purpose:        Set workflow instance
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE start_wf_instance(p_wf_instance IN OUT t_wf_instance);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CANCEL_WF_INSTANCE
  -- purpose:        Cancel workflow instance
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE cancel_wf_instance(p_wf_instance  IN OUT t_wf_instance,
                               p_text_message IN VARCHAR2,
                               p_flag_force   IN BOOLEAN DEFAULT FALSE);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: SUSPEND_WF_INSTANCE
  -- purpose:        Suspend workflow instance
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE suspend_wf_instance(p_id_workflow_instance_main IN INTEGER);
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: RESUME_WF_INSTANCE
  -- purpose:        Resume workflow instance
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE resume_wf_instance(p_id_workflow_instance_main IN INTEGER);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: RESTART_WF_ACTIVITY_INSTANCE
  -- purpose:        Restart failed workflow activity instance
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE restart_wf_activity_instance(p_wf_activity_instance IN OUT t_wf_activity_instance);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: SKIP_WF_ACTIVITY_INSTANCE
  -- purpose:        Skip failed workflow activity instance
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE skip_wf_activity_instance(p_wf_activity_instance IN OUT t_wf_activity_instance);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CANCEL_WF_ACTIVITY_INSTANCE
  -- purpose:        Cancel in workflow activity instance
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE cancel_wf_activity_instance(p_wf_activity_instance IN OUT t_wf_activity_instance);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: EXEC_WF_ACTIVITY_INSTANCE
  -- purpose:        Start workflow activity instance
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE exec_wf_activity_instance(p_wf_activity_instance IN t_wf_activity_instance);
                          
END lib_wf_engine;        
/
CREATE OR REPLACE PACKAGE BODY owner_wfe.lib_wf_engine IS

  ---------------------------------------------------------------------------------------------------------
  -- Global variables
  ---------------------------------------------------------------------------------------------------------  
  c_mod_name                CONSTANT VARCHAR2(30) := 'LIB_WF_ENGINE';
  c_status_complete         CONSTANT VARCHAR2(30) := owner_wfe.lib_wf_constant.c_complete;
  c_status_cancel           CONSTANT VARCHAR2(30) := owner_wfe.lib_wf_constant.c_cancel;
  c_status_new              CONSTANT VARCHAR2(30) := owner_wfe.lib_wf_constant.c_new;
  c_status_running          CONSTANT VARCHAR2(30) := owner_wfe.lib_wf_constant.c_running;
  c_status_error            CONSTANT VARCHAR2(30) := owner_wfe.lib_wf_constant.c_error;
  c_status_restart          CONSTANT VARCHAR2(30) := owner_wfe.lib_wf_constant.c_restart;
  c_status_skip             CONSTANT VARCHAR2(30) := owner_wfe.lib_wf_constant.c_skip;
  c_module_name             CONSTANT VARCHAR2(30) := owner_wfe.lib_wf_constant.c_module_name;
  c_data_type               CONSTANT VARCHAR2(30) := owner_wfe.lib_wf_constant.c_data_type;
  c_date_future             CONSTANT DATE := owner_wfe.lib_wf_constant.c_date_future;
  c_date_future_ts          CONSTANT TIMESTAMP := CAST(c_date_future AS TIMESTAMP);
  c_xap                     CONSTANT VARCHAR2(10) := owner_wfe.lib_wf_constant.c_xap;
  v_text_message            VARCHAR2(4000); 
  
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
  c_timer_duration_attr     CONSTANT VARCHAR2(100) := owner_wfe.lib_wf_constant.c_timer_duration_attr;  
  c_input_parameter_attr    CONSTANT VARCHAR2(100) := owner_wfe.lib_wf_constant.c_input_parameter_attr;
  c_condition_expression    CONSTANT VARCHAR2(100) := owner_wfe.lib_wf_constant.c_condition_expression;
    
  -- Type
  TYPE tt_wf_activity   IS TABLE OF t_wf_activity;

  ---------------------------------------------------------------------------------------------------------
  -- function name: IS_WF_INSTANCE_SUSPEND
  -- purpose:       Find out if parallel gateway is complete (all incoming activities vere processed)
  ---------------------------------------------------------------------------------------------------------  
  FUNCTION is_wf_instance_suspend(p_id_workflow_instance_main IN INTEGER) RETURN BOOLEAN RESULT_CACHE RELIES_ON (owner_wfe.wf_run_instance_suspend)  
  IS
  
    v_cnt INTEGER;
      
  BEGIN
  
    -- Find out if main workflow instance is suspended
    SELECT 
      COUNT(1)
     INTO
      v_cnt 
    FROM owner_wfe.wf_run_instance_suspend
    WHERE id_workflow_instance_main = p_id_workflow_instance_main;
    
    IF v_cnt >= 1 THEN
      RETURN TRUE;
    ELSE
      RETURN FALSE;
    END IF;

  END is_wf_instance_suspend;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: IS_PARALLEL_GATEWAY_COMPLETE
  -- purpose:        Find out if parallel gateway is complete (all incoming activities vere processed)
  ---------------------------------------------------------------------------------------------------------  
  FUNCTION is_parallel_gateway_complete(p_id_workflow_instance   IN INTEGER,
                                        p_id_workflow_definition IN INTEGER,
                                        p_id_workflow_activity   IN VARCHAR2,
                                        p_date_effective         IN DATE) RETURN BOOLEAN
  IS
  
    v_cnt_incoming_trans INTEGER;
    v_cnt_active_inst INTEGER;
      
  BEGIN
  
    -- Get number of incoming transitions
    SELECT
      COUNT(1)
     INTO
      v_cnt_incoming_trans
    FROM owner_wfe.wf_rep_activity a
    WHERE a.id_workflow_definition = p_id_workflow_definition
      AND a.id_workflow_activity_target = p_id_workflow_activity;
      
    -- Get number of active parallel gateway instances
    SELECT
       COUNT(1)
      INTO
       v_cnt_active_inst
    FROM owner_wfe.wf_hist_activity_instance
    WHERE id_workflow_instance = p_id_workflow_instance
      AND id_workflow_activity = p_id_workflow_activity
      AND date_effective = p_date_effective;
      
    -- Return result
    -- If count of active parallel gateway instances is same as count of incoming transitions return TRUE
    IF v_cnt_incoming_trans = v_cnt_active_inst THEN
      RETURN TRUE;
    -- Otherwise false
    ELSE
      RETURN FALSE;
    END IF;
    
  END is_parallel_gateway_complete;

  ---------------------------------------------------------------------------------------------------------
  -- function name: GET_ID_WORKFLOW_INST_SEQ
  -- purpose:       Get id workflow instance from sequence
  ---------------------------------------------------------------------------------------------------------  
  FUNCTION get_id_workflow_inst_seq RETURN INTEGER
  IS
  
    v_id_workflow_instance INTEGER;
  
  BEGIN
  
    -- Get id workflow instance from sequence
    SELECT owner_wfe.s_workflow_instance.nextval
      INTO v_id_workflow_instance
    FROM dual; 
    
    -- Return result
    RETURN v_id_workflow_instance;
    
  END get_id_workflow_inst_seq;

  ---------------------------------------------------------------------------------------------------------
  -- function name: GET_ID_WORKFLOW_ACT_INST_SEQ
  -- purpose:       Get id workflow activity instance from sequence
  ---------------------------------------------------------------------------------------------------------  
  FUNCTION get_id_workflow_act_inst_seq RETURN INTEGER
  IS
  
    v_id_workflow_act_instance INTEGER;
  
  BEGIN
  
    -- Get id workflow activity instance from sequence
    SELECT owner_wfe.s_workflow_activity_instance.nextval
      INTO v_id_workflow_act_instance
    FROM dual; 
    
    -- Return result
    RETURN v_id_workflow_act_instance;
    
  END get_id_workflow_act_inst_seq;

  ---------------------------------------------------------------------------------------------------------
  -- function name: GET_ID_WORKFLOW_INSTANCE
  -- purpose:       Get id workflow instance from repository
  ---------------------------------------------------------------------------------------------------------  
  FUNCTION get_id_workflow_definition(p_name_workflow IN VARCHAR2) RETURN INTEGER
  IS
  
    v_id_workflow_definition INTEGER;
  
  BEGIN
  
    -- Get actuall id workflow version
    BEGIN
      
      SELECT
         id_workflow_definition
        INTO
         v_id_workflow_definition 
      FROM owner_wfe.wf_rep_definition
      WHERE name_workflow = p_name_workflow
        AND dtime_valid_to = c_date_future;
        
    EXCEPTION
      WHEN no_data_found THEN
        -- Set default value
        v_id_workflow_definition := c_minus_two;
        
    END;
    
    -- Return result
    RETURN v_id_workflow_definition;
    
  END get_id_workflow_definition;

  ---------------------------------------------------------------------------------------------------------
  -- function name: GET_TIMER_DURATION
  -- purpose:       Get timer duration from repository
  ---------------------------------------------------------------------------------------------------------  
  FUNCTION get_timer_duration(p_id_workflow_definition IN INTEGER,
                              p_id_workflow_activity   IN VARCHAR2) RETURN NUMBER
  IS
  
    v_num_timer_duration NUMBER;
  
  BEGIN
  
    -- Get timer duration in seconds
    BEGIN
      
      SELECT /*+ index(a idx_wfrepactattr_attrvalue) */
         ROUND((SYSDATE - (SYSDATE - TO_DSINTERVAL(text_attribute_value))) * 86400)
        INTO
         v_num_timer_duration
      FROM owner_wfe.wf_rep_activity_attr 
      WHERE id_workflow_definition = p_id_workflow_definition
        AND id_workflow_activity = p_id_workflow_activity
        AND code_attribute_type = c_timer_duration_attr;

    EXCEPTION
      WHEN no_data_found THEN
        -- Set default value
        v_num_timer_duration := NULL;
        
    END;
    
    -- Return result
    RETURN v_num_timer_duration;
    
  END get_timer_duration;

  ---------------------------------------------------------------------------------------------------------
  -- function name: GET_WF_ACTIVITY_INFO
  -- purpose:       Get information about workflow activity based on definition id and activity id
  ---------------------------------------------------------------------------------------------------------  
  FUNCTION get_wf_activity_info(p_id_workflow_definition IN INTEGER,
                                p_id_workflow_activity   IN VARCHAR2 DEFAULT NULL,
                                p_code_activity_type     IN VARCHAR2 DEFAULT NULL) RETURN t_wf_activity
  IS
  
    a_wf_activity  t_wf_activity;

  BEGIN
  
    -- Get information about workflow activity based on definition id and activity id
    IF p_id_workflow_activity IS NOT NULL THEN
      
      SELECT 
         id_workflow_activity,
         code_activity_type,
         name_activity
        INTO
         a_wf_activity.id_workflow_activity,
         a_wf_activity.code_activity_type,
         a_wf_activity.name_activity
      FROM owner_wfe.wf_rep_activity 
      WHERE id_workflow_definition = p_id_workflow_definition
        AND id_workflow_activity = p_id_workflow_activity;
    
    END IF;
    
    -- Get information about start workflow activity based on definition id and activity type
    IF p_code_activity_type IS NOT NULL THEN   
    
      SELECT 
         id_workflow_activity,
         code_activity_type,
         name_activity
        INTO
         a_wf_activity.id_workflow_activity,
         a_wf_activity.code_activity_type,
         a_wf_activity.name_activity
      FROM owner_wfe.wf_rep_activity 
      WHERE id_workflow_definition = p_id_workflow_definition
        AND code_activity_type = p_code_activity_type;
        
    END IF;

    -- Return result
    RETURN a_wf_activity;
    
  EXCEPTION
    WHEN no_data_found THEN
      -- Set message
      v_text_message := 'Unable to get information about workflow activity!';
      -- Raise error
      raise_application_error(-20001, v_text_message);
    
    WHEN OTHERS THEN
      -- Raise error
      RAISE;

  END get_wf_activity_info;

  ---------------------------------------------------------------------------------------------------------
  -- function name: GET_TARGET_WF_ACTIVITY_INFO
  -- purpose:       Get target (next) workflow activity information
  ---------------------------------------------------------------------------------------------------------  
  FUNCTION get_target_wf_activity_info(p_id_workflow_instance   IN INTEGER,
                                       p_id_workflow_definition IN INTEGER,
                                       p_id_workflow_activity   IN VARCHAR2,
                                       p_date_effective         IN DATE,
                                       p_code_activity_type     IN VARCHAR2) RETURN tt_wf_activity
  IS

    c_proc_name CONSTANT VARCHAR2(30) := 'GET_TARGET_WF_ACTIVITY';
  
    -- Terget reference for activities with exception of sequence flow
    CURSOR c_target_wf_activity IS
      WITH target_activity AS (SELECT
                                  a.id_workflow_definition AS id_workflow_definition,
                                  aa.text_attribute_value  AS id_workflow_activity_target
                               FROM owner_wfe.wf_rep_activity a
                               JOIN owner_wfe.wf_rep_activity_attr aa ON aa.id_workflow_definition = a.id_workflow_definition
                                                                     AND aa.id_workflow_activity = a.id_workflow_activity
                                                                     AND aa.code_attribute_type = c_outgoing_attr    
                               WHERE a.id_workflow_definition = p_id_workflow_definition
                                 AND a.id_workflow_activity = p_id_workflow_activity
                               )
      SELECT
         a.id_workflow_activity,
         a.code_activity_type,
         a.name_activity
      FROM target_activity ta
      JOIN owner_wfe.wf_rep_activity a ON a.id_workflow_definition = ta.id_workflow_definition
                                      AND a.id_workflow_activity = ta.id_workflow_activity_target;
    
    -- Target reference for sequence flow activity                                          
    CURSOR c_target_wf_activity_seq IS
      SELECT
         ta.id_workflow_activity,
         ta.code_activity_type,
         ta.name_activity
      FROM owner_wfe.wf_rep_activity a
      JOIN owner_wfe.wf_rep_activity ta ON ta.id_workflow_definition = a.id_workflow_definition
                                       AND ta.id_workflow_activity = a.id_workflow_activity_target
      WHERE a.id_workflow_definition = p_id_workflow_definition
        AND a.id_workflow_activity = p_id_workflow_activity;
        
    -- Target reference for inclusive gateway activity
    CURSOR c_target_wf_activity_inclg IS
      WITH target_activity AS (SELECT
                                  a.id_workflow_definition AS id_workflow_definition,
                                  aa.text_attribute_value  AS id_workflow_activity_target
                               FROM owner_wfe.wf_rep_activity a
                               JOIN owner_wfe.wf_rep_activity_attr aa ON aa.id_workflow_definition = a.id_workflow_definition
                                                                     AND aa.id_workflow_activity = a.id_workflow_activity
                                                                     AND aa.code_attribute_type = c_outgoing_attr
                               WHERE a.id_workflow_definition = p_id_workflow_definition
                                 AND a.id_workflow_activity = p_id_workflow_activity
                               ),
           -- Evaluate seqeunce flow condition
           target_activity_eval AS (SELECT
                                       a.id_workflow_activity,
                                       a.code_activity_type,
                                       a.name_activity,
                                       CASE WHEN aa.text_attribute_value IS NULL THEN 0
                                            ELSE CASE WHEN v.name_variable IS NOT NULL THEN
                                                           CASE WHEN v.text_value = TRIM(SUBSTR(REGEXP_SUBSTR(aa.text_attribute_value,'"[^"]*', 1), 2)) THEN 1
                                                                ELSE -1
                                                           END 
                                                      ELSE -1
                                                 END
                                       END AS num_result
                                    FROM target_activity ta
                                    JOIN owner_wfe.wf_rep_activity a ON a.id_workflow_definition = ta.id_workflow_definition
                                                                    AND a.id_workflow_activity = ta.id_workflow_activity_target
                                    LEFT JOIN owner_wfe.wf_rep_activity_attr aa ON aa.id_workflow_definition = a.id_workflow_definition
                                                                               AND aa.id_workflow_activity = a.id_workflow_activity
                                                                               AND aa.code_attribute_type = c_condition_expression
                                    LEFT JOIN owner_wfe.wf_hist_variable v ON v.date_effective = p_date_effective
                                                                          AND v.id_workflow_instance = p_id_workflow_instance
                                                                          AND v.id_workflow_activity_instance = c_minus_two
                                                                          AND v.name_variable = TRIM(SUBSTR(REGEXP_SUBSTR(aa.text_attribute_value,'{[^=]*', 1), 2)) 
                                    ),
           -- Sort target activity based on the result from condition evaluation
           target_activity_eval_sort AS (SELECT
                                            id_workflow_activity,
                                            name_activity,
                                            code_activity_type,
                                            ROW_NUMBER() OVER(ORDER BY num_result DESC, id_workflow_activity) AS num_idx
                                         FROM target_activity_eval
                                         )
      -- Pick target activity with "highest" result
      -- Either sequence flow which corresponds with parameter value or default flow (sequence flow without condition)      
      SELECT 
         id_workflow_activity,
         code_activity_type,
         name_activity
      FROM target_activity_eval_sort
      WHERE num_idx = 1;
        
    a_wf_activity_target tt_wf_activity;
  
  BEGIN
  
    -- Get target worfklow activity based on activity type
    IF p_code_activity_type = c_sequence_flow THEN
      
      OPEN c_target_wf_activity_seq;
        FETCH c_target_wf_activity_seq BULK COLLECT INTO a_wf_activity_target;
      CLOSE c_target_wf_activity_seq;
    
    ELSIF p_code_activity_type = c_inclusive_gateway THEN
      
      OPEN c_target_wf_activity_inclg;
        FETCH c_target_wf_activity_inclg BULK COLLECT INTO a_wf_activity_target;
      CLOSE c_target_wf_activity_inclg;
    
    ELSE
      
      OPEN c_target_wf_activity;
        FETCH c_target_wf_activity BULK COLLECT INTO a_wf_activity_target;
      CLOSE c_target_wf_activity; 
      
    END IF;
    
    -- Return array with result    
    RETURN a_wf_activity_target;

  EXCEPTION
    WHEN OTHERS THEN
      -- Close cursors
      IF c_target_wf_activity%ISOPEN THEN CLOSE c_target_wf_activity; END IF;
      IF c_target_wf_activity_seq%ISOPEN THEN CLOSE c_target_wf_activity_seq; END IF;
      IF c_target_wf_activity_inclg%ISOPEN THEN CLOSE c_target_wf_activity_inclg; END IF;
      -- Set message
      v_text_message := 'Error in '||c_proc_name||' during fetching of data for target workflow activity';
      -- Raise error
      raise_application_error(-20002, v_text_message, TRUE);      
    
  END get_target_wf_activity_info;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: GET_INPUT_PARAMETER
  -- purpose:        Get input parameter for receive task from repository
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE get_input_parameter(p_wf_activity_instance IN OUT t_wf_activity_instance)
  IS

  BEGIN
  
    -- Get input parameters (module name and data type)
    BEGIN
      
      SELECT
         MAX(CASE WHEN name_attribute = c_module_name THEN text_attribute_value ELSE NULL END) AS name_module,
         MAX(CASE WHEN name_attribute = c_data_type   THEN text_attribute_value ELSE NULL END) AS text_data
        INTO
         p_wf_activity_instance.name_module,
         p_wf_activity_instance.text_data
      FROM owner_wfe.wf_rep_activity_attr 
      WHERE id_workflow_definition = p_wf_activity_instance.id_workflow_definition
        AND id_workflow_activity = p_wf_activity_instance.id_workflow_activity
        AND code_attribute_type = c_input_parameter_attr;

    EXCEPTION
      WHEN no_data_found THEN
        -- Set default value
        p_wf_activity_instance.name_module := c_xap;
        p_wf_activity_instance.text_data   := NULL;
        
    END;

  END get_input_parameter;

  ---------------------------------------------------------------------------------------------------------
  -- function name: GET_INF_WF_INSTANCE_INFO
  -- purpose:       Get information about inferior workflow instance based on superior id and workflow name
  ---------------------------------------------------------------------------------------------------------  
  FUNCTION get_inf_wf_instance_info(p_id_workflow_instance_main  IN INTEGER,    
                                    p_id_workflow_instance_super IN INTEGER,
                                    p_date_effective             IN DATE,
                                    p_name_workflow              IN VARCHAR2) RETURN t_wf_instance
  IS
  
    a_wf_instance  t_wf_instance;

  BEGIN
  
    -- Get information about inferior workflow instance based on superior id and workflow name
    SELECT
       id_workflow_instance,
       id_workflow_instance_main,
       id_workflow_instance_super,
       id_workflow_definition,
       id_process_instance,
       date_effective,
       num_process_priority,
       name_workflow,
       code_status
      INTO
       a_wf_instance.id_workflow_instance,
       a_wf_instance.id_workflow_instance_main,
       a_wf_instance.id_workflow_instance_super,
       a_wf_instance.id_workflow_definition,
       a_wf_instance.id_process_instance,
       a_wf_instance.date_effective,
       a_wf_instance.num_process_priority,
       a_wf_instance.name_workflow,
       a_wf_instance.code_status 
    FROM owner_wfe.wf_hist_instance
          -- main wf instance is here just because of index
    WHERE id_workflow_instance_main = p_id_workflow_instance_main
      AND id_workflow_instance_super = p_id_workflow_instance_super
      AND date_effective = p_date_effective
      AND name_workflow = p_name_workflow;
      
    -- Return result
    RETURN a_wf_instance;
    
  EXCEPTION
    WHEN no_data_found THEN
      -- Set message
      v_text_message := 'Unable to get information about inferior workflow activity instance!';
      -- Raise error
      raise_application_error(-20003, v_text_message);
    
    WHEN OTHERS THEN
      -- Raise error
      RAISE;

  END get_inf_wf_instance_info;
  
  ---------------------------------------------------------------------------------------------------------
  -- function name: GET_WF_ACTIVITY_INST_INFO
  -- purpose:       Get information about workflow activity instance based on id
  ---------------------------------------------------------------------------------------------------------  
  FUNCTION get_wf_activity_inst_info(p_id_workflow_activity_inst IN INTEGER,
                                     p_date_effective            IN DATE) RETURN t_wf_activity_instance
  IS
  
    a_wf_activity_instance  t_wf_activity_instance;

  BEGIN
  
    -- Get information about workflow activity instance 
    SELECT
       id_workflow_activity_instance, 
       id_workflow_instance,
       id_workflow_instance_main,
       id_workflow_instance_super,
       id_workflow_definition, 
       id_workflow_activity,
       id_workflow_activity_super,
       id_process_instance, 
       date_effective, 
       num_process_priority,
       name_workflow, 
       code_activity_type, 
       name_activity
      INTO
       a_wf_activity_instance.id_workflow_activity_instance,
       a_wf_activity_instance.id_workflow_instance,
       a_wf_activity_instance.id_workflow_instance_main,
       a_wf_activity_instance.id_workflow_instance_super,
       a_wf_activity_instance.id_workflow_definition,
       a_wf_activity_instance.id_workflow_activity,
       a_wf_activity_instance.id_workflow_activity_super,
       a_wf_activity_instance.id_process_instance,
       a_wf_activity_instance.date_effective,
       a_wf_activity_instance.num_process_priority,
       a_wf_activity_instance.name_workflow,
       a_wf_activity_instance.code_activity_type,
       a_wf_activity_instance.name_activity
    FROM owner_wfe.wf_hist_activity_instance
    WHERE id_workflow_activity_instance = p_id_workflow_activity_inst
      AND date_effective = p_date_effective;
      
    -- Return result
    RETURN a_wf_activity_instance;
    
  EXCEPTION
    WHEN no_data_found THEN
      -- Set message
      v_text_message := 'Unable to get information about workflow activity instance!';
      -- Raise error
      raise_application_error(-20004, v_text_message);
    
    WHEN OTHERS THEN
      -- Raise error
      RAISE;

  END get_wf_activity_inst_info;

  ---------------------------------------------------------------------------------------------------------
  -- function name: GET_SUP_WF_ACTIVITY_INST_INFO
  -- purpose:       Get information about superior workflow activity instance 
  ---------------------------------------------------------------------------------------------------------  
  FUNCTION get_sup_wf_activity_inst_info(p_id_workflow_instance_super IN INTEGER,
                                         p_id_workflow_activity       IN VARCHAR2,
                                         p_date_effective             IN DATE) RETURN t_wf_activity_instance
  IS
  
    a_wf_activity_instance  t_wf_activity_instance;

  BEGIN
  
    -- Get information about superior workflow activity instance      
    SELECT
       id_workflow_activity_instance,
       id_workflow_instance,
       id_workflow_instance_main,
       id_workflow_instance_super,
       id_workflow_definition, 
       id_workflow_activity,
       id_workflow_activity_super, 
       id_process_instance, 
       date_effective, 
       num_process_priority, 
       name_workflow,
       code_activity_type, 
       name_activity
      INTO
       a_wf_activity_instance.id_workflow_activity_instance,
       a_wf_activity_instance.id_workflow_instance,
       a_wf_activity_instance.id_workflow_instance_main,
       a_wf_activity_instance.id_workflow_instance_super,
       a_wf_activity_instance.id_workflow_definition,
       a_wf_activity_instance.id_workflow_activity,
       a_wf_activity_instance.id_workflow_activity_super,
       a_wf_activity_instance.id_process_instance,
       a_wf_activity_instance.date_effective,
       a_wf_activity_instance.num_process_priority,
       a_wf_activity_instance.name_workflow,
       a_wf_activity_instance.code_activity_type,
       a_wf_activity_instance.name_activity
    FROM owner_wfe.wf_hist_activity_instance
    WHERE id_workflow_instance = p_id_workflow_instance_super
      AND id_workflow_activity = p_id_workflow_activity
      AND date_effective = p_date_effective;
      
    -- Return result
    RETURN a_wf_activity_instance;
    
  EXCEPTION
    WHEN no_data_found THEN
      -- Set message
      v_text_message := 'Unable to get information about superior workflow activity instance!';
      -- Raise error
      raise_application_error(-20005, v_text_message);
    
    WHEN OTHERS THEN
      -- Raise error
      RAISE;

  END get_sup_wf_activity_inst_info;

  ---------------------------------------------------------------------------------------------------------
  -- function name: CAN_EXEC_WF_ACTIVITY_INSTANCE
  -- purpose:       Decide if activity can be executed or not
  ---------------------------------------------------------------------------------------------------------  
  FUNCTION can_exec_wf_activity_instance(p_id_workflow_instance IN INTEGER,
                                         p_id_workflow_activity IN VARCHAR2,
                                         p_date_effective       IN DATE) RETURN BOOLEAN
  IS
  
    v_cnt    INTEGER;

  BEGIN
  
    -- Get count of started workflow activity instances
    SELECT
       COUNT(1)
      INTO
       v_cnt
    FROM owner_wfe.wf_hist_activity_instance
    WHERE id_workflow_instance = p_id_workflow_instance
      AND id_workflow_activity = p_id_workflow_activity
      AND date_effective = p_date_effective
      AND NVL(code_status, c_xap) NOT IN (c_status_restart, c_status_cancel);

    -- If there is more then one instance, activity cannot be executed
    IF v_cnt > 1 THEN
      RETURN FALSE;
    ELSE
      RETURN TRUE;
    END IF;

  END can_exec_wf_activity_instance;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: ENQ_TARGET_WF_ACTIVITY_INST
  -- purpose:        Enqueue target workflow  activity instance
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE enq_target_wf_activity_inst(p_wf_activity_instance IN t_wf_activity_instance)
  IS

    a_target_wf_activity          tt_wf_activity;
    a_target_wf_activity_instance t_wf_activity_instance;
  
  BEGIN

    -- Get target workflow activity
    a_target_wf_activity := get_target_wf_activity_info(p_id_workflow_instance   => p_wf_activity_instance.id_workflow_instance,
                                                        p_id_workflow_definition => p_wf_activity_instance.id_workflow_definition,
                                                        p_id_workflow_activity   => p_wf_activity_instance.id_workflow_activity,
                                                        p_date_effective         => p_wf_activity_instance.date_effective,
                                                        p_code_activity_type     => p_wf_activity_instance.code_activity_type);
    
    -- Check if array with target activity is not empty
    IF a_target_wf_activity.count > 0 THEN

       -- Loop throught activity and sent them for execution
       FOR i IN a_target_wf_activity.first .. a_target_wf_activity.last
       LOOP
         
         -- Reset record for target activity instance
         a_target_wf_activity_instance := NULL;
         
         -- Set record for target activity instance      
         a_target_wf_activity_instance.id_workflow_activity_instance := get_id_workflow_act_inst_seq;
         a_target_wf_activity_instance.id_workflow_instance          := p_wf_activity_instance.id_workflow_instance;
         a_target_wf_activity_instance.id_workflow_instance_main     := p_wf_activity_instance.id_workflow_instance_main;
         a_target_wf_activity_instance.id_workflow_instance_super    := p_wf_activity_instance.id_workflow_instance_super;
         a_target_wf_activity_instance.id_workflow_definition        := p_wf_activity_instance.id_workflow_definition;
         a_target_wf_activity_instance.id_workflow_activity          := a_target_wf_activity(i).id_workflow_activity;
         a_target_wf_activity_instance.id_workflow_activity_super    := p_wf_activity_instance.id_workflow_activity;
         a_target_wf_activity_instance.id_process_instance           := p_wf_activity_instance.id_process_instance;
         a_target_wf_activity_instance.date_effective                := p_wf_activity_instance.date_effective;
         a_target_wf_activity_instance.num_process_priority          := p_wf_activity_instance.num_process_priority;
         a_target_wf_activity_instance.name_workflow                 := p_wf_activity_instance.name_workflow;
         a_target_wf_activity_instance.code_activity_type            := a_target_wf_activity(i).code_activity_type;
         a_target_wf_activity_instance.name_activity                 := a_target_wf_activity(i).name_activity;
         a_target_wf_activity_instance.name_module                   := NULL;
         a_target_wf_activity_instance.text_data                     := NULL;
         a_target_wf_activity_instance.name_parameter                := NULL;
         a_target_wf_activity_instance.text_parameter_value          := NULL;
         a_target_wf_activity_instance.text_message                  := NULL;
         a_target_wf_activity_instance.code_status                   := c_status_new;
         
         -- If target activity is sequence flow
         IF a_target_wf_activity_instance.code_activity_type = c_sequence_flow THEN
           
           -- Recursive call
           -- Skip sequence flow activity and and enqueue it's target workflow activity instance for execution
           enq_target_wf_activity_inst(p_wf_activity_instance => a_target_wf_activity_instance);
           
         -- For other activities
         ELSE
           
           -- Enqueue target workflow activity instance for execution
           owner_wfe.lib_wf_queue.enq_wf_aq_activity_inst_in(p_wf_activity_instance => a_target_wf_activity_instance); 
           
         END IF;
         
       END LOOP;
       
    END IF;       
    
  END enq_target_wf_activity_inst;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: ENQ_SUP_WF_ACTIVITY_INST
  -- purpose:        Enqueue superior workflow activity instance
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE enq_sup_wf_activity_inst(p_id_workflow_instance_super IN INTEGER,
                                     p_id_workflow_activity       IN VARCHAR2,
                                     p_date_effective             IN DATE)
  IS

    a_sup_wf_activity_instance t_wf_activity_instance;
  
  BEGIN

    -- Get superior instance activity information
    a_sup_wf_activity_instance := get_sup_wf_activity_inst_info(p_id_workflow_instance_super => p_id_workflow_instance_super,
                                                                p_id_workflow_activity       => p_id_workflow_activity, 
                                                                p_date_effective             => p_date_effective);
                                                                  
    -- Set remaining attributes
    a_sup_wf_activity_instance.name_module          := NULL;
    a_sup_wf_activity_instance.text_data            := NULL;
    a_sup_wf_activity_instance.name_parameter       := NULL;
    a_sup_wf_activity_instance.text_parameter_value := NULL;
    a_sup_wf_activity_instance.text_message         := NULL;
    a_sup_wf_activity_instance.code_status          := c_status_complete; 

    -- Enqueue superior workflow activity instance for execution
    owner_wfe.lib_wf_queue.enq_wf_aq_activity_inst_in(p_wf_activity_instance => a_sup_wf_activity_instance); 
   
  END enq_sup_wf_activity_inst;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: SET_WF_INSTANCE
  -- purpose:        Set new worfklow instance
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE set_wf_instance(p_wf_instance IN t_wf_instance)
  IS

    c_systimestamp TIMESTAMP := SYSTIMESTAMP;
  
  BEGIN

    -- Insert new workflow instance into hist table
    INSERT INTO owner_wfe.wf_hist_instance
      (id_workflow_instance, 
       id_workflow_instance_main,
       id_workflow_instance_super, 
       id_workflow_definition, 
       id_process_instance, 
       date_effective, 
       num_process_priority, 
       name_workflow, 
       dtime_start, 
       dtime_end, 
       code_status)
    VALUES
      (p_wf_instance.id_workflow_instance,
       p_wf_instance.id_workflow_instance_main,
       p_wf_instance.id_workflow_instance_super,
       p_wf_instance.id_workflow_definition,
       p_wf_instance.id_process_instance,
       p_wf_instance.date_effective,
       p_wf_instance.num_process_priority,
       p_wf_instance.name_workflow,
       c_systimestamp,
       c_date_future_ts,
       NULL);
       
    -- Insert new workflow instance into runtime table
    INSERT INTO owner_wfe.wf_run_instance
      (id_workflow_instance,
       id_workflow_instance_main,
       id_workflow_instance_super, 
       id_workflow_definition, 
       id_process_instance, 
       date_effective, 
       num_process_priority, 
       name_workflow, 
       dtime_start, 
       code_status)
    VALUES
      (p_wf_instance.id_workflow_instance,
       p_wf_instance.id_workflow_instance_main,
       p_wf_instance.id_workflow_instance_super,
       p_wf_instance.id_workflow_definition,
       p_wf_instance.id_process_instance,
       p_wf_instance.date_effective,
       p_wf_instance.num_process_priority,
       p_wf_instance.name_workflow,
       c_systimestamp,
       p_wf_instance.code_status);
    
  END set_wf_instance;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: SET_WF_INSTANCE
  -- purpose:        Set new worfklow instance
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE set_wf_instance_status(p_wf_instance IN t_wf_instance)
  IS

    c_systimestamp TIMESTAMP := SYSTIMESTAMP;
  
  BEGIN
   
    -- If status is final
    IF p_wf_instance.code_status IN (c_status_complete, c_status_cancel, c_status_skip, c_status_restart) THEN
      
      -- Update in hist table
      UPDATE owner_wfe.wf_hist_instance
         SET dtime_end     = c_systimestamp,
             code_status   = p_wf_instance.code_status
      WHERE id_workflow_instance = p_wf_instance.id_workflow_instance
        AND date_effective = p_wf_instance.date_effective;
      
      -- Delete from runtime table
      DELETE owner_wfe.wf_run_instance 
      WHERE id_workflow_instance = p_wf_instance.id_workflow_instance
        AND date_effective = p_wf_instance.date_effective;
    
    -- If the status is not final    
    ELSE
      
      -- Update runtime table
      UPDATE owner_wfe.wf_run_instance
         SET code_status   = p_wf_instance.code_status
      WHERE id_workflow_instance = p_wf_instance.id_workflow_instance
        AND date_effective = p_wf_instance.date_effective
        AND code_status != p_wf_instance.code_status;
    
    END IF;
    
  END set_wf_instance_status;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: SET_WF_ACTIVITY_INST
  -- purpose:        Set new worfklow activity instance
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE set_wf_activity_inst(p_wf_activity_instance IN t_wf_activity_instance)
  IS

    c_systimestamp TIMESTAMP := SYSTIMESTAMP;
  
  BEGIN

    -- Insert new workflow activity instance into hist table
    INSERT INTO owner_wfe.wf_hist_activity_instance
      (id_workflow_activity_instance, 
       id_workflow_instance,
       id_workflow_instance_main,
       id_workflow_instance_super,
       id_workflow_definition, 
       id_workflow_activity,
       id_workflow_activity_super,
       id_process_instance, 
       date_effective, 
       num_process_priority,
       name_workflow, 
       code_activity_type, 
       name_activity, 
       dtime_start, 
       dtime_end, 
       code_status)
    VALUES
      (p_wf_activity_instance.id_workflow_activity_instance,
       p_wf_activity_instance.id_workflow_instance,
       p_wf_activity_instance.id_workflow_instance_main,
       p_wf_activity_instance.id_workflow_instance_super,
       p_wf_activity_instance.id_workflow_definition,
       p_wf_activity_instance.id_workflow_activity,
       p_wf_activity_instance.id_workflow_activity_super,
       p_wf_activity_instance.id_process_instance,
       p_wf_activity_instance.date_effective,
       p_wf_activity_instance.num_process_priority,
       p_wf_activity_instance.name_workflow,
       p_wf_activity_instance.code_activity_type,
       p_wf_activity_instance.name_activity,
       c_systimestamp,
       c_date_future_ts,
       NULL);
        
    -- Insert new workflow activity instance into runtime table 
    INSERT INTO owner_wfe.wf_run_activity_instance
      (id_workflow_activity_instance, 
       id_workflow_instance,
       id_workflow_instance_main,
       id_workflow_instance_super,
       id_workflow_definition, 
       id_workflow_activity,
       id_workflow_activity_super,
       id_process_instance, 
       date_effective, 
       num_process_priority,
       name_workflow, 
       code_activity_type, 
       name_activity, 
       dtime_start, 
       code_status)
    VALUES
      (p_wf_activity_instance.id_workflow_activity_instance,
       p_wf_activity_instance.id_workflow_instance,
       p_wf_activity_instance.id_workflow_instance_main,
       p_wf_activity_instance.id_workflow_instance_super,
       p_wf_activity_instance.id_workflow_definition,
       p_wf_activity_instance.id_workflow_activity,
       p_wf_activity_instance.id_workflow_activity_super,
       p_wf_activity_instance.id_process_instance,
       p_wf_activity_instance.date_effective,
       p_wf_activity_instance.num_process_priority,
       p_wf_activity_instance.name_workflow,
       p_wf_activity_instance.code_activity_type,
       p_wf_activity_instance.name_activity,
       c_systimestamp,
       p_wf_activity_instance.code_status);  
    
  END set_wf_activity_inst;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: SET_WF_ACTIVITY_INST_STATUS
  -- purpose:        Set worfklow activity instance status
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE set_wf_activity_inst_status(p_wf_activity_instance IN t_wf_activity_instance)
  IS
  
    c_systimestamp TIMESTAMP := SYSTIMESTAMP;
    
  BEGIN
    
    -- Update workflow instance status
    -- If it is parallel gateway
    IF p_wf_activity_instance.code_activity_type = c_parallel_gateway THEN
          
      -- If status is final
      IF p_wf_activity_instance.code_status IN (c_status_complete, c_status_cancel, c_status_skip, c_status_restart) THEN 
        
        -- Update in hist table  
        UPDATE owner_wfe.wf_hist_activity_instance
           SET dtime_end     = c_systimestamp,
               code_status   = p_wf_activity_instance.code_status
        WHERE id_workflow_instance = p_wf_activity_instance.id_workflow_instance
          AND id_workflow_activity = p_wf_activity_instance.id_workflow_activity
          AND date_effective = p_wf_activity_instance.date_effective;
          
        -- Delete from runtime table
        DELETE owner_wfe.wf_run_activity_instance 
        WHERE id_workflow_instance = p_wf_activity_instance.id_workflow_instance
          AND id_workflow_activity = p_wf_activity_instance.id_workflow_activity
          AND date_effective = p_wf_activity_instance.date_effective;
      
      -- If the status is not final
      ELSE
      
        -- Update runtime table
        UPDATE owner_wfe.wf_run_activity_instance
           SET code_status   = p_wf_activity_instance.code_status
        WHERE id_workflow_instance = p_wf_activity_instance.id_workflow_instance
          AND id_workflow_activity = p_wf_activity_instance.id_workflow_activity
          AND date_effective = p_wf_activity_instance.date_effective
          AND code_status != p_wf_activity_instance.code_status;
          
      END IF;
    
    -- Others
    ELSE
      
      -- If status is final
      IF p_wf_activity_instance.code_status IN (c_status_complete, c_status_cancel, c_status_skip, c_status_restart) THEN 
    
        -- Update in hist table
        UPDATE owner_wfe.wf_hist_activity_instance
           SET dtime_end     = c_systimestamp,
               code_status   = p_wf_activity_instance.code_status
        WHERE id_workflow_activity_instance = p_wf_activity_instance.id_workflow_activity_instance
          AND date_effective = p_wf_activity_instance.date_effective;
          
        -- Delete from runtime table
        DELETE owner_wfe.wf_run_activity_instance 
        WHERE id_workflow_activity_instance = p_wf_activity_instance.id_workflow_activity_instance
          AND date_effective = p_wf_activity_instance.date_effective;
      
      -- If the status is not final
      ELSE 
    
        -- Update runtime table
        UPDATE owner_wfe.wf_run_activity_instance
           SET code_status   = p_wf_activity_instance.code_status
        WHERE id_workflow_activity_instance = p_wf_activity_instance.id_workflow_activity_instance
          AND date_effective = p_wf_activity_instance.date_effective
          AND code_status != p_wf_activity_instance.code_status;
        
      END IF;    
        
    END IF;
    
  END set_wf_activity_inst_status;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: SET_WF_INSTANCE
  -- purpose:        Set new worfklow instance
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE set_wf_variable(p_id_workflow_instance      IN INTEGER, 
                            p_id_workflow_activity_inst IN INTEGER DEFAULT c_minus_two, 
                            p_date_effective            IN DATE, 
                            p_name_variable             IN VARCHAR2, 
                            p_text_value                IN VARCHAR2)
  IS

    c_proc_name    CONSTANT VARCHAR2(30) := 'START_WF_INSTANCE';
    c_systimestamp TIMESTAMP := SYSTIMESTAMP;
  
  BEGIN

    -- Insert new workflow variable into hist table
    INSERT INTO owner_wfe.wf_hist_variable
      (id_workflow_instance, 
       id_workflow_activity_instance, 
       date_effective, 
       name_variable, 
       text_value, 
       dtime_inserted)
    VALUES
      (p_id_workflow_instance, 
       p_id_workflow_activity_inst, 
       p_date_effective, 
       p_name_variable, 
       p_text_value,
       c_systimestamp);
  
  EXCEPTION
    WHEN dup_val_on_index THEN
      -- Set message
      v_text_message := 'Variable name '||p_name_variable||' with value '||p_text_value||
                        ' can not be stored twice! (Id worklfow instance - '||p_id_workflow_instance||', id workflow activity instance - '||p_id_workflow_activity_inst||').';
      -- Log error
      owner_wfe.lib_wf_log_api.log_error_event(p_name_event   => c_proc_name,                         
                                               p_text_message => v_text_message);
    
  END set_wf_variable;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: START_WF_INSTANCE
  -- purpose:        Set workflow instance
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE start_wf_instance(p_wf_instance IN OUT t_wf_instance)
  IS

    c_proc_name             CONSTANT VARCHAR2(30) := 'START_WF_INSTANCE';
    v_step                  VARCHAR2(256);

    a_wf_activity           t_wf_activity;    
    a_wf_activity_instance  t_wf_activity_instance;
    
    ex_nonexistent_workflow  EXCEPTION;
  
  BEGIN
    
    -- Get id workflow version from repository
    v_step := 'Get id workflow version from repository';
    p_wf_instance.id_workflow_definition := get_id_workflow_definition(p_name_workflow => p_wf_instance.name_workflow);
    
    -- Check if worfklow exists in repository
    v_step := 'Check if worfklow exists in repository';
    IF p_wf_instance.id_workflow_definition = c_minus_two THEN
      RAISE ex_nonexistent_workflow;
    END IF;
    
    -- Get id workflow instance from sequence
    v_step := 'Get id workflow instance from sequence';
    p_wf_instance.id_workflow_instance := get_id_workflow_inst_seq;
    
    -- Set id workflow instance main
    -- If it is main process itslef, set id workflow instance into id workflow instance main
    IF p_wf_instance.id_workflow_instance_super = c_minus_two THEN
      p_wf_instance.id_workflow_instance_main := p_wf_instance.id_workflow_instance;
    ELSE
      p_wf_instance.id_workflow_instance_main := p_wf_instance.id_workflow_instance_main;
    END IF; 
    
    -- Set status to running
    v_step := 'Set status to running';
    p_wf_instance.code_status := c_status_running;
        
    -- Set workflow instance
    v_step := 'Set workflow instance';
    set_wf_instance(p_wf_instance => p_wf_instance);
    
    -- Get information about start element of given workflof version
    v_step := 'Get information about start element of given workflof version';
    a_wf_activity := get_wf_activity_info(p_id_workflow_definition => p_wf_instance.id_workflow_definition,
                                          p_code_activity_type     => c_start_event);
    
    -- Set record for workflow activity instance (start)
    v_step := 'Set record for workflow activity instance (start)';
    a_wf_activity_instance.id_workflow_activity_instance := get_id_workflow_act_inst_seq;
    a_wf_activity_instance.id_workflow_instance          := p_wf_instance.id_workflow_instance;
    a_wf_activity_instance.id_workflow_instance_main     := p_wf_instance.id_workflow_instance_main;
    a_wf_activity_instance.id_workflow_instance_super    := p_wf_instance.id_workflow_instance_super;
    a_wf_activity_instance.id_workflow_definition        := p_wf_instance.id_workflow_definition;
    a_wf_activity_instance.id_workflow_activity          := a_wf_activity.id_workflow_activity;
    a_wf_activity_instance.id_workflow_activity_super    := c_xap;
    a_wf_activity_instance.id_process_instance           := p_wf_instance.id_process_instance;
    a_wf_activity_instance.date_effective                := p_wf_instance.date_effective;
    a_wf_activity_instance.num_process_priority          := p_wf_instance.num_process_priority;
    a_wf_activity_instance.name_workflow                 := p_wf_instance.name_workflow;
    a_wf_activity_instance.code_activity_type            := a_wf_activity.code_activity_type;
    a_wf_activity_instance.name_activity                 := a_wf_activity.name_activity;
    a_wf_activity_instance.name_module                   := NULL;
    a_wf_activity_instance.text_data                     := NULL;
    a_wf_activity_instance.name_parameter                := NULL;
    a_wf_activity_instance.text_parameter_value          := NULL;
    a_wf_activity_instance.text_message                  := NULL;
    a_wf_activity_instance.code_status                   := c_status_new;
    
    -- Enqueue workflow activity instance for execution
    v_step := 'Enqueue workflow activity instance for execution';
    owner_wfe.lib_wf_queue.enq_wf_aq_activity_inst_in(p_wf_activity_instance => a_wf_activity_instance);
    
    -- Set message
    v_step := 'Set message';
    v_text_message := p_wf_instance.name_workflow||' workflow started! Id workflow instance - '||p_wf_instance.id_workflow_instance;
    
    -- Log message
    v_step := 'Log message';
    owner_wfe.lib_wf_log_api.log_message_event(p_name_event   => c_proc_name,                         
                                               p_text_message => v_text_message);

  EXCEPTION
    WHEN ex_nonexistent_workflow THEN
      -- Set message
      v_text_message := 'Workflow process definition doesnt exists!';
      -- Log error
      owner_wfe.lib_wf_log_api.log_error_event(p_name_event   => c_proc_name,                         
                                               p_text_message => v_text_message);
      -- Raise error
      raise_application_error(-20006, v_text_message);
      
    WHEN OTHERS THEN
      -- Set message
      v_text_message := 'Error in '||c_mod_name||'.'||c_proc_name||' - ('||v_step||'): '||SUBSTR(dbms_utility.format_error_stack, 1, 1500);
      -- Log error
      owner_wfe.lib_wf_log_api.log_error_event(p_name_event   => c_proc_name,                         
                                               p_text_message => v_text_message);
      -- Raise error
      raise_application_error(-20007, v_text_message);
    
  END start_wf_instance;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: END_WF_INSTANCE
  -- purpose:        End workflow instance
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE end_wf_instance(p_wf_instance IN t_wf_instance)
  IS

    c_proc_name             CONSTANT VARCHAR2(30) := 'START_WF_INSTANCE';
  
  BEGIN
  
    -- Set workflow instance status to complete
    set_wf_instance_status(p_wf_instance => p_wf_instance);

    -- Set message
    v_text_message := p_wf_instance.name_workflow||' workflow finished! Id workflow instance - '||p_wf_instance.id_workflow_instance;
    
    -- Log message
    owner_wfe.lib_wf_log_api.log_message_event(p_name_event   => c_proc_name,                         
                                               p_text_message => v_text_message);
    
  END end_wf_instance;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: SUSPEND_WF_INSTANCE
  -- purpose:        Suspend workflow instance
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE suspend_wf_instance(p_id_workflow_instance_main IN INTEGER)
  IS

    c_proc_name             CONSTANT VARCHAR2(30) := 'SUSPEND_WF_INSTANCE';
  
  BEGIN
    
    -- Set workflow instance as suspended
    INSERT INTO owner_wfe.wf_run_instance_suspend
      (id_workflow_instance_main, 
       dtime_inserted)
    VALUES
      (p_id_workflow_instance_main,
       SYSTIMESTAMP);
    
    -- Set message
    v_text_message := 'Workflow instance was suspended! Id workflow instance - '||p_id_workflow_instance_main;
    
    -- Log warning
    owner_wfe.lib_wf_log_api.log_warning_event(p_name_event   => c_proc_name,                         
                                               p_text_message => v_text_message);
    
  END suspend_wf_instance;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: RESUME_WF_INSTANCE
  -- purpose:        Resume workflow instance
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE resume_wf_instance(p_id_workflow_instance_main IN INTEGER)
  IS

    c_proc_name             CONSTANT VARCHAR2(30) := 'RESUME_WF_INSTANCE';
  
  BEGIN
    
    -- Resume workflow instance
    DELETE FROM owner_wfe.wf_run_instance_suspend WHERE id_workflow_instance_main = p_id_workflow_instance_main;
    
    -- Set message
    v_text_message := 'Workflow instance was resumed! Id workflow instance - '||p_id_workflow_instance_main;
    
    -- Log warning
    owner_wfe.lib_wf_log_api.log_warning_event(p_name_event   => c_proc_name,                         
                                               p_text_message => v_text_message);
    
  END resume_wf_instance;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CANCEL_WF_INSTANCE
  -- purpose:        Cancel workflow instance
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE cancel_wf_instance(p_wf_instance  IN OUT t_wf_instance,
                               p_text_message IN VARCHAR2,
                               p_flag_force   IN BOOLEAN DEFAULT FALSE)
  IS

    c_proc_name             CONSTANT VARCHAR2(30) := 'CANCEL_WF_INSTANCE';
    v_step                  VARCHAR2(256);
        
    CURSOR c_activity_instance(p_id_workflow_instance IN INTEGER,
                               p_date_effective       IN DATE) IS
      SELECT
         id_workflow_activity_instance, 
         date_effective,
         code_status
      FROM owner_wfe.wf_hist_activity_instance
      WHERE id_workflow_instance = p_id_workflow_instance
        AND date_effective = p_date_effective;

    a_wf_activity_instance  t_wf_activity_instance;
  
  BEGIN
    
    -- Cancel activities for the workflow instance
    v_step := 'Cancel activities for the workflow instance';
    FOR ai IN c_activity_instance(p_id_workflow_instance => p_wf_instance.id_workflow_instance,
                                  p_date_effective       => p_wf_instance.date_effective)
    LOOP
      
      -- If activity is running or flag force cancel is set to true (even activity in final state will be marked as cancel)
      IF ai.code_status IS NULL OR p_flag_force THEN
      
        -- Get information about worfklow activity instance
        v_step := 'Get information about worfklow activity instance';
        a_wf_activity_instance := get_wf_activity_inst_info(p_id_workflow_activity_inst => ai.id_workflow_activity_instance,
                                                            p_date_effective            => ai.date_effective);
                                                            
        -- Set special message when activity was in final state 
        IF ai.code_status IS NOT NULL THEN
          a_wf_activity_instance.text_message := 'Activity was canceled with force option. Original status was '||ai.code_status;
        END IF;
                                                            
        -- Cancel workflow activity instance
        v_step := 'Cancel workflow activity instance';
        cancel_wf_activity_instance(p_wf_activity_instance => a_wf_activity_instance);
        
      END IF;
    
    END LOOP;
    
    -- Set instance status to cancel
    v_step := 'Set instance status to cancel';
    p_wf_instance.code_status := c_status_cancel;

    -- If message is not null 
    IF p_text_message IS NOT NULL THEN
      
      -- Store cancel message as variable
      v_step := 'Store cancel message as variable';
      set_wf_variable(p_id_workflow_instance      => p_wf_instance.id_workflow_instance, 
                      p_id_workflow_activity_inst => c_minus_two, 
                      p_date_effective            => p_wf_instance.date_effective, 
                      p_name_variable             => p_wf_instance.code_status, 
                      p_text_value                => p_text_message);   
                         
    END IF;
    
    -- Set workflow instance status to cancel
    v_step := 'Set workflow instance status to cancel';
    set_wf_instance_status(p_wf_instance => p_wf_instance);
    
    -- Set message
    v_step := 'Set message';
    v_text_message := 'Workflow instance was canceled! Id workflow instance - '||p_wf_instance.id_workflow_instance;
    
    -- Log warning
    v_step := 'Log warning';
    owner_wfe.lib_wf_log_api.log_warning_event(p_name_event   => c_proc_name,                         
                                               p_text_message => v_text_message);

  EXCEPTION
    WHEN OTHERS THEN
      -- Rollback
      ROLLBACK;
      -- Set message
      v_text_message := 'Error in '||c_mod_name||'.'||c_proc_name||' - ('||v_step||'): '||SUBSTR(dbms_utility.format_error_stack, 1, 1500);
      -- Log error
      owner_wfe.lib_wf_log_api.log_error_event(p_name_event   => c_proc_name,                         
                                               p_text_message => v_text_message);
      -- Raise error
      raise_application_error(-20008, v_text_message);
    
  END cancel_wf_instance;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: START_WF_ACTIVITY_INSTANCE
  -- purpose:        Start workflow activity instance
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE start_wf_activity_instance(p_wf_activity_instance IN OUT t_wf_activity_instance)
  IS
  
  BEGIN
        
    -- Set worekflow activity_status to running
    p_wf_activity_instance.code_status := c_status_running;
    
    -- Set workflow activity instance status
    set_wf_activity_inst(p_wf_activity_instance => p_wf_activity_instance);
    
    -- If it is parallel gateway
    IF p_wf_activity_instance.code_activity_type = c_parallel_gateway
      -- And it can be completed
      AND is_parallel_gateway_complete(p_id_workflow_instance   => p_wf_activity_instance.id_workflow_instance,
                                       p_id_workflow_definition => p_wf_activity_instance.id_workflow_definition,
                                       p_id_workflow_activity   => p_wf_activity_instance.id_workflow_activity,
                                       p_date_effective         => p_wf_activity_instance.date_effective) THEN
                              
      -- Set code status to complete in order to end parallel gateway activity instance
      p_wf_activity_instance.code_status := c_status_complete;
      
    END IF;
           
  END start_wf_activity_instance;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: END_WF_ACTIVITY_INSTANCE
  -- purpose:        End workflow activity instance
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE end_wf_activity_instance(p_wf_activity_instance IN OUT t_wf_activity_instance)
  IS
  
  BEGIN
        
    -- Set workflow activity instance status to complete
    set_wf_activity_inst_status(p_wf_activity_instance => p_wf_activity_instance);
      
  END end_wf_activity_instance;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: ERROR_WF_ACTIVITY_INSTANCE
  -- purpose:        Error in workflow activity instance
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE error_wf_activity_instance(p_wf_activity_instance IN OUT t_wf_activity_instance)
  IS
  
  BEGIN
    
    -- Set activity status to error
    p_wf_activity_instance.code_status := c_status_error;

    -- Store error message as variable
    set_wf_variable(p_id_workflow_instance      => p_wf_activity_instance.id_workflow_instance, 
                    p_id_workflow_activity_inst => p_wf_activity_instance.id_workflow_activity_instance, 
                    p_date_effective            => p_wf_activity_instance.date_effective, 
                    p_name_variable             => p_wf_activity_instance.code_status, 
                    p_text_value                => p_wf_activity_instance.text_message);
        
    -- Set workflow activity instance status to complete
    set_wf_activity_inst_status(p_wf_activity_instance => p_wf_activity_instance);
      
  END error_wf_activity_instance;
 
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: RESTART_WF_ACTIVITY_INSTANCE
  -- purpose:        Restart failed workflow activity instance
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE restart_wf_activity_instance(p_wf_activity_instance IN OUT t_wf_activity_instance)
  IS
  
    c_proc_name             CONSTANT VARCHAR2(30) := 'RESTART_WF_ACTIVITY_INSTANCE';
    v_step                  VARCHAR2(256);
  
  BEGIN

    -- Set status to restart
    p_wf_activity_instance.code_status := c_status_restart;

    -- Set workflow activity instance status to restart
    v_step := 'Set workflow activity instance status to restart';
    set_wf_activity_inst_status(p_wf_activity_instance => p_wf_activity_instance);
    
    -- Get new id workflow activity instance from sequence
    v_step := 'Get new id workflow activity instance from sequence';
    p_wf_activity_instance.id_workflow_activity_instance := get_id_workflow_act_inst_seq;
    
    -- Set status to new
    p_wf_activity_instance.code_status := c_status_new;
       
    -- Enqueue restarted workflow activity instance for execution
    v_step := 'Enqueue restarted workflow activity instance for execution';
    owner_wfe.lib_wf_queue.enq_wf_aq_activity_inst_in(p_wf_activity_instance => p_wf_activity_instance);

    -- Set message
    v_step := 'Set message';
    v_text_message := 'Activity '||p_wf_activity_instance.id_workflow_activity||' within workflow process '||p_wf_activity_instance.name_workflow||
                         ' was restarted. (Id workflow instance - '||p_wf_activity_instance.id_workflow_instance||')';
    
    -- Log message
    v_step := 'Log message';
    owner_wfe.lib_wf_log_api.log_warning_event(p_name_event   => c_proc_name,                         
                                               p_text_message => v_text_message);
    
  EXCEPTION
    WHEN OTHERS THEN
      -- Rollback
      ROLLBACK;
      -- Set message
      v_text_message := 'Error in '||c_mod_name||'.'||c_proc_name||' - ('||v_step||'): '||SUBSTR(dbms_utility.format_error_stack, 1, 1500);
      -- Log error
      owner_wfe.lib_wf_log_api.log_error_event(p_name_event   => c_proc_name,                         
                                               p_text_message => v_text_message);
      -- Raise error
      raise_application_error(-20009, v_text_message);    
      
  END restart_wf_activity_instance;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: SKIP_WF_ACTIVITY_INSTANCE
  -- purpose:        skip failed workflow activity instance
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE skip_wf_activity_instance(p_wf_activity_instance IN OUT t_wf_activity_instance)
  IS
  
    c_proc_name             CONSTANT VARCHAR2(30) := 'SKIP_WF_ACTIVITY_INSTANCE';
    v_step                  VARCHAR2(256);
  
  BEGIN
                                                        
    -- Set status to skip
    p_wf_activity_instance.code_status := c_status_skip;
    
    -- Store skip message as variable
    v_step := 'Store skip message as variable';
    set_wf_variable(p_id_workflow_instance      => p_wf_activity_instance.id_workflow_instance, 
                    p_id_workflow_activity_inst => p_wf_activity_instance.id_workflow_activity_instance, 
                    p_date_effective            => p_wf_activity_instance.date_effective, 
                    p_name_variable             => p_wf_activity_instance.code_status, 
                    p_text_value                => 'Manual skip');

    -- Set workflow activity instance status to skip
    v_step := 'Set workflow activity instance status to skip';
    set_wf_activity_inst_status(p_wf_activity_instance => p_wf_activity_instance);
    
    -- Get new id workflow activity instance from sequence
    v_step := 'Get new id workflow activity instance from sequence';
    p_wf_activity_instance.id_workflow_activity_instance := get_id_workflow_act_inst_seq;
    
    -- Set status to new
    p_wf_activity_instance.code_status := c_status_new;
       
    -- Enqueue target workflow activity instance for execution
    v_step := 'Enqueue target workflow activity instance for execution';
    enq_target_wf_activity_inst(p_wf_activity_instance => p_wf_activity_instance);

    -- Set message
    v_step := 'Set message';
    v_text_message := 'Activity '||p_wf_activity_instance.id_workflow_activity||' within workflow process '||p_wf_activity_instance.name_workflow||
                         ' was skiped. (Id workflow instance - '||p_wf_activity_instance.id_workflow_instance||')';
    
    -- Log message
    v_step := 'Log message';
    owner_wfe.lib_wf_log_api.log_warning_event(p_name_event   => c_proc_name,                         
                                               p_text_message => v_text_message);
    
  EXCEPTION
    WHEN OTHERS THEN
      -- Rollback
      ROLLBACK;
      -- Set message
      v_text_message := 'Error in '||c_mod_name||'.'||c_proc_name||' - ('||v_step||'): '||SUBSTR(dbms_utility.format_error_stack, 1, 1500);
      -- Log error
      owner_wfe.lib_wf_log_api.log_error_event(p_name_event   => c_proc_name,                         
                                               p_text_message => v_text_message);
      -- Raise error
      raise_application_error(-20010, v_text_message);    
      
  END skip_wf_activity_instance;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CANCEL_WF_ACTIVITY_INSTANCE
  -- purpose:        Cancel in workflow activity instance
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE cancel_wf_activity_instance(p_wf_activity_instance IN OUT t_wf_activity_instance)
  IS

    c_proc_name             CONSTANT VARCHAR2(30) := 'CANCEL_WF_ACTIVITY_INSTANCE';
  
  BEGIN
    
    -- Set activity status to cancel
    p_wf_activity_instance.code_status := c_status_cancel;

    -- If message is not null
    IF p_wf_activity_instance.text_message IS NOT NULL THEN
      
      -- Store cancel message as variable
      set_wf_variable(p_id_workflow_instance      => p_wf_activity_instance.id_workflow_instance, 
                      p_id_workflow_activity_inst => p_wf_activity_instance.id_workflow_activity_instance, 
                      p_date_effective            => p_wf_activity_instance.date_effective, 
                      p_name_variable             => p_wf_activity_instance.code_status, 
                      p_text_value                => p_wf_activity_instance.text_message);
                      
    END IF;
        
    -- Set workflow activity instance status to complete
    set_wf_activity_inst_status(p_wf_activity_instance => p_wf_activity_instance);
    
    -- Set message
    v_text_message := 'Activity '||p_wf_activity_instance.id_workflow_activity||' within workflow process '||p_wf_activity_instance.name_workflow||
                         ' was canceled. (Id workflow instance - '||p_wf_activity_instance.id_workflow_instance||')';
    
    -- Log message
    owner_wfe.lib_wf_log_api.log_warning_event(p_name_event   => c_proc_name,                         
                                               p_text_message => v_text_message);
      
  END cancel_wf_activity_instance;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: EXEC_START_EVENT_ACTIVITY
  -- purpose:        Execute start event activity
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE exec_start_event_activity(p_wf_activity_instance IN OUT t_wf_activity_instance)
  IS
  
  BEGIN
    
    -- Enqueue target workflow activity instance for execution
    enq_target_wf_activity_inst(p_wf_activity_instance => p_wf_activity_instance);

    -- Set code status to complete in order to end workflow activity instance
    p_wf_activity_instance.code_status := c_status_complete;
      
  END exec_start_event_activity;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: EXEC_END_EVENT_ACTIVITY
  -- purpose:        Execute end event activity
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE exec_end_event_activity(p_wf_activity_instance IN OUT t_wf_activity_instance)
  IS
  
    a_wf_instance  t_wf_instance;
  
  BEGIN
       
    -- If this end activity continues in superior process
    IF p_wf_activity_instance.id_workflow_instance_super != c_minus_two THEN
                                                                    
      -- Enqueue superior workflow activity instance for execution
      enq_sup_wf_activity_inst(p_id_workflow_instance_super => p_wf_activity_instance.id_workflow_instance_super,
                               p_id_workflow_activity       => p_wf_activity_instance.name_workflow,
                               p_date_effective             => p_wf_activity_instance.date_effective);
                                             
    END IF;
    
    -- Set workflow instance record
    a_wf_instance.id_workflow_instance       := p_wf_activity_instance.id_workflow_instance;
    a_wf_instance.id_workflow_instance_main  := p_wf_activity_instance.id_workflow_instance_main;
    a_wf_instance.id_workflow_instance_super := p_wf_activity_instance.id_workflow_instance_super;
    a_wf_instance.id_workflow_definition     := p_wf_activity_instance.id_workflow_definition;
    a_wf_instance.id_process_instance        := p_wf_activity_instance.id_process_instance;
    a_wf_instance.date_effective             := p_wf_activity_instance.date_effective;
    a_wf_instance.num_process_priority       := p_wf_activity_instance.num_process_priority;
    a_wf_instance.name_workflow              := p_wf_activity_instance.name_workflow;
    a_wf_instance.code_status                := c_status_complete;
     
    -- End workflow instance
    end_wf_instance(p_wf_instance => a_wf_instance);
    
    -- Set code status to complete in order to end workflow activity instance
    p_wf_activity_instance.code_status := c_status_complete;
      
  END exec_end_event_activity;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: EXEC_WAIT_EVENT_ACTIVITY
  -- purpose:        Execute wait event activity
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE exec_wait_event_activity(p_wf_activity_instance IN OUT t_wf_activity_instance)
  IS
  
    v_num_timer_duration BINARY_INTEGER;
  
  BEGIN
    
    -- If wait event activity should be executed (status running)
    IF p_wf_activity_instance.code_status = c_status_running THEN
          
      -- Get timer_duration
      v_num_timer_duration := get_timer_duration(p_id_workflow_definition => p_wf_activity_instance.id_workflow_definition,
                                                 p_id_workflow_activity   => p_wf_activity_instance.id_workflow_activity);
      
      -- Set code status to complete in order to end workflow activity instance (for enqueued message)
      p_wf_activity_instance.code_status := c_status_complete;
      
      -- Enqueue workflow activity instance for execution with delay specified in seconds
      owner_wfe.lib_wf_queue.enq_wf_aq_activity_inst_in(p_wf_activity_instance => p_wf_activity_instance,
                                                        p_num_delay            => v_num_timer_duration);
                                                        
      -- Set code status back to running, so it is not marked as complete yet
      p_wf_activity_instance.code_status := c_status_running;
                                       
    ELSE

      -- Enqueue target workflow activity instance for execution
      enq_target_wf_activity_inst(p_wf_activity_instance => p_wf_activity_instance);
      
    END IF;
      
  END exec_wait_event_activity;

  --------------------------------------------------------------------------------------------------------
  -- procedure name: EXEC_PARALLEL_GATEWAY_ACTIVITY
  -- purpose:        Execute parallel gateway activity
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE exec_parallel_gateway_activity(p_wf_activity_instance IN OUT t_wf_activity_instance)
  IS
  
  BEGIN
    
    -- If parallel gateway activity is complete
    IF p_wf_activity_instance.code_status = c_status_complete THEN         
  
      -- Enqueue target workflow activity instance for execution
      enq_target_wf_activity_inst(p_wf_activity_instance => p_wf_activity_instance);

    END IF;
      
  END exec_parallel_gateway_activity;
 
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: EXEC_INCL_GATEWAY_ACTIVITY
  -- purpose:        Execute inclusive gateway activity
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE exec_incl_gateway_activity(p_wf_activity_instance IN OUT t_wf_activity_instance)
  IS
  
  BEGIN

    -- Set code status to complete in order to end workflow activity instance
    p_wf_activity_instance.code_status := c_status_complete;
  
    -- Enqueue target workflow activity instance for execution
    enq_target_wf_activity_inst(p_wf_activity_instance => p_wf_activity_instance);
      
  END exec_incl_gateway_activity; 

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: EXEC_CALL_ACTIVITY_ACTIVITY
  -- purpose:        Execute call activity activity
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE exec_call_activity_activity(p_wf_activity_instance IN OUT t_wf_activity_instance)
  IS

    a_wf_instance  t_wf_instance;
  
  BEGIN
    
    -- If call activity should be executed (status running)
    IF p_wf_activity_instance.code_status = c_status_running THEN
      
      -- Set record for workflow instance
      a_wf_instance.id_workflow_instance       := NULL;
      a_wf_instance.id_workflow_instance_main  := p_wf_activity_instance.id_workflow_instance_main;
      a_wf_instance.id_workflow_instance_super := p_wf_activity_instance.id_workflow_instance;
      a_wf_instance.id_workflow_definition     := NULL;
      a_wf_instance.id_process_instance        := p_wf_activity_instance.id_process_instance;
      a_wf_instance.date_effective             := p_wf_activity_instance.date_effective;
      a_wf_instance.num_process_priority       := p_wf_activity_instance.num_process_priority;
      a_wf_instance.name_workflow              := p_wf_activity_instance.id_workflow_activity;

      -- Start workflow instance
      start_wf_instance(p_wf_instance => a_wf_instance);

    -- Otherwise
    ELSE
      
      -- Enqueue target workflow activity instance for execution
      enq_target_wf_activity_inst(p_wf_activity_instance => p_wf_activity_instance);
      
    END IF;
      
  END exec_call_activity_activity;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: EXEC_RECEIVE_TASK_ACTIVITY
  -- purpose:        Execute receive task activity
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE exec_receive_task_activity(p_wf_activity_instance IN OUT t_wf_activity_instance)
  IS

  
  BEGIN
    
    -- If receive task should be executed
    IF p_wf_activity_instance.code_status = c_status_running THEN
      
      -- Get input parameter
      get_input_parameter(p_wf_activity_instance => p_wf_activity_instance);
      
      -- Enqueue workflow acitivty for execution by workflow manager
      owner_wfe.lib_wf_queue.enq_wf_aq_activity_inst_out(p_wf_activity_instance => p_wf_activity_instance);
    
    -- If receive task is in error
    ELSIF p_wf_activity_instance.code_status = c_status_error THEN
      
      -- Store error message as variable
      set_wf_variable(p_id_workflow_instance      => p_wf_activity_instance.id_workflow_instance, 
                      p_id_workflow_activity_inst => p_wf_activity_instance.id_workflow_activity_instance, 
                      p_date_effective            => p_wf_activity_instance.date_effective, 
                      p_name_variable             => p_wf_activity_instance.code_status, 
                      p_text_value                => p_wf_activity_instance.text_message);

    -- If receive task is in final state
    ELSIF p_wf_activity_instance.code_status IN (c_status_complete, c_status_cancel, c_status_skip) THEN
      
      -- If some parameter was provided after processing
      IF p_wf_activity_instance.name_parameter IS NOT NULL AND p_wf_activity_instance.text_parameter_value IS NOT NULL THEN
        
        -- Store parameter name and value as variable for the workflow instance
        set_wf_variable(p_id_workflow_instance      => p_wf_activity_instance.id_workflow_instance, 
                        p_id_workflow_activity_inst => c_minus_two, 
                        p_date_effective            => p_wf_activity_instance.date_effective, 
                        p_name_variable             => p_wf_activity_instance.name_parameter, 
                        p_text_value                => p_wf_activity_instance.text_parameter_value);
                        
      END IF;
      
      IF p_wf_activity_instance.code_status = c_status_skip THEN 
        
        -- Store skip message as variable for the workflow activity instance
        set_wf_variable(p_id_workflow_instance      => p_wf_activity_instance.id_workflow_instance, 
                        p_id_workflow_activity_inst => p_wf_activity_instance.id_workflow_activity_instance, 
                        p_date_effective            => p_wf_activity_instance.date_effective, 
                        p_name_variable             => p_wf_activity_instance.code_status, 
                        p_text_value                => p_wf_activity_instance.text_message);
                        
      END IF;
      
      -- Enqueue target workflow activity instance for execution
      enq_target_wf_activity_inst(p_wf_activity_instance => p_wf_activity_instance);
    
    END IF;
      
  END exec_receive_task_activity;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: EXEC_WF_ACTIVITY_INSTANCE
  -- purpose:        Start workflow activity instance
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE exec_wf_activity_instance(p_wf_activity_instance IN t_wf_activity_instance)
  IS
  
    c_proc_name             CONSTANT VARCHAR2(30) := 'EXEC_WF_ACTIVITY_INSTANCE';
    v_step                  VARCHAR2(256);
    
    a_wf_activity_instance  t_wf_activity_instance;
    
    ex_cannot_execute       EXCEPTION;
  
  BEGIN
    
    -- Set workflow activity instance record
    v_step := 'Set workflow activity instance record';
    a_wf_activity_instance := p_wf_activity_instance;
  
    -- If code status is new
    IF a_wf_activity_instance.code_status = c_status_new THEN
      
      -- Start workflow activity instance
      v_step := 'Start workflow activity instance';
      start_wf_activity_instance(p_wf_activity_instance => a_wf_activity_instance);
      
      -- Commit
      COMMIT;
      
    END IF;
    
    -- Check if workflow activity instance should be suspended (only applies for new receive task)
    v_step := 'Check if workflow activity instance should be suspended';
    -- If workflow activity instance is runnning and workflow instance is suspended
    IF is_wf_instance_suspend(p_id_workflow_instance_main => a_wf_activity_instance.id_workflow_instance_main)
        AND a_wf_activity_instance.code_activity_type = c_receive_task
        AND a_wf_activity_instance.code_status = c_status_running THEN
      
      -- Suspend workflow activity instance
      v_step := 'Suspend workflow activity instance';
      -- Set message
      a_wf_activity_instance.text_message := 'Workflow instance is suspended, activity cannot be executed! Id workflow activity instance - '||a_wf_activity_instance.id_workflow_activity_instance;
      -- Log error
      owner_wfe.lib_wf_log_api.log_error_event(p_name_event   => c_proc_name,                         
                                               p_text_message => a_wf_activity_instance.text_message);
      -- Set workflow activity instance status to error 
      error_wf_activity_instance(p_wf_activity_instance => a_wf_activity_instance);
    
    -- Otherwise proceed
    ELSE
    
      BEGIN
                      
        -- Execute activity instance for given activity type
        IF a_wf_activity_instance.code_activity_type = c_start_event THEN
          
          -- Execute start event activity
          v_step := 'Execute start event activity';
          exec_start_event_activity(p_wf_activity_instance => a_wf_activity_instance);
          
        ELSIF a_wf_activity_instance.code_activity_type = c_end_event THEN
          
          -- Execute end event activity
          v_step := 'Execute end event activity';
          exec_end_event_activity(p_wf_activity_instance => a_wf_activity_instance);
          
        ELSIF a_wf_activity_instance.code_activity_type = c_wait_event THEN
          
          -- Execute wait event activity
          v_step := 'Execute wait event activity';
          exec_wait_event_activity(p_wf_activity_instance => a_wf_activity_instance);
        
        ELSIF a_wf_activity_instance.code_activity_type = c_parallel_gateway THEN
          
          -- Execute parallel gateway
          v_step := 'Execute parallel gateway';
          exec_parallel_gateway_activity(p_wf_activity_instance => a_wf_activity_instance);
        
        ELSIF a_wf_activity_instance.code_activity_type = c_inclusive_gateway THEN
          
          -- Check if inclusive gateway can be executed
          v_step := 'Check if inclusive gateway can be executed';
          -- If it is running
          IF a_wf_activity_instance.code_status = c_status_running
            -- and it cannot be executed, because it was already executed
            AND NOT can_exec_wf_activity_instance(p_id_workflow_instance => a_wf_activity_instance.id_workflow_instance,
                                                  p_id_workflow_activity => a_wf_activity_instance.id_workflow_activity,
                                                  p_date_effective       => a_wf_activity_instance.date_effective) THEN

            -- Raise exception
            RAISE ex_cannot_execute;
            
          END IF; 
          
          -- Execute inclusive gateway
          v_step := 'Execute inclusive gateway';
          exec_incl_gateway_activity(p_wf_activity_instance => a_wf_activity_instance);
          
        ELSIF a_wf_activity_instance.code_activity_type = c_receive_task THEN
                 
          -- Check if receive task can be executed
          v_step := 'Check if receive task can be executed';
          -- If it is running
          IF a_wf_activity_instance.code_status = c_status_running
            -- and it cannot be executed, because it was already executed
            AND NOT can_exec_wf_activity_instance(p_id_workflow_instance => a_wf_activity_instance.id_workflow_instance,
                                                  p_id_workflow_activity => a_wf_activity_instance.id_workflow_activity,
                                                  p_date_effective       => a_wf_activity_instance.date_effective) THEN

            -- Raise exception
            RAISE ex_cannot_execute;
            
          END IF; 
        
          -- Execute receive task
          v_step := 'Execute receive task';
          exec_receive_task_activity(p_wf_activity_instance => a_wf_activity_instance);
        
        ELSIF a_wf_activity_instance.code_activity_type = c_call_activity THEN
          
          -- Execute call activity  
          v_step := 'Execute call activity ';
          exec_call_activity_activity(p_wf_activity_instance => a_wf_activity_instance);
        
        END IF;
        
        -- End workflow activity instance
        v_step := 'End workflow activity instance';
        end_wf_activity_instance(p_wf_activity_instance => a_wf_activity_instance);
                  
      EXCEPTION
        WHEN ex_cannot_execute THEN
          -- Rollback
          ROLLBACK;
          -- Set message
          a_wf_activity_instance.text_message := 'Workflow activity instance (Id - '||a_wf_activity_instance.id_workflow_activity_instance||') cannot be executed. There is more then one instance of this activity!';
          -- Log error
          owner_wfe.lib_wf_log_api.log_error_event(p_name_event   => c_proc_name,                         
                                                   p_text_message => a_wf_activity_instance.text_message);
          -- Set workflow activity instance status to cancel 
          cancel_wf_activity_instance(p_wf_activity_instance => a_wf_activity_instance);
          
        WHEN OTHERS THEN
          -- Rollback
          ROLLBACK;
          -- Set message
          a_wf_activity_instance.text_message := c_mod_name||'.'||c_proc_name||' - ('||v_step||'): '||SUBSTR(dbms_utility.format_error_stack, 1, 1500);
          -- Log error
          owner_wfe.lib_wf_log_api.log_error_event(p_name_event   => c_proc_name,                         
                                                   p_text_message => a_wf_activity_instance.text_message);
          -- Set workflow activity instance status to error 
          error_wf_activity_instance(p_wf_activity_instance => a_wf_activity_instance);
             
      END;
      
    END IF;
    
    -- Commit
    COMMIT;
    
  EXCEPTION
    WHEN OTHERS THEN
      -- Rollback
      ROLLBACK;
      -- Set message
      v_text_message := c_mod_name||'.'||c_proc_name||' - ('||v_step||'): '||SUBSTR(dbms_utility.format_error_stack, 1, 1500);
      -- Log error
      owner_wfe.lib_wf_log_api.log_error_event(p_name_event   => c_proc_name,                         
                                               p_text_message => v_text_message);
          
  END exec_wf_activity_instance;
  
END lib_wf_engine;
/
