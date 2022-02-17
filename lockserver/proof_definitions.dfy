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

/************************************** Properties **************************************/

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

/* Main Inductive Invariant */
predicate Inv(cons:Constants, ds:DistrSys) 
{
    && Trivialities(cons, ds)
    && Safety(cons, ds)
    && ClientWorking_Implies_NoMatchingRelease(cons, ds)
    && NoMatchingRelease_Implies_ServerLocked(cons, ds)
    && ServerLocked_Implies_AtMostOneNonMatchedGrant(cons, ds)
}

/* Trivial parts of the main Inv */
predicate Trivialities(cons:Constants, ds:DistrSys) {
    && cons.WF() 
    && ds.WF(cons)
    && ValidPackets(cons, ds)
}

predicate ValidPackets(cons:Constants, ds:DistrSys) 
    requires cons.WF() && ds.WF(cons)
{
    forall p | p in ds.network.sentPackets ::
    match p.msg {
        case Request(_) => ClientToServerPkt(cons, p)
        case Release(_) => ClientToServerPkt(cons, p)
        case Grant(_) => ServerToClientPkt(cons, p)
        case Reject(_) => ServerToClientPkt(cons, p)
    }
}

/* For each client c in Working(s) and epoch e, there exists a Grant(s, c, e) with no 
matching Release */
predicate ClientWorking_Implies_NoMatchingRelease(cons:Constants, ds:DistrSys) 
    requires cons.WF() && ds.WF(cons)
{
    forall cidx | cons.ValidClientIdx(cidx) && ds.clients[cidx].state.Working? 
    ::
    var grant_p := Packet(ds.clients[cidx].state.sid, ds.clients[cidx].consts.id, Grant(ds.clients[cidx].epoch));
    && grant_p in ds.network.sentPackets
    && GetMatchingRelease(grant_p) !in ds.network.sentPackets
}

/* For each valid Grant packet, no matching release implies server is locked */
predicate NoMatchingRelease_Implies_ServerLocked(cons:Constants, ds:DistrSys) 
    requires cons.WF() && ds.WF(cons)
    requires ValidPackets(cons, ds)
{
    forall grant_p:Packet | 
        && IsGrantPacket(ds, grant_p)
        && GetMatchingRelease(grant_p) !in ds.network.sentPackets
    :: ds.servers[grant_p.src.idx].resource == Held(grant_p.dst)
}


/* Server locked implies at most one non-matched Grant */
predicate ServerLocked_Implies_AtMostOneNonMatchedGrant(cons:Constants, ds:DistrSys) 
    requires cons.WF() && ds.WF(cons)
    requires ValidPackets(cons, ds)
{
    //TODO 
    false
}

/***************************************** Utils *****************************************/

/* Is this client in the Working state? */
predicate ClientIsWorking(cons:Constants, ds:DistrSys, cidx:int)
    requires cons.WF() && ds.WF(cons)
    requires cons.ValidClientIdx(cidx)
{
    ds.clients[cidx].state.Working?
}

/* p is a packet from a server a client */
predicate ServerToClientPkt(cons:Constants, p:Packet)
    requires cons.WF()
{
    p.src in cons.server_ids && p.dst in cons.client_ids
}

/* p is a packet from a client a server */
predicate ClientToServerPkt(cons:Constants, p:Packet)
    requires cons.WF()
{
    p.src in cons.client_ids && p.dst in cons.server_ids
}

predicate IsGrantPacket(ds:DistrSys, p:Packet) {
    p.msg.Grant? && p in ds.network.sentPackets
}



/* Returns the corresponding Release packet for a Grant */
function {:opaque} GetMatchingRelease(p:Packet) : (r:Packet)
    requires p.msg.Grant?
    ensures r == Packet(p.dst, p.src, Release(p.msg.e))
{
    Packet(p.dst, p.src, Release(p.msg.e))
}
}