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
    {}
    assert ValidPackets(cons, ds');

    assume false;
    assert ValidLockHoldersAndGranters(cons, ds');
    assert Granted_Implies_ClientEpochSeen(cons, ds');
}

/***************************************** Utils *****************************************/
lemma lemma_NewPacketsComeFromSendIo(cons:Constants, ds:DistrSys, ds':DistrSys, p:Packet) 
    requires cons.WF()
    requires ds.WF(cons) && ds'.WF(cons)
    requires Next(cons, ds, ds')
    requires p !in ds.network.sentPackets && p in ds'.network.sentPackets
    ensures ds.network.nextStep.sendIo == Some(p)
{}
}
