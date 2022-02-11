include "manhole.dfy"

module Proof {

import opened Manhole

predicate Inv(s:State) {
    && Safety(s)
    && s.w.y >= -s.w.x + 5
    && s.w.x >= 0
    && s.radius == 3
}

lemma Inv_Init(s:State) 
    requires Init(s)
    ensures Inv(s)
{}

lemma Inv_Next(s:State, s':State) 
    requires Inv(s)
    requires Next(s, s')
    ensures Inv(s')
{
    assert s'.radius == s.radius == 3;
    assert s'.w.y >= -s'.w.x + 5;
    assert s'.w.x >= 0;

    if s'.w.x == 3 {
        assert s'.w.y >= 2;
        assert Safety(s');

    }

    assert Safety(s');
}


}