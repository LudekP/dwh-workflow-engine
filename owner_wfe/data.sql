--UTF8-BOM: české znaky: ěščřžýáíé a ruské znaky: йцгшщзфы a čínské znaky: 在该商店中不能修改贷款限度额
--nemazat !!!
SET SERVEROUTPUT ON SIZE 10000000000;

TRUNCATE TABLE owner_wfe.wf_tmp_file;
INSERT INTO owner_wfe.wf_tmp_file
  (name_workflow_file,
   text_workflow)
WITH procdef AS (SELECT
                    deployment_id_,
                    resource_name_
                 FROM (SELECT
                          deployment_id_,
                          resource_name_,
                          ROW_NUMBER() OVER(PARTITION BY key_ ORDER BY version_ DESC) AS num_idx
                       FROM owner_cam.act_re_procdef
                       )
                 WHERE num_idx = 1
                 )
SELECT
  be.name_ AS name_workflow,
  XMLTYPE(be.bytes_, NLS_CHARSET_ID('AL32UTF8')) AS text_workflow
FROM procdef pd 
JOIN owner_cam.act_ge_bytearray be ON be.deployment_id_ = pd.deployment_id_
                                  AND be.name_ = pd.resource_name_;
COMMIT;

DECLARE

   v_code_result  VARCHAR2(30);
   v_text_message CLOB;
   v_id_deployment INTEGER := owner_wfe.lib_wf_deployer_api.get_id_deployment;
   
BEGIN
  owner_wfe.lib_wf_deployer_api.validate_workflow(p_code_result  => v_code_result,
                                                  p_text_message => v_text_message);
  dbms_output.put_line(v_code_result);
  dbms_output.put_line(v_text_message);
  
  IF v_code_result = 'ERROR' THEN
    raise_application_error(-20123, 'There is some issue in worfklow definition, please check output! - ' || v_code_result, TRUE);
  END IF;

  owner_wfe.lib_wf_deployer_api.deploy_workflow(p_id_deployment   => v_id_deployment,
                                                p_name_deployment => 'Initial deployment',
                                                p_code_result     => v_code_result,
                                                p_text_message    => v_text_message);
  dbms_output.put_line(v_code_result);
  dbms_output.put_line(v_text_message);
  
  IF v_code_result = 'ERROR' THEN
    raise_application_error(-20123, 'There is some issue in worfklow deployment, please check output! - ' || v_code_result, TRUE);
  END IF;
  
END;
/

COMMIT;
