CREATE OR REPLACE PACKAGE owner_wfe.lib_wf_queue IS

  ---------------------------------------------------------------------------------------------------------
  -- author:  Ludek
  -- created: 11.05.2020
  -- purpose: Manage workflow queues
  ---------------------------------------------------------------------------------------------------------

  ---------------------------------------------------------------------------------------------------------
  -- Global variables
  ---------------------------------------------------------------------------------------------------------  
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: ENQ_WF_AQ_ACTIVITY_INST_IN
  -- purpose:        Enqueue workflow activity instance message into queue WF_AQ_ACTIVITY_INST_IN
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE enq_wf_aq_activity_inst_in(p_wf_activity_instance IN owner_wfe.lib_wf_engine.t_wf_activity_instance,
                                       p_num_delay            IN BINARY_INTEGER DEFAULT NULL);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: DEQ_WF_AQ_ACTIVITY_INST_IN
  -- purpose:        Dequeue workflow activity instance message from queue WF_AQ_ACTIVITY_INST_IN
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE deq_wf_aq_activity_inst_in(context  RAW,
                                       reginfo  sys.aq$_reg_info,
                                       descr    sys.aq$_descriptor,
                                       payload  RAW,
                                       payloadl NUMBER);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: ENQ_WF_AQ_ACTIVITY_INST_OUT
  -- purpose:        Enqueue workflow activity instance message into queue WF_AQ_ACTIVITY_INST_OUT
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE enq_wf_aq_activity_inst_out(p_wf_activity_instance IN owner_wfe.lib_wf_engine.t_wf_activity_instance);
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: DEQ_WF_AQ_ACTIVITY_INST_OUT
  -- purpose:        Dequeue workflow activity instance message from queue WF_AQ_ACTIVITY_INST_OUT
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE deq_wf_aq_activity_inst_out(p_id_workflow_activity_inst OUT INTEGER,
                                        p_id_process_instance       OUT INTEGER,
                                        p_date_effective            OUT DATE,
                                        p_name_module               OUT VARCHAR2,
                                        p_text_data                 OUT VARCHAR2);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: PURGE_WF_AQ_ACTIVITY_INST_IN
  -- purpose:        Purge data from queue WF_AQ_ACTIVITY_INST_IN based on input condition
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE purge_wf_aq_activity_inst_in(p_purge_condition IN VARCHAR2);
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: PURGE_WF_AQ_ACTIVITY_INST_OUT
  -- purpose:        Purge data from queue WF_AQ_ACTIVITY_INST_OUT based on input condition
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE purge_wf_aq_activity_inst_out(p_purge_condition IN VARCHAR2);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: RESTART_WF_AQ_ACTIVITY_INST_IN
  -- purpose:        Restart messages in queue WF_AQ_ACTIVITY_INST_IN for given queue name, main workflow instance and workflow activity instance (optional)
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE restart_wf_aq_activity_inst_in(p_name_queue                IN VARCHAR2, 
                                           p_id_workflow_instance_main IN INTEGER,
                                           p_id_workflow_activity_inst IN INTEGER DEFAULT NULL);
   
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: RESTART_WF_AQ_ACTIV_INST_OUT
  -- purpose:        Restart messages in queue WF_AQ_ACTIVITY_INST_OUT for given queue name, main workflow instance and workflow activity instance (optional)
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE restart_wf_aq_activ_inst_out(p_name_queue                IN VARCHAR2, 
                                         p_id_workflow_instance_main IN INTEGER,
                                         p_id_workflow_activity_inst IN INTEGER DEFAULT NULL);
      
