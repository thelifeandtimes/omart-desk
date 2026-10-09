::  omart: omarchy plugin bazaar, gossiped among pals
::
/-  *omart
/+  default-agent, dbug, server, pals, op=omart-protocol, network=omart-network
::
::
|%
+$  state-0
  $:  %0
      listings=(map id plugin)
      retracted=(set id)
  ==
+$  state-1
  $:  %1
      listings=(map id plugin)
      retracted=(map id ship)
      cfg=gossip-cfg
  ==
::  Signed records and tombstones are keyed by publisher as well as listing ID.
+$  state-2
  $:  %2
      cfg=gossip-cfg
      clock=@ud
      cache=(map listing-key entry)
      legacy=(map listing-key plugin)
      pending=(list [via=ship received=@da env=envelope])
      tracked=(set ship)
      pagers=(map ship (unit listing-key))
      next=@da
  ==
+$  card  card:agent:gall
++  default-cfg  `gossip-cfg`[1 %targets %targets |]
++  max-listings  1.024
++  max-name      256
++  max-desc      4.096
++  max-git       512
++  max-author    128
++  max-ver       32
++  max-tags      16
++  json-ok
  |=  jon=json
  ^-  simple-payload:http
  (json-response:gen:server jon)
++  json-err
  |=  [cod=@ud msg=@t]
  ^-  simple-payload:http
  :-  [cod ['content-type' 'application/json']~]
  `(as-octs:mimes:html (en:json:html (pairs:enjs:format [error+s+msg]~)))
++  header
  |=  [key=@t heads=header-list:http]
  ^-  (unit @t)
  =/  want  (cass (trip key))
  |-  ^-  (unit @t)
  ?~  heads  ~
  ?:  =(want (cass (trip key.i.heads)))  `value.i.heads
  $(heads t.heads)
++  csrf-ok
  |=  req=inbound-request:eyre
  ^-  ?
  =/  heads  header-list.request.req
  =/  xom   (header 'x-omart' heads)
  ?~  xom  |
  =/  host  (header 'host' heads)
  ?~  host  &
  =/  origin  (header 'origin' heads)
  ?^  origin
    ?|  =(u.origin (cat 3 'http://' u.host))
        =(u.origin (cat 3 'https://' u.host))
    ==
  =/  ref  (header 'referer' heads)
  ?~  ref  &
  ?|  =((scag (add 7 (met 3 u.host)) (trip u.ref)) (weld "http://" (trip u.host)))
      =((scag (add 8 (met 3 u.host)) (trip u.ref)) (weld "https://" (trip u.host)))
  ==
++  need-user
  |=  [req=inbound-request:eyre loc=@t]
  ^-  (unit simple-payload:http)
  ?.  authenticated.req
    `[307 ['location' loc]~]~
  ?.  (csrf-ok req)
    `(json-err 403 'bad origin')
  ~
++  git-ok
  |=  git=@t
  ^-  ?
  =/  t  (trip git)
  =/  n  (lent t)
  ?&  (gte n 12)
      (lte n max-git)
      ?|  =((scag 8 t) "https://")
          =((scag 7 t) "http://")
      ==
      =(~ (find " " t))
      =(~ (find "\0a" t))
      =(~ (find "\0d" t))
  ==
++  kind-of
  |=  t=@t
  ^-  (unit kind)
  ?+  t  ~
    %bar-widget  `%bar-widget
    %panel       `%panel
    %overlay     `%overlay
    %menu        `%menu
    %service     `%service
    %bar         `%bar
  ==
++  clip
  |=  [t=@t n=@ud]
  ^-  @t
  ?:  (lte (met 3 t) n)  t
  (end [3 n] t)
++  check-plugin
  |=  p=plugin
  ^-  (each plugin @t)
  ?.  ((sane %tas) id.p)  [%| 'listing id must start with a lowercase letter; use lowercase letters, digits and hyphens']
  ?:  (gth (met 3 id.p) 128)  [%| 'listing id is too long']
  ?.  (git-ok git.p)      [%| 'git must be an http(s) URL']
  ?:  =(0 (met 3 name.p))  [%| 'name required']
  ?:  =(0 (met 3 description.p))  [%| 'description required']
  ?:  =(~ kinds.p)  [%| 'need a kind']
  ?:  (gth (lent kinds.p) 6)  [%| 'too many kinds']
  ?:  (gth (lent tags.p) max-tags)  [%| 'too many tags']
  ?.  (levy tags.p |=(t=term &(((sane %tas) t) (lte (met 3 t) 128))))
    [%| 'invalid tag']
  :-  %&
  %_  p
    name         (clip name.p max-name)
    description  (clip description.p max-desc)
    git          (clip git.p max-git)
    author       (clip author.p max-author)
    version      (clip version.p max-ver)
  ==
