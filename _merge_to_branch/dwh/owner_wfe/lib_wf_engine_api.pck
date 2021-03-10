CREATE OR REPLACE PACKAGE owner_wfe.lib_wf_engine_api IS

  ---------------------------------------------------------------------------------------------------------
  -- author:  Ludek
  -- created: 11.05.2020
  -- purpose: Controll API for workflow process
  ---------------------------------------------------------------------------------------------------------

  ---------------------------------------------------------------------------------------------------------
  -- Global variables
  ---------------------------------------------------------------------------------------------------------  

  ---------------------------------------------------------------------------------------------------------
  -- function name: CHECK_EXISTING_WORKFLOW
  -- purpose:       Find out if workflow exists in repository
  ---------------------------------------------------------------------------------------------------------  
  FUNCTION check_existing_workflow(p_name_workflow IN VARCHAR2) RETURN BOOLEAN;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CHECK_ERROR_WORKFLOW_ACTIVITY
  -- purpose:        Find out if there are failed workflow activities for given workflow process
  ---------------------------------------------------------------------------------------------------------
  FUNCTION check_error_workflow_activity(p_id_workflow_instance_main IN INTEGER) RETURN BOOLEAN;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CHECK_UNPROC_WORKFLOW_ACTIVITY
  -- purpose:        Find out if there are unprocessed workflow activities in inbound and outbound queue for given workflow process
  ---------------------------------------------------------------------------------------------------------
  FUNCTION check_unproc_workflow_activity(p_id_workflow_instance_main IN INTEGER) RETURN BOOLEAN;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: START_WORKFLOW
  -- purpose:        Start workflow process
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE start_workflow(p_name_workflow        IN VARCHAR2,
                           p_id_process_instance  IN INTEGER,
                           p_date_effective       IN DATE,
                           p_num_process_priority IN INTEGER,
                           p_id_workflow_instance OUT INTEGER);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: RESTART_WORKFLOW
  -- purpose:        Restart fail activities within workflow process
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE restart_workflow(p_id_workflow_instance_main IN INTEGER);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: SUSPEND_WORKFLOW
  -- purpose:        Suspend workflow process
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE suspend_workflow(p_id_workflow_instance_main IN INTEGER);
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: RESUME_WORKFLOW
  -- purpose:        Resume workflow process
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE resume_workflow(p_id_workflow_instance_main IN INTEGER);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CANCEL_WORKFLOW
  -- purpose:        Cancel workflow process
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE cancel_workflow(p_id_workflow_instance_main IN INTEGER,
                            p_text_message              IN VARCHAR2 DEFAULT NULL);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: RESTART_WORKFLOW_ACTIVITY
  -- purpose:        Restart failed workflow activity instance
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE restart_workflow_activity(p_id_workflow_activity_inst IN INTEGER,
                                      p_date_effective            IN DATE);
                                    
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: SKIP_WORKFLOW_ACTIVITY
  -- purpose:        Skip failed workflow activity instance
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE skip_workflow_activity(p_id_workflow_activity_inst IN INTEGER,
                                   p_date_effective            IN DATE);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: START_AFTER_WORKFLOW_ACTIVITY
  -- purpose:        Cancel stuck workflow activity instance and start after specified workflow activity
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE start_after_workflow_activity(p_id_workflow_activity_inst  IN INTEGER,
                                          p_date_effective             IN DATE,
                                          p_id_workflow_activity_start IN VARCHAR2);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: START_BEFORE_WORKFLOW_ACTIVITY
  -- purpose:        Cancel stuck workflow activity instance and start before specified workflow activity
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE start_before_workflow_activity(p_id_workflow_activity_inst  IN INTEGER,
                                           p_date_effective             IN DATE,
                                           p_id_workflow_activity_start IN VARCHAR2);
                          
