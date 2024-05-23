#import "@preview/fletcher:0.4.5" as fletcher: diagram, node, edge
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

Components are the most useful and flexible objects in Messenger. They can be very powerful if used in a correct way.

=== Component Group <componentgroup>

Users may use the following command when creating a component to configure the directory the component is created in:

```bash
# Use -cd Or --cdir
messenger component Home Comp1 -cd CSet1
```

This will create a `Scenes/Home/CSet1/Comp1` directory and corresponding component files. The default value of `--cdir` is `Components`.

Grouping components can be helpful because they may have different types of `BaseData`, `Msg` and `Target`. So every group will have a `ComponentBase.elm` and it can be set individually, which means different groups of concrete component type will be abstract into different abstract type. In this way, the component configurations can be organized more methodically, instead of putting everything in one type. The cons is that it is inconvenient to communicate between different groups of components.

Therefore, this feature should be used only after careful consideration. In other words, use it only when the component type in one group hardly need to communicate with other groups of components.

Portable components can be used in an advanced way through this feature. Users can translate the same concrete type into different abstract type for different groups (different from using multiple translators in one group), so that their usages can be managed more clearly. Moreover, some portable components can be set in one group without other user components if needed. Then users can easily manage some portable components that is weakly related to the main game logic such as decorating elements.

=== Sub-component and Component Composition

Users can add components in the component data, this might sounds amazing but reasonable since every data type can be put into a component, including scenes and layers (interesting but useless). Adding components, named as sub-components, could be useful in some situation.

Imagine a situation that in an adventure game, the main character cast magic to fight against enemies. Since the magic system is the core mechanics in this game, it is designed in a complex way: different magics are corresponding to different spells; the magic system needs level value and MP value to judge if a magic can be cast or not; the magic system stores all the magics that the main character has learned.

Of course it can be implement in the character component, combine with other features such as movement, level up, weapons and so on. But this is obviously not a good choice, especially when the magic system is such a complex mechanics.

A better way is to abstract the magic system into a component. For example, the magics have been learned can be stored in `data`, the logic of casting a magic can be implemented in `updaterec` function, and the visual effects of different magic are implemented in `view` function. Since the component for magic system do not need to communicate with other components, it can be put into a separate group.

*Note.* The main character here should not be treated as the same layer component but a parent object when judging the communication objects of the magic system.

Then a magic system component can be added to the data of main character and in the main logic of main character users don't need to care about the implementation of magic system anymore. In other words, the magic system provides some interfaces to outside in this way.

After make a sub-component in this way, users can do more than the previous things! What if some boss in the game has the ability to cast magic? This feature can be easily implemented by adding a magic system component to boss component (maybe a composition of enemy and special features).

This is what is called #link("https://en.wikipedia.org/wiki/Emergent_gameplay")[Emergent gameplay]. Using component composition strategy can somehow do it easy at the code level.

*Note.* Users don't have to use the component type for compositing features. A simple timer, for instance, can be implemented by just `basedata` and `update`. But component type is more general for most of the situations, and it is easier since many tools have been prepared for a component.

*Note.* Do not abstract every simple feature into a component or custom type because you don't need too many portable features! Too many sub-components are chaotic and unmanageable. So use this strategy after thoughtful consideration.

=== Five-Step Updating to Manage Components

Five-Step updating strategy is used to simplify the update logic of a parent object with components (usually is layer). When developing in Messenger, managing the components could be a complex issue, especially when there are several component groups to deal with.

Generally, the `update` function in a parent object with components can be divided into five steps:

+ Update basic data (remove dead components, etc.)
  ```elm
  type alias BasicUpdater data cdata userdata tar msg scenemsg =
      Env cdata userdata -> UserEvent -> data -> ( data, List (Msg tar msg (SceneOutputMsg scenemsg userdata)), ( Env cdata userdata, Bool ) )
  ```
+ Update component groups by using `updateComponents`
+ Determine the messages that need to be sent to components and distribute them (collisions, etc.)
  ```elm
  type alias Distributor data cdata userdata tar msg scenemsg cmsgpacker =
      Env cdata userdata -> UserEvent -> data -> ( data, ( List (Msg tar msg (SceneOutputMsg scenemsg userdata)), cmsgpacker ), Env cdata userdata )
  ```
  where `cmsgpacker` type is a helper type for users to send different type of messages to different component groups. Generally, it should be a record with a similar structure to `data`:
  ```elm
  type alias ComponentMsgPacker =
      { components1: List ( Components1Target, Components1Msg )
      , components2: List ( Components2Target, Components2Msg )
      ...
      }
  ```
  For the objects only need to manage one list of components, the `cmsgpacker` type could be:
  ```elm
  type alias ComponentMsgPacker =
      List ( ComponentTarget, ComponentMsg )
  ```
  Distributor type can also be useful in `updaterec` function.
