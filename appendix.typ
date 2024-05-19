#pagebreak()
= Appendix

== SOM Calls <sommsg>

`SOMMsg`s are top-level APIs (like system calls in OS) that can directly interact with the core. Users can send `SOMMsg` in any general model.

=== `SOMChangeScene`

*Definition.* `SOMChangeScene ( Maybe scenemsg ) String ( Maybe (Transition userdata) )`

This message is used to change to another scene. Users need to provide the scene init data, the scene name, and the transition.

=== `SOMPlayAudio`

*Definition.* `SOMPlayAudio String String AudioOption`

This message is used to play an audio. It has three parameters: audio name, audio
URL, and audio option. The audio name is similar to the sprite name which is used to identify the audio so that later users can stop the audio by name. The audio URL is the URL of the audio file.

`AudioOption` is defined in `Messenger.Audio.Base.elm`:

```elm
type AudioOption
    = ALoop
    | AOnce
```

`ALoop` means the audio will be played repeatedly. `AOnce` means the audio will be
played only once.

=== `SOMStopAudio`

*Definition.* `SOMStopAudio String`

This message is used to stop an audio. The parameter is the name of the audio.

=== `SOMAlert`

*Definition.* `SOMAlert String`

This message is used to show an alert. The parameter is the content of the alert.

=== `SOMPrompt`

*Definition.* `SOMPrompt String String`

This message is used to show a #link("https://developer.mozilla.org/en-US/docs/Web/API/Window/prompt")[prompt]. Users can use this to get text input from the user. The first parameter is the name of the prompt, and the second parameter is the title of the prompt.

When the user clicks the OK button, the Elm runtime will send a `Prompt String String` message. The first parameter is the name of the prompt, and the second parameter is the user’s input.

=== `SOMSetVolume`

*Definition.* `SOMSetVolume Float`

This message is to change the volume. It should be a value in $[0, 1]$. Users could use a larger value but it will sound noisy.

=== `SOMSaveGlobalData`

*Definition.* `SOMSaveGlobalData`

Save global data (including user data) to local storage.

See @localstorage.

=== `SOMSetContext`

*Definition.* `SOMSetContext (SceneContext userdata scenemsg)`

Restore a scene context.

See @ctx.

=== `SOMGetContext`

*Definition.* `SOMGetContext (SceneContext userdata scenemsg -> userdata -> userdata)`

Get the current scene context and save it to user data.

See @ctx.

== Game Configurations

Users may want to change the settings in `MainConfig.elm` to match their demand. This section explains what each options in that configuration file means.

- `initScene`. The first scene users will see when start the game
- `initSceneMsg`. The message to start the first scene
- `virtualSize`. The virtual drawing size. Users may use whatever they like but think carefully about the ratio (Support 4:3 or 16:9? screens)
- `debug`. A debug flag. If turned on, users can press `F1` to change to a scene quickly and press `F2` to change volume during anytime in the game
- `background`. The background users see. Default is a transparent background
- `timeInterval`. The time between two `Tick` events in milliseconds. Users may change this to a large number to help debug
- `initGlobalData` and `saveGlobalData`. See @localstorage

== Messenger CLI Commands <cli>

You can also use `messenger <command> --help` to view help.

=== Scene

Create a scene.

Usage: `messenger scene [OPTIONS] NAME`

Arguments:

- `name`. The name of the scene
- `--raw`. Use raw scene without layers
- `--proto`, `-p`. Create a sceneproto
- `--init`, `-i`. Create a `Init.elm` file

=== Init

Initialize a Messenger project.

Usage: `messenger init [OPTIONS] NAME`

Arguments:

- `name`. The name of project
- `--template-repo`, `-t`. Use customized repository for cloning templates.
- `--template-tag`, `-b`. The tag or branch of the repository to clone.

=== Layer

Create a layer.

Usage: `messenger layer [OPTIONS] NAME LAYER`

Arguments:

- `name`. The name of the scene
- `layer`. The name of the layer
- `--with-component`, `-c`. Use components in this layer
- `--cdir`, `-cd`. Directory of components in the scene
- `--proto`, `-p`. Create layer in sceneproto
- `--init`, `-i`. Create a `Init.elm` file

=== Level

Create a level.

Usage: `messenger level [OPTIONS] SCENEPROTO NAME`

Arguments:

- `sceneproto`. The name of the sceneproto
- `name`. The name of the level

=== Component

Create a component.

Usage: `messenger component [OPTIONS] SCENE NAME`

Arguments:

- `scene`. The name of the scene
- `name`. The name of the component
- `--cdir`, `-cd`. Directory to store components
- `--proto`, `-p`. Create layer in sceneproto
- `--init`, `-i`. Create a `Init.elm` file

=== Update

Update `Scenes/AllScenes.elm` based on `messenger.json`.

Usage: `messenger update`

== Roadmap

This sections contains some ideas we'd like to implement in future versions of Messenger. We welcome users to post feature request in our Messenger repository's issue.

=== Multi-pass Updater

Some components may want to do some operations after all other components have finished. This is the _second-pass_ updater. We plan to extend this idea further to support _multi-pass_ updater. Components may update _any_ number of passes in one event update.

=== Fixed Update

Used to do accurate physical simulation.

=== Global Component

Users might want to store component in user data.

=== Advanced Component View

Users might want to have `List (Renderable, Int)` instead of `(Renderable, Int)` (In fact, this is what Reweave does). A use-case is that a component may have some part behind the player and some other part in front of the player.

== Acknowledgement

We express great gratitude to the FOCS Messenger team. Members are #link("linsy_king@sjtu.edu.cn")[linsyking], #link("junglcuxo@sjtu.edu.cn")[YUcxovo], #link("www125@sjtu.edu.cn")[matmleave]. We also express sincere gratitude to all students using Messenger.