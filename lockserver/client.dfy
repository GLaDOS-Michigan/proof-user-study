include "types.dfy"
include "network.dfy"

module Client {
import opened Types
import opened Network

datatype ClientState = Idle | Pending | Working(sid:Id)  // sid is the id of the server I am using

datatype ClientConts = CC(id:Id, servers:set<Id>)

datatype Client = Client(
    consts:ClientConts,                  
    state:ClientState,    
    epoch:Epoch    
)

/* Client initial state */
predicate ClientInit(c:Client, my_id:Id, servers:set<Id>) {
    && c.consts == CC(my_id, servers)
    && c.state == Idle
    && c.epoch == 0
}

/* Client next state */
predicate ClientNext(c:Client, c':Client, recvIo:IoOpt, sendIo:IoOpt) {
    && c'.consts == c.consts
    && match c.state {
        case Idle => ClientSendRequest(c, c', recvIo, sendIo)
        case Pending => recvIo.None? && ClientStutter(c, c', sendIo)
        case Working(sid) => ClientRelease(c, c', recvIo, sendIo)
    }
}

/* Client sends a request to some non-determined server */
predicate ClientSendRequest(c:Client, c':Client, recvIo:IoOpt, sendIo:IoOpt) 
    requires c.state == Idle
{
    && recvIo.None?
    && if |c.consts.servers| > 0 then
        var dst :| dst in c.consts.servers;
        && c'.state == Pending
        && c'.epoch == c.epoch + 1
        && sendIo == Some(Packet(c.consts.id, dst, Request(c'.epoch)))
    else 
        ClientStutter(c, c', sendIo)
}

/* Client is waiting for server to Grant or Reject a pending request */
predicate ClientPending(c:Client, c':Client, recvIo:IoOpt, sendIo:IoOpt)
    requires c.state == Pending
{
    && recvIo.Some?
    && match recvIo.p.msg {
        case Grant(e) => ClientPending_Granted(c, c', recvIo.p, sendIo)
        case Reject(e) => ClientPending_Rejected(c, c', recvIo.p, sendIo)
        case _ => ClientStutter(c, c', sendIo)
    }
}

predicate ClientPending_Granted(c:Client, c':Client, p:Packet, sendIo:IoOpt)
    requires c.state == Pending
    requires p.msg.Grant?
{
    var e := p.msg.e;
    if e != c.epoch then 
        ClientStutter(c, c', sendIo)    // received stale message
    else
        && c'.epoch == c.epoch
        && c'.state == Working(p.src)
        && sendIo == None
}

predicate ClientPending_Rejected(c:Client, c':Client, p:Packet, sendIo:IoOpt)
    requires c.state == Pending
    requires p.msg.Reject?
{
    var e := p.msg.e;
    if e != c.epoch then 
        ClientStutter(c, c', sendIo)    // received stale message
    else
        && c'.epoch == c.epoch
        && c'.state == Idle
        && sendIo == None
}

/* Client releases the held resource */
predicate ClientRelease(c:Client, c':Client, recvIo:IoOpt, sendIo:IoOpt) 
    requires c.state.Working?
{
    && recvIo.None?
    && c'.state == Idle
    && c'.epoch == c.epoch
    && sendIo == Some(Packet(c.consts.id, c.state.sid, Release(c.epoch)))
}

/* Client taking a stutter step */
predicate ClientStutter(c:Client, c':Client, sendIo:IoOpt) {
    && c' == c
    && sendIo == None
}
}