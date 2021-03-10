--UTF8-BOM: ceské znaky: ešcržýáíé a ruské znaky: ???????? a cínské znaky: ??????????????
--nemazat

-----------------------------------------------------------------
--- VIEW:: v_wf_aq_activity_inst_in
-----------------------------------------------------------------
CREATE OR REPLACE FORCE VIEW owner_wfe.v_wf_aq_activity_inst_in AS      
SELECT
   aqi.q_name                                  AS name_queue,
   aqi.msgid                                   AS id_message,
   aqi.user_data.id_workflow_instance_main     AS id_workflow_instance_main,
   aqi.user_data.id_workflow_activity_instance AS id_workflow_activity_instance,
   aqi.user_data.id_process_instance           AS id_process_instance,
   aqi.user_data.date_effective                AS date_effective,
   aqi.user_data.name_module                   AS name_module,
   aqi.enq_time                                AS dtime_enqueue
FROM owner_wfe.wf_aq_activity_inst_in aqi
WITH READ ONLY;

-----------------------------------------------------------------
--- COMMENTS FOR VIEW:: v_wf_aq_activity_inst_in
-----------------------------------------------------------------
-- Add comments to the table 
COMMENT ON TABLE owner_wfe.v_wf_aq_activity_inst_in IS 'Incoming queue for workflow engine';

-- Add comments to the columns 
COMMENT ON COLUMN owner_wfe.v_wf_aq_activity_inst_in.name_queue IS 'Name of the queue';
COMMENT ON COLUMN owner_wfe.v_wf_aq_activity_inst_in.id_message IS 'Id of the queue message';
COMMENT ON COLUMN owner_wfe.v_wf_aq_activity_inst_in.id_workflow_instance_main IS 'Id of the main workflow instance (original workflow)';
COMMENT ON COLUMN owner_wfe.v_wf_aq_activity_inst_in.id_workflow_activity_instance IS 'Id of the workflow activity instance';
COMMENT ON COLUMN owner_wfe.v_wf_aq_activity_inst_in.id_process_instance IS 'Id of the process process (master process). Value received from process manager';
COMMENT ON COLUMN owner_wfe.v_wf_aq_activity_inst_in.date_effective IS 'Date effective (master process). Value received from process manager';
COMMENT ON COLUMN owner_wfe.v_wf_aq_activity_inst_in.name_module IS 'Name of the workflow';
COMMENT ON COLUMN owner_wfe.v_wf_aq_activity_inst_in.dtime_enqueue IS 'Date and time when was message enqueued';
/
