::  omart: shared types for the plugin bazaar
::
|%
+$  id     term
+$  kind   ?(%bar-widget %panel %overlay %menu %service %bar)
+$  whos   ?(%anybody %targets %mutuals)
+$  gossip-cfg
  $:  hops=@ud
      hear=whos
      tell=whos
      pass=?
  ==
+$  plugin
  $:  id=id
      name=@t
      version=@t
      author=@t
      ship=@p
      description=@t
      git=@t
      kinds=(list kind)
      tags=(list term)
      when=@da
  ==
+$  gone
  $:  id=id
      from=@p
  ==
::  The signature covers the protocol domain, identity, key epoch, revision,
::  publication budget and complete content. ~ content is a withdrawal.
+$  statement
  $:  %omart-signed-v1
      origin=ship
      era=@ud
      life=@ud
      id=id
      revision=@ud
      hops=@ud
      content=(unit plugin)
  ==
+$  signed
  [body=statement public-key=pass signature=@ux]
+$  listing-key  [origin=ship id=id]
+$  envelope  [data=signed distance=@ud]
+$  entry  [data=signed distance=@ud via=ship trusted=?]
+$  sync-page
  [mode=?(%page %live) records=(list envelope) cursor=(unit listing-key) more=(unit listing-key)]
+$  action
  $%  [%publish =plugin]
      [%retract =id]
      [%retry ~]
  ==
+$  update
  $%  [%listings p=(list plugin)]
      [%plugin =plugin]
      [%gone =gone]
  ==
--
