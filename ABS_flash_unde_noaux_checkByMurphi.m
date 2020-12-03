
const

  NODE_NUM : 2;
  DATA_NUM : 2;
                                                        
type

  NODE : scalarset(NODE_NUM);
  DATA : scalarset(DATA_NUM);
  ABS_NODE : union {NODE, enum{other}};
  
  CACHE_STATE : enum{CACHE_I,CACHE_S,CACHE_E};
  
  NODE_CMD : enum{NODE_None,NODE_Get,NODE_GetX};
  
  NODE_STATE : record
    ProcCmd : NODE_CMD;
    InvMarked : boolean;
    CacheState : CACHE_STATE;
    CacheData : DATA;
  end;
  new_type_0 : array [ NODE ] of boolean;
  new_type_1 : array [ NODE ] of boolean;
  
  DIR_STATE : record
    Pending : boolean;
    Local : boolean;
    Dirty : boolean;
    HeadVld : boolean;
    HeadPtr : ABS_NODE;
    ShrVld : boolean;
    InvSet : new_type_0;
    ShrSet : new_type_1;
    HomeHeadPtr : boolean;
    HomeShrSet : boolean;
    HomeInvSet : boolean;
  end;
  
  UNI_CMD : enum{UNI_None,UNI_Get,UNI_GetX,UNI_Put,UNI_PutX,UNI_Nak};
  
  UNI_MSG : record
    Cmd : UNI_CMD;
    Proc : ABS_NODE;
    HomeProc : boolean;
    Data : DATA;
  end;
  
  INV_CMD : enum{INV_None,INV_Inv,INV_InvAck};
  
  INV_MSG : record
    Cmd : INV_CMD;
  end;
  
  RP_CMD : enum{RP_None,RP_Replace};
  
  RP_MSG : record
    Cmd : RP_CMD;
  end;
  
  WB_CMD : enum{WB_None,WB_Wb};
  
  WB_MSG : record
    Cmd : WB_CMD;
    Proc : ABS_NODE;
    HomeProc : boolean;
    Data : DATA;
  end;
  
  SHWB_CMD : enum{SHWB_None,SHWB_ShWb,SHWB_FAck};
  
  SHWB_MSG : record
    Cmd : SHWB_CMD;
    Proc : ABS_NODE;
    HomeProc : boolean;
    Data : DATA;
  end;
  
  NAKC_CMD : enum{NAKC_None,NAKC_Nakc};
  
  NAKC_MSG : record
    Cmd : NAKC_CMD;
  end;
  new_type_2 : array [ NODE ] of NODE_STATE;
  new_type_3 : array [ NODE ] of UNI_MSG;
  new_type_4 : array [ NODE ] of INV_MSG;
  new_type_5 : array [ NODE ] of RP_MSG;
  
  STATE : record
    Proc : new_type_2;
    Dir : DIR_STATE;
    MemData : DATA;
    UniMsg : new_type_3;
    InvMsg : new_type_4;
    RpMsg : new_type_5;
    WbMsg : WB_MSG;
    ShWbMsg : SHWB_MSG;
    NakcMsg : NAKC_MSG;
    HomeProc : NODE_STATE;
    HomeUniMsg : UNI_MSG;
    HomeInvMsg : INV_MSG;
    HomeRpMsg : RP_MSG;
    CurrData : DATA;
  end;


var

  Sta : STATE;

rule "NI_Replace_Home1"
  Sta.HomeRpMsg.Cmd = RP_Replace &
  Sta.Dir.ShrVld
==>
begin
  Sta.HomeRpMsg.Cmd := RP_None;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
endrule;

rule "NI_Replace_Home2"
  Sta.HomeRpMsg.Cmd = RP_Replace &
  !Sta.Dir.ShrVld
==>
begin
  Sta.HomeRpMsg.Cmd := RP_None;
endrule;

ruleset  src : NODE do
rule "NI_Replace3"
  Sta.RpMsg[src].Cmd = RP_Replace &
  Sta.Dir.ShrVld
==>
begin
  Sta.RpMsg[src].Cmd := RP_None;
  Sta.Dir.ShrSet[src] := false;
  Sta.Dir.InvSet[src] := false;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Replace4"
  Sta.RpMsg[src].Cmd = RP_Replace &
  !Sta.Dir.ShrVld
==>
begin
  Sta.RpMsg[src].Cmd := RP_None;
endrule;
endruleset;

rule "NI_ShWb5"
  Sta.ShWbMsg.Cmd = SHWB_ShWb &
  Sta.ShWbMsg.HomeProc
==>
begin
  Sta.ShWbMsg.Cmd := SHWB_None;
  Sta.ShWbMsg.HomeProc := false;
  Sta.Dir.Pending := false;
  Sta.Dir.Dirty := false;
  Sta.Dir.ShrVld := true;
  for p : NODE do
    if (p = Sta.ShWbMsg.Proc & Sta.ShWbMsg.HomeProc = false) | Sta.Dir.ShrSet[p]  then
      Sta.Dir.ShrSet[p] := true;
      Sta.Dir.InvSet[p] := true;
    else
      Sta.Dir.ShrSet[p] := false;
      Sta.Dir.InvSet[p] := false;
    end;
  end;
  if (Sta.ShWbMsg.HomeProc | Sta.Dir.HomeShrSet) then 
    Sta.Dir.HomeShrSet := true; 
    Sta.Dir.HomeInvSet := true; 
  else 
    Sta.Dir.HomeShrSet := false; 
    Sta.Dir.HomeInvSet := false; 
  end; 
  Sta.MemData := Sta.ShWbMsg.Data;
  undefine Sta.ShWbMsg.Proc;
  undefine Sta.ShWbMsg.Data;
endrule;

rule "NI_ShWb6"
  Sta.ShWbMsg.Cmd = SHWB_ShWb &
  Sta.Dir.HomeShrSet
==>
begin
  Sta.ShWbMsg.Cmd := SHWB_None;
  Sta.ShWbMsg.HomeProc := false;
  Sta.Dir.Pending := false;
  Sta.Dir.Dirty := false;
  Sta.Dir.ShrVld := true;
  for p : NODE do
    if (p = Sta.ShWbMsg.Proc & Sta.ShWbMsg.HomeProc = false) | Sta.Dir.ShrSet[p]  then
      Sta.Dir.ShrSet[p] := true;
      Sta.Dir.InvSet[p] := true;
    else
      Sta.Dir.ShrSet[p] := false;
      Sta.Dir.InvSet[p] := false;
    end;
  end;
  if (Sta.ShWbMsg.HomeProc | Sta.Dir.HomeShrSet) then 
    Sta.Dir.HomeShrSet := true; 
    Sta.Dir.HomeInvSet := true; 
  else 
    Sta.Dir.HomeShrSet := false; 
    Sta.Dir.HomeInvSet := false; 
  end; 
  Sta.MemData := Sta.ShWbMsg.Data;
  undefine Sta.ShWbMsg.Proc;
  undefine Sta.ShWbMsg.Data;
endrule;

rule "NI_ShWb7"
  Sta.ShWbMsg.Cmd = SHWB_ShWb &
  !Sta.ShWbMsg.HomeProc &
  !Sta.Dir.HomeShrSet
==>
begin
  Sta.ShWbMsg.Cmd := SHWB_None;
  Sta.ShWbMsg.HomeProc := false;
  Sta.Dir.Pending := false;
  Sta.Dir.Dirty := false;
  Sta.Dir.ShrVld := true;
  for p : NODE do
    if (p = Sta.ShWbMsg.Proc & Sta.ShWbMsg.HomeProc = false) | Sta.Dir.ShrSet[p]  then
      Sta.Dir.ShrSet[p] := true;
      Sta.Dir.InvSet[p] := true;
    else
      Sta.Dir.ShrSet[p] := false;
      Sta.Dir.InvSet[p] := false;
    end;
  end;
  if (Sta.ShWbMsg.HomeProc | Sta.Dir.HomeShrSet) then 
    Sta.Dir.HomeShrSet := true; 
    Sta.Dir.HomeInvSet := true; 
  else 
    Sta.Dir.HomeShrSet := false; 
    Sta.Dir.HomeInvSet := false; 
  end; 
  Sta.MemData := Sta.ShWbMsg.Data;
  undefine Sta.ShWbMsg.Proc;
  undefine Sta.ShWbMsg.Data;
endrule;

rule "NI_FAck8"
  Sta.ShWbMsg.Cmd = SHWB_FAck &
  Sta.Dir.Dirty = true
==>
begin
  Sta.ShWbMsg.Cmd := SHWB_None;
  Sta.Dir.Pending := false;
  Sta.ShWbMsg.HomeProc := false;
  Sta.Dir.HeadPtr := Sta.ShWbMsg.Proc;
  Sta.Dir.HomeHeadPtr := Sta.ShWbMsg.HomeProc;
  undefine Sta.ShWbMsg.Proc;
  undefine Sta.ShWbMsg.Data;
endrule;

rule "NI_FAck9"
  Sta.ShWbMsg.Cmd = SHWB_FAck &
  Sta.Dir.Dirty != true
==>
begin
  Sta.ShWbMsg.Cmd := SHWB_None;
  Sta.Dir.Pending := false;
  Sta.ShWbMsg.HomeProc := false;
  undefine Sta.ShWbMsg.Proc;
  undefine Sta.ShWbMsg.Data;
endrule;

rule "NI_Wb10"
  Sta.WbMsg.Cmd = WB_Wb
==>
begin
  Sta.WbMsg.Cmd := WB_None;
  Sta.WbMsg.HomeProc := false;
  Sta.Dir.Dirty := false;
  Sta.Dir.HeadVld := false;
  Sta.MemData := Sta.WbMsg.Data;
  undefine Sta.Dir.HeadPtr;
  undefine Sta.WbMsg.Proc;
  undefine Sta.WbMsg.Data;
endrule;

ruleset  src : NODE do
rule "NI_InvAck_311"
  Sta.InvMsg[src].Cmd = INV_InvAck &
  Sta.Dir.Pending = true &
  Sta.Dir.InvSet[src] = true &
  Sta.Dir.Dirty = true &
  Sta.Dir.HomeInvSet = false &
  forall p : NODE do
    p = src | Sta.Dir.InvSet[p] = false
  end
==>
begin
  Sta.InvMsg[src].Cmd := INV_None;
  Sta.Dir.InvSet[src] := false;
  Sta.Dir.Pending := false;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_InvAck_212"
  Sta.InvMsg[src].Cmd = INV_InvAck &
  Sta.Dir.Pending = true &
  Sta.Dir.InvSet[src] = true &
  Sta.Dir.Local = false &
  Sta.Dir.HomeInvSet = false &
  forall p : NODE do
    p = src |
    Sta.Dir.InvSet[p] = false
  end
==>
begin
  Sta.InvMsg[src].Cmd := INV_None;
  Sta.Dir.InvSet[src] := false;
  Sta.Dir.Pending := false;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_InvAck_113"
  Sta.InvMsg[src].Cmd = INV_InvAck &
  Sta.Dir.Pending = true &
  Sta.Dir.InvSet[src] = true &
  Sta.Dir.Local = true &
  Sta.Dir.Dirty = false &
  Sta.Dir.HomeInvSet = false &
  forall p : NODE do
    p = src |
    Sta.Dir.InvSet[p] = false
  end
==>
begin
  Sta.InvMsg[src].Cmd := INV_None;
  Sta.Dir.InvSet[src] := false;
  Sta.Dir.Pending := false;
  Sta.Dir.Local := false;
endrule;
endruleset;

ruleset  dst : NODE; src : NODE do
rule "NI_InvAck_exists14"
  Sta.InvMsg[src].Cmd = INV_InvAck &
  Sta.Dir.Pending = true &
  Sta.Dir.InvSet[src] = true &
  dst != src &
  Sta.Dir.InvSet[dst]
==>
begin
  Sta.InvMsg[src].Cmd := INV_None;
  Sta.Dir.InvSet[src] := false;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_InvAck_exists_Home15"
  Sta.InvMsg[src].Cmd = INV_InvAck &
  Sta.Dir.Pending = true &
  Sta.Dir.InvSet[src] = true &
  Sta.Dir.HomeInvSet
==>
begin
  Sta.InvMsg[src].Cmd := INV_None;
  Sta.Dir.InvSet[src] := false;
endrule;
endruleset;

ruleset  dst : NODE do
rule "NI_Inv16"
  Sta.InvMsg[dst].Cmd = INV_Inv &
  Sta.Proc[dst].ProcCmd = NODE_Get
==>
begin
  Sta.InvMsg[dst].Cmd := INV_InvAck;
  Sta.Proc[dst].CacheState := CACHE_I;
  undefine Sta.Proc[dst].CacheData;
  Sta.Proc[dst].InvMarked := true;
endrule;
endruleset;

ruleset  dst : NODE do
rule "NI_Inv17"
  Sta.InvMsg[dst].Cmd = INV_Inv &
  Sta.Proc[dst].ProcCmd != NODE_Get
==>
begin
  Sta.InvMsg[dst].Cmd := INV_InvAck;
  Sta.Proc[dst].CacheState := CACHE_I;
  undefine Sta.Proc[dst].CacheData;
endrule;
endruleset;

ruleset  dst : NODE do
rule "NI_Remote_PutX18"
  Sta.UniMsg[dst].Cmd = UNI_PutX &
  Sta.Proc[dst].ProcCmd = NODE_GetX
==>
begin
  Sta.UniMsg[dst].Cmd := UNI_None;
  Sta.UniMsg[dst].HomeProc := false;
  Sta.Proc[dst].ProcCmd := NODE_None;
  Sta.Proc[dst].InvMarked := false;
  Sta.Proc[dst].CacheState := CACHE_E;
  Sta.Proc[dst].CacheData := Sta.UniMsg[dst].Data;
  undefine Sta.UniMsg[dst].Proc;
  undefine Sta.UniMsg[dst].Data;
endrule;
endruleset;

rule "NI_Local_PutXAcksDone19"
  Sta.HomeUniMsg.Cmd = UNI_PutX
==>
begin
  Sta.HomeUniMsg.Cmd := UNI_None;
  Sta.HomeUniMsg.HomeProc := false;
  Sta.Dir.Pending := false;
  Sta.Dir.Local := true;
  Sta.Dir.HeadVld := false;
  Sta.HomeProc.ProcCmd := NODE_None;
  Sta.HomeProc.InvMarked := false;
  Sta.HomeProc.CacheState := CACHE_E;
  Sta.HomeProc.CacheData := Sta.HomeUniMsg.Data;
  undefine Sta.Dir.HeadPtr;
  undefine Sta.HomeUniMsg.Proc;
  undefine Sta.HomeUniMsg.Data;
endrule;

ruleset  dst : NODE do
rule "NI_Remote_Put20"
  Sta.UniMsg[dst].Cmd = UNI_Put &
  Sta.Proc[dst].InvMarked
==>
begin
  Sta.UniMsg[dst].Cmd := UNI_None;
  Sta.UniMsg[dst].HomeProc := false;
  Sta.Proc[dst].ProcCmd := NODE_None;
  Sta.Proc[dst].InvMarked := false;
  Sta.Proc[dst].CacheState := CACHE_I;
  undefine Sta.Proc[dst].CacheData;
  undefine Sta.UniMsg[dst].Proc;
  undefine Sta.UniMsg[dst].Data;
endrule;
endruleset;

ruleset  dst : NODE do
rule "NI_Remote_Put21"
  Sta.UniMsg[dst].Cmd = UNI_Put &
  !Sta.Proc[dst].InvMarked
==>
begin
  Sta.UniMsg[dst].Cmd := UNI_None;
  Sta.UniMsg[dst].HomeProc := false;
  Sta.Proc[dst].ProcCmd := NODE_None;
  Sta.Proc[dst].CacheState := CACHE_S;
  Sta.Proc[dst].CacheData := Sta.UniMsg[dst].Data;
  undefine Sta.UniMsg[dst].Proc;
  undefine Sta.UniMsg[dst].Data;
endrule;
endruleset;

rule "NI_Local_Put22"
  Sta.HomeUniMsg.Cmd = UNI_Put &
  Sta.HomeProc.InvMarked
==>
begin
  Sta.HomeUniMsg.Cmd := UNI_None;
  Sta.HomeUniMsg.HomeProc := false;
  Sta.Dir.Pending := false;
  Sta.Dir.Dirty := false;
  Sta.Dir.Local := true;
  Sta.MemData := Sta.HomeUniMsg.Data;
  Sta.HomeProc.ProcCmd := NODE_None;
  Sta.HomeProc.InvMarked := false;
  Sta.HomeProc.CacheState := CACHE_I;
  undefine Sta.HomeProc.CacheData;
  undefine Sta.HomeUniMsg.Proc;
  undefine Sta.HomeUniMsg.Data;
endrule;

rule "NI_Local_Put23"
  Sta.HomeUniMsg.Cmd = UNI_Put &
  !Sta.HomeProc.InvMarked
==>
begin
  Sta.HomeUniMsg.Cmd := UNI_None;
  Sta.HomeUniMsg.HomeProc := false;
  Sta.Dir.Pending := false;
  Sta.Dir.Dirty := false;
  Sta.Dir.Local := true;
  Sta.MemData := Sta.HomeUniMsg.Data;
  Sta.HomeProc.ProcCmd := NODE_None;
  Sta.HomeProc.CacheState := CACHE_S;
  Sta.HomeProc.CacheData := Sta.HomeUniMsg.Data;
  undefine Sta.HomeUniMsg.Proc;
  undefine Sta.HomeUniMsg.Data;
endrule;

ruleset  dst : NODE do
rule "NI_Remote_GetX_PutX_Home24"
  Sta.HomeUniMsg.Cmd = UNI_GetX &
  Sta.HomeUniMsg.Proc = dst &
  Sta.HomeUniMsg.HomeProc = false &
  Sta.Proc[dst].CacheState = CACHE_E
==>
begin
  Sta.Proc[dst].CacheState := CACHE_I;
  Sta.HomeUniMsg.Cmd := UNI_PutX;
  Sta.HomeUniMsg.Data := Sta.Proc[dst].CacheData;
  undefine Sta.Proc[dst].CacheData;
endrule;
endruleset;

ruleset  dst : NODE; src : NODE do
rule "NI_Remote_GetX_PutX25"
  src != dst &
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].Proc = dst &
  Sta.UniMsg[src].HomeProc = false &
  Sta.Proc[dst].CacheState = CACHE_E
==>
begin
  Sta.Proc[dst].CacheState := CACHE_I;
  Sta.UniMsg[src].Cmd := UNI_PutX;
  Sta.UniMsg[src].Data := Sta.Proc[dst].CacheData;
  Sta.ShWbMsg.Cmd := SHWB_FAck;
  Sta.ShWbMsg.Proc := src;
  Sta.ShWbMsg.HomeProc := false;
  undefine Sta.ShWbMsg.Data;
  undefine Sta.Proc[dst].CacheData;
endrule;
endruleset;

