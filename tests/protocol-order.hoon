=/  m  (strand ,vase)
=/  plugin=plugin  [%test 'Test' '1' 'author' ~nec 'desc' 'https://example.com/test' ~[%bar] ~ ~2026.10.1]
=/  body=statement  [%omart-signed-v1 ~nec 0 1 %test 100 2 `plugin]
=/  a=signed  [body 0 0x0]
=/  b  a(revision.body 101)
=/  gone  a(content.body ~)
~|  %revision-order
?>  (newer b a)
?<  (newer a b)
?<  (newer a a)
~|  %same-revision-withdrawal-wins
?>  (newer gone a)
?<  (newer a gone)
~|  %newer-publication-can-restore
?>  (newer b gone)
~|  %key-epoch-precedes-clock
?>  (newer a(life.body 2, revision.body 1) b)
?>  (newer a(era.body 1, revision.body 1) b)
~|  %equivocation-converges
=/  other  a(content.body `plugin(name 'Other'))
?>  !=((newer a other) (newer other a))
~|  %relay-budget
?>  (relayable [a 1 ~bus &])
?<  (relayable [a 2 ~bus &])
?<  (relayable [a 0 ~nec |])
?>  (relayable [gone(hops.body 0) 0 ~nec &])
~|  %identity-bound-content
?>  (shape a)
?<  (shape a(content.body `plugin(ship ~bus)))
?<  (shape a(content.body `plugin(id %other)))
(pure:m !>(%ok))
