CREATE OR REPLACE PACKAGE owner_wfe.lib_wf_queue_api IS

  ---------------------------------------------------------------------------------------------------------
  -- author:  Ludek
  -- created: 11.05.2020
  -- purpose: Queueu api for worfklow manager
  ---------------------------------------------------------------------------------------------------------

  ---------------------------------------------------------------------------------------------------------
  -- Global variables
  ---------------------------------------------------------------------------------------------------------  

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: IS_WF_ACTIVITY_INST_OUT_EMPTY
  -- purpose:        Find out if workflow outbound queue is empty
  ---------------------------------------------------------------------------------------------------------   
  FUNCTION is_wf_activity_inst_out_empty RETURN BOOLEAN RESULT_CACHE;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: DEQ_WF_AQ_ACTIVITY_INST_OUT
  -- purpose:        Get workflow activity instance for processing by workflow manager
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE get_wf_activity_instance(p_id_workflow_activity_inst OUT INTEGER,
                                     p_id_process_instance       OUT INTEGER,
                                     p_date_effective            OUT DATE,
                                     p_name_module               OUT VARCHAR2,
                                     p_text_data                 OUT VARCHAR2);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: RESTART_WF_ACTIVITY_INST_IN
  -- purpose:        Purge data from queue WF_AQ_ACTIVITY_INST_IN for given workflow activity instance
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE purge_wf_activity_inst_in(p_id_workflow_activity_inst IN INTEGER);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: SET_WF_ACTIVITY_INSTANCE_RES
  -- purpose:        Set workflow activity instance result after execution by workflow manager
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE set_wf_activity_instance_res(p_id_workflow_activity_inst IN INTEGER,
                                         p_id_process_instance       IN INTEGER,
                                         p_date_effective            IN DATE,                    
                                         p_code_status               IN VARCHAR2,
                                         p_name_parameter            IN VARCHAR2 DEFAULT NULL,
                                         p_text_parameter_value      IN VARCHAR2 DEFAULT NULL,
                                         p_text_message              IN VARCHAR2 DEFAULT NULL);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: RESTART_WF_ACTIVITY_INST_IN
  -- purpose:        Restart messages in queue WF_AQ_ACTIVITY_INST_IN for given queue name, main workflow instance and workflow activity instance (optional)
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE restart_wf_activity_inst_in(p_name_queue                IN VARCHAR2,
                                        p_id_workflow_instance_main IN INTEGER,
                                        p_id_workflow_activity_inst IN INTEGER DEFAULT NULL);
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: RESTART_WF_ACTIVITY_INST_OUT
  -- purpose:        Restart messages in queue WF_AQ_ACTIVITY_INST_OUT for given queue name, main workflow instance and workflow activity instance (optional)
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE restart_wf_activity_inst_out(p_name_queue                IN VARCHAR2,
                                         p_id_workflow_instance_main IN INTEGER,
                                         p_id_workflow_activity_inst IN INTEGER DEFAULT NULL);
      
