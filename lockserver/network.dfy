include "types.dfy"

module Network {
import opened Types

datatype IoOpt = None | Some(p:Packet)

datatype EnvStep = 
    IoStep(actor:Id, recvIo:IoOpt, sendIo:IoOpt)

datatype Environment = Env(
        sentPackets:set<Packet>,
        nextStep:EnvStep
    )

predicate EnvironmentInit(e:Environment) {
    e.sentPackets == {}
}

predicate ValidIoStep(iostep:EnvStep) 
    requires iostep.IoStep?
{
    && (iostep.recvIo.Some? ==> iostep.recvIo.p.dst == iostep.actor)
    && (iostep.sendIo.Some? ==> iostep.sendIo.p.src == iostep.actor)
}


predicate EnvironmentNext(e:Environment, e':Environment)
{
    match e.nextStep {
        case IoStep(actor, recvIo, sendIo) => 
            && ValidIoStep(e.nextStep)
            && e'.sentPackets == e.sentPackets + (if sendIo.Some? then {sendIo.p} else {})
            && recvIo.Some? ==> recvIo.p in e.sentPackets
    }
}

}