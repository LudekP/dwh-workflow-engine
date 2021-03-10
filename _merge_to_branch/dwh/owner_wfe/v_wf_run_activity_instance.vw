--UTF8-BOM: ceské znaky: ešcržýáíé a ruské znaky: ???????? a cínské znaky: ??????????????
--nemazat

-----------------------------------------------------------------
--- VIEW:: v_v_wf_run_activity_instance
-----------------------------------------------------------------
CREATE OR REPLACE FORCE VIEW owner_wfe.v_wf_run_activity_instance AS      
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
   name_activity, 
   dtime_start, 
   code_status
FROM owner_wfe.wf_run_activity_instance
WITH READ ONLY;

-----------------------------------------------------------------
--- COMMENTS FOR VIEW:: v_v_wf_run_activity_instance
-----------------------------------------------------------------
-- Add comments to the table 
COMMENT ON TABLE owner_wfe.wf_run_activity_instance IS 'Workflow activity instance history';

-- Add comments to the columns 
COMMENT ON COLUMN owner_wfe.v_wf_run_activity_instance.id_workflow_activity_instance IS 'Id of the workflow activity instance';
COMMENT ON COLUMN owner_wfe.v_wf_run_activity_instance.id_workflow_instance IS 'Id of the workflow instance';
COMMENT ON COLUMN owner_wfe.v_wf_run_activity_instance.id_workflow_instance_main IS 'Id of the main workflow instance (original workflow)';
COMMENT ON COLUMN owner_wfe.v_wf_run_activity_instance.id_workflow_instance_super IS 'Id of the superior workflow instance';
COMMENT ON COLUMN owner_wfe.v_wf_run_activity_instance.id_workflow_definition IS 'Id of the workflow definition';
COMMENT ON COLUMN owner_wfe.v_wf_run_activity_instance.id_workflow_activity IS 'Id of the workflow activity';
COMMENT ON COLUMN owner_wfe.v_wf_run_activity_instance.id_workflow_activity_super IS 'Id of the superior workflow activity';
COMMENT ON COLUMN owner_wfe.v_wf_run_activity_instance.id_process_instance IS 'Id of the process process (master process). Value received from process manager';
COMMENT ON COLUMN owner_wfe.v_wf_run_activity_instance.date_effective IS 'Date effective (master process). Value received from process manager';
COMMENT ON COLUMN owner_wfe.v_wf_run_activity_instance.num_process_priority IS 'Priority of the process (master process). Value received from process manager';
COMMENT ON COLUMN owner_wfe.v_wf_run_activity_instance.name_workflow IS 'Name of the workflow';
COMMENT ON COLUMN owner_wfe.v_wf_run_activity_instance.code_activity_type IS 'Code of the activity type';
COMMENT ON COLUMN owner_wfe.v_wf_run_activity_instance.name_activity IS 'Name of the activity';
COMMENT ON COLUMN owner_wfe.v_wf_run_activity_instance.dtime_start IS 'Date and time when the workflow activity started';
COMMENT ON COLUMN owner_wfe.v_wf_run_activity_instance.code_status IS 'Status of the the workflow activity';
/
