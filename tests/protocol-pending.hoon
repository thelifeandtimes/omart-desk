::  Isolated state-machine test: cards are not delivered to any agent or vane.
=/  m  (strand ,vase)
;<  live=bowl:spider  bind:m  get-bowl
;<  built=vase  bind:m  (build-file-hard [[our.live %omart %da now.live] /app/omart/hoon])
=/  app  !<(agent:gall built)
=/  bowl  *bowl:gall
=.  bowl  bowl(our our.live, src ~bus, dap %omart, now now.live, byk [our.live %omart %da now.live])
=/  started  on-init:~(. app bowl)
=/  b  (pit:nu:cric:crypto 512 ~bus %b ~)
=/  body=statement  [%omart-signed-v1 ~bus 0 2 %future-key 100 2 ~]
=/  data=signed  [body pub:ex:b (sigh:as:b (jam body))]
=/  packet=sync-page  [%live [[data 0]]~ ~ ~]
=/  received  (on-poke:~(. +.started bowl) %omart-sync !>(packet))
=/  pending-cage  (on-peek:~(. +.received bowl) /x/pending)
=/  pending  !<((list [via=ship received=@da env=envelope]) q:(need (need pending-cage)))
~|  %unknown-key-is-queued-without-trust
?>  =(1 (lent pending))
?>  ?=(^ pending)
?>  =(now.live received.i.pending)
=/  cached  (on-peek:~(. +.received bowl) /x/record/~bus/future-key)
?>  =(~ !<((unit entry) q:(need (need cached))))
~|  %unknown-key-duplicates-do-not-grow-queue
=/  duplicate  (on-poke:~(. +.received bowl) %omart-sync !>(packet))
?>  =(pending-cage (on-peek:~(. +.duplicate bowl) /x/pending))
::  Age the isolated saved queue. Keep bowl.now at the real event time so
::  Jael scries never ask Arvo for a future state.
=/  snapshot
  !<  $:  %2
          cfg=gossip-cfg
          clock=@ud
          cache=(map listing-key entry)
          legacy=(map listing-key plugin)
          pending=(list [via=ship received=@da env=envelope])
          tracked=(set ship)
          pagers=(map ship (unit listing-key))
          next=@da
      ==
  on-save:~(. +.received bowl)
=.  pending.snapshot  (turn pending.snapshot |=(p=[via=ship received=@da env=envelope] p(received (sub received.p ~m10))))
=/  aged  (on-load:~(. app bowl) !>(snapshot))
~|  %retry-preserves-original-expiry
=/  tick  (add now.live ~m5)
=/  retried  (on-arvo:~(. +.aged bowl) [/omart/timer/(scot %da tick) [%behn %wake ~]])
=/  pending-cage  (on-peek:~(. +.retried bowl) /x/pending)
?>  =(pending.snapshot !<((list [ship @da envelope]) q:(need (need pending-cage))))
~|  %unknown-key-record-expires
=.  pending.snapshot  (turn pending.snapshot |=(p=[via=ship received=@da env=envelope] p(received (sub received.p ~m21))))
=/  aged  (on-load:~(. app bowl) !>(snapshot))
=/  expired  (on-arvo:~(. +.aged bowl) [/omart/timer/(scot %da tick) [%behn %wake ~]])
=/  pending-cage  (on-peek:~(. +.expired bowl) /x/pending)
?>  =(~ !<((list [ship @da envelope]) q:(need (need pending-cage))))
(pure:m !>(%ok))