ruleset  dst : NODE do
rule "NI_Remote_GetX_Nak_Home26"
  Sta.HomeUniMsg.Cmd = UNI_GetX &
  Sta.HomeUniMsg.Proc = dst &
  Sta.HomeUniMsg.HomeProc = false &
  Sta.Proc[dst].CacheState != CACHE_E
==>
begin
  Sta.HomeUniMsg.Cmd := UNI_Nak;
  Sta.NakcMsg.Cmd := NAKC_Nakc;
endrule;
endruleset;

ruleset  dst : NODE; src : NODE do
rule "NI_Remote_GetX_Nak27"
  src != dst &
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].Proc = dst &
  Sta.UniMsg[src].HomeProc = false &
  Sta.Proc[dst].CacheState != CACHE_E
==>
begin
  Sta.UniMsg[src].Cmd := UNI_Nak;
  Sta.UniMsg[src].Proc := dst;
  Sta.UniMsg[src].HomeProc := false;
  undefine Sta.UniMsg[src].Data;
  Sta.NakcMsg.Cmd := NAKC_Nakc;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_GetX_PutX_1128"
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].HomeProc &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = true &
  Sta.Dir.Local = true &
  Sta.HomeProc.CacheState = CACHE_E
==>
begin
  Sta.Dir.Local := false;
  Sta.Dir.Dirty := true;
  Sta.Dir.HeadVld := true;
  Sta.Dir.HeadPtr := src;
  Sta.Dir.HomeHeadPtr := false;
  Sta.Dir.ShrVld := false;
  for p : NODE do
    Sta.Dir.ShrSet[p] := false;
    Sta.Dir.InvSet[p] := false;
  end;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
  Sta.UniMsg[src].Cmd := UNI_PutX;
  Sta.UniMsg[src].Data := Sta.HomeProc.CacheData;
  Sta.HomeProc.CacheState := CACHE_I;
  undefine Sta.HomeProc.CacheData;
endrule;
endruleset;

ruleset  dst : NODE; src : NODE do
rule "NI_Local_GetX_PutX_1029"
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].HomeProc &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadVld &
  Sta.Dir.HeadPtr = src &
  Sta.Dir.HomeHeadPtr = false &
  Sta.Dir.ShrSet[dst] &
  Sta.Dir.Local = false
==>
begin
  Sta.Dir.Pending := true;
  Sta.Dir.Local := false;
  Sta.Dir.Dirty := true;
  Sta.Dir.HeadVld := true;
  Sta.Dir.HeadPtr := src;
  Sta.Dir.HomeHeadPtr := false;
  Sta.Dir.ShrVld := false;
  for p : NODE do
    Sta.Dir.ShrSet[p] := false;
    if ((p != src & ((Sta.Dir.ShrVld & Sta.Dir.ShrSet[p]) | ((Sta.Dir.HeadVld & Sta.Dir.HeadPtr = p) & Sta.Dir.HomeHeadPtr = false)))) then
      Sta.Dir.InvSet[p] := true;
      Sta.InvMsg[p].Cmd := INV_Inv;
    else
      Sta.Dir.InvSet[p] := false;
      Sta.InvMsg[p].Cmd := INV_None;
    end;
  end;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
  Sta.HomeInvMsg.Cmd := INV_None;
  Sta.UniMsg[src].Cmd := UNI_PutX;
  Sta.UniMsg[src].Data := Sta.MemData;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_GetX_PutX_10_Home30"
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].HomeProc &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadVld &
  Sta.Dir.HeadPtr = src &
  Sta.Dir.HomeHeadPtr = false &
  Sta.Dir.HomeShrSet &
  Sta.Dir.Local = false
==>
begin
  Sta.Dir.Pending := true;
  Sta.Dir.Local := false;
  Sta.Dir.Dirty := true;
  Sta.Dir.HeadVld := true;
  Sta.Dir.HeadPtr := src;
  Sta.Dir.HomeHeadPtr := false;
  Sta.Dir.ShrVld := false;
  for p : NODE do
    Sta.Dir.ShrSet[p] := false;
    if ((p != src &
    ((Sta.Dir.ShrVld &
    Sta.Dir.ShrSet[p]) |
    ((Sta.Dir.HeadVld &
    Sta.Dir.HeadPtr = p) &
    Sta.Dir.HomeHeadPtr = false)))) then
      Sta.Dir.InvSet[p] := true;
      Sta.InvMsg[p].Cmd := INV_Inv;
    else
      Sta.Dir.InvSet[p] := false;
      Sta.InvMsg[p].Cmd := INV_None;
    end;
  end;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
  Sta.HomeInvMsg.Cmd := INV_None;
  Sta.UniMsg[src].Cmd := UNI_PutX;
  Sta.UniMsg[src].Data := Sta.MemData;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_GetX_PutX_931"
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].HomeProc &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadVld &
  Sta.Dir.HeadPtr != src &
  Sta.Dir.Local = false
==>
begin
  Sta.Dir.Pending := true;
  Sta.Dir.Local := false;
  Sta.Dir.Dirty := true;
  Sta.Dir.HeadVld := true;
  Sta.Dir.HeadPtr := src;
  Sta.Dir.HomeHeadPtr := false;
  Sta.Dir.ShrVld := false;
  for p : NODE do
    Sta.Dir.ShrSet[p] := false;
    if ((p != src &
    ((Sta.Dir.ShrVld &
    Sta.Dir.ShrSet[p]) |
    ((Sta.Dir.HeadVld &
    Sta.Dir.HeadPtr = p) &
    Sta.Dir.HomeHeadPtr = false)))) then
      Sta.Dir.InvSet[p] := true;
      Sta.InvMsg[p].Cmd := INV_Inv;
    else
      Sta.Dir.InvSet[p] := false;
      Sta.InvMsg[p].Cmd := INV_None;
    end;
  end;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
  Sta.HomeInvMsg.Cmd := INV_None;
  Sta.UniMsg[src].Cmd := UNI_PutX;
  Sta.UniMsg[src].Data := Sta.MemData;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_GetX_PutX_932"
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].HomeProc &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadVld &
  Sta.Dir.HomeHeadPtr = true &
  Sta.Dir.Local = false
==>
begin
  Sta.Dir.Pending := true;
  Sta.Dir.Local := false;
  Sta.Dir.Dirty := true;
  Sta.Dir.HeadVld := true;
  Sta.Dir.HeadPtr := src;
  Sta.Dir.HomeHeadPtr := false;
  Sta.Dir.ShrVld := false;
  for p : NODE do
    Sta.Dir.ShrSet[p] := false;
    if ((p != src &
    ((Sta.Dir.ShrVld &
    Sta.Dir.ShrSet[p]) |
    ((Sta.Dir.HeadVld &
    Sta.Dir.HeadPtr = p) &
    Sta.Dir.HomeHeadPtr = false)))) then
      Sta.Dir.InvSet[p] := true;
      Sta.InvMsg[p].Cmd := INV_Inv;
    else
      Sta.Dir.InvSet[p] := false;
      Sta.InvMsg[p].Cmd := INV_None;
    end;
  end;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
  Sta.HomeInvMsg.Cmd := INV_None;
  Sta.UniMsg[src].Cmd := UNI_PutX;
  Sta.UniMsg[src].Data := Sta.MemData;
endrule;
endruleset;

ruleset  dst : NODE; src : NODE do
rule "NI_Local_GetX_PutX_8_NODE_Get33"
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].HomeProc &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadVld &
  Sta.Dir.HeadPtr = src &
  Sta.Dir.HomeHeadPtr = false &
  Sta.Dir.ShrSet[dst] &
  Sta.Dir.Local = true &
  Sta.HomeProc.ProcCmd = NODE_Get
==>
begin
  Sta.Dir.Pending := true;
  Sta.Dir.Local := false;
  Sta.Dir.Dirty := true;
  Sta.Dir.HeadVld := true;
  Sta.Dir.HeadPtr := src;
  Sta.Dir.HomeHeadPtr := false;
  Sta.Dir.ShrVld := false;
  for p : NODE do
    Sta.Dir.ShrSet[p] := false;
    if ((p != src &
    ((Sta.Dir.ShrVld &
    Sta.Dir.ShrSet[p]) |
    ((Sta.Dir.HeadVld &
    Sta.Dir.HeadPtr = p) &
    Sta.Dir.HomeHeadPtr = false)))) then
      Sta.Dir.InvSet[p] := true;
      Sta.InvMsg[p].Cmd := INV_Inv;
    else
      Sta.Dir.InvSet[p] := false;
      Sta.InvMsg[p].Cmd := INV_None;
    end;
  end;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
  Sta.HomeInvMsg.Cmd := INV_None;
  Sta.UniMsg[src].Cmd := UNI_PutX;
  Sta.UniMsg[src].Data := Sta.MemData;
  Sta.HomeProc.CacheState := CACHE_I;
  undefine Sta.HomeProc.CacheData;
  Sta.HomeProc.InvMarked := true;
endrule;
endruleset;

ruleset  dst : NODE; src : NODE do
rule "NI_Local_GetX_PutX_834"
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].HomeProc &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadVld &
  Sta.Dir.HeadPtr = src &
  Sta.Dir.HomeHeadPtr = false &
  Sta.Dir.ShrSet[dst] &
  Sta.Dir.Local = true &
  Sta.HomeProc.ProcCmd != NODE_Get
==>
begin
  Sta.Dir.Pending := true;
  Sta.Dir.Local := false;
  Sta.Dir.Dirty := true;
  Sta.Dir.HeadVld := true;
  Sta.Dir.HeadPtr := src;
  Sta.Dir.HomeHeadPtr := false;
  Sta.Dir.ShrVld := false;
  for p : NODE do
    Sta.Dir.ShrSet[p] := false;
    if ((p != src &
    ((Sta.Dir.ShrVld &
    Sta.Dir.ShrSet[p]) |
    ((Sta.Dir.HeadVld &
    Sta.Dir.HeadPtr = p) &
    Sta.Dir.HomeHeadPtr = false)))) then
      Sta.Dir.InvSet[p] := true;
      Sta.InvMsg[p].Cmd := INV_Inv;
    else
      Sta.Dir.InvSet[p] := false;
      Sta.InvMsg[p].Cmd := INV_None;
    end;
  end;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
  Sta.HomeInvMsg.Cmd := INV_None;
  Sta.UniMsg[src].Cmd := UNI_PutX;
  Sta.UniMsg[src].Data := Sta.MemData;
  Sta.HomeProc.CacheState := CACHE_I;
  undefine Sta.HomeProc.CacheData;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_GetX_PutX_8_Home_NODE_Get35"
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].HomeProc &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadVld &
  Sta.Dir.HeadPtr = src &
  Sta.Dir.HomeHeadPtr = false &
  Sta.Dir.HomeShrSet &
  Sta.Dir.Local = true &
  Sta.HomeProc.ProcCmd = NODE_Get
==>
begin
  Sta.Dir.Pending := true;
  Sta.Dir.Local := false;
  Sta.Dir.Dirty := true;
  Sta.Dir.HeadVld := true;
  Sta.Dir.HeadPtr := src;
  Sta.Dir.HomeHeadPtr := false;
  Sta.Dir.ShrVld := false;
  for p : NODE do
    Sta.Dir.ShrSet[p] := false;
    if ((p != src &
    ((Sta.Dir.ShrVld &
    Sta.Dir.ShrSet[p]) |
    ((Sta.Dir.HeadVld &
    Sta.Dir.HeadPtr = p) &
    Sta.Dir.HomeHeadPtr = false)))) then
      Sta.Dir.InvSet[p] := true;
      Sta.InvMsg[p].Cmd := INV_Inv;
    else
      Sta.Dir.InvSet[p] := false;
      Sta.InvMsg[p].Cmd := INV_None;
    end;
  end;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
  Sta.HomeInvMsg.Cmd := INV_None;
  Sta.UniMsg[src].Cmd := UNI_PutX;
  Sta.UniMsg[src].Data := Sta.MemData;
  Sta.HomeProc.CacheState := CACHE_I;
  undefine Sta.HomeProc.CacheData;
  Sta.HomeProc.InvMarked := true;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_GetX_PutX_8_Home36"
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].HomeProc &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadVld &
  Sta.Dir.HeadPtr = src &
  Sta.Dir.HomeHeadPtr = false &
  Sta.Dir.HomeShrSet &
  Sta.Dir.Local = true &
  Sta.HomeProc.ProcCmd != NODE_Get
==>
begin
  Sta.Dir.Pending := true;
  Sta.Dir.Local := false;
  Sta.Dir.Dirty := true;
  Sta.Dir.HeadVld := true;
  Sta.Dir.HeadPtr := src;
  Sta.Dir.HomeHeadPtr := false;
  Sta.Dir.ShrVld := false;
  for p : NODE do
    Sta.Dir.ShrSet[p] := false;
    if ((p != src &
    ((Sta.Dir.ShrVld &
    Sta.Dir.ShrSet[p]) |
    ((Sta.Dir.HeadVld &
    Sta.Dir.HeadPtr = p) &
    Sta.Dir.HomeHeadPtr = false)))) then
      Sta.Dir.InvSet[p] := true;
      Sta.InvMsg[p].Cmd := INV_Inv;
    else
      Sta.Dir.InvSet[p] := false;
      Sta.InvMsg[p].Cmd := INV_None;
    end;
  end;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
  Sta.HomeInvMsg.Cmd := INV_None;
  Sta.UniMsg[src].Cmd := UNI_PutX;
  Sta.UniMsg[src].Data := Sta.MemData;
  Sta.HomeProc.CacheState := CACHE_I;
  undefine Sta.HomeProc.CacheData;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_GetX_PutX_7_NODE_Get37"
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].HomeProc &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadVld &
  Sta.Dir.HeadPtr != src &
  Sta.Dir.Local = true &
  Sta.HomeProc.ProcCmd = NODE_Get
==>
begin
  Sta.Dir.Pending := true;
  Sta.Dir.Local := false;
  Sta.Dir.Dirty := true;
  Sta.Dir.HeadVld := true;
  Sta.Dir.HeadPtr := src;
  Sta.Dir.HomeHeadPtr := false;
  Sta.Dir.ShrVld := false;
  for p : NODE do
    Sta.Dir.ShrSet[p] := false;
    if ((p != src &
    ((Sta.Dir.ShrVld &
    Sta.Dir.ShrSet[p]) |
    ((Sta.Dir.HeadVld &
    Sta.Dir.HeadPtr = p) &
    Sta.Dir.HomeHeadPtr = false)))) then
      Sta.Dir.InvSet[p] := true;
      Sta.InvMsg[p].Cmd := INV_Inv;
    else
      Sta.Dir.InvSet[p] := false;
      Sta.InvMsg[p].Cmd := INV_None;
    end;
  end;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
  Sta.HomeInvMsg.Cmd := INV_None;
  Sta.UniMsg[src].Cmd := UNI_PutX;
  Sta.UniMsg[src].Data := Sta.MemData;
  Sta.HomeProc.CacheState := CACHE_I;
  Sta.HomeProc.InvMarked := true;
  undefine Sta.HomeProc.CacheData;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_GetX_PutX_7_NODE_Get38"
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].HomeProc &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadVld &
  Sta.Dir.HomeHeadPtr = true &
  Sta.Dir.Local = true &
  Sta.HomeProc.ProcCmd = NODE_Get
==>
begin
  Sta.Dir.Pending := true;
  Sta.Dir.Local := false;
  Sta.Dir.Dirty := true;
  Sta.Dir.HeadVld := true;
  Sta.Dir.HeadPtr := src;
  Sta.Dir.HomeHeadPtr := false;
  Sta.Dir.ShrVld := false;
  for p : NODE do
    Sta.Dir.ShrSet[p] := false;
    if ((p != src &
    ((Sta.Dir.ShrVld &
    Sta.Dir.ShrSet[p]) |
    ((Sta.Dir.HeadVld &
    Sta.Dir.HeadPtr = p) &
    Sta.Dir.HomeHeadPtr = false)))) then
      Sta.Dir.InvSet[p] := true;
      Sta.InvMsg[p].Cmd := INV_Inv;
    else
      Sta.Dir.InvSet[p] := false;
      Sta.InvMsg[p].Cmd := INV_None;
    end;
  end;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
  Sta.HomeInvMsg.Cmd := INV_None;
  Sta.UniMsg[src].Cmd := UNI_PutX;
  Sta.UniMsg[src].Data := Sta.MemData;
  Sta.HomeProc.CacheState := CACHE_I;
  Sta.HomeProc.InvMarked := true;
  undefine Sta.HomeProc.CacheData;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_GetX_PutX_739"
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].HomeProc &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadVld &
  Sta.Dir.HeadPtr != src &
  Sta.Dir.Local = true &
  Sta.HomeProc.ProcCmd != NODE_Get
==>
begin
  Sta.Dir.Pending := true;
  Sta.Dir.Local := false;
  Sta.Dir.Dirty := true;
  Sta.Dir.HeadVld := true;
  Sta.Dir.HeadPtr := src;
  Sta.Dir.HomeHeadPtr := false;
  Sta.Dir.ShrVld := false;
  for p : NODE do
    Sta.Dir.ShrSet[p] := false;
    if ((p != src &
    ((Sta.Dir.ShrVld &
    Sta.Dir.ShrSet[p]) |
    ((Sta.Dir.HeadVld &
    Sta.Dir.HeadPtr = p) &
    Sta.Dir.HomeHeadPtr = false)))) then
      Sta.Dir.InvSet[p] := true;
      Sta.InvMsg[p].Cmd := INV_Inv;
    else
      Sta.Dir.InvSet[p] := false;
      Sta.InvMsg[p].Cmd := INV_None;
    end;
  end;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
  Sta.HomeInvMsg.Cmd := INV_None;
  Sta.UniMsg[src].Cmd := UNI_PutX;
  Sta.UniMsg[src].Data := Sta.MemData;
  Sta.HomeProc.CacheState := CACHE_I;
  undefine Sta.HomeProc.CacheData;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_GetX_PutX_740"
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].HomeProc &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadVld &
  Sta.Dir.HomeHeadPtr = false &
  Sta.Dir.Local = true &
  Sta.HomeProc.ProcCmd != NODE_Get
==>
begin
  Sta.Dir.Pending := true;
  Sta.Dir.Local := false;
  Sta.Dir.Dirty := true;
  Sta.Dir.HeadVld := true;
  Sta.Dir.HeadPtr := src;
  Sta.Dir.HomeHeadPtr := false;
  Sta.Dir.ShrVld := false;
  for p : NODE do
    Sta.Dir.ShrSet[p] := false;
    if ((p != src &
    ((Sta.Dir.ShrVld &
    Sta.Dir.ShrSet[p]) |
    ((Sta.Dir.HeadVld &
    Sta.Dir.HeadPtr = p) &
    Sta.Dir.HomeHeadPtr = false)))) then
      Sta.Dir.InvSet[p] := true;
      Sta.InvMsg[p].Cmd := INV_Inv;
    else
      Sta.Dir.InvSet[p] := false;
      Sta.InvMsg[p].Cmd := INV_None;
    end;
  end;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
  Sta.HomeInvMsg.Cmd := INV_None;
  Sta.UniMsg[src].Cmd := UNI_PutX;
  Sta.UniMsg[src].Data := Sta.MemData;
  Sta.HomeProc.CacheState := CACHE_I;
  undefine Sta.HomeProc.CacheData;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_GetX_PutX_641"
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].HomeProc &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadPtr = src &
  Sta.Dir.HomeHeadPtr = false &
  Sta.Dir.HomeShrSet = false &
  forall p : NODE do
    p != src ->
    Sta.Dir.ShrSet[p] = false
  end &
  Sta.Dir.Local = false
