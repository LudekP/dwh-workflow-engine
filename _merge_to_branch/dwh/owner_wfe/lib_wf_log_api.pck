CREATE OR REPLACE PACKAGE owner_wfe.lib_wf_log_api is

  ---------------------------------------------------------------------------------------------------------
  -- author:  Ludek
  -- created: 21.5.2020
  -- purpose: API for logging
  
  ---------------------------------------------------------------------------------------------------------

  ---------------------------------------------------------------------------------------------------------
  -- Global variables
  ---------------------------------------------------------------------------------------------------------   
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: LOG_ERROR_EVENT
  -- purpose:        log error event name and message
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE log_error_event(p_name_event   IN VARCHAR2,                         
                            p_text_message IN VARCHAR2);
                            
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: LOG_WARNING_EVENT
  -- purpose:        log warning name and message
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE log_warning_event(p_name_event   IN VARCHAR2,                         
                              p_text_message IN VARCHAR2);
                              
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: LOG_MESSAGE_EVENT
  -- purpose:        log message name and message
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE log_message_event(p_name_event   IN VARCHAR2,                         
                              p_text_message IN VARCHAR2);                      
                           
END lib_wf_log_api;
/
CREATE OR REPLACE PACKAGE BODY owner_wfe.lib_wf_log_api IS

  ---------------------------------------------------------------------------------------------------------
  -- Global variables
  ---------------------------------------------------------------------------------------------------------  
  c_type_error   CONSTANT VARCHAR2(30) := owner_wfe.lib_wf_constant.c_error;  
  c_type_warning CONSTANT VARCHAR2(30) := owner_wfe.lib_wf_constant.c_warning;  
  c_type_message CONSTANT VARCHAR2(30) := owner_wfe.lib_wf_constant.c_message;  
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: LOG_EVENT
  -- purpose:        log event type, name and message
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE log_event(p_name_event_type IN VARCHAR2, 
                      p_name_event      IN VARCHAR2,                         
                      p_text_message    IN VARCHAR2)
  IS

    v_user VARCHAR2(70);
    PRAGMA AUTONOMOUS_TRANSACTION;

  BEGIN

    -- Get user name
    v_user := CASE WHEN SYS_CONTEXT('USERENV', 'PROXY_USER') IS NULL THEN SYS_CONTEXT('USERENV', 'SESSION_USER')
                   ELSE SYS_CONTEXT('USERENV', 'PROXY_USER') ||'['|| SYS_CONTEXT('USERENV', 'SESSION_USER')||']'
              END;

    -- Insert event into log table
    INSERT INTO owner_wfe.wf_log_event
      (name_event_type, 
       name_event, 
       text_message, 
       dtime_inserted, 
       user_inserted)
    VALUES
      (p_name_event_type,
       p_name_event,
       p_text_message,
       SYSTIMESTAMP,
       v_user);
       
    COMMIT;

  EXCEPTION 
    WHEN OTHERS THEN
      NULL;
   
  END log_event;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: LOG_ERROR_EVENT
  -- purpose:        log error event name and message
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE log_error_event(p_name_event   IN VARCHAR2,                         
                            p_text_message IN VARCHAR2)
  IS

  BEGIN
   
    log_event(p_name_event_type => c_type_error, 
              p_name_event      => p_name_event,                         
              p_text_message    => p_text_message);
    
  END log_error_event;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: LOG_WARNING_EVENT
  -- purpose:        log warning name and message
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE log_warning_event(p_name_event   IN VARCHAR2,                         
                              p_text_message IN VARCHAR2)
  IS

  BEGIN
   
    log_event(p_name_event_type => c_type_warning, 
              p_name_event      => p_name_event,                         
              p_text_message    => p_text_message);
    
  END log_warning_event;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: LOG_MESSAGE_EVENT
  -- purpose:        log message name and message
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE log_message_event(p_name_event   IN VARCHAR2,                         
                              p_text_message IN VARCHAR2)
  IS

  BEGIN
   
    log_event(p_name_event_type => c_type_message, 
              p_name_event      => p_name_event,                         
              p_text_message    => p_text_message);
    
  END log_message_event;
    
END lib_wf_log_api;
/
