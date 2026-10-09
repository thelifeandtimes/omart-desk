::  Exercise on-load against synthetic old states, without installing/downgrading
::  an agent or delivering any of its returned network cards.
=/  m  (strand ,vase)
;<  live=bowl:spider  bind:m  get-bowl
;<  built=vase  bind:m  (build-file-hard [[our.live %omart %da now.live] /app/omart/hoon])
=/  app  !<(agent:gall built)
=/  bowl  *bowl:gall
=.  bowl  bowl(our our.live, src our.live, dap %omart, now now.live, byk [our.live %omart %da now.live])
=/  own=plugin  [%migration-local 'Local' '1' 'author' our.live 'desc' 'https://example.com/local' ~[%bar] ~ now.live]
=/  remote  own(id %migration-remote, ship ~bus)
=/  listings=(map id plugin)  (my ~[[id.own own] [id.remote remote]])
=/  cfg=gossip-cfg  [2 %targets %targets &]
=/  withdrawn=(map id ship)  (my ~[[%migration-gone our.live] [%remote-gone ~bus]])
=/  old  !>([%1 listings withdrawn cfg])
=/  wrapped  !>([[%gossip ~] [%1 listings withdrawn cfg]])
=/  first  (on-load:~(. app bowl) wrapped)
=/  ag  ~(. +.first bowl)
=/  local-result  (on-peek:ag /x/record/~nec/migration-local)
=/  local  (need !<((unit entry) q:(need (need local-result))))
~|  %upgrade-signs-own-content-and-preserves-budget
?>  =(our.live origin.body.data.local)
?>  =(2 hops.body.data.local)
?>  =(`& (authenticate our.live now.live data.local))
=/  gone-result  (on-peek:ag /x/record/~nec/migration-gone)
=/  gone  (need !<((unit entry) q:(need (need gone-result))))
~|  %upgrade-signs-own-withdrawal
?>  ?=(~ content.body.data.gone)
?>  =(`& (authenticate our.live now.live data.gone))
~|  %never-sign-other-publishers-legacy-content
=/  remote-result  (on-peek:ag /x/record/~bus/migration-remote)
?>  =(~ !<((unit entry) q:(need (need remote-result))))
=/  visible  (on-peek:ag /x/listings)
?>  =(2 (lent !<((list plugin) q:(need (need visible)))))
~|  %upgrade-preserves-settings-but-disables-proxy
=/  config  (on-peek:ag /x/config)
?>  =([2 %targets %targets |] !<(gossip-cfg q:(need (need config))))
~|  %new-state-roundtrip-preserves-records-and-tombstones
=/  saved  on-save:ag
=/  second  (on-load:~(. app bowl) saved)
=/  again  ~(. +.second bowl)
?>  =(local-result (on-peek:again /x/record/~nec/migration-local))
?>  =(gone-result (on-peek:again /x/record/~nec/migration-gone))
~|  %unwrapped-state-one-also-upgrades
=/  unwrapped  (on-load:~(. app bowl) old)
?>  =(local-result (on-peek:~(. +.unwrapped bowl) /x/record/~nec/migration-local))
~|  %state-zero-upgrades
=/  old-zero  !>([%0 listings (silt ~[%migration-gone])])
=/  zero  (on-load:~(. app bowl) old-zero)
=/  zero-config  (on-peek:~(. +.zero bowl) /x/config)
?>  =([1 %targets %targets |] !<(gossip-cfg q:(need (need zero-config))))
~|  %legacy-network-watch-is-rejected
?>  =(~ (mole |.((on-watch:ag /~/gossip/gossip))))
~|  %unsigned-gossip-is-rejected
?>  =(~ (mole |.((on-poke:ag %gossip-rumor !>(~)))))
~|  %outsider-cannot-inject-even-a-valid-signed-record
=/  outsider  ~(. +.first bowl(src ~wex))
=/  packet=sync-page  [%live [[data.local 2]]~ ~ ~]
?>  =(~ (mole |.((on-poke:outsider %omart-sync !>(packet)))))
(pure:m !>(%ok))
