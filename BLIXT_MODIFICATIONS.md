# Blixt fork modifications

This fork adds optional routing from ox_lib UI calls to the separately installed `blixt-ui` resource. The usual ox_lib Lua APIs remain available, and the original UI is used where a fallback is supported.

The Blixt integration affects these ox_lib client files:

- `resource/interface/client/notify.lua`
- `resource/interface/client/progress.lua`
- `resource/interface/client/context.lua`
- `resource/interface/client/menu.lua`
- `resource/interface/client/radial.lua`
- `resource/interface/client/input.lua`
- `resource/interface/client/alert.lua`
- `resource/interface/client/textui.lua`
- `resource/interface/client/skillcheck.lua`

Blixt Developments maintains these changes. The underlying ox_lib library is by Overextended and contributors and retains its LGPL-3.0-or-later licence and notices.

When upgrading the upstream fork, compare these files with the previous Blixt version, reapply the integration as needed and test against the matching `blixt-ui` release before publishing.