END lib_wf_engine_api;        
/
CREATE OR REPLACE PACKAGE BODY owner_wfe.lib_wf_engine_api IS

  ---------------------------------------------------------------------------------------------------------
  -- Global variables
  ---------------------------------------------------------------------------------------------------------  
  c_mod_name                   CONSTANT VARCHAR2(30) := 'LIB_WF_ENGINE_API';
  c_status_new                 CONSTANT VARCHAR2(30) := owner_wfe.lib_wf_constant.c_new;
  c_minus_two                  CONSTANT INTEGER := owner_wfe.lib_wf_constant.c_minus_two;
  c_status_error               CONSTANT VARCHAR2(30) := owner_wfe.lib_wf_constant.c_error;
  c_date_future                CONSTANT DATE := owner_wfe.lib_wf_constant.c_date_future;

  -- Workflow exception queue name
  c_wf_aqn_activity_inst_in_e  CONSTANT VARCHAR2(55) := owner_wfe.lib_wf_constant.c_wf_aqn_activity_inst_in_e;
  c_wf_aqn_activity_inst_out_e CONSTANT VARCHAR2(55) := owner_wfe.lib_wf_constant.c_wf_aqn_activity_inst_out_e;

  -- Workflow activity type
  c_receive_task               CONSTANT VARCHAR2(100) := owner_wfe.lib_wf_constant.c_receive_task;
  c_call_activity              CONSTANT VARCHAR2(100) := owner_wfe.lib_wf_constant.c_call_activity;
    
  v_text_message            VARCHAR2(4000);
  
  ---------------------------------------------------------------------------------------------------------
  -- function name: CHECK_EXISTING_WORKFLOW
  -- purpose:       Find out if workflow exists in repository
  ---------------------------------------------------------------------------------------------------------  
  FUNCTION check_existing_workflow(p_name_workflow IN VARCHAR2) RETURN BOOLEAN
  IS
  
    v_cnt INTEGER;
  
  BEGIN
  
    SELECT
       COUNT(1) 
      INTO
       v_cnt
    FROM owner_wfe.wf_rep_definition
    WHERE name_workflow = p_name_workflow
      AND dtime_valid_to = c_date_future;

    -- Return result
    IF v_cnt = 1 THEN
      RETURN TRUE;
    ELSE
      RETURN FALSE;
    END IF;
    
  END check_existing_workflow;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CHECK_ERROR_WF_ACTIVITY
  -- purpose:        Find out if there are failed workflow activities for given workflow process
  ---------------------------------------------------------------------------------------------------------
  FUNCTION check_error_workflow_activity(p_id_workflow_instance_main IN INTEGER) RETURN BOOLEAN
  IS
  
    v_cnt_error  INTEGER;

  BEGIN
    
    -- Find out if process has some failed activities                                      
    SELECT 
       COUNT(1)
      INTO
       v_cnt_error
    FROM owner_wfe.wf_run_activity_instance
    WHERE id_workflow_instance_main = p_id_workflow_instance_main
      AND code_status = c_status_error;

    IF v_cnt_error = 0 THEN
      
      -- Find out if there are some unprocessed error messages in queue
      SELECT 
         COUNT(1) AS cnt_error
        INTO
         v_cnt_error
      FROM owner_wfe.wf_aq_activity_inst_in aiq
      JOIN owner_wfe.wf_run_activity_instance ai ON ai.id_workflow_activity_instance = aiq.user_data.id_workflow_activity_instance
      WHERE aiq.user_data.id_workflow_instance_main = p_id_workflow_instance_main
        AND aiq.user_data.code_status = c_status_error;
    
    END IF;
                                           
    -- Set result
    IF v_cnt_error = 0 THEN
      -- If there is no failed activity set false
      RETURN FALSE;
    ELSE
      -- Otherwise set true
      RETURN TRUE;
    END IF;

  END check_error_workflow_activity;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CHECK_UNPROC_WORKFLOW_ACTIVITY
  -- purpose:        Find out if there are unprocessed workflow activities in inbound and outbound queue for given workflow process
  ---------------------------------------------------------------------------------------------------------
  FUNCTION check_unproc_workflow_activity(p_id_workflow_instance_main IN INTEGER) RETURN BOOLEAN
  IS
  
    v_cnt_in  INTEGER;
    v_cnt_out INTEGER;

  BEGIN
  
    -- Find out if there are unprocessed inbound activities
    SELECT 
       COUNT(1)
      INTO
       v_cnt_in
    FROM owner_wfe.wf_aq_activity_inst_in aiq
    WHERE aiq.user_data.id_workflow_instance_main = p_id_workflow_instance_main;  
    
    -- Find out if there are unprocessed outbound activities
    SELECT 
       COUNT(1)
      INTO
       v_cnt_out
    FROM owner_wfe.wf_aq_activity_inst_out aiq
    WHERE aiq.user_data.id_workflow_instance_main = p_id_workflow_instance_main;
                                           
    -- Set result
    IF v_cnt_in = 0 AND v_cnt_out = 0 THEN
      -- If there is no unprocessed activity set false
      RETURN FALSE;
    ELSE
      -- Otherwise set true
      RETURN TRUE;
    END IF;

  END check_unproc_workflow_activity;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: START_WORKFLOW
  -- purpose:        Start workflow process
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE start_workflow(p_name_workflow        IN VARCHAR2,
                           p_id_process_instance  IN INTEGER,
                           p_date_effective       IN DATE,
                           p_num_process_priority IN INTEGER,            
                           p_id_workflow_instance OUT INTEGER) IS
    
    a_wf_instance  owner_wfe.lib_wf_engine.t_wf_instance;
    
  BEGIN
    
    -- Set record for workflow instance
    a_wf_instance.id_workflow_instance       := NULL;
    a_wf_instance.id_workflow_instance_main  := NULL;
    a_wf_instance.id_workflow_instance_super := c_minus_two;
    a_wf_instance.id_workflow_definition     := NULL;
    a_wf_instance.id_process_instance        := p_id_process_instance;
    a_wf_instance.date_effective             := p_date_effective;
    a_wf_instance.num_process_priority       := p_num_process_priority;
    a_wf_instance.name_workflow              := p_name_workflow;

    -- Start workflow instance
    owner_wfe.lib_wf_engine.start_wf_instance(p_wf_instance => a_wf_instance);

    -- Set output parameter
    p_id_workflow_instance := a_wf_instance.id_workflow_instance;
        
  END start_workflow; 

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: RESTART_WORKFLOW
  -- purpose:        Restart fail activities within workflow process
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE restart_workflow(p_id_workflow_instance_main IN INTEGER) IS

    CURSOR c_wf_run_act_inst_error IS
      SELECT 
         id_workflow_activity_instance, 
         date_effective
      FROM owner_wfe.wf_run_activity_instance
      WHERE id_workflow_instance_main = p_id_workflow_instance_main
        AND code_status = c_status_error;
                               
  BEGIN
    
    -- Loop through failed activities
    FOR i IN c_wf_run_act_inst_error
    LOOP
      
      -- Restart workflow activity
      restart_workflow_activity(p_id_workflow_activity_inst => i.id_workflow_activity_instance,
                                p_date_effective            => i.date_effective);
                                
    END LOOP;
        
  END restart_workflow; 
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: SUSPEND_WORKFLOW
  -- purpose:        Suspend workflow process
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE suspend_workflow(p_id_workflow_instance_main IN INTEGER)
  IS
  
  BEGIN
    
    -- Suspend workflow process
    owner_wfe.lib_wf_engine.suspend_wf_instance(p_id_workflow_instance_main => p_id_workflow_instance_main);
    
  END suspend_workflow;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: RESUME_WORKFLOW
  -- purpose:        Resume workflow process
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE resume_workflow(p_id_workflow_instance_main IN INTEGER)
  IS
  
  BEGIN
    
    -- Resume workflow process
    owner_wfe.lib_wf_engine.resume_wf_instance(p_id_workflow_instance_main => p_id_workflow_instance_main);
    
    -- Restart messages from in exception queue
    owner_wfe.lib_wf_queue.restart_wf_aq_activity_inst_in(p_name_queue                => c_wf_aqn_activity_inst_in_e,
                                                          p_id_workflow_instance_main => p_id_workflow_instance_main);
    
    -- Restart messages from out exception queue
    owner_wfe.lib_wf_queue.restart_wf_aq_activ_inst_out(p_name_queue                => c_wf_aqn_activity_inst_out_e,
                                                        p_id_workflow_instance_main => p_id_workflow_instance_main);
    
  END resume_workflow; 

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CANCEL_WORKFLOW
  -- purpose:        Cancel workflow process
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE cancel_workflow(p_id_workflow_instance_main IN INTEGER,
                            p_text_message              IN VARCHAR2 DEFAULT NULL)
  IS
  
    CURSOR c_wf_run_instance IS
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
      FROM owner_wfe.wf_run_instance
      WHERE id_workflow_instance_main = p_id_workflow_instance_main
      ORDER BY id_workflow_instance DESC;

    a_wf_instance    owner_wfe.lib_wf_engine.t_wf_instance;

  BEGIN
    
    -- If workflow instance is suspended proceed
    IF owner_wfe.lib_wf_engine.is_wf_instance_suspend(p_id_workflow_instance_main => p_id_workflow_instance_main) THEN
      
      -- Loop throught all running workflow instances belongig to main workflow
      FOR i IN c_wf_run_instance
      LOOP
        
        -- Set record for workflow instance
        a_wf_instance.id_workflow_instance       := i.id_workflow_instance;
        a_wf_instance.id_workflow_instance_main  := i.id_workflow_instance_main;
        a_wf_instance.id_workflow_instance_super := i.id_workflow_instance_super;
        a_wf_instance.id_workflow_definition     := i.id_workflow_definition;
        a_wf_instance.id_process_instance        := i.id_process_instance;
        a_wf_instance.date_effective             := i.date_effective;
        a_wf_instance.num_process_priority       := i.num_process_priority;
        a_wf_instance.name_workflow              := i.name_workflow; 
        a_wf_instance.code_status                := NULL;
      
        -- Cancel workflow instance
        owner_wfe.lib_wf_engine.cancel_wf_instance(p_wf_instance  => a_wf_instance,
                                                   p_text_message => p_text_message);
        
      END LOOP;
      
      -- Remove information about suspended process
      DELETE FROM owner_wfe.wf_run_instance_suspend WHERE id_workflow_instance_main = p_id_workflow_instance_main;
      
      -- Purge unprocessed messages in input queue for canceled process
      owner_wfe.lib_wf_queue.purge_wf_aq_activity_inst_in(p_purge_condition => 'qtview.user_data.id_workflow_instance_main = '||p_id_workflow_instance_main);

      -- Purge unprocessed messages in output queue for canceled process
      owner_wfe.lib_wf_queue.purge_wf_aq_activity_inst_out(p_purge_condition => 'qtview.user_data.id_workflow_instance_main = '||p_id_workflow_instance_main);     
    
    -- Otherwise
    ELSE
      
      -- Raise error
      raise_application_error(-20001, 'Workflow process is not suspended and cannot be cancelled!'); 
      
    END IF;
    
  END cancel_workflow; 
 
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: RESTART_WORKFLOW_ACTIVITY
  -- purpose:        Restart failed workflow activity instance
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE restart_workflow_activity(p_id_workflow_activity_inst IN INTEGER,
                                      p_date_effective            IN DATE) IS

    a_wf_activity_instance  owner_wfe.lib_wf_engine.t_wf_activity_instance;
    
  BEGIN

    -- Get information about worfklow activity instance
    a_wf_activity_instance := owner_wfe.lib_wf_engine.get_wf_activity_inst_info(p_id_workflow_activity_inst => p_id_workflow_activity_inst,
                                                                                p_date_effective            => p_date_effective);
    
    -- Restart failed workflow activity instance
    owner_wfe.lib_wf_engine.restart_wf_activity_instance(p_wf_activity_instance => a_wf_activity_instance);
        
  END restart_workflow_activity;                      

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: SKIP_WORKFLOW_ACTIVITY
  -- purpose:        Skip failed workflow activity instance
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE skip_workflow_activity(p_id_workflow_activity_inst IN INTEGER,
                                   p_date_effective            IN DATE) IS

    a_wf_activity_instance  owner_wfe.lib_wf_engine.t_wf_activity_instance;
    
  BEGIN

    -- Get information about worfklow activity instance
    a_wf_activity_instance := owner_wfe.lib_wf_engine.get_wf_activity_inst_info(p_id_workflow_activity_inst => p_id_workflow_activity_inst,
                                                                                p_date_effective            => p_date_effective);
    
    -- Skip workflow activity instance
    owner_wfe.lib_wf_engine.skip_wf_activity_instance(p_wf_activity_instance => a_wf_activity_instance);
        
  END skip_workflow_activity;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: START_BEFORE_WORKFLOW_ACTIVITY
  -- purpose:        Cancel stuck workflow activity instance and start before specified workflow activity
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE start_before_workflow_activity(p_id_workflow_activity_inst  IN INTEGER,
                                           p_date_effective             IN DATE,
                                           p_id_workflow_activity_start IN VARCHAR2) IS

    c_proc_name             CONSTANT VARCHAR2(30) := 'START_BEFORE_WORKFLOW_ACTIVITY';
    v_step                  VARCHAR2(256);
    
    a_wf_activity           owner_wfe.lib_wf_engine.t_wf_activity;
    a_inf_wf_instance       owner_wfe.lib_wf_engine.t_wf_instance;
    a_wf_activity_instance  owner_wfe.lib_wf_engine.t_wf_activity_instance;
    
  BEGIN

    -- Get information about worfklow activity instance
    v_step := 'Get information about worfklow activity instance';
    a_wf_activity_instance := owner_wfe.lib_wf_engine.get_wf_activity_inst_info(p_id_workflow_activity_inst => p_id_workflow_activity_inst,
                                                                                p_date_effective            => p_date_effective);
    
    -- If case it is receive task or call activity you can proceed 
    IF a_wf_activity_instance.code_activity_type IN (c_receive_task, c_call_activity) THEN
            
      -- In case of call activity activity type cancel inferior workflow instance
      IF a_wf_activity_instance.code_activity_type = c_call_activity THEN
   
        -- Get information about inferior workflow instance based on superior id and workflow name
        v_step := 'Get information about inferior workflow instance based on superior id and workflow name';
        a_inf_wf_instance := owner_wfe.lib_wf_engine.get_inf_wf_instance_info(p_id_workflow_instance_main  => a_wf_activity_instance.id_workflow_instance_main,
                                                                              p_id_workflow_instance_super => a_wf_activity_instance.id_workflow_instance,
                                                                              p_date_effective             => a_wf_activity_instance.date_effective,
                                                                              p_name_workflow              => a_wf_activity_instance.id_workflow_activity);
                                                      
        -- Cancel inferior worfklow instance
        v_step := 'Cancel inferior worfklow instance';
        owner_wfe.lib_wf_engine.cancel_wf_instance(p_wf_instance  => a_inf_wf_instance,
                                                   p_text_message => 'Force cancel by '||c_proc_name,
                                                   p_flag_force   => TRUE);
                                                   
        -- Purge unprocessed messages in input queue for canceled inferior workflow instance
        v_step := 'Purge unprocessed messages in input queue for canceled inferior workflow instance';
        owner_wfe.lib_wf_queue.purge_wf_aq_activity_inst_in(p_purge_condition => 'qtview.user_data.id_workflow_instance = '||a_inf_wf_instance.id_workflow_instance);

        -- Purge unprocessed messages in output queue for canceled inferior workflow instance
        v_step := 'Purge unprocessed messages in output queue for canceled inferior workflow instance';
        owner_wfe.lib_wf_queue.purge_wf_aq_activity_inst_out(p_purge_condition => 'qtview.user_data.id_workflow_instance = '||a_inf_wf_instance.id_workflow_instance);
                                                          
      END IF;
      
      -- Cancel workflow activity instance
      v_step := 'Cancel workflow activity instance';
      owner_wfe.lib_wf_engine.cancel_wf_activity_instance(p_wf_activity_instance => a_wf_activity_instance);
      
      -- Get information about activity after which execution should start
      v_step := 'Get information about activity after which execution should start';
      a_wf_activity := owner_wfe.lib_wf_engine.get_wf_activity_info(p_id_workflow_definition => a_wf_activity_instance.id_workflow_definition,
                                                                    p_id_workflow_activity   => p_id_workflow_activity_start);   
                                            
      -- Set record for workflow activity instance
      a_wf_activity_instance.id_workflow_activity_instance := owner_wfe.lib_wf_engine.get_id_workflow_act_inst_seq;
      a_wf_activity_instance.id_workflow_activity          := a_wf_activity.id_workflow_activity;
      a_wf_activity_instance.id_workflow_activity_super    := a_wf_activity_instance.id_workflow_activity; 
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
    
    ELSE
      
      -- Raise error
      raise_application_error(-20002, 'This action can be done only for call activity or receive task!');  
      
    END IF;   

    -- Commit
    COMMIT; 
      
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
      raise_application_error(-20003, v_text_message);    

  END start_before_workflow_activity;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: START_AFTER_WORKFLOW_ACTIVITY
  -- purpose:        Cancel stuck workflow activity instance and start after specified workflow activity
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE start_after_workflow_activity(p_id_workflow_activity_inst  IN INTEGER,
                                          p_date_effective             IN DATE,
                                          p_id_workflow_activity_start IN VARCHAR2) IS

    c_proc_name             CONSTANT VARCHAR2(30) := 'START_AFTER_WORKFLOW_ACTIVITY';
    v_step                  VARCHAR2(256);

    a_wf_activity           owner_wfe.lib_wf_engine.t_wf_activity;
    a_inf_wf_instance       owner_wfe.lib_wf_engine.t_wf_instance;
    a_wf_activity_instance  owner_wfe.lib_wf_engine.t_wf_activity_instance;
    
  BEGIN

    -- Get information about worfklow activity instance
    v_step := 'Get information about worfklow activity instance';
    a_wf_activity_instance := owner_wfe.lib_wf_engine.get_wf_activity_inst_info(p_id_workflow_activity_inst => p_id_workflow_activity_inst,
                                                                                p_date_effective            => p_date_effective);
    
    -- If case it is receive task or call activity you can proceed 
    IF a_wf_activity_instance.code_activity_type IN (c_receive_task, c_call_activity) THEN
            
      -- In case of call activity activity type cancel inferior workflow instance
      IF a_wf_activity_instance.code_activity_type = c_call_activity THEN
   
        -- Get information about inferior workflow instance based on superior id and workflow name
        v_step := 'Get information about inferior workflow instance based on superior id and workflow name';
        a_inf_wf_instance := owner_wfe.lib_wf_engine.get_inf_wf_instance_info(p_id_workflow_instance_main  => a_wf_activity_instance.id_workflow_instance_main,
                                                                              p_id_workflow_instance_super => a_wf_activity_instance.id_workflow_instance,
                                                                              p_date_effective             => a_wf_activity_instance.date_effective,
                                                                              p_name_workflow              => a_wf_activity_instance.id_workflow_activity);
                                                      
        -- Cancel inferior worfklow instance
        v_step := 'Cancel inferior worfklow instance';
        owner_wfe.lib_wf_engine.cancel_wf_instance(p_wf_instance  => a_inf_wf_instance,
                                                   p_text_message => 'Force cancel by '||c_proc_name,
                                                   p_flag_force   => TRUE);
                                                   
        -- Purge unprocessed messages in input queue for canceled inferior workflow instance
        v_step := 'Purge unprocessed messages in input queue for canceled inferior workflow instance';
        owner_wfe.lib_wf_queue.purge_wf_aq_activity_inst_in(p_purge_condition => 'qtview.user_data.id_workflow_instance = '||a_inf_wf_instance.id_workflow_instance);

        -- Purge unprocessed messages in output queue for canceled inferior workflow instance
        v_step := 'Purge unprocessed messages in output queue for canceled inferior workflow instance';
        owner_wfe.lib_wf_queue.purge_wf_aq_activity_inst_out(p_purge_condition => 'qtview.user_data.id_workflow_instance = '||a_inf_wf_instance.id_workflow_instance);
                                                          
      END IF;
      
      -- Cancel workflow activity instance
      v_step := 'Cancel workflow activity instance';
      owner_wfe.lib_wf_engine.cancel_wf_activity_instance(p_wf_activity_instance => a_wf_activity_instance);
      
      -- Get information about activity after which execution should start
      v_step := 'Get information about activity after which execution should start';
      a_wf_activity := owner_wfe.lib_wf_engine.get_wf_activity_info(p_id_workflow_definition => a_wf_activity_instance.id_workflow_definition,
                                                                    p_id_workflow_activity   => p_id_workflow_activity_start);   
                                            
      -- Set record for target activity instance  
      a_wf_activity_instance.id_workflow_activity       := a_wf_activity.id_workflow_activity;
      a_wf_activity_instance.id_workflow_activity_super := a_wf_activity_instance.id_workflow_activity;
      a_wf_activity_instance.code_activity_type         := a_wf_activity.code_activity_type;
      a_wf_activity_instance.name_activity              := a_wf_activity.name_activity; 

      -- Enqueu target workflow activity
      v_step := 'Enqueu target workflow activity';
      owner_wfe.lib_wf_engine.enq_target_wf_activity_inst(p_wf_activity_instance => a_wf_activity_instance);
   
    ELSE
      
      -- Raise error
      raise_application_error(-20004, 'This action can be done only for call activity or receive task!');  
      
    END IF;   

    -- Commit
    COMMIT; 
      
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
    raise_application_error(-20005, v_text_message);  
    
  END start_after_workflow_activity;

END lib_wf_engine_api;
/
