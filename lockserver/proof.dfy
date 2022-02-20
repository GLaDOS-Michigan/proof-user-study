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

lemma Inv_Init(cons:Constants, ds:DistrSys) 
    requires Init(cons, ds)
    ensures Inv(cons, ds)
{}

lemma Inv_Next(cons:Constants, ds:DistrSys, ds':DistrSys) 
    requires Inv(cons, ds)
    requires Next(cons, ds, ds')
    ensures Inv(cons, ds')
{
    // TODO
    lemma_Inv_Next_Trivialities(cons, ds, ds');
    assume false;
}

lemma lemma_Inv_Next_Trivialities(cons:Constants, ds:DistrSys, ds':DistrSys) 
    requires Trivialities(cons, ds)
    requires Next(cons, ds, ds')
    ensures Trivialities(cons, ds')
{
    assert ds'.WF(cons);

    // First prove ValidPackets(cons, ds')
    forall p | p in ds'.network.sentPackets
    ensures PacketIsValid(cons, ds', p) 
    {
        if p !in ds.network.sentPackets {
            var actor, recvIo, sendIo :| NextOneAgent(cons, ds, ds', actor, recvIo, sendIo);
            if actor.agt == C {
                var c, c' := ds.clients[actor.idx], ds'.clients[actor.idx];
                match c.state {
                    case Idle => {
                        assert |c.consts.servers| > 0;
                        var dst :| dst in c.consts.servers && sendIo==Some(Packet(c.consts.id, dst, Request(c'.epoch)));
                        assert ClientToServerPkt(cons, p);
                    }
                    case Pending =>
                        assume false;
                    case Working(sid) =>
                        assume false;
                }
            } else {
                assume false;
            }
        }
        assert PacketIsValid(cons, ds', p);
    }
    assert ValidPackets(cons, ds');

    assume false;
    assert Granted_Implies_ClientEpochSeen(cons, ds');
}
}
