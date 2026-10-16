# ox_lib for Blixt UI

This is the **Blixt Developments fork of ox_lib**, based on [Overextended's ox_lib](https://github.com/overextended/ox_lib). It keeps the `ox_lib` resource name and adds optional support for the separate Blixt UI interface.

Existing scripts continue to call `lib.notify`, `lib.progressBar`, `lib.showContext` and the other familiar ox_lib functions. The fork forwards supported UI components to `blixt-ui` when that resource is running.

## Installation

Download the **release ZIP** for this fork here: https://github.com/blixtdevelopments/ox_lib/releases/tag/ox_lib 
Extract it so the resulting folder is named `ox_lib` and contains `fxmanifest.lua`, `init.lua`, `imports`, `modules`, `resource`, `web` and the other resource files.


For the full themed interface, install the matching Blixt UI release in a separate `blixt-ui` folder. Add the following before any resources that depend on ox_lib:

```cfg
ensure ox_lib
ensure blixt-ui
```

This fork still works as ox_lib without Blixt UI. When possible, unsupported components and missing Blixt UI fall back to the original interface.

## What this fork changes

The Blixt integration changes client-side interface routing for notifications, progress, context and list menus, radial menus, dialogs, Text UI and skill checks. The original ox_lib APIs remain in use. See [BLIXT_MODIFICATIONS.md](BLIXT_MODIFICATIONS.md) for the affected source paths.

## Credits and licence

Original library: **Overextended and contributors**. Original documentation: https://overextended.dev/ox_lib

ox_lib and the modifications to this fork remain under **LGPL-3.0-or-later**. Keep the original [LICENSE](LICENSE), [NOTICE.md](NOTICE.md) and copyright notices. The modified source must remain available to people who receive the fork. Blixt UI is a separate project with its own terms.
