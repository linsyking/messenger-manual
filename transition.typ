#import "@preview/fletcher:0.4.5" as fletcher: diagram, node, edge

#pagebreak()
= Transitions

Although scene transition animation could be done in user code, it is often very complicated and not generic. Messenger provides a neat API to do transitions between scenes.

Transition has "two stages":

1.  From the old scene to the transition scene
2.  From the transition scene to the new scene

It is defined by:

```elm
type alias Transition userdata =
    { currentTransition : Int
    , outT : Int
    , inT : Int
    , outTrans : SingleTrans userdata
    , inTrans : SingleTrans userdata
    }
```

- `outT` is the time (in milliseconds) of the first stage
- `inT` is the time of the second stage
- `outTrans`: the `SingleTrans` of the first stage
- `inTrans`: the `SingleTrans` of the second stage

The real transition effect is implemented in `SingleTrans`:

```elm
type alias SingleTrans userdata =
    GlobalData userdata -> Renderable -> Float -> Renderable
```

The `Renderable` argument is the `view` of next scene. the `Float` argument is current progress of the transition. It is a value from 0 to 1. 0 means the transition starts, and 1 means the transition ends.

To generate a full transition, use `genTransition`:

```elm
genTransition : ( SingleTrans userdata, Duration ) -> ( SingleTrans userdata, Duration ) -> Transition userdata
```

Now let's take `Fade` transition as an example to explain how to use transition when changing the scene.

== Black Screen Transition

Consider a common scenario when a scene A ends. User wants it to first fade out to black screen and then fade in the next scene B.

#align(center)[
  #diagram(
    node-stroke: 1pt,
    edge-stroke: 1pt,
    node((0, -.2), [A], corner-radius: 2pt),
    node((1.8, -.2), [Black Screen], corner-radius: 2pt),
    node((3.6, -.2), [B], corner-radius: 2pt),
    edge((0.2, -.2), (1.6, -.2), `Fade out`, "->"),
    edge((2, -.2), (3.4, -.2), `Fade in`, "->")
  )
]

Then we emit following `SOMMsg` in A's `update`:

```elm
SOMChangeScene Nothing "B" <| Just <| genTransition (fadeOutBlack, Duration.seconds 5) (fadeInBlack, Duration.seconds 3)
```

5 is the fade out time and 3 is the fade in time.

== Direct Transition

Users may want to directly do transition to the next scene without the black screen.

This is possible by using `nullTransition` and `fadeInWithRenderable` functions.


#set align(center) 
#diagram(
      node-stroke: 1pt,
      edge-stroke: 1pt,
      node((0, -.2), [A], corner-radius: 2pt),
      node((3, -.2), [A], corner-radius: 2pt),
      node((5, -.2), [B], corner-radius: 2pt),
      edge((0.2, -.2), (3, -.2), `nullTransition`, "->"),
      edge((3, -.2), (5, -.2), `Fade in`, "->")
    )
#set align(left)

Since the second scene always exists behind the transition scene during the transition, if the original scene is transparent, the effect will be quite strange. To avoid this, add a white background to the scene (or layer):

```elm
view env data =
    group []
        [ coloredBackground Color.white env.globalData
        ...
        ]
```

Then emit this `SOMMsg`:

```elm
SOMChangeScene Nothing "B" <| Just <| genTransition (nullTransition, Duration.seconds 0) (fadeInWithRenderable <| view env data, Duration.seconds 3)
```

== Transition Implementing

Let's see how `fadeIn` and `fadeOut` is implemented in the core. Users can follow this to design their own transition.

```elm
fadeIn : Color -> SingleTrans ls
fadeIn color gd rd v =
    group []
        [ rd
        , shapes [ fill color, alpha (1 - v) ]
            [ rect gd ( 0, 0 ) ( gd.internalData.virtualWidth, gd.internalData.virtualHeight )
            ]
        ]

fadeOut : Color -> SingleTrans ls
fadeOut color gd rd v =
    group []
        [ rd
        , shapes [ fill color, alpha v ]
            [ rect gd ( 0, 0 ) ( gd.internalData.virtualWidth, gd.internalData.virtualHeight )
            ]
        ]
```

The common pattern is to put the next scene as the background and use an "alpha" value to control the transition scene.
