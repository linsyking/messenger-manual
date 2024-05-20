#import "@preview/fletcher:0.4.5" as fletcher: diagram, node, edge
#import fletcher.shapes: hexagon

= Introduction

There are several Elm packages like #link("https://package.elm-lang.org/packages/evancz/elm-playground/latest/")[elm-playground], which offer simple APIs to create a game. However, these packages have many limitations and are not suitable for creating complex games.

Messenger is a 2D game engine for Elm based on `elm-canvas`. It provides an architecture, a set of APIs, and many library functions to enable rapid game development. Additionally, Messenger is message-based and abstracts the concept of objects using the _co-inductive type_ technique.

Messenger has many cool features:

- *Coordinate System Support*

  The view-port and coordinate transformation functions are already implemented. Messenger is also adaptive to window size changes.

- *Separate User Code and Core Code*

  User code and core code are separated. Any side effects are controlled by the Messenger core. This helps debugging and decrease security concerns.

- *Basic Game Engine API Support*

  Messenger provides handy common game engine APIs. Including data storage, audio manager, sprite(sheet) manager, and so on. More features are still under development.
  
- *Modular Development*
  
  Every component, layer, and scene is a module, simplifying code management. The implementation is highly packaged, allowing focus on the specific logic of the needed functions. Messenger is designed for convenience and ease of use.

- *Highly Customizable*

  The data of each object can be freely defined. The target matching logic and message type are also customizable. Users can create their own object types using the provided General Model type.

- *Flexible Design*

  The engine can be used to varying degrees, with separate management of different tasks. Components can be organized flexibly using the provided functions, allowing classification of portable and non-portable components in any preferred way.

== Messenger Modules

There are several modules (subprojects) within the Messenger project. All the development of Messenger is happening on GitHub.

- #link("https://github.com/linsyking/Messenger")[Messenger CLI]. A handy CLI to create the game rapidly
- #link("https://github.com/linsyking/messenger-core")[Messenger-core]. Core Messenger library
- #link("https://github.com/linsyking/messenger-extra")[Messenger-extra]. Extra Messenger library with experimental features
- #link("https://github.com/linsyking/messenger-examples")[Messenger examples]. Some example projects
- #link("https://github.com/linsyking/messenger-templates")[Messenger templates]. Templates to use Messenger library. Used in the Messenger CLI

*Note.* This manual is compatible with core `11.0.0 <= v < 12.0.0`, templates 0.3.5 and CLI 0.3.5 (make sure your CLI and templates have the same version).

== Messenger Model

The concept of the Messenger model is summarized in the following diagram:

