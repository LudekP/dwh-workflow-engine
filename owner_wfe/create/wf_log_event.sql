-- Create table
CREATE TABLE owner_wfe.wf_log_event 
(
 name_event_type VARCHAR2(30 CHAR),
 name_event      VARCHAR2(100 CHAR),            
 text_message    VARCHAR2(4000 CHAR),
 dtime_inserted  TIMESTAMP(6) NOT NULL,
 date_inserted   GENERATED ALWAYS AS (TRUNC(CAST(DTIME_INSERTED AS DATE))) NOT NULL,
 user_inserted   VARCHAR2(70 CHAR) DEFAULT USER NOT NULL
)
TABLESPACE wf_data
PARTITION BY RANGE (DATE_INSERTED)
INTERVAL(NUMTODSINTERVAL(1, 'DAY'))
SUBPARTITION BY LIST (name_event_type)
  SUBPARTITION TEMPLATE
    ( 
     SUBPARTITION sub_message VALUES ('MESSAGE') TABLESPACE wf_data,
     SUBPARTITION sub_warning VALUES ('WARNING') TABLESPACE wf_data,
     SUBPARTITION sub_error   VALUES ('ERROR') TABLESPACE wf_data,
     SUBPARTITION sub_default VALUES (DEFAULT) TABLESPACE wf_data
    )
(  
 PARTITION partition_min VALUES LESS THAN (TO_DATE('1-1-2000', 'DD-MM-YYYY')) TABLESPACE wf_data
);

-- Add comments to the table 
COMMENT ON TABLE owner_wfe.wf_log_event IS 'Logging table for all events occured during workflow processes';
-- Add comments to the columns 
COMMENT ON COLUMN owner_wfe.wf_log_event.name_event_type IS 'Type of the event - WARNING/MESSAGE/ERROR or others';
COMMENT ON COLUMN owner_wfe.wf_log_event.name_event IS 'Name of the event';
COMMENT ON COLUMN owner_wfe.wf_log_event.text_message IS 'Message of the event';
COMMENT ON COLUMN owner_wfe.wf_log_event.dtime_inserted IS 'Date and time when the record was inserted';
COMMENT ON COLUMN owner_wfe.wf_log_event.date_inserted IS 'Date when the record was inserted';
COMMENT ON COLUMN owner_wfe.wf_log_event.user_inserted IS 'User who inserted the record';

-- Grant/Revoke object privileges 
GRANT SELECT ON owner_wfe.wf_log_event TO core_select_any_table;
GRANT SELECT, INSERT, UPDATE, DELETE ON owner_wfe.wf_log_event TO core_modify_any_table;
