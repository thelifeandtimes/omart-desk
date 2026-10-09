::  omart: omarchy plugin bazaar, gossiped among pals
::
/-  *omart
/+  gossip, default-agent, dbug, server, pals
::
/$  grab-plugin  %noun  %omart-plugin
/$  grab-gone    %noun  %omart-gone
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
  ?.  (git-ok git.p)      [%| 'git must be an http(s) URL']
  ?:  =(0 (met 3 name.p))  [%| 'name required']
  ?:  =(0 (met 3 description.p))  [%| 'description required']
  ?:  =(~ kinds.p)  [%| 'need a kind']
  ?:  (gth (lent tags.p) max-tags)  [%| 'too many tags']
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
++  listings-json
  |=  m=(map id plugin)
  ^-  json
  a+(turn ~(val by m) plugin-json)
++  cfg-json
  |=  cfg=gossip-cfg
  ^-  json
  =,  enjs:format
  %-  pairs
  :~  hops+(numb hops.cfg)
      hear+s+hear.cfg
      tell+s+tell.cfg
      pass+b+pass.cfg
  ==
++  pal-json
  |=  [=bowl:gall targs=(set @p) leech=(set @p) who=@p]
  ^-  json
  =/  sub  (~(get by wex.bowl) [/~/gossip/gossip/(scot %p who) who dap.bowl])
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
  =/  pass=?  |
  =?  pass  &(?=(^ pass-j) ?=(%b -.u.pass-j))
    p.u.pass-j
  `[hops hear tell pass]
++  take-plugin
  |=  [listings=(map id plugin) retracted=(map id ship) p=plugin]
  ^-  (unit (map id plugin))
  =/  had  (~(get by listings) id.p)
  ?^  had
    ?.  =(ship.u.had ship.p)  ~
    `(~(put by listings) id.p p)
  ?:  (~(has by retracted) id.p)
    =/  who  (~(got by retracted) id.p)
    ?.  =(who ship.p)  ~
    `(~(put by listings) id.p p)
  ?:  (gte ~(wyt by listings) max-listings)  ~
  `(~(put by listings) id.p p)
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
  |=  [=bowl:gall listings=(map id plugin) cfg=gossip-cfg req=inbound-request:eyre]
  ^-  simple-payload:http
  =/  url  (trip url.request.req)
  ?:  ?=(^ (find "listings.json" url))
    (json-ok (listings-json listings))
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
--
::
=|  state-1
=*  state  -
::
%-  %+  agent:gossip
      [1 %targets %targets |]
    %-  ~(gas by *(map mark $-(* vase)))
    :~  [%omart-plugin |=(n=* !>((grab-plugin n)))]
        [%omart-gone |=(n=* !>((grab-gone n)))]
    ==
::
%-  agent:dbug
^-  agent:gall
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %|) bowl)
::
++  on-init
  ^-  (quip card _this)
  :_  this(cfg default-cfg)
  %+  weld  (eyre-cards bowl)
  [(configure:gossip default-cfg)]~
