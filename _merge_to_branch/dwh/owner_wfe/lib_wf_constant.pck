CREATE OR REPLACE PACKAGE owner_wfe.lib_wf_constant IS

  ---------------------------------------------------------------------------------------------------------
  -- author:  Ludek
  -- created: 14.05.2020
  -- purpose: Workflow constants
  ---------------------------------------------------------------------------------------------------------

  ---------------------------------------------------------------------------------------------------------
  -- Global variables
  ---------------------------------------------------------------------------------------------------------
  -- Status
  c_complete                    CONSTANT VARCHAR2(30) := 'COMPLETE';
  c_cancel                      CONSTANT VARCHAR2(30) := 'CANCEL';
  c_new                         CONSTANT VARCHAR2(30) := 'NEW';
  c_running                     CONSTANT VARCHAR2(30) := 'RUNNING';
  c_error                       CONSTANT VARCHAR2(30) := 'ERROR';
  c_restart                     CONSTANT VARCHAR2(30) := 'RESTART';
  c_suspend                     CONSTANT VARCHAR2(30) := 'SUSPEND';
  c_skip                        CONSTANT VARCHAR2(30) := 'SKIP';
  c_stuck                       CONSTANT VARCHAR2(30) := 'STUCK';
  c_int_complete                CONSTANT INTEGER := 1;
  c_int_warning                 CONSTANT INTEGER := 2;
  c_int_error                   CONSTANT INTEGER := 3;
  
  c_warning                     CONSTANT VARCHAR2(30) := 'WARNING';
  c_message                     CONSTANT VARCHAR2(30) := 'MESSAGE'; 
  c_module_name                 CONSTANT VARCHAR2(30) := 'MODULE_NAME';
  c_data_type                   CONSTANT VARCHAR2(30) := 'DATA_TYPE';
  c_flag_y                      CONSTANT VARCHAR2(1)  := 'Y';
  c_flag_n                      CONSTANT VARCHAR2(1)  := 'N';
  c_minus_two                   CONSTANT INTEGER := -2; 
  c_xap                         CONSTANT VARCHAR2(10) := 'XAP';
  c_date_future                 CONSTANT DATE := DATE'3000-01-01';  
  
  -- Queues
  c_wf_aq_activity_inst_in      CONSTANT VARCHAR2(55) := 'OWNER_WFE.WF_AQ_ACTIVITY_INST_IN';
  c_wf_aq_activity_inst_out     CONSTANT VARCHAR2(55) := 'OWNER_WFE.WF_AQ_ACTIVITY_INST_OUT';
  c_wf_aq_activity_inst_in_e    CONSTANT VARCHAR2(55) := 'OWNER_WFE.AQ$_WF_AQ_ACTIVITY_INST_IN_E';
  c_wf_aq_activity_inst_out_e   CONSTANT VARCHAR2(55) := 'OWNER_WFE.AQ$_WF_AQ_ACTIVITY_INST_OUT_E';
  c_wf_aqn_activity_inst_in     CONSTANT VARCHAR2(55) := 'WF_AQ_ACTIVITY_INST_IN';
  c_wf_aqn_activity_inst_out    CONSTANT VARCHAR2(55) := 'WF_AQ_ACTIVITY_INST_OUT';
  c_wf_aqn_activity_inst_in_e   CONSTANT VARCHAR2(55) := 'AQ$_WF_AQ_ACTIVITY_INST_IN_E';
  c_wf_aqn_activity_inst_out_e  CONSTANT VARCHAR2(55) := 'AQ$_WF_AQ_ACTIVITY_INST_OUT_E';

  -- Workflow main element type
  c_process                     CONSTANT VARCHAR2(100) := 'process';
  c_diagram                     CONSTANT VARCHAR2(100) := 'BPMNDiagram';
  
  -- Workflow activity diagram type
  c_shape                       CONSTANT VARCHAR2(100) := 'BPMNShape';
  c_edge                        CONSTANT VARCHAR2(100) := 'BPMNEdge';                          
  
  -- Workflow activity type
  c_start_event                 CONSTANT VARCHAR2(100) := 'startEvent';
  c_end_event                   CONSTANT VARCHAR2(100) := 'endEvent';
  c_wait_event                  CONSTANT VARCHAR2(100) := 'intermediateCatchEvent';
  c_sequence_flow               CONSTANT VARCHAR2(100) := 'sequenceFlow';
  c_parallel_gateway            CONSTANT VARCHAR2(100) := 'parallelGateway';
  c_inclusive_gateway           CONSTANT VARCHAR2(100) := 'inclusiveGateway';
  c_receive_task                CONSTANT VARCHAR2(100) := 'receiveTask';
  c_call_activity               CONSTANT VARCHAR2(100) := 'callActivity';
  c_condition_expression        CONSTANT VARCHAR2(100) := 'conditionExpression';
    
  -- Workflow activity attribute type
  c_outgoing_attr               CONSTANT VARCHAR2(100) := 'outgoing';
  c_incoming_attr               CONSTANT VARCHAR2(100) := 'incoming';
  c_timer_definition_attr       CONSTANT VARCHAR2(100) := 'timerEventDefinition';
  c_timer_duration_attr         CONSTANT VARCHAR2(100) := 'timeDuration';
  c_extension_elements_attr     CONSTANT VARCHAR2(100) := 'extensionElements';
  c_input_output_attr           CONSTANT VARCHAR2(100) := 'inputOutput';
  c_input_parameter_attr        CONSTANT VARCHAR2(100) := 'inputParameter';

END lib_wf_constant;        
/
