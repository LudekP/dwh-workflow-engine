--UTF8-BOM: ceské znaky: ešcržýáíé a ruské znaky: ???????? a cínské znaky: ??????????????
--nemazat

-----------------------------------------------------------------
--- VIEW:: v_wf_activity_instance
-----------------------------------------------------------------
CREATE OR REPLACE FORCE VIEW owner_wfe.v_wf_activity_instance AS      
SELECT
   hai.id_workflow_activity_instance,
   hai.id_workflow_instance,
   hai.id_workflow_instance_main,
   hai.id_workflow_instance_super,
   hai.id_workflow_definition,
   hai.id_workflow_activity,
   hai.id_workflow_activity_super,
   hai.id_process_instance,
   hai.date_effective,
   hai.num_process_priority,
   hai.name_workflow,
   hai.code_activity_type,
   hai.name_activity,
   hai.dtime_start,
   hai.dtime_end,
   CASE WHEN hai.code_status IS NULL AND hve.id_workflow_activity_instance IS NOT NULL THEN 'ERROR'
        WHEN hai.code_status IS NULL AND hve.id_workflow_activity_instance IS NULL     THEN 'RUNNING'
        ELSE hai.code_status
   END AS code_status,
   TO_CHAR(TRUNC((LEAST(CAST(hai.dtime_end AS DATE), SYSDATE) - CAST(hai.dtime_start AS DATE)) * 24)) || ':' 
     || SUBSTR(TO_CHAR(TRUNC(MOD((LEAST(CAST(hai.dtime_end AS DATE), SYSDATE) - CAST(hai.dtime_start AS DATE)) * 24 * 60, 60)), '09'), 2) || ':' 
     || SUBSTR(TO_CHAR(MOD((LEAST(CAST(hai.dtime_end AS DATE), SYSDATE) - CAST(hai.dtime_start AS DATE)) * 24 * 60 * 60, 60), '09'), 2) AS duration,
   COALESCE(hve.text_value, hvs.text_value, hvc.text_value) AS text_message
FROM owner_wfe.wf_hist_activity_instance hai
LEFT JOIN owner_wfe.wf_hist_variable hve ON hve.id_workflow_activity_instance = hai.id_workflow_activity_instance
                                        AND hve.id_workflow_instance = hai.id_workflow_instance 
                                        AND hve.date_effective = hai.date_effective
                                        AND hve.name_variable = 'ERROR'
LEFT JOIN owner_wfe.wf_hist_variable hvs ON hvs.id_workflow_activity_instance = hai.id_workflow_activity_instance
                                        AND hvs.id_workflow_instance = hai.id_workflow_instance 
                                        AND hvs.date_effective = hai.date_effective
                                        AND hvs.name_variable = 'SKIP'
LEFT JOIN owner_wfe.wf_hist_variable hvc ON hvc.id_workflow_activity_instance = hai.id_workflow_activity_instance
                                        AND hvc.id_workflow_instance = hai.id_workflow_instance 
                                        AND hvc.date_effective = hai.date_effective
                                        AND hvc.name_variable = 'CANCEL'
WITH READ ONLY;

-----------------------------------------------------------------
--- COMMENTS FOR VIEW:: v_wf_activity_instance
-----------------------------------------------------------------
-- Add comments to the table 
COMMENT ON TABLE owner_wfe.v_wf_activity_instance IS 'Workflow activity instance';

-- Add comments to the columns 
COMMENT ON COLUMN owner_wfe.v_wf_activity_instance.id_workflow_activity_instance IS 'Id of the workflow activity instance';
COMMENT ON COLUMN owner_wfe.v_wf_activity_instance.id_workflow_instance IS 'Id of the workflow instance';
COMMENT ON COLUMN owner_wfe.v_wf_activity_instance.id_workflow_instance_main IS 'Id of the main workflow instance (original workflow)';
COMMENT ON COLUMN owner_wfe.v_wf_activity_instance.id_workflow_instance_super IS 'Id of the superior workflow instance';
COMMENT ON COLUMN owner_wfe.v_wf_activity_instance.id_workflow_definition IS 'Id of the workflow definition';
COMMENT ON COLUMN owner_wfe.v_wf_activity_instance.id_workflow_activity IS 'Id of the workflow activity';
COMMENT ON COLUMN owner_wfe.v_wf_activity_instance.id_workflow_activity_super IS 'Id of the superior workflow activity';
COMMENT ON COLUMN owner_wfe.v_wf_activity_instance.id_process_instance IS 'Id of the process process (master process). Value received from process manager';
COMMENT ON COLUMN owner_wfe.v_wf_activity_instance.date_effective IS 'Date effective (master process). Value received from process manager';
COMMENT ON COLUMN owner_wfe.v_wf_activity_instance.num_process_priority IS 'Priority of the process (master process). Value received from process manager';
COMMENT ON COLUMN owner_wfe.v_wf_activity_instance.name_workflow IS 'Name of the workflow';
COMMENT ON COLUMN owner_wfe.v_wf_activity_instance.code_activity_type IS 'Code of the activity type';
COMMENT ON COLUMN owner_wfe.v_wf_activity_instance.name_activity IS 'Name of the activity';
COMMENT ON COLUMN owner_wfe.v_wf_activity_instance.dtime_start IS 'Date and time when the workflow activity started';
COMMENT ON COLUMN owner_wfe.v_wf_activity_instance.dtime_end IS 'Date and time when the workflow activity ended';
COMMENT ON COLUMN owner_wfe.v_wf_activity_instance.code_status IS 'Status of the the workflow activity';
COMMENT ON COLUMN owner_wfe.v_wf_activity_instance.duration IS 'Duration of the workflow activity';
COMMENT ON COLUMN owner_wfe.v_wf_activity_instance.text_message IS 'Message of the workflow activity';
/