::
++  on-save  !>(state)
++  on-load
  |=  ole=vase
  ^-  (quip card _this)
  ?:  =(%1 -.q.ole)
    :_  this(state !<(state-1 ole))
    (eyre-cards bowl)
  ?:  =(%0 -.q.ole)
    =/  old  !<(state-0 ole)
    =/  ret=(map id ship)
      %-  ~(gas by *(map id ship))
      (turn ~(tap in retracted.old) |=(=id [id our.bowl]))
    :_  this(state [%1 listings.old ret default-cfg])
    %+  weld  (eyre-cards bowl)
    [(configure:gossip default-cfg)]~
  :_  this
  (eyre-cards bowl)
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
      (handle-get bowl listings cfg req)
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
        :_  this
        %+  weld  [retry:gossip]~
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
        =/  nxt  (take-plugin listings retracted plugin)
        ?~  nxt
          :_  this
          (give-simple-payload:app:server eyre-id (json-err 409 'id taken'))
        :_  this(listings u.nxt, retracted (~(del by retracted) id.plugin))
        %+  weld  [(invent:gossip %omart-plugin !>(plugin))]~
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
        =/  had  (~(get by listings) u.who)
        ?~  had
          :_  this
          (give-simple-payload:app:server eyre-id (json-err 404 'not found'))
        ?.  =(ship.u.had our.bowl)
          :_  this
          (give-simple-payload:app:server eyre-id (json-err 403 'not yours'))
        =/  g=gone  [u.who our.bowl]
        :_  this(listings (~(del by listings) u.who), retracted (~(put by retracted) u.who our.bowl))
        %+  weld  [(invent:gossip %omart-gone !>(g))]~
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
        :_  this(cfg u.new)
        %+  weld  [(configure:gossip u.new)]~
        %+  give-simple-payload:app:server  eyre-id
        (json-ok (cfg-json u.new))
      :_  this
      %+  give-simple-payload:app:server  eyre-id
      (json-err 404 'unknown')
    :_  this
    %+  give-simple-payload:app:server  eyre-id
    [[405 ~] ~]
  ::
      %omart-action
    ?>  =(src our):bowl
    =+  act=!<(action vase)
    ?-    -.act
        %retry
      [[retry:gossip]~ this]
        %publish
      =/  made  (check-plugin plugin.act(ship our.bowl, when now.bowl))
      ?:  ?=(%| -.made)  [~ this]
      =/  nxt  (take-plugin listings retracted p.made)
      ?~  nxt  [~ this]
      :_  this(listings u.nxt, retracted (~(del by retracted) id.p.made))
      [(invent:gossip %omart-plugin !>(p.made))]~
        %retract
      =/  had  (~(get by listings) id.act)
      ?~  had  [~ this]
      ?.  =(ship.u.had our.bowl)  [~ this]
      :_  this(listings (~(del by listings) id.act), retracted (~(put by retracted) id.act our.bowl))
      [(invent:gossip %omart-gone !>(`gone`[id.act our.bowl]))]~
    ==
  ==
::
++  on-watch
  |=  =path
  ^-  (quip card _this)
  ?:  ?=([%http-response *] path)  [~ this]
  ?:  &(=(/listings path) =(our src):bowl)  [~ this]
  ?.  =(/~/gossip/source path)
    (on-watch:def path)
  :_  this
  ::  /source rewraps each fact with our configured hop budget. Only the
  ::  origin may replenish that budget. Cached listings stay on live relay.
  %+  murn  ~(val by listings)
  |=  =plugin
  ^-  (unit card)
  ?.  =(ship.plugin our.bowl)  ~
  `[%give %fact ~ %omart-plugin !>(plugin)]
::
++  on-arvo
  |=  [=wire sign=sign-arvo]
  ^-  (quip card _this)
  ?+    wire  (on-arvo:def wire sign)
      [%eyre *]
    ?>  ?=([%eyre %bound *] sign)
    [~ this]
  ==
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
  ?:  ?=([%pals *] wire)
    [~ this]
  ?.  ?=([%~.~ %gossip *] wire)
    (on-agent:def wire sign)
  ?+    -.sign  (on-agent:def wire sign)
      %fact
    ?+    p.cage.sign  (on-agent:def wire sign)
        %omart-plugin
      =/  pul  (mole |.(!<(plugin q.cage.sign)))
      ?~  pul  [~ this]
      =/  made  (check-plugin u.pul)
      ?:  ?=(%| -.made)  [~ this]
      =/  nxt  (take-plugin listings retracted p.made)
      ?~  nxt  [~ this]
      :-  [%give %fact [/listings]~ %omart-plugin !>(p.made)]~
      this(listings u.nxt)
        %omart-gone
      =/  gud  (mole |.(!<(gone q.cage.sign)))
      ?~  gud  [~ this]
      =/  had  (~(get by listings) id.u.gud)
      ?~  had  [~ this]
      ?.  =(ship.u.had from.u.gud)  [~ this]
      `this(listings (~(del by listings) id.u.gud), retracted (~(put by retracted) id.u.gud from.u.gud))
    ==
  ==
::
++  on-peek
  |=  =path
  ^-  (unit (unit cage))
  ?+  path  (on-peek:def path)
    [%x %listings ~]  ``noun+!>(~(val by listings))
    [%x %config ~]    ``noun+!>(cfg)
    [%x %plugin @ ~]
      =/  =id  i.t.t.path
      ``noun+!>(`(unit plugin)`(~(get by listings) id))
  ==
--
