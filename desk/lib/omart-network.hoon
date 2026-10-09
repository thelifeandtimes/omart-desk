::  Pals-discovered subscriptions. Snapshots are paged so large catalogs do not
::  overflow Gall's subscription queue. Every record retains origin signatures.
/-  *omart
/+  pals, op=omart-protocol
|_  [=bowl:gall cfg=gossip-cfg cache=(map listing-key entry)]
+*  pal  ~(. pals bowl)
+$  card  card:agent:gall
++  wanted
  ^-  (set ship)
  ?-  hear.cfg
    %anybody  (~(uni in leeches:pal) (targets:pal ~.))
    %targets  (targets:pal ~.)
    %mutuals  (mutuals:pal ~.)
  ==
++  allowed
  |=  who=ship
  ^-  ?
  ?-  tell.cfg
    %anybody  &
    %targets  (~(has in (targets:pal ~.)) who)
    %mutuals  (~(has in (mutuals:pal ~.)) who)
  ==
++  watch
  |=  who=ship
  ^-  card
  [%pass /omart/peer/(scot %p who) %agent [who dap.bowl] %watch /omart/v2/(scot %p our.bowl)]
++  request
  |=  [who=ship cursor=(unit listing-key)]
  ^-  card
  [%pass /omart/page/(scot %p who) %agent [who dap.bowl] %poke %omart-page !>(cursor)]
++  pals-watches
  ^-  (list card)
  %+  murn  `(list term)`~[%targets %leeches]
  |=  label=term
  ^-  (unit card)
  =/  wire  /omart/pals/[label]
  ?:  (~(has by wex.bowl) [wire our.bowl %pals])  ~
  `[%pass wire %agent [our.bowl %pals] %watch /[label]]
++  reconcile
  |=  refresh=?
  ^-  (list card)
  =/  desired  (~(del in wanted) our.bowl)
  =/  old=(list card)
    %+  murn  ~(tap by wex.bowl)
    |=  [[=wire =ship =term] [acked=? =path]]
    ^-  (unit card)
    ?.  |(?=([%omart %peer @ ~] wire) ?=([%~.~ %gossip *] wire))  ~
    ?:  &(?=([%omart %peer @ ~] wire) (~(has in desired) ship))  ~
    `[%pass wire %agent [ship term] %leave ~]
  =/  kicks=(list card)
    %+  murn  ~(val by sup.bowl)
    |=  [who=ship path=path]
    ^-  (unit card)
    ?:  =(/~/gossip/gossip path)  `[%give %kick [path]~ `who]
    ?.  ?=([%omart %v2 @ ~] path)  ~
    ?:  (allowed who)  ~
    `[%give %kick [path]~ `who]
  ;:  weld  old  kicks  pals-watches
    %+  murn  ~(tap in desired)
    |=  who=ship
    ^-  (unit card)
    =/  existing  (~(get by wex.bowl) [/omart/peer/(scot %p who) who dap.bowl])
    ?~  existing  `(watch who)
    ?.  &(refresh -.u.existing)  ~
    `(request who ~)
  ==
++  wire-entry
  |=  e=entry
  ^-  envelope
  [data.e ?:(?=(~ content.body.data.e) 0 +(distance.e))]
++  page
  |=  cursor=(unit listing-key)
  ^-  sync-page
  =/  keys
    %+  sort
      %+  murn  ~(tap by cache)
      |=  [key=listing-key val=entry]
      ^-  (unit listing-key)
      ?.  (relayable:op val)  ~
      ?^  cursor
        ?.  &(!=(u.cursor key) (gor u.cursor key))  ~
        `key
      `key
    gor
  =/  chosen  (scag 8 keys)
  :+  %page  (turn chosen |=(k=listing-key (wire-entry (~(got by cache) k))))
  :-  cursor
  ?:  (lte (lent keys) 8)  ~
  `(rear chosen)
++  broadcast
  |=  [e=entry except=ship]
  ^-  (list card)
  ?.  (relayable:op e)  ~
  =/  paths=(list path)
    %+  murn  ~(val by sup.bowl)
    |=  [who=ship path=path]
    ^-  (unit ^path)
    ?.  &(?=([%omart %v2 @ ~] path) (allowed who))  ~
    ?:  |(=(who except) =(who origin.body.data.e))  ~
    `path
  ?~  paths  ~
  [%give %fact paths %omart-sync !>(`sync-page`[%live [(wire-entry e)]~ ~ ~])]~
--
