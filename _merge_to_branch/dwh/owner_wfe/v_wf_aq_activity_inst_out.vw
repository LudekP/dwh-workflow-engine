--UTF8-BOM: ceské znaky: ešcržýáíé a ruské znaky: ???????? a cínské znaky: ??????????????
--nemazat

-----------------------------------------------------------------
--- VIEW:: v_wf_aq_activity_inst_out
-----------------------------------------------------------------
CREATE OR REPLACE FORCE VIEW owner_wfe.v_wf_aq_activity_inst_out AS      
SELECT
   aqo.q_name                                  AS name_queue,
   aqo.msgid                                   AS id_message,
   aqo.user_data.id_workflow_instance_main     AS id_workflow_instance_main,
   aqo.user_data.id_workflow_activity_instance AS id_workflow_activity_instance,
   aqo.user_data.id_process_instance           AS id_process_instance,
   aqo.user_data.date_effective                AS date_effective,
   aqo.user_data.name_module                   AS name_module,
   aqo.enq_time                                AS dtime_enqueue
FROM owner_wfe.wf_aq_activity_inst_out aqo
WITH READ ONLY;

-----------------------------------------------------------------
--- COMMENTS FOR VIEW:: v_wf_aq_activity_inst_out
-----------------------------------------------------------------
-- Add comments to the table 
COMMENT ON TABLE owner_wfe.v_wf_aq_activity_inst_out IS 'Incoming queue for workflow engine';

-- Add comments to the columns 
COMMENT ON COLUMN owner_wfe.v_wf_aq_activity_inst_out.name_queue IS 'Name of the queue';
COMMENT ON COLUMN owner_wfe.v_wf_aq_activity_inst_out.id_message IS 'Id of the queue message';
COMMENT ON COLUMN owner_wfe.v_wf_aq_activity_inst_out.id_workflow_instance_main IS 'Id of the main workflow instance (original workflow)';
COMMENT ON COLUMN owner_wfe.v_wf_aq_activity_inst_out.id_workflow_activity_instance IS 'Id of the workflow activity instance';
COMMENT ON COLUMN owner_wfe.v_wf_aq_activity_inst_out.id_process_instance IS 'Id of the process process (master process). Value received from process manager';
COMMENT ON COLUMN owner_wfe.v_wf_aq_activity_inst_out.date_effective IS 'Date effective (master process). Value received from process manager';
COMMENT ON COLUMN owner_wfe.v_wf_aq_activity_inst_out.name_module IS 'Name of the workflow';
COMMENT ON COLUMN owner_wfe.v_wf_aq_activity_inst_out.dtime_enqueue IS 'Date and time when was message enqueued';