+ Update the components with the `cmsgpacker` in step 3 using `updateComponentsWithTarget`. If there are multiple `cmsgpacker` results, they need to be combined together first.
+ Handle all the component messages generated from the previous steps.

Here is an example of a layer with two lists of components in different component groups:

```elm
update : LayerUpdate SceneCommonData UserData Target LayerMsg SceneMsg Data
update env evt data =
    let
        --- Step 1
        ( newData1, newlMsg1, ( newEnv1, newBlock1 ) ) =
            updateBasic env evt data

        --- Step 2
        ( newAComps2, newAcMsg2, ( newEnv2_1, newBlock2_1 ) ) =
            updateComponentsWithBlock newEnv1 evt newBlock1 newData1.acomponents

        ( newBComps2, newBcMsg2, ( newEnv2_2, newBlock2_2 ) ) =
            updateComponentsWithBlock newEnv2_1 evt newBlock2_1 newData1.bcomponents

        --- Step 3
        ( newData3, ( newlMsg3, compMsgs ), newEnv3 ) =
            distributeComponentMsgs newEnv2_2 evt { newData1 | acomponents = newAComps2, bcomponents = newBComp2 }

        --- Step 4
        ( newAComps4, newAcMsg4, newEnv4_1 ) =
            updateComponentsWithTarget newEnv3 compMsgs.acomponents newData3.acomponents

        ( newBComp4, newBcMsg4, newEnv4_2 ) =
            updateComponentsWithTarget newEnv4_1 compMsgs.bcomponents newData3.bcomponents

        --- Step 5
        ( newData5_1, newlMsg5_1, newEnv5_1 ) =
            handleComponentMsgs newEnv4_2 (newAcMsg2 ++ newAcMsg4) { newData3 | acomponents = newAComps4, bcomponents = newBComp4 } (newlMsg1 ++ newlMsg3) handlePComponentMsg

        ( newData5_2, newlMsg5_2, newEnv5_2 ) =
            handleComponentMsgs newEnv5_1 (newBcMsg2 ++ newBcMsg4) newData5_1 newlMsg5_1 handleUComponentMsg
    in
    ( newData5_2, (newlMsg5_2, ( newEnv5_2, newBlock2_2 ) )
```
\ 
\ 

