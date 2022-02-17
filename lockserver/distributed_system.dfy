include "types.dfy"
include "network.dfy"
include "client.dfy"
include "server.dfy"
include "generic_definitions.dfy"

module System {
import opened Types
import opened Network
import opened Client_Agent
import opened Server_Agent
import opened Generic_Defs

datatype Constants = Constants(client_ids:seq<Id>, server_ids:seq<Id>) {
    predicate WF() {
        && |client_ids| >= 1
        && |server_ids| >= 1
        && ValidTypes()
        && ValidIds()
        && UniqueIds()
    }

    predicate ValidServerIdx(i:int) {
        0<=i<|server_ids|
    }

    predicate ValidClientIdx(i:int) {
        0<=i<|client_ids|
    }

    predicate ValidServerId(id:Id) {
        id.agt == S && ValidServerIdx(id.idx)
    }

    predicate ValidClientId(id:Id) {
        id.agt == C && ValidClientIdx(id.idx)
    }

    predicate ValidTypes() {
        && (forall l | l in client_ids :: l.agt.C?)
        && (forall l | l in server_ids :: l.agt.S?)
    }

    predicate UniqueIds() {
        && seqIsUnique(client_ids)
        && seqIsUnique(server_ids)
    }

    predicate ValidIds() {
        && (forall i | ValidClientIdx(i) :: client_ids[i].idx == i)
        && (forall i | ValidServerIdx(i) :: server_ids[i].idx == i)
    }
}

datatype DistrSys = DistrSys(
    network: Environment,
    clients: seq<Client>,
    servers: seq<Server>
) {
    predicate WF(c: Constants)
        requires c.WF()
    {
        && |clients| == |c.client_ids|
        && |servers| == |c.server_ids|
        && (forall i | c.ValidClientIdx(i) :: clients[i].consts.id == c.client_ids[i])
        && (forall i | c.ValidServerIdx(i) :: servers[i].id == c.server_ids[i])
        && (forall i | c.ValidClientIdx(i) :: clients[i].consts.servers == c.server_ids)
    }
}

/*****************************************************************************************
*                                        DS Init                                         *
*****************************************************************************************/
predicate Init(c:Constants, ds:DistrSys) 
{
    && c.WF()
    && ds.WF(c)
    && EnvironmentInit(ds.network)
    && (forall i | c.ValidClientIdx(i) :: ClientInit(ds.clients[i], c.client_ids[i], c.server_ids))
    && (forall i | c.ValidServerIdx(i) :: ServerInit(ds.servers[i], c.server_ids[i]))
}


/*****************************************************************************************
*                                        DS Next                                         *
*****************************************************************************************/

predicate Next(c:Constants, ds:DistrSys, ds':DistrSys) {
    && c.WF()
    && ds.WF(c)
    && ds'.WF(c)
    && exists actor, recvIo, sendIo :: NextOneAgent(c, ds, ds', actor, recvIo, sendIo)
}

predicate NextOneAgent(c:Constants, ds:DistrSys, ds':DistrSys, actor:Id, recvIo:IoOpt, sendIo:IoOpt)
    requires c.WF() && ds.WF(c) && ds'.WF(c)
{
    && ValidActor(c, actor)
    && ds.network.nextStep == IoStep(actor, recvIo, sendIo)
    && EnvironmentNext(ds.network, ds'.network)
    && match actor.agt {
        case C => 
            && ds'.servers == ds.servers
            && ds'.clients == ds.clients[actor.idx := ds'.clients[actor.idx]]
            && ClientNext(ds.clients[actor.idx], ds'.clients[actor.idx], recvIo, sendIo)
        case S => 
            && ds'.clients == ds.clients
            && ds'.servers == ds.servers[actor.idx := ds'.servers[actor.idx]]
            && ServerNext(ds.servers[actor.idx], ds'.servers[actor.idx], recvIo, sendIo)
    }
}

predicate ValidActor(c:Constants, actor:Id) 
    requires c.WF()
{
     match actor.agt {
        case C => c.ValidClientIdx(actor.idx)
        case S => c.ValidServerIdx(actor.idx)
    }
}
}