++  plugin-json
  |=  =plugin
  ^-  json
  =,  enjs:format
  %-  pairs
  :~  id+s+id.plugin
      name+s+name.plugin
      version+s+version.plugin
      author+s+author.plugin
      ship+s+(scot %p ship.plugin)
      description+s+description.plugin
      git+s+git.plugin
      kinds+a+(turn kinds.plugin |=(k=kind s+k))
      tags+a+(turn tags.plugin |=(t=term s+t))
      when+s+(scot %da when.plugin)
  ==
++  visible-listings
  |=  [cache=(map listing-key entry) legacy=(map listing-key plugin)]
  ^-  (map listing-key plugin)
  =/  out  legacy
  =/  records  ~(tap by cache)
  |-  ^-  (map listing-key plugin)
  ?~  records  out
  =/  [key=listing-key val=entry]  i.records
  =.  out  (~(del by out) key)
  =?  out  &(trusted.val ?=(^ content.body.data.val))
    (~(put by out) key u.content.body.data.val)
  $(records t.records)
++  listings-json
  |=  [cache=(map listing-key entry) legacy=(map listing-key plugin)]
  ^-  json
  :-  %a
  %+  turn  ~(tap by (visible-listings cache legacy))
  |=  [key=listing-key val=plugin]
  =/  jon  (plugin-json val)
  ?>  ?=(%o -.jon)
  =/  had  (~(get by cache) key)
  =.  p.jon  (~(put by p.jon) 'verified' b+?=(^ had))
  ?~  had  jon
  =.  p.jon  (~(put by p.jon) 'hop' (numb:enjs:format distance.u.had))
  =.  p.jon  (~(put by p.jon) 'via' s+(scot %p via.u.had))
  =.  p.jon  (~(put by p.jon) 'revision' s+(scot %ud revision.body.data.u.had))
  jon
++  cfg-json
  |=  cfg=gossip-cfg
  ^-  json
  =,  enjs:format
  %-  pairs
  :~  hops+(numb hops.cfg)
      hear+s+hear.cfg
      tell+s+tell.cfg
      pass+b+|
  ==
++  pal-json
  |=  [=bowl:gall targs=(set @p) leech=(set @p) who=@p]
  ^-  json
  =/  sub  (~(get by wex.bowl) [/omart/peer/(scot %p who) who dap.bowl])
  =,  enjs:format
  %-  pairs
  :~  ship+s+(scot %p who)
      target+b+(~(has in targs) who)
      leech+b+(~(has in leech) who)
      connection+s+?~(sub 'disconnected' ?:(-.u.sub 'connected' 'connecting'))
  ==