#align(center)[
  #diagram(
    node-stroke: 1pt,
    edge-stroke: 1pt,
    node((0.8, 0.3), [`otherData`], corner-radius: 0pt),
    node((0, 0), [`acomponents`], corner-radius: 0pt),
    node((0, 0.6), [`bcomponents`], corner-radius: 0pt),
    node(enclose: ((0.8, 0.3), (0, 0),(0, 0.6) ), stroke: (paint: blue), corner-radius: 6pt, inset: 8pt, name: <init>),
    node((0.8, -0.2), text(fill: blue)[`Data`], stroke: none),
    node((0.8, 2.3), [`otherData'`], corner-radius: 0pt),
    node((0, 2), [`acomponents'`], corner-radius: 0pt),
    node((0, 2.6), [`bcomponents'`], corner-radius: 0pt),
    node(enclose: ((0.8, 2.3), (0, 2),(0, 2.6) ), stroke: (paint: blue), corner-radius: 6pt, inset: 8pt, name: <step1>),
    node((0.8, 1.8), text(fill: blue)[`Data1`], stroke: none),
    edge(<init>, <step1>, `BasicUpdater`, "->", label-side: center),
    node((0.8, 4.3), [`otherData'`], corner-radius: 0pt),
    node((0, 4), [`acomponents2`], corner-radius: 0pt),
    node((0, 4.6), [`bcomponents'`], corner-radius: 0pt),
    node(enclose: ((0.8, 4.3), (0, 4),(0, 4.6) ), stroke: (paint: blue), corner-radius: 6pt, inset: 8pt, name: <step1.5>),
    node((0.8, 3.8), text(fill: blue)[`Data1'`], stroke: none),
    edge(<step1>, <step1.5>, `updateComponentsWithBlock a`, "->", label-side: center),
    node((0.8, 6.3), [`otherData'`], corner-radius: 0pt),
    node((0, 6), [`acomponents2`], corner-radius: 0pt),
    node((0, 6.6), [`bcomponents2`], corner-radius: 0pt),
    node(enclose: ((0.8, 6.3), (0, 6),(0, 6.6) ), stroke: (paint: blue), corner-radius: 6pt, inset: 8pt, name: <step2>),
    node((0.8, 5.8), text(fill: blue)[`Data1''`], stroke: none),
    edge(<step1.5>, <step2>, `updateComponentsWithBlock b`, "->", label-side: center),
    node((0.8, 8.3), [`otherData''`], corner-radius: 0pt),
    node((0, 8), [`acomponents2'`], corner-radius: 0pt),
    node((0, 8.6), [`bcomponents2'`], corner-radius: 0pt),
    node(enclose: ((0.8, 8.3), (0, 8),(0, 8.6) ), stroke: (paint: blue), corner-radius: 6pt, inset: 8pt, name: <step3>),
    node((0.8, 7.8), text(fill: blue)[`Data3`], stroke: none),
    edge(<step2>, <step3>, `Distributor`, "->", label-side: center),
    node((2.3, 1.3), [`LayerMsg1`], corner-radius: 0pt),
    edge((0.8, 1.3), (2.3, 1.3), "->"),
    node((-1.2, 3.3), [`AcMsg2`], corner-radius: 0pt),
    edge((-0.3, 3.3), (-1.2, 3.3), "->"),
    node((-2.7, 5.3), [`BcMsg2`], corner-radius: 0pt),
    edge((-0.3, 5.3), (-2.7, 5.3), "->"),
    node((2.3, 7.3), [`LayerMsg3`], corner-radius: 0pt),
    edge((0.8, 7.3), (2.3, 7.3), "->"),
    // node((-1.2, 7.3), [`toAcMsg3`], corner-radius: 0pt),
    // edge((0, 7.3), (-1.2, 7.3), "->"),
    // node((-2.7, 7.3), [`toBcMsg3`], corner-radius: 0pt),
    // edge((-1.2, 7.3), (-2.7, 7.3), "-"),
    node(enclose: ((2.3, 0.3), (2.3, 7.3)), stroke: (paint: red, dash: "dashed"), inset: 8pt),    
    node((2.3, 0.3), text(fill: red)[Layer Msg], stroke: none),
    node(enclose: ((-1.2, 2.3), (-1.2, 9.3)), stroke: (paint: green, dash: "dashed"), inset: 8pt),    
    node((-1.2, 2.3), text(fill: green)[A Msg], stroke: none),
    node(enclose: ((-2.7, 4.3), (-2.7, 9.3)), stroke: (paint: purple, dash: "dashed"), inset: 8pt),    
    node((-2.7, 4.3), text(fill: purple)[B Msg], stroke: none),
    edge(<step3>, (0.4, 9.5), "->"),
    edge((2.3, 7.8),(2.3, 9.5),stroke: (paint: red, dash: "dashed"), "->"),
    edge((0, 7.3), (-0.7, 7.3), (-0.7, 9.5), "->")
  )
]

