--UTF8-BOM: české znaky: ěščřžýáíé a ruské znaky: йцгшщзфы a čínské znaky: 在该商店中不能修改贷款限度额
--nemazat !!!
CREATE OR REPLACE TYPE owner_wfe.t_wf_activity_instance_in AS OBJECT
(
 id_workflow_activity_instance INTEGER,
 id_workflow_instance          INTEGER,
 id_workflow_instance_main     INTEGER,
 id_workflow_instance_super    INTEGER,
 id_workflow_definition        INTEGER,
 id_workflow_activity          VARCHAR2(255 CHAR),
 id_workflow_activity_super    VARCHAR2(255 CHAR),
 id_process_instance           INTEGER,
 date_effective                DATE,
 num_process_priority          INTEGER,
 name_workflow                 VARCHAR2(255 CHAR),
 code_activity_type            VARCHAR2(255 CHAR),
 name_activity                 VARCHAR2(255 CHAR),
 name_module                   VARCHAR2(255 CHAR),
 text_data                     VARCHAR2(1000 CHAR),
 name_parameter                VARCHAR2(255 CHAR),
 text_parameter_value          VARCHAR2(255 CHAR),
 text_message                  VARCHAR2(4000 CHAR),
 code_status                   VARCHAR2(30)
);
/

CREATE OR REPLACE TYPE owner_wfe.t_wf_activity_instance_out AS OBJECT
(
 id_workflow_activity_instance INTEGER,
 id_workflow_instance_main     INTEGER,
 id_workflow_instance          INTEGER,
 id_process_instance           INTEGER,
 date_effective                DATE,
 name_module                   VARCHAR2(255 CHAR),
 text_data                     VARCHAR2(1000 CHAR)
);
/

-- Incoming queue
BEGIN 
  dbms_aqadm.create_queue_table(queue_table        => 'OWNER_WFE.WF_AQ_ACTIVITY_INST_IN',
                                sort_list          => 'ENQ_TIME',
                                queue_payload_type => 'OWNER_WFE.T_WF_ACTIVITY_INSTANCE_IN',
                                storage_clause     => 'TABLESPACE WF_DATA',
                                multiple_consumers => TRUE);
END;
/

BEGIN
  dbms_aqadm.create_queue(queue_name         => 'OWNER_WFE.WF_AQ_ACTIVITY_INST_IN',
                          queue_table        => 'OWNER_WFE.WF_AQ_ACTIVITY_INST_IN',
                          auto_commit        => FALSE,
                          max_retries        => 5);
END;
/

BEGIN
  dbms_aqadm.start_queue(queue_name => 'OWNER_WFE.WF_AQ_ACTIVITY_INST_IN');
END;
/

BEGIN
  dbms_aqadm.start_queue(queue_name => 'OWNER_WFE.AQ$_WF_AQ_ACTIVITY_INST_IN_E', enqueue => FALSE, dequeue => TRUE);
END;
/

-- Outgoing queue
BEGIN 
  dbms_aqadm.create_queue_table(queue_table        => 'OWNER_WFE.WF_AQ_ACTIVITY_INST_OUT',
                                sort_list          => 'PRIORITY,ENQ_TIME',
                                queue_payload_type => 'OWNER_WFE.T_WF_ACTIVITY_INSTANCE_OUT',
                                storage_clause     => 'TABLESPACE WF_DATA');
END;
/

BEGIN
  dbms_aqadm.create_queue(queue_name         => 'OWNER_WFE.WF_AQ_ACTIVITY_INST_OUT',
                          queue_table        => 'OWNER_WFE.WF_AQ_ACTIVITY_INST_OUT',
                          auto_commit        => FALSE,
                          max_retries        => 500);
END;
/

BEGIN
  dbms_aqadm.alter_queue(queue_name  => 'OWNER_WFE.WF_AQ_ACTIVITY_INST_OUT',
                         auto_commit => FALSE,
                         max_retries => 500);
  dbms_aqadm.alter_queue(queue_name  => 'OWNER_WFE.WF_AQ_ACTIVITY_INST_IN',
                         auto_commit => FALSE,
                         max_retries => 20,
                         retry_delay => 5);
END;
/

BEGIN
  dbms_aqadm.start_queue(queue_name => 'OWNER_WFE.WF_AQ_ACTIVITY_INST_OUT');
END;
/

BEGIN
  dbms_aqadm.start_queue(queue_name => 'OWNER_WFE.AQ$_WF_AQ_ACTIVITY_INST_OUT_E', enqueue => FALSE, dequeue => TRUE);
END;
/

/*
BEGIN
  dbms_aqadm.stop_queue(queue_name => 'OWNER_WFE.WF_AQ_ACTIVITY_INST_IN');
  dbms_aqadm.drop_queue(queue_name => 'OWNER_WFE.WF_AQ_ACTIVITY_INST_IN');
  dbms_aqadm.drop_queue_table(queue_table => 'OWNER_WFE.WF_AQ_ACTIVITY_INST_IN');
END;
/

BEGIN
  dbms_aqadm.stop_queue(queue_name => 'OWNER_WFE.WF_AQ_ACTIVITY_INST_OUT');
  dbms_aqadm.drop_queue(queue_name => 'OWNER_WFE.WF_AQ_ACTIVITY_INST_OUT');
  dbms_aqadm.drop_queue_table(queue_table => 'OWNER_WFE.WF_AQ_ACTIVITY_INST_OUT');
END;
/
*/


