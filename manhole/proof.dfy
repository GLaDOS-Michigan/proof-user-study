include "manhole.dfy"

module Proof {

import opened Manhole

predicate Inv(s:State) {
    && Safety(s)
    && s.w.y >= -s.w.x + 5
    && s.radius == 3
    && s.w.x * s.w.x + s.w.y * s.w.y >= s.radius*s.radius
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
    assert s.w.x * s.w.x + s.w.y * s.w.y >= 3*3;
    assert s'.w.x * s'.w.x + s'.w.y * s'.w.y >= s'.radius*s'.radius;
    assert Safety(s');
}


}