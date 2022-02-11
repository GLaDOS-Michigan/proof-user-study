include "manhole.dfy"

module Proof {

import opened Manhole

predicate Inv(s:State) {
    && Safety(s)
}

lemma Inv_Init(s:State) 
    requires Init(s)
    ensures Inv(s)
{}

lemma Inv_Next(s:State, s':State) 
    requires Inv(s)
    requires Next(s, s')
    ensures Inv(s')
{}


}