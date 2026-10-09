::  Origin authentication and deterministic ordering. No network side effects.
/-  *omart
|%
++  key
  |=(s=signed `listing-key`[origin.body.s id.body.s])
++  rank
  |=(s=signed [era.body.s life.body.s revision.body.s])
++  newer
  |=  [a=signed b=signed]
  ^-  ?
  ?:  !=(era.body.a era.body.b)  (gth era.body.a era.body.b)
  ?:  !=(life.body.a life.body.b)  (gth life.body.a life.body.b)
  ?:  !=(revision.body.a revision.body.b)
    (gth revision.body.a revision.body.b)
  ::  An origin equivocating at one revision converges deterministically;
  ::  at equal revision, a withdrawal always wins over a publication.
  ?:  !=(?=(~ content.body.a) ?=(~ content.body.b))
    ?=(~ content.body.a)
  &(!=(body.a body.b) (gor body.a body.b))
++  shape
  |=  s=signed
  ^-  ?
  ?.  &((lte (met 3 (jam s)) 32.768) (lte (met 0 signature.s) 512))  |
  ?.  &((gth revision.body.s 0) (lte (met 0 revision.body.s) 128))  |
  ?.  &((lte hops.body.s 3) (gth life.body.s 0) (lte (met 0 origin.body.s) 128))  |
  ?.  &(((sane %tas) id.body.s) (lte (met 3 id.body.s) 128))  |
  ?~  content.body.s  &
  =/  p  u.content.body.s
  ?&  =(id.p id.body.s)
      =(ship.p origin.body.s)
      (gth (met 3 name.p) 0)
      (lte (met 3 name.p) 256)
      (gth (met 3 description.p) 0)
      (lte (met 3 description.p) 4.096)
      (lte (met 3 git.p) 512)
      |(=("https://" (scag 8 (trip git.p))) =("http://" (scag 7 (trip git.p))))
      =(~ (find " " (trip git.p)))
      =(~ (find "\0a" (trip git.p)))
      =(~ (find "\0d" (trip git.p)))
      (lte (met 3 author.p) 128)
      (lte (met 3 version.p) 32)
      !=(~ kinds.p)
      (lte (lent kinds.p) 6)
      (lte (lent tags.p) 16)
      (levy tags.p |=(t=term &(((sane %tas) t) (lte (met 3 t) 128))))
  ==
++  autograph
  |=  s=signed
  ^-  ?
  =/  checked  (mole |.((safe:as:(com:nu:cric:crypto public-key.s) signature.s (jam body.s))))
  ?~  checked  |
  u.checked
++  authenticate
  |=  [our=ship now=@da s=signed]
  ^-  (unit ?)
  ?.  &((shape s) (autograph s))  `|
  ::  Comet identities are the fingerprint of their own networking key.
  ?:  =(%pawn (clan:title origin.body.s))
    :-  ~
    ?&  =(life.body.s 1)
        =(era.body.s 0)
        =(origin.body.s fig:ex:(com:nu:cric:crypto public-key.s))
    ==
  =/  ego  (scot %p our)
  =/  wen  (scot %da now)
  =/  who  (scot %p origin.body.s)
  =/  rift  .^((unit @ud) %j /[ego]/ryft/[wen]/[who])
  ?~  rift  ~
  ?:  (lth era.body.s u.rift)  `|
  ?:  (gth era.body.s u.rift)  ~
  ::  Only the currently authorized key may introduce a statement. Historical
  ::  keys remain in Jael after a breach, so accepting them with a new claimed
  ::  era would let a former owner impersonate the current identity.
  =/  current  .^((unit @ud) %j /[ego]/lyfe/[wen]/[who])
  ?~  current  ~
  ?:  (lth life.body.s u.current)  `|
  ?:  (gth life.body.s u.current)  ~
  =/  deed
    %-  mole
    |.  .^([life=@ud pub=pass proof=(unit @)] %j /[ego]/deed/[wen]/[who]/(scot %ud life.body.s))
  ?~  deed  ~
  `&(=(life.u.deed life.body.s) =(pub.u.deed public-key.s))
++  seal
  |=  [our=ship now=@da id=id revision=@ud hops=@ud content=(unit plugin)]
  ^-  signed
  =/  ego  (scot %p our)
  =/  wen  (scot %da now)
  =/  life  .^(@ud %j /[ego]/life/[wen]/[ego])
  =/  era  ?:(=(%pawn (clan:title our)) 0 .^(@ud %j /[ego]/rift/[wen]/[ego]))
  =/  sec  .^(ring %j /[ego]/vein/[wen]/(scot %ud life))
  =/  cic  (nol:nu:cric:crypto sec)
  =/  body=statement  [%omart-signed-v1 our era life id revision hops content]
  [body pub:ex:cic (sigh:as:cic (jam body))]
++  relayable
  |=  e=entry
  ^-  ?
  ?&  trusted.e
      |(?=(~ content.body.data.e) (lth distance.e hops.body.data.e))
  ==
--