#align(center)[
  #diagram(
    node-stroke: 1pt,
    edge-stroke: 1pt,
    
    node((1, 0), width: 10pt, height: 10pt, shape: circle, fill: yellow.lighten(60%), stroke: 1pt + yellow.darken(20%)),
    node((1+0.5, 0), width: 10pt, height: 10pt, shape: circle, fill: yellow.lighten(60%), stroke: 1pt + yellow.darken(20%)),
    node((1+0.5, 1), width: 10pt, height: 10pt, shape: circle, fill: yellow.lighten(60%), stroke: 1pt + yellow.darken(20%)),
    node((1, 1), width: 10pt, height: 10pt, shape: circle, fill: yellow.lighten(60%), stroke: 1pt + yellow.darken(20%)),
    node([Layer], enclose: ((1, 0), (1+0.5, 1)), corner-radius: 5pt, fill: teal.lighten(80%), stroke: 1pt + teal.darken(20%), name: <l1>),
    edge((1+0.5, 0), (1+0.5, 1), "->", stroke: 1pt + yellow.darken(20%)),
    edge((1, 0), (1+0.5, 0), "->", stroke: 1pt + yellow.darken(20%)),
    edge((1, 1), (1, 0), "->", stroke: 1pt + yellow.darken(20%)),
    edge((1, 1), (1+0.5, 1), "->", stroke: 1pt + yellow.darken(20%)),

    node((2, 0), width: 10pt, height: 10pt, shape: circle, fill: yellow.lighten(60%), stroke: 1pt + yellow.darken(20%)),
    node((2+0.5, 0), width: 10pt, height: 10pt, shape: circle, fill: yellow.lighten(60%), stroke: 1pt + yellow.darken(20%)),
    node((2+0.5, 1), width: 10pt, height: 10pt, shape: circle, fill: yellow.lighten(60%), stroke: 1pt + yellow.darken(20%)),
    node((2, 1), width: 10pt, height: 10pt, shape: circle, fill: yellow.lighten(60%), stroke: 1pt + yellow.darken(20%)),
    node([Layer], enclose: ((2, 0), (2+0.5, 1)), corner-radius: 5pt, fill: teal.lighten(80%), stroke: 1pt + teal.darken(20%), name: <l2>),
    edge((2+0.5, 0), (2+0.5, 1), "->", stroke: 1pt + yellow.darken(20%)),
    edge((2, 0), (2+0.5, 0), "->", stroke: 1pt + yellow.darken(20%)),
    edge((2, 1), (2, 0), "->", stroke: 1pt + yellow.darken(20%)),
    edge((2, 1), (2+0.5, 1), "->", stroke: 1pt + yellow.darken(20%)),

    edge(<l1>, <l2>, "<->", stroke: 1pt + teal.darken(20%)),
    
    node(enclose: ((0.5,-1), (3,2)), corner-radius: 5pt, stroke: 1pt + blue, align(left + top, [Scene]), name:<scene>),
    node((1, 5), [`WorldEvent`], corner-radius: 5pt,fill: gray.lighten(60%), stroke: 1pt + gray.darken(20%), name:<world>),
    node((0.4, 4), [`GlobalData`], corner-radius: 5pt,fill: red.lighten(60%), stroke: 1pt + red.darken(20%), name:<gd>),
    node((1.2, 4), [`UserEvent`], corner-radius: 5pt,fill: red.lighten(60%), stroke: 1pt + red.darken(20%), name:<user>),
    edge(<gd>, <scene>, "->"),
    edge(<user>, <scene>, "->"),
    edge(<world>, <user>, "->", label: "Filter"),
    node((2, 4), [`GlobalData`], corner-radius: 5pt, fill: green.lighten(60%), stroke: 1pt + green.darken(20%), name:<ngd>),
    node((2.8, 4), [`SceneOutputMsg`], corner-radius: 5pt, fill: green.lighten(60%), stroke: 1pt + green.darken(20%), name:<som>),
    node((2.8, 6), [`SOMHandler`], fill: yellow.lighten(60%), stroke: 1pt + yellow.darken(20%), name:<somhandler>, shape: hexagon),
    node((3.8, 5), [`ViewHandler`], fill: yellow.lighten(60%), stroke: 1pt + yellow.darken(20%), name:<viewhandler>, shape: hexagon),
    node((3.8, 6), [Side Effects], corner-radius: 5pt, fill: gray.lighten(60%), stroke: 1pt + gray.darken(20%), name:<sideeff>),
    node((3.8, 4), [`Renderable`], corner-radius: 5pt, fill: green.lighten(60%), stroke: 1pt + green.darken(20%), name:<render>),
    edge(<scene>, <ngd>, "->"),
    edge(<scene>, <som>, "->"),
    edge(<ngd>, <somhandler>, "->"),
    edge(<som>, <somhandler>, "->"),
    edge(<render>, <viewhandler>, "->"),
    edge(<viewhandler>, <sideeff>, "->"),
    edge(<somhandler>, <sideeff>, "->"),
    edge(<scene>, <render>, "->"),
    node(enclose: ((0,-2),(3.5, 2.5)), align(left + top, [User Code]), stroke: (paint: blue, dash: "dashed")),
    edge(<somhandler> ,(0.4,6), <gd>, "->"),
    node(enclose: ((0, 3),(4.8, 6.5)), align(left + top, [Core Code]), stroke: (paint: red, dash: "dashed")),
  )
]

Messenger provides two parts that users can use. The template _user code_ and the _core library code_. Users write code based on the template code and may use any functions in core library. In user code, users need to design the _logic_ of scenes, layers and possibly components. _Logic_ includes the data structure it uses, the `update` function that updates the data when events occur, `view` function that renders the object. Messenger core will first translate world event into user event, then send that event to the scene with the current `globalData`. `globalData` is the data structure Messenger keeps between scenes and users may read and write. The user code will updates its own data and generate some `SceneOutputMessage`. Messenger core (core in brief) will handle all that messages and updates `globalData`.

Messenger manages a game through three levels of objects (Users can create more levels if they want), listed from parents to children:

1. *Scenes*. The core maintains *one scene* at a time. Example: a single level of the game
2. *Layers*. One scene may have multiple layers. Example: the map of the game, and the character layer
3. *Components*. One layer may have multiple components. The small yellow circles in layers in the diagram are _components_. Example: bullets a character shoots

Parent levels can hold children levels, while children levels can send messages to parent levels. Messages can also be sent inside a level between different objects.

=== General Model

Layers and components are defined as an alias of `AbstractGeneralModel`.
It is generated by a `ConcreteGeneralModel`, where users implement their logic.
Their definitions are as follows:

```elm
type AbstractGeneralModel env event tar msg ren bdata sommsg
    = Roll
        { update : env -> event -> ( AbstractGeneralModel env event tar msg ren bdata sommsg, List (Msg tar msg sommsg), ( env, Bool ) )
        , updaterec : env -> msg -> ( AbstractGeneralModel env event tar msg ren bdata sommsg, List (Msg tar msg sommsg), env )
        , view : env -> ren
        , matcher : tar -> Bool
        , baseData : bdata
        }

type alias ConcreteGeneralModel data env event tar msg ren bdata sommsg =
    { init : env -> msg -> ( data, bdata )
    , update : env -> event -> data -> bdata -> ( ( data, bdata ), List (Msg tar msg sommsg), ( env, Bool ) )
    , updaterec : env -> msg -> data -> bdata -> ( ( data, bdata ), List (Msg tar msg sommsg), env )
    , view : env -> data -> bdata -> ren
    , matcher : data -> bdata -> tar -> Bool
    }
```

*Note.* Scenes are similar to layers and components, but have some differences as well. So the core does not define scene by `GeneralModel`.

In brief, `AbstractGeneralModel` is a model that can update itself and generate the view but hiding the data to the user.

When the model updates itself, it will be fed an event (a _user event_, used in `update`) or a message from other object (used in `updaterec`) and it will generate a list of new messages with targets. The target can be either the same type of object or the higher level object. For example, a component can send messages to another component in the same scene and to its parent layer; a layer can send messages to another layer and to its parent scene.

If the input is an event, the model can choose to _block_ it from sending to the next object. To prevent getting wrong messages, model use _matcher_ to identify itself.

The model also has a `baseData` field so that users can get some specific type of data outside the model. This is used in components.

A `ConcreteGeneralModel` can be considered as the _initialization data_ of its corresponding `AbstractGeneralModel`. Specific logic for every part of the `AbstractGeneralModel` should be implemented in `ConcreteGeneralModel` "concretely". That is, to generate a `AbstractGeneralModel`, users have to set a `ConcreteGeneralModel` first, then `abstract` it.

The `abstract` function mainly takes use of the _delayed evaluation_ to implement.

First, consider a simple example.

```elm
type Abstract
    = Roll (() -> Abstract)

type alias Concrete a =
    { init : a, update : a -> a }

abstract : Concrete a -> Abstract
abstract con =
    let
        abstractRec : a -> Abstract
        abstractRec a =
            let
                func : () -> Abstract
                func () =
                    abstractRec <| con.update a
            in
            Roll func
    in
    abstractRec con.init
```

`Abstract` hides the data it is updating and only leaves the interface for users to use. Thus, `Abstarct` with different inner data types can have the same type. The `update` function is like a _virtual function_ in OOP.

Next, let's examine how a concrete `view` is transformed into an abstract `view` for a more advanced example.

```elm
abstract : ConcreteGeneralModel data env event tar msg ren bdata sommsg -> msg -> env -> AbstractGeneralModel env event tar msg ren bdata sommsg
abstract conmodel initMsg initEnv =
    let
        abstractRec : data -> bdata -> AbstractGeneralModel env event tar msg ren bdata sommsg
        abstractRec data base =
            let
                ...
                views : env -> ren
                views env =
                    conmodel.view env data base
            in
            Roll
                { update = updates
                , updaterec = updaterecs
                , view = views
                , matcher = matchers
                , baseData = baseDatas
                }
        ( init_d, init_bd ) =
            conmodel.init initEnv initMsg
    in
    abstractRec init_d init_bd
```

After understanding the relationship between the concrete model and the abstract model, `Messenger.Recursion.updateObjects` can be used to update all objects recursively.

```elm
updateObjects : env -> event -> List (AbstractGeneralModel env event tar msg ren bdata sommsg) -> ( List (AbstractGeneralModel env event tar msg ren bdata sommsg), List (MsgBase msg sommsg), ( env, Bool ) )
```

