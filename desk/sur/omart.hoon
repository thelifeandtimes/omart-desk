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