#align(center)[
  #diagram(
    node-stroke: 1pt,
    edge-stroke: 1pt,
    edge((-0.7, 0.0), (-0.7, 0.3)),
    edge((-0.75, 0.3), (0.3, 0.3), `toAcMsg`, "->"),
    edge((-0.7, 2.3), (-0.7, 3.6)),
    edge((-0.7, 3.6), (0.3, 3.6), `toBcMsg`, "->"),
    node((0.8, 2.3), [`otherData''`], corner-radius: 0pt),
    node((0, 2), [`acomponents4`], corner-radius: 0pt),
    node((0, 2.6), [`bcomponents2'`], corner-radius: 0pt),
    node(enclose: ((0.8, 2.3), (0, 2),(0, 2.6) ), stroke: (paint: blue), corner-radius: 6pt, inset: 8pt, name: <step3.5>),
    node((0.8, 1.8), text(fill: blue)[`Data3'`], stroke: none),
    edge((0.4, 0), <step3.5>, `updateComponentsWithTarget a`,"->", label-side: center),
    node((0.8, 5.3), [`otherData''`], corner-radius: 0pt),
    node((0, 5), [`acomponents4`], corner-radius: 0pt),
    node((0, 5.6), [`bcomponents4`], corner-radius: 0pt),
    node(enclose: ((0.8, 5.3), (0, 5),(0, 5.6) ), stroke: (paint: blue), corner-radius: 6pt, inset: 8pt, name: <step4>),
    node((0.8, 4.8), text(fill: blue)[`Data3''`], stroke: none),
    edge(<step3.5>, <step4>, `updateComponentsWithTarget b`,"->", label-side: center),
    node((0.8, 8.3), [`otherData'''`], corner-radius: 0pt),
    node((0, 8), [`acomponents4'`], corner-radius: 0pt),
    node((0, 8.6), [`bcomponents4'`], corner-radius: 0pt),
    node(enclose: ((0.8, 8.3), (0, 8),(0, 8.6) ), stroke: (paint: blue), corner-radius: 6pt, inset: 8pt, name: <step5_1>),
    node((0.8, 7.8), text(fill: blue)[`Data5_1`], stroke: none),
    edge(<step4>, <step5_1>, `handleComponentMsgs a`,"->", label-side: center),
    node((0.8, 11.3), [`otherData''''`], corner-radius: 0pt),
    node((0, 11), [`acomponents4''`], corner-radius: 0pt),
    node((0, 11.6), [`bcomponents4''`], corner-radius: 0pt),
    node(enclose: ((0.8, 11.3), (0, 11),(0, 11.6) ), stroke: (paint: blue), corner-radius: 6pt, inset: 8pt, name: <step5_2>),
    node((0.8, 10.8), text(fill: blue)[`Data5_2`], stroke: none),
    edge(<step5_1>, <step5_2>, `handleComponentMsgs b`,"->", label-side: center),
    node((-1.2, 1.3), [`AcMsg4`], corner-radius: 0pt),
    edge((0.3, 1.3), (-1.2, 1.3), "->"),
    node((-2.7, 4.3), [`BcMsg4`], corner-radius: 0pt),
    edge((0.3, 4.3), (-2.7, 4.3), "->"),
    node((2.3, 7.3), [`LayerMsg5_1`], corner-radius: 0pt),
    edge((0.5, 7.3), (2.3, 7.3), "->"),
    edge((2.3, 7.3), (2.3, 9.3), (0.6, 9.3), stroke: (paint: red, dash: "dashed"), "->"),
    node((2.3, 10.3), [`LayerMsg5_2`], corner-radius: 0pt),
    edge((0.5, 10.3), (2.3, 10.3), "->"),
    edge((2.3, 0),(2.3, 6.3), (0.6, 6.3),stroke: (paint: red, dash: "dashed"), "->"),
    node(enclose: ((-1.2, 0), (-1.2, 1.3)), stroke: (paint: green, dash: "dashed"), inset: 8pt),    
    node((-1.2, 0), text(fill: green)[A Msg], stroke: none),
    edge((-1.2, 1.8),(-1.2, 6.3), (0.2, 6.3),stroke: (paint: green, dash: "dashed"), "->"),
    node(enclose: ((-2.7, 0), (-2.7, 4.3)), stroke: (paint: purple, dash: "dashed"), inset: 8pt),    
    node((-2.7, 0), text(fill: purple)[B Msg], stroke: none),
    edge((-2.7, 4.8),(-2.7, 9.3), (0.2, 9.3),stroke: (paint: purple, dash: "dashed"), "->"),
    node(enclose: ((-1, 12), (2.3, 10.3)), stroke: (paint: blue, dash: "dashed"), inset: 8pt),
    node((2, 11.8), text(fill: blue)[Result], stroke: none)
  )
]

== Initial Asset Loading Scene

User may want to have an asset loading scene just like what Reweave does.

When Messenger is loading assets, `update` of the initial scene will not be called. All the user input and events are ignored. However, `view` will be called. `globalTime` and `currentTimeStamp` will be updated but `sceneStartTime` will not be updated.

Moreover, users can get the number of loaded assets by using the `loadedResourceNum` function. Then you can compare it with `resourceNum resource`.

An example:

```elm
startText : GlobalData UserData -> Renderable
startText gd =
    let
        loaded =
            loadedResourceNum gd

        total =
            resourceNum resources

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