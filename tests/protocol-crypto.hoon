::  Evaluated inside the development ~nec with omart-protocol as a dependency.
::  All generated keys below are deterministic test keys, never production keys.
=/  m  (strand ,vase)
;<  =bowl:spider  bind:m  get-bowl
=/  b  (pit:nu:cric:crypto 512 111 %b ~)
=/  c  (pit:nu:cric:crypto 512 222 %c ~)
=/  bb=statement  [%omart-signed-v1 `@p`fig:ex:b 0 1 %test 100 2 ~]
=/  cb=statement  [%omart-signed-v1 `@p`fig:ex:c 0 1 %test 100 2 ~]
=/  bs=signed  [bb pub:ex:b (sigh:as:b (jam bb))]
=/  cs=signed  [cb pub:ex:c (sigh:as:c (jam cb))]
~|  %both-crypto-suites-and-comet-identities
?>  &((autograph bs) (autograph cs))
?>  =(`& (authenticate our.bowl now.bowl bs))
?>  =(`& (authenticate our.bowl now.bowl cs))
~|  %comet-key-substitution
?<  (autograph bs(public-key pub:ex:c))
~|  %valid-signature-wrong-identity
=/  wrong  cb(origin `@p`fig:ex:b)
=/  forged=signed  [wrong pub:ex:c (sigh:as:c (jam wrong))]
?>  (autograph forged)
?>  =(`| (authenticate our.bowl now.bowl forged))
~|  %galaxy-key-substitution
=/  wrong  cb(origin ~nec)
=/  forged=signed  [wrong pub:ex:c (sigh:as:c (jam wrong))]
?>  (autograph forged)
?>  =(`| (authenticate our.bowl now.bowl forged))
~|  %bad-key-and-signature-fail-closed
?<  (autograph bs(public-key 0))
?<  (autograph bs(signature 0x0))
~|  %local-signing-and-jael-binding
=/  local  (seal our.bowl now.bowl %test 100 2 ~)
?>  =(`& (authenticate our.bowl now.bowl local))
~|  %unknown-future-epoch-waits-for-jael
=/  n  (pit:nu:cric:crypto 512 ~nec %b ~)
=/  future  body.local(life 2)
=/  future-s=signed  [future pub:ex:n (sigh:as:n (jam future))]
?>  =(~ (authenticate our.bowl now.bowl future-s))
=/  future  body.local(era 1)
=/  future-s=signed  [future pub:ex:n (sigh:as:n (jam future))]
?>  =(~ (authenticate our.bowl now.bowl future-s))
~|  %signed-domain-and-content-cannot-change
?<  (autograph local(revision.body 101))
?<  (autograph local(id.body %other))
?<  (autograph local(hops.body 3))
~|  %bounded-input-shape
?<  (shape local(hops.body 4))
?<  (shape local(revision.body 0))
?<  (shape local(life.body 0))
?<  (shape local(id.body `@tas`'bad.id'))
(pure:m !>(%ok))