END lib_wf_queue;        
/
CREATE OR REPLACE PACKAGE BODY owner_wfe.lib_wf_queue IS

  ---------------------------------------------------------------------------------------------------------
  -- Global variables
  ---------------------------------------------------------------------------------------------------------  
  c_mod_name                  CONSTANT VARCHAR2(30) := 'LIB_WF_QUEUE';

  c_wf_aq_activity_inst_in     CONSTANT VARCHAR2(55) := owner_wfe.lib_wf_constant.c_wf_aq_activity_inst_in;
  c_wf_aq_activity_inst_out    CONSTANT VARCHAR2(55) := owner_wfe.lib_wf_constant.c_wf_aq_activity_inst_out;
  c_wf_aq_activity_inst_in_e   CONSTANT VARCHAR2(55) := owner_wfe.lib_wf_constant.c_wf_aq_activity_inst_in_e;
  c_wf_aq_activity_inst_out_e  CONSTANT VARCHAR2(55) := owner_wfe.lib_wf_constant.c_wf_aq_activity_inst_out_e;
  c_wf_aqn_activity_inst_in    CONSTANT VARCHAR2(55) := owner_wfe.lib_wf_constant.c_wf_aqn_activity_inst_in;
  c_wf_aqn_activity_inst_out   CONSTANT VARCHAR2(55) := owner_wfe.lib_wf_constant.c_wf_aqn_activity_inst_out;
  c_wf_aqn_activity_inst_in_e  CONSTANT VARCHAR2(55) := owner_wfe.lib_wf_constant.c_wf_aqn_activity_inst_in_e;
  c_wf_aqn_activity_inst_out_e CONSTANT VARCHAR2(55) := owner_wfe.lib_wf_constant.c_wf_aqn_activity_inst_out_e;
  v_text_message               VARCHAR2(4000);  
   
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: ENQ_WF_AQ_ACTIVITY_INST_IN
  -- purpose:        Enqueue workflow activity instance message into queue WF_AQ_ACTIVITY_INST_IN
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE enq_wf_aq_activity_inst_in(p_wf_activity_instance IN owner_wfe.lib_wf_engine.t_wf_activity_instance,
                                       p_num_delay            IN BINARY_INTEGER DEFAULT NULL)
  IS
     
    v_msg_payload  owner_wfe.t_wf_activity_instance_in;
    v_enqueue_opts dbms_aq.enqueue_options_t;
    v_msg_props    dbms_aq.message_properties_t;
    v_msg_id       RAW(16);
    
  BEGIN
    
    -- Set delay in message properties
    IF p_num_delay IS NOT NULL THEN
      v_msg_props.delay := p_num_delay;
    END IF;

    -- Create payload object
    v_msg_payload := NEW owner_wfe.t_wf_activity_instance_in(id_workflow_activity_instance => p_wf_activity_instance.id_workflow_activity_instance,
                                                             id_workflow_instance          => p_wf_activity_instance.id_workflow_instance,
                                                             id_workflow_instance_main     => p_wf_activity_instance.id_workflow_instance_main,
                                                             id_workflow_instance_super    => p_wf_activity_instance.id_workflow_instance_super,
                                                             id_workflow_definition        => p_wf_activity_instance.id_workflow_definition,
                                                             id_workflow_activity          => p_wf_activity_instance.id_workflow_activity,
                                                             id_workflow_activity_super    => p_wf_activity_instance.id_workflow_activity_super,
                                                             id_process_instance           => p_wf_activity_instance.id_process_instance,
                                                             date_effective                => p_wf_activity_instance.date_effective,
                                                             num_process_priority          => p_wf_activity_instance.num_process_priority,
                                                             name_workflow                 => p_wf_activity_instance.name_workflow,
                                                             code_activity_type            => p_wf_activity_instance.code_activity_type,
                                                             name_activity                 => p_wf_activity_instance.name_activity,
                                                             name_module                   => p_wf_activity_instance.name_module,
                                                             text_data                     => p_wf_activity_instance.text_data,                                                   
                                                             name_parameter                => p_wf_activity_instance.name_parameter,
                                                             text_parameter_value          => p_wf_activity_instance.text_parameter_value,
                                                             text_message                  => p_wf_activity_instance.text_message,
                                                             code_status                   => p_wf_activity_instance.code_status);

    -- Enqueue message
    dbms_aq.enqueue(queue_name           => c_wf_aq_activity_inst_in,
                    enqueue_options      => v_enqueue_opts,
                    message_properties   => v_msg_props,
                    payload              => v_msg_payload,
                    msgid                => v_msg_id);

  END enq_wf_aq_activity_inst_in;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: DEQ_WF_AQ_ACTIVITY_INST_IN
  -- purpose:        Dequeue workflow activity instance message from queue WF_AQ_ACTIVITY_INST_IN
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE deq_wf_aq_activity_inst_in(context  RAW,
                                       reginfo  sys.aq$_reg_info,
                                       descr    sys.aq$_descriptor,
                                       payload  RAW,
                                       payloadl NUMBER)
  IS
   
    v_msg_payload          owner_wfe.t_wf_activity_instance_in;
    v_dequeue_opts         dbms_aq.dequeue_options_t;
    v_msg_props            dbms_aq.message_properties_t;
    v_msg_id               RAW(16);
    a_wf_activity_instance owner_wfe.lib_wf_engine.t_wf_activity_instance;
    
  BEGIN
    
    -- Set dequeue options
    v_dequeue_opts.consumer_name := descr.consumer_name;
    v_dequeue_opts.msgid := descr.msg_id;
    
    -- Dequeue message
    dbms_aq.dequeue(queue_name         => descr.queue_name,
                    dequeue_options    => v_dequeue_opts,
                    message_properties => v_msg_props,
                    payload            => v_msg_payload,
                    msgid              => v_msg_id);
                    
    -- Set record
    a_wf_activity_instance.id_workflow_activity_instance := v_msg_payload.id_workflow_activity_instance;
    a_wf_activity_instance.id_workflow_instance          := v_msg_payload.id_workflow_instance;
    a_wf_activity_instance.id_workflow_instance_main     := v_msg_payload.id_workflow_instance_main;
    a_wf_activity_instance.id_workflow_instance_super    := v_msg_payload.id_workflow_instance_super;
    a_wf_activity_instance.id_workflow_definition        := v_msg_payload.id_workflow_definition;
    a_wf_activity_instance.id_workflow_activity          := v_msg_payload.id_workflow_activity;
    a_wf_activity_instance.id_workflow_activity_super    := v_msg_payload.id_workflow_activity_super;
    a_wf_activity_instance.id_process_instance           := v_msg_payload.id_process_instance;
    a_wf_activity_instance.date_effective                := v_msg_payload.date_effective;
    a_wf_activity_instance.num_process_priority          := v_msg_payload.num_process_priority;
    a_wf_activity_instance.name_workflow                 := v_msg_payload.name_workflow;
    a_wf_activity_instance.code_activity_type            := v_msg_payload.code_activity_type;
    a_wf_activity_instance.name_activity                 := v_msg_payload.name_activity;
    a_wf_activity_instance.name_module                   := v_msg_payload.name_module;
    a_wf_activity_instance.text_data                     := v_msg_payload.text_data;
    a_wf_activity_instance.name_parameter                := v_msg_payload.name_parameter;
    a_wf_activity_instance.text_parameter_value          := v_msg_payload.text_parameter_value;
    a_wf_activity_instance.text_message                  := v_msg_payload.text_message;
    a_wf_activity_instance.code_status                   := v_msg_payload.code_status;

    -- Execute workflow activity instance
    owner_wfe.lib_wf_engine.exec_wf_activity_instance(p_wf_activity_instance => a_wf_activity_instance);

  END deq_wf_aq_activity_inst_in; 
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: ENQ_WF_AQ_ACTIVITY_INST_OUT
  -- purpose:        Enqueue workflow activity instance message into queue WF_AQ_ACTIVITY_INST_OUT
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE enq_wf_aq_activity_inst_out(p_wf_activity_instance IN owner_wfe.lib_wf_engine.t_wf_activity_instance)
  IS
         
    v_msg_payload  owner_wfe.t_wf_activity_instance_out;
    v_enqueue_opts dbms_aq.enqueue_options_t;
    v_msg_props    dbms_aq.message_properties_t;
    v_msg_id       RAW(16);
    
  BEGIN
    
    -- Set message properties
    v_msg_props.priority := p_wf_activity_instance.num_process_priority;
       
    -- Create payload object
    v_msg_payload := NEW owner_wfe.t_wf_activity_instance_out(id_workflow_activity_instance => p_wf_activity_instance.id_workflow_activity_instance,
                                                              id_workflow_instance_main     => p_wf_activity_instance.id_workflow_instance_main,
                                                              id_workflow_instance          => p_wf_activity_instance.id_workflow_instance,
                                                              id_process_instance           => p_wf_activity_instance.id_process_instance,
                                                              date_effective                => p_wf_activity_instance.date_effective,
                                                              name_module                   => p_wf_activity_instance.name_module,
                                                              text_data                     => p_wf_activity_instance.text_data);

    -- Enqueue message
    dbms_aq.enqueue(queue_name           => c_wf_aq_activity_inst_out,
                    enqueue_options      => v_enqueue_opts,
                    message_properties   => v_msg_props,
                    payload              => v_msg_payload,
                    msgid                => v_msg_id);

  END enq_wf_aq_activity_inst_out;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: DEQ_WF_AQ_ACTIVITY_INST_OUT
  -- purpose:        Dequeue workflow activity instance message from queue WF_AQ_ACTIVITY_INST_OUT
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE deq_wf_aq_activity_inst_out(p_id_workflow_activity_inst OUT INTEGER,
                                        p_id_process_instance       OUT INTEGER,
                                        p_date_effective            OUT DATE,
                                        p_name_module               OUT VARCHAR2,
                                        p_text_data                 OUT VARCHAR2)
  IS
  
    v_msg_payload      owner_wfe.t_wf_activity_instance_out;
    v_dequeue_opts     dbms_aq.dequeue_options_t;
    v_msg_props        dbms_aq.message_properties_t;
    v_msg_id           RAW(16);

    ex_empty_queue EXCEPTION;
    PRAGMA EXCEPTION_INIT(ex_empty_queue, -25228);
        
  BEGIN
    
    -- Set dequeue options
    v_dequeue_opts.wait         := dbms_aq.no_wait;
    v_dequeue_opts.navigation   := dbms_aq.first_message;
    
    -- Dequeue message
    BEGIN
      
      dbms_aq.dequeue(queue_name         => c_wf_aq_activity_inst_out,
                      dequeue_options    => v_dequeue_opts,
                      message_properties => v_msg_props,
                      payload            => v_msg_payload,
                      msgid              => v_msg_id);
    
    EXCEPTION
      WHEN ex_empty_queue THEN 
        NULL;
    END;

    -- Set result
    p_id_workflow_activity_inst := v_msg_payload.id_workflow_activity_instance;
    p_id_process_instance       := v_msg_payload.id_process_instance;
    p_date_effective            := v_msg_payload.date_effective;
    p_name_module               := v_msg_payload.name_module;
    p_text_data                 := v_msg_payload.text_data;

  END deq_wf_aq_activity_inst_out; 

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: PURGE_WF_AQ_ACTIVITY_INST_IN
  -- purpose:        Purge data from queue WF_AQ_ACTIVITY_INST_IN based on input condition
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE purge_wf_aq_activity_inst_in(p_purge_condition IN VARCHAR2)
  IS

    t_purge_options  sys.dbms_aqadm.aq$_purge_options_t;
        
  BEGIN
    
    -- Purge data
    dbms_aqadm.purge_queue_table(queue_table     => c_wf_aq_activity_inst_in,
                                 purge_condition => p_purge_condition,
                                 purge_options   => t_purge_options);  

  END purge_wf_aq_activity_inst_in; 

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: PURGE_WF_AQ_ACTIVITY_INST_OUT
  -- purpose:        Purge data from queue WF_AQ_ACTIVITY_INST_OUT based on input condition
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE purge_wf_aq_activity_inst_out(p_purge_condition IN VARCHAR2)
  IS

    t_purge_options  sys.dbms_aqadm.aq$_purge_options_t;
        
  BEGIN
    
    -- Purge data
    dbms_aqadm.purge_queue_table(queue_table     => c_wf_aq_activity_inst_out,
                                 purge_condition => p_purge_condition,
                                 purge_options   => t_purge_options);  

  END purge_wf_aq_activity_inst_out; 
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: RESTART_WF_AQ_ACTIVITY_INST_IN
  -- purpose:        Restart messages in queue WF_AQ_ACTIVITY_INST_IN for given queue name, main workflow instance and workflow activity instance (optional)
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE restart_wf_aq_activity_inst_in(p_name_queue                IN VARCHAR2, 
                                           p_id_workflow_instance_main IN INTEGER,
                                           p_id_workflow_activity_inst IN INTEGER DEFAULT NULL)
  IS

    c_proc_name       CONSTANT VARCHAR2(30) := 'RESTART_WF_AQ_ACTIVITY_INST_IN';
    
    v_msg_payload     owner_wfe.t_wf_activity_instance_in;
    v_dequeue_opts    dbms_aq.dequeue_options_t;
    v_enqueue_opts    dbms_aq.enqueue_options_t;
    v_msg_props       dbms_aq.message_properties_t;
    v_msg_id          RAW(16);
    v_name_queue_full VARCHAR2(55);
    
    CURSOR c_restart_queue IS
      SELECT 
         a.msgid
      FROM owner_wfe.wf_aq_activity_inst_in a
      WHERE a.q_name = p_name_queue
        AND a.user_data.id_workflow_instance_main = p_id_workflow_instance_main
        AND a.user_data.id_workflow_activity_instance = CASE WHEN p_id_workflow_activity_inst IS NOT NULL THEN p_id_workflow_activity_inst 
                                                             ELSE a.user_data.id_workflow_activity_instance
                                                        END;

    ex_no_message EXCEPTION;
    PRAGMA EXCEPTION_INIT(ex_no_message, -25263);
            
  BEGIN
    
    v_dequeue_opts.wait         := dbms_aq.no_wait;
    v_dequeue_opts.navigation   := dbms_aq.first_message;
    
    -- Set additional options for message dequeue based on queue name
    IF p_name_queue = c_wf_aqn_activity_inst_in THEN
      -- Set full queue name ("normal" queue)
      v_name_queue_full := c_wf_aq_activity_inst_in;
      -- Set message consumer
      v_dequeue_opts.consumer_name := c_wf_aqn_activity_inst_in;
    ELSE
      -- Set full queue name ("exception" queue)
      v_name_queue_full := c_wf_aq_activity_inst_in_e;
    END IF;
    
    FOR i IN c_restart_queue
    LOOP
          
      -- Set message id
      v_dequeue_opts.msgid := i.msgid; 

      -- Dequeue message from exception queueu
      dbms_aq.dequeue(queue_name         => v_name_queue_full, 
                      dequeue_options    => v_dequeue_opts,
                      message_properties => v_msg_props,
                      payload            => v_msg_payload,
                      msgid              => v_msg_id);        
                 
      -- Enqueue message so it will be send again
      dbms_aq.enqueue(queue_name         => c_wf_aq_activity_inst_in,
                      enqueue_options    => v_enqueue_opts,
                      message_properties => v_msg_props,
                      payload            => v_msg_payload,
                      msgid              => v_msg_id);
    
      -- Commit
      COMMIT;
      
      -- Reset message id
      v_dequeue_opts.msgid := NULL;
      v_dequeue_opts.navigation := dbms_aq.next_message;
      
      -- Set message
      v_text_message := 'Message for workflow instance activity (id workflow instance activity '||v_msg_payload.id_workflow_activity_instance||') was restarted!';
    
      -- Log warning
      owner_wfe.lib_wf_log_api.log_warning_event(p_name_event   => c_proc_name,                         
                                                 p_text_message => v_text_message);
    
    END LOOP;
    
  END restart_wf_aq_activity_inst_in;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: RESTART_WF_AQ_ACTIV_INST_OUT
  -- purpose:        Restart messages in queue WF_AQ_ACTIVITY_INST_OUT for given queue name, main workflow instance and workflow activity instance (optional)
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE restart_wf_aq_activ_inst_out(p_name_queue                IN VARCHAR2, 
                                         p_id_workflow_instance_main IN INTEGER,
                                         p_id_workflow_activity_inst IN INTEGER DEFAULT NULL)
  IS
  
    c_proc_name    CONSTANT VARCHAR2(30) := 'RESTART_WF_AQ_ACTIV_INST_OUT';
    
    v_msg_payload     owner_wfe.t_wf_activity_instance_out;
    v_dequeue_opts    dbms_aq.dequeue_options_t;
    v_enqueue_opts    dbms_aq.enqueue_options_t;
    v_msg_props       dbms_aq.message_properties_t;
    v_msg_id          RAW(16);
    v_name_queue_full VARCHAR2(55);
    
    CURSOR c_restart_queue IS
      SELECT 
         a.msgid
      FROM owner_wfe.wf_aq_activity_inst_out a
      WHERE a.q_name = p_name_queue
        AND a.user_data.id_workflow_instance_main = p_id_workflow_instance_main
        AND a.user_data.id_workflow_activity_instance = CASE WHEN p_id_workflow_activity_inst IS NOT NULL THEN p_id_workflow_activity_inst 
                                                             ELSE a.user_data.id_workflow_activity_instance
                                                        END;

    ex_no_message EXCEPTION;
    PRAGMA EXCEPTION_INIT(ex_no_message, -25263);
            
  BEGIN
    
    v_dequeue_opts.wait         := dbms_aq.no_wait;
    v_dequeue_opts.navigation   := dbms_aq.first_message;
    
    -- Set additional options for message dequeue based on queue name
    IF p_name_queue = c_wf_aqn_activity_inst_out THEN
      -- Set full queue name ("normal" queue)
      v_name_queue_full := c_wf_aq_activity_inst_out;
    ELSE
      -- Set full queue name ("exception" queue)
      v_name_queue_full := c_wf_aq_activity_inst_out_e;
    END IF;
    
    FOR i IN c_restart_queue
    LOOP
      
      -- Set message id
      v_dequeue_opts.msgid := i.msgid; 

      -- Dequeue message from exception queueu
      dbms_aq.dequeue(queue_name         => v_name_queue_full, 
                      dequeue_options    => v_dequeue_opts,
                      message_properties => v_msg_props,
                      payload            => v_msg_payload,
                      msgid              => v_msg_id);        
                 
      -- Enqueue message so it will be send again
      dbms_aq.enqueue(queue_name         => c_wf_aq_activity_inst_out,
                      enqueue_options    => v_enqueue_opts,
                      message_properties => v_msg_props,
                      payload            => v_msg_payload,
                      msgid              => v_msg_id);
    
      -- Commit
      COMMIT;
      
      -- Reset message id
      v_dequeue_opts.msgid := NULL;
      v_dequeue_opts.navigation := dbms_aq.next_message;
      
      -- Set message
      v_text_message := 'Message for workflow instance activity (id workflow instance activity '||v_msg_payload.id_workflow_activity_instance||') was restarted!';
    
      -- Log warning
      owner_wfe.lib_wf_log_api.log_warning_event(p_name_event   => c_proc_name,                         
                                                 p_text_message => v_text_message);
    
    END LOOP;
    
  END restart_wf_aq_activ_inst_out;

END lib_wf_queue;
/