==>
begin
  Sta.Dir.Local := false;
  Sta.Dir.Dirty := true;
  Sta.Dir.HeadVld := true;
  Sta.Dir.HeadPtr := src;
  Sta.Dir.HomeHeadPtr := false;
  Sta.Dir.ShrVld := false;
  for p : NODE do
    Sta.Dir.ShrSet[p] := false;
    Sta.Dir.InvSet[p] := false;
  end;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
  Sta.UniMsg[src].Cmd := UNI_PutX;
  Sta.UniMsg[src].Data := Sta.MemData;
  Sta.HomeProc.CacheState := CACHE_I;
  undefine Sta.HomeProc.CacheData;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_GetX_PutX_542"
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].HomeProc &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadPtr = src &
  Sta.Dir.HomeHeadPtr = false &
  Sta.Dir.HomeShrSet = false &
  forall p : NODE do
    p != src ->
    Sta.Dir.ShrSet[p] = false
  end &
  Sta.Dir.Local = true &
  Sta.HomeProc.ProcCmd != NODE_Get
==>
begin
  Sta.Dir.Local := false;
  Sta.Dir.Dirty := true;
  Sta.Dir.HeadVld := true;
  Sta.Dir.HeadPtr := src;
  Sta.Dir.HomeHeadPtr := false;
  Sta.Dir.ShrVld := false;
  for p : NODE do
    Sta.Dir.ShrSet[p] := false;
    Sta.Dir.InvSet[p] := false;
  end;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
  Sta.UniMsg[src].Cmd := UNI_PutX;
  Sta.UniMsg[src].Data := Sta.MemData;
  Sta.HomeProc.CacheState := CACHE_I;
  undefine Sta.HomeProc.CacheData;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_GetX_PutX_443"
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].HomeProc &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadPtr = src &
  Sta.Dir.HomeHeadPtr = false &
  Sta.Dir.HomeShrSet = false &
  forall p : NODE do
    p != src ->
    Sta.Dir.ShrSet[p] = false
  end &
  Sta.Dir.Local = true &
  Sta.HomeProc.ProcCmd = NODE_Get
==>
begin
  Sta.Dir.Local := false;
  Sta.Dir.Dirty := true;
  Sta.Dir.HeadVld := true;
  Sta.Dir.HeadPtr := src;
  Sta.Dir.HomeHeadPtr := false;
  Sta.Dir.ShrVld := false;
  for p : NODE do
    Sta.Dir.ShrSet[p] := false;
    Sta.Dir.InvSet[p] := false;
  end;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
  Sta.UniMsg[src].Cmd := UNI_PutX;
  Sta.UniMsg[src].Data := Sta.MemData;
  Sta.HomeProc.CacheState := CACHE_I;
  undefine Sta.HomeProc.CacheData;
  Sta.HomeProc.InvMarked := true;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_GetX_PutX_344"
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].HomeProc &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadVld = false &
  Sta.Dir.Local = false
==>
begin
  Sta.Dir.Local := false;
  Sta.Dir.Dirty := true;
  Sta.Dir.HeadVld := true;
  Sta.Dir.HeadPtr := src;
  Sta.Dir.HomeHeadPtr := false;
  Sta.Dir.ShrVld := false;
  for p : NODE do
    Sta.Dir.ShrSet[p] := false;
    Sta.Dir.InvSet[p] := false;
  end;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
  Sta.UniMsg[src].Cmd := UNI_PutX;
  Sta.UniMsg[src].Data := Sta.MemData;
  Sta.HomeProc.CacheState := CACHE_I;
  undefine Sta.HomeProc.CacheData;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_GetX_PutX_245"
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].HomeProc &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadVld = false &
  Sta.Dir.Local = true &
  Sta.HomeProc.ProcCmd != NODE_Get
==>
begin
  Sta.Dir.Local := false;
  Sta.Dir.Dirty := true;
  Sta.Dir.HeadVld := true;
  Sta.Dir.HeadPtr := src;
  Sta.Dir.HomeHeadPtr := false;
  Sta.Dir.ShrVld := false;
  for p : NODE do
    Sta.Dir.ShrSet[p] := false;
    Sta.Dir.InvSet[p] := false;
  end;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
  Sta.UniMsg[src].Cmd := UNI_PutX;
  Sta.UniMsg[src].Data := Sta.MemData;
  Sta.HomeProc.CacheState := CACHE_I;
  undefine Sta.HomeProc.CacheData;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_GetX_PutX_146"
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].HomeProc &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadVld = false &
  Sta.Dir.Local = true &
  Sta.HomeProc.ProcCmd = NODE_Get
==>
begin
  Sta.Dir.Local := false;
  Sta.Dir.Dirty := true;
  Sta.Dir.HeadVld := true;
  Sta.Dir.HeadPtr := src;
  Sta.Dir.HomeHeadPtr := false;
  Sta.Dir.ShrVld := false;
  for p : NODE do
    Sta.Dir.ShrSet[p] := false;
    Sta.Dir.InvSet[p] := false;
  end;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
  Sta.UniMsg[src].Cmd := UNI_PutX;
  Sta.UniMsg[src].Data := Sta.MemData;
  Sta.HomeProc.CacheState := CACHE_I;
  Sta.HomeProc.InvMarked := true;
  undefine Sta.HomeProc.CacheData;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_GetX_GetX47"
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].HomeProc &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = true &
  Sta.Dir.Local = false &
  Sta.Dir.HeadPtr != src
==>
begin
  Sta.Dir.Pending := true;
  Sta.UniMsg[src].Cmd := UNI_GetX;
  Sta.UniMsg[src].Proc := Sta.Dir.HeadPtr;
  undefine Sta.UniMsg[src].Data;
  Sta.UniMsg[src].HomeProc := Sta.Dir.HomeHeadPtr;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_GetX_GetX48"
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].HomeProc &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = true &
  Sta.Dir.Local = false &
  Sta.Dir.HomeHeadPtr = true
==>
begin
  Sta.Dir.Pending := true;
  Sta.UniMsg[src].Cmd := UNI_GetX;
  Sta.UniMsg[src].Proc := Sta.Dir.HeadPtr;
  undefine Sta.UniMsg[src].Data;
  Sta.UniMsg[src].HomeProc := Sta.Dir.HomeHeadPtr;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_GetX_Nak49"
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].HomeProc &
  Sta.Dir.Pending = true
==>
begin
  Sta.UniMsg[src].Cmd := UNI_Nak;
  Sta.UniMsg[src].HomeProc := true;
  undefine Sta.UniMsg[src].Proc;
  undefine Sta.UniMsg[src].Data;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_GetX_Nak50"
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].HomeProc &
  Sta.Dir.Dirty = true &
  Sta.Dir.Local = true &
  Sta.HomeProc.CacheState != CACHE_E
==>
begin
  Sta.UniMsg[src].Cmd := UNI_Nak;
  Sta.UniMsg[src].HomeProc := true;
  undefine Sta.UniMsg[src].Proc;
  undefine Sta.UniMsg[src].Data;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_GetX_Nak51"
  Sta.UniMsg[src].Cmd = UNI_GetX &
  Sta.UniMsg[src].HomeProc &
  Sta.Dir.Dirty = true &
  Sta.Dir.Local = false &
  Sta.Dir.HeadPtr = src &
  Sta.Dir.HomeHeadPtr = false
==>
begin
  Sta.UniMsg[src].Cmd := UNI_Nak;
  Sta.UniMsg[src].HomeProc := true;
  undefine Sta.UniMsg[src].Proc;
  undefine Sta.UniMsg[src].Data;
endrule;
endruleset;

ruleset  dst : NODE do
rule "NI_Remote_Get_Put_Home52"
  Sta.HomeUniMsg.Cmd = UNI_Get &
  Sta.HomeUniMsg.Proc = dst &
  Sta.HomeUniMsg.HomeProc = false &
  Sta.Proc[dst].CacheState = CACHE_E
==>
begin
  Sta.Proc[dst].CacheState := CACHE_S;
  Sta.HomeUniMsg.Cmd := UNI_Put;
  Sta.HomeUniMsg.Data := Sta.Proc[dst].CacheData;
endrule;
endruleset;

ruleset  dst : NODE; src : NODE do
rule "NI_Remote_Get_Put53"
  src != dst &
  Sta.UniMsg[src].Cmd = UNI_Get &
  Sta.UniMsg[src].Proc = dst &
  Sta.UniMsg[src].HomeProc = false &
  Sta.Proc[dst].CacheState = CACHE_E
==>
begin
  Sta.Proc[dst].CacheState := CACHE_S;
  Sta.UniMsg[src].Cmd := UNI_Put;
  Sta.UniMsg[src].Data := Sta.Proc[dst].CacheData;
  Sta.ShWbMsg.Cmd := SHWB_ShWb;
  Sta.ShWbMsg.Proc := src;
  Sta.ShWbMsg.HomeProc := false;
  Sta.ShWbMsg.Data := Sta.Proc[dst].CacheData;
endrule;
endruleset;

ruleset  dst : NODE do
rule "NI_Remote_Get_Nak_Home54"
  Sta.HomeUniMsg.Cmd = UNI_Get &
  Sta.HomeUniMsg.Proc = dst &
  Sta.HomeUniMsg.HomeProc = false &
  Sta.Proc[dst].CacheState != CACHE_E
==>
begin
  Sta.HomeUniMsg.Cmd := UNI_Nak;
  Sta.NakcMsg.Cmd := NAKC_Nakc;
  undefine Sta.HomeUniMsg.Data;
  undefine Sta.HomeUniMsg.Proc;
endrule;
endruleset;

ruleset  dst : NODE; src : NODE do
rule "NI_Remote_Get_Nak55"
  src != dst &
  Sta.UniMsg[src].Cmd = UNI_Get &
  Sta.UniMsg[src].Proc = dst &
  Sta.UniMsg[src].HomeProc = false &
  Sta.Proc[dst].CacheState != CACHE_E
==>
begin
  Sta.UniMsg[src].Cmd := UNI_Nak;
  Sta.UniMsg[src].Proc := dst;
  Sta.UniMsg[src].HomeProc := false;
  undefine Sta.UniMsg[src].Data;
  Sta.NakcMsg.Cmd := NAKC_Nakc;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_Get_Put_Dirty56"
  Sta.UniMsg[src].Cmd = UNI_Get &
  Sta.UniMsg[src].HomeProc &
  Sta.RpMsg[src].Cmd != RP_Replace &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = true &
  Sta.Dir.Local = true &
  Sta.HomeProc.CacheState = CACHE_E
==>
begin
  Sta.Dir.Dirty := false;
  Sta.Dir.HeadVld := true;
  Sta.Dir.HeadPtr := src;
  Sta.Dir.HomeHeadPtr := false;
  Sta.MemData := Sta.HomeProc.CacheData;
  Sta.HomeProc.CacheState := CACHE_S;
  Sta.UniMsg[src].Cmd := UNI_Put;
  Sta.UniMsg[src].Data := Sta.HomeProc.CacheData;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_Get_Put57"
  Sta.UniMsg[src].Cmd = UNI_Get &
  Sta.UniMsg[src].HomeProc &
  Sta.RpMsg[src].Cmd != RP_Replace &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadVld = false
==>
begin
  Sta.Dir.HeadVld := true;
  Sta.Dir.HeadPtr := src;
  Sta.Dir.HomeHeadPtr := false;
  Sta.UniMsg[src].Cmd := UNI_Put;
  Sta.UniMsg[src].Data := Sta.MemData;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_Get_Put_Head58"
  Sta.UniMsg[src].Cmd = UNI_Get &
  Sta.UniMsg[src].HomeProc &
  Sta.RpMsg[src].Cmd != RP_Replace &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadVld
==>
begin
  Sta.Dir.ShrVld := true;
  Sta.Dir.ShrSet[src] := true;
  for p : NODE do
    if (p = src) then
      Sta.Dir.InvSet[p] := true;
    else
      Sta.Dir.InvSet[p] := Sta.Dir.ShrSet[p];
    end;
  end;
  Sta.Dir.HomeInvSet := Sta.Dir.HomeShrSet;
  Sta.UniMsg[src].Cmd := UNI_Put;
  Sta.UniMsg[src].Data := Sta.MemData;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_Get_Get59"
  Sta.UniMsg[src].Cmd = UNI_Get &
  Sta.UniMsg[src].HomeProc &
  Sta.RpMsg[src].Cmd != RP_Replace &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = true &
  Sta.Dir.Local = false &
  Sta.Dir.HeadPtr != src
==>
begin
  Sta.Dir.Pending := true;
  Sta.UniMsg[src].Cmd := UNI_Get;
  Sta.UniMsg[src].Proc := Sta.Dir.HeadPtr;
  undefine Sta.UniMsg[src].Data;
  Sta.UniMsg[src].HomeProc := Sta.Dir.HomeHeadPtr;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_Get_Get60"
  Sta.UniMsg[src].Cmd = UNI_Get &
  Sta.UniMsg[src].HomeProc &
  Sta.RpMsg[src].Cmd != RP_Replace &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = true &
  Sta.Dir.Local = false &
  Sta.Dir.HomeHeadPtr = true
==>
begin
  Sta.Dir.Pending := true;
  Sta.UniMsg[src].Cmd := UNI_Get;
  Sta.UniMsg[src].Proc := Sta.Dir.HeadPtr;
  undefine Sta.UniMsg[src].Data;
  Sta.UniMsg[src].HomeProc := Sta.Dir.HomeHeadPtr;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_Get_Nak61"
  Sta.UniMsg[src].Cmd = UNI_Get &
  Sta.UniMsg[src].HomeProc &
  Sta.RpMsg[src].Cmd != RP_Replace &
  Sta.Dir.Pending = true
==>
begin
  Sta.UniMsg[src].Cmd := UNI_Nak;
  Sta.UniMsg[src].HomeProc := true;
  undefine Sta.UniMsg[src].Proc;
  undefine Sta.UniMsg[src].Data;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_Get_Nak62"
  Sta.UniMsg[src].Cmd = UNI_Get &
  Sta.UniMsg[src].HomeProc &
  Sta.RpMsg[src].Cmd != RP_Replace &
  Sta.Dir.Dirty = true &
  Sta.Dir.Local = true &
  Sta.HomeProc.CacheState != CACHE_E
==>
begin
  Sta.UniMsg[src].Cmd := UNI_Nak;
  Sta.UniMsg[src].HomeProc := true;
  undefine Sta.UniMsg[src].Proc;
  undefine Sta.UniMsg[src].Data;
endrule;
endruleset;

ruleset  src : NODE do
rule "NI_Local_Get_Nak63"
  Sta.UniMsg[src].Cmd = UNI_Get &
  Sta.UniMsg[src].HomeProc &
  Sta.RpMsg[src].Cmd != RP_Replace &
  Sta.Dir.Dirty = true &
  Sta.Dir.Local = false &
  Sta.Dir.HeadPtr = src &
  Sta.Dir.HomeHeadPtr = false
==>
begin
  Sta.UniMsg[src].Cmd := UNI_Nak;
  Sta.UniMsg[src].HomeProc := true;
  undefine Sta.UniMsg[src].Proc;
  undefine Sta.UniMsg[src].Data;
endrule;
endruleset;

rule "NI_Nak_Clear64"
  Sta.NakcMsg.Cmd = NAKC_Nakc
==>
begin
  Sta.NakcMsg.Cmd := NAKC_None;
  Sta.Dir.Pending := false;
endrule;

rule "NI_Nak_Home65"
  Sta.HomeUniMsg.Cmd = UNI_Nak
==>
begin
  Sta.HomeUniMsg.Cmd := UNI_None;
  Sta.HomeUniMsg.HomeProc := false;
  Sta.HomeProc.ProcCmd := NODE_None;
  Sta.HomeProc.InvMarked := false;
  undefine Sta.HomeUniMsg.Proc;
  undefine Sta.HomeUniMsg.Data;
endrule;

ruleset  dst : NODE do
rule "NI_Nak66"
  Sta.UniMsg[dst].Cmd = UNI_Nak
==>
begin
  Sta.UniMsg[dst].Cmd := UNI_None;
  Sta.UniMsg[dst].HomeProc := false;
  Sta.Proc[dst].ProcCmd := NODE_None;
  Sta.Proc[dst].InvMarked := false;
  undefine Sta.UniMsg[dst].Proc;
  undefine Sta.UniMsg[dst].Data;
endrule;
endruleset;

rule "PI_Local_Replace67"
  Sta.HomeProc.ProcCmd = NODE_None &
  Sta.HomeProc.CacheState = CACHE_S
==>
begin
  Sta.Dir.Local := false;
  Sta.HomeProc.CacheState := CACHE_I;
  undefine Sta.HomeProc.CacheData;
endrule;

ruleset  src : NODE do
rule "PI_Remote_Replace68"
  Sta.Proc[src].ProcCmd = NODE_None &
  Sta.Proc[src].CacheState = CACHE_S
==>
begin
  Sta.Proc[src].CacheState := CACHE_I;
  Sta.RpMsg[src].Cmd := RP_Replace;
  undefine Sta.Proc[src].CacheData;
endrule;
endruleset;

rule "PI_Local_PutX69"
  Sta.HomeProc.ProcCmd = NODE_None &
  Sta.HomeProc.CacheState = CACHE_E &
  Sta.Dir.Pending = true
==>
begin
  Sta.HomeProc.CacheState := CACHE_I;
  Sta.Dir.Dirty := false;
  Sta.MemData := Sta.HomeProc.CacheData;
  undefine Sta.HomeProc.CacheData;
endrule;

rule "PI_Local_PutX70"
  Sta.HomeProc.ProcCmd = NODE_None &
  Sta.HomeProc.CacheState = CACHE_E &
  Sta.Dir.Pending != true
==>
begin
  Sta.HomeProc.CacheState := CACHE_I;
  Sta.Dir.Local := false;
  Sta.Dir.Dirty := false;
  Sta.MemData := Sta.HomeProc.CacheData;
  undefine Sta.HomeProc.CacheData;
endrule;

ruleset  dst : NODE do
rule "PI_Remote_PutX71"
  Sta.Proc[dst].ProcCmd = NODE_None &
  Sta.Proc[dst].CacheState = CACHE_E
