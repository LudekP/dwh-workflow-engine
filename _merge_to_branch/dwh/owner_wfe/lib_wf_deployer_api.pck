CREATE OR REPLACE PACKAGE owner_wfe.lib_wf_deployer_api IS

  ---------------------------------------------------------------------------------------------------------
  -- author:  Ludek
  -- created: 11.05.2020
  -- purpose: Deploy workflow definition
  ---------------------------------------------------------------------------------------------------------

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: GET_ID_DEPLOYMENT
  -- purpose:        Get id deployment from sequence
  ---------------------------------------------------------------------------------------------------------  
  FUNCTION get_id_deployment RETURN INTEGER;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: PURGE_WORKFLOW_FILE
  -- purpose:        Purge workflow files before validation and deployment
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE purge_workflow_file(p_code_result  OUT VARCHAR2,
                                p_text_message OUT CLOB);
                                
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: convert_workflow_file2xmltype
  -- purpose:        Convert workflow file to xmltype for validation and deployment
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE convert_workflow_file2xmltype(p_id_deployment IN INTEGER,
                                          p_code_result   OUT VARCHAR2,
                                          p_text_message  OUT CLOB);
                                 
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: VALIDATE_WORKFLOW
  -- purpose:        Validate workflow files before deployment (check if everything is in place)       
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE validate_workflow(p_code_result  OUT VARCHAR2,
                              p_text_message OUT CLOB);
                           
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: DEPLOY_WORKFLOW
  -- purpose:        Deploy validated workflow definition     
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE deploy_workflow(p_id_deployment   IN INTEGER,
                            p_name_deployment IN VARCHAR2,
                            p_code_result     OUT VARCHAR2,
                            p_text_message    OUT CLOB);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: DELETE_WORKFLOW
  -- purpose:        Delete all workflow definitions for given id workflow    
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE delete_workflow(p_id_workflow IN VARCHAR2);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: DELETE_WORKFLOW_DEFINITION
  -- purpose:        Delete workflow definition 
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE delete_workflow_definition(p_id_workflow_definition IN INTEGER,
                                       p_id_workflow            IN VARCHAR2, 
                                       p_commit                 IN BOOLEAN DEFAULT TRUE);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: DELETE_DEPLOYMENT
  -- purpose:        Delete whole deployment 
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE delete_deployment(p_id_deployment IN INTEGER);
 
