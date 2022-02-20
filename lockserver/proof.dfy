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
    Inv_Next_Trivialities(cons, ds, ds');
    assert ClientWorking_Implies_NoMatchingRelease(cons, ds');
    assert ClientRelease_Implies_Idle(cons, ds');
    assert NoMatchingRelease_Implies_ServerLocked(cons, ds');

    Inv_Next_ServerLocked_Implies_Granted(cons, ds, ds');
    assert ServerLocked_Implies_Granted(cons, ds');

    assume false;
    assert ServerLocked_Implies_AtMostOneNonMatchedGrant(cons, ds');
    assert Safety(cons, ds');
}

lemma Inv_Next_Trivialities(cons:Constants, ds:DistrSys, ds':DistrSys) 
    requires Trivialities(cons, ds)
    requires Next(cons, ds, ds')
    ensures Trivialities(cons, ds')
{}

lemma Inv_Next_ServerLocked_Implies_Granted(cons:Constants, ds:DistrSys, ds':DistrSys) 
    requires cons.WF()
    requires ds.WF(cons) && ds'.WF(cons)
    requires Next(cons, ds, ds')
    requires ServerLocked_Implies_Granted(cons, ds);
    ensures ServerLocked_Implies_Granted(cons, ds')
{}

/***************************************** Utils *****************************************/
lemma lemma_NewPacketsComeFromSendIo(cons:Constants, ds:DistrSys, ds':DistrSys, p:Packet) 
    requires cons.WF()
    requires ds.WF(cons) && ds'.WF(cons)
    requires Next(cons, ds, ds')
    requires p !in ds.network.sentPackets && p in ds'.network.sentPackets
    ensures ds.network.nextStep.sendIo == Some(p)
{}
}
