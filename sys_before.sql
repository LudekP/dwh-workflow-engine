--UTF8-BOM: české znaky: ěščřžýáíé a ruské znaky: йцгшщзфы a čínské znaky: 在该商店中不能修改贷款限度额
--nemazat !!!
CREATE TABLESPACE wf_data DATAFILE SIZE 1024M AUTOEXTEND ON NEXT 1024M MAXSIZE UNLIMITED;
CREATE TABLESPACE wf_index DATAFILE SIZE 1024M AUTOEXTEND ON NEXT 1024M MAXSIZE UNLIMITED;

CREATE USER owner_wfe
  IDENTIFIED BY owner_wfe
  DEFAULT TABLESPACE wf_data
  TEMPORARY TABLESPACE temp
  QUOTA UNLIMITED ON wf_data
  QUOTA UNLIMITED ON wf_index
  PROFILE application;
  
GRANT aq_administrator_role TO owner_wfe;
GRANT EXECUTE ON dbms_aq TO owner_wfe;
GRANT EXECUTE ON dbms_aqadm TO owner_wfe;
GRANT CONNECT TO owner_wfe;