==>
begin
  Sta.Proc[dst].CacheState := CACHE_I;
  Sta.WbMsg.Cmd := WB_Wb;
  Sta.WbMsg.Proc := dst;
  Sta.WbMsg.HomeProc := false;
  Sta.WbMsg.Data := Sta.Proc[dst].CacheData;
  undefine Sta.Proc[dst].CacheData;
endrule;
endruleset;

rule "PI_Local_GetX_PutX_HeadVld7572"
  Sta.HomeProc.ProcCmd = NODE_None &
  Sta.HomeProc.CacheState = CACHE_S &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadVld = true
==>
begin
  Sta.Dir.Local := true;
  Sta.Dir.Dirty := true;
  Sta.Dir.Pending := true;
  Sta.Dir.HeadVld := false;
  Sta.Dir.ShrVld := false;
  for p : NODE do
    Sta.Dir.ShrSet[p] := false;
    if (((Sta.Dir.ShrVld &
    Sta.Dir.ShrSet[p]) |
    (Sta.Dir.HeadPtr = p &
    Sta.Dir.HomeHeadPtr = false))) then
      Sta.Dir.InvSet[p] := true;
      Sta.InvMsg[p].Cmd := INV_Inv;
    else
      Sta.Dir.InvSet[p] := false;
      Sta.InvMsg[p].Cmd := INV_None;
    end;
  end;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
  Sta.HomeInvMsg.Cmd := INV_None;
  Sta.HomeProc.ProcCmd := NODE_None;
  Sta.HomeProc.InvMarked := false;
  Sta.HomeProc.CacheState := CACHE_E;
  Sta.HomeProc.CacheData := Sta.MemData;
endrule;

rule "PI_Local_GetX_PutX_HeadVld7473"
  Sta.HomeProc.ProcCmd = NODE_None &
  Sta.HomeProc.CacheState = CACHE_I &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadVld = true
==>
begin
  Sta.Dir.Local := true;
  Sta.Dir.Dirty := true;
  Sta.Dir.Pending := true;
  Sta.Dir.HeadVld := false;
  Sta.Dir.ShrVld := false;
  for p : NODE do
    Sta.Dir.ShrSet[p] := false;
    if (((Sta.Dir.ShrVld &
    Sta.Dir.ShrSet[p]) |
    (Sta.Dir.HeadPtr = p &
    Sta.Dir.HomeHeadPtr = false))) then
      Sta.Dir.InvSet[p] := true;
      Sta.InvMsg[p].Cmd := INV_Inv;
    else
      Sta.Dir.InvSet[p] := false;
      Sta.InvMsg[p].Cmd := INV_None;
    end;
  end;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
  Sta.HomeInvMsg.Cmd := INV_None;
  Sta.HomeProc.ProcCmd := NODE_None;
  Sta.HomeProc.InvMarked := false;
  Sta.HomeProc.CacheState := CACHE_E;
  Sta.HomeProc.CacheData := Sta.MemData;
endrule;

rule "PI_Local_GetX_PutX7374"
  Sta.HomeProc.ProcCmd = NODE_None &
  Sta.HomeProc.CacheState = CACHE_S &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadVld = false
==>
begin
  Sta.Dir.Local := true;
  Sta.Dir.Dirty := true;
  Sta.HomeProc.ProcCmd := NODE_None;
  Sta.HomeProc.InvMarked := false;
  Sta.HomeProc.CacheState := CACHE_E;
  Sta.HomeProc.CacheData := Sta.MemData;
endrule;

rule "PI_Local_GetX_PutX7275"
  Sta.HomeProc.ProcCmd = NODE_None &
  Sta.HomeProc.CacheState = CACHE_I &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadVld = false
==>
begin
  Sta.Dir.Local := true;
  Sta.Dir.Dirty := true;
  Sta.HomeProc.ProcCmd := NODE_None;
  Sta.HomeProc.InvMarked := false;
  Sta.HomeProc.CacheState := CACHE_E;
  Sta.HomeProc.CacheData := Sta.MemData;
endrule;

rule "PI_Local_GetX_PutX_HeadVld76"
  Sta.HomeProc.ProcCmd = NODE_None &
  Sta.HomeProc.CacheState = CACHE_I &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadVld = true
==>
begin
  Sta.Dir.Local := true;
  Sta.Dir.Dirty := true;
  Sta.Dir.Pending := true;
  Sta.Dir.HeadVld := false;
  undefine Sta.Dir.HeadPtr;
  Sta.Dir.ShrVld := false;
  for p : NODE do
    Sta.Dir.ShrSet[p] := false;
    if (((Sta.Dir.ShrVld &
    Sta.Dir.ShrSet[p]) |
    (Sta.Dir.HeadPtr = p &
    Sta.Dir.HomeHeadPtr = false))) then
      Sta.Dir.InvSet[p] := true;
      Sta.InvMsg[p].Cmd := INV_Inv;
    else
      Sta.Dir.InvSet[p] := false;
      Sta.InvMsg[p].Cmd := INV_None;
    end;
  end;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
  Sta.HomeInvMsg.Cmd := INV_None;
  Sta.HomeProc.ProcCmd := NODE_None;
  Sta.HomeProc.InvMarked := false;
  Sta.HomeProc.CacheState := CACHE_E;
  Sta.HomeProc.CacheData := Sta.MemData;
endrule;

rule "PI_Local_GetX_PutX_HeadVld77"
  Sta.HomeProc.ProcCmd = NODE_None &
  Sta.HomeProc.CacheState = CACHE_S &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.Dir.HeadVld = true
==>
begin
  Sta.Dir.Local := true;
  Sta.Dir.Dirty := true;
  Sta.Dir.Pending := true;
  Sta.Dir.HeadVld := false;
  undefine Sta.Dir.HeadPtr;
  Sta.Dir.ShrVld := false;
  for p : NODE do
    Sta.Dir.ShrSet[p] := false;
    if (((Sta.Dir.ShrVld &
    Sta.Dir.ShrSet[p]) |
    (Sta.Dir.HeadPtr = p &
    Sta.Dir.HomeHeadPtr = false))) then
      Sta.Dir.InvSet[p] := true;
      Sta.InvMsg[p].Cmd := INV_Inv;
    else
      Sta.Dir.InvSet[p] := false;
      Sta.InvMsg[p].Cmd := INV_None;
    end;
  end;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
  Sta.HomeInvMsg.Cmd := INV_None;
  Sta.HomeProc.ProcCmd := NODE_None;
  Sta.HomeProc.InvMarked := false;
  Sta.HomeProc.CacheState := CACHE_E;
  Sta.HomeProc.CacheData := Sta.MemData;
endrule;

rule "PI_Local_GetX_GetX78"
  Sta.HomeProc.ProcCmd = NODE_None &
  Sta.HomeProc.CacheState = CACHE_I &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = true
==>
begin
  Sta.HomeProc.ProcCmd := NODE_GetX;
  Sta.Dir.Pending := true;
  Sta.HomeUniMsg.Cmd := UNI_GetX;
  Sta.HomeUniMsg.Proc := Sta.Dir.HeadPtr;
  Sta.HomeUniMsg.HomeProc := Sta.Dir.HomeHeadPtr;
endrule;

rule "PI_Local_GetX_GetX79"
  Sta.HomeProc.ProcCmd = NODE_None &
  Sta.HomeProc.CacheState = CACHE_S &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = true
==>
begin
  Sta.HomeProc.ProcCmd := NODE_GetX;
  Sta.Dir.Pending := true;
  Sta.HomeUniMsg.Cmd := UNI_GetX;
  Sta.HomeUniMsg.Proc := Sta.Dir.HeadPtr;
  Sta.HomeUniMsg.HomeProc := Sta.Dir.HomeHeadPtr;
endrule;

ruleset  src : NODE do
rule "PI_Remote_GetX80"
  Sta.Proc[src].ProcCmd = NODE_None &
  Sta.Proc[src].CacheState = CACHE_I
==>
begin
  Sta.Proc[src].ProcCmd := NODE_GetX;
  Sta.UniMsg[src].Cmd := UNI_GetX;
  Sta.UniMsg[src].HomeProc := true;
  undefine Sta.UniMsg[src].Proc;
  undefine Sta.UniMsg[src].Data;
endrule;
endruleset;

rule "PI_Local_Get_Put81"
  Sta.HomeProc.ProcCmd = NODE_None &
  Sta.HomeProc.CacheState = CACHE_I &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  Sta.HomeProc.InvMarked
==>
begin
  Sta.Dir.Local := true;
  Sta.HomeProc.ProcCmd := NODE_None;
  Sta.HomeProc.InvMarked := false;
  Sta.HomeProc.CacheState := CACHE_I;
  undefine Sta.HomeProc.CacheData;
endrule;

rule "PI_Local_Get_Put82"
  Sta.HomeProc.ProcCmd = NODE_None &
  Sta.HomeProc.CacheState = CACHE_I &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = false &
  !Sta.HomeProc.InvMarked
==>
begin
  Sta.Dir.Local := true;
  Sta.HomeProc.ProcCmd := NODE_None;
  Sta.HomeProc.CacheState := CACHE_S;
  Sta.HomeProc.CacheData := Sta.MemData;
endrule;

rule "PI_Local_Get_Get83"
  Sta.HomeProc.ProcCmd = NODE_None &
  Sta.HomeProc.CacheState = CACHE_I &
  Sta.Dir.Pending = false &
  Sta.Dir.Dirty = true
==>
begin
  Sta.HomeProc.ProcCmd := NODE_Get;
  Sta.Dir.Pending := true;
  Sta.HomeUniMsg.Cmd := UNI_Get;
  Sta.HomeUniMsg.Proc := Sta.Dir.HeadPtr;
  Sta.HomeUniMsg.HomeProc := Sta.Dir.HomeHeadPtr;
  undefine Sta.HomeUniMsg.Data;
endrule;

ruleset  src : NODE do
rule "PI_Remote_Get84"
  Sta.Proc[src].ProcCmd = NODE_None &
  Sta.Proc[src].CacheState = CACHE_I
==>
begin
  Sta.Proc[src].ProcCmd := NODE_Get;
  Sta.UniMsg[src].Cmd := UNI_Get;
  Sta.UniMsg[src].HomeProc := true;
  undefine Sta.UniMsg[src].Proc;
  undefine Sta.UniMsg[src].Data;
endrule;
endruleset;

ruleset  data : DATA do
rule "Store_Home85"
  Sta.HomeProc.CacheState = CACHE_E
==>
begin
  Sta.HomeProc.CacheData := data;
  Sta.CurrData := data;
endrule;
endruleset;

ruleset  data : DATA; src : NODE do
rule "Store86"
  Sta.Proc[src].CacheState = CACHE_E
==>
begin
  Sta.Proc[src].CacheData := data;
  Sta.CurrData := data;
endrule;
endruleset;

ruleset  h : NODE; d : DATA do
startstate
  undefine Sta;
  Sta.MemData := d;
  Sta.Dir.Pending := false;
  Sta.Dir.Local := false;
  Sta.Dir.Dirty := false;
  Sta.Dir.HeadVld := false;
  Sta.Dir.HeadPtr := h;
  Sta.Dir.HomeHeadPtr := true;
  Sta.Dir.ShrVld := false;
  Sta.WbMsg.Cmd := WB_None;
  Sta.WbMsg.Proc := h;
  Sta.WbMsg.HomeProc := true;
  Sta.WbMsg.Data := d;
  Sta.ShWbMsg.Cmd := SHWB_None;
  Sta.ShWbMsg.Proc := h;
  Sta.ShWbMsg.HomeProc := true;
  Sta.ShWbMsg.Data := d;
  Sta.NakcMsg.Cmd := NAKC_None;
  for p : NODE do
    Sta.Proc[p].ProcCmd := NODE_None;
    Sta.Proc[p].InvMarked := false;
    Sta.Proc[p].CacheState := CACHE_I;
    Sta.Proc[p].CacheData := d;
    Sta.Dir.ShrSet[p] := false;
    Sta.Dir.InvSet[p] := false;
    Sta.UniMsg[p].Cmd := UNI_None;
    Sta.UniMsg[p].Proc := h;
    Sta.UniMsg[p].HomeProc := true;
    Sta.UniMsg[p].Data := d;
    Sta.InvMsg[p].Cmd := INV_None;
    Sta.RpMsg[p].Cmd := RP_None;
  end;
  Sta.HomeProc.ProcCmd := NODE_None;
  Sta.HomeProc.InvMarked := false;
  Sta.HomeProc.CacheState := CACHE_I;
  undefine Sta.HomeProc.CacheData;
  Sta.HomeProc.CacheData := d;
  Sta.Dir.HomeShrSet := false;
  Sta.Dir.HomeInvSet := false;
  Sta.HomeUniMsg.Cmd := UNI_None;
  Sta.HomeUniMsg.Proc := h;
  Sta.HomeUniMsg.HomeProc := true;
  Sta.HomeUniMsg.Data := d;
  Sta.HomeInvMsg.Cmd := INV_None;
  Sta.HomeRpMsg.Cmd := RP_None;
  Sta.CurrData := d;
endstartstate;
endruleset;
invariant "CacheStateProp"
  forall p : NODE do
    forall q : NODE do
      (p != q ->
      !(Sta.Proc[p].CacheState = CACHE_E &
      Sta.Proc[q].CacheState = CACHE_E))
    end
  end;

invariant "CacheStatePropHome"
  forall p : NODE do
    !(Sta.Proc[p].CacheState = CACHE_E &
    Sta.HomeProc.CacheState = CACHE_E)
  end;

invariant "DataProp"
  forall p : NODE do
    (Sta.Proc[p].CacheState = CACHE_E ->
    Sta.Proc[p].CacheData = Sta.CurrData)
  end;

invariant "MemDataProp"
  (Sta.Dir.Dirty = false ->
  Sta.MemData = Sta.CurrData);


