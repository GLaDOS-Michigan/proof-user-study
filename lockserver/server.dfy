include "types.dfy"

module Server {
import opened Types


datatype Server = Server(
    id:Id,                  
    resource_available:bool,    // is this server free to grant requests?
    epoch_map:map<Id, Epoch>    // maps each client to the latest epoch seen from that client
)

predicate ServerInit(s:Server, id:Id) {
    && s.id == id
    && s.resource_available
    && s.epoch_map == map[]
}



}