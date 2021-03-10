--UTF8-BOM: české znaky: ěščřžýáíé a ruské znaky: йцгшщзфы a čínské znaky: 在该商店中不能修改贷款限度额
--nemazat !!!
-- Create subscriber for WF_AQ_ACTIVITY_INST_IN
BEGIN
  dbms_aqadm.add_subscriber('OWNER_WFE.WF_AQ_ACTIVITY_INST_IN', sys.aq$_agent('WF_AQ_ACTIVITY_INST_IN', null, null));
  dbms_aq.register(sys.aq$_reg_info_list(sys.aq$_reg_info('OWNER_WFE.WF_AQ_ACTIVITY_INST_IN:WF_AQ_ACTIVITY_INST_IN', dbms_aq.namespace_aq, 'plsql://owner_wfe.lib_wf_queue.deq_wf_aq_activity_inst_in', hextoraw('FF'))), 1);
END;
/
