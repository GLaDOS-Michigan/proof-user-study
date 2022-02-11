include "manhole.dfy"

module Proof {

import opened Manhole

predicate Inv(s:State) {
    && Safety(s)
}

lemma SafetyProof(s:State, s':State) {

}






}