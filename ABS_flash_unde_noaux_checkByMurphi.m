
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


ruleset j : NODE do
Invariant "rule_1"
	(Sta.Dir.ShrSet[j] = true -> Sta.Dir.Dirty = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2"
	(Sta.Dir.Dirty = false -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_3"
	(Sta.Dir.ShrSet[i] = true -> Sta.Dir.Dirty = false);
endruleset;
Invariant "rule_4"
	(Sta.Dir.Dirty = false -> Sta.Dir.HeadPtr != Home);


ruleset j : NODE do
Invariant "rule_5"
	(Sta.Dir.Dirty = false -> Sta.UniMsg[j].Proc != Home);
endruleset;
Invariant "rule_6"
	(Sta.Dir.Dirty = false -> Sta.ShWbMsg.Cmd != SHWB_ShWb);


ruleset j : NODE do
Invariant "rule_7"
	(Sta.Dir.Dirty = false -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_8"
	(Sta.Dir.InvSet[j] = true -> Sta.Dir.Dirty = false);
endruleset;


ruleset i : NODE do
Invariant "rule_9"
	(Sta.Dir.Dirty = false -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_10"
	(Sta.Dir.Dirty = false -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_11"
	(Sta.Dir.Dirty = false -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_12"
	(Sta.Dir.Dirty = false -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;
Invariant "rule_13"
	(Sta.Dir.ShrVld = true -> Sta.Dir.Dirty = false);
Invariant "rule_14"
	(Sta.Dir.Dirty = false -> Sta.WbMsg.Data != Sta.PrevData);


ruleset j : NODE do
Invariant "rule_15"
	(Sta.Dir.Dirty = false -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;
Invariant "rule_16"
	(Sta.Dir.Dirty = false -> Sta.MemData != Sta.PrevData);
Invariant "rule_17"
	(Sta.Dir.Dirty = false -> Sta.ShWbMsg.Proc != Home);


ruleset i : NODE do
Invariant "rule_18"
	(Sta.Dir.Dirty = false -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_19"
	(Sta.Dir.Dirty = false -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_20"
	(Sta.Dir.Dirty = false -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;
Invariant "rule_21"
	(Sta.Dir.Dirty = false -> Sta.WbMsg.Cmd != WB_Wb);


ruleset i : NODE do
Invariant "rule_22"
	(Sta.Dir.Dirty = false -> Sta.UniMsg[i].Proc != Home);
endruleset;
Invariant "rule_23"
	(Sta.Dir.Dirty = false -> Sta.MemData = Sta.CurrData);
Invariant "rule_24"
	(Sta.Dir.Dirty = false -> Sta.ShWbMsg.Data != Sta.PrevData);


ruleset j : NODE do
Invariant "rule_25"
	(Sta.Dir.Dirty = false -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_26"
	(Sta.Dir.Dirty = true -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_27"
	(Sta.Dir.Dirty = true -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_28"
	(Sta.Dir.Dirty = true -> Sta.Dir.ShrSet[i] = false);
endruleset;
Invariant "rule_29"
	(Sta.Dir.Dirty = true -> Sta.Dir.HeadPtr != Home);


ruleset j : NODE do
Invariant "rule_30"
	(Sta.Dir.Dirty = true -> Sta.UniMsg[j].Proc != Home);
endruleset;
Invariant "rule_31"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Dir.Dirty = true);


ruleset j : NODE do
Invariant "rule_32"
	(Sta.Dir.Dirty = true -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_33"
	(Sta.Dir.Dirty = true -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_34"
	(Sta.Dir.Dirty = true -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_35"
	(Sta.Dir.Dirty = true -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_36"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Dir.Dirty = true);
endruleset;


ruleset j : NODE do
Invariant "rule_37"
	(Sta.Dir.Dirty = true -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;
Invariant "rule_38"
	(Sta.Dir.Dirty = true -> Sta.Dir.ShrVld = false);
Invariant "rule_39"
	(Sta.Dir.Dirty = true -> Sta.WbMsg.Data != Sta.PrevData);


ruleset j : NODE do
Invariant "rule_40"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Dir.Dirty = true);
endruleset;
Invariant "rule_41"
	(Sta.Dir.Dirty = true -> Sta.MemData != Sta.PrevData);
Invariant "rule_42"
	(Sta.Dir.Dirty = true -> Sta.ShWbMsg.Proc != Home);


ruleset i : NODE do
Invariant "rule_43"
	(Sta.Dir.Dirty = true -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_44"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Dir.Dirty = true);
endruleset;


ruleset j : NODE do
Invariant "rule_45"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Dir.Dirty = true);
endruleset;
Invariant "rule_46"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.Dir.Dirty = true);


ruleset i : NODE do
Invariant "rule_47"
	(Sta.Dir.Dirty = true -> Sta.UniMsg[i].Proc != Home);
endruleset;
Invariant "rule_48"
	(Sta.MemData != Sta.CurrData -> Sta.Dir.Dirty = true);
Invariant "rule_49"
	(Sta.Dir.Dirty = true -> Sta.ShWbMsg.Data != Sta.PrevData);


ruleset j : NODE do
Invariant "rule_50"
	(Sta.Dir.Dirty = true -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_51"
	(Sta.Dir.ShrSet[j] = false -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_52"
	(Sta.Dir.ShrSet[j] = false -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_53"
	(Sta.Dir.ShrSet[j] = false -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_54"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_55"
	(Sta.Dir.ShrSet[j] = false -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_56"
	(Sta.Dir.ShrSet[j] = false -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_57"
	(Sta.Dir.InvSet[j] = false -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_58"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_59"
		(j != i) ->	(Sta.Dir.ShrSet[j] = false -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_60"
	(Sta.Dir.Pending = true -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_61"
	(Sta.Dir.ShrSet[j] = false -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_62"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_63"
	(Sta.Dir.ShrSet[j] = false -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_64"
	(Sta.Dir.ShrVld = false -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_65"
	(Sta.Dir.ShrSet[j] = false -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_66"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_67"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_68"
		(i != j) ->	(Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_69"
		(i != j) ->	(Sta.UniMsg[i].Proc = j -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_70"
	(Sta.Dir.HeadVld = false -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_71"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_72"
	(Sta.Dir.ShrSet[j] = false -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_73"
	(Sta.Dir.ShrSet[j] = false -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_74"
		(j != i) ->	(Sta.Dir.ShrSet[j] = false -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_75"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_76"
	(Sta.UniMsg[j].Data != Sta.CurrData -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_77"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_78"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_79"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_80"
		(j != i) ->	(Sta.Dir.ShrSet[j] = false -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_81"
		(i != j) ->	(Sta.Dir.HeadPtr != i -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_82"
	(Sta.MemData != Sta.CurrData -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_83"
	(Sta.Dir.ShrSet[j] = false -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_84"
	(Sta.Dir.ShrSet[j] = false -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_85"
	(Sta.Dir.ShrSet[j] = true -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_86"
	(Sta.Dir.ShrSet[j] = true -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_87"
	(Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_88"
	(Sta.Dir.ShrSet[j] = true -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_89"
	(Sta.Dir.ShrSet[j] = true -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_90"
	(Sta.Dir.InvSet[j] = true -> Sta.Dir.ShrSet[j] = true);
endruleset;


ruleset j : NODE do
Invariant "rule_91"
	(Sta.Dir.ShrSet[j] = true -> Sta.Dir.InvSet[j] = true);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_92"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_93"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_94"
	(Sta.Dir.ShrSet[j] = true -> Sta.Dir.Pending = false);
endruleset;


ruleset j : NODE do
Invariant "rule_95"
	(Sta.Dir.ShrSet[j] = true -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_96"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_97"
	(Sta.Dir.ShrSet[j] = true -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_98"
	(Sta.Dir.ShrSet[j] = true -> Sta.Dir.ShrVld = true);
endruleset;


ruleset j : NODE do
Invariant "rule_99"
	(Sta.Dir.ShrSet[j] = true -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_100"
	(Sta.Dir.ShrSet[j] = true -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE do
Invariant "rule_101"
	(Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_102"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE do
Invariant "rule_103"
	(Sta.Dir.ShrSet[j] = true -> Sta.Dir.HeadVld = true);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_104"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_105"
	(Sta.Dir.ShrSet[j] = true -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_106"
	(Sta.Dir.ShrSet[j] = true -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_107"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_108"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_109"
	(Sta.Dir.ShrSet[j] = true -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_110"
	(Sta.Dir.ShrSet[j] = true -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_111"
	(Sta.Dir.ShrSet[j] = true -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_112"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_113"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true -> Sta.Dir.HeadPtr = i);
endruleset;


ruleset j : NODE do
Invariant "rule_114"
	(Sta.Dir.ShrSet[j] = true -> Sta.MemData = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_115"
	(Sta.Dir.ShrSet[j] = true -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_116"
	(Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_117"
		(i != j) ->	(Sta.Dir.ShrSet[i] = false -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_118"
		(i != j) ->	(Sta.Dir.ShrSet[i] = true -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_119"
	(Sta.InvMsg[j].Cmd != INV_InvAck -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_120"
	(Sta.Dir.HeadPtr != Home -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_121"
	(Sta.UniMsg[j].Proc != Home -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_122"
	(Sta.InvMsg[j].Cmd != INV_InvAck -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_123"
		(i != j) ->	(Sta.Proc[i].ProcCmd != NODE_GetX -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_124"
		(i != j) ->	(Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_125"
	(Sta.ShWbMsg.Data != Sta.CurrData -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_126"
	(Sta.ShWbMsg.Data = Sta.CurrData -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_127"
	(Sta.Dir.Local = false -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_128"
	(Sta.Dir.Local = true -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_129"
	(Sta.ShWbMsg.Cmd != SHWB_ShWb -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_130"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_131"
	(Sta.Dir.HeadPtr != j -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_132"
	(Sta.InvMsg[j].Cmd != INV_InvAck -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_133"
	(Sta.Dir.InvSet[j] = false -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_134"
	(Sta.Dir.InvSet[j] = true -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_135"
	(Sta.Proc[j].InvMarked = true -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_136"
	(Sta.Proc[j].InvMarked = false -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_137"
	(Sta.Proc[j].CacheState != CACHE_S -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_138"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_139"
		(i != j) ->	(Sta.InvMsg[i].Cmd != INV_Inv -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_140"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_141"
		(i != j) ->	(Sta.RpMsg[i].Cmd != RP_Replace -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_142"
		(i != j) ->	(Sta.RpMsg[i].Cmd = RP_Replace -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_143"
		(j != i) ->	(Sta.InvMsg[j].Cmd != INV_InvAck -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_144"
		(i != j) ->	(Sta.UniMsg[i].Data != Sta.PrevData -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_145"
		(i != j) ->	(Sta.UniMsg[i].Cmd != UNI_Get -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_146"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_147"
	(Sta.Dir.Pending = true -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_148"
	(Sta.Dir.Pending = false -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_149"
		(i != j) ->	(Sta.Dir.InvSet[i] = true -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_150"
		(i != j) ->	(Sta.Dir.InvSet[i] = false -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_151"
		(i != j) ->	(Sta.ShWbMsg.Proc != i -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_152"
		(i != j) ->	(Sta.ShWbMsg.Proc = i -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_153"
	(Sta.UniMsg[j].Cmd != UNI_Put -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_154"
	(Sta.UniMsg[j].Cmd = UNI_Put -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_155"
	(Sta.Proc[j].ProcCmd != NODE_GetX -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_156"
	(Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_157"
		(i != j) ->	(Sta.UniMsg[i].Cmd != UNI_PutX -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_158"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_159"
	(Sta.InvMsg[j].Cmd != INV_InvAck -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_160"
	(Sta.Proc[j].CacheData != Sta.PrevData -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_161"
	(Sta.Dir.ShrVld = true -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_162"
	(Sta.Dir.ShrVld = false -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_163"
	(Sta.Proc[j].ProcCmd != NODE_None -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_164"
	(Sta.Proc[j].ProcCmd = NODE_None -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_165"
	(Sta.WbMsg.Data != Sta.PrevData -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_166"
	(Sta.InvMsg[j].Cmd != INV_InvAck -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_167"
	(Sta.NakcMsg.Cmd != NAKC_Nakc -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_168"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_169"
	(Sta.WbMsg.Data != Sta.CurrData -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_170"
	(Sta.WbMsg.Data = Sta.CurrData -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_171"
	(Sta.UniMsg[j].Cmd != UNI_PutX -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_172"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_173"
		(i != j) ->	(Sta.UniMsg[i].Data != Sta.CurrData -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_174"
		(i != j) ->	(Sta.UniMsg[i].Data = Sta.CurrData -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_175"
		(i != j) ->	(Sta.UniMsg[i].Proc != j -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_176"
		(i != j) ->	(Sta.UniMsg[i].Proc = j -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_177"
	(Sta.Proc[j].ProcCmd != NODE_Get -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_178"
	(Sta.Proc[j].ProcCmd = NODE_Get -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_179"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_180"
		(i != j) ->	(Sta.Proc[i].CacheData = Sta.CurrData -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_181"
	(Sta.Dir.HeadVld = true -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_182"
	(Sta.Dir.HeadVld = false -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_183"
		(i != j) ->	(Sta.InvMsg[i].Cmd != INV_InvAck -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_184"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_185"
	(Sta.InvMsg[j].Cmd != INV_InvAck -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_186"
	(Sta.MemData != Sta.PrevData -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_187"
	(Sta.UniMsg[j].Cmd != UNI_GetX -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_188"
	(Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_189"
		(i != j) ->	(Sta.Proc[i].InvMarked = false -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_190"
		(i != j) ->	(Sta.Proc[i].InvMarked = true -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_191"
		(i != j) ->	(Sta.Proc[i].CacheState != CACHE_I -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_192"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_I -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_193"
		(i != j) ->	(Sta.Proc[i].ProcCmd != NODE_Get -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_194"
		(i != j) ->	(Sta.Proc[i].ProcCmd = NODE_Get -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_195"
	(Sta.InvMsg[j].Cmd != INV_InvAck -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_196"
	(Sta.ShWbMsg.Proc != Home -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_197"
	(Sta.ShWbMsg.Proc != j -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_198"
	(Sta.ShWbMsg.Proc = j -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_199"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.PrevData -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_200"
		(j != i) ->	(Sta.InvMsg[j].Cmd != INV_InvAck -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_201"
	(Sta.UniMsg[j].Cmd != UNI_Nak -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_202"
	(Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_203"
		(i != j) ->	(Sta.Proc[i].CacheState != CACHE_E -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_204"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_E -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_205"
		(i != j) ->	(Sta.UniMsg[i].Cmd != UNI_Nak -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_206"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_207"
	(Sta.UniMsg[j].Data != Sta.CurrData -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_208"
	(Sta.UniMsg[j].Data = Sta.CurrData -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_209"
	(Sta.RpMsg[j].Cmd != RP_Replace -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_210"
	(Sta.RpMsg[j].Cmd = RP_Replace -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_211"
	(Sta.UniMsg[j].Cmd != UNI_Get -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_212"
	(Sta.UniMsg[j].Cmd = UNI_Get -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_213"
		(i != j) ->	(Sta.Proc[i].ProcCmd != NODE_None -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_214"
		(i != j) ->	(Sta.Proc[i].ProcCmd = NODE_None -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_215"
	(Sta.Proc[j].CacheData != Sta.CurrData -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_216"
	(Sta.Proc[j].CacheData = Sta.CurrData -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_217"
	(Sta.ShWbMsg.Cmd != SHWB_FAck -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_218"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_219"
		(i != j) ->	(Sta.Proc[i].CacheState != CACHE_S -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_220"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_S -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_221"
	(Sta.Proc[j].CacheState != CACHE_E -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_222"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_223"
	(Sta.WbMsg.Cmd != WB_Wb -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_224"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_225"
		(j != i) ->	(Sta.UniMsg[j].Proc != i -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_226"
		(j != i) ->	(Sta.UniMsg[j].Proc = i -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_227"
		(i != j) ->	(Sta.UniMsg[i].Proc != Home -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_228"
		(j != i) ->	(Sta.InvMsg[j].Cmd != INV_InvAck -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_229"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_230"
	(Sta.Proc[j].CacheState = CACHE_I -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_231"
		(i != j) ->	(Sta.Dir.HeadPtr != i -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_232"
		(i != j) ->	(Sta.Dir.HeadPtr = i -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_233"
		(i != j) ->	(Sta.UniMsg[i].Cmd != UNI_Put -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_234"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_235"
		(i != j) ->	(Sta.UniMsg[i].Cmd != UNI_GetX -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_236"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_237"
	(Sta.MemData != Sta.CurrData -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_238"
	(Sta.MemData = Sta.CurrData -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_239"
	(Sta.InvMsg[j].Cmd != INV_InvAck -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_240"
	(Sta.ShWbMsg.Data != Sta.PrevData -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_241"
	(Sta.UniMsg[j].Data != Sta.PrevData -> Sta.InvMsg[j].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_242"
	(Sta.InvMsg[j].Cmd != INV_InvAck -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_243"
	(Sta.Dir.ShrSet[i] = false -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_244"
		(i != j) ->	(Sta.Dir.ShrSet[i] = false -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_245"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_246"
		(i != j) ->	(Sta.Dir.ShrSet[i] = false -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE do
Invariant "rule_247"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_248"
	(Sta.Dir.ShrSet[i] = false -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_249"
	(Sta.Dir.Pending = true -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_250"
		(i != j) ->	(Sta.Dir.ShrSet[i] = false -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_251"
	(Sta.Dir.InvSet[i] = false -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_252"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_253"
		(i != j) ->	(Sta.Dir.ShrSet[i] = false -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_254"
	(Sta.Dir.ShrVld = false -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_255"
	(Sta.Dir.ShrSet[i] = false -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_256"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_257"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_258"
	(Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_259"
		(i != j) ->	(Sta.UniMsg[i].Proc = j -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_260"
	(Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_261"
	(Sta.Dir.HeadVld = false -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_262"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_263"
	(Sta.Dir.ShrSet[i] = false -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_264"
	(Sta.Proc[i].InvMarked = true -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_265"
	(Sta.Dir.ShrSet[i] = false -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_266"
	(Sta.Dir.ShrSet[i] = false -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_267"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_268"
	(Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_269"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_270"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_271"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_272"
	(Sta.Dir.ShrSet[i] = false -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_273"
	(Sta.Dir.HeadPtr != i -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_274"
	(Sta.MemData != Sta.CurrData -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_275"
	(Sta.Dir.ShrSet[i] = false -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_276"
		(i != j) ->	(Sta.Dir.ShrSet[i] = false -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_277"
	(Sta.Dir.ShrSet[i] = true -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_278"
		(i != j) ->	(Sta.Dir.ShrSet[i] = true -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_279"
	(Sta.Dir.ShrSet[i] = true -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_280"
		(i != j) ->	(Sta.Dir.ShrSet[i] = true -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE do
Invariant "rule_281"
	(Sta.Dir.ShrSet[i] = true -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_282"
	(Sta.Dir.ShrSet[i] = true -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_283"
	(Sta.Dir.ShrSet[i] = true -> Sta.Dir.Pending = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_284"
		(i != j) ->	(Sta.Dir.ShrSet[i] = true -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_285"
	(Sta.Dir.ShrSet[i] = true -> Sta.Dir.InvSet[i] = true);
endruleset;


ruleset i : NODE do
Invariant "rule_286"
	(Sta.Dir.ShrSet[i] = true -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_287"
		(i != j) ->	(Sta.Dir.ShrSet[i] = true -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_288"
	(Sta.Dir.ShrSet[i] = true -> Sta.Dir.ShrVld = true);
endruleset;


ruleset i : NODE do
Invariant "rule_289"
	(Sta.Dir.ShrSet[i] = true -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_290"
	(Sta.Dir.ShrSet[i] = true -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_291"
		(i != j) ->	(Sta.Dir.ShrSet[i] = true -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_292"
		(i != j) ->	(Sta.Dir.ShrSet[i] = true -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE do
Invariant "rule_293"
	(Sta.Dir.ShrSet[i] = true -> Sta.Dir.HeadVld = true);
endruleset;


ruleset i : NODE do
Invariant "rule_294"
	(Sta.Dir.ShrSet[i] = true -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_295"
	(Sta.Dir.ShrSet[i] = true -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_296"
	(Sta.Dir.ShrSet[i] = true -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_297"
	(Sta.Dir.ShrSet[i] = true -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_298"
	(Sta.Dir.ShrSet[i] = true -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_299"
	(Sta.Dir.ShrSet[i] = true -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_300"
	(Sta.Dir.ShrSet[i] = true -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_301"
	(Sta.Dir.ShrSet[i] = true -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_302"
		(i != j) ->	(Sta.Dir.ShrSet[i] = true -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_303"
	(Sta.Dir.ShrSet[i] = true -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset i : NODE do
Invariant "rule_304"
	(Sta.Dir.ShrSet[i] = true -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_305"
	(Sta.Dir.ShrSet[i] = true -> Sta.Dir.HeadPtr = i);
endruleset;


ruleset i : NODE do
Invariant "rule_306"
	(Sta.Dir.ShrSet[i] = true -> Sta.MemData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_307"
	(Sta.Dir.ShrSet[i] = true -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_308"
		(i != j) ->	(Sta.Dir.ShrSet[i] = true -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_309"
	(Sta.UniMsg[j].Proc != Home -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_310"
	(Sta.Dir.HeadPtr != Home -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_311"
	(Sta.Proc[i].ProcCmd != NODE_GetX -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_312"
	(Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.Dir.HeadPtr != Home);
endruleset;
Invariant "rule_313"
	(Sta.ShWbMsg.Data != Sta.CurrData -> Sta.Dir.HeadPtr != Home);
Invariant "rule_314"
	(Sta.ShWbMsg.Data = Sta.CurrData -> Sta.Dir.HeadPtr != Home);
Invariant "rule_315"
	(Sta.Dir.Local = false -> Sta.Dir.HeadPtr != Home);
Invariant "rule_316"
	(Sta.Dir.Local = true -> Sta.Dir.HeadPtr != Home);
Invariant "rule_317"
	(Sta.ShWbMsg.Cmd != SHWB_ShWb -> Sta.Dir.HeadPtr != Home);
Invariant "rule_318"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Dir.HeadPtr != Home);


ruleset j : NODE do
Invariant "rule_319"
	(Sta.Dir.InvSet[j] = false -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_320"
	(Sta.Dir.InvSet[j] = true -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_321"
	(Sta.Proc[j].InvMarked = true -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_322"
	(Sta.Proc[j].InvMarked = false -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_323"
	(Sta.Proc[j].CacheState != CACHE_S -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_324"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_325"
	(Sta.InvMsg[i].Cmd != INV_Inv -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_326"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_327"
	(Sta.RpMsg[i].Cmd != RP_Replace -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_328"
	(Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_329"
	(Sta.UniMsg[i].Data != Sta.PrevData -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_330"
	(Sta.Dir.HeadPtr != Home -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_331"
	(Sta.UniMsg[i].Cmd != UNI_Get -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_332"
	(Sta.UniMsg[i].Cmd = UNI_Get -> Sta.Dir.HeadPtr != Home);
endruleset;
Invariant "rule_333"
	(Sta.Dir.Pending = true -> Sta.Dir.HeadPtr != Home);
Invariant "rule_334"
	(Sta.Dir.Pending = false -> Sta.Dir.HeadPtr != Home);


ruleset j : NODE do
Invariant "rule_335"
	(Sta.InvMsg[j].Cmd != INV_Inv -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_336"
	(Sta.Dir.HeadPtr != Home -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_337"
	(Sta.Dir.InvSet[i] = true -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_338"
	(Sta.Dir.InvSet[i] = false -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_339"
	(Sta.ShWbMsg.Proc != i -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_340"
	(Sta.ShWbMsg.Proc = i -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_341"
	(Sta.UniMsg[j].Cmd != UNI_Put -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_342"
	(Sta.UniMsg[j].Cmd = UNI_Put -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_343"
	(Sta.Proc[j].ProcCmd != NODE_GetX -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_344"
	(Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_345"
	(Sta.UniMsg[i].Cmd != UNI_PutX -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_346"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_347"
	(Sta.Proc[j].CacheData != Sta.PrevData -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_348"
	(Sta.Dir.HeadPtr != Home -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;
Invariant "rule_349"
	(Sta.Dir.ShrVld = true -> Sta.Dir.HeadPtr != Home);
Invariant "rule_350"
	(Sta.Dir.ShrVld = false -> Sta.Dir.HeadPtr != Home);


ruleset j : NODE do
Invariant "rule_351"
	(Sta.Proc[j].ProcCmd != NODE_None -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_352"
	(Sta.Proc[j].ProcCmd = NODE_None -> Sta.Dir.HeadPtr != Home);
endruleset;
Invariant "rule_353"
	(Sta.WbMsg.Data != Sta.PrevData -> Sta.Dir.HeadPtr != Home);
Invariant "rule_354"
	(Sta.Dir.HeadPtr != Home -> Sta.WbMsg.Data != Sta.PrevData);
Invariant "rule_355"
	(Sta.NakcMsg.Cmd != NAKC_Nakc -> Sta.Dir.HeadPtr != Home);
Invariant "rule_356"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Dir.HeadPtr != Home);
Invariant "rule_357"
	(Sta.WbMsg.Data != Sta.CurrData -> Sta.Dir.HeadPtr != Home);
Invariant "rule_358"
	(Sta.WbMsg.Data = Sta.CurrData -> Sta.Dir.HeadPtr != Home);


ruleset j : NODE do
Invariant "rule_359"
	(Sta.UniMsg[j].Cmd != UNI_PutX -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_360"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_361"
	(Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_362"
	(Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_363"
		(i != j) ->	(Sta.UniMsg[i].Proc != j -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_364"
		(i != j) ->	(Sta.UniMsg[i].Proc = j -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_365"
	(Sta.Proc[j].ProcCmd != NODE_Get -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_366"
	(Sta.Proc[j].ProcCmd = NODE_Get -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_367"
	(Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_368"
	(Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Dir.HeadPtr != Home);
endruleset;
Invariant "rule_369"
	(Sta.Dir.HeadVld = true -> Sta.Dir.HeadPtr != Home);
Invariant "rule_370"
	(Sta.Dir.HeadVld = false -> Sta.Dir.HeadPtr != Home);


ruleset i : NODE do
Invariant "rule_371"
	(Sta.InvMsg[i].Cmd != INV_InvAck -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_372"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Dir.HeadPtr != Home);
endruleset;
Invariant "rule_373"
	(Sta.MemData != Sta.PrevData -> Sta.Dir.HeadPtr != Home);
Invariant "rule_374"
	(Sta.Dir.HeadPtr != Home -> Sta.MemData != Sta.PrevData);


ruleset j : NODE do
Invariant "rule_375"
	(Sta.UniMsg[j].Cmd != UNI_GetX -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_376"
	(Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_377"
	(Sta.Proc[i].InvMarked = false -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_378"
	(Sta.Proc[i].InvMarked = true -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_379"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_380"
	(Sta.Proc[i].CacheState = CACHE_I -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_381"
	(Sta.Proc[i].ProcCmd != NODE_Get -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_382"
	(Sta.Proc[i].ProcCmd = NODE_Get -> Sta.Dir.HeadPtr != Home);
endruleset;
Invariant "rule_383"
	(Sta.ShWbMsg.Proc != Home -> Sta.Dir.HeadPtr != Home);
Invariant "rule_384"
	(Sta.Dir.HeadPtr != Home -> Sta.ShWbMsg.Proc != Home);


ruleset j : NODE do
Invariant "rule_385"
	(Sta.ShWbMsg.Proc != j -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_386"
	(Sta.ShWbMsg.Proc = j -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_387"
	(Sta.Proc[i].CacheData != Sta.PrevData -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_388"
	(Sta.Dir.HeadPtr != Home -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_389"
	(Sta.UniMsg[j].Cmd != UNI_Nak -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_390"
	(Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_391"
	(Sta.Proc[i].CacheState != CACHE_E -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_392"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_393"
	(Sta.UniMsg[i].Cmd != UNI_Nak -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_394"
	(Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_395"
	(Sta.UniMsg[j].Data != Sta.CurrData -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_396"
	(Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_397"
	(Sta.RpMsg[j].Cmd != RP_Replace -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_398"
	(Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_399"
	(Sta.UniMsg[j].Cmd != UNI_Get -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_400"
	(Sta.UniMsg[j].Cmd = UNI_Get -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_401"
	(Sta.Proc[i].ProcCmd != NODE_None -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_402"
	(Sta.Proc[i].ProcCmd = NODE_None -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_403"
	(Sta.Proc[j].CacheData != Sta.CurrData -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_404"
	(Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Dir.HeadPtr != Home);
endruleset;
Invariant "rule_405"
	(Sta.ShWbMsg.Cmd != SHWB_FAck -> Sta.Dir.HeadPtr != Home);
Invariant "rule_406"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.HeadPtr != Home);


ruleset i : NODE do
Invariant "rule_407"
	(Sta.Proc[i].CacheState != CACHE_S -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_408"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_409"
	(Sta.Proc[j].CacheState != CACHE_E -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_410"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Dir.HeadPtr != Home);
endruleset;
Invariant "rule_411"
	(Sta.WbMsg.Cmd != WB_Wb -> Sta.Dir.HeadPtr != Home);
Invariant "rule_412"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.Dir.HeadPtr != Home);


ruleset j : NODE ; i : NODE do
Invariant "rule_413"
		(j != i) ->	(Sta.UniMsg[j].Proc != i -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_414"
		(j != i) ->	(Sta.UniMsg[j].Proc = i -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_415"
	(Sta.UniMsg[i].Proc != Home -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_416"
	(Sta.Dir.HeadPtr != Home -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_417"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_418"
	(Sta.Proc[j].CacheState = CACHE_I -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_419"
	(Sta.UniMsg[i].Cmd != UNI_Put -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_420"
	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_421"
	(Sta.UniMsg[i].Cmd != UNI_GetX -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_422"
	(Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Dir.HeadPtr != Home);
endruleset;
Invariant "rule_423"
	(Sta.MemData != Sta.CurrData -> Sta.Dir.HeadPtr != Home);
Invariant "rule_424"
	(Sta.MemData = Sta.CurrData -> Sta.Dir.HeadPtr != Home);
Invariant "rule_425"
	(Sta.ShWbMsg.Data != Sta.PrevData -> Sta.Dir.HeadPtr != Home);
Invariant "rule_426"
	(Sta.Dir.HeadPtr != Home -> Sta.ShWbMsg.Data != Sta.PrevData);


ruleset j : NODE do
Invariant "rule_427"
	(Sta.UniMsg[j].Data != Sta.PrevData -> Sta.Dir.HeadPtr != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_428"
	(Sta.Dir.HeadPtr != Home -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_429"
		(i != j) ->	(Sta.Proc[i].ProcCmd != NODE_GetX -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_430"
		(i != j) ->	(Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_431"
	(Sta.ShWbMsg.Data != Sta.CurrData -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_432"
	(Sta.ShWbMsg.Data = Sta.CurrData -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_433"
	(Sta.Dir.Local = false -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_434"
	(Sta.Dir.Local = true -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_435"
	(Sta.ShWbMsg.Cmd != SHWB_ShWb -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_436"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_437"
	(Sta.UniMsg[j].Proc != Home -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_438"
	(Sta.Dir.HeadPtr != j -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_439"
	(Sta.Dir.InvSet[j] = false -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_440"
	(Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_441"
	(Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_442"
	(Sta.Proc[j].InvMarked = false -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_443"
	(Sta.Proc[j].CacheState != CACHE_S -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_444"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_445"
		(i != j) ->	(Sta.InvMsg[i].Cmd != INV_Inv -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_446"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_447"
		(i != j) ->	(Sta.RpMsg[i].Cmd != RP_Replace -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_448"
		(i != j) ->	(Sta.RpMsg[i].Cmd = RP_Replace -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_449"
		(j != i) ->	(Sta.UniMsg[j].Proc != Home -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_450"
		(i != j) ->	(Sta.UniMsg[i].Data != Sta.PrevData -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_451"
		(i != j) ->	(Sta.UniMsg[i].Cmd != UNI_Get -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_452"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_453"
	(Sta.Dir.Pending = true -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_454"
	(Sta.Dir.Pending = false -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_455"
	(Sta.UniMsg[j].Proc != Home -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_456"
	(Sta.InvMsg[j].Cmd != INV_Inv -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_457"
		(i != j) ->	(Sta.Dir.InvSet[i] = true -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_458"
		(i != j) ->	(Sta.Dir.InvSet[i] = false -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_459"
		(i != j) ->	(Sta.ShWbMsg.Proc != i -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_460"
		(i != j) ->	(Sta.ShWbMsg.Proc = i -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_461"
	(Sta.UniMsg[j].Cmd != UNI_Put -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_462"
	(Sta.UniMsg[j].Cmd = UNI_Put -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_463"
	(Sta.Proc[j].ProcCmd != NODE_GetX -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_464"
	(Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_465"
		(i != j) ->	(Sta.UniMsg[i].Cmd != UNI_PutX -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_466"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_467"
	(Sta.UniMsg[j].Proc != Home -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_468"
	(Sta.Proc[j].CacheData != Sta.PrevData -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_469"
	(Sta.Dir.ShrVld = true -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_470"
	(Sta.Dir.ShrVld = false -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_471"
	(Sta.Proc[j].ProcCmd != NODE_None -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_472"
	(Sta.Proc[j].ProcCmd = NODE_None -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_473"
	(Sta.UniMsg[j].Proc != Home -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_474"
	(Sta.WbMsg.Data != Sta.PrevData -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_475"
	(Sta.NakcMsg.Cmd != NAKC_Nakc -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_476"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_477"
	(Sta.WbMsg.Data != Sta.CurrData -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_478"
	(Sta.WbMsg.Data = Sta.CurrData -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_479"
	(Sta.UniMsg[j].Cmd != UNI_PutX -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_480"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_481"
		(i != j) ->	(Sta.UniMsg[i].Data != Sta.CurrData -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_482"
		(i != j) ->	(Sta.UniMsg[i].Data = Sta.CurrData -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_483"
		(i != j) ->	(Sta.UniMsg[i].Proc != j -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_484"
		(i != j) ->	(Sta.UniMsg[i].Proc = j -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_485"
	(Sta.Proc[j].ProcCmd != NODE_Get -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_486"
	(Sta.Proc[j].ProcCmd = NODE_Get -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_487"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_488"
		(i != j) ->	(Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_489"
	(Sta.Dir.HeadVld = true -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_490"
	(Sta.Dir.HeadVld = false -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_491"
		(i != j) ->	(Sta.InvMsg[i].Cmd != INV_InvAck -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_492"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_493"
	(Sta.UniMsg[j].Proc != Home -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_494"
	(Sta.MemData != Sta.PrevData -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_495"
	(Sta.UniMsg[j].Cmd != UNI_GetX -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_496"
	(Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_497"
		(i != j) ->	(Sta.Proc[i].InvMarked = false -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_498"
		(i != j) ->	(Sta.Proc[i].InvMarked = true -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_499"
		(i != j) ->	(Sta.Proc[i].CacheState != CACHE_I -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_500"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_I -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_501"
		(i != j) ->	(Sta.Proc[i].ProcCmd != NODE_Get -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_502"
		(i != j) ->	(Sta.Proc[i].ProcCmd = NODE_Get -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_503"
	(Sta.UniMsg[j].Proc != Home -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_504"
	(Sta.ShWbMsg.Proc != Home -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_505"
	(Sta.ShWbMsg.Proc != j -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_506"
	(Sta.ShWbMsg.Proc = j -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_507"
		(j != i) ->	(Sta.UniMsg[j].Proc != Home -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_508"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.PrevData -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_509"
	(Sta.UniMsg[j].Cmd != UNI_Nak -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_510"
	(Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_511"
		(i != j) ->	(Sta.Proc[i].CacheState != CACHE_E -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_512"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_E -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_513"
		(i != j) ->	(Sta.UniMsg[i].Cmd != UNI_Nak -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_514"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_515"
	(Sta.UniMsg[j].Data != Sta.CurrData -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_516"
	(Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_517"
	(Sta.RpMsg[j].Cmd != RP_Replace -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_518"
	(Sta.RpMsg[j].Cmd = RP_Replace -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_519"
	(Sta.UniMsg[j].Cmd != UNI_Get -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_520"
	(Sta.UniMsg[j].Cmd = UNI_Get -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_521"
		(i != j) ->	(Sta.Proc[i].ProcCmd != NODE_None -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_522"
		(i != j) ->	(Sta.Proc[i].ProcCmd = NODE_None -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_523"
	(Sta.Proc[j].CacheData != Sta.CurrData -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_524"
	(Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_525"
	(Sta.ShWbMsg.Cmd != SHWB_FAck -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_526"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_527"
		(i != j) ->	(Sta.Proc[i].CacheState != CACHE_S -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_528"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_S -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_529"
	(Sta.Proc[j].CacheState != CACHE_E -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_530"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_531"
	(Sta.WbMsg.Cmd != WB_Wb -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_532"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_533"
		(j != i) ->	(Sta.UniMsg[j].Proc != Home -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_534"
		(i != j) ->	(Sta.UniMsg[i].Proc != Home -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_535"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_536"
	(Sta.Proc[j].CacheState = CACHE_I -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_537"
		(i != j) ->	(Sta.Dir.HeadPtr != i -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_538"
		(i != j) ->	(Sta.Dir.HeadPtr = i -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_539"
		(i != j) ->	(Sta.UniMsg[i].Cmd != UNI_Put -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_540"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_541"
		(i != j) ->	(Sta.UniMsg[i].Cmd != UNI_GetX -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_542"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_543"
	(Sta.MemData != Sta.CurrData -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_544"
	(Sta.MemData = Sta.CurrData -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_545"
	(Sta.UniMsg[j].Proc != Home -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_546"
	(Sta.ShWbMsg.Data != Sta.PrevData -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_547"
	(Sta.UniMsg[j].Proc != Home -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_548"
	(Sta.UniMsg[j].Data != Sta.PrevData -> Sta.UniMsg[j].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_549"
		(i != j) ->	(Sta.Proc[i].ProcCmd != NODE_GetX -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE do
Invariant "rule_550"
	(Sta.Proc[i].ProcCmd != NODE_GetX -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_551"
	(Sta.UniMsg[i].Cmd = UNI_Get -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_552"
		(i != j) ->	(Sta.Proc[i].ProcCmd != NODE_GetX -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_553"
	(Sta.Proc[i].ProcCmd != NODE_GetX -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_554"
		(i != j) ->	(Sta.Proc[i].ProcCmd != NODE_GetX -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_555"
	(Sta.Proc[i].ProcCmd != NODE_GetX -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_556"
	(Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_557"
	(Sta.Proc[i].ProcCmd != NODE_GetX -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_558"
	(Sta.Proc[i].InvMarked = true -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_559"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_560"
	(Sta.Proc[i].ProcCmd != NODE_GetX -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_561"
	(Sta.Proc[i].ProcCmd != NODE_GetX -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_562"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_563"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_564"
	(Sta.Proc[i].ProcCmd != NODE_GetX -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_565"
	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_566"
	(Sta.Proc[i].ProcCmd != NODE_GetX -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_567"
	(Sta.Proc[i].ProcCmd != NODE_GetX -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_568"
		(i != j) ->	(Sta.Proc[i].ProcCmd != NODE_GetX -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_569"
		(i != j) ->	(Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE do
Invariant "rule_570"
	(Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_571"
	(Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_572"
		(i != j) ->	(Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_573"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Proc[i].ProcCmd = NODE_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_574"
		(i != j) ->	(Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_575"
	(Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_576"
	(Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_577"
	(Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_578"
	(Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_579"
	(Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_580"
	(Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_581"
	(Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_582"
	(Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_583"
	(Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_584"
	(Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_585"
	(Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Proc[i].ProcCmd = NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_586"
	(Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_587"
		(i != j) ->	(Sta.Proc[i].ProcCmd = NODE_GetX -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;
Invariant "rule_588"
	(Sta.ShWbMsg.Data != Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_ShWb);


ruleset j : NODE do
Invariant "rule_589"
	(Sta.ShWbMsg.Data != Sta.CurrData -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE do
Invariant "rule_590"
	(Sta.ShWbMsg.Data != Sta.CurrData -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_591"
	(Sta.ShWbMsg.Data != Sta.CurrData -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_592"
	(Sta.ShWbMsg.Data != Sta.CurrData -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;
Invariant "rule_593"
	(Sta.ShWbMsg.Data != Sta.CurrData -> Sta.WbMsg.Data != Sta.PrevData);


ruleset j : NODE do
Invariant "rule_594"
	(Sta.ShWbMsg.Data != Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;
Invariant "rule_595"
	(Sta.ShWbMsg.Data != Sta.CurrData -> Sta.MemData != Sta.PrevData);
Invariant "rule_596"
	(Sta.ShWbMsg.Data != Sta.CurrData -> Sta.ShWbMsg.Proc != Home);


ruleset i : NODE do
Invariant "rule_597"
	(Sta.ShWbMsg.Data != Sta.CurrData -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;
Invariant "rule_598"
	(Sta.ShWbMsg.Data != Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);


ruleset j : NODE do
Invariant "rule_599"
	(Sta.ShWbMsg.Data != Sta.CurrData -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_600"
	(Sta.ShWbMsg.Data != Sta.CurrData -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_601"
	(Sta.ShWbMsg.Data != Sta.CurrData -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;
Invariant "rule_602"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.ShWbMsg.Data = Sta.CurrData);


ruleset j : NODE do
Invariant "rule_603"
	(Sta.ShWbMsg.Data = Sta.CurrData -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE do
Invariant "rule_604"
	(Sta.ShWbMsg.Data = Sta.CurrData -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_605"
	(Sta.ShWbMsg.Data = Sta.CurrData -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_606"
	(Sta.ShWbMsg.Data = Sta.CurrData -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;
Invariant "rule_607"
	(Sta.ShWbMsg.Data = Sta.CurrData -> Sta.WbMsg.Data != Sta.PrevData);


ruleset j : NODE do
Invariant "rule_608"
	(Sta.ShWbMsg.Data = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;
Invariant "rule_609"
	(Sta.ShWbMsg.Data = Sta.CurrData -> Sta.MemData != Sta.PrevData);
Invariant "rule_610"
	(Sta.ShWbMsg.Data = Sta.CurrData -> Sta.ShWbMsg.Proc != Home);


ruleset i : NODE do
Invariant "rule_611"
	(Sta.ShWbMsg.Data = Sta.CurrData -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;
Invariant "rule_612"
	(Sta.ShWbMsg.Data = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);


ruleset j : NODE do
Invariant "rule_613"
	(Sta.ShWbMsg.Data = Sta.CurrData -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_614"
	(Sta.ShWbMsg.Data = Sta.CurrData -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_615"
	(Sta.ShWbMsg.Data = Sta.CurrData -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;
Invariant "rule_616"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Dir.Local = false);


ruleset j : NODE do
Invariant "rule_617"
	(Sta.Dir.Local = false -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE do
Invariant "rule_618"
	(Sta.Dir.Local = false -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_619"
	(Sta.Dir.Local = false -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_620"
	(Sta.Dir.Local = false -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_621"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Dir.Local = false);
endruleset;


ruleset j : NODE do
Invariant "rule_622"
	(Sta.Dir.Local = false -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;
Invariant "rule_623"
	(Sta.Dir.Local = false -> Sta.WbMsg.Data != Sta.PrevData);
Invariant "rule_624"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Dir.Local = false);


ruleset j : NODE do
Invariant "rule_625"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Dir.Local = false);
endruleset;


ruleset i : NODE do
Invariant "rule_626"
	(Sta.Dir.Local = false -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;
Invariant "rule_627"
	(Sta.Dir.Local = false -> Sta.MemData != Sta.PrevData);
Invariant "rule_628"
	(Sta.Dir.Local = false -> Sta.ShWbMsg.Proc != Home);


ruleset i : NODE do
Invariant "rule_629"
	(Sta.Dir.Local = false -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_630"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Dir.Local = false);
endruleset;
Invariant "rule_631"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.Local = false);


ruleset j : NODE do
Invariant "rule_632"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Dir.Local = false);
endruleset;
Invariant "rule_633"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.Dir.Local = false);


ruleset i : NODE do
Invariant "rule_634"
	(Sta.Dir.Local = false -> Sta.UniMsg[i].Proc != Home);
endruleset;
Invariant "rule_635"
	(Sta.Dir.Local = false -> Sta.ShWbMsg.Data != Sta.PrevData);


ruleset j : NODE do
Invariant "rule_636"
	(Sta.Dir.Local = false -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;
Invariant "rule_637"
	(Sta.Dir.Local = true -> Sta.ShWbMsg.Cmd != SHWB_ShWb);


ruleset j : NODE do
Invariant "rule_638"
	(Sta.Dir.Local = true -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE do
Invariant "rule_639"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Dir.Local = true);
endruleset;


ruleset i : NODE do
Invariant "rule_640"
	(Sta.Dir.Local = true -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_641"
	(Sta.Dir.Local = true -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_642"
	(Sta.Dir.Local = true -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_643"
	(Sta.Dir.Local = true -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;
Invariant "rule_644"
	(Sta.Dir.Local = true -> Sta.WbMsg.Data != Sta.PrevData);
Invariant "rule_645"
	(Sta.Dir.Local = true -> Sta.NakcMsg.Cmd != NAKC_Nakc);


ruleset j : NODE do
Invariant "rule_646"
	(Sta.Dir.Local = true -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_647"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Dir.Local = true);
endruleset;
Invariant "rule_648"
	(Sta.Dir.Local = true -> Sta.MemData != Sta.PrevData);
Invariant "rule_649"
	(Sta.Dir.Local = true -> Sta.ShWbMsg.Proc != Home);


ruleset i : NODE do
Invariant "rule_650"
	(Sta.Dir.Local = true -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_651"
	(Sta.Dir.Local = true -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;
Invariant "rule_652"
	(Sta.Dir.Local = true -> Sta.ShWbMsg.Cmd != SHWB_FAck);


ruleset j : NODE do
Invariant "rule_653"
	(Sta.Dir.Local = true -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;
Invariant "rule_654"
	(Sta.Dir.Local = true -> Sta.WbMsg.Cmd != WB_Wb);


ruleset i : NODE do
Invariant "rule_655"
	(Sta.Dir.Local = true -> Sta.UniMsg[i].Proc != Home);
endruleset;
Invariant "rule_656"
	(Sta.Dir.Local = true -> Sta.ShWbMsg.Data != Sta.PrevData);


ruleset j : NODE do
Invariant "rule_657"
	(Sta.Dir.Local = true -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_658"
	(Sta.ShWbMsg.Cmd != SHWB_ShWb -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_659"
	(Sta.Dir.InvSet[j] = true -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset i : NODE do
Invariant "rule_660"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset i : NODE do
Invariant "rule_661"
	(Sta.ShWbMsg.Cmd != SHWB_ShWb -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;
Invariant "rule_662"
	(Sta.Dir.Pending = false -> Sta.ShWbMsg.Cmd != SHWB_ShWb);


ruleset j : NODE do
Invariant "rule_663"
	(Sta.ShWbMsg.Cmd != SHWB_ShWb -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_664"
	(Sta.Dir.InvSet[i] = true -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset i : NODE do
Invariant "rule_665"
	(Sta.ShWbMsg.Proc = i -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset i : NODE do
Invariant "rule_666"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_667"
	(Sta.ShWbMsg.Cmd != SHWB_ShWb -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;
Invariant "rule_668"
	(Sta.Dir.ShrVld = true -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
Invariant "rule_669"
	(Sta.ShWbMsg.Cmd != SHWB_ShWb -> Sta.WbMsg.Data != Sta.PrevData);
Invariant "rule_670"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.ShWbMsg.Cmd != SHWB_ShWb);


ruleset j : NODE do
Invariant "rule_671"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset i : NODE do
Invariant "rule_672"
	(Sta.UniMsg[i].Data != Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset i : NODE do
Invariant "rule_673"
	(Sta.UniMsg[i].Data = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_674"
		(i != j) ->	(Sta.UniMsg[i].Proc = j -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset i : NODE do
Invariant "rule_675"
	(Sta.Proc[i].CacheData != Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;
Invariant "rule_676"
	(Sta.Dir.HeadVld = false -> Sta.ShWbMsg.Cmd != SHWB_ShWb);


ruleset i : NODE do
Invariant "rule_677"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;
Invariant "rule_678"
	(Sta.ShWbMsg.Cmd != SHWB_ShWb -> Sta.MemData != Sta.PrevData);


ruleset i : NODE do
Invariant "rule_679"
	(Sta.Proc[i].InvMarked = true -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;
Invariant "rule_680"
	(Sta.ShWbMsg.Cmd != SHWB_ShWb -> Sta.ShWbMsg.Proc != Home);


ruleset j : NODE do
Invariant "rule_681"
	(Sta.ShWbMsg.Proc != j -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset i : NODE do
Invariant "rule_682"
	(Sta.ShWbMsg.Cmd != SHWB_ShWb -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_683"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_684"
	(Sta.UniMsg[j].Data != Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_685"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;
Invariant "rule_686"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.ShWbMsg.Cmd != SHWB_ShWb);


ruleset i : NODE do
Invariant "rule_687"
	(Sta.ShWbMsg.Cmd != SHWB_ShWb -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_688"
	(Sta.Dir.HeadPtr != i -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset i : NODE do
Invariant "rule_689"
	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;
Invariant "rule_690"
	(Sta.ShWbMsg.Cmd != SHWB_ShWb -> Sta.ShWbMsg.Data != Sta.PrevData);


ruleset j : NODE do
Invariant "rule_691"
	(Sta.ShWbMsg.Cmd != SHWB_ShWb -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_692"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_693"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_694"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_695"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;
Invariant "rule_696"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Dir.Pending = true);


ruleset j : NODE do
Invariant "rule_697"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_698"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_699"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset i : NODE do
Invariant "rule_700"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_701"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;
Invariant "rule_702"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Dir.ShrVld = false);
Invariant "rule_703"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.WbMsg.Data != Sta.PrevData);
Invariant "rule_704"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.NakcMsg.Cmd != NAKC_Nakc);


ruleset j : NODE do
Invariant "rule_705"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_706"
		(i != j) ->	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[i].Proc != j);
endruleset;
Invariant "rule_707"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Dir.HeadVld = true);


ruleset i : NODE do
Invariant "rule_708"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;
Invariant "rule_709"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.MemData != Sta.PrevData);


ruleset i : NODE do
Invariant "rule_710"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[i].InvMarked = false);
endruleset;
Invariant "rule_711"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.ShWbMsg.Proc != Home);


ruleset j : NODE do
Invariant "rule_712"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.ShWbMsg.Proc = j);
endruleset;


ruleset i : NODE do
Invariant "rule_713"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_714"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_715"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;
Invariant "rule_716"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.WbMsg.Cmd != WB_Wb);


ruleset i : NODE do
Invariant "rule_717"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_718"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Dir.HeadPtr = i);
endruleset;


ruleset i : NODE do
Invariant "rule_719"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;
Invariant "rule_720"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.ShWbMsg.Data != Sta.PrevData);


ruleset j : NODE do
Invariant "rule_721"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_722"
	(Sta.Dir.InvSet[j] = false -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_723"
	(Sta.Dir.InvSet[j] = true -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_724"
	(Sta.Proc[j].InvMarked = true -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_725"
	(Sta.Proc[j].InvMarked = false -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_726"
	(Sta.Proc[j].CacheState != CACHE_S -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_727"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_728"
		(i != j) ->	(Sta.InvMsg[i].Cmd != INV_Inv -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_729"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_730"
		(i != j) ->	(Sta.RpMsg[i].Cmd != RP_Replace -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_731"
		(i != j) ->	(Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_732"
		(j != i) ->	(Sta.Dir.HeadPtr != j -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_733"
		(i != j) ->	(Sta.UniMsg[i].Data != Sta.PrevData -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_734"
		(i != j) ->	(Sta.UniMsg[i].Cmd != UNI_Get -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_735"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_736"
	(Sta.Dir.Pending = true -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_737"
	(Sta.Dir.Pending = false -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_738"
	(Sta.Dir.HeadPtr != j -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_739"
	(Sta.InvMsg[j].Cmd != INV_Inv -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_740"
		(i != j) ->	(Sta.Dir.InvSet[i] = true -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_741"
		(i != j) ->	(Sta.Dir.InvSet[i] = false -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_742"
		(i != j) ->	(Sta.ShWbMsg.Proc != i -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_743"
		(i != j) ->	(Sta.ShWbMsg.Proc = i -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_744"
	(Sta.UniMsg[j].Cmd != UNI_Put -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_745"
	(Sta.UniMsg[j].Cmd = UNI_Put -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_746"
	(Sta.Proc[j].ProcCmd != NODE_GetX -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_747"
	(Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_748"
		(i != j) ->	(Sta.UniMsg[i].Cmd != UNI_PutX -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_749"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_750"
	(Sta.Dir.HeadPtr != j -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_751"
	(Sta.Proc[j].CacheData != Sta.PrevData -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_752"
	(Sta.Dir.ShrVld = true -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_753"
	(Sta.Dir.ShrVld = false -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_754"
	(Sta.Proc[j].ProcCmd != NODE_None -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_755"
	(Sta.Proc[j].ProcCmd = NODE_None -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_756"
	(Sta.Dir.HeadPtr != j -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_757"
	(Sta.WbMsg.Data != Sta.PrevData -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_758"
	(Sta.NakcMsg.Cmd != NAKC_Nakc -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_759"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_760"
	(Sta.WbMsg.Data != Sta.CurrData -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_761"
	(Sta.WbMsg.Data = Sta.CurrData -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_762"
	(Sta.UniMsg[j].Cmd != UNI_PutX -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_763"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_764"
		(i != j) ->	(Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_765"
		(i != j) ->	(Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_766"
		(i != j) ->	(Sta.UniMsg[i].Proc != j -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_767"
		(i != j) ->	(Sta.UniMsg[i].Proc = j -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_768"
	(Sta.Proc[j].ProcCmd != NODE_Get -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_769"
	(Sta.Proc[j].ProcCmd = NODE_Get -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_770"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_771"
		(i != j) ->	(Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_772"
	(Sta.Dir.HeadVld = true -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_773"
	(Sta.Dir.HeadVld = false -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_774"
		(i != j) ->	(Sta.InvMsg[i].Cmd != INV_InvAck -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_775"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_776"
	(Sta.Dir.HeadPtr != j -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_777"
	(Sta.MemData != Sta.PrevData -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_778"
	(Sta.UniMsg[j].Cmd != UNI_GetX -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_779"
	(Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_780"
		(i != j) ->	(Sta.Proc[i].InvMarked = false -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_781"
		(i != j) ->	(Sta.Proc[i].InvMarked = true -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_782"
		(i != j) ->	(Sta.Proc[i].CacheState != CACHE_I -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_783"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_I -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_784"
		(i != j) ->	(Sta.Proc[i].ProcCmd != NODE_Get -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_785"
		(i != j) ->	(Sta.Proc[i].ProcCmd = NODE_Get -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_786"
	(Sta.Dir.HeadPtr != j -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_787"
	(Sta.ShWbMsg.Proc != Home -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_788"
	(Sta.ShWbMsg.Proc != j -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_789"
	(Sta.ShWbMsg.Proc = j -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_790"
		(j != i) ->	(Sta.Dir.HeadPtr != j -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_791"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.PrevData -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_792"
	(Sta.UniMsg[j].Cmd != UNI_Nak -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_793"
	(Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_794"
		(i != j) ->	(Sta.Proc[i].CacheState != CACHE_E -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_795"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_796"
		(i != j) ->	(Sta.UniMsg[i].Cmd != UNI_Nak -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_797"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_798"
	(Sta.UniMsg[j].Data != Sta.CurrData -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_799"
	(Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_800"
	(Sta.RpMsg[j].Cmd != RP_Replace -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_801"
	(Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_802"
	(Sta.UniMsg[j].Cmd != UNI_Get -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_803"
	(Sta.UniMsg[j].Cmd = UNI_Get -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_804"
		(i != j) ->	(Sta.Proc[i].ProcCmd != NODE_None -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_805"
		(i != j) ->	(Sta.Proc[i].ProcCmd = NODE_None -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_806"
	(Sta.Proc[j].CacheData != Sta.CurrData -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_807"
	(Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_808"
	(Sta.ShWbMsg.Cmd != SHWB_FAck -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_809"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_810"
		(i != j) ->	(Sta.Proc[i].CacheState != CACHE_S -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_811"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_S -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_812"
	(Sta.Proc[j].CacheState != CACHE_E -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_813"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_814"
	(Sta.WbMsg.Cmd != WB_Wb -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_815"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_816"
		(j != i) ->	(Sta.UniMsg[j].Proc != i -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_817"
		(j != i) ->	(Sta.UniMsg[j].Proc = i -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_818"
		(j != i) ->	(Sta.Dir.HeadPtr != j -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_819"
		(i != j) ->	(Sta.UniMsg[i].Proc != Home -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_820"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_821"
	(Sta.Proc[j].CacheState = CACHE_I -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_822"
		(i != j) ->	(Sta.UniMsg[i].Cmd != UNI_Put -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_823"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_824"
		(i != j) ->	(Sta.UniMsg[i].Cmd != UNI_GetX -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_825"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_826"
	(Sta.MemData != Sta.CurrData -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_827"
	(Sta.MemData = Sta.CurrData -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_828"
	(Sta.Dir.HeadPtr != j -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_829"
	(Sta.ShWbMsg.Data != Sta.PrevData -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset j : NODE do
Invariant "rule_830"
	(Sta.Dir.HeadPtr != j -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_831"
	(Sta.UniMsg[j].Data != Sta.PrevData -> Sta.Dir.HeadPtr != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_832"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_833"
		(j != i) ->	(Sta.Dir.InvSet[j] = false -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_834"
	(Sta.Dir.Pending = true -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_835"
	(Sta.Dir.InvSet[j] = false -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_836"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_837"
	(Sta.Dir.InvSet[j] = false -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_838"
	(Sta.Dir.ShrVld = false -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_839"
	(Sta.Dir.InvSet[j] = false -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_840"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_841"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_842"
		(i != j) ->	(Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_843"
		(i != j) ->	(Sta.UniMsg[i].Proc = j -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_844"
	(Sta.Dir.HeadVld = false -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_845"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_846"
	(Sta.Dir.InvSet[j] = false -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_847"
	(Sta.Dir.InvSet[j] = false -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_848"
		(j != i) ->	(Sta.Dir.InvSet[j] = false -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_849"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_850"
	(Sta.UniMsg[j].Data != Sta.CurrData -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_851"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_852"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_853"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_854"
		(j != i) ->	(Sta.Dir.InvSet[j] = false -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_855"
		(i != j) ->	(Sta.Dir.HeadPtr != i -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_856"
	(Sta.MemData != Sta.CurrData -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_857"
	(Sta.Dir.InvSet[j] = false -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_858"
	(Sta.Dir.InvSet[j] = false -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_859"
		(j != i) ->	(Sta.Dir.InvSet[j] = true -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_860"
		(j != i) ->	(Sta.Dir.InvSet[j] = true -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_861"
	(Sta.Dir.InvSet[j] = true -> Sta.Dir.Pending = false);
endruleset;


ruleset j : NODE do
Invariant "rule_862"
	(Sta.Dir.InvSet[j] = true -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_863"
		(j != i) ->	(Sta.Dir.InvSet[j] = true -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_864"
	(Sta.Dir.InvSet[j] = true -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_865"
	(Sta.Dir.InvSet[j] = true -> Sta.Dir.ShrVld = true);
endruleset;


ruleset j : NODE do
Invariant "rule_866"
	(Sta.Dir.InvSet[j] = true -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_867"
	(Sta.Dir.InvSet[j] = true -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE do
Invariant "rule_868"
	(Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_869"
		(j != i) ->	(Sta.Dir.InvSet[j] = true -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE do
Invariant "rule_870"
	(Sta.Dir.InvSet[j] = true -> Sta.Dir.HeadVld = true);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_871"
		(j != i) ->	(Sta.Dir.InvSet[j] = true -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_872"
	(Sta.Dir.InvSet[j] = true -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_873"
	(Sta.Dir.InvSet[j] = true -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_874"
		(j != i) ->	(Sta.Dir.InvSet[j] = true -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_875"
		(j != i) ->	(Sta.Dir.InvSet[j] = true -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_876"
	(Sta.Dir.InvSet[j] = true -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_877"
	(Sta.Dir.InvSet[j] = true -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_878"
	(Sta.Dir.InvSet[j] = true -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_879"
		(j != i) ->	(Sta.Dir.InvSet[j] = true -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_880"
		(j != i) ->	(Sta.Dir.InvSet[j] = true -> Sta.Dir.HeadPtr = i);
endruleset;


ruleset j : NODE do
Invariant "rule_881"
	(Sta.Dir.InvSet[j] = true -> Sta.MemData = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_882"
	(Sta.Dir.InvSet[j] = true -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_883"
	(Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_884"
	(Sta.Proc[j].InvMarked = true -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_885"
		(j != i) ->	(Sta.Proc[j].InvMarked = true -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_886"
	(Sta.Proc[j].InvMarked = true -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_887"
	(Sta.Proc[j].InvMarked = true -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_888"
	(Sta.Proc[j].InvMarked = true -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_889"
	(Sta.Proc[j].InvMarked = true -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_890"
	(Sta.Proc[j].InvMarked = true -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_891"
	(Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_892"
	(Sta.Proc[j].InvMarked = true -> Sta.Proc[j].ProcCmd = NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_893"
	(Sta.Proc[j].InvMarked = true -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_894"
	(Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_895"
	(Sta.Proc[j].InvMarked = true -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_896"
		(j != i) ->	(Sta.Proc[j].InvMarked = true -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_897"
	(Sta.Proc[j].InvMarked = true -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_898"
	(Sta.Proc[j].InvMarked = true -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_899"
		(j != i) ->	(Sta.Proc[j].InvMarked = true -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_900"
	(Sta.Proc[j].InvMarked = true -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_901"
	(Sta.Proc[j].InvMarked = true -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_902"
	(Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_903"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_904"
		(j != i) ->	(Sta.Proc[j].InvMarked = false -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_905"
	(Sta.Proc[j].InvMarked = false -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_906"
	(Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_907"
	(Sta.Proc[j].InvMarked = false -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_908"
	(Sta.Proc[j].ProcCmd = NODE_None -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_909"
	(Sta.Proc[j].InvMarked = false -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_910"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_911"
	(Sta.Proc[j].ProcCmd != NODE_Get -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_912"
	(Sta.Proc[j].InvMarked = false -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_913"
	(Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_914"
	(Sta.Proc[j].InvMarked = false -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_915"
		(j != i) ->	(Sta.Proc[j].InvMarked = false -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_916"
	(Sta.Proc[j].CacheData != Sta.CurrData -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_917"
	(Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_918"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_919"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_920"
		(j != i) ->	(Sta.Proc[j].InvMarked = false -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_921"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_922"
	(Sta.Proc[j].InvMarked = false -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_923"
	(Sta.Proc[j].InvMarked = false -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_924"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_S -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_925"
	(Sta.Proc[j].CacheState != CACHE_S -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_926"
	(Sta.UniMsg[j].Cmd = UNI_Put -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_927"
	(Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_928"
	(Sta.Proc[j].CacheState != CACHE_S -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_929"
	(Sta.Proc[j].ProcCmd != NODE_None -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_930"
	(Sta.Proc[j].CacheState != CACHE_S -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_931"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_932"
	(Sta.Proc[j].ProcCmd = NODE_Get -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_933"
	(Sta.Proc[j].CacheState != CACHE_S -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_934"
	(Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_935"
	(Sta.Proc[j].CacheState != CACHE_S -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_936"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_S -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_937"
	(Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_938"
	(Sta.UniMsg[j].Data != Sta.CurrData -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_939"
	(Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_940"
	(Sta.UniMsg[j].Cmd = UNI_Get -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_941"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_942"
		(j != i) ->	(Sta.UniMsg[j].Proc = i -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_943"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_S -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_944"
	(Sta.Proc[j].CacheState != CACHE_S -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_945"
	(Sta.Proc[j].CacheState != CACHE_S -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_946"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_947"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_948"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_949"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_950"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_951"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.Proc[j].ProcCmd = NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_952"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_953"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_954"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_955"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_956"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_957"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_958"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_959"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_960"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_961"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_962"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_963"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_964"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_965"
	(Sta.Proc[j].CacheState = CACHE_S -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_966"
	(Sta.InvMsg[i].Cmd != INV_Inv -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_967"
	(Sta.Dir.Pending = false -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_968"
		(i != j) ->	(Sta.InvMsg[i].Cmd != INV_Inv -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_969"
	(Sta.Dir.InvSet[i] = false -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_970"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_971"
		(i != j) ->	(Sta.InvMsg[i].Cmd != INV_Inv -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_972"
	(Sta.Dir.ShrVld = true -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_973"
	(Sta.InvMsg[i].Cmd != INV_Inv -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_974"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_975"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_976"
		(i != j) ->	(Sta.UniMsg[i].Proc = j -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_977"
	(Sta.Dir.HeadVld = true -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_978"
	(Sta.InvMsg[i].Cmd != INV_Inv -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_979"
	(Sta.InvMsg[i].Cmd != INV_Inv -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_980"
	(Sta.InvMsg[i].Cmd != INV_Inv -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_981"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_982"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_983"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_E -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_984"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_985"
	(Sta.InvMsg[i].Cmd != INV_Inv -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_986"
	(Sta.Dir.HeadPtr != i -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_987"
	(Sta.InvMsg[i].Cmd != INV_Inv -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_988"
		(i != j) ->	(Sta.InvMsg[i].Cmd != INV_Inv -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_989"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_990"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Dir.Pending = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_991"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_992"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Dir.InvSet[i] = true);
endruleset;


ruleset i : NODE do
Invariant "rule_993"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_994"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_995"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_996"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_997"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_998"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_999"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE do
Invariant "rule_1000"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1001"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1002"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_1003"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1004"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_1005"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1006"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_1007"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset i : NODE do
Invariant "rule_1008"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_1009"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Dir.HeadPtr = i);
endruleset;


ruleset i : NODE do
Invariant "rule_1010"
	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1011"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1012"
	(Sta.RpMsg[i].Cmd != RP_Replace -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1013"
		(i != j) ->	(Sta.RpMsg[i].Cmd != RP_Replace -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1014"
		(i != j) ->	(Sta.RpMsg[i].Cmd != RP_Replace -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1015"
	(Sta.RpMsg[i].Cmd != RP_Replace -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1016"
	(Sta.UniMsg[i].Data != Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_1017"
	(Sta.RpMsg[i].Cmd != RP_Replace -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1018"
	(Sta.RpMsg[i].Cmd != RP_Replace -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_1019"
	(Sta.RpMsg[i].Cmd != RP_Replace -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1020"
	(Sta.RpMsg[i].Cmd != RP_Replace -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_1021"
	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_1022"
	(Sta.RpMsg[i].Cmd != RP_Replace -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1023"
		(i != j) ->	(Sta.RpMsg[i].Cmd != RP_Replace -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1024"
	(Sta.RpMsg[i].Cmd = RP_Replace -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1025"
		(i != j) ->	(Sta.RpMsg[i].Cmd = RP_Replace -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1026"
		(i != j) ->	(Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1027"
	(Sta.RpMsg[i].Cmd = RP_Replace -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1028"
	(Sta.RpMsg[i].Cmd = RP_Replace -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1029"
	(Sta.RpMsg[i].Cmd = RP_Replace -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_1030"
	(Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1031"
	(Sta.RpMsg[i].Cmd = RP_Replace -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_1032"
	(Sta.RpMsg[i].Cmd = RP_Replace -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_1033"
	(Sta.RpMsg[i].Cmd = RP_Replace -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1034"
		(i != j) ->	(Sta.RpMsg[i].Cmd = RP_Replace -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1035"
	(Sta.UniMsg[i].Cmd != UNI_Get -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1036"
	(Sta.UniMsg[i].Cmd = UNI_Get -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1037"
	(Sta.Dir.Pending = true -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1038"
	(Sta.Dir.Pending = false -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1039"
		(j != i) ->	(Sta.InvMsg[j].Cmd != INV_Inv -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1040"
		(i != j) ->	(Sta.UniMsg[i].Data != Sta.PrevData -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_1041"
	(Sta.Dir.InvSet[i] = true -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1042"
	(Sta.Dir.InvSet[i] = false -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1043"
	(Sta.ShWbMsg.Proc != i -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1044"
	(Sta.ShWbMsg.Proc = i -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1045"
		(j != i) ->	(Sta.UniMsg[j].Cmd != UNI_Put -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1046"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Put -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1047"
		(j != i) ->	(Sta.Proc[j].ProcCmd != NODE_GetX -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1048"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1049"
	(Sta.UniMsg[i].Cmd != UNI_PutX -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1050"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1051"
		(j != i) ->	(Sta.Proc[j].CacheData != Sta.PrevData -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1052"
		(i != j) ->	(Sta.UniMsg[i].Data != Sta.PrevData -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1053"
	(Sta.Dir.ShrVld = true -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1054"
	(Sta.Dir.ShrVld = false -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1055"
		(j != i) ->	(Sta.Proc[j].ProcCmd != NODE_None -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1056"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_None -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1057"
	(Sta.WbMsg.Data != Sta.PrevData -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1058"
	(Sta.UniMsg[i].Data != Sta.PrevData -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1059"
	(Sta.NakcMsg.Cmd != NAKC_Nakc -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1060"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1061"
	(Sta.WbMsg.Data != Sta.CurrData -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1062"
	(Sta.WbMsg.Data = Sta.CurrData -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1063"
		(j != i) ->	(Sta.UniMsg[j].Cmd != UNI_PutX -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1064"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1065"
		(i != j) ->	(Sta.UniMsg[i].Proc != j -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1066"
		(i != j) ->	(Sta.UniMsg[i].Proc = j -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1067"
		(j != i) ->	(Sta.Proc[j].ProcCmd != NODE_Get -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1068"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_Get -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1069"
	(Sta.Proc[i].CacheData != Sta.CurrData -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1070"
	(Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1071"
	(Sta.Dir.HeadVld = true -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1072"
	(Sta.Dir.HeadVld = false -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1073"
	(Sta.InvMsg[i].Cmd != INV_InvAck -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1074"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1075"
	(Sta.MemData != Sta.PrevData -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1076"
	(Sta.UniMsg[i].Data != Sta.PrevData -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1077"
		(j != i) ->	(Sta.UniMsg[j].Cmd != UNI_GetX -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1078"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1079"
	(Sta.Proc[i].InvMarked = false -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1080"
	(Sta.Proc[i].InvMarked = true -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1081"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1082"
	(Sta.Proc[i].CacheState = CACHE_I -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1083"
	(Sta.Proc[i].ProcCmd != NODE_Get -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1084"
	(Sta.Proc[i].ProcCmd = NODE_Get -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1085"
	(Sta.ShWbMsg.Proc != Home -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1086"
	(Sta.UniMsg[i].Data != Sta.PrevData -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1087"
		(j != i) ->	(Sta.ShWbMsg.Proc != j -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1088"
		(j != i) ->	(Sta.ShWbMsg.Proc = j -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1089"
	(Sta.Proc[i].CacheData != Sta.PrevData -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1090"
	(Sta.UniMsg[i].Data != Sta.PrevData -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1091"
		(j != i) ->	(Sta.UniMsg[j].Cmd != UNI_Nak -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1092"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1093"
	(Sta.Proc[i].CacheState != CACHE_E -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1094"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1095"
	(Sta.UniMsg[i].Cmd != UNI_Nak -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1096"
	(Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1097"
		(j != i) ->	(Sta.UniMsg[j].Data != Sta.CurrData -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1098"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1099"
		(j != i) ->	(Sta.RpMsg[j].Cmd != RP_Replace -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1100"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1101"
		(j != i) ->	(Sta.UniMsg[j].Cmd != UNI_Get -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1102"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1103"
	(Sta.Proc[i].ProcCmd != NODE_None -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1104"
	(Sta.Proc[i].ProcCmd = NODE_None -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1105"
		(j != i) ->	(Sta.Proc[j].CacheData != Sta.CurrData -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1106"
		(j != i) ->	(Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1107"
	(Sta.ShWbMsg.Cmd != SHWB_FAck -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1108"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1109"
	(Sta.Proc[i].CacheState != CACHE_S -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1110"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1111"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_E -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1112"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_E -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1113"
	(Sta.WbMsg.Cmd != WB_Wb -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1114"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1115"
		(j != i) ->	(Sta.UniMsg[j].Proc != i -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1116"
		(j != i) ->	(Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1117"
	(Sta.UniMsg[i].Proc != Home -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1118"
	(Sta.UniMsg[i].Data != Sta.PrevData -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1119"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_I -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1120"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_I -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1121"
	(Sta.Dir.HeadPtr != i -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1122"
	(Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1123"
	(Sta.UniMsg[i].Cmd != UNI_Put -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1124"
	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1125"
	(Sta.UniMsg[i].Cmd != UNI_GetX -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1126"
	(Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1127"
	(Sta.MemData != Sta.CurrData -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1128"
	(Sta.MemData = Sta.CurrData -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1129"
	(Sta.ShWbMsg.Data != Sta.PrevData -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1130"
	(Sta.UniMsg[i].Data != Sta.PrevData -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1131"
		(j != i) ->	(Sta.UniMsg[j].Data != Sta.PrevData -> Sta.UniMsg[i].Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1132"
		(i != j) ->	(Sta.UniMsg[i].Data != Sta.PrevData -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1133"
		(i != j) ->	(Sta.UniMsg[i].Cmd != UNI_Get -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1134"
		(i != j) ->	(Sta.UniMsg[i].Cmd != UNI_Get -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1135"
	(Sta.UniMsg[i].Cmd != UNI_Get -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1136"
	(Sta.UniMsg[i].Data != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_1137"
	(Sta.UniMsg[i].Data = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_1138"
	(Sta.UniMsg[i].Cmd != UNI_Get -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1139"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_1140"
	(Sta.Proc[i].ProcCmd != NODE_Get -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_1141"
	(Sta.UniMsg[i].Cmd != UNI_Get -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_1142"
	(Sta.UniMsg[i].Cmd != UNI_Get -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1143"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_1144"
	(Sta.Proc[i].ProcCmd = NODE_None -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_1145"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_1146"
	(Sta.UniMsg[i].Cmd != UNI_Get -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_1147"
	(Sta.UniMsg[i].Cmd != UNI_Get -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1148"
		(i != j) ->	(Sta.UniMsg[i].Cmd != UNI_Get -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1149"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1150"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1151"
	(Sta.UniMsg[i].Cmd = UNI_Get -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1152"
	(Sta.UniMsg[i].Cmd = UNI_Get -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1153"
	(Sta.UniMsg[i].Cmd = UNI_Get -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_1154"
	(Sta.UniMsg[i].Cmd = UNI_Get -> Sta.Proc[i].ProcCmd = NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_1155"
	(Sta.UniMsg[i].Cmd = UNI_Get -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_1156"
	(Sta.UniMsg[i].Cmd = UNI_Get -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1157"
	(Sta.UniMsg[i].Cmd = UNI_Get -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_1158"
	(Sta.UniMsg[i].Cmd = UNI_Get -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_1159"
	(Sta.UniMsg[i].Cmd = UNI_Get -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_1160"
	(Sta.UniMsg[i].Cmd = UNI_Get -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_1161"
	(Sta.UniMsg[i].Cmd = UNI_Get -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1162"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1163"
	(Sta.Dir.Pending = true -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_1164"
	(Sta.Dir.Pending = true -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;
Invariant "rule_1165"
	(Sta.Dir.Pending = true -> Sta.Dir.ShrVld = false);
Invariant "rule_1166"
	(Sta.Dir.Pending = true -> Sta.WbMsg.Data != Sta.PrevData);
Invariant "rule_1167"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Dir.Pending = true);


ruleset j : NODE do
Invariant "rule_1168"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Dir.Pending = true);
endruleset;


ruleset i : NODE do
Invariant "rule_1169"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Dir.Pending = true);
endruleset;
Invariant "rule_1170"
	(Sta.Dir.Pending = true -> Sta.MemData != Sta.PrevData);
Invariant "rule_1171"
	(Sta.Dir.Pending = true -> Sta.ShWbMsg.Proc != Home);


ruleset i : NODE do
Invariant "rule_1172"
	(Sta.Dir.Pending = true -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;
Invariant "rule_1173"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.Pending = true);


ruleset j : NODE do
Invariant "rule_1174"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Dir.Pending = true);
endruleset;


ruleset i : NODE do
Invariant "rule_1175"
	(Sta.Dir.Pending = true -> Sta.UniMsg[i].Proc != Home);
endruleset;
Invariant "rule_1176"
	(Sta.Dir.Pending = true -> Sta.ShWbMsg.Data != Sta.PrevData);


ruleset j : NODE do
Invariant "rule_1177"
	(Sta.Dir.Pending = true -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1178"
	(Sta.Dir.Pending = false -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_1179"
	(Sta.Dir.Pending = false -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;
Invariant "rule_1180"
	(Sta.Dir.ShrVld = true -> Sta.Dir.Pending = false);
Invariant "rule_1181"
	(Sta.Dir.Pending = false -> Sta.WbMsg.Data != Sta.PrevData);
Invariant "rule_1182"
	(Sta.Dir.Pending = false -> Sta.NakcMsg.Cmd != NAKC_Nakc);


ruleset j : NODE do
Invariant "rule_1183"
	(Sta.Dir.Pending = false -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_1184"
	(Sta.Dir.Pending = false -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;
Invariant "rule_1185"
	(Sta.Dir.Pending = false -> Sta.MemData != Sta.PrevData);
Invariant "rule_1186"
	(Sta.Dir.Pending = false -> Sta.ShWbMsg.Proc != Home);


ruleset i : NODE do
Invariant "rule_1187"
	(Sta.Dir.Pending = false -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;
Invariant "rule_1188"
	(Sta.Dir.Pending = false -> Sta.ShWbMsg.Cmd != SHWB_FAck);


ruleset j : NODE do
Invariant "rule_1189"
	(Sta.Dir.Pending = false -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_1190"
	(Sta.Dir.Pending = false -> Sta.UniMsg[i].Proc != Home);
endruleset;
Invariant "rule_1191"
	(Sta.Dir.Pending = false -> Sta.ShWbMsg.Data != Sta.PrevData);


ruleset j : NODE do
Invariant "rule_1192"
	(Sta.Dir.Pending = false -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1193"
		(i != j) ->	(Sta.Dir.InvSet[i] = true -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1194"
		(i != j) ->	(Sta.Dir.InvSet[i] = false -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1195"
		(i != j) ->	(Sta.ShWbMsg.Proc != i -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1196"
		(i != j) ->	(Sta.ShWbMsg.Proc = i -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_1197"
	(Sta.UniMsg[j].Cmd != UNI_Put -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_1198"
	(Sta.UniMsg[j].Cmd = UNI_Put -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_1199"
	(Sta.Proc[j].ProcCmd != NODE_GetX -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_1200"
	(Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1201"
		(i != j) ->	(Sta.UniMsg[i].Cmd != UNI_PutX -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1202"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_1203"
	(Sta.InvMsg[j].Cmd != INV_Inv -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1204"
	(Sta.Proc[j].CacheData != Sta.PrevData -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_1205"
	(Sta.Dir.ShrVld = true -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_1206"
	(Sta.Dir.ShrVld = false -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_1207"
	(Sta.Proc[j].ProcCmd != NODE_None -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_1208"
	(Sta.Proc[j].ProcCmd = NODE_None -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_1209"
	(Sta.WbMsg.Data != Sta.PrevData -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_1210"
	(Sta.InvMsg[j].Cmd != INV_Inv -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1211"
	(Sta.NakcMsg.Cmd != NAKC_Nakc -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_1212"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_1213"
	(Sta.WbMsg.Data != Sta.CurrData -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_1214"
	(Sta.WbMsg.Data = Sta.CurrData -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_1215"
	(Sta.UniMsg[j].Cmd != UNI_PutX -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_1216"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1217"
		(i != j) ->	(Sta.UniMsg[i].Data != Sta.CurrData -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1218"
		(i != j) ->	(Sta.UniMsg[i].Data = Sta.CurrData -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1219"
		(i != j) ->	(Sta.UniMsg[i].Proc != j -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1220"
		(i != j) ->	(Sta.UniMsg[i].Proc = j -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_1221"
	(Sta.Proc[j].ProcCmd != NODE_Get -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_1222"
	(Sta.Proc[j].ProcCmd = NODE_Get -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1223"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1224"
		(i != j) ->	(Sta.Proc[i].CacheData = Sta.CurrData -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_1225"
	(Sta.Dir.HeadVld = true -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_1226"
	(Sta.Dir.HeadVld = false -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1227"
		(i != j) ->	(Sta.InvMsg[i].Cmd != INV_InvAck -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1228"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_1229"
	(Sta.InvMsg[j].Cmd != INV_Inv -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1230"
	(Sta.MemData != Sta.PrevData -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_1231"
	(Sta.UniMsg[j].Cmd != UNI_GetX -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_1232"
	(Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1233"
		(i != j) ->	(Sta.Proc[i].InvMarked = false -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1234"
		(i != j) ->	(Sta.Proc[i].InvMarked = true -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1235"
		(i != j) ->	(Sta.Proc[i].CacheState != CACHE_I -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1236"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_I -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1237"
		(i != j) ->	(Sta.Proc[i].ProcCmd != NODE_Get -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1238"
		(i != j) ->	(Sta.Proc[i].ProcCmd = NODE_Get -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_1239"
	(Sta.InvMsg[j].Cmd != INV_Inv -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_1240"
	(Sta.ShWbMsg.Proc != Home -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_1241"
	(Sta.ShWbMsg.Proc != j -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_1242"
	(Sta.ShWbMsg.Proc = j -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1243"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.PrevData -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1244"
		(j != i) ->	(Sta.InvMsg[j].Cmd != INV_Inv -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1245"
	(Sta.UniMsg[j].Cmd != UNI_Nak -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_1246"
	(Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1247"
		(i != j) ->	(Sta.Proc[i].CacheState != CACHE_E -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1248"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_E -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1249"
		(i != j) ->	(Sta.UniMsg[i].Cmd != UNI_Nak -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1250"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_1251"
	(Sta.UniMsg[j].Data != Sta.CurrData -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_1252"
	(Sta.UniMsg[j].Data = Sta.CurrData -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_1253"
	(Sta.RpMsg[j].Cmd != RP_Replace -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_1254"
	(Sta.RpMsg[j].Cmd = RP_Replace -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_1255"
	(Sta.UniMsg[j].Cmd != UNI_Get -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_1256"
	(Sta.UniMsg[j].Cmd = UNI_Get -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1257"
		(i != j) ->	(Sta.Proc[i].ProcCmd != NODE_None -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1258"
		(i != j) ->	(Sta.Proc[i].ProcCmd = NODE_None -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_1259"
	(Sta.Proc[j].CacheData != Sta.CurrData -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_1260"
	(Sta.Proc[j].CacheData = Sta.CurrData -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_1261"
	(Sta.ShWbMsg.Cmd != SHWB_FAck -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_1262"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1263"
		(i != j) ->	(Sta.Proc[i].CacheState != CACHE_S -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1264"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_S -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_1265"
	(Sta.Proc[j].CacheState != CACHE_E -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_1266"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_1267"
	(Sta.WbMsg.Cmd != WB_Wb -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_1268"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1269"
		(j != i) ->	(Sta.UniMsg[j].Proc != i -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1270"
		(j != i) ->	(Sta.UniMsg[j].Proc = i -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1271"
		(i != j) ->	(Sta.UniMsg[i].Proc != Home -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1272"
		(j != i) ->	(Sta.InvMsg[j].Cmd != INV_Inv -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_1273"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_1274"
	(Sta.Proc[j].CacheState = CACHE_I -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1275"
		(i != j) ->	(Sta.Dir.HeadPtr != i -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1276"
		(i != j) ->	(Sta.Dir.HeadPtr = i -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1277"
		(i != j) ->	(Sta.UniMsg[i].Cmd != UNI_Put -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1278"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1279"
		(i != j) ->	(Sta.UniMsg[i].Cmd != UNI_GetX -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1280"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_1281"
	(Sta.MemData != Sta.CurrData -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_1282"
	(Sta.MemData = Sta.CurrData -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_1283"
	(Sta.InvMsg[j].Cmd != INV_Inv -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1284"
	(Sta.ShWbMsg.Data != Sta.PrevData -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset j : NODE do
Invariant "rule_1285"
	(Sta.InvMsg[j].Cmd != INV_Inv -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1286"
	(Sta.UniMsg[j].Data != Sta.PrevData -> Sta.InvMsg[j].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_1287"
	(Sta.Dir.InvSet[i] = true -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1288"
		(i != j) ->	(Sta.Dir.InvSet[i] = true -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1289"
	(Sta.Dir.InvSet[i] = true -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1290"
	(Sta.Dir.InvSet[i] = true -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1291"
		(i != j) ->	(Sta.Dir.InvSet[i] = true -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1292"
		(i != j) ->	(Sta.Dir.InvSet[i] = true -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE do
Invariant "rule_1293"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Dir.InvSet[i] = true);
endruleset;


ruleset i : NODE do
Invariant "rule_1294"
	(Sta.Dir.InvSet[i] = true -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1295"
	(Sta.Dir.InvSet[i] = true -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_1296"
	(Sta.Dir.InvSet[i] = true -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1297"
	(Sta.Dir.InvSet[i] = true -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_1298"
	(Sta.Dir.InvSet[i] = true -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1299"
		(i != j) ->	(Sta.Dir.InvSet[i] = true -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_1300"
	(Sta.Dir.InvSet[i] = true -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset i : NODE do
Invariant "rule_1301"
	(Sta.Dir.InvSet[i] = true -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_1302"
	(Sta.Dir.InvSet[i] = true -> Sta.Dir.HeadPtr = i);
endruleset;


ruleset i : NODE do
Invariant "rule_1303"
	(Sta.Dir.InvSet[i] = true -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1304"
		(i != j) ->	(Sta.Dir.InvSet[i] = true -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1305"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1306"
		(i != j) ->	(Sta.Dir.InvSet[i] = false -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1307"
	(Sta.Dir.InvSet[i] = false -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1308"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1309"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1310"
		(i != j) ->	(Sta.UniMsg[i].Proc = j -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1311"
	(Sta.Dir.InvSet[i] = false -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_1312"
	(Sta.Dir.InvSet[i] = false -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1313"
	(Sta.Dir.InvSet[i] = false -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_1314"
	(Sta.Dir.InvSet[i] = false -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1315"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1316"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1317"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1318"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1319"
	(Sta.Dir.InvSet[i] = false -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_1320"
	(Sta.Dir.HeadPtr != i -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1321"
	(Sta.Dir.InvSet[i] = false -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1322"
		(i != j) ->	(Sta.Dir.InvSet[i] = false -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1323"
		(i != j) ->	(Sta.ShWbMsg.Proc != i -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1324"
	(Sta.ShWbMsg.Proc != i -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1325"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset i : NODE do
Invariant "rule_1326"
	(Sta.ShWbMsg.Proc != i -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1327"
	(Sta.ShWbMsg.Proc != i -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1328"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_E -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset i : NODE do
Invariant "rule_1329"
	(Sta.ShWbMsg.Proc != i -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_1330"
	(Sta.ShWbMsg.Proc != i -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1331"
		(i != j) ->	(Sta.ShWbMsg.Proc != i -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1332"
		(i != j) ->	(Sta.ShWbMsg.Proc = i -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1333"
	(Sta.ShWbMsg.Proc = i -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1334"
		(i != j) ->	(Sta.ShWbMsg.Proc = i -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_1335"
	(Sta.ShWbMsg.Proc = i -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1336"
	(Sta.ShWbMsg.Proc = i -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1337"
		(i != j) ->	(Sta.ShWbMsg.Proc = i -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_1338"
	(Sta.ShWbMsg.Proc = i -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_1339"
	(Sta.ShWbMsg.Proc = i -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1340"
		(i != j) ->	(Sta.ShWbMsg.Proc = i -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1341"
	(Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_1342"
	(Sta.UniMsg[j].Cmd != UNI_Put -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1343"
	(Sta.Proc[j].ProcCmd = NODE_None -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_1344"
	(Sta.UniMsg[j].Cmd != UNI_Put -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1345"
	(Sta.Proc[j].ProcCmd != NODE_Get -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_1346"
	(Sta.UniMsg[j].Cmd != UNI_Put -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1347"
	(Sta.UniMsg[j].Cmd != UNI_Put -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1348"
		(j != i) ->	(Sta.UniMsg[j].Cmd != UNI_Put -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1349"
	(Sta.RpMsg[j].Cmd = RP_Replace -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_1350"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_1351"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1352"
		(j != i) ->	(Sta.UniMsg[j].Cmd != UNI_Put -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_1353"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_1354"
	(Sta.UniMsg[j].Cmd != UNI_Put -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1355"
	(Sta.UniMsg[j].Cmd != UNI_Put -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1356"
	(Sta.UniMsg[j].Cmd = UNI_Put -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_1357"
	(Sta.UniMsg[j].Cmd = UNI_Put -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1358"
	(Sta.UniMsg[j].Cmd = UNI_Put -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_1359"
	(Sta.UniMsg[j].Cmd = UNI_Put -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1360"
	(Sta.UniMsg[j].Cmd = UNI_Put -> Sta.Proc[j].ProcCmd = NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_1361"
	(Sta.UniMsg[j].Cmd = UNI_Put -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1362"
	(Sta.UniMsg[j].Cmd = UNI_Put -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1363"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Put -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1364"
	(Sta.UniMsg[j].Cmd = UNI_Put -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_1365"
	(Sta.UniMsg[j].Cmd = UNI_Put -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1366"
	(Sta.UniMsg[j].Cmd = UNI_Put -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1367"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Put -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_1368"
	(Sta.UniMsg[j].Cmd = UNI_Put -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_1369"
	(Sta.UniMsg[j].Cmd = UNI_Put -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1370"
	(Sta.UniMsg[j].Cmd = UNI_Put -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1371"
	(Sta.Proc[j].ProcCmd != NODE_GetX -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1372"
	(Sta.Proc[j].ProcCmd != NODE_GetX -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1373"
	(Sta.Proc[j].ProcCmd != NODE_GetX -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_1374"
	(Sta.Proc[j].ProcCmd != NODE_GetX -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1375"
	(Sta.Proc[j].ProcCmd != NODE_GetX -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_1376"
	(Sta.Proc[j].ProcCmd != NODE_GetX -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1377"
		(j != i) ->	(Sta.Proc[j].ProcCmd != NODE_GetX -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1378"
	(Sta.UniMsg[j].Data != Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_1379"
	(Sta.UniMsg[j].Cmd = UNI_Get -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_1380"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1381"
		(j != i) ->	(Sta.Proc[j].ProcCmd != NODE_GetX -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_1382"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_1383"
	(Sta.Proc[j].ProcCmd != NODE_GetX -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1384"
	(Sta.Proc[j].ProcCmd != NODE_GetX -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1385"
	(Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1386"
	(Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1387"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Proc[j].ProcCmd = NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_1388"
	(Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1389"
	(Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.Proc[j].ProcCmd = NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_1390"
	(Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1391"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1392"
	(Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_1393"
	(Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1394"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_1395"
	(Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_1396"
	(Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1397"
	(Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1398"
		(i != j) ->	(Sta.UniMsg[i].Cmd != UNI_PutX -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1399"
	(Sta.Dir.ShrVld = true -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_1400"
	(Sta.UniMsg[i].Cmd != UNI_PutX -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1401"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_1402"
	(Sta.UniMsg[i].Data != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_1403"
	(Sta.Dir.HeadVld = false -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_1404"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_1405"
	(Sta.UniMsg[i].Cmd != UNI_PutX -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1406"
	(Sta.Proc[i].InvMarked = true -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_1407"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_1408"
	(Sta.Proc[i].ProcCmd = NODE_Get -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_1409"
	(Sta.UniMsg[i].Cmd != UNI_PutX -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_1410"
	(Sta.UniMsg[i].Cmd != UNI_PutX -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1411"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_1412"
	(Sta.Proc[i].ProcCmd = NODE_None -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_1413"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_1414"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1415"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_E -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_1416"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_1417"
	(Sta.UniMsg[i].Cmd != UNI_PutX -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_1418"
	(Sta.Dir.HeadPtr != i -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_1419"
	(Sta.UniMsg[i].Cmd != UNI_PutX -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1420"
		(i != j) ->	(Sta.UniMsg[i].Cmd != UNI_PutX -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1421"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1422"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1423"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1424"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_1425"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.UniMsg[i].Data = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_1426"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Dir.HeadVld = true);
endruleset;


ruleset i : NODE do
Invariant "rule_1427"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_1428"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1429"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1430"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_1431"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_1432"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_1433"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1434"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_1435"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_1436"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset i : NODE do
Invariant "rule_1437"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1438"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_1439"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset i : NODE do
Invariant "rule_1440"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_1441"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Dir.HeadPtr = i);
endruleset;


ruleset i : NODE do
Invariant "rule_1442"
	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1443"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1444"
	(Sta.Dir.ShrVld = true -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1445"
	(Sta.Dir.ShrVld = false -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1446"
	(Sta.Proc[j].ProcCmd != NODE_None -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1447"
	(Sta.Proc[j].ProcCmd = NODE_None -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1448"
	(Sta.WbMsg.Data != Sta.PrevData -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1449"
	(Sta.Proc[j].CacheData != Sta.PrevData -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1450"
	(Sta.NakcMsg.Cmd != NAKC_Nakc -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1451"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1452"
	(Sta.WbMsg.Data != Sta.CurrData -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1453"
	(Sta.WbMsg.Data = Sta.CurrData -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1454"
	(Sta.UniMsg[j].Cmd != UNI_PutX -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1455"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1456"
		(i != j) ->	(Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1457"
		(i != j) ->	(Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1458"
		(i != j) ->	(Sta.UniMsg[i].Proc != j -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1459"
		(i != j) ->	(Sta.UniMsg[i].Proc = j -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1460"
	(Sta.Proc[j].ProcCmd != NODE_Get -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1461"
	(Sta.Proc[j].ProcCmd = NODE_Get -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1462"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1463"
		(i != j) ->	(Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1464"
	(Sta.Dir.HeadVld = true -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1465"
	(Sta.Dir.HeadVld = false -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1466"
		(i != j) ->	(Sta.InvMsg[i].Cmd != INV_InvAck -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1467"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1468"
	(Sta.MemData != Sta.PrevData -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1469"
	(Sta.Proc[j].CacheData != Sta.PrevData -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1470"
	(Sta.UniMsg[j].Cmd != UNI_GetX -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1471"
	(Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1472"
		(i != j) ->	(Sta.Proc[i].InvMarked = false -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1473"
		(i != j) ->	(Sta.Proc[i].InvMarked = true -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1474"
		(i != j) ->	(Sta.Proc[i].CacheState != CACHE_I -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1475"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_I -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1476"
		(i != j) ->	(Sta.Proc[i].ProcCmd != NODE_Get -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1477"
		(i != j) ->	(Sta.Proc[i].ProcCmd = NODE_Get -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1478"
	(Sta.ShWbMsg.Proc != Home -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1479"
	(Sta.Proc[j].CacheData != Sta.PrevData -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_1480"
	(Sta.ShWbMsg.Proc != j -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1481"
	(Sta.ShWbMsg.Proc = j -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1482"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.PrevData -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1483"
		(j != i) ->	(Sta.Proc[j].CacheData != Sta.PrevData -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1484"
	(Sta.UniMsg[j].Cmd != UNI_Nak -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1485"
	(Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1486"
		(i != j) ->	(Sta.Proc[i].CacheState != CACHE_E -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1487"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1488"
		(i != j) ->	(Sta.UniMsg[i].Cmd != UNI_Nak -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1489"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1490"
	(Sta.UniMsg[j].Data != Sta.CurrData -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1491"
	(Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1492"
	(Sta.RpMsg[j].Cmd != RP_Replace -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1493"
	(Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1494"
	(Sta.UniMsg[j].Cmd != UNI_Get -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1495"
	(Sta.UniMsg[j].Cmd = UNI_Get -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1496"
		(i != j) ->	(Sta.Proc[i].ProcCmd != NODE_None -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1497"
		(i != j) ->	(Sta.Proc[i].ProcCmd = NODE_None -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1498"
	(Sta.ShWbMsg.Cmd != SHWB_FAck -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1499"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1500"
		(i != j) ->	(Sta.Proc[i].CacheState != CACHE_S -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1501"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_S -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1502"
	(Sta.Proc[j].CacheState != CACHE_E -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1503"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1504"
	(Sta.WbMsg.Cmd != WB_Wb -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1505"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1506"
		(j != i) ->	(Sta.UniMsg[j].Proc != i -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1507"
		(j != i) ->	(Sta.UniMsg[j].Proc = i -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1508"
		(i != j) ->	(Sta.UniMsg[i].Proc != Home -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1509"
		(j != i) ->	(Sta.Proc[j].CacheData != Sta.PrevData -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_1510"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1511"
	(Sta.Proc[j].CacheState = CACHE_I -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1512"
		(i != j) ->	(Sta.Dir.HeadPtr != i -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1513"
		(i != j) ->	(Sta.Dir.HeadPtr = i -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1514"
		(i != j) ->	(Sta.UniMsg[i].Cmd != UNI_Put -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1515"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1516"
		(i != j) ->	(Sta.UniMsg[i].Cmd != UNI_GetX -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1517"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1518"
	(Sta.MemData != Sta.CurrData -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1519"
	(Sta.MemData = Sta.CurrData -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1520"
	(Sta.ShWbMsg.Data != Sta.PrevData -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1521"
	(Sta.Proc[j].CacheData != Sta.PrevData -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1522"
	(Sta.UniMsg[j].Data != Sta.PrevData -> Sta.Proc[j].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1523"
	(Sta.Proc[j].CacheData != Sta.PrevData -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;
Invariant "rule_1524"
	(Sta.Dir.ShrVld = true -> Sta.WbMsg.Data != Sta.PrevData);
Invariant "rule_1525"
	(Sta.Dir.ShrVld = true -> Sta.NakcMsg.Cmd != NAKC_Nakc);


ruleset j : NODE do
Invariant "rule_1526"
	(Sta.Dir.ShrVld = true -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1527"
		(i != j) ->	(Sta.Dir.ShrVld = true -> Sta.UniMsg[i].Proc != j);
endruleset;
Invariant "rule_1528"
	(Sta.Dir.ShrVld = true -> Sta.Dir.HeadVld = true);


ruleset i : NODE do
Invariant "rule_1529"
	(Sta.Dir.ShrVld = true -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;
Invariant "rule_1530"
	(Sta.Dir.ShrVld = true -> Sta.MemData != Sta.PrevData);
Invariant "rule_1531"
	(Sta.Dir.ShrVld = true -> Sta.ShWbMsg.Proc != Home);


ruleset i : NODE do
Invariant "rule_1532"
	(Sta.Dir.ShrVld = true -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1533"
	(Sta.Dir.ShrVld = true -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;
Invariant "rule_1534"
	(Sta.Dir.ShrVld = true -> Sta.ShWbMsg.Cmd != SHWB_FAck);


ruleset j : NODE do
Invariant "rule_1535"
	(Sta.Dir.ShrVld = true -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;
Invariant "rule_1536"
	(Sta.Dir.ShrVld = true -> Sta.WbMsg.Cmd != WB_Wb);


ruleset i : NODE do
Invariant "rule_1537"
	(Sta.Dir.ShrVld = true -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_1538"
	(Sta.Dir.ShrVld = true -> Sta.Dir.HeadPtr = i);
endruleset;
Invariant "rule_1539"
	(Sta.Dir.ShrVld = true -> Sta.MemData = Sta.CurrData);
Invariant "rule_1540"
	(Sta.Dir.ShrVld = true -> Sta.ShWbMsg.Data != Sta.PrevData);


ruleset j : NODE do
Invariant "rule_1541"
	(Sta.Dir.ShrVld = true -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;
Invariant "rule_1542"
	(Sta.Dir.ShrVld = false -> Sta.WbMsg.Data != Sta.PrevData);
Invariant "rule_1543"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Dir.ShrVld = false);


ruleset j : NODE do
Invariant "rule_1544"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1545"
	(Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1546"
		(i != j) ->	(Sta.UniMsg[i].Proc = j -> Sta.Dir.ShrVld = false);
endruleset;
Invariant "rule_1547"
	(Sta.Dir.HeadVld = false -> Sta.Dir.ShrVld = false);


ruleset i : NODE do
Invariant "rule_1548"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Dir.ShrVld = false);
endruleset;
Invariant "rule_1549"
	(Sta.Dir.ShrVld = false -> Sta.MemData != Sta.PrevData);
Invariant "rule_1550"
	(Sta.Dir.ShrVld = false -> Sta.ShWbMsg.Proc != Home);


ruleset i : NODE do
Invariant "rule_1551"
	(Sta.Dir.ShrVld = false -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1552"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Dir.ShrVld = false);
endruleset;
Invariant "rule_1553"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.ShrVld = false);


ruleset j : NODE do
Invariant "rule_1554"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Dir.ShrVld = false);
endruleset;
Invariant "rule_1555"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.Dir.ShrVld = false);


ruleset i : NODE do
Invariant "rule_1556"
	(Sta.Dir.ShrVld = false -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_1557"
	(Sta.Dir.HeadPtr != i -> Sta.Dir.ShrVld = false);
endruleset;
Invariant "rule_1558"
	(Sta.MemData != Sta.CurrData -> Sta.Dir.ShrVld = false);
Invariant "rule_1559"
	(Sta.Dir.ShrVld = false -> Sta.ShWbMsg.Data != Sta.PrevData);


ruleset j : NODE do
Invariant "rule_1560"
	(Sta.Dir.ShrVld = false -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1561"
	(Sta.Proc[j].ProcCmd != NODE_None -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1562"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_1563"
	(Sta.Proc[j].ProcCmd != NODE_None -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1564"
	(Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_1565"
	(Sta.Proc[j].ProcCmd != NODE_None -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1566"
		(j != i) ->	(Sta.Proc[j].ProcCmd != NODE_None -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1567"
	(Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_1568"
	(Sta.UniMsg[j].Cmd = UNI_Get -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_1569"
	(Sta.Proc[j].ProcCmd != NODE_None -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1570"
		(j != i) ->	(Sta.Proc[j].ProcCmd != NODE_None -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_1571"
	(Sta.Proc[j].ProcCmd != NODE_None -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_1572"
	(Sta.Proc[j].ProcCmd != NODE_None -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1573"
	(Sta.Proc[j].ProcCmd != NODE_None -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1574"
	(Sta.Proc[j].ProcCmd = NODE_None -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1575"
	(Sta.Proc[j].ProcCmd = NODE_None -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_1576"
	(Sta.Proc[j].ProcCmd = NODE_None -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1577"
	(Sta.Proc[j].ProcCmd = NODE_None -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_1578"
	(Sta.Proc[j].ProcCmd = NODE_None -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1579"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_None -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1580"
	(Sta.Proc[j].ProcCmd = NODE_None -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_1581"
	(Sta.Proc[j].ProcCmd = NODE_None -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_1582"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Proc[j].ProcCmd = NODE_None);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1583"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_None -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_1584"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.Proc[j].ProcCmd = NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_1585"
	(Sta.Proc[j].ProcCmd = NODE_None -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1586"
	(Sta.Proc[j].ProcCmd = NODE_None -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;
Invariant "rule_1587"
	(Sta.NakcMsg.Cmd != NAKC_Nakc -> Sta.WbMsg.Data != Sta.PrevData);
Invariant "rule_1588"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.WbMsg.Data != Sta.PrevData);


ruleset j : NODE do
Invariant "rule_1589"
	(Sta.UniMsg[j].Cmd != UNI_PutX -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1590"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1591"
	(Sta.UniMsg[i].Data != Sta.CurrData -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1592"
	(Sta.UniMsg[i].Data = Sta.CurrData -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1593"
		(i != j) ->	(Sta.UniMsg[i].Proc != j -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1594"
		(i != j) ->	(Sta.UniMsg[i].Proc = j -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1595"
	(Sta.Proc[j].ProcCmd != NODE_Get -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1596"
	(Sta.Proc[j].ProcCmd = NODE_Get -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1597"
	(Sta.Proc[i].CacheData != Sta.CurrData -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1598"
	(Sta.Proc[i].CacheData = Sta.CurrData -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;
Invariant "rule_1599"
	(Sta.Dir.HeadVld = true -> Sta.WbMsg.Data != Sta.PrevData);
Invariant "rule_1600"
	(Sta.Dir.HeadVld = false -> Sta.WbMsg.Data != Sta.PrevData);


ruleset i : NODE do
Invariant "rule_1601"
	(Sta.InvMsg[i].Cmd != INV_InvAck -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1602"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;
Invariant "rule_1603"
	(Sta.WbMsg.Data != Sta.PrevData -> Sta.MemData != Sta.PrevData);
Invariant "rule_1604"
	(Sta.MemData != Sta.PrevData -> Sta.WbMsg.Data != Sta.PrevData);


ruleset j : NODE do
Invariant "rule_1605"
	(Sta.UniMsg[j].Cmd != UNI_GetX -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1606"
	(Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1607"
	(Sta.Proc[i].InvMarked = false -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1608"
	(Sta.Proc[i].InvMarked = true -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1609"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1610"
	(Sta.Proc[i].CacheState = CACHE_I -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1611"
	(Sta.Proc[i].ProcCmd != NODE_Get -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1612"
	(Sta.Proc[i].ProcCmd = NODE_Get -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;
Invariant "rule_1613"
	(Sta.WbMsg.Data != Sta.PrevData -> Sta.ShWbMsg.Proc != Home);
Invariant "rule_1614"
	(Sta.ShWbMsg.Proc != Home -> Sta.WbMsg.Data != Sta.PrevData);


ruleset j : NODE do
Invariant "rule_1615"
	(Sta.ShWbMsg.Proc != j -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1616"
	(Sta.ShWbMsg.Proc = j -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1617"
	(Sta.Proc[i].CacheData != Sta.PrevData -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1618"
	(Sta.WbMsg.Data != Sta.PrevData -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1619"
	(Sta.UniMsg[j].Cmd != UNI_Nak -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1620"
	(Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1621"
	(Sta.Proc[i].CacheState != CACHE_E -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1622"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1623"
	(Sta.UniMsg[i].Cmd != UNI_Nak -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1624"
	(Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1625"
	(Sta.UniMsg[j].Data != Sta.CurrData -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1626"
	(Sta.UniMsg[j].Data = Sta.CurrData -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1627"
	(Sta.RpMsg[j].Cmd != RP_Replace -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1628"
	(Sta.RpMsg[j].Cmd = RP_Replace -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1629"
	(Sta.UniMsg[j].Cmd != UNI_Get -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1630"
	(Sta.UniMsg[j].Cmd = UNI_Get -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1631"
	(Sta.Proc[i].ProcCmd != NODE_None -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1632"
	(Sta.Proc[i].ProcCmd = NODE_None -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1633"
	(Sta.Proc[j].CacheData != Sta.CurrData -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1634"
	(Sta.Proc[j].CacheData = Sta.CurrData -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;
Invariant "rule_1635"
	(Sta.ShWbMsg.Cmd != SHWB_FAck -> Sta.WbMsg.Data != Sta.PrevData);
Invariant "rule_1636"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.WbMsg.Data != Sta.PrevData);


ruleset i : NODE do
Invariant "rule_1637"
	(Sta.Proc[i].CacheState != CACHE_S -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1638"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1639"
	(Sta.Proc[j].CacheState != CACHE_E -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1640"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;
Invariant "rule_1641"
	(Sta.WbMsg.Cmd != WB_Wb -> Sta.WbMsg.Data != Sta.PrevData);
Invariant "rule_1642"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.WbMsg.Data != Sta.PrevData);


ruleset j : NODE ; i : NODE do
Invariant "rule_1643"
		(j != i) ->	(Sta.UniMsg[j].Proc != i -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1644"
		(j != i) ->	(Sta.UniMsg[j].Proc = i -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1645"
	(Sta.UniMsg[i].Proc != Home -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1646"
	(Sta.WbMsg.Data != Sta.PrevData -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_1647"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1648"
	(Sta.Proc[j].CacheState = CACHE_I -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1649"
	(Sta.Dir.HeadPtr != i -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1650"
	(Sta.Dir.HeadPtr = i -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1651"
	(Sta.UniMsg[i].Cmd != UNI_Put -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1652"
	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1653"
	(Sta.UniMsg[i].Cmd != UNI_GetX -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1654"
	(Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;
Invariant "rule_1655"
	(Sta.MemData != Sta.CurrData -> Sta.WbMsg.Data != Sta.PrevData);
Invariant "rule_1656"
	(Sta.MemData = Sta.CurrData -> Sta.WbMsg.Data != Sta.PrevData);
Invariant "rule_1657"
	(Sta.WbMsg.Data != Sta.PrevData -> Sta.ShWbMsg.Data != Sta.PrevData);
Invariant "rule_1658"
	(Sta.ShWbMsg.Data != Sta.PrevData -> Sta.WbMsg.Data != Sta.PrevData);


ruleset j : NODE do
Invariant "rule_1659"
	(Sta.WbMsg.Data != Sta.PrevData -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1660"
	(Sta.UniMsg[j].Data != Sta.PrevData -> Sta.WbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1661"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_1662"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;
Invariant "rule_1663"
	(Sta.NakcMsg.Cmd != NAKC_Nakc -> Sta.MemData != Sta.PrevData);
Invariant "rule_1664"
	(Sta.NakcMsg.Cmd != NAKC_Nakc -> Sta.ShWbMsg.Proc != Home);


ruleset i : NODE do
Invariant "rule_1665"
	(Sta.NakcMsg.Cmd != NAKC_Nakc -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;
Invariant "rule_1666"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.NakcMsg.Cmd != NAKC_Nakc);


ruleset j : NODE do
Invariant "rule_1667"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_1668"
	(Sta.NakcMsg.Cmd != NAKC_Nakc -> Sta.UniMsg[i].Proc != Home);
endruleset;
Invariant "rule_1669"
	(Sta.NakcMsg.Cmd != NAKC_Nakc -> Sta.ShWbMsg.Data != Sta.PrevData);


ruleset j : NODE do
Invariant "rule_1670"
	(Sta.NakcMsg.Cmd != NAKC_Nakc -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1671"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_1672"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;
Invariant "rule_1673"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.MemData != Sta.PrevData);
Invariant "rule_1674"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.ShWbMsg.Proc != Home);


ruleset i : NODE do
Invariant "rule_1675"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;
Invariant "rule_1676"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.ShWbMsg.Cmd != SHWB_FAck);


ruleset j : NODE do
Invariant "rule_1677"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_1678"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[i].Proc != Home);
endruleset;
Invariant "rule_1679"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.ShWbMsg.Data != Sta.PrevData);


ruleset j : NODE do
Invariant "rule_1680"
	(Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;
Invariant "rule_1681"
	(Sta.WbMsg.Data != Sta.CurrData -> Sta.MemData != Sta.PrevData);
Invariant "rule_1682"
	(Sta.WbMsg.Data != Sta.CurrData -> Sta.ShWbMsg.Proc != Home);


ruleset i : NODE do
Invariant "rule_1683"
	(Sta.WbMsg.Data != Sta.CurrData -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;
Invariant "rule_1684"
	(Sta.WbMsg.Data != Sta.CurrData -> Sta.WbMsg.Cmd != WB_Wb);


ruleset i : NODE do
Invariant "rule_1685"
	(Sta.WbMsg.Data != Sta.CurrData -> Sta.UniMsg[i].Proc != Home);
endruleset;
Invariant "rule_1686"
	(Sta.WbMsg.Data != Sta.CurrData -> Sta.ShWbMsg.Data != Sta.PrevData);


ruleset j : NODE do
Invariant "rule_1687"
	(Sta.WbMsg.Data != Sta.CurrData -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;
Invariant "rule_1688"
	(Sta.WbMsg.Data = Sta.CurrData -> Sta.MemData != Sta.PrevData);
Invariant "rule_1689"
	(Sta.WbMsg.Data = Sta.CurrData -> Sta.ShWbMsg.Proc != Home);


ruleset i : NODE do
Invariant "rule_1690"
	(Sta.WbMsg.Data = Sta.CurrData -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;
Invariant "rule_1691"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.WbMsg.Data = Sta.CurrData);


ruleset i : NODE do
Invariant "rule_1692"
	(Sta.WbMsg.Data = Sta.CurrData -> Sta.UniMsg[i].Proc != Home);
endruleset;
Invariant "rule_1693"
	(Sta.WbMsg.Data = Sta.CurrData -> Sta.ShWbMsg.Data != Sta.PrevData);


ruleset j : NODE do
Invariant "rule_1694"
	(Sta.WbMsg.Data = Sta.CurrData -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1695"
		(i != j) ->	(Sta.UniMsg[i].Data != Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1696"
		(i != j) ->	(Sta.UniMsg[i].Data = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1697"
		(i != j) ->	(Sta.UniMsg[i].Proc = j -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_1698"
	(Sta.Proc[j].ProcCmd = NODE_Get -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1699"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1700"
		(i != j) ->	(Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_1701"
	(Sta.Dir.HeadVld = false -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1702"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_1703"
	(Sta.UniMsg[j].Cmd != UNI_PutX -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1704"
		(i != j) ->	(Sta.Proc[i].InvMarked = true -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1705"
		(i != j) ->	(Sta.Proc[i].CacheState != CACHE_I -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_1706"
	(Sta.UniMsg[j].Cmd != UNI_PutX -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_1707"
	(Sta.ShWbMsg.Proc != j -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1708"
		(j != i) ->	(Sta.UniMsg[j].Cmd != UNI_PutX -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1709"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_E -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_1710"
	(Sta.UniMsg[j].Data != Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_1711"
	(Sta.ShWbMsg.Cmd != SHWB_FAck -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1712"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_S -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_1713"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_1714"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1715"
		(j != i) ->	(Sta.UniMsg[j].Proc != i -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1716"
		(j != i) ->	(Sta.UniMsg[j].Cmd != UNI_PutX -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_1717"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1718"
		(i != j) ->	(Sta.Dir.HeadPtr != i -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1719"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_1720"
	(Sta.UniMsg[j].Cmd != UNI_PutX -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1721"
	(Sta.UniMsg[j].Cmd != UNI_PutX -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1722"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE do
Invariant "rule_1723"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_1724"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Dir.HeadVld = true);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1725"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE do
Invariant "rule_1726"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1727"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1728"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_1729"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_1730"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.ShWbMsg.Proc = j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1731"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1732"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_1733"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.UniMsg[j].Data = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_1734"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.ShWbMsg.Cmd = SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1735"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_1736"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_1737"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1738"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.UniMsg[j].Proc = i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1739"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_1740"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1741"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.Dir.HeadPtr = i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1742"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_1743"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1744"
	(Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1745"
	(Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1746"
	(Sta.UniMsg[i].Data != Sta.CurrData -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1747"
	(Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_1748"
	(Sta.UniMsg[i].Data != Sta.CurrData -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_1749"
	(Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1750"
	(Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_1751"
	(Sta.UniMsg[i].Data != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_1752"
	(Sta.UniMsg[i].Data != Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset i : NODE do
Invariant "rule_1753"
	(Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1754"
		(i != j) ->	(Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_1755"
	(Sta.UniMsg[i].Data != Sta.CurrData -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset i : NODE do
Invariant "rule_1756"
	(Sta.UniMsg[i].Data != Sta.CurrData -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_1757"
	(Sta.UniMsg[i].Data != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_1758"
	(Sta.UniMsg[i].Data != Sta.CurrData -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1759"
		(i != j) ->	(Sta.UniMsg[i].Data != Sta.CurrData -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1760"
	(Sta.UniMsg[i].Data = Sta.CurrData -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1761"
	(Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_1762"
	(Sta.UniMsg[i].Data = Sta.CurrData -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_1763"
	(Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1764"
	(Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_1765"
	(Sta.UniMsg[i].Data = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_1766"
	(Sta.UniMsg[i].Data = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset i : NODE do
Invariant "rule_1767"
	(Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1768"
		(i != j) ->	(Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_1769"
	(Sta.UniMsg[i].Data = Sta.CurrData -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset i : NODE do
Invariant "rule_1770"
	(Sta.UniMsg[i].Data = Sta.CurrData -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_1771"
	(Sta.UniMsg[i].Data = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_1772"
	(Sta.UniMsg[i].Data = Sta.CurrData -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1773"
		(i != j) ->	(Sta.UniMsg[i].Data = Sta.CurrData -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1774"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1775"
		(i != j) ->	(Sta.UniMsg[i].Proc != j -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1776"
		(i != j) ->	(Sta.Proc[i].CacheState != CACHE_I -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1777"
		(i != j) ->	(Sta.UniMsg[i].Proc != j -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1778"
		(j != i) ->	(Sta.ShWbMsg.Proc = j -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1779"
		(i != j) ->	(Sta.UniMsg[i].Proc != j -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1780"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_E -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1781"
		(i != j) ->	(Sta.Proc[i].ProcCmd = NODE_None -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1782"
		(i != j) ->	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1783"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_S -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1784"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_E -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1785"
		(i != j) ->	(Sta.WbMsg.Cmd = WB_Wb -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1786"
		(i != j) ->	(Sta.UniMsg[i].Proc != j -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1787"
		(i != j) ->	(Sta.UniMsg[i].Proc != j -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1788"
		(i != j) ->	(Sta.UniMsg[i].Proc = j -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1789"
		(i != j) ->	(Sta.UniMsg[i].Proc = j -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1790"
		(i != j) ->	(Sta.UniMsg[i].Proc = j -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1791"
		(i != j) ->	(Sta.UniMsg[i].Proc = j -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1792"
		(i != j) ->	(Sta.UniMsg[i].Proc = j -> Sta.ShWbMsg.Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1793"
		(i != j) ->	(Sta.UniMsg[i].Proc = j -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1794"
		(i != j) ->	(Sta.UniMsg[i].Proc = j -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1795"
		(i != j) ->	(Sta.UniMsg[i].Proc = j -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1796"
		(i != j) ->	(Sta.UniMsg[i].Proc = j -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1797"
		(i != j) ->	(Sta.UniMsg[i].Proc = j -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1798"
		(i != j) ->	(Sta.UniMsg[i].Proc = j -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1799"
		(i != j) ->	(Sta.UniMsg[i].Proc = j -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1800"
		(i != j) ->	(Sta.UniMsg[i].Proc = j -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1801"
		(i != j) ->	(Sta.UniMsg[i].Proc = j -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1802"
	(Sta.Proc[j].ProcCmd != NODE_Get -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1803"
	(Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_1804"
	(Sta.Proc[j].ProcCmd != NODE_Get -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1805"
		(j != i) ->	(Sta.Proc[j].ProcCmd != NODE_Get -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1806"
	(Sta.Proc[j].ProcCmd != NODE_Get -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_1807"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1808"
		(j != i) ->	(Sta.Proc[j].ProcCmd != NODE_Get -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_1809"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_1810"
	(Sta.Proc[j].ProcCmd != NODE_Get -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1811"
	(Sta.Proc[j].ProcCmd != NODE_Get -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1812"
	(Sta.Proc[j].ProcCmd = NODE_Get -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1813"
	(Sta.Proc[j].ProcCmd = NODE_Get -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_1814"
	(Sta.Proc[j].ProcCmd = NODE_Get -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1815"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_Get -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1816"
	(Sta.UniMsg[j].Cmd = UNI_Get -> Sta.Proc[j].ProcCmd = NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_1817"
	(Sta.Proc[j].ProcCmd = NODE_Get -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1818"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_Get -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_1819"
	(Sta.Proc[j].ProcCmd = NODE_Get -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_1820"
	(Sta.Proc[j].ProcCmd = NODE_Get -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1821"
	(Sta.Proc[j].ProcCmd = NODE_Get -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1822"
	(Sta.Proc[i].CacheData != Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_1823"
	(Sta.Proc[i].CacheData != Sta.CurrData -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1824"
	(Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1825"
	(Sta.Proc[i].CacheData != Sta.CurrData -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_1826"
	(Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_1827"
	(Sta.Proc[i].CacheData != Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1828"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_1829"
	(Sta.Proc[i].CacheData != Sta.CurrData -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset i : NODE do
Invariant "rule_1830"
	(Sta.Proc[i].CacheData != Sta.CurrData -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_1831"
	(Sta.Proc[i].CacheData != Sta.CurrData -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1832"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1833"
	(Sta.Proc[i].CacheData = Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_1834"
	(Sta.Proc[i].CacheData = Sta.CurrData -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1835"
	(Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1836"
	(Sta.Proc[i].CacheData = Sta.CurrData -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_1837"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Proc[i].CacheData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_1838"
	(Sta.Proc[i].CacheData = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1839"
		(i != j) ->	(Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_1840"
	(Sta.Proc[i].CacheData = Sta.CurrData -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset i : NODE do
Invariant "rule_1841"
	(Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_1842"
	(Sta.Proc[i].CacheData = Sta.CurrData -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1843"
		(i != j) ->	(Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1844"
	(Sta.Dir.HeadVld = true -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;
Invariant "rule_1845"
	(Sta.Dir.HeadVld = true -> Sta.MemData != Sta.PrevData);
Invariant "rule_1846"
	(Sta.Dir.HeadVld = true -> Sta.ShWbMsg.Proc != Home);


ruleset i : NODE do
Invariant "rule_1847"
	(Sta.Dir.HeadVld = true -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1848"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Dir.HeadVld = true);
endruleset;


ruleset j : NODE do
Invariant "rule_1849"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Dir.HeadVld = true);
endruleset;
Invariant "rule_1850"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.Dir.HeadVld = true);


ruleset i : NODE do
Invariant "rule_1851"
	(Sta.Dir.HeadVld = true -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_1852"
	(Sta.Dir.HeadVld = true -> Sta.Dir.HeadPtr = i);
endruleset;
Invariant "rule_1853"
	(Sta.Dir.HeadVld = true -> Sta.ShWbMsg.Data != Sta.PrevData);


ruleset j : NODE do
Invariant "rule_1854"
	(Sta.Dir.HeadVld = true -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1855"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Dir.HeadVld = false);
endruleset;
Invariant "rule_1856"
	(Sta.Dir.HeadVld = false -> Sta.MemData != Sta.PrevData);
Invariant "rule_1857"
	(Sta.Dir.HeadVld = false -> Sta.ShWbMsg.Proc != Home);


ruleset i : NODE do
Invariant "rule_1858"
	(Sta.Dir.HeadVld = false -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1859"
	(Sta.Dir.HeadVld = false -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_1860"
	(Sta.Dir.HeadVld = false -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;
Invariant "rule_1861"
	(Sta.Dir.HeadVld = false -> Sta.WbMsg.Cmd != WB_Wb);


ruleset i : NODE do
Invariant "rule_1862"
	(Sta.Dir.HeadVld = false -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_1863"
	(Sta.Dir.HeadPtr != i -> Sta.Dir.HeadVld = false);
endruleset;
Invariant "rule_1864"
	(Sta.Dir.HeadVld = false -> Sta.ShWbMsg.Data != Sta.PrevData);


ruleset j : NODE do
Invariant "rule_1865"
	(Sta.Dir.HeadVld = false -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1866"
	(Sta.InvMsg[i].Cmd != INV_InvAck -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1867"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_1868"
	(Sta.InvMsg[i].Cmd != INV_InvAck -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_1869"
	(Sta.InvMsg[i].Cmd != INV_InvAck -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1870"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_1871"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_1872"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1873"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_E -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_1874"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_1875"
	(Sta.InvMsg[i].Cmd != INV_InvAck -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_1876"
	(Sta.Dir.HeadPtr != i -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_1877"
	(Sta.InvMsg[i].Cmd != INV_InvAck -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1878"
		(i != j) ->	(Sta.InvMsg[i].Cmd != INV_InvAck -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1879"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1880"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_1881"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_1882"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1883"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_1884"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset i : NODE do
Invariant "rule_1885"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1886"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_1887"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset i : NODE do
Invariant "rule_1888"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_1889"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Dir.HeadPtr = i);
endruleset;


ruleset i : NODE do
Invariant "rule_1890"
	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1891"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1892"
	(Sta.UniMsg[j].Cmd != UNI_GetX -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1893"
	(Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1894"
	(Sta.Proc[i].InvMarked = false -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1895"
	(Sta.Proc[i].InvMarked = true -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1896"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1897"
	(Sta.Proc[i].CacheState = CACHE_I -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1898"
	(Sta.Proc[i].ProcCmd != NODE_Get -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1899"
	(Sta.Proc[i].ProcCmd = NODE_Get -> Sta.MemData != Sta.PrevData);
endruleset;
Invariant "rule_1900"
	(Sta.MemData != Sta.PrevData -> Sta.ShWbMsg.Proc != Home);
Invariant "rule_1901"
	(Sta.ShWbMsg.Proc != Home -> Sta.MemData != Sta.PrevData);


ruleset j : NODE do
Invariant "rule_1902"
	(Sta.ShWbMsg.Proc != j -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1903"
	(Sta.ShWbMsg.Proc = j -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1904"
	(Sta.Proc[i].CacheData != Sta.PrevData -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1905"
	(Sta.MemData != Sta.PrevData -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1906"
	(Sta.UniMsg[j].Cmd != UNI_Nak -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1907"
	(Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1908"
	(Sta.Proc[i].CacheState != CACHE_E -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1909"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1910"
	(Sta.UniMsg[i].Cmd != UNI_Nak -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1911"
	(Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1912"
	(Sta.UniMsg[j].Data != Sta.CurrData -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1913"
	(Sta.UniMsg[j].Data = Sta.CurrData -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1914"
	(Sta.RpMsg[j].Cmd != RP_Replace -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1915"
	(Sta.RpMsg[j].Cmd = RP_Replace -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1916"
	(Sta.UniMsg[j].Cmd != UNI_Get -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1917"
	(Sta.UniMsg[j].Cmd = UNI_Get -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1918"
	(Sta.Proc[i].ProcCmd != NODE_None -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1919"
	(Sta.Proc[i].ProcCmd = NODE_None -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1920"
	(Sta.Proc[j].CacheData != Sta.CurrData -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1921"
	(Sta.Proc[j].CacheData = Sta.CurrData -> Sta.MemData != Sta.PrevData);
endruleset;
Invariant "rule_1922"
	(Sta.ShWbMsg.Cmd != SHWB_FAck -> Sta.MemData != Sta.PrevData);
Invariant "rule_1923"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.MemData != Sta.PrevData);


ruleset i : NODE do
Invariant "rule_1924"
	(Sta.Proc[i].CacheState != CACHE_S -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1925"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1926"
	(Sta.Proc[j].CacheState != CACHE_E -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1927"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.MemData != Sta.PrevData);
endruleset;
Invariant "rule_1928"
	(Sta.WbMsg.Cmd != WB_Wb -> Sta.MemData != Sta.PrevData);
Invariant "rule_1929"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.MemData != Sta.PrevData);


ruleset j : NODE ; i : NODE do
Invariant "rule_1930"
		(j != i) ->	(Sta.UniMsg[j].Proc != i -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1931"
		(j != i) ->	(Sta.UniMsg[j].Proc = i -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1932"
	(Sta.UniMsg[i].Proc != Home -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1933"
	(Sta.MemData != Sta.PrevData -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_1934"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1935"
	(Sta.Proc[j].CacheState = CACHE_I -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1936"
	(Sta.Dir.HeadPtr != i -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1937"
	(Sta.Dir.HeadPtr = i -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1938"
	(Sta.UniMsg[i].Cmd != UNI_Put -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1939"
	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1940"
	(Sta.UniMsg[i].Cmd != UNI_GetX -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1941"
	(Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.MemData != Sta.PrevData);
endruleset;
Invariant "rule_1942"
	(Sta.MemData != Sta.PrevData -> Sta.ShWbMsg.Data != Sta.PrevData);
Invariant "rule_1943"
	(Sta.ShWbMsg.Data != Sta.PrevData -> Sta.MemData != Sta.PrevData);


ruleset j : NODE do
Invariant "rule_1944"
	(Sta.UniMsg[j].Data != Sta.PrevData -> Sta.MemData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1945"
	(Sta.MemData != Sta.PrevData -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1946"
	(Sta.UniMsg[j].Cmd != UNI_GetX -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1947"
		(j != i) ->	(Sta.UniMsg[j].Cmd != UNI_GetX -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1948"
	(Sta.UniMsg[j].Data != Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_1949"
	(Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_1950"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1951"
		(j != i) ->	(Sta.UniMsg[j].Cmd != UNI_GetX -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_1952"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_1953"
	(Sta.UniMsg[j].Cmd != UNI_GetX -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1954"
	(Sta.UniMsg[j].Cmd != UNI_GetX -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1955"
	(Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1956"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1957"
	(Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1958"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_1959"
	(Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_1960"
	(Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_1961"
	(Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1962"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1963"
	(Sta.Proc[i].ProcCmd != NODE_Get -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1964"
	(Sta.Proc[i].InvMarked = false -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_1965"
	(Sta.Proc[i].InvMarked = false -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1966"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1967"
	(Sta.Proc[i].ProcCmd = NODE_None -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1968"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1969"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_1970"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1971"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1972"
	(Sta.Proc[i].InvMarked = false -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_1973"
	(Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_1974"
	(Sta.Proc[i].InvMarked = false -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1975"
		(i != j) ->	(Sta.Proc[i].InvMarked = false -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1976"
	(Sta.Proc[i].InvMarked = true -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_1977"
	(Sta.Proc[i].InvMarked = true -> Sta.Proc[i].ProcCmd = NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_1978"
	(Sta.Proc[i].InvMarked = true -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_1979"
	(Sta.Proc[i].InvMarked = true -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1980"
	(Sta.Proc[i].InvMarked = true -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_1981"
	(Sta.Proc[i].InvMarked = true -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_1982"
	(Sta.Proc[i].InvMarked = true -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset i : NODE do
Invariant "rule_1983"
	(Sta.Proc[i].InvMarked = true -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1984"
		(i != j) ->	(Sta.Proc[i].InvMarked = true -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_1985"
	(Sta.Proc[i].InvMarked = true -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset i : NODE do
Invariant "rule_1986"
	(Sta.Proc[i].InvMarked = true -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_1987"
	(Sta.Proc[i].InvMarked = true -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_1988"
	(Sta.Proc[i].InvMarked = true -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1989"
		(i != j) ->	(Sta.Proc[i].InvMarked = true -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1990"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_1991"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_1992"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_1993"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_1994"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.Proc[i].ProcCmd = NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_1995"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_1996"
		(i != j) ->	(Sta.Proc[i].CacheState != CACHE_I -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_1997"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset i : NODE do
Invariant "rule_1998"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_1999"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_2000"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2001"
	(Sta.Proc[i].CacheState != CACHE_I -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2002"
		(i != j) ->	(Sta.Proc[i].CacheState != CACHE_I -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_2003"
	(Sta.Proc[i].ProcCmd = NODE_Get -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_2004"
	(Sta.Proc[i].CacheState = CACHE_I -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_2005"
	(Sta.Proc[i].CacheState = CACHE_I -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_2006"
	(Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_2007"
	(Sta.Proc[i].ProcCmd != NODE_None -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_2008"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2009"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_2010"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_2011"
	(Sta.Proc[i].CacheState = CACHE_I -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_2012"
	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_2013"
	(Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_2014"
	(Sta.Proc[i].CacheState = CACHE_I -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2015"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_I -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_2016"
	(Sta.Proc[i].ProcCmd != NODE_Get -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_2017"
	(Sta.Proc[i].ProcCmd != NODE_Get -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_2018"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_2019"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_2020"
	(Sta.Proc[i].ProcCmd != NODE_Get -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_2021"
	(Sta.Proc[i].ProcCmd != NODE_Get -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_2022"
	(Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_2023"
	(Sta.Proc[i].ProcCmd != NODE_Get -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2024"
		(i != j) ->	(Sta.Proc[i].ProcCmd != NODE_Get -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_2025"
	(Sta.Proc[i].ProcCmd = NODE_Get -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_2026"
	(Sta.Proc[i].ProcCmd = NODE_Get -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_2027"
	(Sta.Proc[i].ProcCmd = NODE_Get -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_2028"
	(Sta.Proc[i].ProcCmd = NODE_Get -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_2029"
	(Sta.Proc[i].ProcCmd = NODE_Get -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_2030"
	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.Proc[i].ProcCmd = NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_2031"
	(Sta.Proc[i].ProcCmd = NODE_Get -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2032"
	(Sta.Proc[i].ProcCmd = NODE_Get -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2033"
		(i != j) ->	(Sta.Proc[i].ProcCmd = NODE_Get -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_2034"
	(Sta.Proc[i].CacheData != Sta.PrevData -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_2035"
	(Sta.ShWbMsg.Proc != Home -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_2036"
	(Sta.UniMsg[j].Cmd != UNI_Nak -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_2037"
	(Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_2038"
	(Sta.Proc[i].CacheState != CACHE_E -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_2039"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_2040"
	(Sta.UniMsg[i].Cmd != UNI_Nak -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_2041"
	(Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_2042"
	(Sta.UniMsg[j].Data != Sta.CurrData -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_2043"
	(Sta.UniMsg[j].Data = Sta.CurrData -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_2044"
	(Sta.RpMsg[j].Cmd != RP_Replace -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_2045"
	(Sta.RpMsg[j].Cmd = RP_Replace -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_2046"
	(Sta.UniMsg[j].Cmd != UNI_Get -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_2047"
	(Sta.UniMsg[j].Cmd = UNI_Get -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_2048"
	(Sta.Proc[i].ProcCmd != NODE_None -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_2049"
	(Sta.Proc[i].ProcCmd = NODE_None -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_2050"
	(Sta.Proc[j].CacheData != Sta.CurrData -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_2051"
	(Sta.Proc[j].CacheData = Sta.CurrData -> Sta.ShWbMsg.Proc != Home);
endruleset;
Invariant "rule_2052"
	(Sta.ShWbMsg.Cmd != SHWB_FAck -> Sta.ShWbMsg.Proc != Home);
Invariant "rule_2053"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.ShWbMsg.Proc != Home);


ruleset i : NODE do
Invariant "rule_2054"
	(Sta.Proc[i].CacheState != CACHE_S -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_2055"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_2056"
	(Sta.Proc[j].CacheState != CACHE_E -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_2057"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.ShWbMsg.Proc != Home);
endruleset;
Invariant "rule_2058"
	(Sta.WbMsg.Cmd != WB_Wb -> Sta.ShWbMsg.Proc != Home);
Invariant "rule_2059"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.ShWbMsg.Proc != Home);


ruleset j : NODE ; i : NODE do
Invariant "rule_2060"
		(j != i) ->	(Sta.UniMsg[j].Proc != i -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2061"
		(j != i) ->	(Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_2062"
	(Sta.UniMsg[i].Proc != Home -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_2063"
	(Sta.ShWbMsg.Proc != Home -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_2064"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_2065"
	(Sta.Proc[j].CacheState = CACHE_I -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_2066"
	(Sta.Dir.HeadPtr != i -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_2067"
	(Sta.Dir.HeadPtr = i -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_2068"
	(Sta.UniMsg[i].Cmd != UNI_Put -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_2069"
	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_2070"
	(Sta.UniMsg[i].Cmd != UNI_GetX -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_2071"
	(Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.ShWbMsg.Proc != Home);
endruleset;
Invariant "rule_2072"
	(Sta.MemData != Sta.CurrData -> Sta.ShWbMsg.Proc != Home);
Invariant "rule_2073"
	(Sta.MemData = Sta.CurrData -> Sta.ShWbMsg.Proc != Home);
Invariant "rule_2074"
	(Sta.ShWbMsg.Proc != Home -> Sta.ShWbMsg.Data != Sta.PrevData);
Invariant "rule_2075"
	(Sta.ShWbMsg.Data != Sta.PrevData -> Sta.ShWbMsg.Proc != Home);


ruleset j : NODE do
Invariant "rule_2076"
	(Sta.UniMsg[j].Data != Sta.PrevData -> Sta.ShWbMsg.Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_2077"
	(Sta.ShWbMsg.Proc != Home -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2078"
		(j != i) ->	(Sta.ShWbMsg.Proc != j -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_2079"
	(Sta.ShWbMsg.Proc != j -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2080"
		(j != i) ->	(Sta.ShWbMsg.Proc != j -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2081"
		(i != j) ->	(Sta.Dir.HeadPtr != i -> Sta.ShWbMsg.Proc != j);
endruleset;


ruleset j : NODE do
Invariant "rule_2082"
	(Sta.ShWbMsg.Proc != j -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_2083"
	(Sta.ShWbMsg.Proc != j -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2084"
		(j != i) ->	(Sta.ShWbMsg.Proc = j -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_2085"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.ShWbMsg.Proc = j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2086"
		(j != i) ->	(Sta.ShWbMsg.Proc = j -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2087"
		(j != i) ->	(Sta.ShWbMsg.Proc = j -> Sta.Dir.HeadPtr = i);
endruleset;


ruleset j : NODE do
Invariant "rule_2088"
	(Sta.ShWbMsg.Proc = j -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_2089"
	(Sta.ShWbMsg.Proc = j -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2090"
		(j != i) ->	(Sta.UniMsg[j].Cmd != UNI_Nak -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2091"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_2092"
	(Sta.Proc[i].CacheState != CACHE_E -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_2093"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_2094"
	(Sta.UniMsg[i].Cmd != UNI_Nak -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_2095"
	(Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2096"
		(j != i) ->	(Sta.UniMsg[j].Data != Sta.CurrData -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2097"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2098"
		(j != i) ->	(Sta.RpMsg[j].Cmd != RP_Replace -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2099"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2100"
		(j != i) ->	(Sta.UniMsg[j].Cmd != UNI_Get -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2101"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_2102"
	(Sta.Proc[i].ProcCmd != NODE_None -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_2103"
	(Sta.Proc[i].ProcCmd = NODE_None -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2104"
		(j != i) ->	(Sta.Proc[j].CacheData != Sta.CurrData -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2105"
		(j != i) ->	(Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_2106"
	(Sta.ShWbMsg.Cmd != SHWB_FAck -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_2107"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_2108"
	(Sta.Proc[i].CacheState != CACHE_S -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_2109"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2110"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_E -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2111"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_2112"
	(Sta.WbMsg.Cmd != WB_Wb -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_2113"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2114"
		(j != i) ->	(Sta.UniMsg[j].Proc != i -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2115"
		(j != i) ->	(Sta.UniMsg[j].Proc = i -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_2116"
	(Sta.UniMsg[i].Proc != Home -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_2117"
	(Sta.Proc[i].CacheData != Sta.PrevData -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2118"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_I -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2119"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_I -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_2120"
	(Sta.Dir.HeadPtr != i -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_2121"
	(Sta.Dir.HeadPtr = i -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_2122"
	(Sta.UniMsg[i].Cmd != UNI_Put -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_2123"
	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_2124"
	(Sta.UniMsg[i].Cmd != UNI_GetX -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_2125"
	(Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_2126"
	(Sta.MemData != Sta.CurrData -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_2127"
	(Sta.MemData = Sta.CurrData -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_2128"
	(Sta.Proc[i].CacheData != Sta.PrevData -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_2129"
	(Sta.ShWbMsg.Data != Sta.PrevData -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2130"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.PrevData -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2131"
		(j != i) ->	(Sta.UniMsg[j].Data != Sta.PrevData -> Sta.Proc[i].CacheData != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_2132"
	(Sta.UniMsg[j].Data != Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_2133"
	(Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_2134"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2135"
		(j != i) ->	(Sta.UniMsg[j].Cmd != UNI_Nak -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_2136"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_2137"
	(Sta.UniMsg[j].Cmd != UNI_Nak -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_2138"
	(Sta.UniMsg[j].Cmd != UNI_Nak -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_2139"
	(Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2140"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_2141"
	(Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_2142"
	(Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_2143"
	(Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_2144"
	(Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_2145"
	(Sta.Proc[i].ProcCmd != NODE_None -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_2146"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2147"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_2148"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_2149"
	(Sta.Proc[i].CacheState != CACHE_E -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_2150"
	(Sta.Dir.HeadPtr != i -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_2151"
	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_2152"
	(Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_2153"
	(Sta.Proc[i].CacheState != CACHE_E -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2154"
		(i != j) ->	(Sta.Proc[i].CacheState != CACHE_E -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_2155"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_2156"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Proc[i].ProcCmd = NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_2157"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2158"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_2159"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset i : NODE do
Invariant "rule_2160"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_2161"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.Dir.HeadPtr = i);
endruleset;


ruleset i : NODE do
Invariant "rule_2162"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_2163"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2164"
	(Sta.Proc[i].CacheState = CACHE_E -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2165"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_E -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_2166"
	(Sta.Proc[i].ProcCmd = NODE_None -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_2167"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_2168"
	(Sta.UniMsg[i].Cmd != UNI_Nak -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_2169"
	(Sta.UniMsg[i].Cmd != UNI_Nak -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2170"
		(i != j) ->	(Sta.UniMsg[i].Cmd != UNI_Nak -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_2171"
	(Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_2172"
	(Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_2173"
	(Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_2174"
	(Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2175"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_2176"
	(Sta.UniMsg[j].Data != Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2177"
	(Sta.UniMsg[j].Data != Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_2178"
	(Sta.UniMsg[j].Data != Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_2179"
	(Sta.UniMsg[j].Data != Sta.CurrData -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2180"
		(j != i) ->	(Sta.UniMsg[j].Data != Sta.CurrData -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_2181"
	(Sta.UniMsg[j].Data != Sta.CurrData -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_2182"
	(Sta.UniMsg[j].Data != Sta.CurrData -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_2183"
	(Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_2184"
	(Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2185"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_2186"
	(Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_2187"
	(Sta.UniMsg[j].Data = Sta.CurrData -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2188"
		(j != i) ->	(Sta.RpMsg[j].Cmd != RP_Replace -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_2189"
	(Sta.RpMsg[j].Cmd != RP_Replace -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_2190"
	(Sta.RpMsg[j].Cmd != RP_Replace -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2191"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_2192"
	(Sta.RpMsg[j].Cmd = RP_Replace -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_2193"
	(Sta.RpMsg[j].Cmd = RP_Replace -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_2194"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2195"
		(j != i) ->	(Sta.UniMsg[j].Cmd != UNI_Get -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_2196"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_2197"
	(Sta.UniMsg[j].Cmd != UNI_Get -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_2198"
	(Sta.UniMsg[j].Cmd != UNI_Get -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_2199"
	(Sta.UniMsg[j].Cmd = UNI_Get -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2200"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_2201"
	(Sta.UniMsg[j].Cmd = UNI_Get -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_2202"
	(Sta.UniMsg[j].Cmd = UNI_Get -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_2203"
	(Sta.UniMsg[j].Cmd = UNI_Get -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_2204"
	(Sta.Proc[i].ProcCmd != NODE_None -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_2205"
	(Sta.Proc[i].ProcCmd != NODE_None -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_2206"
	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_2207"
	(Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_2208"
	(Sta.Proc[i].ProcCmd != NODE_None -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2209"
		(i != j) ->	(Sta.Proc[i].ProcCmd != NODE_None -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_2210"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.Proc[i].ProcCmd = NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_2211"
	(Sta.Proc[i].ProcCmd = NODE_None -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_2212"
	(Sta.Proc[i].ProcCmd = NODE_None -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_2213"
	(Sta.Proc[i].ProcCmd = NODE_None -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2214"
	(Sta.Proc[i].ProcCmd = NODE_None -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2215"
		(i != j) ->	(Sta.Proc[i].ProcCmd = NODE_None -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_2216"
	(Sta.Proc[j].CacheData != Sta.CurrData -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2217"
		(j != i) ->	(Sta.Proc[j].CacheData != Sta.CurrData -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_2218"
	(Sta.Proc[j].CacheData != Sta.CurrData -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_2219"
	(Sta.Proc[j].CacheData != Sta.CurrData -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_2220"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Proc[j].CacheData = Sta.CurrData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2221"
		(j != i) ->	(Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_2222"
	(Sta.Proc[j].CacheData = Sta.CurrData -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_2223"
	(Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_2224"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_2225"
	(Sta.ShWbMsg.Cmd != SHWB_FAck -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_2226"
	(Sta.ShWbMsg.Cmd != SHWB_FAck -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_2227"
	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;
Invariant "rule_2228"
	(Sta.ShWbMsg.Cmd != SHWB_FAck -> Sta.ShWbMsg.Data != Sta.PrevData);


ruleset j : NODE do
Invariant "rule_2229"
	(Sta.ShWbMsg.Cmd != SHWB_FAck -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_2230"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_2231"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.ShWbMsg.Cmd = SHWB_FAck);
endruleset;


ruleset i : NODE do
Invariant "rule_2232"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_2233"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;
Invariant "rule_2234"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.ShWbMsg.Data != Sta.PrevData);


ruleset j : NODE do
Invariant "rule_2235"
	(Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2236"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_2237"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_2238"
	(Sta.Proc[i].CacheState != CACHE_S -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_2239"
	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_2240"
	(Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_2241"
	(Sta.Proc[i].CacheState != CACHE_S -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2242"
		(i != j) ->	(Sta.Proc[i].CacheState != CACHE_S -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2243"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_S -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_2244"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset i : NODE do
Invariant "rule_2245"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_2246"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_2247"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2248"
	(Sta.Proc[i].CacheState = CACHE_S -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2249"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_S -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_2250"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2251"
		(j != i) ->	(Sta.UniMsg[j].Proc = i -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2252"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_E -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2253"
		(i != j) ->	(Sta.Dir.HeadPtr != i -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2254"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.Proc[j].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_2255"
	(Sta.Proc[j].CacheState != CACHE_E -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_2256"
	(Sta.Proc[j].CacheState != CACHE_E -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_2257"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2258"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_E -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2259"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_E -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2260"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_E -> Sta.Dir.HeadPtr = i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2261"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_E -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_2262"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_2263"
	(Sta.Proc[j].CacheState = CACHE_E -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_2264"
	(Sta.WbMsg.Cmd != WB_Wb -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_2265"
	(Sta.Dir.HeadPtr != i -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset i : NODE do
Invariant "rule_2266"
	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;
Invariant "rule_2267"
	(Sta.WbMsg.Cmd != WB_Wb -> Sta.ShWbMsg.Data != Sta.PrevData);


ruleset j : NODE do
Invariant "rule_2268"
	(Sta.WbMsg.Cmd != WB_Wb -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_2269"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_2270"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.Dir.HeadPtr = i);
endruleset;


ruleset i : NODE do
Invariant "rule_2271"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;
Invariant "rule_2272"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.ShWbMsg.Data != Sta.PrevData);


ruleset j : NODE do
Invariant "rule_2273"
	(Sta.WbMsg.Cmd = WB_Wb -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2274"
		(j != i) ->	(Sta.UniMsg[j].Proc != i -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2275"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_I -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2276"
		(j != i) ->	(Sta.UniMsg[j].Proc != i -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2277"
		(j != i) ->	(Sta.UniMsg[j].Proc != i -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2278"
		(j != i) ->	(Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2279"
		(j != i) ->	(Sta.UniMsg[j].Proc = i -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2280"
		(j != i) ->	(Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2281"
		(j != i) ->	(Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2282"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_I -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2283"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_I -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_2284"
	(Sta.Dir.HeadPtr != i -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_2285"
	(Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_2286"
	(Sta.UniMsg[i].Cmd != UNI_Put -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_2287"
	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_2288"
	(Sta.UniMsg[i].Cmd != UNI_GetX -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_2289"
	(Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_2290"
	(Sta.MemData != Sta.CurrData -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_2291"
	(Sta.MemData = Sta.CurrData -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE do
Invariant "rule_2292"
	(Sta.UniMsg[i].Proc != Home -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_2293"
	(Sta.ShWbMsg.Data != Sta.PrevData -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2294"
		(i != j) ->	(Sta.UniMsg[i].Proc != Home -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2295"
		(j != i) ->	(Sta.UniMsg[j].Data != Sta.PrevData -> Sta.UniMsg[i].Proc != Home);
endruleset;


ruleset j : NODE do
Invariant "rule_2296"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_2297"
	(Sta.Proc[j].CacheState != CACHE_I -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_2298"
	(Sta.Proc[j].CacheState = CACHE_I -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_2299"
	(Sta.Proc[j].CacheState = CACHE_I -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_2300"
	(Sta.Dir.HeadPtr != i -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2301"
		(i != j) ->	(Sta.Dir.HeadPtr != i -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_2302"
	(Sta.Dir.HeadPtr = i -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2303"
		(i != j) ->	(Sta.Dir.HeadPtr = i -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_2304"
	(Sta.UniMsg[i].Cmd != UNI_Put -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2305"
		(i != j) ->	(Sta.UniMsg[i].Cmd != UNI_Put -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_2306"
	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2307"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_2308"
	(Sta.UniMsg[i].Cmd != UNI_GetX -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2309"
		(i != j) ->	(Sta.UniMsg[i].Cmd != UNI_GetX -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_2310"
	(Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2311"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;
Invariant "rule_2312"
	(Sta.MemData != Sta.CurrData -> Sta.ShWbMsg.Data != Sta.PrevData);


ruleset j : NODE do
Invariant "rule_2313"
	(Sta.MemData != Sta.CurrData -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;
Invariant "rule_2314"
	(Sta.MemData = Sta.CurrData -> Sta.ShWbMsg.Data != Sta.PrevData);


ruleset j : NODE do
Invariant "rule_2315"
	(Sta.MemData = Sta.CurrData -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_2316"
	(Sta.UniMsg[j].Data != Sta.PrevData -> Sta.ShWbMsg.Data != Sta.PrevData);
endruleset;


ruleset j : NODE do
Invariant "rule_2317"
	(Sta.ShWbMsg.Data != Sta.PrevData -> Sta.UniMsg[j].Data != Sta.PrevData);
endruleset;


ruleset i : NODE do
Invariant "rule_2318"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.Dirty = false -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2319"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.Local = false -> Sta.Dir.Dirty = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2320"
	(Sta.Dir.Local = false & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Dir.Dirty = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2321"
	(Sta.Proc[i].InvMarked = true & Sta.Dir.Local = false -> Sta.Dir.Dirty = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2322"
	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.Dir.Local = false -> Sta.Dir.Dirty = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2323"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.Dirty = false -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2324"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.UniMsg[i].Proc = j -> Sta.Dir.Dirty = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2325"
	(Sta.Dir.Pending = false & Sta.Dir.InvSet[i] = true -> Sta.Dir.Dirty = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2326"
	(Sta.Dir.HeadVld = true & Sta.Dir.InvSet[i] = true -> Sta.Dir.Dirty = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2327"
	(Sta.Dir.Dirty = false & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2328"
	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Dir.Dirty = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2329"
	(Sta.Proc[i].InvMarked = true & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Dir.Dirty = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2330"
	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[i].CacheState = CACHE_S -> Sta.Dir.Dirty = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2331"
	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Dir.Dirty = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2332"
		(i != j) ->	(Sta.Dir.HeadVld = true & Sta.Dir.Dirty = false -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2333"
		(j != i) ->	(Sta.Dir.Dirty = false & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2334"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.Dir.Dirty = false -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2335"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.Dirty = false -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2336"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.Dirty = false -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2337"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.Dirty = false -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2338"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Dir.Dirty = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2339"
	(Sta.Dir.HeadVld = true & Sta.Proc[i].InvMarked = true -> Sta.Dir.Dirty = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2340"
	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.Dir.HeadVld = true -> Sta.Dir.Dirty = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2341"
	(Sta.Dir.Dirty = false & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2342"
	(Sta.Dir.Dirty = false & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_2343"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Dir.Dirty = false -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_2344"
	(Sta.Dir.Dirty = false & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2345"
		(j != i) ->	(Sta.Dir.Dirty = false & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_2346"
	(Sta.Dir.Dirty = false & Sta.Proc[j].CacheState != CACHE_I -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2347"
		(j != i) ->	(Sta.Dir.Dirty = false & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_2348"
	(Sta.Dir.Dirty = false & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_2349"
	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Dir.Dirty = true);
endruleset;


ruleset i : NODE do
Invariant "rule_2350"
	(Sta.Dir.Local = false & Sta.Dir.Dirty = true -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2351"
	(Sta.Dir.Local = false & Sta.Dir.Dirty = true -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2352"
	(Sta.Dir.Local = false & Sta.Dir.Dirty = true -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_2353"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.Dirty = true -> Sta.Dir.Local = true);
endruleset;


ruleset i : NODE do
Invariant "rule_2354"
	(Sta.Dir.Dirty = true & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Dir.Local = true);
endruleset;


ruleset i : NODE do
Invariant "rule_2355"
	(Sta.Proc[i].InvMarked = true & Sta.Dir.Dirty = true -> Sta.Dir.Local = true);
endruleset;


ruleset i : NODE do
Invariant "rule_2356"
	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.Dir.Dirty = true -> Sta.Dir.Local = true);
endruleset;


ruleset j : NODE do
Invariant "rule_2357"
	(Sta.Proc[j].CacheState != CACHE_S & Sta.Proc[j].CacheState != CACHE_I -> Sta.Dir.Dirty = true);
endruleset;


ruleset i : NODE do
Invariant "rule_2358"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Dir.Dirty = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2359"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.Dirty = true -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2360"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Dir.Dirty = true -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE do
Invariant "rule_2361"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.Dirty = true -> Sta.Dir.Pending = true);
endruleset;


ruleset i : NODE do
Invariant "rule_2362"
	(Sta.Dir.Pending = false & Sta.Dir.Dirty = true -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2363"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.Dirty = true -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2364"
	(Sta.Dir.HeadVld = true & Sta.Dir.Dirty = true -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2365"
	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.Dirty = true);
endruleset;


ruleset i : NODE do
Invariant "rule_2366"
	(Sta.Dir.Dirty = true & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_2367"
	(Sta.Proc[i].InvMarked = true & Sta.Dir.Dirty = true -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_2368"
	(Sta.Dir.Dirty = true & Sta.Proc[i].CacheState = CACHE_S -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_2369"
	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.Dir.Dirty = true -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_2370"
	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Dir.Dirty = true -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2371"
	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Dir.Dirty = true -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_2372"
	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Dir.Dirty = true -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2373"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_GetX & Sta.Dir.Dirty = true -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2374"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadVld = true -> Sta.Dir.Dirty = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2375"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Proc = i -> Sta.Dir.Dirty = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2376"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadPtr = i -> Sta.Dir.Dirty = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2377"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.Dirty = true -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2378"
	(Sta.Dir.HeadVld = true & Sta.Dir.Dirty = true -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2379"
	(Sta.Dir.HeadVld = true & Sta.Dir.Dirty = true -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_2380"
	(Sta.Proc[i].InvMarked = true & Sta.Dir.Dirty = true -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2381"
	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.Dir.Dirty = true -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2382"
	(Sta.Proc[i].CacheState != CACHE_S & Sta.Proc[i].CacheState != CACHE_I -> Sta.Dir.Dirty = true);
endruleset;


ruleset j : NODE do
Invariant "rule_2383"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.Dirty = true);
endruleset;


ruleset j : NODE do
Invariant "rule_2384"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.Dirty = true);
endruleset;


ruleset j : NODE do
Invariant "rule_2385"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.Dirty = true);
endruleset;


ruleset j : NODE do
Invariant "rule_2386"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.Dirty = true);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2387"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.Dirty = true);
endruleset;


ruleset j : NODE do
Invariant "rule_2388"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.Dirty = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2389"
		(i != j) ->	(Sta.Dir.InvSet[i] = true & Sta.Dir.ShrSet[i] = false -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2390"
		(i != j) ->	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2391"
		(i != j) ->	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2392"
		(i != j) ->	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2393"
	(Sta.WbMsg.Data = Sta.CurrData & Sta.ShWbMsg.Data != Sta.CurrData -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2394"
	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2395"
		(j != i) ->	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2396"
	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.WbMsg.Data != Sta.CurrData -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2397"
		(i != j) ->	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2398"
	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2399"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.ShWbMsg.Data = Sta.CurrData -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2400"
		(j != i) ->	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2401"
	(Sta.UniMsg[j].Cmd != UNI_Put & Sta.Proc[j].InvMarked = true -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2402"
	(Sta.Proc[j].InvMarked = true & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2403"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].InvMarked = true -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2404"
	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.Proc[j].InvMarked = true -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2405"
	(Sta.Proc[j].CacheState != CACHE_S & Sta.Proc[j].CacheState != CACHE_I -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2406"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheState = CACHE_S -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2407"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Proc[j].CacheState = CACHE_S -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2408"
		(i != j) ->	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2409"
		(i != j) ->	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2410"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2411"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2412"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2413"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Proc[i].InvMarked = true -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2414"
		(i != j) ->	(Sta.Dir.InvSet[i] = true & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2415"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.Dir.InvSet[i] = true -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2416"
		(i != j) ->	(Sta.Dir.InvSet[i] = true & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2417"
		(i != j) ->	(Sta.ShWbMsg.Proc = i & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2418"
		(i != j) ->	(Sta.ShWbMsg.Proc = i & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2419"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.UniMsg[j].Cmd != UNI_Put -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2420"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.UniMsg[j].Cmd != UNI_Put -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2421"
		(j != i) ->	(Sta.UniMsg[j].Cmd != UNI_Put & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2422"
	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2423"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2424"
	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2425"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2426"
	(Sta.Proc[j].ProcCmd = NODE_None & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2427"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_None -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2428"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_None & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2429"
		(i != j) ->	(Sta.WbMsg.Data = Sta.CurrData & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2430"
	(Sta.WbMsg.Data = Sta.CurrData & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2431"
		(i != j) ->	(Sta.Proc[i].ProcCmd != NODE_Get & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2432"
		(i != j) ->	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_None -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2433"
		(i != j) ->	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.UniMsg[i].Cmd != UNI_Put -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2434"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd != NODE_Get -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2435"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Proc[j].ProcCmd != NODE_Get -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2436"
		(j != i) ->	(Sta.Proc[j].ProcCmd != NODE_Get & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2437"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Proc[i].CacheState != CACHE_I -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2438"
		(i != j) ->	(Sta.Proc[i].ProcCmd != NODE_Get & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2439"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2440"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2441"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_None -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2442"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Proc[i].CacheState = CACHE_S -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2443"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2444"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.UniMsg[i].Cmd != UNI_Put -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2445"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2446"
		(i != j) ->	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2447"
		(i != j) ->	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2448"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2449"
	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2450"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2451"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2452"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2453"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2454"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[i].Cmd != UNI_Put -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2455"
		(i != j) ->	(Sta.Proc[i].CacheState != CACHE_S & Sta.Proc[i].CacheState != CACHE_I -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2456"
	(Sta.ShWbMsg.Proc = j & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2457"
		(j != i) ->	(Sta.ShWbMsg.Proc = j & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2458"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2459"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2460"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2461"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2462"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2463"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2464"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2465"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheState != CACHE_I -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2466"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2467"
	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2468"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2469"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Proc[j].CacheState != CACHE_I -> Sta.Dir.ShrSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2470"
		(i != j) ->	(Sta.Dir.ShrSet[i] = false & Sta.Dir.ShrSet[j] = true -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2471"
		(i != j) ->	(Sta.Dir.InvSet[i] = true & Sta.Dir.ShrSet[j] = true -> Sta.Dir.ShrSet[i] = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2472"
		(i != j) ->	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2473"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2474"
		(i != j) ->	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2475"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.ShWbMsg.Data != Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_2476"
	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2477"
		(j != i) ->	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_2478"
	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2479"
		(j != i) ->	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_2480"
	(Sta.Proc[j].InvMarked = true & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_2481"
	(Sta.Proc[j].InvMarked = true & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_2482"
	(Sta.Proc[j].InvMarked = true & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Data = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_2483"
	(Sta.Proc[j].InvMarked = true & Sta.Dir.ShrSet[j] = true -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2484"
	(Sta.Proc[j].InvMarked = true & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_2485"
	(Sta.UniMsg[j].Cmd != UNI_Put & Sta.Dir.ShrSet[j] = true -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2486"
	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.Dir.ShrSet[j] = true -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2487"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Dir.ShrSet[j] = true -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2488"
	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.Dir.ShrSet[j] = true -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2489"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Dir.ShrSet[j] = true -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_2490"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_2491"
	(Sta.Proc[j].CacheState = CACHE_S & Sta.Dir.ShrSet[j] = true -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2492"
	(Sta.Proc[j].CacheState = CACHE_S & Sta.Dir.ShrSet[j] = true -> Sta.Proc[j].CacheData = Sta.CurrData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2493"
		(i != j) ->	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2494"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2495"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.Dir.ShrSet[j] = true -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2496"
		(i != j) ->	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Dir.ShrSet[j] = true -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2497"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2498"
		(i != j) ->	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2499"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2500"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Dir.ShrSet[j] = true -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2501"
		(i != j) ->	(Sta.Dir.InvSet[i] = true & Sta.Dir.ShrSet[j] = true -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2502"
		(i != j) ->	(Sta.Dir.InvSet[i] = true & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2503"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2504"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.Dir.ShrSet[j] = true -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2505"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Nak & Sta.Dir.ShrSet[j] = true -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2506"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.Dir.ShrSet[j] = true -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2507"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Dir.ShrSet[j] = true -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2508"
		(i != j) ->	(Sta.ShWbMsg.Proc = i & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2509"
		(i != j) ->	(Sta.ShWbMsg.Proc = i & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2510"
		(j != i) ->	(Sta.UniMsg[j].Cmd != UNI_Put & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_2511"
	(Sta.UniMsg[j].Cmd = UNI_Put & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Data = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_2512"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_2513"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2514"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_2515"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_2516"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_2517"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2518"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Dir.ShrSet[j] = true -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2519"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_2520"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_2521"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2522"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Dir.ShrSet[j] = true -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2523"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_None & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2524"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[i].Data = Sta.CurrData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2525"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[i].Data = Sta.CurrData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2526"
		(i != j) ->	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.Proc[i].ProcCmd = NODE_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2527"
		(i != j) ->	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2528"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[i].Data = Sta.CurrData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2529"
		(i != j) ->	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2530"
		(j != i) ->	(Sta.Proc[j].ProcCmd != NODE_Get & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_2531"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.Proc[j].ProcCmd = NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_2532"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.Proc[j].ProcCmd = NODE_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2533"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Dir.ShrSet[j] = true -> Sta.Proc[j].ProcCmd = NODE_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2534"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2535"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.Proc[i].ProcCmd = NODE_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2536"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2537"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2538"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2539"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2540"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2541"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2542"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2543"
		(j != i) ->	(Sta.Dir.ShrSet[j] = true & Sta.Proc[i].CacheState != CACHE_I -> Sta.Proc[i].CacheData = Sta.CurrData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2544"
		(i != j) ->	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2545"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_S & Sta.Dir.ShrSet[j] = true -> Sta.Proc[i].CacheData = Sta.CurrData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2546"
		(i != j) ->	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_2547"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_2548"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2549"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2550"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2551"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.Dir.ShrSet[j] = true -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2552"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Nak & Sta.Dir.ShrSet[j] = true -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2553"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Dir.ShrSet[j] = true -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2554"
		(i != j) ->	(Sta.UniMsg[i].Cmd != UNI_Put & Sta.Dir.ShrSet[j] = true -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2555"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2556"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2557"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2558"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_2559"
	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.Dir.ShrSet[j] = true -> Sta.ShWbMsg.Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2560"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Dir.ShrSet[j] = true -> Sta.ShWbMsg.Proc != j);
endruleset;


ruleset j : NODE do
Invariant "rule_2561"
	(Sta.ShWbMsg.Proc = j & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2562"
		(j != i) ->	(Sta.ShWbMsg.Proc = j & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_2563"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_2564"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2565"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2566"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_2567"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2568"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Data = Sta.CurrData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2569"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Data = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_2570"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2571"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2572"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Dir.ShrSet[j] = true -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2573"
	(Sta.Dir.ShrSet[j] = true & Sta.Proc[j].CacheState != CACHE_I -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2574"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_2575"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Dir.ShrSet[j] = true -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_2576"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_2577"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2578"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2579"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.Dir.ShrSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_2580"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Dir.ShrSet[j] = true -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_2581"
	(Sta.Dir.ShrSet[j] = true & Sta.Proc[j].CacheState != CACHE_I -> Sta.Proc[j].CacheData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_2582"
	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.RpMsg[i].Cmd != RP_Replace -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2583"
	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2584"
	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2585"
	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.UniMsg[i].Cmd != UNI_GetX -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2586"
	(Sta.WbMsg.Data = Sta.CurrData & Sta.ShWbMsg.Data != Sta.CurrData -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2587"
	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.WbMsg.Data != Sta.CurrData -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2588"
	(Sta.Dir.ShrSet[i] = false & Sta.Dir.Local = false -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2589"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.ShrSet[i] = false -> Sta.Dir.Local = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2590"
		(i != j) ->	(Sta.Dir.InvSet[i] = true & Sta.Dir.ShrSet[i] = false -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2591"
		(i != j) ->	(Sta.Dir.ShrSet[i] = false & Sta.Dir.InvSet[j] = true -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2592"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_S & Sta.Proc[j].CacheState != CACHE_I -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2593"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheState = CACHE_S -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2594"
	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.RpMsg[i].Cmd != RP_Replace -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2595"
	(Sta.RpMsg[i].Cmd != RP_Replace & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2596"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2597"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2598"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheState != CACHE_I -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2599"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheState = CACHE_S -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2600"
	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2601"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.ShrSet[i] = false -> Sta.Dir.Pending = true);
endruleset;


ruleset i : NODE do
Invariant "rule_2602"
	(Sta.Dir.Pending = false & Sta.Dir.ShrSet[i] = false -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2603"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.ShrSet[i] = false -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2604"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.ShrSet[i] = false -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2605"
	(Sta.Dir.ShrSet[i] = false & Sta.Dir.ShrVld = true -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2606"
	(Sta.Dir.HeadVld = true & Sta.Dir.ShrSet[i] = false -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2607"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2608"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2609"
	(Sta.Proc[i].ProcCmd != NODE_Get & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2610"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_None -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2611"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.UniMsg[i].Cmd != UNI_Put -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2612"
	(Sta.Proc[i].CacheState = CACHE_I & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2613"
	(Sta.Proc[i].ProcCmd = NODE_Get & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2614"
	(Sta.Proc[i].ProcCmd != NODE_None & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2615"
	(Sta.Proc[i].CacheState != CACHE_S & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2616"
	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2617"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2618"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2619"
	(Sta.Proc[i].CacheState != CACHE_S & Sta.Proc[i].CacheState != CACHE_I -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2620"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2621"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2622"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2623"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheState != CACHE_I -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2624"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2625"
	(Sta.RpMsg[i].Cmd != RP_Replace & Sta.Dir.ShrSet[i] = true -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2626"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.ShrSet[i] = true -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2627"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.Dir.ShrSet[i] = true -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2628"
	(Sta.Dir.ShrSet[i] = true & Sta.UniMsg[i].Cmd != UNI_GetX -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2629"
	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.Dir.ShrSet[i] = true -> Sta.RpMsg[i].Cmd = RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2630"
	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.Dir.ShrSet[i] = true -> Sta.UniMsg[i].Cmd = UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2631"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.Local = false -> Sta.Dir.ShrSet[i] = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2632"
		(i != j) ->	(Sta.Dir.InvSet[i] = true & Sta.Dir.InvSet[j] = true -> Sta.Dir.ShrSet[i] = true);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2633"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Dir.ShrSet[i] = true -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2634"
		(i != j) ->	(Sta.Dir.ShrSet[i] = true & Sta.Proc[j].CacheState = CACHE_S -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2635"
	(Sta.RpMsg[i].Cmd != RP_Replace & Sta.Dir.ShrSet[i] = true -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_2636"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.ShrSet[i] = true -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2637"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.Dir.ShrSet[i] = true -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2638"
	(Sta.Dir.ShrSet[i] = true & Sta.Proc[i].CacheState != CACHE_I -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2639"
	(Sta.Dir.ShrSet[i] = true & Sta.Proc[i].CacheState = CACHE_S -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2640"
	(Sta.RpMsg[i].Cmd != RP_Replace & Sta.Dir.ShrSet[i] = true -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2641"
	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Dir.ShrSet[i] = true -> Sta.RpMsg[i].Cmd = RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2642"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Dir.ShrSet[i] = true -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_2643"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Dir.ShrSet[i] = true -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_2644"
	(Sta.Dir.ShrSet[i] = true & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.RpMsg[i].Cmd = RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2645"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.Dir.ShrSet[i] = true -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_2646"
	(Sta.Dir.Pending = false & Sta.Dir.InvSet[i] = true -> Sta.Dir.ShrSet[i] = true);
endruleset;


ruleset i : NODE do
Invariant "rule_2647"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.ShrVld = true -> Sta.Dir.ShrSet[i] = true);
endruleset;


ruleset i : NODE do
Invariant "rule_2648"
	(Sta.Dir.HeadVld = true & Sta.Dir.InvSet[i] = true -> Sta.Dir.ShrSet[i] = true);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2649"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.ShrSet[i] = true -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2650"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.ShrSet[i] = true -> Sta.Proc[i].ProcCmd = NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_2651"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.ShrSet[i] = true -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_2652"
	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.Dir.ShrSet[i] = true -> Sta.UniMsg[i].Data = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_2653"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.ShrSet[i] = true -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_2654"
	(Sta.Dir.ShrSet[i] = true & Sta.Proc[i].CacheState != CACHE_I -> Sta.Proc[i].CacheData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_2655"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.Dir.ShrSet[i] = true -> Sta.Proc[i].CacheState != CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_2656"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.Dir.ShrSet[i] = true -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_2657"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.Dir.ShrSet[i] = true -> Sta.Proc[i].ProcCmd = NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_2658"
	(Sta.Dir.ShrSet[i] = true & Sta.Proc[i].CacheState = CACHE_S -> Sta.Proc[i].CacheData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_2659"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.Dir.ShrSet[i] = true -> Sta.Proc[i].CacheState = CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_2660"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.Dir.ShrSet[i] = true -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_2661"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.Dir.ShrSet[i] = true -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2662"
		(i != j) ->	(Sta.Dir.ShrSet[i] = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2663"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.Dir.ShrSet[i] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2664"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.ShrSet[i] = true -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2665"
		(j != i) ->	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Dir.ShrSet[i] = true -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2666"
		(i != j) ->	(Sta.Dir.ShrSet[i] = true & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2667"
		(i != j) ->	(Sta.Dir.ShrSet[i] = true & Sta.Proc[j].CacheState != CACHE_I -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2668"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Dir.ShrSet[i] = true -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2669"
		(i != j) ->	(Sta.Dir.ShrSet[i] = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2670"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.Dir.ShrSet[i] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE do
Invariant "rule_2671"
	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2672"
	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2673"
	(Sta.Dir.Local = true & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2674"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2675"
		(i != j) ->	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2676"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2677"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2678"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2679"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2680"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2681"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd != NODE_GetX -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2682"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[i].ProcCmd != NODE_GetX -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2683"
	(Sta.UniMsg[i].Cmd = UNI_Nak & Sta.Proc[i].ProcCmd != NODE_GetX -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2684"
		(i != j) ->	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].ProcCmd != NODE_GetX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE do
Invariant "rule_2685"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2686"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2687"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].ProcCmd != NODE_GetX -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_2688"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.InvSet[i] = true -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2689"
	(Sta.Dir.InvSet[i] = true & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2690"
	(Sta.Dir.InvSet[i] = true & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2691"
	(Sta.UniMsg[i].Cmd != UNI_PutX & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2692"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.ShrVld = true -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2693"
	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Dir.ShrVld = true -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2694"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.Dir.ShrVld = true -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2695"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.WbMsg.Data != Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2696"
	(Sta.WbMsg.Data = Sta.CurrData & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2697"
	(Sta.Dir.HeadVld = false & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2698"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2699"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.HeadPtr != i -> Sta.Proc[i].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2700"
		(i != j) ->	(Sta.Dir.HeadVld = true & Sta.Proc[i].ProcCmd != NODE_GetX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2701"
		(i != j) ->	(Sta.Proc[i].ProcCmd != NODE_Get & Sta.Proc[i].ProcCmd != NODE_GetX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2702"
		(i != j) ->	(Sta.Proc[i].ProcCmd != NODE_GetX & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2703"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.Proc[i].ProcCmd != NODE_GetX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2704"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[i].ProcCmd != NODE_GetX -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2705"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[i].ProcCmd != NODE_GetX -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2706"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[i].ProcCmd != NODE_GetX -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE do
Invariant "rule_2707"
	(Sta.Proc[i].ProcCmd != NODE_Get & Sta.Proc[i].ProcCmd != NODE_GetX -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_2708"
	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Dir.Local = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2709"
	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2710"
		(i != j) ->	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2711"
		(i != j) ->	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2712"
		(i != j) ->	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2713"
	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_2714"
	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_2715"
	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_2716"
	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2717"
	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_2718"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Proc[i].ProcCmd = NODE_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2719"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Proc[i].ProcCmd = NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2720"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Proc[i].ProcCmd = NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2721"
	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2722"
	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2723"
	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2724"
	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.UniMsg[i].Cmd = UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_2725"
	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2726"
	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2727"
	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2728"
	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Dir.HeadVld = true);
endruleset;


ruleset i : NODE do
Invariant "rule_2729"
	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_2730"
	(Sta.Proc[i].ProcCmd = NODE_GetX & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Dir.HeadPtr = i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2731"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadVld = true -> Sta.Proc[i].ProcCmd = NODE_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2732"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Proc = i -> Sta.Proc[i].ProcCmd = NODE_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2733"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadPtr = i -> Sta.Proc[i].ProcCmd = NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_2734"
	(Sta.WbMsg.Data = Sta.CurrData & Sta.ShWbMsg.Data != Sta.CurrData -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2735"
	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2736"
		(j != i) ->	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.UniMsg[j].Proc = i -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2737"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.ShWbMsg.Data != Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_2738"
	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2739"
		(j != i) ->	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_2740"
	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Proc[j].CacheState = CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_2741"
	(Sta.WbMsg.Data = Sta.CurrData & Sta.ShWbMsg.Data != Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_2742"
	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_2743"
	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.ShWbMsg.Data != Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_2744"
	(Sta.WbMsg.Data = Sta.CurrData & Sta.ShWbMsg.Data != Sta.CurrData -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2745"
		(i != j) ->	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.ShWbMsg.Proc != i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2746"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.ShWbMsg.Data != Sta.CurrData -> Sta.ShWbMsg.Proc = i);
endruleset;


ruleset j : NODE do
Invariant "rule_2747"
	(Sta.UniMsg[j].Data != Sta.CurrData & Sta.UniMsg[j].Cmd != UNI_Put -> Sta.ShWbMsg.Data != Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_2748"
	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2749"
		(j != i) ->	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_2750"
	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2751"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Put & Sta.ShWbMsg.Data != Sta.CurrData -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_2752"
	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_2753"
	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2754"
	(Sta.WbMsg.Data = Sta.CurrData & Sta.ShWbMsg.Data != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2755"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.ShWbMsg.Data != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_2756"
	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2757"
		(i != j) ->	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE do
Invariant "rule_2758"
	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Dir.ShrVld = true -> Sta.ShWbMsg.Data != Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_2759"
	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_2760"
	(Sta.Proc[j].ProcCmd = NODE_None & Sta.UniMsg[j].Data != Sta.CurrData -> Sta.ShWbMsg.Data != Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_2761"
	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Proc[j].ProcCmd = NODE_None);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2762"
		(i != j) ->	(Sta.WbMsg.Data = Sta.CurrData & Sta.ShWbMsg.Data != Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE do
Invariant "rule_2763"
	(Sta.WbMsg.Data = Sta.CurrData & Sta.ShWbMsg.Data != Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_2764"
	(Sta.WbMsg.Data = Sta.CurrData & Sta.ShWbMsg.Data != Sta.CurrData -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2765"
	(Sta.WbMsg.Data = Sta.CurrData & Sta.ShWbMsg.Data != Sta.CurrData -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_2766"
	(Sta.WbMsg.Data = Sta.CurrData & Sta.ShWbMsg.Data != Sta.CurrData -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_2767"
	(Sta.WbMsg.Data = Sta.CurrData & Sta.ShWbMsg.Data != Sta.CurrData -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_2768"
	(Sta.WbMsg.Data = Sta.CurrData & Sta.ShWbMsg.Data != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2769"
		(i != j) ->	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE do
Invariant "rule_2770"
	(Sta.Proc[i].ProcCmd != NODE_Get & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.ShWbMsg.Data != Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_2771"
	(Sta.UniMsg[i].Data != Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_None -> Sta.ShWbMsg.Data != Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_2772"
	(Sta.UniMsg[i].Cmd != UNI_Put & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.ShWbMsg.Data != Sta.CurrData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2773"
		(i != j) ->	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE do
Invariant "rule_2774"
	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2775"
		(i != j) ->	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2776"
		(i != j) ->	(Sta.Dir.HeadVld = true & Sta.ShWbMsg.Data != Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2777"
		(j != i) ->	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2778"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.ShWbMsg.Data != Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2779"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.ShWbMsg.Data != Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2780"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.ShWbMsg.Data != Sta.CurrData -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2781"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.ShWbMsg.Data != Sta.CurrData -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2782"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.ShWbMsg.Data != Sta.CurrData -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2783"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.ShWbMsg.Data != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_2784"
	(Sta.UniMsg[j].Data != Sta.CurrData & Sta.Proc[j].ProcCmd != NODE_Get -> Sta.ShWbMsg.Data != Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_2785"
	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_2786"
	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd = NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_2787"
	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.ShWbMsg.Data != Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_2788"
	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.ShWbMsg.Data != Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_2789"
	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Proc[i].CacheState != CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_2790"
	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_2791"
	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_2792"
	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Proc[i].ProcCmd = NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_2793"
	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_2794"
	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_2795"
	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_2796"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.ShWbMsg.Data != Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_2797"
	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_2798"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.ShWbMsg.Data != Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_2799"
	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2800"
		(j != i) ->	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_2801"
	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_2802"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.ShWbMsg.Data != Sta.CurrData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2803"
		(j != i) ->	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_2804"
	(Sta.ShWbMsg.Data != Sta.CurrData & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Proc[j].CacheState != CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_2805"
	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.WbMsg.Data != Sta.CurrData -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2806"
		(i != j) ->	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2807"
	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2808"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.ShWbMsg.Data = Sta.CurrData -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2809"
		(j != i) ->	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.UniMsg[j].Proc = i -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2810"
	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2811"
		(j != i) ->	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE do
Invariant "rule_2812"
	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.WbMsg.Data != Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_2813"
	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_2814"
	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.ShWbMsg.Data = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_2815"
	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.WbMsg.Data != Sta.CurrData -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2816"
		(i != j) ->	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.ShWbMsg.Proc != i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2817"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.ShWbMsg.Data = Sta.CurrData -> Sta.ShWbMsg.Proc = i);
endruleset;


ruleset j : NODE do
Invariant "rule_2818"
	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.UniMsg[j].Data != Sta.CurrData -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_2819"
	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_2820"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.ShWbMsg.Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2821"
	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.WbMsg.Data != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2822"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.ShWbMsg.Data = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_2823"
	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2824"
		(i != j) ->	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE do
Invariant "rule_2825"
	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Dir.ShrVld = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2826"
	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.UniMsg[j].Data != Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_2827"
	(Sta.Proc[j].ProcCmd = NODE_None & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.ShWbMsg.Data = Sta.CurrData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2828"
		(i != j) ->	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.WbMsg.Data != Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE do
Invariant "rule_2829"
	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.WbMsg.Data != Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_2830"
	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.WbMsg.Data != Sta.CurrData -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2831"
	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.WbMsg.Data != Sta.CurrData -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE do
Invariant "rule_2832"
	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.WbMsg.Data != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2833"
		(i != j) ->	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE do
Invariant "rule_2834"
	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Proc[i].ProcCmd = NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_2835"
	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_2836"
	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2837"
		(i != j) ->	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE do
Invariant "rule_2838"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_None -> Sta.ShWbMsg.Data = Sta.CurrData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2839"
		(i != j) ->	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2840"
		(i != j) ->	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.Dir.HeadVld = true -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2841"
		(j != i) ->	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2842"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.ShWbMsg.Data = Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2843"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.ShWbMsg.Data = Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2844"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.ShWbMsg.Data = Sta.CurrData -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2845"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.ShWbMsg.Data = Sta.CurrData -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2846"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.ShWbMsg.Data = Sta.CurrData -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2847"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.ShWbMsg.Data = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_2848"
	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.UniMsg[j].Data != Sta.CurrData -> Sta.Proc[j].ProcCmd = NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_2849"
	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2850"
	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Proc[i].CacheState != CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_2851"
	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_2852"
	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_2853"
	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Proc[i].ProcCmd = NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_2854"
	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Proc[i].CacheState = CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_2855"
	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_2856"
	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2857"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.ShWbMsg.Data = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_2858"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.ShWbMsg.Data = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_2859"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.ShWbMsg.Data = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_2860"
	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.ShWbMsg.Data = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_2861"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.ShWbMsg.Data = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_2862"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.ShWbMsg.Data = Sta.CurrData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2863"
		(j != i) ->	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.UniMsg[j].Data != Sta.CurrData -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_2864"
	(Sta.ShWbMsg.Data = Sta.CurrData & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2865"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.ShWbMsg.Data = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_2866"
	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.ShWbMsg.Data = Sta.CurrData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2867"
		(j != i) ->	(Sta.Proc[j].InvMarked = true & Sta.Dir.Local = false -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2868"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.Local = false -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2869"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.Local = false -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_2870"
	(Sta.Proc[j].CacheState != CACHE_S & Sta.Proc[j].CacheState != CACHE_I -> Sta.Dir.Local = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2871"
		(j != i) ->	(Sta.Dir.Local = false & Sta.Proc[j].CacheState = CACHE_S -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE do
Invariant "rule_2872"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Dir.Local = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2873"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.UniMsg[i].Proc = j -> Sta.Dir.Local = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2874"
	(Sta.Dir.Pending = true & Sta.Dir.Local = false -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2875"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.Local = false -> Sta.Dir.Pending = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2876"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.Local = false -> Sta.Dir.ShrVld = true);
endruleset;


ruleset i : NODE do
Invariant "rule_2877"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.Local = false -> Sta.Dir.HeadVld = true);
endruleset;


ruleset i : NODE do
Invariant "rule_2878"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.Local = false -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2879"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.Local = false -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_2880"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.Local = false -> Sta.MemData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_2881"
	(Sta.Dir.ShrVld = false & Sta.Dir.Local = false -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2882"
	(Sta.Dir.Local = false & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2883"
	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Dir.Local = false -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2884"
	(Sta.Dir.HeadVld = false & Sta.Dir.Local = false -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2885"
	(Sta.Proc[i].InvMarked = true & Sta.Dir.Local = false -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2886"
	(Sta.Dir.Local = false & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2887"
	(Sta.MemData != Sta.CurrData & Sta.Dir.Local = false -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2888"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.Local = false -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2889"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Put & Sta.Dir.Local = false -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE do
Invariant "rule_2890"
	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.Local = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2891"
	(Sta.Dir.Local = false & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.MemData = Sta.CurrData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2892"
		(j != i) ->	(Sta.UniMsg[j].Data != Sta.CurrData & Sta.Dir.Local = false -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2893"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.Local = false -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2894"
		(j != i) ->	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Dir.Local = false -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2895"
		(j != i) ->	(Sta.Dir.Local = false & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2896"
		(j != i) ->	(Sta.Dir.Local = false & Sta.Proc[j].CacheState != CACHE_I -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2897"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadVld = true -> Sta.Dir.Local = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2898"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Proc = i -> Sta.Dir.Local = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2899"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.Local = false -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2900"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadPtr = i -> Sta.Dir.Local = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2901"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Dir.Local = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2902"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.UniMsg[j].Proc = i -> Sta.Dir.Local = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2903"
	(Sta.MemData != Sta.CurrData & Sta.Dir.Local = false -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2904"
	(Sta.Proc[i].InvMarked = true & Sta.Dir.Local = false -> Sta.MemData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_2905"
	(Sta.Proc[i].CacheState != CACHE_S & Sta.Proc[i].CacheState != CACHE_I -> Sta.Dir.Local = false);
endruleset;


ruleset j : NODE do
Invariant "rule_2906"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.Local = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2907"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.Dir.Local = false);
endruleset;


ruleset i : NODE do
Invariant "rule_2908"
	(Sta.MemData != Sta.CurrData & Sta.Dir.Local = false -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_2909"
	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.Dir.Local = false -> Sta.MemData = Sta.CurrData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2910"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].InvMarked = true -> Sta.Dir.Local = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2911"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheState = CACHE_S -> Sta.Dir.Local = true);
endruleset;


ruleset i : NODE do
Invariant "rule_2912"
	(Sta.Dir.Local = true & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2913"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.Local = true -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2914"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Dir.Local = true -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE do
Invariant "rule_2915"
	(Sta.Dir.Pending = true & Sta.Dir.InvSet[i] = true -> Sta.Dir.Local = true);
endruleset;


ruleset i : NODE do
Invariant "rule_2916"
	(Sta.Dir.ShrVld = false & Sta.Dir.InvSet[i] = true -> Sta.Dir.Local = true);
endruleset;


ruleset i : NODE do
Invariant "rule_2917"
	(Sta.Dir.InvSet[i] = true & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Dir.Local = true);
endruleset;


ruleset i : NODE do
Invariant "rule_2918"
	(Sta.Dir.InvSet[i] = true & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Dir.Local = true);
endruleset;


ruleset i : NODE do
Invariant "rule_2919"
	(Sta.Dir.HeadVld = false & Sta.Dir.InvSet[i] = true -> Sta.Dir.Local = true);
endruleset;


ruleset i : NODE do
Invariant "rule_2920"
	(Sta.Proc[i].InvMarked = true & Sta.Dir.InvSet[i] = true -> Sta.Dir.Local = true);
endruleset;


ruleset i : NODE do
Invariant "rule_2921"
	(Sta.Dir.InvSet[i] = true & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Dir.Local = true);
endruleset;


ruleset i : NODE do
Invariant "rule_2922"
	(Sta.Dir.InvSet[i] = true & Sta.MemData != Sta.CurrData -> Sta.Dir.Local = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2923"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.Dir.Local = true);
endruleset;


ruleset j : NODE do
Invariant "rule_2924"
	(Sta.Dir.Local = true & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_2925"
	(Sta.MemData != Sta.CurrData & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Dir.Local = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2926"
		(i != j) ->	(Sta.Dir.HeadVld = true & Sta.Dir.Local = true -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2927"
		(j != i) ->	(Sta.Dir.Local = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2928"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.Dir.Local = true -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2929"
		(i != j) ->	(Sta.Dir.Local = true & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2930"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.Local = true -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2931"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Data != Sta.CurrData -> Sta.Dir.Local = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2932"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.Local = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2933"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.Dir.Local = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2934"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Dir.Local = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2935"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.Local = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2936"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheState != CACHE_I -> Sta.Dir.Local = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2937"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.Local = true -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_2938"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.Local = true -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2939"
		(j != i) ->	(Sta.Dir.Local = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2940"
		(j != i) ->	(Sta.Dir.Local = true & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE do
Invariant "rule_2941"
	(Sta.Proc[i].InvMarked = true & Sta.MemData != Sta.CurrData -> Sta.Dir.Local = true);
endruleset;


ruleset j : NODE do
Invariant "rule_2942"
	(Sta.Dir.Local = true & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2943"
		(j != i) ->	(Sta.Dir.Local = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2944"
		(j != i) ->	(Sta.Dir.Local = true & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE do
Invariant "rule_2945"
	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.MemData != Sta.CurrData -> Sta.Dir.Local = true);
endruleset;


ruleset j : NODE do
Invariant "rule_2946"
	(Sta.UniMsg[j].Cmd != UNI_Put & Sta.Proc[j].InvMarked = true -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2947"
	(Sta.Proc[j].InvMarked = true & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2948"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].InvMarked = true -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2949"
	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.Proc[j].InvMarked = true -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2950"
		(j != i) ->	(Sta.Proc[j].InvMarked = true & Sta.UniMsg[j].Proc != i -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2951"
	(Sta.Proc[j].CacheState != CACHE_S & Sta.Proc[j].CacheState != CACHE_I -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2952"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheState = CACHE_S -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2953"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Proc[j].CacheState = CACHE_S -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset i : NODE do
Invariant "rule_2954"
	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2955"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.UniMsg[j].Cmd != UNI_Put -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2956"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.UniMsg[j].Cmd != UNI_Put -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2957"
		(j != i) ->	(Sta.UniMsg[j].Cmd != UNI_Put & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2958"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Put & Sta.UniMsg[j].Proc != i -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2959"
	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2960"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2961"
	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2962"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2963"
	(Sta.Proc[j].ProcCmd = NODE_None & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2964"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_None -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2965"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_None & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2966"
	(Sta.WbMsg.Data = Sta.CurrData & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2967"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd != NODE_Get -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2968"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Proc[j].ProcCmd != NODE_Get -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2969"
		(j != i) ->	(Sta.Proc[j].ProcCmd != NODE_Get & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset i : NODE do
Invariant "rule_2970"
	(Sta.Proc[i].CacheState = CACHE_I & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset i : NODE do
Invariant "rule_2971"
	(Sta.Proc[i].ProcCmd = NODE_Get & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset i : NODE do
Invariant "rule_2972"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset i : NODE do
Invariant "rule_2973"
	(Sta.Proc[i].ProcCmd != NODE_None & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset i : NODE do
Invariant "rule_2974"
	(Sta.Proc[i].CacheState != CACHE_S & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset i : NODE do
Invariant "rule_2975"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2976"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2977"
	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2978"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset i : NODE do
Invariant "rule_2979"
	(Sta.Proc[i].CacheState != CACHE_S & Sta.Proc[i].CacheState != CACHE_I -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2980"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2981"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2982"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2983"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2984"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.UniMsg[j].Proc != i -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2985"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2986"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2987"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2988"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheState != CACHE_I -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2989"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2990"
	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2991"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2992"
		(j != i) ->	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.UniMsg[j].Proc != i -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2993"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Proc[j].CacheState != CACHE_I -> Sta.ShWbMsg.Cmd != SHWB_ShWb);
endruleset;


ruleset j : NODE do
Invariant "rule_2994"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_2995"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_2996"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Data = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_2997"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[j].InvMarked = true -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_2998"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_2999"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Proc = i);
endruleset;


ruleset j : NODE do
Invariant "rule_3000"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Cmd != UNI_Put -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3001"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3002"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3003"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3004"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Proc != i -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3005"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_3006"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_3007"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[j].CacheState = CACHE_S -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_3008"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[j].CacheState = CACHE_S -> Sta.Proc[j].CacheData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_3009"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3010"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Cmd != UNI_Put -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3011"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Proc != i -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_3012"
	(Sta.UniMsg[j].Cmd = UNI_Put & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Data = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_3013"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_3014"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3015"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Put & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Proc = i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3016"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_3017"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_3018"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_3019"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3020"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3021"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_3022"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_3023"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3024"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3025"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_None & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3026"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[j].ProcCmd != NODE_Get -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_3027"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd = NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_3028"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[j].ProcCmd = NODE_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3029"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd = NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_3030"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[i].CacheState != CACHE_I -> Sta.Proc[i].CacheData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_3031"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Proc[i].CacheState != CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_3032"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_3033"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_3034"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Proc[i].ProcCmd = NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_3035"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[i].CacheState = CACHE_S -> Sta.Proc[i].CacheData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_3036"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Proc[i].CacheState = CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_3037"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_3038"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_3039"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3040"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3041"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_3042"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_3043"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3044"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3045"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_3046"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_3047"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Data = Sta.CurrData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3048"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Data = Sta.CurrData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3049"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[j].Proc = i);
endruleset;


ruleset j : NODE do
Invariant "rule_3050"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_3051"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3052"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Proc = i -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_3053"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[j].CacheState != CACHE_I -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3054"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_3055"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_3056"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_3057"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3058"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3059"
		(j != i) ->	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3060"
		(j != i) ->	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.UniMsg[j].Proc = i);
endruleset;


ruleset j : NODE do
Invariant "rule_3061"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_ShWb -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_3062"
	(Sta.ShWbMsg.Cmd = SHWB_ShWb & Sta.Proc[j].CacheState != CACHE_I -> Sta.Proc[j].CacheData = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_3063"
	(Sta.UniMsg[j].Cmd != UNI_Put & Sta.Proc[j].InvMarked = true -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3064"
	(Sta.Proc[j].InvMarked = true & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3065"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].InvMarked = true -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3066"
	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.Proc[j].InvMarked = true -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3067"
	(Sta.Proc[j].CacheState != CACHE_S & Sta.Proc[j].CacheState != CACHE_I -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3068"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheState = CACHE_S -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3069"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Proc[j].CacheState = CACHE_S -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3070"
		(i != j) ->	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3071"
		(i != j) ->	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3072"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3073"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3074"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3075"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Proc[i].InvMarked = true -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3076"
		(i != j) ->	(Sta.Dir.InvSet[i] = true & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3077"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.Dir.InvSet[i] = true -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3078"
		(i != j) ->	(Sta.Dir.InvSet[i] = true & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3079"
		(i != j) ->	(Sta.ShWbMsg.Proc = i & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3080"
		(i != j) ->	(Sta.ShWbMsg.Proc = i & Sta.UniMsg[j].Proc = i -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3081"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.UniMsg[j].Cmd != UNI_Put -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3082"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.UniMsg[j].Cmd != UNI_Put -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3083"
		(j != i) ->	(Sta.UniMsg[j].Cmd != UNI_Put & Sta.UniMsg[j].Proc = i -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3084"
	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3085"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3086"
	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3087"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.UniMsg[j].Proc = i -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3088"
	(Sta.Proc[j].ProcCmd = NODE_None & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3089"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_None -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3090"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_None & Sta.UniMsg[j].Proc = i -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3091"
		(i != j) ->	(Sta.WbMsg.Data = Sta.CurrData & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3092"
	(Sta.WbMsg.Data = Sta.CurrData & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3093"
		(i != j) ->	(Sta.Proc[i].ProcCmd != NODE_Get & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3094"
		(i != j) ->	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_None -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3095"
		(i != j) ->	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.UniMsg[i].Cmd != UNI_Put -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3096"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd != NODE_Get -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3097"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Proc[j].ProcCmd != NODE_Get -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3098"
		(j != i) ->	(Sta.Proc[j].ProcCmd != NODE_Get & Sta.UniMsg[j].Proc = i -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3099"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Proc[i].CacheState != CACHE_I -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3100"
		(i != j) ->	(Sta.Proc[i].ProcCmd != NODE_Get & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3101"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3102"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3103"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_None -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3104"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Proc[i].CacheState = CACHE_S -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3105"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.UniMsg[j].Proc = i -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3106"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.UniMsg[i].Cmd != UNI_Put -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3107"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3108"
		(i != j) ->	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3109"
		(i != j) ->	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3110"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3111"
	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3112"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.UniMsg[j].Proc = i -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3113"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3114"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3115"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Proc = i -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3116"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[i].Cmd != UNI_Put -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3117"
		(i != j) ->	(Sta.Proc[i].CacheState != CACHE_S & Sta.Proc[i].CacheState != CACHE_I -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3118"
	(Sta.ShWbMsg.Proc = j & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3119"
		(j != i) ->	(Sta.ShWbMsg.Proc = j & Sta.UniMsg[j].Proc = i -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3120"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3121"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3122"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3123"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3124"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3125"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3126"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Proc = i -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3127"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheState != CACHE_I -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3128"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3129"
	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3130"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3131"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Proc[j].CacheState != CACHE_I -> Sta.Dir.InvSet[j] = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3132"
	(Sta.Dir.InvSet[j] = true & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_3133"
	(Sta.Dir.InvSet[j] = true & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_3134"
	(Sta.Dir.InvSet[j] = true & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Data = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_3135"
	(Sta.Dir.InvSet[j] = true & Sta.Proc[j].InvMarked = true -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_3136"
	(Sta.Dir.InvSet[j] = true & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_3137"
	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Cmd != UNI_Put -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3138"
	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3139"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Dir.InvSet[j] = true -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3140"
	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3141"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Dir.InvSet[j] = true -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_3142"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_3143"
	(Sta.Dir.InvSet[j] = true & Sta.Proc[j].CacheState = CACHE_S -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_3144"
	(Sta.Dir.InvSet[j] = true & Sta.Proc[j].CacheState = CACHE_S -> Sta.Proc[j].CacheData = Sta.CurrData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3145"
		(i != j) ->	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3146"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3147"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.Dir.InvSet[j] = true -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3148"
		(i != j) ->	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Dir.InvSet[j] = true -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3149"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3150"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3151"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3152"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Dir.InvSet[j] = true -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3153"
		(i != j) ->	(Sta.Dir.InvSet[i] = true & Sta.Dir.InvSet[j] = true -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3154"
		(i != j) ->	(Sta.Dir.InvSet[i] = true & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3155"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3156"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.Dir.InvSet[j] = true -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3157"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3158"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3159"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3160"
		(i != j) ->	(Sta.ShWbMsg.Proc = i & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3161"
		(i != j) ->	(Sta.ShWbMsg.Proc = i & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3162"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Cmd != UNI_Put -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_3163"
	(Sta.UniMsg[j].Cmd = UNI_Put & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Data = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_3164"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_3165"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3166"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_3167"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_3168"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_3169"
	(Sta.Dir.InvSet[j] = true & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3170"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3171"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_3172"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_3173"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3174"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3175"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_None & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3176"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[i].Data = Sta.CurrData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3177"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[i].Data = Sta.CurrData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3178"
		(i != j) ->	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.Proc[i].ProcCmd = NODE_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3179"
		(i != j) ->	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3180"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[i].Data = Sta.CurrData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3181"
		(i != j) ->	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3182"
		(j != i) ->	(Sta.Proc[j].ProcCmd != NODE_Get & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_3183"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.Proc[j].ProcCmd = NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_3184"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.Proc[j].ProcCmd = NODE_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3185"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd = NODE_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3186"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3187"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.Proc[i].ProcCmd = NODE_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3188"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3189"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3190"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3191"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3192"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3193"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3194"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3195"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.Proc[i].CacheState != CACHE_I -> Sta.Proc[i].CacheData = Sta.CurrData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3196"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3197"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.Proc[i].CacheState = CACHE_S -> Sta.Proc[i].CacheData = Sta.CurrData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3198"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_3199"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_3200"
	(Sta.Dir.InvSet[j] = true & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3201"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3202"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3203"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3204"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3205"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3206"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[i].Cmd != UNI_Put -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3207"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3208"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3209"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3210"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_3211"
	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.ShWbMsg.Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3212"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Proc != j);
endruleset;


ruleset j : NODE do
Invariant "rule_3213"
	(Sta.ShWbMsg.Proc = j & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3214"
		(j != i) ->	(Sta.ShWbMsg.Proc = j & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_3215"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_3216"
	(Sta.Dir.InvSet[j] = true & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3217"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3218"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_3219"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_3220"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Data = Sta.CurrData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3221"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Data = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_3222"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_3223"
	(Sta.Dir.InvSet[j] = true & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3224"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_3225"
	(Sta.Dir.InvSet[j] = true & Sta.Proc[j].CacheState != CACHE_I -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3226"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_3227"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Dir.InvSet[j] = true -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_3228"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_3229"
	(Sta.Dir.InvSet[j] = true & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3230"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3231"
		(j != i) ->	(Sta.Dir.InvSet[j] = true & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_3232"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Dir.InvSet[j] = true -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_3233"
	(Sta.Dir.InvSet[j] = true & Sta.Proc[j].CacheState != CACHE_I -> Sta.Proc[j].CacheData = Sta.CurrData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3234"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3235"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3236"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].InvMarked = true -> Sta.Dir.Pending = true);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3237"
		(j != i) ->	(Sta.Dir.Pending = false & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3238"
		(j != i) ->	(Sta.UniMsg[j].Cmd != UNI_Put & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3239"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_3240"
	(Sta.UniMsg[j].Data != Sta.CurrData & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_3241"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3242"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3243"
		(j != i) ->	(Sta.Proc[j].InvMarked = true & Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3244"
		(j != i) ->	(Sta.Proc[j].InvMarked = true & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3245"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].InvMarked = true -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3246"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.Proc[j].InvMarked = true -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3247"
		(j != i) ->	(Sta.Proc[j].InvMarked = true & Sta.Proc[i].CacheState = CACHE_S -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3248"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.Proc[j].InvMarked = true -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3249"
		(j != i) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3250"
		(j != i) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[j].InvMarked = true -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3251"
		(j != i) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[j].InvMarked = true -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3252"
		(j != i) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3253"
		(j != i) ->	(Sta.Dir.HeadVld = true & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3254"
		(j != i) ->	(Sta.Proc[j].InvMarked = true & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3255"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3256"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3257"
		(j != i) ->	(Sta.Proc[j].InvMarked = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3258"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3259"
		(j != i) ->	(Sta.Proc[j].InvMarked = true & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3260"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].InvMarked = true -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3261"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3262"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].InvMarked = true -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3263"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3264"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3265"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].InvMarked = true -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3266"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_3267"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_3268"
	(Sta.Proc[j].InvMarked = true & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_3269"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].InvMarked = true -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_3270"
	(Sta.UniMsg[j].Cmd != UNI_Get & Sta.Proc[j].InvMarked = true -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3271"
		(j != i) ->	(Sta.Proc[j].InvMarked = true & Sta.UniMsg[j].Proc = i -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_3272"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Cmd = UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3273"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].InvMarked = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3274"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.UniMsg[i].Proc = j -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3275"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.Pending = false -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3276"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Cmd != UNI_Put -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3277"
	(Sta.UniMsg[j].Data != Sta.CurrData & Sta.UniMsg[j].Cmd != UNI_Put -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3278"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.UniMsg[j].Cmd != UNI_Put -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3279"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3280"
		(i != j) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3281"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3282"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3283"
		(i != j) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[i].CacheState = CACHE_S -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3284"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3285"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadVld = true -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3286"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3287"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[i].Proc = j -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3288"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3289"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3290"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadPtr = i -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3291"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3292"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3293"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3294"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Cmd != UNI_Get -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3295"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3296"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_S & Sta.Proc[j].CacheState != CACHE_I -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3297"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3298"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.UniMsg[i].Proc = j -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_3299"
	(Sta.Proc[j].CacheState != CACHE_S & Sta.Proc[j].CacheState != CACHE_I -> Sta.Dir.Pending = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3300"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.Pending = false -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_3301"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Dir.Pending = false -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3302"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Dir.InvSet[i] = true -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3303"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_S & Sta.Proc[j].CacheState != CACHE_I -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3304"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_S & Sta.Proc[j].CacheState != CACHE_I -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3305"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_S & Sta.Proc[j].CacheState != CACHE_I -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3306"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_3307"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Dir.ShrVld = true -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_3308"
	(Sta.Proc[j].CacheState != CACHE_S & Sta.Proc[j].CacheState != CACHE_I -> Sta.Dir.ShrVld = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3309"
	(Sta.Proc[j].CacheState != CACHE_S & Sta.Proc[j].CacheState != CACHE_I -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3310"
		(i != j) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3311"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3312"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3313"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_3314"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3315"
		(i != j) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[i].CacheState = CACHE_S -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3316"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3317"
		(j != i) ->	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Proc[j].CacheState != CACHE_S -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3318"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_S & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3319"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_S & Sta.Proc[j].CacheState != CACHE_I -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3320"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadVld = true -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3321"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadPtr = i -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3322"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_3323"
	(Sta.Proc[j].CacheState != CACHE_S & Sta.Proc[j].CacheState != CACHE_I -> Sta.Dir.HeadVld = true);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3324"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_S & Sta.Proc[j].CacheState != CACHE_I -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3325"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Proc[j].CacheState != CACHE_S);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3326"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_S & Sta.Proc[j].CacheState != CACHE_I -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3327"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_S & Sta.Proc[j].CacheState != CACHE_I -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_3328"
	(Sta.Proc[j].CacheState != CACHE_S & Sta.Proc[j].CacheState != CACHE_I -> Sta.ShWbMsg.Proc = j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3329"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_S & Sta.Proc[j].CacheState != CACHE_I -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_3330"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Proc[j].CacheState != CACHE_S -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_3331"
	(Sta.Proc[j].CacheState != CACHE_S & Sta.Proc[j].CacheState != CACHE_I -> Sta.Proc[j].CacheData = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_3332"
	(Sta.Proc[j].CacheState != CACHE_S & Sta.Proc[j].CacheState != CACHE_I -> Sta.ShWbMsg.Cmd = SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3333"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_S & Sta.Proc[j].CacheState != CACHE_I -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_3334"
	(Sta.Proc[j].CacheState != CACHE_S & Sta.Proc[j].CacheState != CACHE_I -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3335"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_S & Sta.Proc[j].CacheState != CACHE_I -> Sta.Dir.HeadPtr = i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3336"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_S & Sta.Proc[j].CacheState != CACHE_I -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3337"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheState = CACHE_S -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3338"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.Proc[j].CacheState = CACHE_S -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3339"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheState = CACHE_S -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3340"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Proc[j].CacheState = CACHE_S -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3341"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheState = CACHE_S -> Sta.Dir.Pending = true);
endruleset;


ruleset j : NODE do
Invariant "rule_3342"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheState = CACHE_S -> Sta.Dir.Pending = true);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3343"
		(j != i) ->	(Sta.Dir.Pending = false & Sta.Proc[j].CacheState = CACHE_S -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE do
Invariant "rule_3344"
	(Sta.Dir.Pending = false & Sta.Proc[j].CacheState = CACHE_S -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3345"
		(i != j) ->	(Sta.Dir.InvSet[i] = true & Sta.Proc[j].CacheState = CACHE_S -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3346"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheState = CACHE_S -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3347"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheState = CACHE_S -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3348"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S & Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE do
Invariant "rule_3349"
	(Sta.Dir.ShrVld = true & Sta.Proc[j].CacheState = CACHE_S -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_3350"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheState = CACHE_S -> Sta.Dir.ShrVld = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3351"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_S & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3352"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheState = CACHE_S -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3353"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Proc[j].CacheState = CACHE_S -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3354"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.Proc[j].CacheState = CACHE_S -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE do
Invariant "rule_3355"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheState = CACHE_S -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3356"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_S & Sta.Proc[j].CacheState = CACHE_S -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3357"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.Proc[j].CacheState = CACHE_S -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3358"
		(j != i) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[j].CacheState = CACHE_S -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3359"
		(j != i) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[j].CacheState = CACHE_S -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3360"
	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[j].CacheState = CACHE_S -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3361"
		(j != i) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[j].CacheState = CACHE_S -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3362"
		(j != i) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[j].CacheState = CACHE_S -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3363"
		(j != i) ->	(Sta.Dir.HeadVld = true & Sta.Proc[j].CacheState = CACHE_S -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3364"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.Proc[j].CacheState = CACHE_S -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3365"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_GetX & Sta.Proc[j].CacheState = CACHE_S -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3366"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheState = CACHE_S -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3367"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.Proc[j].CacheState = CACHE_S);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3368"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Proc[j].CacheState = CACHE_S);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3369"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheState = CACHE_S -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3370"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheState = CACHE_S -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3371"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheState = CACHE_S -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3372"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck & Sta.Proc[j].CacheState = CACHE_S -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_3373"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.Proc[j].CacheState = CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_3374"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_3375"
	(Sta.Proc[i].InvMarked = true & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_3376"
	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_3377"
	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_3378"
	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Proc[i].InvMarked = true -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_3379"
	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.InvMsg[i].Cmd != INV_Inv -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3380"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_3381"
	(Sta.Proc[i].ProcCmd != NODE_Get & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_3382"
	(Sta.UniMsg[i].Data != Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_None -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_3383"
	(Sta.UniMsg[i].Cmd != UNI_Put & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_3384"
	(Sta.Proc[i].ProcCmd != NODE_Get & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_3385"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_None -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_3386"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.UniMsg[i].Cmd != UNI_Put -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_3387"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.MemData != Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_3388"
	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_3389"
	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_3390"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_3391"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3392"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.UniMsg[j].Proc = i -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_3393"
	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_3394"
	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[i].Cmd != UNI_Put -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_3395"
	(Sta.Proc[i].CacheState != CACHE_S & Sta.Proc[i].CacheState != CACHE_I -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3396"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3397"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3398"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3399"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheState != CACHE_I -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3400"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.InvMsg[i].Cmd != INV_Inv);
endruleset;


ruleset i : NODE do
Invariant "rule_3401"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3402"
	(Sta.Proc[i].InvMarked = true & Sta.InvMsg[i].Cmd = INV_Inv -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3403"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3404"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_3405"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_3406"
	(Sta.Proc[i].InvMarked = true & Sta.InvMsg[i].Cmd = INV_Inv -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_3407"
	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3408"
	(Sta.Dir.InvSet[i] = true & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.InvMsg[i].Cmd = INV_Inv);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3409"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_3410"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Proc[i].ProcCmd = NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_3411"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_3412"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_3413"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd = NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_3414"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_3415"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_3416"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.MemData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_3417"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_3418"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_3419"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_3420"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3421"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3422"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE do
Invariant "rule_3423"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3424"
	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[i].Cmd != UNI_Put -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3425"
	(Sta.Proc[i].InvMarked = true & Sta.InvMsg[i].Cmd = INV_Inv -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_3426"
	(Sta.Proc[i].InvMarked = true & Sta.InvMsg[i].Cmd = INV_Inv -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3427"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3428"
		(j != i) ->	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.InvMsg[i].Cmd = INV_Inv -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3429"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3430"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.Proc[j].CacheState != CACHE_I -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3431"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.InvMsg[i].Cmd = INV_Inv -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3432"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3433"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_Inv & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE do
Invariant "rule_3434"
	(Sta.UniMsg[i].Cmd != UNI_Get & Sta.Proc[i].InvMarked = true -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3435"
	(Sta.UniMsg[i].Cmd != UNI_Get & Sta.Proc[i].ProcCmd = NODE_Get -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3436"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.UniMsg[i].Proc = j -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3437"
	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3438"
	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3439"
	(Sta.Dir.Pending = false & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3440"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.InvSet[i] = true -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3441"
	(Sta.UniMsg[i].Cmd != UNI_PutX & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3442"
	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3443"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3444"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.ShrVld = true -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3445"
	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Dir.ShrVld = true -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3446"
	(Sta.Proc[i].InvMarked = true & Sta.Dir.ShrVld = true -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3447"
	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3448"
	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[i].CacheState = CACHE_S -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3449"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3450"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3451"
	(Sta.Dir.HeadVld = false & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3452"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3453"
	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3454"
	(Sta.Proc[i].ProcCmd = NODE_Get & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3455"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_None -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3456"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.HeadPtr != i -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3457"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3458"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3459"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[i].InvMarked = true -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3460"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[i].ProcCmd = NODE_Get -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3461"
	(Sta.Dir.HeadVld = true & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3462"
	(Sta.Proc[i].CacheState = CACHE_I & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3463"
	(Sta.Proc[i].ProcCmd = NODE_Get & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3464"
	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3465"
	(Sta.Proc[i].ProcCmd != NODE_None & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3466"
	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Proc[i].CacheState != CACHE_S -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3467"
	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3468"
	(Sta.Proc[i].CacheState = CACHE_I & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3469"
	(Sta.Proc[i].ProcCmd = NODE_Get & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3470"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3471"
	(Sta.Proc[i].ProcCmd != NODE_None & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3472"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3473"
	(Sta.Dir.HeadVld = true & Sta.Proc[i].InvMarked = true -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3474"
	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3475"
	(Sta.Proc[i].ProcCmd = NODE_Get & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.RpMsg[i].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3476"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_3477"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_3478"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_3479"
	(Sta.UniMsg[i].Cmd != UNI_Get & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3480"
	(Sta.UniMsg[i].Cmd != UNI_Get & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3481"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE do
Invariant "rule_3482"
	(Sta.Proc[i].InvMarked = true & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.UniMsg[i].Cmd = UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_3483"
	(Sta.Proc[i].ProcCmd = NODE_Get & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.UniMsg[i].Cmd = UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_3484"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Dir.Pending = true);
endruleset;


ruleset i : NODE do
Invariant "rule_3485"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3486"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_3487"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_3488"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.UniMsg[i].Cmd = UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_3489"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Dir.ShrVld = true -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3490"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3491"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3492"
	(Sta.Proc[i].InvMarked = true & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3493"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_3494"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheState = CACHE_S -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_3495"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_3496"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Dir.HeadVld = true);
endruleset;


ruleset i : NODE do
Invariant "rule_3497"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_3498"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3499"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_3500"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_3501"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Dir.HeadPtr = i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3502"
		(i != j) ->	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3503"
		(i != j) ->	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3504"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3505"
		(i != j) ->	(Sta.Proc[i].ProcCmd = NODE_Get & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3506"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3507"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_3508"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3509"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Proc[i].CacheState != CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_3510"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_3511"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_3512"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Proc[i].ProcCmd = NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_3513"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Proc[i].CacheState = CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_3514"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_3515"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Proc[i].CacheState != CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_3516"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_3517"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_3518"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Proc[i].ProcCmd = NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_3519"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_3520"
	(Sta.Dir.HeadVld = true & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3521"
	(Sta.Proc[i].InvMarked = true & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3522"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3523"
	(Sta.Proc[i].InvMarked = true & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_3524"
	(Sta.RpMsg[i].Cmd = RP_Replace & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_3525"
	(Sta.Proc[i].ProcCmd = NODE_Get & Sta.RpMsg[i].Cmd = RP_Replace -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3526"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.Pending = false -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_3527"
	(Sta.Dir.InvSet[i] = true & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_3528"
	(Sta.Dir.InvSet[i] = true & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_3529"
	(Sta.ShWbMsg.Proc != i & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_3530"
	(Sta.ShWbMsg.Proc != i & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3531"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_3532"
	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Dir.ShrVld = true -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_3533"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.Dir.ShrVld = true -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_3534"
	(Sta.Proc[i].InvMarked = true & Sta.Dir.ShrVld = true -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_3535"
	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.WbMsg.Data != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3536"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3537"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.WbMsg.Data != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_3538"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.WbMsg.Data != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3539"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.WbMsg.Data = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_3540"
	(Sta.WbMsg.Data = Sta.CurrData & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3541"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadVld = true -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3542"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Data != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3543"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3544"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3545"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3546"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3547"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheState != CACHE_I -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3548"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3549"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.MemData != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_3550"
	(Sta.Dir.HeadVld = true & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3551"
		(j != i) ->	(Sta.ShWbMsg.Proc = j & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_3552"
	(Sta.Dir.HeadVld = true & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3553"
		(j != i) ->	(Sta.ShWbMsg.Proc = j & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_3554"
	(Sta.Dir.HeadVld = true & Sta.Proc[i].InvMarked = true -> Sta.UniMsg[i].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3555"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.UniMsg[i].Proc = j -> Sta.Dir.Pending = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3556"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Dir.Pending = false -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE do
Invariant "rule_3557"
	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3558"
	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3559"
	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.ShWbMsg.Proc = i);
endruleset;


ruleset i : NODE do
Invariant "rule_3560"
	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.ShWbMsg.Proc = i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3561"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3562"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE do
Invariant "rule_3563"
	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Dir.ShrVld = true -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3564"
	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3565"
	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3566"
	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Proc[i].InvMarked = true -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3567"
	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.WbMsg.Data != Sta.CurrData -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3568"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.UniMsg[i].Proc = j -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3569"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3570"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.WbMsg.Data != Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3571"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.WbMsg.Data = Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3572"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Dir.HeadVld = true -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3573"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.UniMsg[j].Data != Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3574"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3575"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3576"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3577"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3578"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Proc[j].CacheState != CACHE_I -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3579"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3580"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.MemData != Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3581"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.UniMsg[i].Proc = j -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3582"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.UniMsg[i].Proc = j -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3583"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.UniMsg[i].Proc = j -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3584"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.UniMsg[i].Proc = j -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3585"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.UniMsg[i].Proc = j -> Sta.MemData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_3586"
	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3587"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.ShWbMsg.Proc != j);
endruleset;


ruleset i : NODE do
Invariant "rule_3588"
	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3589"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.ShWbMsg.Proc != j);
endruleset;


ruleset i : NODE do
Invariant "rule_3590"
	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Dir.HeadVld = true -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3591"
	(Sta.UniMsg[i].Cmd = UNI_Get & Sta.Proc[i].InvMarked = true -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3592"
	(Sta.Dir.ShrVld = false & Sta.Dir.InvSet[i] = true -> Sta.Dir.Pending = true);
endruleset;


ruleset i : NODE do
Invariant "rule_3593"
	(Sta.Dir.InvSet[i] = true & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Dir.Pending = true);
endruleset;


ruleset i : NODE do
Invariant "rule_3594"
	(Sta.Dir.InvSet[i] = true & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Dir.Pending = true);
endruleset;


ruleset i : NODE do
Invariant "rule_3595"
	(Sta.Dir.HeadVld = false & Sta.Dir.InvSet[i] = true -> Sta.Dir.Pending = true);
endruleset;


ruleset i : NODE do
Invariant "rule_3596"
	(Sta.Dir.Pending = true & Sta.Dir.InvSet[i] = true -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3597"
	(Sta.Proc[i].InvMarked = true & Sta.Dir.InvSet[i] = true -> Sta.Dir.Pending = true);
endruleset;


ruleset i : NODE do
Invariant "rule_3598"
	(Sta.Dir.InvSet[i] = true & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Dir.Pending = true);
endruleset;


ruleset i : NODE do
Invariant "rule_3599"
	(Sta.Dir.InvSet[i] = true & Sta.MemData != Sta.CurrData -> Sta.Dir.Pending = true);
endruleset;


ruleset i : NODE do
Invariant "rule_3600"
	(Sta.Dir.Pending = true & Sta.Dir.HeadVld = true -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3601"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.Dir.Pending = true);
endruleset;


ruleset j : NODE do
Invariant "rule_3602"
	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.Pending = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3603"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Data != Sta.CurrData -> Sta.Dir.Pending = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3604"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.Pending = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3605"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.Dir.Pending = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3606"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Dir.Pending = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3607"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheState != CACHE_I -> Sta.Dir.Pending = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3608"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Dir.Pending = true);
endruleset;


ruleset i : NODE do
Invariant "rule_3609"
	(Sta.Dir.Pending = true & Sta.Dir.HeadVld = true -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3610"
	(Sta.Dir.Pending = true & Sta.Dir.HeadVld = true -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_3611"
	(Sta.Dir.Pending = true & Sta.Proc[i].InvMarked = true -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3612"
	(Sta.Dir.Pending = true & Sta.UniMsg[i].Cmd = UNI_Put -> Sta.Dir.HeadVld = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3613"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.UniMsg[j].Proc = i -> Sta.Dir.Pending = true);
endruleset;


ruleset j : NODE do
Invariant "rule_3614"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.Pending = true);
endruleset;


ruleset j : NODE do
Invariant "rule_3615"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.Dir.Pending = true);
endruleset;


ruleset j : NODE do
Invariant "rule_3616"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Dir.Pending = true);
endruleset;


ruleset j : NODE do
Invariant "rule_3617"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheState != CACHE_I -> Sta.Dir.Pending = true);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3618"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.Dir.Pending = true);
endruleset;


ruleset i : NODE do
Invariant "rule_3619"
	(Sta.Dir.Pending = false & Sta.Dir.InvSet[i] = true -> Sta.Dir.ShrVld = true);
endruleset;


ruleset i : NODE do
Invariant "rule_3620"
	(Sta.Dir.HeadVld = true & Sta.Dir.InvSet[i] = true -> Sta.Dir.Pending = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3621"
	(Sta.Dir.Pending = false & Sta.Dir.InvSet[i] = true -> Sta.Dir.HeadVld = true);
endruleset;


ruleset i : NODE do
Invariant "rule_3622"
	(Sta.Dir.Pending = false & Sta.Dir.InvSet[i] = true -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3623"
	(Sta.Dir.Pending = false & Sta.Dir.InvSet[i] = true -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_3624"
	(Sta.Dir.Pending = false & Sta.Dir.InvSet[i] = true -> Sta.MemData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_3625"
	(Sta.Dir.ShrVld = false & Sta.Dir.Pending = false -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3626"
	(Sta.Dir.Pending = false & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3627"
	(Sta.Dir.Pending = false & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3628"
	(Sta.Dir.HeadVld = false & Sta.Dir.Pending = false -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3629"
	(Sta.Dir.Pending = false & Sta.Proc[i].InvMarked = true -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3630"
	(Sta.Dir.Pending = false & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3631"
	(Sta.Dir.Pending = false & Sta.MemData != Sta.CurrData -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3632"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.Pending = false -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3633"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Put & Sta.Dir.Pending = false -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE do
Invariant "rule_3634"
	(Sta.Dir.Pending = false & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3635"
		(j != i) ->	(Sta.Dir.Pending = false & Sta.UniMsg[j].Data != Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3636"
		(j != i) ->	(Sta.Dir.Pending = false & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3637"
		(j != i) ->	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Dir.Pending = false -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3638"
		(j != i) ->	(Sta.Dir.Pending = false & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3639"
		(j != i) ->	(Sta.Dir.Pending = false & Sta.Proc[j].CacheState != CACHE_I -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3640"
		(i != j) ->	(Sta.Dir.Pending = false & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3641"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.Pending = false -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3642"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.Pending = false -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_3643"
	(Sta.Dir.HeadVld = true & Sta.Proc[i].InvMarked = true -> Sta.Dir.Pending = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3644"
	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.Dir.HeadVld = true -> Sta.Dir.Pending = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3645"
		(j != i) ->	(Sta.Dir.Pending = false & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3646"
		(j != i) ->	(Sta.Dir.Pending = false & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_3647"
	(Sta.Dir.Pending = false & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_3648"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Dir.Pending = false -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_3649"
	(Sta.Dir.Pending = false & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_3650"
	(Sta.Dir.Pending = false & Sta.Proc[j].CacheState != CACHE_I -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_3651"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Dir.Pending = false -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3652"
		(j != i) ->	(Sta.Dir.Pending = false & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3653"
		(j != i) ->	(Sta.Dir.Pending = false & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3654"
		(i != j) ->	(Sta.Dir.InvSet[i] = true & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_3655"
	(Sta.Dir.HeadVld = true & Sta.Dir.InvSet[i] = true -> Sta.Dir.ShrVld = true);
endruleset;


ruleset i : NODE do
Invariant "rule_3656"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.ShrVld = true -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3657"
	(Sta.Dir.InvSet[i] = true & Sta.Dir.ShrVld = true -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_3658"
	(Sta.Dir.InvSet[i] = true & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3659"
	(Sta.Dir.ShrVld = false & Sta.Dir.InvSet[i] = true -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3660"
	(Sta.Proc[i].InvMarked = true & Sta.Dir.InvSet[i] = true -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3661"
	(Sta.Dir.InvSet[i] = true & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3662"
	(Sta.Dir.InvSet[i] = true & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Proc[i].ProcCmd = NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_3663"
	(Sta.Dir.InvSet[i] = true & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_3664"
	(Sta.Dir.InvSet[i] = true & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_3665"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.InvSet[i] = true -> Sta.Proc[i].ProcCmd = NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_3666"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.InvSet[i] = true -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_3667"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.InvSet[i] = true -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_3668"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.InvSet[i] = true -> Sta.MemData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_3669"
	(Sta.Dir.InvSet[i] = true & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3670"
	(Sta.Dir.InvSet[i] = true & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_3671"
	(Sta.Dir.InvSet[i] = true & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_3672"
	(Sta.Dir.InvSet[i] = true & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_3673"
	(Sta.Dir.InvSet[i] = true & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_3674"
	(Sta.Dir.HeadVld = true & Sta.Dir.InvSet[i] = true -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3675"
	(Sta.Dir.HeadVld = true & Sta.Dir.InvSet[i] = true -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_3676"
	(Sta.Dir.HeadVld = true & Sta.Dir.InvSet[i] = true -> Sta.MemData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_3677"
	(Sta.Proc[i].InvMarked = true & Sta.Dir.InvSet[i] = true -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3678"
	(Sta.Dir.InvSet[i] = true & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3679"
	(Sta.Dir.InvSet[i] = true & Sta.MemData != Sta.CurrData -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3680"
		(i != j) ->	(Sta.Dir.InvSet[i] = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3681"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.Dir.InvSet[i] = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3682"
		(i != j) ->	(Sta.Dir.InvSet[i] = true & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3683"
		(j != i) ->	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Dir.InvSet[i] = true -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3684"
		(i != j) ->	(Sta.Dir.InvSet[i] = true & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3685"
		(i != j) ->	(Sta.Dir.InvSet[i] = true & Sta.Proc[j].CacheState != CACHE_I -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3686"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Dir.InvSet[i] = true -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3687"
		(i != j) ->	(Sta.Dir.InvSet[i] = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3688"
		(i != j) ->	(Sta.Dir.InvSet[i] = true & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3689"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3690"
	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Dir.ShrVld = true -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3691"
	(Sta.Proc[i].InvMarked = true & Sta.Dir.ShrVld = true -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3692"
	(Sta.UniMsg[i].Cmd = UNI_Nak & Sta.Dir.ShrVld = true -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3693"
	(Sta.Dir.ShrVld = false & Sta.Dir.HeadVld = true -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3694"
	(Sta.Proc[i].ProcCmd != NODE_Get & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3695"
	(Sta.UniMsg[i].Data != Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_None -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3696"
	(Sta.UniMsg[i].Cmd != UNI_Put & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3697"
	(Sta.Proc[i].ProcCmd != NODE_Get & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3698"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_None -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3699"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.UniMsg[i].Cmd != UNI_Put -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3700"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.MemData != Sta.CurrData -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3701"
	(Sta.Dir.HeadVld = true & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3702"
	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3703"
	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3704"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3705"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3706"
	(Sta.Dir.HeadVld = true & Sta.Proc[i].InvMarked = true -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3707"
	(Sta.Dir.HeadVld = true & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3708"
	(Sta.Dir.HeadVld = true & Sta.MemData != Sta.CurrData -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3709"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.UniMsg[j].Proc = i -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3710"
	(Sta.Proc[i].CacheState != CACHE_S & Sta.Proc[i].CacheState != CACHE_I -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3711"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3712"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3713"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3714"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheState != CACHE_I -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3715"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.Dir.InvSet[i] = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3716"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Put & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3717"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3718"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3719"
		(i != j) ->	(Sta.ShWbMsg.Proc != i & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3720"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_None & Sta.ShWbMsg.Proc != i -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3721"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset i : NODE do
Invariant "rule_3722"
	(Sta.ShWbMsg.Proc != i & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Proc[i].ProcCmd = NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_3723"
	(Sta.ShWbMsg.Proc != i & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_3724"
	(Sta.ShWbMsg.Proc != i & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3725"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset i : NODE do
Invariant "rule_3726"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.ShWbMsg.Proc != i -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3727"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadVld = true -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3728"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3729"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadPtr = i -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3730"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd = UNI_Put -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset i : NODE do
Invariant "rule_3731"
	(Sta.ShWbMsg.Proc != i & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_3732"
	(Sta.ShWbMsg.Proc != i & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_3733"
	(Sta.ShWbMsg.Proc != i & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_3734"
	(Sta.ShWbMsg.Proc != i & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3735"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3736"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3737"
		(j != i) ->	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3738"
		(j != i) ->	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3739"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3740"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_I & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.ShWbMsg.Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3741"
		(i != j) ->	(Sta.ShWbMsg.Proc = i & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3742"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Put & Sta.ShWbMsg.Proc = i -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3743"
		(i != j) ->	(Sta.ShWbMsg.Proc = i & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3744"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.ShWbMsg.Proc = i -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3745"
		(i != j) ->	(Sta.ShWbMsg.Proc = i & Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3746"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_None & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Proc = i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3747"
		(i != j) ->	(Sta.ShWbMsg.Proc = i & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE do
Invariant "rule_3748"
	(Sta.Proc[i].ProcCmd != NODE_Get & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.ShWbMsg.Proc = i);
endruleset;


ruleset i : NODE do
Invariant "rule_3749"
	(Sta.UniMsg[i].Data != Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_None -> Sta.ShWbMsg.Proc = i);
endruleset;


ruleset i : NODE do
Invariant "rule_3750"
	(Sta.UniMsg[i].Cmd != UNI_Put & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.ShWbMsg.Proc = i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3751"
		(i != j) ->	(Sta.ShWbMsg.Proc = i & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE do
Invariant "rule_3752"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_None -> Sta.ShWbMsg.Proc = i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3753"
		(i != j) ->	(Sta.ShWbMsg.Proc = i & Sta.Dir.HeadVld = true -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3754"
		(i != j) ->	(Sta.ShWbMsg.Proc = i & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3755"
		(i != j) ->	(Sta.ShWbMsg.Proc = i & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3756"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.ShWbMsg.Proc = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3757"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.ShWbMsg.Proc = i -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3758"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.ShWbMsg.Proc = i -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3759"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.ShWbMsg.Proc = i -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3760"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.ShWbMsg.Proc = i -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_3761"
	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.ShWbMsg.Proc = i);
endruleset;


ruleset i : NODE do
Invariant "rule_3762"
	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.ShWbMsg.Proc = i);
endruleset;


ruleset i : NODE do
Invariant "rule_3763"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.ShWbMsg.Proc = i);
endruleset;


ruleset i : NODE do
Invariant "rule_3764"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.ShWbMsg.Proc = i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3765"
		(i != j) ->	(Sta.ShWbMsg.Proc = i & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3766"
		(i != j) ->	(Sta.ShWbMsg.Proc = i & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3767"
		(j != i) ->	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.ShWbMsg.Proc = i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3768"
		(i != j) ->	(Sta.ShWbMsg.Proc = i & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3769"
		(i != j) ->	(Sta.ShWbMsg.Proc = i & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3770"
		(i != j) ->	(Sta.ShWbMsg.Proc = i & Sta.Proc[j].CacheState != CACHE_I -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3771"
		(i != j) ->	(Sta.ShWbMsg.Proc = i & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3772"
		(i != j) ->	(Sta.ShWbMsg.Proc = i & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3773"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_3774"
	(Sta.UniMsg[j].Data != Sta.CurrData & Sta.UniMsg[j].Cmd != UNI_Put -> Sta.Proc[j].ProcCmd = NODE_None);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3775"
		(i != j) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3776"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3777"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3778"
		(i != j) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[i].CacheState = CACHE_S -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3779"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_3780"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.WbMsg.Data != Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3781"
		(j != i) ->	(Sta.UniMsg[j].Data != Sta.CurrData & Sta.UniMsg[j].Cmd != UNI_Put -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3782"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.UniMsg[j].Cmd != UNI_Put -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3783"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadVld = true -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3784"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3785"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3786"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3787"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadPtr = i -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3788"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.UniMsg[j].Cmd != UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_3789"
	(Sta.UniMsg[j].Data != Sta.CurrData & Sta.UniMsg[j].Cmd != UNI_Put -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_3790"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.UniMsg[j].Cmd != UNI_Put -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_3791"
	(Sta.UniMsg[j].Data != Sta.CurrData & Sta.UniMsg[j].Cmd != UNI_Put -> Sta.Proc[j].CacheData != Sta.CurrData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3792"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3793"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Put & Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE do
Invariant "rule_3794"
	(Sta.UniMsg[j].Data != Sta.CurrData & Sta.Proc[j].ProcCmd != NODE_None -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3795"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Put & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3796"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3797"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Put & Sta.Proc[i].InvMarked = true -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3798"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Put & Sta.Proc[i].CacheState = CACHE_S -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3799"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Put & Sta.UniMsg[i].Cmd = UNI_Put -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3800"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Put & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3801"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Put & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3802"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Put & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3803"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Put & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3804"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Put & Sta.Dir.HeadVld = true -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3805"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Put & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3806"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Put & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3807"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Put & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3808"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Put & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3809"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Put & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3810"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3811"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Data != Sta.CurrData -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3812"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3813"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3814"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3815"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Cmd = UNI_Put -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_3816"
	(Sta.UniMsg[j].Data != Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_Get -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_3817"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_Get -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_3818"
	(Sta.UniMsg[j].Data != Sta.CurrData & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[j].Cmd = UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3819"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_3820"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.ShrVld = true -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_3821"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_3822"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.WbMsg.Data != Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_3823"
	(Sta.UniMsg[j].Cmd != UNI_PutX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3824"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3825"
		(i != j) ->	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3826"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3827"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3828"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_3829"
	(Sta.Proc[j].ProcCmd != NODE_GetX & Sta.Proc[j].ProcCmd != NODE_Get -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3830"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3831"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_3832"
	(Sta.Dir.HeadVld = false & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3833"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3834"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3835"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[i].CacheState != CACHE_I -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_3836"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.ShWbMsg.Proc != j -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_3837"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].ProcCmd != NODE_GetX -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_3838"
	(Sta.Proc[j].ProcCmd != NODE_GetX & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3839"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_E & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_3840"
	(Sta.Proc[j].ProcCmd != NODE_GetX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_3841"
	(Sta.Proc[j].ProcCmd != NODE_GetX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_3842"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.ShWbMsg.Cmd != SHWB_FAck -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3843"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[i].CacheState = CACHE_S -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_3844"
	(Sta.WbMsg.Cmd = WB_Wb & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3845"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.UniMsg[j].Proc != i -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3846"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.HeadPtr != i -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3847"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3848"
		(j != i) ->	(Sta.Proc[j].ProcCmd != NODE_GetX & Sta.UniMsg[j].Proc = i -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_3849"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_3850"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3851"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].ProcCmd != NODE_GetX -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_3852"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Proc[j].ProcCmd != NODE_GetX -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3853"
		(j != i) ->	(Sta.Proc[j].ProcCmd != NODE_GetX & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3854"
		(j != i) ->	(Sta.Proc[j].ProcCmd != NODE_GetX & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3855"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_3856"
	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.ShrVld = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3857"
	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE do
Invariant "rule_3858"
	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[j].Cmd = UNI_PutX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3859"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3860"
		(j != i) ->	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3861"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE do
Invariant "rule_3862"
	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.HeadVld = true);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3863"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3864"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3865"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_3866"
	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.ShWbMsg.Proc = j);
endruleset;


ruleset j : NODE do
Invariant "rule_3867"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Proc[j].ProcCmd = NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3868"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset j : NODE do
Invariant "rule_3869"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd = NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_3870"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[j].ProcCmd = NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_3871"
	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.ShWbMsg.Cmd = SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3872"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_3873"
	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3874"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[j].Proc = i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3875"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.HeadPtr = i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3876"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_3877"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_GetX -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_3878"
	(Sta.Proc[j].ProcCmd = NODE_GetX & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3879"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd = NODE_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_3880"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[j].ProcCmd = NODE_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3881"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[j].ProcCmd = NODE_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_3882"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.WbMsg.Data != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_3883"
	(Sta.WbMsg.Data = Sta.CurrData & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3884"
		(i != j) ->	(Sta.UniMsg[i].Cmd != UNI_PutX & Sta.Dir.HeadVld = true -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3885"
		(i != j) ->	(Sta.UniMsg[i].Cmd != UNI_PutX & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3886"
		(i != j) ->	(Sta.UniMsg[i].Cmd != UNI_PutX & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3887"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd != UNI_PutX -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3888"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Data != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3889"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3890"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3891"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3892"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd != UNI_PutX -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3893"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheState != CACHE_I -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3894"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd != UNI_PutX -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3895"
		(j != i) ->	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3896"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3897"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3898"
		(j != i) ->	(Sta.UniMsg[j].Data != Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3899"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3900"
		(j != i) ->	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3901"
		(j != i) ->	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3902"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_PutX & Sta.Proc[j].CacheState != CACHE_I -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3903"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadVld = true -> Sta.UniMsg[i].Cmd = UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3904"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Cmd = UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3905"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3906"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Cmd = UNI_PutX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3907"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3908"
		(j != i) ->	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_PutX -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_3909"
	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Dir.ShrVld = true -> Sta.UniMsg[i].Data = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_3910"
	(Sta.Proc[i].InvMarked = true & Sta.Dir.ShrVld = true -> Sta.UniMsg[i].Data = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_3911"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.ShrVld = true -> Sta.Proc[i].ProcCmd = NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_3912"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.ShrVld = true -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_3913"
	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.Dir.ShrVld = true -> Sta.UniMsg[i].Data = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_3914"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Dir.ShrVld = true -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_3915"
	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Dir.ShrVld = true -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_3916"
	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Dir.ShrVld = true -> Sta.Proc[i].ProcCmd = NODE_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3917"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Dir.ShrVld = true -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_3918"
	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Dir.ShrVld = true -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_3919"
	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Dir.ShrVld = true -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_3920"
	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Dir.ShrVld = true -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3921"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Dir.ShrVld = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE do
Invariant "rule_3922"
	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Dir.ShrVld = true -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_3923"
	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Dir.ShrVld = true -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_3924"
	(Sta.Dir.ShrVld = true & Sta.Proc[i].CacheState != CACHE_I -> Sta.Proc[i].CacheData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_3925"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.Dir.ShrVld = true -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_3926"
	(Sta.Proc[i].CacheState = CACHE_S & Sta.Dir.ShrVld = true -> Sta.Proc[i].CacheData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_3927"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.Dir.ShrVld = true -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3928"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Dir.ShrVld = true -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3929"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.Dir.ShrVld = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3930"
		(j != i) ->	(Sta.Dir.ShrVld = true & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3931"
	(Sta.UniMsg[i].Cmd = UNI_Nak & Sta.Dir.ShrVld = true -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3932"
		(j != i) ->	(Sta.UniMsg[j].Data != Sta.CurrData & Sta.Dir.ShrVld = true -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3933"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Dir.ShrVld = true -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3934"
	(Sta.UniMsg[i].Cmd != UNI_Put & Sta.Dir.ShrVld = true -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3935"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.Dir.ShrVld = true -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_3936"
	(Sta.Proc[i].InvMarked = true & Sta.Dir.ShrVld = true -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3937"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.Dir.ShrVld = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE do
Invariant "rule_3938"
	(Sta.Proc[i].InvMarked = true & Sta.Dir.ShrVld = true -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3939"
		(j != i) ->	(Sta.UniMsg[j].Data != Sta.CurrData & Sta.Dir.ShrVld = true -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_3940"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.ShrVld = true -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_3941"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Dir.ShrVld = true -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_3942"
	(Sta.Dir.ShrVld = true & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_3943"
	(Sta.Dir.ShrVld = true & Sta.Proc[j].CacheState != CACHE_I -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_3944"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Dir.ShrVld = true -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3945"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Dir.ShrVld = true -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3946"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.Dir.ShrVld = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE do
Invariant "rule_3947"
	(Sta.WbMsg.Data = Sta.CurrData & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3948"
	(Sta.Proc[i].ProcCmd != NODE_Get & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3949"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_None -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3950"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.UniMsg[i].Cmd != UNI_Put -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3951"
	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Proc[i].CacheState != CACHE_I -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3952"
	(Sta.Proc[i].ProcCmd != NODE_Get & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3953"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3954"
	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3955"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.UniMsg[j].Data != Sta.CurrData -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3956"
	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_None -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3957"
	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Proc[i].CacheState = CACHE_S -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3958"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3959"
	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.UniMsg[i].Cmd != UNI_Put -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3960"
	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3961"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3962"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Dir.ShrVld = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3963"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3964"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3965"
	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3966"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Data != Sta.CurrData -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3967"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3968"
	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[i].Cmd != UNI_Put -> Sta.Dir.ShrVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_3969"
	(Sta.Proc[i].CacheState != CACHE_S & Sta.Proc[i].CacheState != CACHE_I -> Sta.Dir.ShrVld = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3970"
		(j != i) ->	(Sta.UniMsg[j].Data != Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Dir.ShrVld = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3971"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.ShrVld = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3972"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.Dir.ShrVld = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3973"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Dir.ShrVld = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3974"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheState != CACHE_I -> Sta.Dir.ShrVld = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3975"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.Dir.ShrVld = false);
endruleset;


ruleset j : NODE do
Invariant "rule_3976"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.WbMsg.Data != Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3977"
		(j != i) ->	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Proc[j].ProcCmd != NODE_None -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3978"
		(j != i) ->	(Sta.Proc[j].ProcCmd != NODE_None & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3979"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Data != Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3980"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3981"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3982"
		(j != i) ->	(Sta.ShWbMsg.Proc = j & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_3983"
	(Sta.UniMsg[j].Data != Sta.CurrData & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_3984"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_3985"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_3986"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_3987"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Proc[j].ProcCmd != NODE_None -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_3988"
	(Sta.Proc[j].ProcCmd != NODE_None & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3989"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_3990"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3991"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[j].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_3992"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.WbMsg.Data != Sta.CurrData -> Sta.Proc[j].ProcCmd = NODE_None);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3993"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_None & Sta.UniMsg[j].Data != Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3994"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_None & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3995"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_None & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3996"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.Proc[j].ProcCmd = NODE_None);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3997"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Proc[j].ProcCmd = NODE_None);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_3998"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].ProcCmd = NODE_None -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_3999"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_None & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4000"
		(j != i) ->	(Sta.ShWbMsg.Proc = j & Sta.Proc[j].ProcCmd = NODE_None -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_4001"
	(Sta.Proc[j].ProcCmd = NODE_None & Sta.UniMsg[j].Data != Sta.CurrData -> Sta.Proc[j].CacheData != Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_4002"
	(Sta.Proc[j].ProcCmd = NODE_None & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_4003"
	(Sta.Proc[j].ProcCmd = NODE_None & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].CacheData = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_4004"
	(Sta.Proc[j].ProcCmd = NODE_None & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4005"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_None & Sta.UniMsg[j].Proc = i -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_4006"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.Proc[j].ProcCmd = NODE_None);
endruleset;


ruleset j : NODE do
Invariant "rule_4007"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Proc[j].ProcCmd = NODE_None);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4008"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].ProcCmd = NODE_None -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_4009"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_None -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4010"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_None & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4011"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_None & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE do
Invariant "rule_4012"
	(Sta.UniMsg[i].Data != Sta.CurrData & Sta.WbMsg.Data != Sta.CurrData -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_4013"
	(Sta.Proc[i].InvMarked = true & Sta.WbMsg.Data != Sta.CurrData -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_4014"
	(Sta.Proc[i].ProcCmd = NODE_Get & Sta.WbMsg.Data != Sta.CurrData -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_4015"
	(Sta.UniMsg[i].Cmd = UNI_Nak & Sta.WbMsg.Data != Sta.CurrData -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_4016"
	(Sta.Proc[i].CacheState = CACHE_S & Sta.WbMsg.Data != Sta.CurrData -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_4017"
	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.WbMsg.Data != Sta.CurrData -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_4018"
	(Sta.UniMsg[i].Cmd = UNI_GetX & Sta.WbMsg.Data != Sta.CurrData -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_4019"
	(Sta.WbMsg.Data = Sta.CurrData & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_4020"
	(Sta.WbMsg.Data = Sta.CurrData & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_4021"
	(Sta.WbMsg.Data = Sta.CurrData & Sta.Proc[i].InvMarked = true -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_4022"
	(Sta.WbMsg.Data = Sta.CurrData & Sta.Proc[i].CacheState = CACHE_S -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_4023"
	(Sta.WbMsg.Data = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_Put -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4024"
		(j != i) ->	(Sta.ShWbMsg.Proc = j & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4025"
		(j != i) ->	(Sta.UniMsg[j].Data != Sta.CurrData & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4026"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4027"
		(j != i) ->	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4028"
		(j != i) ->	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4029"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4030"
		(i != j) ->	(Sta.UniMsg[i].Data != Sta.CurrData & Sta.Proc[j].CacheState != CACHE_I -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_4031"
	(Sta.Dir.HeadPtr = i & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_4032"
	(Sta.MemData != Sta.CurrData & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4033"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Data != Sta.CurrData -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4034"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4035"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4036"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4037"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheState != CACHE_I -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4038"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4039"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4040"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Proc[j].CacheState != CACHE_I -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_4041"
	(Sta.Dir.HeadVld = true & Sta.Proc[i].InvMarked = true -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_4042"
	(Sta.Dir.HeadVld = true & Sta.Proc[i].CacheState = CACHE_S -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_4043"
	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.Dir.HeadVld = true -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4044"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.UniMsg[j].Proc = i -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4045"
		(j != i) ->	(Sta.ShWbMsg.Proc = j & Sta.Proc[i].InvMarked = true -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4046"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Data != Sta.CurrData -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4047"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4048"
		(j != i) ->	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Proc[i].InvMarked = true -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4049"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4050"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Proc = i -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4051"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.Proc[j].CacheState != CACHE_I -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_4052"
	(Sta.Dir.HeadPtr = i & Sta.Proc[i].InvMarked = true -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_4053"
	(Sta.Proc[i].InvMarked = true & Sta.MemData != Sta.CurrData -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4054"
		(j != i) ->	(Sta.ShWbMsg.Proc = j & Sta.Proc[i].CacheState = CACHE_S -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4055"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.ShWbMsg.Proc = j -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4056"
		(j != i) ->	(Sta.UniMsg[j].Data != Sta.CurrData & Sta.Proc[i].CacheState = CACHE_S -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4057"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.UniMsg[j].Data != Sta.CurrData -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE do
Invariant "rule_4058"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4059"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[i].CacheState = CACHE_S -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4060"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE do
Invariant "rule_4061"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE do
Invariant "rule_4062"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE do
Invariant "rule_4063"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheState != CACHE_I -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4064"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4065"
		(j != i) ->	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Proc[i].CacheState = CACHE_S -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4066"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4067"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_S & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4068"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4069"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Proc[i].CacheState = CACHE_S -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4070"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_S & Sta.Proc[j].CacheState != CACHE_I -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_4071"
	(Sta.Dir.HeadPtr = i & Sta.Proc[i].CacheState = CACHE_S -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_4072"
	(Sta.MemData != Sta.CurrData & Sta.Proc[i].CacheState = CACHE_S -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4073"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.UniMsg[j].Proc = i -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4074"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.Proc[j].CacheState != CACHE_I -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_4075"
	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.Dir.HeadPtr = i -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_4076"
	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.MemData != Sta.CurrData -> Sta.NakcMsg.Cmd != NAKC_Nakc);
endruleset;


ruleset i : NODE do
Invariant "rule_4077"
	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.WbMsg.Data != Sta.CurrData -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_4078"
	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.WbMsg.Data != Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_4079"
	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.WbMsg.Data != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_4080"
	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.WbMsg.Data != Sta.CurrData -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_4081"
	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.WbMsg.Data != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_4082"
	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.WbMsg.Data != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_4083"
	(Sta.WbMsg.Data = Sta.CurrData & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_4084"
	(Sta.WbMsg.Data = Sta.CurrData & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_4085"
	(Sta.WbMsg.Data = Sta.CurrData & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4086"
		(i != j) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.ShWbMsg.Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4087"
		(i != j) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4088"
		(i != j) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_4089"
	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE do
Invariant "rule_4090"
	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.MemData = Sta.CurrData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4091"
		(j != i) ->	(Sta.UniMsg[j].Data != Sta.CurrData & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4092"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4093"
		(j != i) ->	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4094"
		(j != i) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4095"
		(j != i) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[j].CacheState != CACHE_I -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4096"
		(i != j) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4097"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4098"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4099"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_4100"
	(Sta.Dir.HeadVld = true & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_4101"
	(Sta.Dir.HeadVld = true & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_4102"
	(Sta.Dir.HeadVld = true & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_4103"
	(Sta.Proc[i].InvMarked = true & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_4104"
	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[i].CacheState = CACHE_S -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_4105"
	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Dir.HeadVld = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4106"
		(j != i) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4107"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4108"
		(j != i) ->	(Sta.ShWbMsg.Proc = j & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4109"
		(j != i) ->	(Sta.UniMsg[j].Data != Sta.CurrData & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4110"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4111"
		(j != i) ->	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4112"
		(j != i) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4113"
		(j != i) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[j].Proc = i -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4114"
		(j != i) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[j].CacheState != CACHE_I -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_4115"
	(Sta.Dir.HeadPtr = i & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_4116"
	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.MemData != Sta.CurrData -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4117"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.ShWbMsg.Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4118"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4119"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_4120"
	(Sta.Proc[i].InvMarked = true & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE do
Invariant "rule_4121"
	(Sta.Proc[i].InvMarked = true & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.MemData = Sta.CurrData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4122"
		(i != j) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[i].CacheState = CACHE_S -> Sta.ShWbMsg.Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4123"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.ShWbMsg.Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4124"
		(j != i) ->	(Sta.ShWbMsg.Proc = j & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4125"
		(j != i) ->	(Sta.ShWbMsg.Proc = j & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4126"
		(j != i) ->	(Sta.UniMsg[j].Data != Sta.CurrData & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4127"
		(j != i) ->	(Sta.UniMsg[j].Data != Sta.CurrData & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_4128"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4129"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4130"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_4131"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_4132"
	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_4133"
	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[j].CacheState != CACHE_I -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_4134"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4135"
		(j != i) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4136"
		(j != i) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4137"
		(j != i) ->	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4138"
		(j != i) ->	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4139"
		(j != i) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4140"
		(j != i) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4141"
		(j != i) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[j].Proc = i -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4142"
		(j != i) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[j].CacheState != CACHE_I -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_4143"
	(Sta.Dir.HeadPtr = i & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_4144"
	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.MemData != Sta.CurrData -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4145"
		(i != j) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[i].CacheState = CACHE_S -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4146"
		(i != j) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[i].CacheState = CACHE_S -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_4147"
	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[i].CacheState = CACHE_S -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE do
Invariant "rule_4148"
	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[i].CacheState = CACHE_S -> Sta.MemData = Sta.CurrData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4149"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4150"
		(j != i) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4151"
		(j != i) ->	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.Proc[j].CacheState != CACHE_I -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4152"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_4153"
	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE do
Invariant "rule_4154"
	(Sta.Dir.HeadPtr = i & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_4155"
	(Sta.NakcMsg.Cmd = NAKC_Nakc & Sta.MemData != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_4156"
	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.NakcMsg.Cmd = NAKC_Nakc -> Sta.MemData = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_4157"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.WbMsg.Data != Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_4158"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.WbMsg.Data != Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4159"
		(i != j) ->	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.WbMsg.Data != Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4160"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_GetX & Sta.WbMsg.Data != Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4161"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.WbMsg.Data != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_4162"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.WbMsg.Data != Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_4163"
	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.WbMsg.Data != Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_4164"
	(Sta.Proc[j].ProcCmd = NODE_Get & Sta.WbMsg.Data != Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset i : NODE do
Invariant "rule_4165"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.WbMsg.Data != Sta.CurrData -> Sta.Proc[i].CacheState != CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_4166"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.WbMsg.Data != Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_4167"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.WbMsg.Data != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_4168"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.WbMsg.Data != Sta.CurrData -> Sta.Proc[i].ProcCmd = NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_4169"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.WbMsg.Data != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_4170"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.WbMsg.Data != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_4171"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.WbMsg.Data != Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_4172"
	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.WbMsg.Data != Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_4173"
	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.WbMsg.Data != Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_4174"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.WbMsg.Data != Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_4175"
	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.WbMsg.Data != Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_4176"
	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.WbMsg.Data != Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_4177"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.WbMsg.Data != Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_4178"
	(Sta.ShWbMsg.Cmd = SHWB_FAck & Sta.WbMsg.Data != Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_4179"
	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.WbMsg.Data != Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4180"
		(j != i) ->	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.WbMsg.Data != Sta.CurrData -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_4181"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.WbMsg.Data != Sta.CurrData -> Sta.Proc[j].CacheState != CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_4182"
	(Sta.WbMsg.Data = Sta.CurrData & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset i : NODE do
Invariant "rule_4183"
	(Sta.WbMsg.Data = Sta.CurrData & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Proc[i].ProcCmd = NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_4184"
	(Sta.WbMsg.Data = Sta.CurrData & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_4185"
	(Sta.WbMsg.Data = Sta.CurrData & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4186"
		(i != j) ->	(Sta.WbMsg.Data = Sta.CurrData & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4187"
		(i != j) ->	(Sta.WbMsg.Data = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4188"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.WbMsg.Data = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_4189"
	(Sta.WbMsg.Data = Sta.CurrData & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_4190"
	(Sta.WbMsg.Data = Sta.CurrData & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Proc[i].CacheState != CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_4191"
	(Sta.WbMsg.Data = Sta.CurrData & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_4192"
	(Sta.WbMsg.Data = Sta.CurrData & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_4193"
	(Sta.WbMsg.Data = Sta.CurrData & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Proc[i].ProcCmd = NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_4194"
	(Sta.WbMsg.Data = Sta.CurrData & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Proc[i].CacheState = CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_4195"
	(Sta.WbMsg.Data = Sta.CurrData & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_4196"
	(Sta.WbMsg.Data = Sta.CurrData & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_4197"
	(Sta.WbMsg.Data = Sta.CurrData & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_4198"
	(Sta.UniMsg[j].Cmd != UNI_PutX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_4199"
	(Sta.UniMsg[j].Cmd != UNI_PutX & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_4200"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_4201"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_4202"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.UniMsg[j].Cmd != UNI_PutX -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4203"
		(j != i) ->	(Sta.UniMsg[j].Cmd != UNI_PutX & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4204"
		(j != i) ->	(Sta.UniMsg[j].Cmd != UNI_PutX & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_4205"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[j].Cmd = UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_4206"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Cmd = UNI_PutX);
endruleset;


ruleset j : NODE do
Invariant "rule_4207"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_PutX -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_4208"
	(Sta.UniMsg[j].Cmd = UNI_PutX & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_4209"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Cmd = UNI_PutX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4210"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Cmd = UNI_PutX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4211"
		(i != j) ->	(Sta.Proc[i].ProcCmd != NODE_Get & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4212"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4213"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4214"
		(i != j) ->	(Sta.UniMsg[i].Cmd != UNI_Put & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4215"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Proc[i].ProcCmd = NODE_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4216"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4217"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4218"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_4219"
	(Sta.Proc[i].ProcCmd != NODE_Get & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Proc[i].CacheData != Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_4220"
	(Sta.UniMsg[i].Data != Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_None -> Sta.Proc[i].CacheData != Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_4221"
	(Sta.UniMsg[i].Cmd != UNI_Put & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Proc[i].CacheData != Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_4222"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Proc[i].ProcCmd = NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_4223"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_4224"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_4225"
	(Sta.Proc[i].InvMarked = false & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_4226"
	(Sta.Proc[i].ProcCmd != NODE_Get & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_4227"
	(Sta.UniMsg[i].Data != Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_None -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_4228"
	(Sta.UniMsg[i].Cmd != UNI_Put & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_4229"
	(Sta.InvMsg[i].Cmd = INV_InvAck & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Proc[i].InvMarked = true);
endruleset;


ruleset i : NODE do
Invariant "rule_4230"
	(Sta.InvMsg[i].Cmd = INV_InvAck & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Proc[i].ProcCmd = NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_4231"
	(Sta.InvMsg[i].Cmd = INV_InvAck & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_4232"
	(Sta.InvMsg[i].Cmd = INV_InvAck & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4233"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4234"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE do
Invariant "rule_4235"
	(Sta.UniMsg[i].Cmd != UNI_Put & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_4236"
	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4237"
		(i != j) ->	(Sta.Proc[i].ProcCmd != NODE_Get & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.ShWbMsg.Proc != j);
endruleset;


ruleset i : NODE do
Invariant "rule_4238"
	(Sta.UniMsg[i].Cmd != UNI_Put & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4239"
		(j != i) ->	(Sta.ShWbMsg.Proc = j & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Proc[i].ProcCmd = NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_4240"
	(Sta.Proc[i].ProcCmd = NODE_Get & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4241"
		(i != j) ->	(Sta.UniMsg[i].Data != Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_None -> Sta.ShWbMsg.Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4242"
		(i != j) ->	(Sta.UniMsg[i].Cmd != UNI_Put & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.ShWbMsg.Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4243"
		(j != i) ->	(Sta.ShWbMsg.Proc = j & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4244"
		(j != i) ->	(Sta.ShWbMsg.Proc = j & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4245"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4246"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4247"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE do
Invariant "rule_4248"
	(Sta.Proc[i].ProcCmd != NODE_None & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_4249"
	(Sta.UniMsg[i].Cmd != UNI_Put & Sta.UniMsg[i].Data != Sta.CurrData -> Sta.Proc[i].ProcCmd = NODE_None);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4250"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadVld = true -> Sta.UniMsg[i].Data = Sta.CurrData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4251"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Data = Sta.CurrData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4252"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Data = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_4253"
	(Sta.Dir.HeadVld = true & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.UniMsg[i].Data = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_4254"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_4255"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_None -> Sta.Proc[i].CacheData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_4256"
	(Sta.Dir.HeadVld = true & Sta.Proc[i].InvMarked = true -> Sta.UniMsg[i].Data = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_4257"
	(Sta.Dir.HeadVld = true & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_4258"
	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.Dir.HeadVld = true -> Sta.UniMsg[i].Data = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_4259"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_None -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_4260"
	(Sta.Proc[i].InvMarked = false & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_4261"
	(Sta.Proc[i].ProcCmd != NODE_Get & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_4262"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_None -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_4263"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.UniMsg[i].Cmd != UNI_Put -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_4264"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.MemData != Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_4265"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Proc[i].InvMarked = true);
endruleset;


ruleset i : NODE do
Invariant "rule_4266"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Proc[i].ProcCmd = NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_4267"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_4268"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_4269"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.MemData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_4270"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.UniMsg[i].Cmd != UNI_Put -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_4271"
	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_4272"
	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.UniMsg[i].Cmd != UNI_Put -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE do
Invariant "rule_4273"
	(Sta.Proc[i].ProcCmd = NODE_Get & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4274"
		(i != j) ->	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_None -> Sta.ShWbMsg.Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4275"
		(j != i) ->	(Sta.ShWbMsg.Proc = j & Sta.UniMsg[i].Data = Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4276"
		(i != j) ->	(Sta.UniMsg[i].Data = Sta.CurrData & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4277"
		(j != i) ->	(Sta.UniMsg[j].Data != Sta.CurrData & Sta.Proc[j].ProcCmd != NODE_Get -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4278"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd != NODE_Get -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4279"
		(j != i) ->	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_Get -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4280"
		(j != i) ->	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_Get -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4281"
		(i != j) ->	(Sta.Dir.HeadVld = true & Sta.Proc[i].InvMarked = true -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4282"
		(i != j) ->	(Sta.Proc[i].ProcCmd = NODE_Get & Sta.Dir.HeadVld = true -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4283"
		(i != j) ->	(Sta.Dir.HeadVld = true & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4284"
		(j != i) ->	(Sta.Dir.HeadVld = true & Sta.UniMsg[j].Data != Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4285"
		(j != i) ->	(Sta.Dir.HeadVld = true & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4286"
		(j != i) ->	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Dir.HeadVld = true -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4287"
		(j != i) ->	(Sta.Dir.HeadVld = true & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4288"
		(j != i) ->	(Sta.Dir.HeadVld = true & Sta.Proc[j].CacheState != CACHE_I -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4289"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.Dir.HeadVld = true -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4290"
		(i != j) ->	(Sta.Dir.HeadVld = true & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4291"
		(j != i) ->	(Sta.Dir.HeadVld = false & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4292"
		(i != j) ->	(Sta.Dir.HeadVld = false & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4293"
		(j != i) ->	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4294"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4295"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4296"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.Proc[i].InvMarked = true -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4297"
		(i != j) ->	(Sta.Proc[i].ProcCmd = NODE_Get & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4298"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.Proc[i].ProcCmd = NODE_Get -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4299"
		(j != i) ->	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4300"
		(j != i) ->	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4301"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Nak & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4302"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4303"
		(j != i) ->	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.UniMsg[j].Data != Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4304"
		(j != i) ->	(Sta.UniMsg[j].Data != Sta.CurrData & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4305"
		(j != i) ->	(Sta.UniMsg[j].Data != Sta.CurrData & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4306"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[j].Data != Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4307"
		(j != i) ->	(Sta.UniMsg[j].Data != Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4308"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4309"
		(j != i) ->	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4310"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4311"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4312"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4313"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4314"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.MemData != Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4315"
		(j != i) ->	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4316"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4317"
		(j != i) ->	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4318"
		(j != i) ->	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Proc[j].CacheState = CACHE_I -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4319"
		(j != i) ->	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4320"
		(j != i) ->	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4321"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4322"
		(j != i) ->	(Sta.Proc[j].CacheState = CACHE_I & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4323"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4324"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_GetX & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4325"
		(j != i) ->	(Sta.MemData != Sta.CurrData & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4326"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Dir.HeadPtr != i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4327"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4328"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_GetX & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4329"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.Proc[j].CacheState != CACHE_I -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4330"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_GetX & Sta.Proc[j].CacheState != CACHE_I -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4331"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4332"
		(i != j) ->	(Sta.Dir.HeadPtr = i & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4333"
		(i != j) ->	(Sta.MemData != Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.UniMsg[i].Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4334"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4335"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4336"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Data != Sta.CurrData -> Sta.Proc[j].ProcCmd = NODE_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4337"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd = NODE_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4338"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadVld = true -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4339"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadVld = true -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4340"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadVld = true -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4341"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Proc = i -> Sta.Dir.HeadVld = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4342"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadVld = true -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4343"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadPtr = i -> Sta.Dir.HeadVld = true);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4344"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadVld = true -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4345"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadVld = true -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4346"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[i].InvMarked = true -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4347"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[i].ProcCmd = NODE_Get -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4348"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4349"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Data != Sta.CurrData -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4350"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4351"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4352"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4353"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadVld = false -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4354"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheState != CACHE_I -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4355"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadVld = false -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4356"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd = UNI_Put -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4357"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4358"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4359"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4360"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Proc = i -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4361"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadPtr = i -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4362"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[i].InvMarked = true -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4363"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[i].InvMarked = true -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4364"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Proc = i -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4365"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadPtr = i -> Sta.Proc[i].ProcCmd != NODE_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4366"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[i].ProcCmd = NODE_Get -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4367"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[i].ProcCmd = NODE_Get -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4368"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4369"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4370"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4371"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4372"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4373"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4374"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Data != Sta.CurrData -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4375"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Data != Sta.CurrData -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4376"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Data != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4377"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4378"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4379"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4380"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4381"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.MemData = Sta.CurrData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4382"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4383"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4384"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4385"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.Proc[j].CacheState != CACHE_I);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4386"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4387"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4388"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4389"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Proc[j].CacheState != CACHE_I);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4390"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4391"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4392"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.MemData = Sta.CurrData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4393"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadPtr != i -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4394"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd = UNI_Put -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4395"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4396"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Proc = i -> Sta.Dir.HeadPtr = i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4397"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4398"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4399"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheState != CACHE_I -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4400"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Proc[j].CacheState != CACHE_I -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4401"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadPtr = i -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4402"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4403"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd = UNI_Put -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4404"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4405"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4406"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.Dir.HeadPtr = i -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4407"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.MemData != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4408"
		(i != j) ->	(Sta.UniMsg[i].Proc = j & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.MemData = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_4409"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_4410"
	(Sta.UniMsg[j].Data != Sta.CurrData & Sta.Proc[j].ProcCmd != NODE_Get -> Sta.Proc[j].CacheData != Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_4411"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_4412"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_4413"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Cmd != UNI_Get -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_4414"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_4415"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4416"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Proc = i -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_4417"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_4418"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4419"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[j].ProcCmd != NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_4420"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].ProcCmd = NODE_Get -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_4421"
	(Sta.Proc[j].ProcCmd = NODE_Get & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_4422"
	(Sta.UniMsg[j].Data != Sta.CurrData & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Proc[j].ProcCmd = NODE_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_4423"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_Get -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_4424"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_Get -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_4425"
	(Sta.UniMsg[j].Cmd != UNI_Get & Sta.Proc[j].ProcCmd = NODE_Get -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_4426"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_Get -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_4427"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_Get -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4428"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Proc[j].ProcCmd = NODE_Get -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_4429"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].ProcCmd = NODE_Get -> Sta.UniMsg[j].Cmd = UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4430"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].ProcCmd = NODE_Get -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_4431"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_Get -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_4432"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.Proc[j].ProcCmd = NODE_Get -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4433"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Proc[j].ProcCmd = NODE_Get -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4434"
		(j != i) ->	(Sta.Proc[j].ProcCmd = NODE_Get & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE do
Invariant "rule_4435"
	(Sta.Dir.HeadVld = true & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_4436"
	(Sta.Dir.HeadVld = true & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_4437"
	(Sta.Dir.HeadVld = true & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Proc[i].ProcCmd != NODE_None);
endruleset;


ruleset i : NODE do
Invariant "rule_4438"
	(Sta.Dir.HeadVld = true & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset i : NODE do
Invariant "rule_4439"
	(Sta.Dir.HeadVld = true & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_4440"
	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Proc[i].CacheState != CACHE_I -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_4441"
	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_4442"
	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Proc[i].ProcCmd = NODE_None -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_4443"
	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.Proc[i].CacheState = CACHE_S -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_4444"
	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4445"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.ShWbMsg.Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4446"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.ShWbMsg.Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4447"
		(j != i) ->	(Sta.ShWbMsg.Proc = j & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4448"
		(j != i) ->	(Sta.ShWbMsg.Proc = j & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4449"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_4450"
	(Sta.Dir.HeadPtr = i & Sta.Proc[i].CacheData != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4451"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE do
Invariant "rule_4452"
	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4453"
		(i != j) ->	(Sta.Proc[i].CacheData != Sta.CurrData & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_4454"
	(Sta.Dir.HeadVld = true & Sta.Proc[i].CacheState != CACHE_I -> Sta.Proc[i].CacheData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_4455"
	(Sta.Dir.HeadVld = true & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_4456"
	(Sta.Dir.HeadVld = true & Sta.Proc[i].CacheState = CACHE_S -> Sta.Proc[i].CacheData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_4457"
	(Sta.Dir.HeadVld = true & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE do
Invariant "rule_4458"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_4459"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_4460"
	(Sta.Proc[i].CacheState != CACHE_S & Sta.Proc[i].CacheState != CACHE_I -> Sta.Proc[i].CacheData = Sta.CurrData);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4461"
		(i != j) ->	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.ShWbMsg.Proc != j);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4462"
		(i != j) ->	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_GetX -> Sta.ShWbMsg.Proc != j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4463"
		(j != i) ->	(Sta.ShWbMsg.Proc = j & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4464"
		(j != i) ->	(Sta.ShWbMsg.Proc = j & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4465"
		(i != j) ->	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_4466"
	(Sta.Dir.HeadPtr = i & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4467"
		(i != j) ->	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE do
Invariant "rule_4468"
	(Sta.Proc[i].CacheData = Sta.CurrData & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Dir.HeadPtr != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4469"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[i].CacheData = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_4470"
	(Sta.Dir.HeadVld = true & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_4471"
	(Sta.Dir.HeadVld = true & Sta.UniMsg[i].Cmd != UNI_Put -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_4472"
	(Sta.Dir.HeadVld = true & Sta.MemData != Sta.CurrData -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE do
Invariant "rule_4473"
	(Sta.Dir.HeadVld = true & Sta.Proc[i].InvMarked = true -> Sta.UniMsg[i].Cmd != UNI_Nak);
endruleset;


ruleset i : NODE do
Invariant "rule_4474"
	(Sta.Dir.HeadVld = true & Sta.Proc[i].InvMarked = true -> Sta.UniMsg[i].Cmd = UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_4475"
	(Sta.Dir.HeadVld = true & Sta.Proc[i].InvMarked = true -> Sta.MemData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_4476"
	(Sta.Proc[i].CacheState != CACHE_S & Sta.Proc[i].CacheState != CACHE_I -> Sta.Dir.HeadVld = true);
endruleset;


ruleset j : NODE do
Invariant "rule_4477"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.HeadVld = true);
endruleset;


ruleset j : NODE do
Invariant "rule_4478"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.HeadVld = true);
endruleset;


ruleset j : NODE do
Invariant "rule_4479"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.HeadVld = true);
endruleset;


ruleset j : NODE do
Invariant "rule_4480"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.HeadVld = true);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4481"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.HeadVld = true);
endruleset;


ruleset j : NODE do
Invariant "rule_4482"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.HeadVld = true);
endruleset;


ruleset i : NODE do
Invariant "rule_4483"
	(Sta.Dir.HeadVld = true & Sta.MemData != Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_4484"
	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.Dir.HeadVld = true -> Sta.MemData = Sta.CurrData);
endruleset;


ruleset i : NODE do
Invariant "rule_4485"
	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[i].Cmd = UNI_Nak -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_4486"
	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[i].Cmd != UNI_Put -> Sta.Dir.HeadVld = false);
endruleset;


ruleset i : NODE do
Invariant "rule_4487"
	(Sta.Proc[i].InvMarked = true & Sta.MemData != Sta.CurrData -> Sta.Dir.HeadVld = false);
endruleset;


ruleset j : NODE do
Invariant "rule_4488"
	(Sta.Dir.HeadVld = false & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_4489"
	(Sta.Dir.HeadVld = false & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_4490"
	(Sta.Dir.HeadVld = false & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_4491"
	(Sta.Dir.HeadVld = false & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4492"
		(j != i) ->	(Sta.Dir.HeadVld = false & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_4493"
	(Sta.Dir.HeadVld = false & Sta.Proc[j].CacheState != CACHE_I -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4494"
		(j != i) ->	(Sta.Dir.HeadVld = false & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_4495"
	(Sta.Dir.HeadVld = false & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset i : NODE do
Invariant "rule_4496"
	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.MemData != Sta.CurrData -> Sta.Dir.HeadVld = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4497"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.UniMsg[j].Proc = i -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE do
Invariant "rule_4498"
	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.Proc[i].InvMarked = false -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4499"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4500"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4501"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4502"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheState != CACHE_I -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4503"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.InvMsg[i].Cmd != INV_InvAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4504"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4505"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE do
Invariant "rule_4506"
	(Sta.Proc[i].InvMarked = false & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset i : NODE do
Invariant "rule_4507"
	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Proc[i].InvMarked = true);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4508"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4509"
		(j != i) ->	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4510"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4511"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck & Sta.Proc[j].CacheState != CACHE_I -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4512"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4513"
		(i != j) ->	(Sta.InvMsg[i].Cmd = INV_InvAck & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4514"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.InvMsg[i].Cmd = INV_InvAck -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4515"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_4516"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_4517"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_4518"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE do
Invariant "rule_4519"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4520"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4521"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Proc[i].CacheState = CACHE_S -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4522"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_GetX);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4523"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.UniMsg[j].Proc = i -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4524"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_4525"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_4526"
	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_4527"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_4528"
	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4529"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4530"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4531"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.UniMsg[j].Proc = i -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4532"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.Proc[i].CacheState = CACHE_S -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4533"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.UniMsg[j].Cmd = UNI_GetX -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4534"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_GetX & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4535"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4536"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.Proc[i].InvMarked = false);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4537"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4538"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4539"
		(i != j) ->	(Sta.Proc[i].InvMarked = true & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4540"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[i].CacheState != CACHE_I -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset i : NODE do
Invariant "rule_4541"
	(Sta.Proc[i].CacheState != CACHE_S & Sta.Proc[i].CacheState != CACHE_I -> Sta.Dir.HeadPtr = i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4542"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[i].CacheState = CACHE_I);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4543"
		(j != i) ->	(Sta.UniMsg[j].Data != Sta.CurrData & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Proc != j);
endruleset;


ruleset j : NODE do
Invariant "rule_4544"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.ShWbMsg.Proc != j -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_4545"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.ShWbMsg.Proc != j -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_4546"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.ShWbMsg.Proc != j -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_4547"
	(Sta.ShWbMsg.Proc != j & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4548"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Proc != j -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_4549"
	(Sta.ShWbMsg.Proc != j & Sta.Proc[j].CacheState != CACHE_I -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4550"
		(j != i) ->	(Sta.ShWbMsg.Proc != j & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_4551"
	(Sta.ShWbMsg.Proc != j & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4552"
		(j != i) ->	(Sta.ShWbMsg.Proc = j & Sta.UniMsg[j].Data != Sta.CurrData -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_4553"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.ShWbMsg.Proc = j);
endruleset;


ruleset j : NODE do
Invariant "rule_4554"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.ShWbMsg.Proc = j);
endruleset;


ruleset j : NODE do
Invariant "rule_4555"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.ShWbMsg.Proc = j);
endruleset;


ruleset j : NODE do
Invariant "rule_4556"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.ShWbMsg.Proc = j);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4557"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.ShWbMsg.Proc = j);
endruleset;


ruleset j : NODE do
Invariant "rule_4558"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.ShWbMsg.Proc = j);
endruleset;


ruleset j : NODE do
Invariant "rule_4559"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_4560"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_4561"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_4562"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4563"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Cmd != UNI_Nak);
endruleset;


ruleset j : NODE do
Invariant "rule_4564"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_4565"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_4566"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_4567"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4568"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.UniMsg[j].Cmd = UNI_Nak -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4569"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Nak & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4570"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[i].CacheState != CACHE_E);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4571"
		(i != j) ->	(Sta.Proc[i].CacheState = CACHE_E & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_4572"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_4573"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_4574"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.ShWbMsg.Cmd != SHWB_FAck -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4575"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Proc[i].CacheState = CACHE_S -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_4576"
	(Sta.WbMsg.Cmd = WB_Wb & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4577"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.UniMsg[j].Proc != i -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4578"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.HeadPtr != i -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4579"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_4580"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.ShWbMsg.Cmd = SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4581"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset j : NODE do
Invariant "rule_4582"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4583"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[j].Proc = i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4584"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.Dir.HeadPtr = i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4585"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_4586"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Data = Sta.CurrData);
endruleset;


ruleset j : NODE do
Invariant "rule_4587"
	(Sta.WbMsg.Cmd = WB_Wb & Sta.UniMsg[j].Data = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4588"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.UniMsg[j].Proc != i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4589"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.Dir.HeadPtr != i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_4590"
	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4591"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Data = Sta.CurrData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4592"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Proc = i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4593"
		(j != i) ->	(Sta.UniMsg[j].Data = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.HeadPtr = i);
endruleset;


ruleset j : NODE do
Invariant "rule_4594"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_4595"
	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4596"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_4597"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4598"
		(j != i) ->	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.UniMsg[j].Proc = i -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_4599"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Proc[j].CacheState = CACHE_I -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4600"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_4601"
	(Sta.Proc[j].CacheState = CACHE_I & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.RpMsg[j].Cmd != RP_Replace);
endruleset;


ruleset j : NODE do
Invariant "rule_4602"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_4603"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4604"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4605"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_4606"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4607"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_4608"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheData != Sta.CurrData -> Sta.Proc[j].CacheState != CACHE_I);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4609"
		(j != i) ->	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_4610"
	(Sta.RpMsg[j].Cmd = RP_Replace & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.Proc[j].CacheState != CACHE_I);
endruleset;


ruleset j : NODE do
Invariant "rule_4611"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_4612"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4613"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4614"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Proc[i].CacheState = CACHE_S -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4615"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[j].Cmd != UNI_Get);
endruleset;


ruleset j : NODE do
Invariant "rule_4616"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_4617"
	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4618"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4619"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4620"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.Proc[i].CacheState != CACHE_S);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4621"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.Proc[i].CacheState = CACHE_S -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4622"
		(i != j) ->	(Sta.UniMsg[i].Cmd = UNI_Put & Sta.UniMsg[j].Cmd = UNI_Get -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4623"
		(j != i) ->	(Sta.UniMsg[j].Cmd = UNI_Get & Sta.UniMsg[j].Proc = i -> Sta.UniMsg[i].Cmd != UNI_Put);
endruleset;


ruleset j : NODE do
Invariant "rule_4624"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.WbMsg.Cmd = WB_Wb -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4625"
		(j != i) ->	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.UniMsg[j].Proc != i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_4626"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Proc[j].CacheState != CACHE_I -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4627"
		(j != i) ->	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.Dir.HeadPtr != i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_4628"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4629"
		(j != i) ->	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Proc = i);
endruleset;


ruleset j : NODE do
Invariant "rule_4630"
	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4631"
		(j != i) ->	(Sta.Proc[j].CacheData != Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.HeadPtr = i);
endruleset;


ruleset j : NODE do
Invariant "rule_4632"
	(Sta.WbMsg.Cmd = WB_Wb & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4633"
		(i != j) ->	(Sta.Dir.HeadPtr != i & Sta.Proc[j].CacheData = Sta.CurrData -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_4634"
	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset j : NODE do
Invariant "rule_4635"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[j].CacheData = Sta.CurrData);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4636"
		(j != i) ->	(Sta.Proc[j].CacheData = Sta.CurrData & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.HeadPtr = i);
endruleset;


ruleset j : NODE do
Invariant "rule_4637"
	(Sta.Proc[j].CacheState != CACHE_E & Sta.Proc[j].CacheState != CACHE_I -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4638"
		(j != i) ->	(Sta.WbMsg.Cmd = WB_Wb & Sta.UniMsg[j].Proc = i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE do
Invariant "rule_4639"
	(Sta.WbMsg.Cmd = WB_Wb & Sta.Proc[j].CacheState != CACHE_I -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4640"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.Dir.HeadPtr != i -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4641"
		(i != j) ->	(Sta.Dir.HeadPtr != i & Sta.Proc[j].CacheState != CACHE_I -> Sta.ShWbMsg.Cmd != SHWB_FAck);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4642"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset j : NODE do
Invariant "rule_4643"
	(Sta.Proc[j].CacheState != CACHE_I & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.WbMsg.Cmd != WB_Wb);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4644"
		(j != i) ->	(Sta.WbMsg.Cmd = WB_Wb & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE do
Invariant "rule_4645"
	(Sta.WbMsg.Cmd = WB_Wb & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4646"
		(i != j) ->	(Sta.Dir.HeadPtr != i & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.UniMsg[j].Proc != i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4647"
		(j != i) ->	(Sta.UniMsg[j].Proc = i & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.HeadPtr = i);
endruleset;


ruleset j : NODE ; i : NODE do
Invariant "rule_4648"
		(j != i) ->	(Sta.Proc[j].CacheState != CACHE_I & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Dir.HeadPtr = i);
endruleset;


ruleset i : NODE ; j : NODE do
Invariant "rule_4649"
		(i != j) ->	(Sta.Dir.HeadPtr != i & Sta.ShWbMsg.Cmd = SHWB_FAck -> Sta.Proc[j].CacheState = CACHE_I);
endruleset;