ruleset i : NODE ; j : NODE do
Invariant "rule_1"
		(i != j) ->	(Sta.UniMsg[i].Proc = j -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_2"
	(Sta.Dir.Pending = false -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_3"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_4"
	(Sta.Dir.ShrVld = true -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_5"
	(Sta.Dir.HeadVld = true -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_6"
		(j != i) ->	(Sta.Dir.InvSet[j] = true -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_7"
	(Sta.Dir.ShrSet[i] = true -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_8"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_9"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_11"
	(Sta.Dir.Local = false -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_12"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_13"
	(Sta.Dir.InvSet[i] = false -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_14"
	(Sta.Dir.HeadPtr != i -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_15"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_16"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_18"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_E -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_20"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_21"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_22"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE do
Invariant "rule_23"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Dir.Pending = true);
endruleset;


ruleset i : NODE do
Invariant "rule_24"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset i : NODE do
Invariant "rule_25"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_26"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_27"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_28"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_29"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_30"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_31"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE do
Invariant "rule_32"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Dir.Local = true);
endruleset;


ruleset i : NODE do
Invariant "rule_33"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset i : NODE do
Invariant "rule_34"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Dir.InvSet[i] = true);
endruleset;


ruleset i : NODE do
Invariant "rule_35"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Dir.HeadPtr = i);
endruleset;


ruleset i : NODE do
Invariant "rule_36"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_37"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_38"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_39"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_40"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_41"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_42"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_43"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_46"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_48"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_50"
	(Sta.Proc[i].ProcCmd = NODE_None -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_52"
	(Sta.UniMsg[i].Data = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_53"
	(Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_56"
	(Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_58"
	(Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_60"
	(Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_63"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_S -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_70"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_E -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_74"
		(i != j) ->	(Sta.Proc[i].CacheState != CACHE_I -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_79"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_82"
		(i != j) ->	(Sta.UniMsg[i].Proc = j -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_89"
		(i != j) ->	(Sta.UniMsg[i].Proc = j -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_93"
		(i != j) ->	(Sta.UniMsg[i].Proc = j -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_98"
		(i != j) ->	(Sta.UniMsg[i].Proc = j -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_99"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_100"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_101"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_103"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_104"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_105"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_106"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.Proc[j].ProcCmd = NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_107"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_108"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_110"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_111"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_I -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_112"
	(Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_113"
	(Sta.Proc[j].ProcCmd = NODE_Get -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_114"
	(Sta.UniMsg[j].Cmd = UNI_Get -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_116"
	(Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_118"
	(Sta.Proc[j].InvMarked = true -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_119"
	(Sta.UniMsg[j].Cmd = UNI_Put -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_120"
	(Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_121"
	(Sta.Proc[j].ProcCmd != NODE_None -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_122"
	(Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_123"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_126"
		(j != i) ->	(Sta.UniMsg[j].Proc = i -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;
Invariant "rule_127"
	(Sta.Dir.ShrVld = true -> Sta.Dir.Pending = false);


ruleset i : NODE do
Invariant "rule_129"
	(Sta.Dir.ShrSet[i] = true -> Sta.Dir.Pending = false);
endruleset;
Invariant "rule_130"
	(Sta.Dir.Pending = false -> Sta.ShWbMsg.Cmd != SHWB_FAck);
Invariant "rule_132"
	(Sta.Dir.Pending = false -> Sta.ShWbMsg.Cmd != SHWB_ShWb);


ruleset j : NODE do
Invariant "rule_134"
	(Sta.Dir.Pending = false -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_136"
	(Sta.Dir.Pending = false -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_137"
	(Sta.Dir.ShrSet[j] = true -> Sta.Dir.Pending = false);
endruleset;
Invariant "rule_138"
	(Sta.Dir.Pending = false -> Sta.NakcMsg.Cmd != NAKC_Nakc);


ruleset i : NODE do
Invariant "rule_139"
	(Sta.Dir.Pending = false -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;
Invariant "rule_140"
	(Sta.Dir.Pending = true -> Sta.Dir.ShrVld = false);


ruleset i : NODE do
Invariant "rule_142"
	(Sta.Dir.Pending = true -> Sta.Dir.ShrSet[i] = false);
endruleset;
Invariant "rule_143"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.Pending = true);
Invariant "rule_145"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Dir.Pending = true);


ruleset j : NODE do
Invariant "rule_150"
	(Sta.Dir.Pending = true -> Sta.Dir.ShrSet[j] = false);
endruleset;
Invariant "rule_151"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Dir.Pending = true);


ruleset i : NODE do
Invariant "rule_152"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Dir.Pending = true);
endruleset;
Invariant "rule_153"
	(Sta.Dir.ShrVld = true -> Sta.WbMsg.Cmd != WB_Wb);
Invariant "rule_156"
	(Sta.Dir.HeadVld = false -> Sta.WbMsg.Cmd != WB_Wb);


ruleset j : NODE do
Invariant "rule_157"
	(Sta.Dir.InvSet[j] = true -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset i : NODE do
Invariant "rule_158"
	(Sta.Dir.ShrSet[i] = true -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset i : NODE do
Invariant "rule_159"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;
Invariant "rule_161"
	(Sta.Dir.Local = true -> Sta.WbMsg.Cmd != WB_Wb);
Invariant "rule_162"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.WbMsg.Cmd != WB_Wb);


ruleset i : NODE do
Invariant "rule_163"
	(Sta.Dir.InvSet[i] = true -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;
Invariant "rule_165"
	(Sta.WbMsg.Data != Sta.CurrData -> Sta.WbMsg.Cmd != WB_Wb);


ruleset i : NODE do
Invariant "rule_166"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset j : NODE do
Invariant "rule_167"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;
Invariant "rule_168"
	(Sta.Dir.Dirty = false -> Sta.WbMsg.Cmd != WB_Wb);


ruleset j : NODE do
Invariant "rule_172"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset j : NODE do
Invariant "rule_178"
	(Sta.Dir.ShrSet[j] = true -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset i : NODE do
Invariant "rule_179"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;
Invariant "rule_180"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.Dir.ShrVld = false);
Invariant "rule_183"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.Dir.HeadVld = true);


ruleset j : NODE do
Invariant "rule_184"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_185"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_186"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;
Invariant "rule_188"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.Dir.Local = false);
Invariant "rule_189"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.ShWbMsg.Cmd != SHWB_ShWb);


ruleset i : NODE do
Invariant "rule_190"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.Dir.InvSet[i] = false);
endruleset;
Invariant "rule_192"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.WbMsg.Data = Sta.CurrData);


ruleset i : NODE do
Invariant "rule_193"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_194"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;
Invariant "rule_195"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.Dir.Dirty = true);


ruleset j : NODE do
Invariant "rule_196"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_197"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_199"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_201"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_202"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_203"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_204"
	(Sta.UniMsg[j].Cmd = UNI_Get -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_207"
	(Sta.Proc[j].InvMarked = true -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_208"
	(Sta.UniMsg[j].Cmd = UNI_Put -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_209"
	(Sta.Proc[j].ProcCmd != NODE_GetX -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_210"
	(Sta.Proc[j].ProcCmd != NODE_GetX -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_212"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_214"
	(Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_215"
	(Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_217"
	(Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_218"
	(Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_219"
	(Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.Proc[j].ProcCmd = NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_220"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Proc[j].ProcCmd = NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_222"
	(Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;
Invariant "rule_224"
	(Sta.Dir.HeadVld = false -> Sta.Dir.ShrVld = false);


ruleset i : NODE do
Invariant "rule_226"
	(Sta.Dir.ShrVld = false -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_227"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Dir.ShrVld = false);
endruleset;
Invariant "rule_228"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.ShrVld = false);
Invariant "rule_230"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Dir.ShrVld = false);


ruleset i : NODE do
Invariant "rule_232"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Dir.ShrVld = false);
endruleset;


ruleset j : NODE do
Invariant "rule_233"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Dir.ShrVld = false);
endruleset;
Invariant "rule_234"
	(Sta.Dir.Dirty = true -> Sta.Dir.ShrVld = false);
Invariant "rule_235"
	(Sta.MemData != Sta.CurrData -> Sta.Dir.ShrVld = false);


ruleset j : NODE do
Invariant "rule_237"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Dir.ShrVld = false);
endruleset;


ruleset j : NODE do
Invariant "rule_240"
	(Sta.Dir.ShrVld = false -> Sta.Dir.ShrSet[j] = false);
endruleset;
Invariant "rule_241"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Dir.ShrVld = false);


ruleset i : NODE do
Invariant "rule_242"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Dir.ShrVld = false);
endruleset;
Invariant "rule_243"
	(Sta.Dir.ShrVld = true -> Sta.Dir.HeadVld = true);


ruleset i : NODE do
Invariant "rule_245"
	(Sta.Dir.ShrSet[i] = true -> Sta.Dir.ShrVld = true);
endruleset;


ruleset i : NODE do
Invariant "rule_246"
	(Sta.Dir.ShrVld = true -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;
Invariant "rule_247"
	(Sta.Dir.ShrVld = true -> Sta.ShWbMsg.Cmd != SHWB_FAck);
Invariant "rule_249"
	(Sta.Dir.ShrVld = true -> Sta.ShWbMsg.Cmd != SHWB_ShWb);


ruleset i : NODE do
Invariant "rule_251"
	(Sta.Dir.ShrVld = true -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_252"
	(Sta.Dir.ShrVld = true -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;
Invariant "rule_253"
	(Sta.Dir.ShrVld = true -> Sta.Dir.Dirty = false);
Invariant "rule_254"
	(Sta.Dir.ShrVld = true -> Sta.MemData = Sta.CurrData);


ruleset j : NODE do
Invariant "rule_255"
	(Sta.Dir.ShrVld = true -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_256"
	(Sta.Dir.ShrVld = true -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_257"
	(Sta.Dir.ShrVld = true -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_258"
	(Sta.Dir.ShrSet[j] = true -> Sta.Dir.ShrVld = true);
endruleset;
Invariant "rule_259"
	(Sta.Dir.ShrVld = true -> Sta.NakcMsg.Cmd != NAKC_Nakc);


ruleset i : NODE do
Invariant "rule_260"
	(Sta.Dir.ShrVld = true -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_261"
	(Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_262"
	(Sta.Proc[i].InvMarked = true -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_263"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_264"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_266"
	(Sta.UniMsg[i].Cmd = UNI_Get -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_267"
	(Sta.Proc[i].ProcCmd = NODE_Get -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_272"
	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_273"
	(Sta.Proc[i].ProcCmd != NODE_None -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_275"
	(Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_276"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_277"
	(Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_278"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_279"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_280"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_281"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset i : NODE do
Invariant "rule_283"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_284"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_289"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_290"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.Proc[i].ProcCmd = NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_291"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_292"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_293"
	(Sta.Proc[i].InvMarked = true -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_294"
	(Sta.Proc[i].ProcCmd != NODE_GetX -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_296"
	(Sta.UniMsg[i].Cmd = UNI_Get -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_297"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_299"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_301"
	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_303"
	(Sta.Proc[i].ProcCmd != NODE_GetX -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_304"
	(Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_305"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Proc[i].ProcCmd = NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_307"
	(Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_308"
	(Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_310"
	(Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_312"
	(Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_313"
	(Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Proc[i].ProcCmd = NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_315"
	(Sta.Proc[i].InvMarked = true -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_316"
	(Sta.Proc[i].InvMarked = true -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset i : NODE do
Invariant "rule_319"
	(Sta.Proc[i].InvMarked = true -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_320"
	(Sta.Proc[i].InvMarked = true -> Sta.Proc[i].ProcCmd = NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_324"
	(Sta.Proc[i].InvMarked = true -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_326"
	(Sta.Proc[i].InvMarked = true -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_327"
	(Sta.Proc[i].InvMarked = true -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_329"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_330"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_333"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_334"
	(Sta.Proc[i].ProcCmd != NODE_Get -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_337"
	(Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_340"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_342"
	(Sta.Proc[i].ProcCmd = NODE_None -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_343"
	(Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_345"
	(Sta.Dir.HeadVld = false -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_346"
	(Sta.Dir.HeadVld = false -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;
Invariant "rule_348"
	(Sta.Dir.HeadVld = false -> Sta.ShWbMsg.Cmd != SHWB_ShWb);


ruleset i : NODE do
Invariant "rule_350"
	(Sta.Dir.HeadVld = false -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_351"
	(Sta.Dir.HeadVld = false -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_353"
	(Sta.Dir.HeadVld = false -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_356"
	(Sta.Dir.HeadVld = false -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_357"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_359"
	(Sta.Dir.ShrSet[i] = true -> Sta.Dir.HeadVld = true);
endruleset;


ruleset i : NODE do
Invariant "rule_360"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Dir.HeadVld = true);
endruleset;
Invariant "rule_362"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Dir.HeadVld = true);


ruleset i : NODE do
Invariant "rule_364"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Dir.HeadVld = true);
endruleset;


ruleset j : NODE do
Invariant "rule_365"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Dir.HeadVld = true);
endruleset;


ruleset j : NODE do
Invariant "rule_366"
	(Sta.Dir.HeadVld = true -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_367"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Dir.HeadVld = true);
endruleset;


ruleset j : NODE do
Invariant "rule_368"
	(Sta.Dir.HeadVld = true -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_369"
	(Sta.Dir.ShrSet[j] = true -> Sta.Dir.HeadVld = true);
endruleset;


ruleset i : NODE do
Invariant "rule_370"
	(Sta.Dir.HeadVld = true -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_371"
	(Sta.Proc[j].ProcCmd = NODE_Get -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_372"
	(Sta.UniMsg[j].Cmd = UNI_Get -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_373"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_375"
	(Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_377"
	(Sta.Proc[j].InvMarked = true -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_378"
	(Sta.UniMsg[j].Cmd = UNI_Put -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_379"
	(Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_380"
	(Sta.Proc[j].ProcCmd != NODE_None -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_381"
	(Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_382"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_385"
		(j != i) ->	(Sta.UniMsg[j].Proc = i -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_386"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_387"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_388"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_390"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_391"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_392"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_393"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.Proc[j].ProcCmd = NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_394"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_395"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_397"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_398"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_399"
		(j != i) ->	(Sta.Dir.InvSet[j] = true -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_400"
	(Sta.Dir.InvSet[j] = true -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_402"
	(Sta.Dir.InvSet[j] = true -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_404"
		(j != i) ->	(Sta.Dir.InvSet[j] = true -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_405"
	(Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_409"
	(Sta.Dir.InvSet[j] = true -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_411"
	(Sta.Dir.ShrSet[j] = true -> Sta.Dir.InvSet[j] = true);
endruleset;


ruleset j : NODE do
Invariant "rule_413"
	(Sta.Dir.InvSet[j] = true -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_414"
		(j != i) ->	(Sta.Dir.InvSet[j] = true -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_415"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_416"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_419"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_421"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_422"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_425"
	(Sta.Dir.InvSet[j] = false -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_426"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_427"
	(Sta.Dir.InvSet[j] = false -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_430"
	(Sta.Dir.InvSet[j] = false -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_431"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_432"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_433"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_434"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_436"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_437"
	(Sta.Dir.InvSet[i] = false -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_439"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_440"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_441"
	(Sta.Dir.Dirty = true -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_442"
	(Sta.MemData != Sta.CurrData -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_445"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_448"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_449"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_450"
	(Sta.Dir.ShrSet[i] = true -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_451"
	(Sta.Dir.ShrSet[i] = true -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset i : NODE do
Invariant "rule_453"
	(Sta.Dir.ShrSet[i] = true -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset i : NODE do
Invariant "rule_454"
	(Sta.Dir.ShrSet[i] = true -> Sta.Dir.InvSet[i] = true);
endruleset;


ruleset i : NODE do
Invariant "rule_456"
	(Sta.Dir.ShrSet[i] = true -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_457"
		(i != j) ->	(Sta.Dir.ShrSet[i] = true -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_458"
	(Sta.Dir.ShrSet[i] = true -> Sta.Dir.Dirty = false);
endruleset;


ruleset i : NODE do
Invariant "rule_459"
	(Sta.Dir.ShrSet[i] = true -> Sta.MemData = Sta.CurrData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_460"
		(i != j) ->	(Sta.Dir.ShrSet[i] = true -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_461"
		(i != j) ->	(Sta.Dir.ShrSet[i] = true -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_462"
		(i != j) ->	(Sta.Dir.ShrSet[i] = true -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_463"
	(Sta.Dir.ShrSet[i] = true -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_464"
	(Sta.Dir.ShrSet[i] = true -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_467"
	(Sta.Dir.Local = true -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_468"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_469"
	(Sta.Dir.InvSet[i] = true -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_471"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_472"
	(Sta.Proc[i].ProcCmd = NODE_Get -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_473"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_474"
	(Sta.Dir.Dirty = false -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_476"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_E -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_477"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_479"
	(Sta.Proc[i].ProcCmd = NODE_None -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_480"
	(Sta.UniMsg[i].Data != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_481"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_482"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_485"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Dir.Local = false);
endruleset;


ruleset i : NODE do
Invariant "rule_486"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset i : NODE do
Invariant "rule_487"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_489"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_490"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_491"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_492"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Dir.Dirty = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_493"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_494"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_495"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_496"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_497"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_498"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.UniMsg[i].Data = Sta.CurrData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_499"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_500"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;
Invariant "rule_503"
	(Sta.ShWbMsg.Data != Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
Invariant "rule_508"
	(Sta.ShWbMsg.Data = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
Invariant "rule_510"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.ShWbMsg.Data = Sta.CurrData);


ruleset j : NODE do
Invariant "rule_515"
	(Sta.Proc[j].ProcCmd != NODE_Get -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_517"
	(Sta.Proc[j].ProcCmd != NODE_Get -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_518"
	(Sta.Proc[j].ProcCmd != NODE_Get -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_519"
	(Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_520"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_522"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_524"
	(Sta.UniMsg[j].Cmd = UNI_Get -> Sta.Proc[j].ProcCmd = NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_526"
	(Sta.Proc[j].InvMarked = true -> Sta.Proc[j].ProcCmd = NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_527"
	(Sta.UniMsg[j].Cmd = UNI_Put -> Sta.Proc[j].ProcCmd = NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_528"
	(Sta.Proc[j].ProcCmd = NODE_Get -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_529"
	(Sta.Proc[j].ProcCmd = NODE_Get -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_531"
	(Sta.Proc[j].ProcCmd = NODE_Get -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_534"
	(Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_536"
	(Sta.Proc[j].ProcCmd = NODE_None -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_538"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_541"
	(Sta.UniMsg[j].Cmd = UNI_Get -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_543"
	(Sta.UniMsg[j].Cmd = UNI_Get -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;
Invariant "rule_547"
	(Sta.Dir.Local = true -> Sta.ShWbMsg.Cmd != SHWB_FAck);


ruleset j : NODE do
Invariant "rule_548"
	(Sta.Proc[j].InvMarked = true -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset i : NODE do
Invariant "rule_549"
	(Sta.Dir.InvSet[i] = true -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_550"
	(Sta.UniMsg[j].Cmd = UNI_Put -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset i : NODE do
Invariant "rule_559"
	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_562"
	(Sta.Dir.ShrSet[j] = true -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;
Invariant "rule_563"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.ShWbMsg.Cmd != SHWB_FAck);


ruleset i : NODE do
Invariant "rule_564"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;
Invariant "rule_566"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.Local = false);


ruleset j : NODE do
Invariant "rule_567"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_568"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_569"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_572"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_575"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_576"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_577"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.ShrSet[j] = false);
endruleset;
Invariant "rule_578"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.NakcMsg.Cmd != NAKC_Nakc);


ruleset i : NODE do
Invariant "rule_579"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_621"
	(Sta.Dir.HeadPtr != j -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_629"
	(Sta.Dir.HeadPtr != j -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_645"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_648"
	(Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_649"
	(Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_650"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.UniMsg[j].Data = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_652"
	(Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_657"
	(Sta.UniMsg[j].Data != Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;
Invariant "rule_663"
	(Sta.Dir.Local = true -> Sta.ShWbMsg.Cmd != SHWB_ShWb);


ruleset i : NODE do
Invariant "rule_664"
	(Sta.Dir.Local = true -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_665"
	(Sta.Dir.Local = true -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_667"
	(Sta.Dir.Local = true -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;
Invariant "rule_669"
	(Sta.Dir.Local = true -> Sta.NakcMsg.Cmd != NAKC_Nakc);


ruleset i : NODE do
Invariant "rule_670"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Dir.Local = true);
endruleset;
Invariant "rule_671"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Dir.Local = false);


ruleset i : NODE do
Invariant "rule_672"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Dir.Local = false);
endruleset;


ruleset j : NODE do
Invariant "rule_673"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Dir.Local = false);
endruleset;


ruleset j : NODE do
Invariant "rule_674"
	(Sta.Dir.Local = false -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_675"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Dir.Local = false);
endruleset;


ruleset j : NODE do
Invariant "rule_676"
	(Sta.Dir.Local = false -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;
Invariant "rule_677"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Dir.Local = false);


ruleset i : NODE do
Invariant "rule_678"
	(Sta.Dir.Local = false -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_679"
	(Sta.Proc[j].InvMarked = true -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_680"
	(Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_681"
	(Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_683"
	(Sta.Proc[j].InvMarked = true -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_685"
	(Sta.Proc[j].ProcCmd = NODE_None -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_687"
	(Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_688"
	(Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_689"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_691"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_693"
	(Sta.Dir.InvSet[i] = true -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset i : NODE do
Invariant "rule_695"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_696"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;
Invariant "rule_697"
	(Sta.Dir.Dirty = false -> Sta.ShWbMsg.Cmd != SHWB_ShWb);


ruleset j : NODE do
Invariant "rule_700"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_706"
	(Sta.Dir.ShrSet[j] = true -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;
Invariant "rule_707"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.ShWbMsg.Cmd != SHWB_ShWb);


ruleset i : NODE do
Invariant "rule_709"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset i : NODE do
Invariant "rule_710"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_712"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_713"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;
Invariant "rule_714"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Dir.Dirty = true);


ruleset j : NODE do
Invariant "rule_715"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_716"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_718"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_720"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Dir.ShrSet[j] = false);
endruleset;
Invariant "rule_721"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.NakcMsg.Cmd != NAKC_Nakc);


ruleset i : NODE do
Invariant "rule_723"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_725"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_726"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_728"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_730"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_731"
	(Sta.Dir.InvSet[i] = false -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_733"
	(Sta.Dir.InvSet[i] = true -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_734"
		(i != j) ->	(Sta.Dir.InvSet[i] = true -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_735"
		(i != j) ->	(Sta.Dir.InvSet[i] = true -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_736"
		(i != j) ->	(Sta.Dir.InvSet[i] = true -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_737"
		(i != j) ->	(Sta.Dir.InvSet[i] = true -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_738"
	(Sta.Dir.InvSet[i] = true -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_739"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Dir.InvSet[i] = true);
endruleset;


ruleset j : NODE do
Invariant "rule_740"
	(Sta.Proc[j].ProcCmd = NODE_None -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_741"
	(Sta.RpMsg[j].Cmd = RP_Replace -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_743"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_745"
	(Sta.UniMsg[j].Cmd = UNI_Put -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_746"
	(Sta.UniMsg[j].Cmd = UNI_Put -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_748"
	(Sta.UniMsg[j].Cmd = UNI_Put -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_750"
	(Sta.Proc[j].ProcCmd = NODE_None -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_752"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_754"
	(Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_756"
	(Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_765"
	(Sta.Dir.HeadPtr != i -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_768"
		(i != j) ->	(Sta.Dir.HeadPtr = i -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_770"
		(i != j) ->	(Sta.Dir.HeadPtr = i -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_773"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Dir.HeadPtr = i);
endruleset;


ruleset i : NODE do
Invariant "rule_774"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_775"
	(Sta.Proc[i].ProcCmd != NODE_Get -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_777"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_779"
	(Sta.Proc[i].ProcCmd = NODE_None -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_781"
	(Sta.UniMsg[i].Data = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_782"
	(Sta.UniMsg[i].Cmd = UNI_Get -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_783"
	(Sta.UniMsg[i].Cmd = UNI_Get -> Sta.Proc[i].ProcCmd = NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_785"
	(Sta.UniMsg[i].Cmd = UNI_Get -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_787"
	(Sta.UniMsg[i].Cmd = UNI_Get -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_794"
	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_798"
	(Sta.RpMsg[i].Cmd = RP_Replace -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_799"
	(Sta.Proc[i].ProcCmd = NODE_Get -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_800"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_801"
	(Sta.Dir.Dirty = false -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_802"
	(Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_804"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_806"
	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_807"
	(Sta.Proc[i].ProcCmd != NODE_None -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_809"
	(Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_810"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_811"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_812"
	(Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_813"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_814"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_E -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_815"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Dir.Dirty = true);
endruleset;


ruleset i : NODE do
Invariant "rule_816"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Proc[i].CacheData = Sta.CurrData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_817"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_E -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_818"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_819"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_E -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_820"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_821"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Proc[i].ProcCmd = NODE_None);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_822"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_823"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_824"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_826"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_828"
	(Sta.Proc[i].ProcCmd != NODE_Get -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_829"
	(Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_831"
	(Sta.Proc[i].ProcCmd = NODE_Get -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_833"
	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.Proc[i].ProcCmd = NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_834"
	(Sta.Proc[i].ProcCmd = NODE_Get -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_835"
	(Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_836"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_838"
	(Sta.Proc[j].ProcCmd != NODE_None -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_840"
	(Sta.Proc[j].ProcCmd = NODE_None -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_841"
	(Sta.Proc[j].ProcCmd = NODE_None -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_843"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Proc[j].ProcCmd = NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_846"
	(Sta.Proc[j].CacheData != Sta.CurrData -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_849"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Proc[j].CacheData = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_850"
	(Sta.Proc[j].CacheData = Sta.CurrData -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_852"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_855"
	(Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_857"
	(Sta.Dir.Dirty = false -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_861"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_868"
	(Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_872"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_873"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Dir.Dirty = true);
endruleset;


ruleset j : NODE do
Invariant "rule_874"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_875"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_878"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_880"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_884"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;
Invariant "rule_885"
	(Sta.MemData != Sta.CurrData -> Sta.Dir.Dirty = true);


ruleset j : NODE do
Invariant "rule_887"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Dir.Dirty = true);
endruleset;


ruleset j : NODE do
Invariant "rule_889"
	(Sta.Dir.Dirty = true -> Sta.Dir.ShrSet[j] = false);
endruleset;
Invariant "rule_890"
	(Sta.Dir.Dirty = false -> Sta.MemData = Sta.CurrData);


ruleset j : NODE do
Invariant "rule_892"
	(Sta.Dir.Dirty = false -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_894"
	(Sta.Dir.ShrSet[j] = true -> Sta.Dir.Dirty = false);
endruleset;


ruleset j : NODE do
Invariant "rule_897"
	(Sta.MemData != Sta.CurrData -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_900"
	(Sta.Dir.ShrSet[j] = true -> Sta.MemData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_908"
	(Sta.Proc[i].CacheData = Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_914"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_925"
	(Sta.Dir.ShrSet[j] = true -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_928"
		(j != i) ->	(Sta.UniMsg[j].Proc = i -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_930"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_934"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_943"
	(Sta.Dir.ShrSet[j] = true -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_944"
		(j != i) ->	(Sta.UniMsg[j].Proc = i -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_947"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_950"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_952"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_953"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_E -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_956"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_E -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_960"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_961"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.Proc[i].ProcCmd = NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_962"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_963"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_965"
	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_966"
	(Sta.Proc[i].ProcCmd != NODE_None -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_968"
	(Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_969"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_970"
	(Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_977"
	(Sta.Dir.ShrSet[j] = true -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_980"
		(j != i) ->	(Sta.UniMsg[j].Proc = i -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_982"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_986"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_989"
	(Sta.Proc[i].ProcCmd = NODE_None -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_990"
	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_991"
	(Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_992"
	(Sta.Proc[i].ProcCmd = NODE_None -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_995"
	(Sta.UniMsg[i].Data = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_996"
	(Sta.Dir.ShrSet[j] = true -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_997"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_998"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_999"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1000"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_1001"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_1002"
	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_1004"
	(Sta.UniMsg[i].Cmd = UNI_Nak & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1005"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_S & Sta.Proc[j].CacheState != CACHE_I -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1006"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_I & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1007"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_1008"
	(Sta.Proc[i].CacheState != CACHE_S & Sta.Proc[i].CacheState != CACHE_I -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_1010"
	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_1011"
	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_1012"
	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[i].Cmd = UNI_Get -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_1013"
	(Sta.Proc[i].InvMarked = true & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_1014"
	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[i].Cmd != UNI_Put -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1015"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1018"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1019"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_1022"
	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_1023"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_1025"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd != NODE_Get -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1027"
		(j != i) ->	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1028"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.UniMsg[j].Proc = i -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_1029"
	(Sta.MemData != Sta.CurrData & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_1031"
	(Sta.UniMsg[i].Cmd = UNI_GetX & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_1033"
	(Sta.UniMsg[i].Cmd != UNI_Put & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_1035"
	(Sta.Proc[i].ProcCmd = NODE_None & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_1036"
	(Sta.Proc[i].InvMarked = true & Sta.InvMsg[i].Cmd = INV_Inv -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_1038"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_1039"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1040"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.Proc[j].CacheState != CACHE_I -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1041"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1042"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_1044"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_1045"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_1046"
	(Sta.Proc[i].InvMarked = true & Sta.InvMsg[i].Cmd = INV_Inv -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_1047"
	(Sta.Proc[i].InvMarked = true & Sta.InvMsg[i].Cmd = INV_Inv -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_1048"
	(Sta.Proc[i].InvMarked = true & Sta.InvMsg[i].Cmd = INV_Inv -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_1049"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[i].Cmd = UNI_Get -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1050"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1051"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[i].Cmd != UNI_Put -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1052"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1053"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.Proc[j].CacheState = CACHE_S -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1054"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1055"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1056"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_1059"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_1060"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_1062"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd = NODE_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1064"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1065"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1066"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE do
Invariant "rule_1067"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.MemData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_1069"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_1071"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_1073"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1075"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_1083"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].ProcCmd != NODE_GetX -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_1084"
	(Sta.Proc[i].ProcCmd != NODE_GetX & Sta.Proc[i].ProcCmd != NODE_Get -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_1087"
	(Sta.Proc[i].InvMarked = true & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_1095"
	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_1098"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_1100"
	(Sta.Dir.InvSet[i] = true & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_1103"
	(Sta.Dir.HeadPtr = i & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_1107"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].ProcCmd = NODE_Get -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_1109"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1116"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1119"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1122"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE do
Invariant "rule_1133"
	(Sta.Proc[i].ProcCmd != NODE_GetX & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_1134"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Proc[i].ProcCmd = NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_1137"
	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_1141"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1152"
	(Sta.UniMsg[i].Cmd = UNI_Nak & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.ShWbMsg.Data = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_1155"
	(Sta.UniMsg[i].Cmd = UNI_Nak & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset i : NODE do
Invariant "rule_1157"
	(Sta.UniMsg[i].Cmd = UNI_Nak & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1161"
	(Sta.UniMsg[i].Cmd = UNI_Nak & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE do
Invariant "rule_1163"
	(Sta.UniMsg[i].Cmd = UNI_Nak & Sta.Proc[i].ProcCmd = NODE_Get -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_1165"
	(Sta.UniMsg[i].Cmd = UNI_Nak & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_1166"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1173"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Nak & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1178"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_I & Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1180"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.Proc[j].CacheState != CACHE_I -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1191"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Dir.Pending = false -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1194"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_GetX & Sta.Dir.Pending = false -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1199"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.Proc[i].ProcCmd != NODE_GetX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1200"
		(i != j) ->	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].ProcCmd != NODE_GetX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1204"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.Proc[i].InvMarked = true -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1205"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1206"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1207"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.Dir.HeadVld = false -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1208"
		(j != i) ->	(Sta.Dir.HeadVld = false & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1228"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S & Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1230"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.Proc[j].CacheState = CACHE_S -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1231"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Proc[j].CacheState = CACHE_S -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1232"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1233"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1234"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[i].Cmd != UNI_PutX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1237"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX & Sta.ShWbMsg.Data = Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1238"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1240"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1241"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1243"
		(j != i) ->	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1253"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.ShWbMsg.Data = Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1260"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Data = Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1270"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1290"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.Dir.Local = true -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1291"
		(i != j) ->	(Sta.Dir.Local = true & Sta.UniMsg[i].Cmd = UNI_Get -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1292"
		(j != i) ->	(Sta.Dir.Local = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1293"
		(i != j) ->	(Sta.Dir.Local = true & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1300"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1301"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1303"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1304"
		(j != i) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1305"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_GetX & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1306"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1307"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1310"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1311"
		(j != i) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1312"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_GetX & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1314"
		(j != i) ->	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1316"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[i].Cmd = UNI_Get -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1317"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.Proc[i].ProcCmd = NODE_Get -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1319"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1320"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.Dir.Dirty = false -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1321"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.ShWbMsg.Proc = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1322"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[i].Cmd = UNI_Put -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1323"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1324"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1327"
		(i != j) ->	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Cmd = UNI_Get -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1333"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1338"
		(i != j) ->	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].ProcCmd = NODE_Get -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1340"
		(i != j) ->	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1345"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Proc[j].ProcCmd = NODE_None -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1356"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Dir.Dirty = false -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1361"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Proc = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1363"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.UniMsg[i].Cmd = UNI_Put -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1366"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_GetX & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1369"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_I & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1371"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_I & Sta.UniMsg[i].Proc = j -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1379"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX & Sta.UniMsg[i].Proc = j -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1381"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[i].Proc = j -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1388"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.Pending = false -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1389"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.Pending = false -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1395"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.UniMsg[i].Proc = j -> Sta.Dir.Pending = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1398"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_GetX & Sta.UniMsg[i].Proc = j -> Sta.Dir.Pending = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1403"
		(i != j) ->	(Sta.Proc[i].ProcCmd != NODE_GetX & Sta.UniMsg[i].Proc = j -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1404"
		(i != j) ->	(Sta.Proc[i].ProcCmd != NODE_GetX & Sta.UniMsg[i].Proc = j -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1407"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[i].Proc = j -> Sta.Proc[i].ProcCmd = NODE_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1408"
		(i != j) ->	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Proc = j -> Sta.Proc[i].ProcCmd = NODE_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1411"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[i].Proc = j -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1412"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[i].Proc = j -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1413"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1415"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[i].Proc = j -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1416"
		(i != j) ->	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Proc = j -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1417"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.UniMsg[i].Proc = j -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1427"
		(i != j) ->	(Sta.Dir.HeadVld = false & Sta.UniMsg[i].Proc = j -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1435"
		(i != j) ->	(Sta.Dir.HeadVld = false & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1442"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[i].Proc = j -> Sta.Dir.HeadVld = true);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1449"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.UniMsg[i].Proc = j -> Sta.Dir.HeadVld = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1451"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX & Sta.UniMsg[i].Proc = j -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1453"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[i].Proc = j -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1454"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.UniMsg[i].Proc = j -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1455"
		(i != j) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[i].Proc = j -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1456"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_GetX & Sta.UniMsg[i].Proc = j -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1457"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1459"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S & Sta.UniMsg[i].Proc = j -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1460"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1463"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S & Sta.UniMsg[i].Proc = j -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1464"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1466"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.ShWbMsg.Data = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1467"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1469"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1470"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Put & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1471"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd != UNI_PutX -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1473"
		(j != i) ->	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1476"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX & Sta.UniMsg[i].Proc = j -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1477"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1478"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Cmd = UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1485"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.ShWbMsg.Data = Sta.CurrData -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1488"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.ShWbMsg.Data = Sta.CurrData -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1499"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1517"
		(i != j) ->	(Sta.Dir.Local = true & Sta.UniMsg[i].Proc = j -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1518"
		(i != j) ->	(Sta.Dir.Local = true & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1521"
		(i != j) ->	(Sta.Dir.Local = true & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1522"
		(i != j) ->	(Sta.Dir.Local = true & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1525"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[i].Proc = j -> Sta.Dir.Local = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1526"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.UniMsg[i].Proc = j -> Sta.Dir.Local = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1527"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.UniMsg[i].Proc = j -> Sta.Dir.Local = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1528"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_GetX & Sta.UniMsg[i].Proc = j -> Sta.Dir.Local = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1531"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].InvMarked = true -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1532"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1534"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1535"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].InvMarked = true -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1536"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1539"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[i].Proc = j -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1540"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.UniMsg[i].Proc = j -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1542"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.UniMsg[i].Proc = j -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1543"
		(i != j) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[i].Proc = j -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1544"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_GetX & Sta.UniMsg[i].Proc = j -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1545"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1546"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1549"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1550"
		(i != j) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1551"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_GetX & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1552"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Put & Sta.UniMsg[i].Proc = j -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1553"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Put & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1554"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Put & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1555"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Put & Sta.UniMsg[i].Proc = j -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1556"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Put & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1558"
		(j != i) ->	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1559"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.UniMsg[i].Proc = j -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1560"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[i].ProcCmd = NODE_Get -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1562"
		(j != i) ->	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[i].Proc = j -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1563"
		(i != j) ->	(Sta.Dir.Dirty = false & Sta.UniMsg[i].Proc = j -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1564"
		(i != j) ->	(Sta.ShWbMsg.Proc = i & Sta.UniMsg[i].Proc = j -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1565"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.UniMsg[i].Proc = j -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1566"
		(i != j) ->	(Sta.UniMsg[i].Data != Sta.CurrData & Sta.UniMsg[i].Proc = j -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1568"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_GetX & Sta.UniMsg[i].Proc = j -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1569"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1570"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[i].Proc = j -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1571"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[i].Proc = j -> Sta.Dir.Dirty = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1572"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[i].Proc = j -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1573"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1574"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Data = Sta.CurrData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1576"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1579"
		(i != j) ->	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1585"
		(i != j) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1586"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.UniMsg[i].Proc = j -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1590"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.UniMsg[i].Proc = j -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1593"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[i].ProcCmd = NODE_Get -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1595"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1596"
		(i != j) ->	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Proc = j -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1600"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.UniMsg[i].Proc = j -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1603"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].ProcCmd = NODE_None -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1613"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.UniMsg[i].Proc = j -> Sta.Dir.Dirty = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1615"
		(i != j) ->	(Sta.Dir.Dirty = false & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1622"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.UniMsg[i].Proc = j -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1624"
		(i != j) ->	(Sta.ShWbMsg.Proc = i & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1625"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1627"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1632"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_GetX & Sta.UniMsg[i].Proc = j -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1633"
		(i != j) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_1637"
	(Sta.Proc[j].CacheState != CACHE_S & Sta.Proc[j].CacheState != CACHE_I -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset j : NODE do
Invariant "rule_1638"
	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.Proc[j].CacheState != CACHE_I -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset j : NODE do
Invariant "rule_1639"
	(Sta.WbMsg.Cmd = WB_Wb & Sta.Proc[j].CacheState != CACHE_I -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1640"
	(Sta.Proc[j].CacheState != CACHE_S & Sta.Proc[j].CacheState != CACHE_I -> Sta.Dir.ShrVld = false);
endruleset;


ruleset j : NODE do
Invariant "rule_1649"
	(Sta.Dir.HeadVld = false & Sta.Proc[j].CacheState != CACHE_I -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1650"
	(Sta.Proc[j].CacheState != CACHE_S & Sta.Proc[j].CacheState != CACHE_I -> Sta.Dir.HeadVld = true);
endruleset;


ruleset j : NODE do
Invariant "rule_1651"
	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.Proc[j].CacheState != CACHE_I -> Sta.Dir.HeadVld = true);
endruleset;


ruleset j : NODE do
Invariant "rule_1652"
	(Sta.Proc[j].CacheState != CACHE_S & Sta.Proc[j].CacheState != CACHE_I -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1653"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_S & Sta.Proc[j].CacheState != CACHE_I -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1654"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_S & Sta.Proc[j].CacheState != CACHE_I -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_1656"
	(Sta.Proc[j].CacheState != CACHE_S & Sta.Proc[j].CacheState != CACHE_I -> Sta.Dir.Local = false);
endruleset;


ruleset j : NODE do
Invariant "rule_1657"
	(Sta.Proc[j].CacheState != CACHE_S & Sta.Proc[j].CacheState != CACHE_I -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1658"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_S & Sta.Proc[j].CacheState != CACHE_I -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1660"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_S & Sta.Proc[j].CacheState != CACHE_I -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_1661"
	(Sta.Proc[j].CacheState != CACHE_S & Sta.Proc[j].CacheState != CACHE_I -> Sta.Proc[j].CacheData = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_1662"
	(Sta.Proc[j].CacheState != CACHE_S & Sta.Proc[j].CacheState != CACHE_I -> Sta.Dir.Dirty = true);
endruleset;


ruleset j : NODE do
Invariant "rule_1666"
	(Sta.Proc[j].CacheState != CACHE_S & Sta.Proc[j].CacheState != CACHE_I -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1669"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_S & Sta.Proc[j].CacheState != CACHE_I -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1677"
		(i != j) ->	(Sta.Dir.HeadPtr != i & Sta.Proc[j].CacheState != CACHE_I -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1678"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1679"
	(Sta.Dir.Dirty = false & Sta.Proc[j].CacheState != CACHE_I -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1680"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.Proc[j].CacheState != CACHE_E -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1681"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_I & Sta.ShWbMsg.Proc = i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1682"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.ShWbMsg.Proc != j -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1683"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.Proc[j].CacheState != CACHE_I -> Sta.Dir.HeadPtr = i);
endruleset;


ruleset j : NODE do
Invariant "rule_1684"
	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.Proc[j].CacheState != CACHE_I -> Sta.Proc[j].CacheData = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_1685"
	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.Proc[j].CacheState != CACHE_I -> Sta.Dir.Dirty = true);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1686"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.Proc[j].CacheState != CACHE_I -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_1687"
	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.Proc[j].CacheState != CACHE_I -> Sta.ShWbMsg.Proc = j);
endruleset;


ruleset j : NODE do
Invariant "rule_1688"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_1690"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[j].CacheData = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_1696"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_1697"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Proc[j].CacheState != CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_1698"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.Dir.ShrSet[j] = true -> Sta.Proc[j].CacheData = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_1700"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.Dir.ShrSet[j] = true -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1702"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck & Sta.Proc[j].CacheState != CACHE_I -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_1703"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1705"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_I & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1710"
	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.WbMsg.Cmd = WB_Wb -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_1714"
	(Sta.Dir.HeadVld = false & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1718"
		(i != j) ->	(Sta.Dir.HeadPtr != i & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_1719"
	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_1720"
	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.Dir.Dirty = false -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1721"
		(i != j) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.ShWbMsg.Proc = i -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_1722"
	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.ShWbMsg.Proc != j -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_1723"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_1727"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_1728"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Proc[j].CacheState = CACHE_I -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_1730"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Dir.ShrSet[j] = true -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1732"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_1736"
	(Sta.Dir.ShrVld = false & Sta.Dir.Pending = false -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1737"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.Pending = false -> Sta.Dir.ShrVld = true);
endruleset;


ruleset i : NODE do
Invariant "rule_1741"
	(Sta.Dir.HeadVld = false & Sta.Dir.Pending = false -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1742"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.Pending = false -> Sta.Dir.HeadVld = true);
endruleset;


ruleset i : NODE do
Invariant "rule_1743"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.HeadVld = true -> Sta.Dir.Pending = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1747"
	(Sta.Dir.ShrSet[i] = false & Sta.Dir.Pending = false -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1748"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.Pending = false -> Sta.Dir.ShrSet[i] = true);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1749"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Dir.Pending = false -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1750"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.Dir.Pending = false -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE do
Invariant "rule_1752"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.Local = false -> Sta.Dir.Pending = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1753"
	(Sta.Dir.Dirty = true & Sta.Dir.Pending = false -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1754"
	(Sta.MemData != Sta.CurrData & Sta.Dir.Pending = false -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1757"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.Pending = false -> Sta.Dir.Dirty = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1758"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.Pending = false -> Sta.MemData = Sta.CurrData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1762"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Dir.Pending = false -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1763"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.Dir.Pending = false -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE do
Invariant "rule_1765"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.ShrVld = false -> Sta.Dir.Pending = true);
endruleset;


ruleset i : NODE do
Invariant "rule_1769"
	(Sta.Dir.Pending = true & Sta.Dir.InvSet[i] = true -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1770"
	(Sta.Dir.HeadVld = false & Sta.Dir.InvSet[i] = true -> Sta.Dir.Pending = true);
endruleset;


ruleset i : NODE do
Invariant "rule_1772"
	(Sta.Dir.Pending = true & Sta.Dir.HeadVld = true -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1775"
	(Sta.Dir.ShrSet[i] = false & Sta.Dir.InvSet[i] = true -> Sta.Dir.Pending = true);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1776"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.Dir.Pending = true);
endruleset;


ruleset i : NODE do
Invariant "rule_1778"
	(Sta.Dir.Pending = true & Sta.Dir.InvSet[i] = true -> Sta.Dir.Local = true);
endruleset;


ruleset i : NODE do
Invariant "rule_1779"
	(Sta.Dir.Pending = true & Sta.Dir.Local = false -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1780"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.Dirty = true -> Sta.Dir.Pending = true);
endruleset;


ruleset i : NODE do
Invariant "rule_1781"
	(Sta.Dir.InvSet[i] = true & Sta.MemData != Sta.CurrData -> Sta.Dir.Pending = true);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1787"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.UniMsg[j].Proc = i -> Sta.Dir.Pending = true);
endruleset;


ruleset j : NODE do
Invariant "rule_1788"
	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset j : NODE do
Invariant "rule_1789"
	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset j : NODE do
Invariant "rule_1791"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1792"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Proc = i -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset j : NODE do
Invariant "rule_1793"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset j : NODE do
Invariant "rule_1794"
	(Sta.WbMsg.Cmd = WB_Wb & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_1795"
	(Sta.WbMsg.Cmd = WB_Wb & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1797"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.WbMsg.Cmd = WB_Wb -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1798"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.WbMsg.Cmd = WB_Wb -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1799"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.WbMsg.Cmd = WB_Wb -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_1800"
	(Sta.WbMsg.Cmd = WB_Wb & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_1801"
	(Sta.Dir.ShrVld = true & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_1804"
	(Sta.Dir.HeadVld = false & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_1805"
	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_1807"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1808"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1809"
		(i != j) ->	(Sta.Dir.ShrSet[i] = true & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1810"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_1815"
	(Sta.Proc[j].ProcCmd != NODE_GetX & Sta.Proc[j].ProcCmd != NODE_Get -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_1817"
	(Sta.Proc[j].ProcCmd != NODE_GetX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1819"
		(j != i) ->	(Sta.Proc[j].ProcCmd != NODE_GetX & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1820"
		(j != i) ->	(Sta.Proc[j].ProcCmd != NODE_GetX & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_1821"
	(Sta.Dir.Local = true & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_1822"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1823"
		(i != j) ->	(Sta.Dir.InvSet[i] = true & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1825"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_E & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_1826"
	(Sta.UniMsg[j].Cmd != UNI_PutX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_1827"
	(Sta.Dir.Dirty = false & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_1830"
	(Sta.Proc[j].ProcCmd != NODE_GetX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_1836"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1840"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_1842"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1843"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_1844"
	(Sta.Proc[j].ProcCmd != NODE_GetX & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_1845"
	(Sta.Proc[j].ProcCmd != NODE_GetX & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_1849"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_1850"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1851"
		(j != i) ->	(Sta.Proc[j].ProcCmd != NODE_GetX & Sta.UniMsg[j].Proc = i -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1852"
		(j != i) ->	(Sta.Proc[j].ProcCmd != NODE_GetX & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1853"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Dir.ShrSet[j] = true -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_1854"
	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.ShrVld = false);
endruleset;


ruleset j : NODE do
Invariant "rule_1857"
	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.HeadVld = true);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1858"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_1859"
	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_1861"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1862"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1863"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1864"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_1865"
	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd = NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1868"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd = NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_1869"
	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.Local = false);
endruleset;


ruleset j : NODE do
Invariant "rule_1870"
	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1871"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1873"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_1874"
	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[j].Cmd = UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_1875"
	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.Dirty = true);
endruleset;


ruleset j : NODE do
Invariant "rule_1876"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd = NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_1880"
	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1884"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1886"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1887"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1888"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_1889"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Proc[j].ProcCmd = NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_1892"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_1893"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1894"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Proc[j].ProcCmd = NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1895"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1896"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1897"
	(Sta.Proc[i].CacheState != CACHE_S & Sta.Proc[i].CacheState != CACHE_I -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1901"
	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1908"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1909"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.ShrVld = false -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1910"
	(Sta.Dir.ShrVld = false & Sta.Dir.HeadVld = true -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1912"
	(Sta.Dir.ShrSet[i] = false & Sta.Dir.InvSet[i] = true -> Sta.Dir.ShrVld = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1914"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrVld = false);
endruleset;


ruleset j : NODE do
Invariant "rule_1915"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1917"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.ShrVld = false -> Sta.Dir.Local = true);
endruleset;


ruleset i : NODE do
Invariant "rule_1918"
	(Sta.Dir.ShrVld = false & Sta.Dir.Local = false -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1925"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Dir.ShrVld = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1930"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1943"
	(Sta.Dir.ShrVld = true & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1950"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.Dir.ShrVld = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1957"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Dir.ShrVld = true -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1958"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.HeadVld = true -> Sta.Dir.ShrVld = true);
endruleset;


ruleset i : NODE do
Invariant "rule_1961"
	(Sta.Dir.ShrVld = true & Sta.Dir.ShrSet[i] = false -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1962"
	(Sta.Dir.ShrVld = true & Sta.Dir.InvSet[i] = true -> Sta.Dir.ShrSet[i] = true);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1964"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Dir.ShrVld = true -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1965"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.Dir.ShrVld = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_1966"
	(Sta.Dir.ShrVld = true & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_1967"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.Local = false -> Sta.Dir.ShrVld = true);
endruleset;


ruleset i : NODE do
Invariant "rule_1973"
	(Sta.Dir.ShrVld = true & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1978"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Dir.ShrVld = true -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1979"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.Dir.ShrVld = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE do
Invariant "rule_1992"
	(Sta.Proc[i].CacheState != CACHE_S & Sta.Proc[i].CacheState != CACHE_I -> Sta.Dir.HeadVld = true);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1994"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1996"
		(i != j) ->	(Sta.Proc[i].CacheState != CACHE_S & Sta.Proc[i].CacheState != CACHE_I -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1998"
	(Sta.Proc[i].CacheState != CACHE_S & Sta.Proc[i].CacheState != CACHE_I -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1999"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Dir.ShrSet[i] = true -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2001"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_2005"
	(Sta.Proc[i].CacheState != CACHE_S & Sta.Proc[i].CacheState != CACHE_I -> Sta.Dir.Local = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2006"
		(j != i) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[j].InvMarked = true -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_2008"
	(Sta.Proc[i].CacheState != CACHE_S & Sta.Proc[i].CacheState != CACHE_I -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset i : NODE do
Invariant "rule_2009"
	(Sta.Proc[i].CacheState != CACHE_S & Sta.Proc[i].CacheState != CACHE_I -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2010"
		(j != i) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_2012"
	(Sta.Dir.HeadPtr = i & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_2016"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2019"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.UniMsg[j].Proc = i -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_2020"
	(Sta.Proc[i].CacheState != CACHE_S & Sta.Proc[i].CacheState != CACHE_I -> Sta.Dir.Dirty = true);
endruleset;


ruleset i : NODE do
Invariant "rule_2024"
	(Sta.Proc[i].CacheState != CACHE_S & Sta.Proc[i].CacheState != CACHE_I -> Sta.Proc[i].CacheData = Sta.CurrData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2025"
		(i != j) ->	(Sta.Proc[i].CacheState != CACHE_S & Sta.Proc[i].CacheState != CACHE_I -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2026"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2032"
		(i != j) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[i].CacheState = CACHE_S -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2033"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S & Sta.Proc[i].CacheState = CACHE_S -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_2036"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheState = CACHE_S -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2037"
	(Sta.Dir.ShrSet[i] = true & Sta.Proc[i].CacheState = CACHE_S -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2039"
	(Sta.Dir.ShrSet[i] = true & Sta.Proc[i].CacheState = CACHE_S -> Sta.Proc[i].CacheData = Sta.CurrData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2041"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Proc[i].CacheState = CACHE_S -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2042"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.Proc[i].CacheState = CACHE_S -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2046"
		(j != i) ->	(Sta.Proc[j].InvMarked = true & Sta.Proc[i].CacheState = CACHE_S -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2047"
		(i != j) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[i].CacheState = CACHE_S -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2049"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[i].CacheState = CACHE_S -> Sta.Proc[i].CacheData = Sta.CurrData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2050"
		(i != j) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[i].CacheState = CACHE_S -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2051"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Put & Sta.Proc[i].CacheState = CACHE_S -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_2052"
	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[i].CacheState = CACHE_S -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE do
Invariant "rule_2053"
	(Sta.Dir.HeadPtr = i & Sta.Proc[i].CacheState = CACHE_S -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_2057"
	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[i].CacheState = CACHE_S -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2059"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheState = CACHE_S -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2062"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Proc[i].CacheState = CACHE_S -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2063"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.Proc[i].CacheState = CACHE_S -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2070"
		(i != j) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[i].CacheState = CACHE_S -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2071"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Proc[i].CacheState = CACHE_S -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_2074"
	(Sta.Dir.HeadVld = false & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2077"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2079"
	(Sta.Dir.ShrSet[i] = true & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2080"
	(Sta.Dir.ShrSet[i] = true & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2082"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.UniMsg[i].Cmd != UNI_PutX -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2085"
	(Sta.Dir.Local = true & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2086"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2088"
	(Sta.Dir.InvSet[i] = true & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2089"
	(Sta.Dir.InvSet[i] = true & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2093"
	(Sta.Proc[i].ProcCmd != NODE_GetX & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2095"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2096"
	(Sta.Dir.Dirty = false & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2099"
		(i != j) ->	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2100"
	(Sta.InvMsg[i].Cmd = INV_InvAck & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2101"
	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Dir.HeadVld = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2104"
		(i != j) ->	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2106"
	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2107"
	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2111"
	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.UniMsg[i].Cmd = UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_2112"
	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Dir.Local = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2113"
	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset i : NODE do
Invariant "rule_2115"
	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2116"
	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2119"
	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2120"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd = NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2121"
	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Dir.Dirty = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2124"
		(i != j) ->	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2125"
	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2141"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2142"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.Proc[j].CacheState = CACHE_S -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2149"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2155"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Proc = i -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2156"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2157"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2167"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.Proc[j].InvMarked = true -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2168"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2171"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2172"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2173"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2174"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2175"
	(Sta.Proc[i].InvMarked = true & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE do
Invariant "rule_2176"
	(Sta.Dir.HeadPtr = i & Sta.Proc[i].InvMarked = true -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_2177"
	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[i].Cmd != UNI_Get -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2179"
	(Sta.Proc[i].InvMarked = true & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.UniMsg[i].Cmd = UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_2183"
	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2188"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2189"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE do
Invariant "rule_2196"
	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_2198"
	(Sta.InvMsg[i].Cmd = INV_InvAck & Sta.UniMsg[i].Cmd = UNI_Put -> Sta.Proc[i].InvMarked = true);
endruleset;


ruleset i : NODE do
Invariant "rule_2201"
	(Sta.InvMsg[i].Cmd = INV_InvAck & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].InvMarked = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2202"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2203"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2204"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2205"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Proc = i -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2215"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2221"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2224"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2231"
		(j != i) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[j].InvMarked = true -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2233"
		(j != i) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2234"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.Dir.ShrSet[j] = true -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2235"
	(Sta.Dir.HeadPtr = i & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2236"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Cmd != UNI_Get -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2240"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2244"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.UniMsg[j].Proc = i -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2248"
	(Sta.UniMsg[i].Cmd != UNI_Put & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2250"
	(Sta.InvMsg[i].Cmd = INV_InvAck & Sta.Proc[i].InvMarked = false -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_2251"
	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.Proc[i].InvMarked = false -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_2253"
	(Sta.Proc[i].InvMarked = false & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2254"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Dir.ShrSet[j] = true -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2255"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2257"
	(Sta.Dir.ShrSet[i] = false & Sta.Dir.InvSet[i] = true -> Sta.Dir.HeadVld = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2259"
	(Sta.Dir.HeadVld = false & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_2261"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Dir.HeadVld = false -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2262"
		(j != i) ->	(Sta.Dir.HeadVld = false & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2263"
		(j != i) ->	(Sta.Dir.HeadVld = false & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_2264"
	(Sta.Dir.HeadVld = false & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2265"
	(Sta.Dir.HeadVld = false & Sta.Dir.InvSet[i] = true -> Sta.Dir.Local = true);
endruleset;


ruleset i : NODE do
Invariant "rule_2266"
	(Sta.Dir.HeadVld = false & Sta.Dir.Local = false -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2267"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.Dirty = true -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2268"
	(Sta.Dir.InvSet[i] = true & Sta.MemData != Sta.CurrData -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2273"
	(Sta.Dir.HeadVld = false & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2283"
	(Sta.Dir.ShrSet[i] = false & Sta.Dir.HeadVld = true -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2284"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.HeadVld = true -> Sta.Dir.ShrSet[i] = true);
endruleset;


ruleset j : NODE do
Invariant "rule_2285"
	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.HeadVld = true);
endruleset;


ruleset j : NODE do
Invariant "rule_2287"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.HeadVld = true);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2288"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Proc = i -> Sta.Dir.HeadVld = true);
endruleset;


ruleset j : NODE do
Invariant "rule_2289"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.HeadVld = true);
endruleset;


ruleset i : NODE do
Invariant "rule_2290"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.Local = false -> Sta.Dir.HeadVld = true);
endruleset;


ruleset i : NODE do
Invariant "rule_2291"
	(Sta.Dir.HeadVld = true & Sta.Dir.Dirty = true -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2292"
	(Sta.Dir.HeadVld = true & Sta.MemData != Sta.CurrData -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2294"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.HeadVld = true -> Sta.Dir.Dirty = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2295"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.HeadVld = true -> Sta.MemData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_2299"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Dir.HeadVld = true);
endruleset;


ruleset j : NODE do
Invariant "rule_2317"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_2321"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_2323"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Dir.ShrSet[j] = true -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_2324"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2325"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2326"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_2335"
	(Sta.Proc[j].CacheState = CACHE_S & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2337"
	(Sta.Proc[j].CacheState = CACHE_S & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[j].CacheData = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_2342"
	(Sta.Proc[j].CacheState = CACHE_S & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2343"
	(Sta.Proc[j].CacheState = CACHE_S & Sta.Dir.ShrSet[j] = true -> Sta.Proc[j].CacheData = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_2345"
	(Sta.Proc[j].CacheState = CACHE_S & Sta.Dir.ShrSet[j] = true -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2346"
	(Sta.Proc[j].CacheState = CACHE_S & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2347"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck & Sta.Proc[j].CacheState = CACHE_S -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2348"
	(Sta.Proc[j].CacheState = CACHE_S & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2349"
	(Sta.Proc[j].CacheState = CACHE_S & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2350"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2351"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2352"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.Proc[j].CacheState = CACHE_S -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2354"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.Dir.ShrSet[i] = false -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2355"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.Dir.InvSet[i] = true -> Sta.Dir.ShrSet[i] = true);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2360"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.ShWbMsg.Data = Sta.CurrData -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2361"
		(j != i) ->	(Sta.Proc[j].ProcCmd != NODE_Get & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_2362"
	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd = NODE_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2364"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd = NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_2367"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2368"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2370"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_2373"
	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_2374"
	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_2376"
	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2377"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Data = Sta.CurrData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2385"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Cmd != UNI_Put -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2387"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_2389"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2392"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2395"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2400"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2404"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2405"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.Proc[j].ProcCmd = NODE_None -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_2408"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2410"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2411"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2420"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2421"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2422"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2423"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.ShWbMsg.Proc = i -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2427"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.ShWbMsg.Proc = j -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2428"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2429"
		(i != j) ->	(Sta.Dir.ShrSet[i] = false & Sta.Dir.InvSet[i] = true -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2437"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Data = Sta.CurrData -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2438"
	(Sta.Proc[j].ProcCmd != NODE_Get & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2440"
		(j != i) ->	(Sta.Proc[j].ProcCmd != NODE_Get & Sta.UniMsg[j].Proc = i -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2443"
	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2444"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2445"
	(Sta.UniMsg[j].Cmd != UNI_Put & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2446"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_None -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2447"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2453"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.UniMsg[j].Cmd != UNI_Put -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2455"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2458"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2465"
		(i != j) ->	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2469"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Proc[j].ProcCmd = NODE_None -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2472"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2474"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.UniMsg[j].Proc = i -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2481"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2482"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Proc = i -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2485"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Proc = j -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2488"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2489"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2490"
	(Sta.Dir.ShrSet[i] = false & Sta.Dir.InvSet[i] = true -> Sta.Dir.Local = true);
endruleset;


ruleset i : NODE do
Invariant "rule_2491"
	(Sta.Dir.ShrSet[i] = false & Sta.Dir.Local = false -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2492"
		(i != j) ->	(Sta.Dir.ShrSet[i] = false & Sta.Dir.ShrSet[j] = true -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2493"
		(i != j) ->	(Sta.Dir.ShrSet[i] = false & Sta.Dir.InvSet[i] = true -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2495"
	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2497"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2498"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheState != CACHE_I -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2499"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2500"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd != NODE_Get -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2504"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2509"
	(Sta.UniMsg[i].Cmd = UNI_GetX & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2510"
	(Sta.UniMsg[i].Cmd != UNI_Put & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2511"
	(Sta.Proc[i].ProcCmd = NODE_None & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2512"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Dir.ShrSet[i] = true -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2513"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.Dir.ShrSet[i] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2514"
		(i != j) ->	(Sta.Dir.ShrSet[i] = true & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2515"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.Local = false -> Sta.Dir.ShrSet[i] = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2516"
		(i != j) ->	(Sta.Dir.InvSet[i] = true & Sta.Dir.ShrSet[j] = true -> Sta.Dir.ShrSet[i] = true);
endruleset;


ruleset i : NODE do
Invariant "rule_2518"
	(Sta.Dir.ShrSet[i] = true & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_2520"
	(Sta.Dir.ShrSet[i] = true & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2521"
	(Sta.Proc[i].CacheState != CACHE_I & Sta.Dir.ShrSet[i] = true -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2522"
	(Sta.Dir.ShrSet[i] = true & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2524"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Dir.ShrSet[i] = true -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_2527"
	(Sta.Dir.ShrSet[i] = true & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd = NODE_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2530"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Dir.ShrSet[i] = true -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2531"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.Dir.ShrSet[i] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE do
Invariant "rule_2533"
	(Sta.Proc[i].CacheState != CACHE_I & Sta.Dir.ShrSet[i] = true -> Sta.Proc[i].CacheData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_2536"
	(Sta.Dir.ShrSet[i] = true & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2537"
	(Sta.Dir.ShrSet[i] = true & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_2538"
	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.Dir.ShrSet[i] = true -> Sta.UniMsg[i].Data = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_2539"
	(Sta.Dir.ShrSet[i] = true & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2544"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_2547"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.UniMsg[i].Cmd != UNI_PutX -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2549"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2552"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2554"
	(Sta.UniMsg[i].Cmd = UNI_PutX & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2555"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.UniMsg[i].Cmd = UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_2560"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Data != Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_2563"
	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_2572"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Data != Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_2576"
	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_2587"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Data != Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2594"
	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2596"
	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_2602"
	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.ShWbMsg.Data = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_2603"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_None -> Sta.ShWbMsg.Data = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_2610"
	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_2611"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.ShWbMsg.Data = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_2612"
	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.ShWbMsg.Data = Sta.CurrData -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2614"
	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.ShWbMsg.Data = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_2623"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.ShWbMsg.Data = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_2629"
	(Sta.UniMsg[i].Cmd = UNI_GetX & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.ShWbMsg.Data = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_2632"
	(Sta.Proc[i].ProcCmd = NODE_None & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.ShWbMsg.Data = Sta.CurrData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2633"
		(j != i) ->	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2634"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Data = Sta.CurrData -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2635"
	(Sta.UniMsg[j].Cmd != UNI_Get & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_2636"
	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_2639"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2640"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_2641"
	(Sta.Proc[j].ProcCmd != NODE_Get & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2642"
	(Sta.UniMsg[j].Cmd != UNI_Put & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_2643"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_2644"
	(Sta.Proc[j].ProcCmd != NODE_Get & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2648"
		(j != i) ->	(Sta.Proc[j].ProcCmd != NODE_Get & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2649"
		(j != i) ->	(Sta.Proc[j].ProcCmd != NODE_Get & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_2650"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_2654"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2655"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2656"
		(j != i) ->	(Sta.Proc[j].ProcCmd != NODE_Get & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2657"
		(j != i) ->	(Sta.Proc[j].ProcCmd != NODE_Get & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2658"
	(Sta.UniMsg[j].Cmd != UNI_Get & Sta.Proc[j].ProcCmd = NODE_Get -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2659"
	(Sta.Proc[j].ProcCmd = NODE_Get & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.UniMsg[j].Cmd = UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_2660"
	(Sta.Proc[j].ProcCmd = NODE_Get & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_2663"
	(Sta.Proc[j].ProcCmd = NODE_Get & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2664"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_Get & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2665"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_Get & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_2666"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd = NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_2667"
	(Sta.Proc[j].ProcCmd = NODE_Get & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_2668"
	(Sta.Proc[j].ProcCmd = NODE_Get & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2669"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.Proc[j].ProcCmd = NODE_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2673"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[j].ProcCmd = NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_2674"
	(Sta.Proc[j].ProcCmd = NODE_Get & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_2675"
	(Sta.Proc[j].ProcCmd = NODE_Get & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2678"
	(Sta.Proc[j].ProcCmd = NODE_Get & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2679"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_Get & Sta.UniMsg[j].Proc = i -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2680"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_Get & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2681"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Dir.ShrSet[j] = true -> Sta.Proc[j].ProcCmd = NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_2684"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2685"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2686"
		(j != i) ->	(Sta.Dir.Local = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_2687"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_2688"
	(Sta.UniMsg[j].Cmd != UNI_Get & Sta.Proc[j].InvMarked = true -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2689"
	(Sta.Dir.ShrSet[j] = true & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_2690"
	(Sta.UniMsg[j].Cmd != UNI_Get & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2692"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2693"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2694"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Dir.InvSet[i] = true -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_2698"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_2699"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2700"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2701"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2703"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2704"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2705"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_2708"
	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2709"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2710"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2711"
		(j != i) ->	(Sta.Dir.Local = true & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2712"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.Dir.Local = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2713"
	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.Proc[j].InvMarked = true -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2714"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Cmd = UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_2715"
	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.Proc[j].InvMarked = true -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2716"
	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2717"
	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.Dir.ShrSet[j] = true -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2719"
	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2720"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2721"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2722"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2723"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.Dir.InvSet[i] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_2726"
	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2727"
	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2728"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2729"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2730"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2731"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[i].Cmd = UNI_Put -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2733"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2734"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2735"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2736"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2737"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2738"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2739"
		(i != j) ->	(Sta.Dir.HeadPtr != i & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_2740"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_None -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_2741"
	(Sta.UniMsg[j].Cmd != UNI_PutX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_2742"
	(Sta.Dir.Dirty = false & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2744"
		(i != j) ->	(Sta.ShWbMsg.Proc = i & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2745"
		(j != i) ->	(Sta.UniMsg[j].Proc != i & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_2746"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.ShWbMsg.Proc != j -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_2749"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2750"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2752"
		(j != i) ->	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Dir.HeadPtr != i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2753"
		(i != j) ->	(Sta.Dir.HeadPtr != i & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2757"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Proc[j].ProcCmd = NODE_None -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_2765"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_2766"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Dir.Dirty = false -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2767"
		(j != i) ->	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Proc = i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_2768"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Proc != j -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2769"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2770"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.UniMsg[j].Cmd != UNI_PutX -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2771"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Dir.Dirty = false -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2772"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Proc = i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2773"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Proc != j -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2774"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.HeadPtr = i);
endruleset;


ruleset j : NODE do
Invariant "rule_2775"
	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_2777"
	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[j].Cmd = UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_2778"
	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.Dirty = true);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2780"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2781"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Data = Sta.CurrData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2782"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[j].Proc = i);
endruleset;


ruleset j : NODE do
Invariant "rule_2783"
	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.ShWbMsg.Proc = j);
endruleset;


ruleset j : NODE do
Invariant "rule_2786"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2787"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2788"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2789"
		(i != j) ->	(Sta.Dir.HeadPtr != i & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2791"
		(j != i) ->	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.HeadPtr = i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2792"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Proc = i -> Sta.Dir.HeadPtr = i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2795"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2796"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.Proc[j].ProcCmd = NODE_None -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_2804"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_2805"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.Dirty = true);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2806"
		(j != i) ->	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_2807"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.ShWbMsg.Proc = j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2808"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2809"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2810"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Cmd != UNI_PutX -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2811"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd = UNI_PutX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2812"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Proc = i -> Sta.Dir.Dirty = true);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2813"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.Dir.Dirty = false -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2814"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2815"
		(i != j) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.ShWbMsg.Proc = i -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2816"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.ShWbMsg.Proc != j -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2817"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Proc = j);
endruleset;


ruleset j : NODE do
Invariant "rule_2818"
	(Sta.Dir.Local = true & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2819"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.Local = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2820"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Data = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_2821"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_2822"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].InvMarked = true -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2823"
	(Sta.Dir.ShrSet[j] = true & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Data = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_2824"
	(Sta.UniMsg[j].Cmd != UNI_Put & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2825"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2826"
	(Sta.UniMsg[j].Cmd != UNI_Put & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2827"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_None -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2828"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2829"
		(j != i) ->	(Sta.UniMsg[j].Proc != i & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2830"
	(Sta.UniMsg[j].Cmd = UNI_Put & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Data = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_2831"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_2832"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_2834"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2835"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Data = Sta.CurrData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2836"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[j].Proc = i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2837"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2838"
		(i != j) ->	(Sta.Dir.InvSet[i] = true & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2839"
	(Sta.UniMsg[j].Cmd != UNI_Put & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2840"
	(Sta.UniMsg[j].Cmd = UNI_Put & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Data = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_2841"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2845"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2846"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_E & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2847"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_2848"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_2849"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_2850"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_None -> Sta.Proc[j].CacheData = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_2851"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_None -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2852"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_None -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2855"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2856"
	(Sta.UniMsg[j].Cmd != UNI_PutX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2857"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[j].Cmd = UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_2858"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.Dirty = true);
endruleset;


ruleset j : NODE do
Invariant "rule_2859"
	(Sta.Dir.Dirty = false & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2867"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2871"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2875"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2879"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2883"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Data = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_2897"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.Dirty = true -> Sta.Dir.Local = true);
endruleset;


ruleset i : NODE do
Invariant "rule_2898"
	(Sta.Dir.InvSet[i] = true & Sta.MemData != Sta.CurrData -> Sta.Dir.Local = true);
endruleset;


ruleset i : NODE do
Invariant "rule_2901"
	(Sta.Dir.Local = true & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2902"
		(j != i) ->	(Sta.Dir.Local = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2903"
		(j != i) ->	(Sta.Dir.Local = true & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE do
Invariant "rule_2908"
	(Sta.Dir.Dirty = true & Sta.Dir.Local = false -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2909"
	(Sta.MemData != Sta.CurrData & Sta.Dir.Local = false -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2912"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.Local = false -> Sta.Dir.Dirty = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2913"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.Local = false -> Sta.MemData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_2914"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Dir.Local = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2915"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.UniMsg[j].Proc = i -> Sta.Dir.Local = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2922"
	(Sta.UniMsg[j].Cmd != UNI_Put & Sta.Proc[j].InvMarked = true -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2923"
	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.Proc[j].InvMarked = true -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2924"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].InvMarked = true -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2925"
		(j != i) ->	(Sta.UniMsg[j].Proc != i & Sta.Proc[j].InvMarked = true -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2926"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_2927"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_2928"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[j].InvMarked = true -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2929"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Proc = i);
endruleset;


ruleset j : NODE do
Invariant "rule_2930"
	(Sta.UniMsg[j].Cmd != UNI_Put & Sta.Proc[j].InvMarked = true -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2931"
	(Sta.Dir.ShrSet[j] = true & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_2932"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_2933"
	(Sta.Dir.ShrSet[j] = true & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_2934"
	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.Proc[j].InvMarked = true -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2935"
	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.Proc[j].InvMarked = true -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2936"
	(Sta.Dir.ShrSet[j] = true & Sta.Proc[j].InvMarked = true -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2937"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Proc[j].InvMarked = true -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2938"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].InvMarked = true -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2939"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2940"
		(j != i) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2941"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.Proc[j].InvMarked = true -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE do
Invariant "rule_2943"
	(Sta.UniMsg[j].Cmd != UNI_Put & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2944"
	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2945"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2946"
		(j != i) ->	(Sta.UniMsg[j].Proc != i & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2947"
	(Sta.UniMsg[j].Cmd != UNI_Put & Sta.Dir.ShrSet[j] = true -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2948"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2949"
	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.Dir.ShrSet[j] = true -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2950"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Dir.ShrSet[j] = true -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2951"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2952"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2955"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.UniMsg[j].Cmd != UNI_Put -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2956"
		(j != i) ->	(Sta.UniMsg[j].Proc != i & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2958"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2959"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset i : NODE do
Invariant "rule_2960"
	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2964"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Proc[j].ProcCmd = NODE_None -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2968"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2970"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset i : NODE do
Invariant "rule_2973"
	(Sta.UniMsg[i].Cmd = UNI_GetX & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2974"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2975"
		(j != i) ->	(Sta.UniMsg[j].Proc != i & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2976"
		(j != i) ->	(Sta.UniMsg[j].Cmd != UNI_Put & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2978"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2979"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Put & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Proc = i);
endruleset;


ruleset j : NODE do
Invariant "rule_2981"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2982"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2983"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE do
Invariant "rule_2984"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2987"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2988"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[j].ProcCmd = NODE_None -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_2992"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2994"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2995"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE do
Invariant "rule_2997"
	(Sta.Proc[i].CacheState != CACHE_I & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[i].CacheData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_2999"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3000"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3001"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE do
Invariant "rule_3003"
	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3004"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3006"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd != NODE_Get -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3009"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.UniMsg[j].Proc = i -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3010"
	(Sta.MemData != Sta.CurrData & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3013"
	(Sta.UniMsg[i].Cmd = UNI_GetX & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3015"
	(Sta.UniMsg[i].Cmd != UNI_Put & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3017"
	(Sta.Proc[i].ProcCmd = NODE_None & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3019"
	(Sta.Dir.InvSet[i] = true & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_3020"
	(Sta.Dir.InvSet[i] = true & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3022"
	(Sta.Dir.InvSet[i] = true & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd = NODE_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3025"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Dir.InvSet[i] = true -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3026"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.Dir.InvSet[i] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE do
Invariant "rule_3027"
	(Sta.Dir.InvSet[i] = true & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.MemData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_3030"
	(Sta.Dir.InvSet[i] = true & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_3032"
	(Sta.Dir.InvSet[i] = true & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_3034"
	(Sta.Dir.InvSet[i] = true & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3037"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Proc = i -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3038"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3040"
		(j != i) ->	(Sta.UniMsg[j].Cmd != UNI_Put & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3041"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.UniMsg[j].Cmd != UNI_Put -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3043"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3044"
		(i != j) ->	(Sta.ShWbMsg.Proc = i & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3045"
		(j != i) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3046"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3048"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_3052"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_3053"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3055"
		(i != j) ->	(Sta.ShWbMsg.Proc = i & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3056"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_3057"
	(Sta.ShWbMsg.Proc = j & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_3060"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_3061"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3063"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.Dir.ShrSet[j] = true -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3064"
		(i != j) ->	(Sta.ShWbMsg.Proc = i & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3065"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_3066"
	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.Dir.ShrSet[j] = true -> Sta.ShWbMsg.Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3067"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3068"
	(Sta.ShWbMsg.Proc = j & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3070"
	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE do
Invariant "rule_3073"
	(Sta.Dir.HeadPtr = i & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_3074"
	(Sta.Dir.HeadPtr = i & Sta.UniMsg[i].Cmd = UNI_Put -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_3079"
	(Sta.UniMsg[i].Cmd != UNI_Get & Sta.Proc[i].ProcCmd = NODE_Get -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3080"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Cmd != UNI_Get -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_3082"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_3091"
	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3092"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].ProcCmd = NODE_Get -> Sta.UniMsg[i].Cmd = UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_3132"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_Get -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3133"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_Get -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3134"
	(Sta.Dir.Dirty = false & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3141"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.Proc[i].CacheState = CACHE_I -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3142"
	(Sta.Proc[i].ProcCmd != NODE_None & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3143"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3144"
	(Sta.UniMsg[i].Cmd = UNI_GetX & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3145"
	(Sta.Proc[i].ProcCmd = NODE_None & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3146"
		(i != j) ->	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3147"
	(Sta.InvMsg[i].Cmd = INV_InvAck & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3149"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_3150"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_3151"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Dir.Dirty = true);
endruleset;


ruleset i : NODE do
Invariant "rule_3157"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Proc[i].CacheState != CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_3158"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Proc[i].ProcCmd = NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_3159"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_3160"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3161"
		(i != j) ->	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3162"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_3167"
	(Sta.UniMsg[i].Cmd != UNI_Put & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_3171"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd != NODE_Get -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_3176"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_Get -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_3180"
	(Sta.InvMsg[i].Cmd = INV_InvAck & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd = NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_3183"
	(Sta.Proc[j].ProcCmd != NODE_None & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3184"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3185"
		(i != j) ->	(Sta.ShWbMsg.Proc != i & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3186"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Dir.ShrSet[j] = true -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3187"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Proc = j -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_3190"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Proc[j].ProcCmd = NODE_None);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3191"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Proc[j].ProcCmd = NODE_None -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3192"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].ProcCmd = NODE_None -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3193"
		(i != j) ->	(Sta.ShWbMsg.Proc != i & Sta.Proc[j].ProcCmd = NODE_None -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3194"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Proc[j].ProcCmd = NODE_None -> Sta.ShWbMsg.Proc = i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3195"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_None & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3196"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Proc[j].ProcCmd = NODE_None -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3197"
		(j != i) ->	(Sta.ShWbMsg.Proc = j & Sta.Proc[j].ProcCmd = NODE_None -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3198"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Proc[j].ProcCmd = NODE_None -> Sta.ShWbMsg.Proc != j);
endruleset;


ruleset j : NODE do
Invariant "rule_3216"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_3217"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_3218"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_3219"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3220"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_3221"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_3223"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3224"
		(j != i) ->	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Proc = i -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3226"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_3227"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3228"
		(j != i) ->	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3230"
		(j != i) ->	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3234"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3236"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3237"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3238"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3239"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3240"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.UniMsg[i].Cmd = UNI_Put -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3242"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3243"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3244"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3245"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3246"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.UniMsg[j].Proc = i -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3247"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.UniMsg[j].Proc = i -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_3256"
	(Sta.MemData != Sta.CurrData & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_3259"
	(Sta.InvMsg[i].Cmd = INV_InvAck & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.MemData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_3267"
	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_3283"
	(Sta.Proc[i].ProcCmd = NODE_None & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].CacheData = Sta.CurrData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3288"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Dir.ShrSet[j] = true -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3289"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3290"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3294"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Dir.ShrSet[j] = true -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3298"
		(i != j) ->	(Sta.ShWbMsg.Proc = i & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3299"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Proc = i -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3304"
	(Sta.UniMsg[i].Cmd != UNI_Put & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3305"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_3312"
	(Sta.InvMsg[i].Cmd = INV_InvAck & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3313"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3314"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.UniMsg[j].Proc = i -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_3321"
	(Sta.InvMsg[i].Cmd = INV_InvAck & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_3326"
	(Sta.Proc[i].ProcCmd = NODE_None & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3331"
		(j != i) ->	(Sta.ShWbMsg.Proc = j & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3332"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Dir.ShrSet[j] = true -> Sta.ShWbMsg.Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3333"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Proc = j -> Sta.Dir.ShrSet[j] = false);
endruleset;