Note that the output messages of `updateObjects` don't include the targets because the target of those messages are the parent object. If the result has messages that needs to be sent to a same level object, the recursion won't stop.

If users want to only send a specific message(s) to a specific object(s), they may use `updateObjectsWithTarget`:

```elm
updateObjectsWithTarget : env -> List ( tar, msg ) -> List (AbstractGeneralModel env event tar msg ren bdata sommsg) -> ( List (AbstractGeneralModel env event tar msg ren bdata sommsg), List (MsgBase msg sommsg), env )
```

=== Msg Model

The `Msg` type of Messenger is defined as below:

#grid(columns: (4fr, 5fr),
  [```elm
type Msg othertar msg sommsg
    = Parent (MsgBase msg sommsg)
    | Other othertar msg
```
  where `MsgBase` is defined as
  ```elm
type MsgBase othermsg sommsg
    = SOMMsg sommsg
    | OtherMsg othermsg
  ```
  `SOMMsg`, or _Scene Output Message_, is a message that can directly interact with the core. For example, to play an audio, users can emit a `SOMPlayAudio` message, and the core will handle it.
  ],
  [
    #set align(right)
    #diagram(
      node-stroke: 1pt,
      edge-stroke: 1pt,
      node((0, -.2), [Component], corner-radius: 2pt),
      node((1.6, -.2), [Component], corner-radius: 2pt),
      node((.8, .8), [Layer], corner-radius: 2pt),
      edge((0, -.2), (1.8, -.2), `Other`, "->"),
      edge((0, -.2), (.8, .8), `Parent`, "->", bend: -30deg),
      edge((1.6, -.2), (.8, .8), `Parent`, "->", bend: 30deg)
    )
    #v(.5pt)
    #diagram(
      node-stroke: 1pt,
      edge-stroke: 1pt,
      node((0, 0), [Component], corner-radius: 2pt),
      node((1.3, 0), [Layer], corner-radius: 2pt),
      node((1.3, .8), [Layer], corner-radius: 2pt),
      node((2.6, 0), [Scene], corner-radius: 2pt),
      node((2.6, .8), [Messenger], corner-radius: 2pt),
      edge((0, 0), (1.3, 0), `SOMMsg`, "->"),
      edge((1.3, 0), (2.6, 0), `SOMMsg`, "->"),
      edge((2.6, 0), (2.6, .8), `SOMMsg`, "->"),
      edge((0, 0), (1.3, .8), `OtherMsg`, "->", bend: -10deg)
    )
  ]
)

`SOMMsg` is passed to the core from Component $->$ Layer $->$ Scene. It's possible to block `SOMMsg` from a higher level. See @sommsg to learn more about `SOMMsg`s.

Users may need to handle `Parent` messages from components in a layer. Messenger provides a handy function `handleComponentMsgs` which is defined in `Messenger.Layer.Layer`, to help users handle those messages. Users need to provide a `MsgBase` handler, for example:

```elm
handleComponentMsg : Handler Data SceneCommonData UserData Target LayerMsg SceneMsg ComponentMsg
handleComponentMsg env compmsg data =
    case compmsg of
        SOMMsg som ->
            ( data, [ Parent <| SOMMsg som ], env )

        OtherMsg _ ->
            ( data, [], env )

        _ ->
            ( data, [], env )
```

Then users can combine it with `updateComponents` to define the `update` function in layers (provided in the Messenger template):

```elm
update : LayerUpdate SceneCommonData UserData LayerTarget LayerMsg SceneMsg Data
update env evt data =
    let
        ( comps1, msgs1, ( env1, block1 ) ) =
            updateComponents env evt data.components

        ( data1, msgs2, env2 ) =
            handleComponentMsgs env1 msgs1 { data | components = comps1 } [] handleComponentMsg
    in
    ( data1, msgs2, ( env2, block1 ) )
```

=== Example <example1>

*Example.* A, B are two layers (or components) which are in the same scene (or layer) C. The logic of these objects are as follows:

- If A receives an integer $0 <= x <= 10$, then A will send $3x$ and $10-3x$ to B, and send $x$ to C.
- If B receives an integer $x$, then B will send $x-1$ to A.

Now at some time B sends $2$ to A, what will C finally receive?

Answer: 2, 5, 3, 8, 0, 9.
