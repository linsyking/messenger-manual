#pagebreak()
= Advanced Usage

== LocalStorage <localstorage>

#link("https://developer.mozilla.org/en-US/docs/Web/API/Window/localStorage")[Local storage] is a mechanism to store data in the browser.
It allows the game to save data locally.

In Messenger, local storage content is defined by a `String`. When users need to save something to local storage, they need to first serialize it (for example, use `Json`).

Users can read or write to local storage by editing `globalData.userdata` and the data type in local storage is defined in `Lib/UserData.elm`. However, not all things in `UserData` are needed to store to local storage.

Users will need to implement `initGlobalData` and `saveGlobalData` functions. They act as a decoder and decoder for global data.

`initGlobalData` is called when the game starts.
Its type is:

```elm
initGlobalData : String -> UserViewGlobalData UserData
```

The string it needs is the real local storage data. Users will use the local storage data to initialize a global data. The `UserViewGlobalData`

`saveGlobalData` is called when user wants to save the global data (emitted by a `SOMSaveGlobalData` message). Users may encode some part of global data.

== Scene Context Management <ctx>

Users can save the current running scene (including all its data, name and start time) to user data by emitting a `SOMGetContext` message.

Users can load a stored scene context by emitting a `SOMSetContext` message.

=== Example: Scene Stacking

Users may want to stack scenes up like a mobile app. There is only one scene but users can open a new identical scene and later return to the previous page (think as if you are using a video watching app).

To implement this, we have to first define a "stack" in user data. Edit `Lib/UserData.elm`:

```elm
type SceneStack
    = Roll (List (SceneContext UserData SceneMsg))

type alias UserData =
    { sceneStack : SceneStack
    }
```

Note that we need to use an extra type `SceneStack` with `Roll` to avoid infinite type error.

Next, for convenience, we write an `unroll` function and a `popLastScene` function to pop the last scene in the stack:

```elm
unroll : UserData -> List (SceneContext UserData SceneMsg)
unroll storage =
    case storage.sceneStack of
        Roll stack ->
            stack

popLastScene : UserData -> ( Maybe (SceneContext UserData SceneMsg), UserData )
popLastScene storage =
    case unroll storage of
        [] ->
            ( Nothing, storage )

        scene :: rest ->
            ( Just scene, { storage | sceneStack = Roll rest } )
```

We also need a context setter:

```elm
contextSetter : SceneContext UserData SceneMsg -> UserData -> UserData
contextSetter context storage =
    { sceneStack = Roll <| context :: unroll storage
    }
```

Then, for example the scene we are stacking is called "T".

In the updating logic, when it needs to save state and change scene, emit these `SOMMsg`s:

```elm
[ SOMGetContext contextSetter, SOMChangeScene ... ]
```

Note that you must put `SOMGetContext` before `SOMChangeScene`.

And when you want to return, emit a `SOMSetContext` message:

```elm
let
    gd =
        env.globalData
in
case popLastScene gd.userData of
    ( Just s, newud ) ->
        let
            newgd =
                { gd | userData = newud }
        in
        ( data, [ SOMSetContext s ], { env | globalData = newgd } )

    _ ->
        ( data, [], env )
```

== Advanced Component Management

=== Component Group

Users may use the following command when creating a component to configure the directory the component is created in:

```bash
# Use -cd Or --cdir
messenger component Home Comp1 -cd CSet1
```

This will create a `Scenes/Home/CSet1/Comp1` directory and corresponding component files. The default value of `--cdir` is `Components`.

Grouping components can be helpful because they may have different types of `BaseData`, `Msg` and `Target`. The cons is that it is inconvenient to communicate between different groups of components.

=== Five-Step Updating in Layers

// TODO

== Initial Asset Loading Scene

User may want to have an asset loading scene just like what Reweave does.

When Messenger is loading assets, `update` of the initial scene will not be called. All the user input and events are ignored. However, `view` will be called. `globalTime` and `currentTimeStamp` will be updated but `sceneStartTime` will not be updated.

Moreover, users can get the number of loaded assets by using the `loadedSpriteNum` function. Then you can compare it with `spriteNum allTexture allSpriteSheets`.

An example:

```elm
startText : GlobalData UserData -> Renderable
startText gd =
    let
        loaded =
            loadedSpriteNum gd

        total =
            spriteNum allTexture allSpriteSheets

        progress =
            String.slice 0 4 <| String.fromFloat (toFloat loaded / toFloat total * 100)

        text =
            if loaded /= total then
                "Loading... " ++ progress ++ "%"

            else
                "Click to start"
    in
    group [ alpha (0.7 + sin (toFloat gd.globalTime / 10) / 3) ]
        [ renderTextWithColorCenter gd 60 text "Arial" Color.black ( 960, 900 )
        ]
```

The full example is in #link("https://github.com/linsyking/messenger-examples/tree/main/spritesheet")[messenger examples].