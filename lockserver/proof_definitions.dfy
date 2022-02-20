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
    && ClientRelease_Implies_Idle(cons, ds)
    && NoMatchingRelease_Implies_ServerLocked(cons, ds)
    && ServerLocked_Implies_Granted(cons, ds)
    && ServerLocked_Implies_AtMostOneNonMatchedGrant(cons, ds)
}

/* Trivial parts of the main Inv */
predicate Trivialities(cons:Constants, ds:DistrSys) {
    && cons.WF() 
    && ds.WF(cons)
    && ValidPackets(cons, ds)
    && ValidLockHoldersAndGranters(cons, ds)
    && Granted_Implies_ClientEpochSeen(cons, ds)
}

predicate ValidPackets(cons:Constants, ds:DistrSys) 
    requires cons.WF() && ds.WF(cons)
{
    forall p | p in ds.network.sentPackets ::
    PacketIsValid(cons, ds, p)
}

predicate ValidLockHoldersAndGranters(cons:Constants, ds:DistrSys) 
    requires cons.WF() && ds.WF(cons)
{
    && (forall sidx | cons.ValidServerIdx(sidx) && ds.servers[sidx].resource.Held?
        :: ds.servers[sidx].resource.client in cons.client_ids)
    && (forall cidx | cons.ValidClientIdx(cidx) && ds.clients[cidx].state.Working?
        :: ds.clients[cidx].state.sid in cons.server_ids)
}

predicate PacketIsValid(cons:Constants, ds:DistrSys, p:Packet) 
    requires cons.WF() && ds.WF(cons)
{
    match p.msg {
        case Request(_) => ClientToServerPkt(cons, p)
        case Release(_) => ClientToServerPkt(cons, p)
        case Grant(_) => ServerToClientPkt(cons, p)
        case Reject(_) => ServerToClientPkt(cons, p)
    }
}

/* If a server s has granted to client c, then c in s.epoch_map, 
   and s.epoch_map[c] >= grant_msg.epoch */
predicate Granted_Implies_ClientEpochSeen(cons:Constants, ds:DistrSys) 
    requires cons.WF() && ds.WF(cons)
    requires ValidPackets(cons, ds)
{
    forall p | IsGrantPacket(ds, p) :: 
    && p.dst in ds.servers[p.src.idx].epoch_map
    && ds.servers[p.src.idx].epoch_map[p.dst] >= p.msg.e
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

/* For each client c, having a Release of c.epoch implies that client is in Idle state */
predicate ClientRelease_Implies_Idle(cons:Constants, ds:DistrSys) 
    requires cons.WF() && ds.WF(cons)
    requires ValidPackets(cons, ds)
{
    forall p | IsReleasePacket(ds, p) :: 
    p.msg.e == ds.clients[p.src.idx].epoch ==> ds.clients[p.src.idx].state == Idle
}

/* For each valid Grant packet, no matching release implies server is locked */
predicate NoMatchingRelease_Implies_ServerLocked(cons:Constants, ds:DistrSys) 
    requires cons.WF() && ds.WF(cons)
    requires ValidPackets(cons, ds)
    requires Granted_Implies_ClientEpochSeen(cons, ds)
{
    forall grant_p:Packet | 
        && IsGrantPacket(ds, grant_p)
        && GetMatchingRelease(grant_p) !in ds.network.sentPackets
    :: ds.servers[grant_p.src.idx].resource == Held(grant_p.dst)
}

/* Server locked implies Grant message in network */
predicate ServerLocked_Implies_Granted(cons:Constants, ds:DistrSys) 
    requires cons.WF() && ds.WF(cons)
{
    forall sidx | 
        && cons.ValidServerIdx(sidx) 
        && ds.servers[sidx].resource.Held?
    :: var s := ds.servers[sidx];
    && s.resource.client in s.epoch_map
    && GetLatestGrant(s) in ds.network.sentPackets
}

/* Server locked implies at most one non-matched Grant */
predicate ServerLocked_Implies_AtMostOneNonMatchedGrant(cons:Constants, ds:DistrSys) 
    requires cons.WF() && ds.WF(cons)
    requires ServerLocked_Implies_Granted(cons, ds)
{
    forall sidx | 
        && cons.ValidServerIdx(sidx) 
        && ds.servers[sidx].resource.Held?
    :: ServerHasAtMostOneNonMatchedGrant(cons, ds, sidx)
}

/* A server that is locked can have at most one non-matched grant */
predicate ServerHasAtMostOneNonMatchedGrant(cons:Constants, ds:DistrSys, sidx:int)
    requires cons.WF() && ds.WF(cons)
    requires cons.ValidServerIdx(sidx) 
    requires ds.servers[sidx].resource.Held?
    requires ds.servers[sidx].resource.client in ds.servers[sidx].epoch_map
{
    var s := ds.servers[sidx];
    var possibly_unpaired_grant := GetLatestGrant(s);
    forall p | IsGrantPacket(ds, p) && p.src == s.id 
    :: GetMatchingRelease(p) !in ds.network.sentPackets ==> p == possibly_unpaired_grant
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

predicate IsReleasePacket(ds:DistrSys, p:Packet) {
    p.msg.Release? && p in ds.network.sentPackets
}

/* Returns the corresponding Release packet for a Grant */
function {:opaque} GetMatchingRelease(p:Packet) : (r:Packet)
    requires p.msg.Grant?
    ensures r == Packet(p.dst, p.src, Release(p.msg.e))
{
    Packet(p.dst, p.src, Release(p.msg.e))
}

/* Returns the latest Grant message of a locked server */
function {:opaque} GetLatestGrant(s:Server) : (r:Packet)
    requires s.resource.Held?
    requires s.resource.client in s.epoch_map
{
    Packet(s.id, s.resource.client, Grant(s.epoch_map[s.resource.client]))
}
}