include "types.dfy"
include "network.dfy"
include "client.dfy"
include "server.dfy"
include "generic_definitions.dfy"
include "distributed_system.dfy"

module Proof_Defs {
import opened Types
import opened Network
import opened Client_Agent
import opened Server_Agent
import opened Generic_Defs
import opened System

predicate ClientIsWorking(cons:Constants, ds:DistrSys, cidx:int)
    requires cons.WF() && ds.WF(cons)
    requires cons.ValidClientIdx(cidx)
{
    ds.clients[cidx].state.Working?
}
}