++  pals-install-state
  |=  =bowl:gall
  ^-  [phase=@t source=(unit ship)]
  =/  ego  (scot %p our.bowl)
  =/  wen  (scot %da now.bowl)
  =/  sources  .^((map desk [ship desk]) %gx /[ego]/hood/[wen]/kiln/sources/noun)
  =/  source  (~(get by sources) %pals)
  =/  from=(unit ship)  ?~(source ~ `-.u.source)
  ?:  running:~(. pals bowl)  ['ready' from]
  =/  desks  .^(rock:tire:clay %cx /[ego]//[wen]/tire)
  =/  installed  (~(get by desks) %pals)
  ?~  installed  [?~(source 'missing' 'installing') from]
  ?:  =(%dead zest.u.installed)  ['suspended' from]
  ?:  !=(~ wic.u.installed)  ['waiting' from]
  ?:  =(%held zest.u.installed)  ['installing' from]
  ['starting' from]
++  pals-status-json
  |=  =bowl:gall
  ^-  json
  =/  status  (pals-install-state bowl)
  (pairs:enjs:format ~[phase+s+phase.status source+?~(source.status ~ s+(scot %p u.source.status))])
++  pals-json
  |=  =bowl:gall
  ^-  json
  =/  pal  ~(. pals bowl)
  =/  targs=(set ship)  (targets:pal ~.)
  =/  leech=(set ship)  leeches:pal
  =/  all=(list @p)  ~(tap in (~(uni in targs) leech))
  =,  enjs:format
  %-  pairs
  :~  our+s+(scot %p our.bowl)
      status+(pals-status-json bowl)
      pals+a+(turn all |=(who=@p (pal-json bowl targs leech who)))
  ==
++  plugin-from-json
  |=  [=bowl:gall jon=json]
  ^-  (each plugin @t)
  ?.  ?=(%o -.jon)  [%| 'object required']
  =,  dejs-soft:format
  =/  raw  %.  jon
    %-  ot
    :~  [%id so]
        [%name so]
        [%git so]
        [%description so]
        [%version so]
        [%author so]
        [%kinds (ar so)]
        [%tags (ar so)]
    ==
  ?~  raw  [%| 'missing fields']
  =/  [i=@t n=@t g=@t d=@t v=@t a=@t ks=(list @t) ts=(list @t)]  u.raw
  ?.  ((sane %tas) i)  [%| 'listing id must start with a lowercase letter; use lowercase letters, digits and hyphens']
  =/  kinds=(list kind)
    (murn ks kind-of)
  =/  tags=(list term)
    %+  murn  ts
    |=  t=@t
    ^-  (unit term)
    ?.  ((sane %tas) t)  ~
    `t
  (check-plugin [i n v a our.bowl d g kinds tags now.bowl])
++  ship-from-json
  |=  jon=json
  ^-  (unit ship)
  ?.  ?=(%o -.jon)  ~
  =/  v  (~(get by p.jon) 'ship')
  ?~  v  ~
  ?.  ?=(%s -.u.v)  ~
  =/  t  (trip p.u.v)
  ?:  =(~ t)  ~
  =/  with=tape  ?:(=('~' (snag 0 t)) t (weld "~" t))
  (slaw %p (crip with))
++  id-from-json
  |=  jon=json
  ^-  (unit id)
  ?.  ?=(%o -.jon)  ~
  =/  v  (~(get by p.jon) 'id')
  ?~  v  ~
  ?.  ?=(%s -.u.v)  ~
  ?.  ((sane %tas) p.u.v)  ~
  `p.u.v
++  cfg-from-json
  |=  jon=json
  ^-  (unit gossip-cfg)
  ?.  ?=(%o -.jon)  ~
  =/  hops-j  (~(get by p.jon) 'hops')
  =/  hear-j  (~(get by p.jon) 'hear')
  =/  tell-j  (~(get by p.jon) 'tell')
  =/  pass-j  (~(get by p.jon) 'pass')
  ?.  ?=(^ hops-j)  ~
  ?.  ?=(%n -.u.hops-j)  ~
  =/  hops=@ud  (rash p.u.hops-j dem)
  ?:  (gth hops 3)  ~
  =/  hear=whos  %targets
  =?  hear  &(?=(^ hear-j) ?=(%s -.u.hear-j))
    ?+  p.u.hear-j  %targets
      %anybody  %anybody
      %targets  %targets
      %mutuals  %mutuals
    ==
  =/  tell=whos  %targets
  =?  tell  &(?=(^ tell-j) ?=(%s -.u.tell-j))
    ?+  p.u.tell-j  %targets
      %anybody  %anybody
      %targets  %targets
      %mutuals  %mutuals
    ==
  `[hops hear tell |]
++  static
  |=  [ct=@t =octs]
  ^-  simple-payload:http
  [[200 [['content-type' ct] ['cache-control' 'no-store']~]] `octs]
++  clay-file
  |=  [=bowl:gall pax=path]
  ^-  octs
  =/  dat=@
    .^  @  %cx
      :(weld /(scot %p our.bowl)/[dap.bowl]/(scot %da now.bowl) pax)
    ==
  [(met 3 dat) dat]
++  cat-octs
  |=  [a=octs b=octs]
  ^-  octs
  [(add p.a p.b) (add q.a (lsh [3 p.a] q.b))]
++  clay-js-chunks
  |=  =bowl:gall
  ^-  octs
  =/  base=path
    /(scot %p our.bowl)/[dap.bowl]/(scot %da now.bowl)/web/js
  =/  =arch  .^(arch %cy base)
  =/  n=@ud  ~(wyt by dir.arch)
  =/  i=@ud  0
  =/  out=octs  [0 0]
  |-  ^-  octs
  ?:  =(i n)  out
  =/  dat=@  .^(@ %cx (weld base /(scot %ud i)/js))
  $(i +(i), out (cat-octs out [(met 3 dat) dat]))
++  eyre-cards
  |=  =bowl:gall
  ^-  (list card)
  :~  [%pass /eyre/connect %arvo %e %connect [~ /[dap.bowl]] dap.bowl]
      [%pass /eyre/apps %arvo %e %connect [~ /apps/[dap.bowl]] dap.bowl]
  ==
++  handle-get
  |=  [=bowl:gall cache=(map listing-key entry) legacy=(map listing-key plugin) cfg=gossip-cfg req=inbound-request:eyre]
  ^-  simple-payload:http
  =/  url  (trip url.request.req)
  ?:  ?=(^ (find "listings.json" url))
    (json-ok (listings-json cache legacy))
  ?:  ?=(^ (find "pals.json" url))
    ?.  authenticated.req
      [307 ['location' '/~/login?redirect=/apps/omart/pals']~]~
    (json-ok (pals-json bowl))
  ?:  ?=(^ (find "config.json" url))
    ?.  authenticated.req
      [307 ['location' '/~/login?redirect=/apps/omart/pals']~]~
    (json-ok (cfg-json cfg))
  ?:  ?=(^ (find "icon.svg" url))
    (static 'image/svg+xml' (clay-file bowl /web/icon/svg))
  ?:  ?=(^ (find "assets/app.js" url))
    (static 'text/javascript' (clay-js-chunks bowl))
  ?:  ?=(^ (find "assets/app.css" url))
    (static 'text/css' (clay-file bowl /web/assets/app/css))
  (static 'text/html' (clay-file bowl /web/index/html))
++  helpers
  |_  [=bowl:gall state-2]
  +*  state  +<+
      net  ~(. network bowl cfg cache)
  ++  new-pagers
    ^-  (map ship (unit listing-key))
    %-  ~(gas by *(map ship (unit listing-key)))
    (turn ~(tap in wanted:net) |=(s=ship [s ~]))
  ::
  ++  startup
    ^-  (quip card _state)
    =.  cfg  cfg(pass |)
    =.  next  (add now.bowl ~m5)
    =.  pagers  new-pagers
    =^  refreshed  state  refresh-owned
    :_  state
    ;:  weld
      refreshed
      (eyre-cards bowl)
      (reconcile:net &)
      `(list card)`~[[%pass /omart/keys/(scot %p our.bowl) %arvo %j %public-keys (silt ~[our.bowl])]]
      `(list card)`~[[%pass /omart/timer/(scot %da next) %arvo %b %wait next]]
    ==
  ::
  ++  make-local
    |=  [key=id content=(unit plugin) budget=@ud]
    ^-  (quip card _state)
    =.  clock  (max +(clock) now.bowl)
    =/  signed  (seal:op our.bowl now.bowl key clock budget content)
    ?.  (shape:op signed)  [~ state]
    =/  item=entry  [signed 0 our.bowl &]
    =.  cache  (~(put by cache) [our.bowl key] item)
    =.  legacy  (~(del by legacy) [our.bowl key])
    [(broadcast:net item our.bowl) state]
  ::
  ++  refresh-owned
    ^-  (quip card _state)
    =/  ego  (scot %p our.bowl)
    =/  wen  (scot %da now.bowl)
    =/  life  .^(@ud %j /[ego]/life/[wen]/[ego])
    =/  era  ?:(=(%pawn (clan:title our.bowl)) 0 .^(@ud %j /[ego]/rift/[wen]/[ego]))
    =/  rows  ~(tap by cache)
    =|  cards=(list card)
    |-
    ?~  rows  [cards state]
    =/  [key=listing-key val=entry]  i.rows
    ?:  !=(origin.key our.bowl)  $(rows t.rows)
    ?:  &(=(life life.body.data.val) =(era era.body.data.val))
      $(rows t.rows)
    =^  more  state  (make-local id.key content.body.data.val hops.body.data.val)
    $(rows t.rows, cards (weld cards more))
  ::
  ++  ingest
    |=  [via=ship env=envelope]
    ^-  (quip card _state)
    =/  key  (key:op data.env)
    ?.  (shape:op data.env)  [~ state]
    ?.  ?|  ?=(~ content.body.data.env)
            ?&  (gth distance.env 0)
                (lte distance.env hops.body.data.env)
                ?:(=(via origin.key) =(distance.env 1) (gte distance.env 2))
            ==
        ==
      [~ state]
    (ingest-checked via env)
  ::
  ++  ingest-checked
    |=  [via=ship env=envelope]
    ^-  (quip card _state)
    =/  key  (key:op data.env)
    =/  auth  (authenticate:op our.bowl now.bowl data.env)
    ?~  auth
      ?:  (gte (lent pending) 128)  [~ state]
      ?:  (levy pending |=(p=[via=ship received=@da env=envelope] !=(env.p env)))
        =.  pending  [[via now.bowl env] pending]
        ?:  (~(has in tracked) origin.key)  [~ state]
        =.  tracked  (~(put in tracked) origin.key)
        :_  state
        [%pass /omart/keys/(scot %p origin.key) %arvo %j %public-keys (silt ~[origin.key])]~
      [~ state]
    ?.  u.auth  [~ state]
    =/  old  (~(get by cache) key)
    ?^  old
      ?.  (newer:op data.env data.u.old)
        ?.  &(=(body.data.env body.data.u.old) trusted.u.old (lth distance.env distance.u.old))
          [~ state]
        (store-entry via env)
      (store-entry via env)
    (store-entry via env)
  ::
  ++  store-entry
    |=  [via=ship env=envelope]
    ^-  (quip card _state)
    =/  key  (key:op data.env)
    =/  item=entry  [data.env ?:(?=(~ content.body.data.env) 0 distance.env) via &]
    =.  cache  (~(put by cache) key item)
    =.  legacy  (~(del by legacy) key)
    =?  clock  =(our.bowl origin.key)
      (max clock revision.body.data.env)
    =/  cards  (broadcast:net item via)
    ?:  |(=(our.bowl origin.key) =(%pawn (clan:title origin.key)) (~(has in tracked) origin.key))
      [cards state]
    =.  tracked  (~(put in tracked) origin.key)
    :-  [[%pass /omart/keys/(scot %p origin.key) %arvo %j %public-keys (silt ~[origin.key])] cards]
    state
  ::
  ++  receive
    |=  [via=ship page=sync-page]
    ^-  (quip card _state)
    ?.  (~(has in wanted:net) via)  [~ state]
    ?:  (gth (lent records.page) 8)  [~ state]
    =|  cards=(list card)
    =/  rows  records.page
    |-
    ?^  rows
      =^  more  state  (ingest via i.rows)
      $(rows t.rows, cards (weld cards more))
    ?:  =(%live mode.page)  [cards state]
    =/  expected  (~(get by pagers) via)
    ?~  expected  [cards state]
    ?.  =(u.expected cursor.page)  [cards state]
    ?~  more.page
      [cards state(pagers (~(del by pagers) via))]
    ?~  records.page  [cards state]
    ?.  =(u.more.page (key:op data:(rear records.page)))  [cards state]
    ?^  cursor.page
      ?.  &(!=(u.cursor.page u.more.page) (gor u.cursor.page u.more.page))  [cards state]
      [(snoc cards (request:net via more.page)) state(pagers (~(put by pagers) via more.page))]
    [(snoc cards (request:net via more.page)) state(pagers (~(put by pagers) via more.page))]
  ::
  ++  retry-pending
    ^-  (quip card _state)
    =/  rows  pending
    =.  pending  ~
    =|  cards=(list card)
    |-
    ?~  rows  [cards state]
    =/  p  i.rows
    ?:  (gth now.bowl (add received.p ~m30))  $(rows t.rows)
    ?.  (~(has in wanted:net) via.p)  $(rows t.rows)
    =^  more  state  (ingest via.p env.p)
    ::  Retrying must not extend an unknown-key record's original deadline.
    =.  pending
      (turn pending |=(q=[via=ship received=@da env=envelope] ?:(=(env.q env.p) q(received received.p) q)))
    $(rows t.rows, cards (weld cards more))
  ::
  --
--
::
=|  state-2
=*  state  -
::
%-  agent:dbug
^-  agent:gall
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %|) bowl)
    net   ~(. network bowl cfg cache)
    up    ~(. helpers bowl state)
::
++  on-init
  ^-  (quip card _this)
  =.  cfg  default-cfg
  =^  cards  state  startup:up
  [cards this]
::
++  on-save  !>(state)
++  on-load
  |=  ole=vase
  ^-  (quip card _this)
  ::  Earlier versions saved the app inside the generic gossip wrapper.
  =?  ole  ?=([[%gossip *] *] q.ole)
    (slot 3 ole)
  ?:  =(%2 -.q.ole)
    =.  state  !<(state-2 ole)
    =^  cards  state  startup:up
    [cards this]
  =/  old=state-1
    ?:  =(%1 -.q.ole)  !<(state-1 ole)
    ?>  =(%0 -.q.ole)
    =/  prev  !<(state-0 ole)
    =/  ret  (~(gas by *(map id ship)) (turn ~(tap in retracted.prev) |=(key=id [key our.bowl])))
    [%1 listings.prev ret default-cfg]
  =.  state  *state-2
  =.  cfg  cfg.old(pass |)
  =/  rows  ~(val by listings.old)
  =|  cards=(list card)
  |-
  ?^  rows
    =/  p  i.rows
    ?:  !=(ship.p our.bowl)
      $(rows t.rows, legacy (~(put by legacy) [ship.p id.p] p))
    =.  legacy  (~(put by legacy) [ship.p id.p] p)
    =^  ignored  state  (make-local:up id.p `p hops.cfg)
    $(rows t.rows)
  =/  gone  ~(tap by retracted.old)
  |-
  ?^  gone
    =/  [key=id owner=ship]  i.gone
    ?:  |(!=(owner our.bowl) (~(has by cache) [owner key]))
      $(gone t.gone)
    =^  ignored  state  (make-local:up key ~ hops.cfg)
    $(gone t.gone)
  =^  cards  state  startup:up
  [cards this]
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  ?+    mark  (on-poke:def mark vase)
      %handle-http-request
    =+  !<([eyre-id=@ta req=inbound-request:eyre] vase)
    =/  method  method.request.req
    =/  url  url.request.req
    =/  sit  site:(parse-request-line:server url)
    =/  tail  ?~(sit %$ (rear sit))
    ?:  =(method %'GET')
      :_  this
      %+  give-simple-payload:app:server  eyre-id
      (handle-get bowl cache legacy cfg req)
    ?:  =(method %'POST')
      ?:  =(tail %install-pals)
        ?^  no=(need-user req '/~/login?redirect=/apps/omart/pals')
          :_  this
          (give-simple-payload:app:server eyre-id u.no)
        =/  status  (pals-install-state bowl)
        ?:  =('missing' phase.status)
          :_  this
          [%pass /pals-install/[eyre-id] %agent [our.bowl %hood] %poke %kiln-install !>([%pals ~paldev %pals])]~
        ?:  =('suspended' phase.status)
          :_  this
          [%pass /pals-install/[eyre-id] %agent [our.bowl %hood] %poke %kiln-revive !>(%pals)]~
        :_  this
        (give-simple-payload:app:server eyre-id (json-ok (pals-status-json bowl)))
      ?:  =(tail %retry)
        ?^  no=(need-user req '/~/login?redirect=/apps/omart/pals')
          :_  this
          (give-simple-payload:app:server eyre-id u.no)
        =.  pagers  new-pagers:up
        :_  this
        %+  weld  (reconcile:net &)
        (give-simple-payload:app:server eyre-id (json-ok (pairs:enjs:format ~[ok+b+&])))
      ?:  =(tail %meet)
        ?^  no=(need-user req '/~/login?redirect=/apps/omart/pals')
          :_  this
          (give-simple-payload:app:server eyre-id u.no)
        ?.  running:~(. pals bowl)
          :_  this
          (give-simple-payload:app:server eyre-id (json-err 409 '%pals is not running'))
        ?~  body.request.req
          :_  this
          (give-simple-payload:app:server eyre-id (json-err 400 'missing body'))
        =/  jon  (de:json:html q.u.body.request.req)
        ?~  jon
          :_  this
          (give-simple-payload:app:server eyre-id (json-err 400 'bad json'))
        =/  who=(unit ship)  (ship-from-json u.jon)
        ?~  who
          :_  this
          (give-simple-payload:app:server eyre-id (json-err 400 'bad ship'))
        :_  this
        %+  weld
          [%pass /pals %agent [our.bowl %pals] %poke %pals-command !>([%meet u.who ~])]~
        %+  give-simple-payload:app:server  eyre-id
        (json-ok (pairs:enjs:format ~[ok+b+& ship+s+(scot %p u.who)]))
      ?:  =(tail %part)
        ?^  no=(need-user req '/~/login?redirect=/apps/omart/pals')
          :_  this
          (give-simple-payload:app:server eyre-id u.no)
        ?.  running:~(. pals bowl)
          :_  this
          (give-simple-payload:app:server eyre-id (json-err 409 '%pals is not running'))
        ?~  body.request.req
          :_  this
          (give-simple-payload:app:server eyre-id (json-err 400 'missing body'))
        =/  jon  (de:json:html q.u.body.request.req)
        ?~  jon
          :_  this
          (give-simple-payload:app:server eyre-id (json-err 400 'bad json'))
        =/  who=(unit ship)  (ship-from-json u.jon)
        ?~  who
          :_  this
          (give-simple-payload:app:server eyre-id (json-err 400 'bad ship'))
        :_  this
        %+  weld
          [%pass /pals %agent [our.bowl %pals] %poke %pals-command !>([%part u.who ~])]~
        %+  give-simple-payload:app:server  eyre-id
        (json-ok (pairs:enjs:format ~[ok+b+& ship+s+(scot %p u.who)]))
      ?:  =(tail %publish)
        ?^  no=(need-user req '/~/login?redirect=/apps/omart')
          :_  this
          (give-simple-payload:app:server eyre-id u.no)
        ?~  body.request.req
          :_  this
          (give-simple-payload:app:server eyre-id (json-err 400 'missing body'))
        =/  jon  (de:json:html q.u.body.request.req)
        ?~  jon
          :_  this
          (give-simple-payload:app:server eyre-id (json-err 400 'bad json'))
        =/  made  (plugin-from-json bowl u.jon)
        ?:  ?=(%| -.made)
          :_  this
          (give-simple-payload:app:server eyre-id (json-err 400 p.made))
        =/  =plugin  p.made
        =^  cards  state  (make-local:up id.plugin `plugin hops.cfg)
        :_  this
        %+  weld  cards
        %+  give-simple-payload:app:server  eyre-id
        (json-ok (plugin-json plugin))
      ?:  =(tail %retract)
        ?^  no=(need-user req '/~/login?redirect=/apps/omart')
          :_  this
          (give-simple-payload:app:server eyre-id u.no)
        ?~  body.request.req
          :_  this
          (give-simple-payload:app:server eyre-id (json-err 400 'missing body'))
        =/  jon  (de:json:html q.u.body.request.req)
        ?~  jon
          :_  this
          (give-simple-payload:app:server eyre-id (json-err 400 'bad json'))
        =/  who  (id-from-json u.jon)
        ?~  who
          :_  this
          (give-simple-payload:app:server eyre-id (json-err 400 'bad id'))
        ?.  |((~(has by cache) [our.bowl u.who]) (~(has by legacy) [our.bowl u.who]))
          :_  this
          (give-simple-payload:app:server eyre-id (json-err 404 'own listing not found'))
        =^  cards  state  (make-local:up u.who ~ hops.cfg)
        :_  this
        %+  weld  cards
        %+  give-simple-payload:app:server  eyre-id
        %-  json-ok
        %-  pairs:enjs:format
        :~  ok+b+%&
            [%id %s (scot %tas u.who)]
        ==
      ?:  =(tail %config)
        ?^  no=(need-user req '/~/login?redirect=/apps/omart/pals')
          :_  this
          (give-simple-payload:app:server eyre-id u.no)
        ?~  body.request.req
          :_  this
          (give-simple-payload:app:server eyre-id (json-err 400 'missing body'))
        =/  jon  (de:json:html q.u.body.request.req)
        ?~  jon
          :_  this
          (give-simple-payload:app:server eyre-id (json-err 400 'bad json'))
        =/  new  (cfg-from-json u.jon)
        ?~  new
          :_  this
          (give-simple-payload:app:server eyre-id (json-err 400 'bad config'))
        =.  cfg  u.new
        =.  pagers  new-pagers:up
        :_  this
        %+  weld  (reconcile:net &)
        %+  give-simple-payload:app:server  eyre-id
        (json-ok (cfg-json u.new))
      :_  this
      %+  give-simple-payload:app:server  eyre-id
      (json-err 404 'unknown')
    :_  this
    %+  give-simple-payload:app:server  eyre-id
    [[405 ~] ~]
  ::
      %omart-page
    ?>  (allowed:net src.bowl)
    =/  cursor  !<((unit listing-key) vase)
    :_  this
    [%give %fact [/omart/v2/(scot %p src.bowl)]~ %omart-sync !>((page:net cursor))]~
      %omart-sync
    ?>  (~(has in wanted:net) src.bowl)
    =/  incoming  (mole |.(!<(sync-page vase)))
    ?~  incoming  [~ this]
    =^  cards  state  (receive:up src.bowl u.incoming)
    [cards this]
      %omart-action
    ?>  =(src our):bowl
    =+  act=!<(action vase)
    ?-    -.act
        %retry
      =.  pagers  new-pagers:up
      [(reconcile:net &) this]
        %publish
      =/  made  (check-plugin plugin.act(ship our.bowl, when now.bowl))
      ?:  ?=(%| -.made)  [~ this]
      =^  cards  state  (make-local:up id.p.made `p.made hops.cfg)
      [cards this]
        %retract
      ?.  |((~(has by cache) [our.bowl id.act]) (~(has by legacy) [our.bowl id.act]))  [~ this]
      =^  cards  state  (make-local:up id.act ~ hops.cfg)
      [cards this]
    ==
  ==
::
++  on-watch
  |=  =path
  ^-  (quip card _this)
  ?:  ?=([%http-response *] path)  [~ this]
  ?:  &(=(/listings path) =(our src):bowl)  [~ this]
  ?>  =(/omart/v2/(scot %p src.bowl) path)
  ?>  (allowed:net src.bowl)
  [[%give %fact ~ %omart-sync !>((page:net ~))]~ this]
::
++  on-arvo
  |=  [=wire sign=sign-arvo]
  ^-  (quip card _this)
  ?:  ?=([%eyre *] wire)  [~ this]
  ?:  ?=([%omart %keys @ ~] wire)
    ?>  ?=([%jael %public-keys *] sign)
    =/  who  (slav %p i.t.t.wire)
    ::  Re-sign our records after a key change; peers stop relaying signatures
    ::  made with a key that Jael no longer authorizes for this identity.
    =^  refreshed  state  refresh-owned:up
    =/  rows  ~(tap by cache)
    |-
    ?^  rows
      =/  [key=listing-key val=entry]  i.rows
      ?:  !=(origin.key who)  $(rows t.rows)
      =/  auth  (authenticate:op our.bowl now.bowl data.val)
      $(rows t.rows, cache (~(put by cache) key val(trusted ?~(auth | u.auth))))
    =^  cards  state  retry-pending:up
    [(weld refreshed cards) this]
  ?:  ?=([%omart %timer @ ~] wire)
    ?>  ?=([%behn %wake *] sign)
    ?.  =(next (slav %da i.t.t.wire))  [~ this]
    =^  refreshed  state  refresh-owned:up
    =^  before  state  retry-pending:up
    =.  next  (add now.bowl ~m5)
    =.  pagers  new-pagers:up
    :_  this
    ;:  weld  refreshed  before  (reconcile:net &)
      `(list card)`~[[%pass /omart/timer/(scot %da next) %arvo %b %wait next]]
    ==
  ::  Old wrapper timers may still arrive after the state migration.
  [~ this]
::
++  on-leave  on-leave:def
++  on-fail   on-fail:def
++  on-agent
  |=  [=wire =sign:agent:gall]
  ^-  (quip card _this)
  ?:  ?=([%pals-install @ ~] wire)
    ?>  ?=(%poke-ack -.sign)
    :_  this
    %+  give-simple-payload:app:server  i.t.wire
    ?^  p.sign
      (json-err 500 '%pals install request was rejected; check +vats %pals in the dojo')
    (json-ok (pals-status-json bowl))
  ?:  ?=([%omart %pals @ ~] wire)
    ::  Missing/suspended pals retries on the timer, not an immediate nack loop.
    ?.  ?=(%fact -.sign)  [~ this]
    ::  Read the actual pals sets after each effect, rather than guessing
    ::  whether this meet/near/part changed subscription eligibility.
    [(reconcile:net |) this]
  ?:  ?=([%omart %peer @ ~] wire)
    ?>  =(src.bowl (slav %p i.t.t.wire))
    ?+  -.sign  [~ this]
      %watch-ack
        ?^  p.sign  [~ this]
        [~ this(pagers (~(put by pagers) src.bowl ~))]
      %fact
        ?.  =(%omart-sync p.cage.sign)  [~ this]
        =/  incoming  (mole |.(!<(sync-page q.cage.sign)))
        ?~  incoming  [~ this]
        =^  cards  state  (receive:up src.bowl u.incoming)
        [cards this]
      %kick
        [~ this]
    ==
  [~ this]
::
++  on-peek
  |=  =path
  ^-  (unit (unit cage))
  ?+  path  (on-peek:def path)
    [%x %listings ~]  ``noun+!>(~(val by (visible-listings cache legacy)))
    [%x %config ~]    ``noun+!>(cfg)
    [%x %records ~]   ``noun+!>(cache)
    [%x %pending ~]   ``noun+!>(pending)
    [%x %record @ @ ~]
      ``noun+!>((~(get by cache) [(slav %p i.t.t.path) i.t.t.t.path]))
    [%x %plugin @ ~]
      =/  key=id  i.t.t.path
      ``noun+!>(`(unit plugin)`(~(get by (visible-listings cache legacy)) [our.bowl key]))
  ==
--
