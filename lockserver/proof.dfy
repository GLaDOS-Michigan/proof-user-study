include "types.dfy"
include "network.dfy"
include "client.dfy"
include "server.dfy"
include "generic_definitions.dfy"
include "distributed_system.dfy"
include "proof_definitions.dfy"

module Proof {
import opened Types
import opened Network
import opened Client_Agent
import opened Server_Agent
import opened Generic_Defs
import opened System
import opened Proof_Defs

/* Safety Property: No two clients can be working on the same server */
predicate Safety(cons:Constants, ds:DistrSys) 
    requires cons.WF() && ds.WF(cons)
{
    forall i, j | 
        && cons.ValidClientIdx(i)
        && cons.ValidClientIdx(j)
        && ClientIsWorking(cons, ds, i)
        && ClientIsWorking(cons, ds, j)
        && ds.clients[i].state.sid == ds.clients[j].state.sid
    ::
        i == j
}

predicate Inv(cons:Constants, ds:DistrSys) 
{
    && cons.WF() 
    && ds.WF(cons)
    && Safety(cons, ds)
}

lemma Inv_Init(cons:Constants, ds:DistrSys) 
    requires Init(cons, ds)
    ensures Inv(cons, ds)
{}

lemma Inv_Next(cons:Constants, ds:DistrSys, ds':DistrSys) 
    requires Inv(cons, ds)
    requires Next(cons, ds, ds')
    ensures Inv(cons, ds')
{}
}