END lib_wf_deployer_api;        
/
CREATE OR REPLACE PACKAGE BODY owner_wfe.lib_wf_deployer_api IS

  ---------------------------------------------------------------------------------------------------------
  -- Global variables
  ---------------------------------------------------------------------------------------------------------  
  c_mod_name                CONSTANT VARCHAR2(30) := 'LIB_WF_DEPLOYER_API';
  c_status_complete         CONSTANT VARCHAR2(30) := owner_wfe.lib_wf_constant.c_complete;
  c_status_warning          CONSTANT VARCHAR2(30) := owner_wfe.lib_wf_constant.c_warning;
  c_status_error            CONSTANT VARCHAR2(30) := owner_wfe.lib_wf_constant.c_error;
  c_flag_y                  CONSTANT VARCHAR2(1) := owner_wfe.lib_wf_constant.c_flag_y;
  c_date_future             CONSTANT DATE := owner_wfe.lib_wf_constant.c_date_future;
  v_text_message            VARCHAR2(4000);
  
  -- Workflow main element type
  c_process                 CONSTANT VARCHAR2(100) := owner_wfe.lib_wf_constant.c_process;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: GET_ID_DEPLOYMENT
  -- purpose:        Get id deployment from sequence
  ---------------------------------------------------------------------------------------------------------  
  FUNCTION get_id_deployment RETURN INTEGER
  IS
  
    v_id_deployment INTEGER;
  
  BEGIN
  
    -- Get id deployment from sequence
    SELECT owner_wfe.s_deployment.nextval
      INTO v_id_deployment
    FROM dual; 
    
    -- Return result
    RETURN v_id_deployment;
    
  END get_id_deployment;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: GET_ID_WORKFLOW_DEFINITION
  -- purpose:        Get id workflow definition from sequence
  ---------------------------------------------------------------------------------------------------------  
  FUNCTION get_id_workflow_definition RETURN INTEGER
  IS
  
    v_id_workflow_definition INTEGER;
  
  BEGIN
  
    -- Get id workflow version from sequence 
    SELECT owner_wfe.s_workflow_definition.nextval
      INTO v_id_workflow_definition 
    FROM dual; 
    
    -- Return result
    RETURN v_id_workflow_definition;
    
  END get_id_workflow_definition;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CLOSE_WORKFLOW_VALIDITY
  -- purpose:        Close validity of last workflow version
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE close_workflow_validity(p_id_workflow    IN VARCHAR2,
                                    p_dtime_valid_to IN DATE,                
                                    p_num_version    OUT INTEGER)
  IS

  BEGIN

    -- Get last worfklow version for given id workflow
    SELECT
       MAX(num_version)
      INTO 
       p_num_version 
    FROM owner_wfe.wf_rep_definition
    WHERE id_workflow = p_id_workflow;

    IF p_num_version IS NOT NULL THEN
      
      -- Close validity of workflow version
      UPDATE owner_wfe.wf_rep_definition
         SET dtime_valid_to = p_dtime_valid_to
      WHERE id_workflow = p_id_workflow
        AND num_version = p_num_version;
        
    ELSE
      
      -- Set default value to version number
      p_num_version := 0;
      
    END IF;
      
  END close_workflow_validity;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: UPDATE_WORKFLOW_VALIDITY
  -- purpose:        Update workflow validy for given id workflow
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE update_workflow_validity(p_id_workflow IN VARCHAR2)
  IS

  BEGIN

    -- Get last worfklow version for given id workflow
    MERGE INTO owner_wfe.wf_rep_definition t
    USING (SELECT
              id_row,
              dtime_valid_to
           FROM (SELECT
                    i.rowid          AS id_row,
                    i.dtime_valid_to AS dtime_valid_to#,
                    NVL(LEAD(i.dtime_valid_from - INTERVAL '1' SECOND) OVER (PARTITION BY i.id_workflow ORDER BY i.dtime_valid_from), c_date_future) AS dtime_valid_to
                 FROM owner_wfe.wf_rep_definition i
                 WHERE i.id_workflow = p_id_workflow
                 )
           WHERE DECODE(dtime_valid_to, dtime_valid_to#, c_flag_y) IS NULL
           ) i
    ON (t.rowid = i.id_row)
    WHEN MATCHED THEN
      UPDATE SET
        t.dtime_valid_to = i.dtime_valid_to;
      
  END update_workflow_validity;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: PURGE_WORKFLOW_FILE
  -- purpose:        Purge workflow files before validation and deployment
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE purge_workflow_file(p_code_result  OUT VARCHAR2,
                                p_text_message OUT CLOB)
  IS

    c_proc_name CONSTANT VARCHAR2(30) := 'PURGE_WORKFLOW_FILE';  
    v_step      VARCHAR2(256);

  BEGIN

    -- Purge data from owner_wfe.wf_tmp_file2deployment
    v_step := 'Purge data from owner_wfe.wf_tmp_file2deployment';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE owner_wfe.wf_tmp_file2deployment';

    -- Purge data from owner_wfe.wf_tmp_file
    v_step := 'Delete data from owner_wfe.wf_tmp_file';
    DELETE FROM owner_wfe.wf_tmp_file;
    
    -- Set result
    p_code_result := c_status_complete;
    
  EXCEPTION
    WHEN OTHERS THEN
      -- Set result
      p_code_result := c_status_error;
      -- Set message
      p_text_message := 'Error in '||c_mod_name||'.'||c_proc_name||' - ('||v_step||'): '||SUBSTR(dbms_utility.format_error_stack, 1, 1500);

  END purge_workflow_file;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: convert_workflow_file2xmltype
  -- purpose:        Convert workflow file to xmltype for validation and deployment
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE convert_workflow_file2xmltype(p_id_deployment IN INTEGER,
                                          p_code_result   OUT VARCHAR2,
                                          p_text_message  OUT CLOB)
  IS
    
    c_proc_name         CONSTANT VARCHAR2(30) := 'UPLOAD_WORKFLOW_FILE';  
    v_step              VARCHAR2(256);
  
  BEGIN

    -- Insert workflow file into table
    v_step := 'Insert workflow file into table';
    INSERT INTO owner_wfe.wf_tmp_file
      (name_workflow_file, 
       text_workflow)
    SELECT
       name_workflow_file, 
       XMLTYPE(text_workflow)
    FROM owner_wfe.wf_tmp_file2deployment
    WHERE id_deployment = p_id_deployment;
       
    -- Commit
    COMMIT;
    
    -- Set result
    p_code_result := c_status_complete;
     
  EXCEPTION
    WHEN OTHERS THEN
      -- Set result
      p_code_result := c_status_error;
      -- Set message
      p_text_message := 'Error in '||c_mod_name||'.'||c_proc_name||' - ('||v_step||'): '||SUBSTR(dbms_utility.format_error_stack, 1, 1500);

  END convert_workflow_file2xmltype;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: VALIDATE_WORKFLOW
  -- purpose:        Validate workflow files before deployment (check if everything is in place)       
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE validate_workflow(p_code_result  OUT VARCHAR2,
                              p_text_message OUT CLOB)
  IS

    c_proc_name            CONSTANT VARCHAR2(30) := 'VALIDATE_WORKFLOW'; 
    v_step                 VARCHAR2(256);
    v_code_result_parse    VARCHAR2(30);
    v_code_result_validate VARCHAR2(30);
    v_code_result_final    VARCHAR2(30);
    v_text_message         CLOB;
    v_text_message_final   CLOB;
    
  BEGIN
    
    -- Parse workflow
    v_step := 'Parse workflow';
    owner_wfe.lib_wf_parser.parse_workflow(p_code_result  => v_code_result_parse,
                                           p_text_message => p_text_message);

    -- Set final text message
    IF v_text_message IS NOT NULL THEN
      v_text_message_final := v_text_message_final||v_text_message||CHR(10);
    END IF;

    -- Validate workflow
    v_step := 'Validate workflow';
    owner_wfe.lib_wf_validator.validate_workflow(p_code_result  => v_code_result_validate,
                                                 p_text_message => v_text_message);

    -- Set final text message
    IF v_text_message IS NOT NULL THEN
      v_text_message_final := v_text_message_final||v_text_message||CHR(10);
    END IF;
  
    -- Set final code result
    IF v_code_result_parse = c_status_error OR v_code_result_validate = c_status_error THEN
      v_code_result_final := c_status_error;
    ELSIF v_code_result_parse = c_status_warning OR v_code_result_validate = c_status_warning THEN
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

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: DEPLOY_WORKFLOW
  -- purpose:        Deploy validated workflow definition     
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE deploy_workflow(p_id_deployment   IN INTEGER,
                            p_name_deployment IN VARCHAR2,
                            p_code_result     OUT VARCHAR2,
                            p_text_message    OUT CLOB)
  IS
 
    c_proc_name              CONSTANT VARCHAR2(30) := 'DEPLOY_WORKFLOW'; 
    c_sysdate                CONSTANT DATE := SYSDATE;
    v_id_workflow_definition INTEGER;
    v_num_version            INTEGER;
    v_user                   VARCHAR2(60);
    v_step                   VARCHAR2(256);
  
    CURSOR c_wf_definition IS
      SELECT
         name_workflow_file AS name_workflow_file,
         id_main_element    AS id_workflow,
         name_main_element  AS name_workflow
      FROM owner_wfe.wf_tmp_definition
      WHERE code_main_element_type = c_process;
  
  BEGIN
    
    -- Set user name
    v_step := 'Set user name';
    v_user := CASE WHEN SYS_CONTEXT('USERENV', 'PROXY_USER') IS NULL THEN SYS_CONTEXT('USERENV', 'SESSION_USER')
                   ELSE SYS_CONTEXT('USERENV', 'PROXY_USER') ||'['|| SYS_CONTEXT('USERENV', 'SESSION_USER')||']'
               END;
    
    -- Insert new deployment
    v_step := 'Insert new deployment';
    INSERT INTO owner_wfe.wf_rep_deployment
      (id_deployment, 
       name_deployment,
       dtime_inserted, 
       user_inserted)
    VALUES
      (p_id_deployment,
       p_name_deployment,
       c_sysdate,
       v_user);
    
    FOR d IN c_wf_definition
    LOOP
      
      -- Get id workflow definition
      v_step := 'Get id workflow definition';
      v_id_workflow_definition := get_id_workflow_definition;
      
      -- Close validity of last workflow definition and return its version number
      v_step := 'Close validity of last workflow definition';
      close_workflow_validity(p_id_workflow    => d.id_workflow,
                              p_dtime_valid_to => c_sysdate - INTERVAL '1' SECOND,                
                              p_num_version    => v_num_version);
                              
      -- Insert new definition of workflow file
      v_step := 'Insert new definition of workflow file';    
      INSERT INTO owner_wfe.wf_rep_file
        (id_workflow_definition, 
         name_workflow_file, 
         text_workflow)
      SELECT
         v_id_workflow_definition, 
         name_workflow_file, 
         text_workflow
      FROM owner_wfe.wf_tmp_file
      WHERE name_workflow_file = d.name_workflow_file;
      
      -- Insert new definition of workflow
      v_step := 'Insert new definition of workflow';
      INSERT INTO owner_wfe.wf_rep_definition
        (id_workflow_definition, 
         id_workflow, 
         num_version, 
         id_deployment, 
         name_workflow, 
         name_workflow_file, 
         dtime_valid_from, 
         dtime_valid_to) 
       VALUES
        (v_id_workflow_definition,
         d.id_workflow,
         v_num_version + 1,
         p_id_deployment,
         d.name_workflow,
         d.name_workflow_file,
         c_sysdate,
         c_date_future);
         
      -- Insert new definition of workflow process activity
      v_step := 'Insert new definition of workflow activity';
      INSERT INTO owner_wfe.wf_rep_activity
        (id_workflow_definition, 
         id_workflow_activity, 
         code_activity_type, 
         name_activity, 
         id_workflow_called, 
         id_workflow_activity_source, 
         id_workflow_activity_target)
      SELECT
         v_id_workflow_definition, 
         id_workflow_activity, 
         code_activity_type, 
         name_activity, 
         id_workflow_called, 
         id_workflow_activity_source, 
         id_workflow_activity_target
      FROM owner_wfe.wf_tmp_activity
      WHERE name_workflow_file = d.name_workflow_file;
      
      -- Insert new definition of workflow activity attr
      v_step := 'Insert new definition of workflow activity attr';
      INSERT INTO owner_wfe.wf_rep_activity_attr
        (id_workflow_definition, 
         id_workflow_activity, 
         code_attribute_type, 
         name_attribute, 
         text_attribute_value)
      SELECT
         v_id_workflow_definition, 
         id_workflow_activity, 
         code_attribute_type, 
         name_attribute, 
         text_attribute_value
      FROM owner_wfe.wf_tmp_activity_attr
      WHERE name_workflow_file = d.name_workflow_file;
         
    END LOOP;
    
    -- Commit
    COMMIT;
    
    -- Set result
    p_code_result := c_status_complete;
    
  EXCEPTION
    WHEN OTHERS THEN
      -- Rollback
      ROLLBACK;
      -- Set result
      p_code_result := c_status_error;
      -- Set message
      p_text_message := 'Error in '||c_mod_name||'.'||c_proc_name||' - ('||v_step||'): '||SUBSTR(dbms_utility.format_error_stack, 1, 1500);

  END deploy_workflow; 

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: DELETE_WORKFLOW
  -- purpose:        Delete all workflow definitions for given id workflow    
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE delete_workflow(p_id_workflow IN VARCHAR2)
  IS
 
    c_proc_name              CONSTANT VARCHAR2(30) := 'DELETE_WORKFLOW'; 
    v_step                   VARCHAR2(256);
  
  BEGIN
     
    -- Delete all definitions of workflow file
    v_step := 'Delete all definitions of workflow file';  
    DELETE FROM owner_wfe.wf_rep_file 
    WHERE id_workflow_definition IN (SELECT id_workflow_definition
                                     FROM owner_wfe.wf_rep_definition
                                     WHERE id_workflow = p_id_workflow);

    -- Delete all definitions of workflow activity attr
    v_step := 'Delete all definitions of workflow activity attr';  
    DELETE FROM owner_wfe.wf_rep_activity_attr 
    WHERE id_workflow_definition IN (SELECT id_workflow_definition
                                     FROM owner_wfe.wf_rep_definition
                                     WHERE id_workflow = p_id_workflow);
                                     
    -- Delete all definitions of workflow activity
    v_step := 'Delete all definitions of workflow activity';  
    DELETE FROM owner_wfe.wf_rep_activity 
    WHERE id_workflow_definition IN (SELECT id_workflow_definition
                                     FROM owner_wfe.wf_rep_definition
                                     WHERE id_workflow = p_id_workflow);
                                     
    -- Delete all definitions of workflow
    v_step := 'Delete all definitions of workflow';  
    DELETE FROM owner_wfe.wf_rep_definition 
    WHERE id_workflow = p_id_workflow;
                                    
    -- Commit
    COMMIT;
    
    -- Set message
    v_text_message := 'Workflow (id workflow - '||p_id_workflow||') was successfully removed from repository!';
    
    -- Log message
    owner_wfe.lib_wf_log_api.log_message_event(p_name_event   => c_proc_name,                         
                                               p_text_message => v_text_message);    

  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK; 
      -- Set message
      v_text_message := 'Error in '||c_mod_name||'.'||c_proc_name||' ('||v_step||'): '||SUBSTR(dbms_utility.format_error_stack, 1, 3000);
      
      -- Log error
      owner_wfe.lib_wf_log_api.log_error_event(p_name_event   => c_proc_name,                         
                                               p_text_message => v_text_message);
      -- Raise error
      raise_application_error(-20001, v_text_message);
      
  END delete_workflow;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: DELETE_WORKFLOW_DEFINITION
  -- purpose:        Delete workflow definition 
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE delete_workflow_definition(p_id_workflow_definition IN INTEGER,
                                       p_id_workflow            IN VARCHAR2, 
                                       p_commit                 IN BOOLEAN DEFAULT TRUE)
  IS
 
    c_proc_name              CONSTANT VARCHAR2(30) := 'DELETE_WORKFLOW_DEFINITION'; 
    v_step                   VARCHAR2(256);
  
  BEGIN
     
    -- Delete definition of workflow file
    v_step := 'Delete definition of workflow file';  
    DELETE FROM owner_wfe.wf_rep_file 
    WHERE id_workflow_definition = p_id_workflow_definition;

    -- Delete definition of workflow activity attr
    v_step := 'Delete definition of workflow activity attr';  
    DELETE FROM owner_wfe.wf_rep_activity_attr 
    WHERE id_workflow_definition = p_id_workflow_definition;
                                     
    -- Delete definition of workflow activity
    v_step := 'Delete definition of workflow activity';  
    DELETE FROM owner_wfe.wf_rep_activity 
    WHERE id_workflow_definition = p_id_workflow_definition;
                                     
    -- Delete definition of workflow
    v_step := 'Delete definition of workflow';  
    DELETE FROM owner_wfe.wf_rep_definition 
    WHERE id_workflow_definition = p_id_workflow_definition;
    
    -- Update workflow worfklow validity
    v_step := 'Update workflow worfklow validity';  
    update_workflow_validity(p_id_workflow => p_id_workflow);
                                    
    -- Commit
    IF p_commit THEN
      COMMIT;
    END IF;
    
    -- Set message
    v_text_message := 'Workflow definition (id workflow definition - '||p_id_workflow_definition||') was successfully removed from repository!';
    
    -- Log message
    owner_wfe.lib_wf_log_api.log_message_event(p_name_event   => c_proc_name,                         
                                               p_text_message => v_text_message);    

  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK; 
      -- Set message
      v_text_message := 'Error in '||c_mod_name||'.'||c_proc_name||' ('||v_step||'): '||SUBSTR(dbms_utility.format_error_stack, 1, 3000);
      
      -- Log error
      owner_wfe.lib_wf_log_api.log_error_event(p_name_event   => c_proc_name,                         
                                               p_text_message => v_text_message);
      -- Raise error
      raise_application_error(-20002, v_text_message);
      
  END delete_workflow_definition;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: DELETE_DEPLOYMENT
  -- purpose:        Delete whole deployment 
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE delete_deployment(p_id_deployment IN INTEGER)
  IS
 
    c_proc_name              CONSTANT VARCHAR2(30) := 'DELETE_DEPLOYMENT'; 
    v_step                   VARCHAR2(256);
    
    CURSOR c_wf_deployment IS
      SELECT
         id_workflow_definition,
         id_workflow
      FROM owner_wfe.wf_rep_definition
      WHERE id_deployment = p_id_deployment;
  
  BEGIN
     
    -- Loop throught workflow definitions
    FOR d IN c_wf_deployment
    LOOP
      
      -- Delete workflow definition
      delete_workflow_definition(p_id_workflow_definition => d.id_workflow_definition,
                                 p_id_workflow            => d.id_workflow, 
                                 p_commit                 => FALSE);
      
    END LOOP;
                                   
    -- Commit
    COMMIT;
    
    -- Set message
    v_text_message := 'Workflow deployment (id deployment - '||p_id_deployment||') was successfully removed from repository!';
    
    -- Log message
    owner_wfe.lib_wf_log_api.log_message_event(p_name_event   => c_proc_name,                         
                                               p_text_message => v_text_message);    

  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK; 
      -- Set message
      v_text_message := 'Error in '||c_mod_name||'.'||c_proc_name||' ('||v_step||'): '||SUBSTR(dbms_utility.format_error_stack, 1, 3000);
      
      -- Log error
      owner_wfe.lib_wf_log_api.log_error_event(p_name_event   => c_proc_name,                         
                                               p_text_message => v_text_message);
      -- Raise error
      raise_application_error(-20003, v_text_message);
      
  END delete_deployment;
  
END lib_wf_deployer_api;
/