END lib_wf_queue_api;        
/
CREATE OR REPLACE PACKAGE BODY owner_wfe.lib_wf_queue_api IS

  ---------------------------------------------------------------------------------------------------------
  -- Global variables
  ---------------------------------------------------------------------------------------------------------  
  c_mod_name                CONSTANT VARCHAR2(30) := 'LIB_WF_QUEUE_API';

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: IS_WF_ACTIVITY_INST_OUT_EMPTY
  -- purpose:        Find out if workflow outbound queue is empty
  ---------------------------------------------------------------------------------------------------------   
  FUNCTION is_wf_activity_inst_out_empty RETURN BOOLEAN RESULT_CACHE RELIES_ON (owner_wfe.wf_aq_activity_inst_out)  

  IS
    
    v_cnt INTEGER;
    
  BEGIN
  
    SELECT 
      COUNT(1)
     INTO
      v_cnt 
    FROM owner_wfe.wf_aq_activity_inst_out
    WHERE exception_queue IS NULL;
    
    IF v_cnt = 0 THEN
      RETURN TRUE;
    ELSE
      RETURN FALSE;
    END IF;
    
  END is_wf_activity_inst_out_empty;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: DEQ_WF_AQ_ACTIVITY_INST_OUT
  -- purpose:        Get workflow activity instance for execution by workflow manager
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE get_wf_activity_instance(p_id_workflow_activity_inst OUT INTEGER,
                                     p_id_process_instance       OUT INTEGER,
                                     p_date_effective            OUT DATE,
                                     p_name_module               OUT VARCHAR2,
                                     p_text_data                 OUT VARCHAR2)
  IS
        
  BEGIN
    
    -- Dequeue workflow activity instance for execution by workflow manager 
    owner_wfe.lib_wf_queue.deq_wf_aq_activity_inst_out(p_id_workflow_activity_inst => p_id_workflow_activity_inst,
                                                       p_id_process_instance       => p_id_process_instance,
                                                       p_date_effective            => p_date_effective,
                                                       p_name_module               => p_name_module,
                                                       p_text_data                 => p_text_data);

  END get_wf_activity_instance;   

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: SET_WF_ACTIVITY_INSTANCE_RES
  -- purpose:        Set workflow activity instance result after execution by workflow manager
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE set_wf_activity_instance_res(p_id_workflow_activity_inst IN INTEGER,
                                         p_id_process_instance       IN INTEGER,
                                         p_date_effective            IN DATE,                    
                                         p_code_status               IN VARCHAR2,
                                         p_name_parameter            IN VARCHAR2 DEFAULT NULL,
                                         p_text_parameter_value      IN VARCHAR2 DEFAULT NULL,
                                         p_text_message              IN VARCHAR2 DEFAULT NULL)
  IS
  
    a_wf_activity_instance  owner_wfe.lib_wf_engine.t_wf_activity_instance;
        
  BEGIN
    
    -- Get information about workflow activity instance
    a_wf_activity_instance := owner_wfe.lib_wf_engine.get_wf_activity_inst_info(p_id_workflow_activity_inst => p_id_workflow_activity_inst,
                                                                                p_date_effective            => p_date_effective);
    
    -- Add result from executed receive task activity
    a_wf_activity_instance.name_module                   := NULL;
    a_wf_activity_instance.text_data                     := NULL;
    a_wf_activity_instance.name_parameter                := p_name_parameter;
    a_wf_activity_instance.text_parameter_value          := p_text_parameter_value;
    a_wf_activity_instance.text_message                  := p_text_message;
    a_wf_activity_instance.code_status                   := p_code_status;
    
    -- Enqueue workflow activity instance message into queue WF_AQ_ACTIVITY_INST_IN
    owner_wfe.lib_wf_queue.enq_wf_aq_activity_inst_in(p_wf_activity_instance => a_wf_activity_instance);
    
  END set_wf_activity_instance_res;   
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: RESTART_WF_ACTIVITY_INST_IN
  -- purpose:        Purge data from queue WF_AQ_ACTIVITY_INST_IN for given workflow activity instance
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE purge_wf_activity_inst_in(p_id_workflow_activity_inst IN INTEGER)
  IS
            
  BEGIN
    
    -- Purge data from queue WF_AQ_ACTIVITY_INST_IN for given workflow activity instance
    owner_wfe.lib_wf_queue.purge_wf_aq_activity_inst_in(p_purge_condition => 'qtview.user_data.id_workflow_activity_instance = '||p_id_workflow_activity_inst);
    
  END purge_wf_activity_inst_in;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: RESTART_WF_ACTIVITY_INST_IN
  -- purpose:        Restart messages in queue WF_AQ_ACTIVITY_INST_IN for given queue name, main workflow instance and workflow activity instance (optional)
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE restart_wf_activity_inst_in(p_name_queue                IN VARCHAR2,
                                        p_id_workflow_instance_main IN INTEGER,
                                        p_id_workflow_activity_inst IN INTEGER DEFAULT NULL)
  IS
            
  BEGIN
    
    -- Restart messages from exception queue WF_AQ_ACTIVITY_INST_IN for given main workflow instance
    owner_wfe.lib_wf_queue.restart_wf_aq_activity_inst_in(p_name_queue                => p_name_queue,
                                                          p_id_workflow_instance_main => p_id_workflow_instance_main,
                                                          p_id_workflow_activity_inst => p_id_workflow_activity_inst);
    
  END restart_wf_activity_inst_in;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: RESTART_WF_ACTIVITY_INST_OUT
  -- purpose:        Restart messages in queue WF_AQ_ACTIVITY_INST_OUT for given queue name, main workflow instance and workflow activity instance (optional)
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE restart_wf_activity_inst_out(p_name_queue                IN VARCHAR2,
                                         p_id_workflow_instance_main IN INTEGER,
                                         p_id_workflow_activity_inst IN INTEGER DEFAULT NULL)
  IS
            
  BEGIN
    
    -- Restart messages from exception queue WF_AQ_ACTIVITY_INST_OUT for given main workflow instance
    owner_wfe.lib_wf_queue.restart_wf_aq_activ_inst_out(p_name_queue                => p_name_queue,
                                                        p_id_workflow_instance_main => p_id_workflow_instance_main,
                                                        p_id_workflow_activity_inst => p_id_workflow_activity_inst);
    
  END restart_wf_activity_inst_out;
  
END lib_wf_queue_api;
/
