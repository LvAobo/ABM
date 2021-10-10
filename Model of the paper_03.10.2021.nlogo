breed [ public people ]
breed [ factories factory ]
breed [ banks bank ]
breed [ centrals central ]
directed-link-breed [counters counter]
directed-link-breed [jobs job]
directed-link-breed [invesments invesment]

turtles-own [money]
public-own [
  k-value b-value
  have-job
  goods
  skill
  owe
  trans
] ;; HOUSEHOLD
factories-own [
  owe
  k-value b-value
  scale employee
  equipment
  goods pre-goods
  salary pmoney
  price
  resetup
  time
  real-money
  inves
  inves-num
] ;;GOODS-SERVES
banks-own [
  goal
  usable-money
  fac-num
  fac-rate
  pub-rate
]

to setup
  clear-all
  ask patches [ set pcolor blue ]

  set-default-shape public "person"
  create-public initial-number-public [
    set color white
    set size 1.0
    set label-color blue - 2
    set money 100
    set k-value 0 - (1 / (1 + random 10))
    set b-value random 10 + 1
    set have-job 0
    set goods 0
    set skill 1
    set owe 0
    set trans 0
    setxy random-xcor random-ycor
  ]

  set-default-shape factories "house"
  create-factories initial-number-factories [
    ;; then initialize their variables
    set color white
    set size 1.5  ;; easier to see
    setxy random-xcor random-ycor
    set scale 5
    set employee 0
    set money 100
    set real-money 100
    set goods 0
    set salary 10
    set equipment 1
    set pmoney 0
    set price 10
    set owe 0
    set resetup 0
    set time -2
    set inves 0
    set inves-num 0
  ]

  set-default-shape banks "wheel"
  create-banks initial-number-banks [
    ;; then initialize their variables
    set color white
    set size 1.5
    set label-color blue - 2
    setxy 5 - random 10 5 - random 10
    set money 1000
    set goal 0
    set usable-money 0
    set fac-num 0
    set fac-rate 0.2
    set pub-rate 0.005
  ]

  set-default-shape centrals "wheel"
  create-centrals 1 [
    ;; then initialize their variables
    set color yellow
    set size 2.5
   set label-color blue - 2
    setxy random-xcor random-ycor
    set money 0
  ]

  ask public [
    create-counter-to one-of banks
  ]
  ask factories [
    create-counter-to  one-of banks
  ]
  ask banks [
    set fac-num count in-counter-neighbors with [breed = factories]
  ]
  reset-ticks
end

to go
  ask-job ;;ok
  produce ;;ok
  pay-salary ;;ok
  return-money ;;
  rate-reset
  people-re-setup ;;ok
  reset-equipment ;;
  exchange ;;ok
  reset-price ;;ok
  fac-reset
  save-money ;;.
  dismiss-people ;;.
  bank-reset
  investment ;;.

  if new-policy? [
    new-policy
  ]

  tick

end

to ask-job
  ask public [
    if have-job = 0
    [
      let employer one-of factories
      if ([scale] of employer - [employee] of employer) > 0
      [
        create-job-to employer
        ask employer [
          set employee employee + 1
        ]
        set have-job 1
      ]
    ]
  ]
end
to produce ;; S * ^SCAL*SKILL * ^PRO
  ask factories[
    set pre-goods 0
    set pre-goods sum [skill] of max-n-of (count in-job-neighbors with [breed = public]) in-job-neighbors with [breed = public] [money]
    set goods goods + ((money ^ 0.75 + 0.1) * ((pre-goods + 1) ^ 0.25) * (equipment + 1)) / 2
  ]
end

to pay-salary ;; K * SKILL//no
  ask factories [
    if (count in-job-neighbors with [breed = public]) > 0 [

      set salary  (money / 2) / ave-employee
      ifelse money >= salary * (count in-job-neighbors with [breed = public]) [

        set real-money real-money - salary * (count in-job-neighbors with [breed = public])
        set money money - salary * (count in-job-neighbors with [breed = public])

        let payer self
        ask in-job-neighbors with [breed = public] [
          set money money + [salary] of payer
        ]
        if money >= salary * (count in-job-neighbors with [breed = public]) [
          set resetup   1
        ]

      ]
      [
        set real-money real-money - money
        set salary money / (count in-job-neighbors with [breed = public])
        let payer self
        ask in-job-neighbors with [breed = public] [
          set money money + [salary] of payer
        ]
        set money 0
        show ("meiqian fagongzi")
      ]
    ]
  ]


end

to people-re-setup
  ask public [
    set b-value (4 * money * (0 - k-value)) ^ 0.5
    if b-value <= 0.0001[
      show "my b and k is:"
      show b-value
    ]
;    show k-value
;    show " my money and want "
;    show money
;    show b-value * b-value / k-value * -1 / 4
  ]
end
to return-money ;; BALANCE
  ask banks [
    let giver self
    ask in-counter-neighbors with [breed = public] [
      let ower self
      set money money + [pub-rate] of giver * owe
      ask out-counter-neighbors with [breed = banks] [
        set money money - pub-rate * [owe] of ower
      ]
    ]
  ]

end
to rate-reset
  ask banks [
    ifelse usable-money <= 1500
    [
      ifelse money >= 600
      [
        if pub-rate < 2 [
          set pub-rate pub-rate + 0.01]
        if fac-rate < 2 [
          set fac-rate fac-rate + 0.01]
      ]
      [
        if pub-rate > 0.03 [
          set pub-rate pub-rate - 0.03]
        if fac-rate < 2[
          set fac-rate fac-rate + 0.01]
      ]
    ]
    [
      ifelse money >= 600
      [
        if pub-rate < 2 [
          set pub-rate pub-rate + 0.01]
        if fac-rate > 0.01 [
          set fac-rate fac-rate - 0.01]
      ]
      [
        if pub-rate > 0.03 [
          set pub-rate pub-rate - 0.03]
        if fac-rate > 0.01 [
          set fac-rate fac-rate - 0.01]
      ]
    ]

  ]
end
to exchange
  ask public [
    let buyer self
    let seller one-of factories
    if [price] of seller * [k-value] of buyer + [b-value] of buyer > 0.0001 [
      ifelse [goods] of seller >= ( [price] of seller * [k-value] of buyer + [b-value] of buyer)
      [
        set goods goods + ([price] of seller * [k-value] of buyer + [b-value] of buyer)
        set money money - ([price] of seller * [k-value] of buyer + [b-value] of buyer) * [price] of seller
        ask seller [
          set real-money real-money + (price * [k-value] of buyer + [b-value] of buyer) * price
          set money money + (price * [k-value] of buyer + [b-value] of buyer) * price
          if money <= 0.0001[
            show "2"
            show money
            show price
            show goods
          ]
          set goods goods - (price * [k-value] of buyer + [b-value] of buyer)
        ]
        if money <= 0[
          show "3"
          show money
          show k-value
          show b-value
        ]
      ]
      [
        set goods goods + [goods] of seller
        set money money - [goods] of seller * [price] of seller
        ask seller [
          set real-money real-money + goods * price
          set money money + goods * price
          if money <= 0.0001[
            show "3"
            show money
          ]

          set goods 0
        ]
        if money <= 0.0001[
          show "4"
          show money
        ]
      ]
    ]
    if money < 0 [
      show " my money < 0"
    ]
  ]
end
to reset-price
  ask factories [
    ifelse goods > 0.0001
    [
      if price > 1.1
      [
        set price price - 1
      ]
    ]
    [
      set price price + 1
    ]


  ]
end

to fac-reset
  ask factories [
    set salary  (money / 2 ) / ave-employee
    set pre-goods sum [skill] of max-n-of (count in-job-neighbors with [breed = public]) in-job-neighbors with [breed = public] [money]
    ifelse count in-job-neighbors with [breed = public] = 0
    [
      set scale scale + 1
    ]
    [
      ifelse money - salary * ((count in-job-neighbors with [breed = public]) + 1) <= 0
      [
        set inves 1
        set inves-num (salary * scale) - money
      ]
      [
        ifelse ((money - salary * ((count in-job-neighbors with [breed = public]) + 1)) ^ 0.85 * (pre-goods + 1) ^ 0.25 ) >= ((money - salary * ((count in-job-neighbors with [breed = public]))) ^ 0.85 * (pre-goods ) ^ 0.25)
        [
          if scale - employee < 3 [
            set scale scale + 1
          ]
        ]
        [
          set scale scale - 1
          set inves 1
          set inves-num salary
        ]
      ]
    ]

    set inves 1
    set inves-num 300
  ]

end
to reset-equipment
  ask factories [
    if resetup = 1 [
      let buyer self
      let saller one-of other factories
      ifelse money < [goods] of saller * [price] of saller
      [
        set equipment equipment + ( money / [price] of saller) / 50
        ask saller [
          set goods goods - [money] of buyer / price
          set real-money real-money + [money] of buyer
          set money money + [money] of buyer
        ]
        set real-money real-money - money
        set money 0
      ]
      [
        set  equipment equipment + ([goods] of saller) / 50
        set money money - [goods] of saller * [price] of saller
        set real-money real-money  - [goods] of saller * [price] of saller
        ask saller [
          set real-money real-money + goods * price
          set money money + goods * price
          set goods 0
        ]
      ]
      set resetup 0
    ]
  ]
end


to investment ;;PRO > BANK
  ask factories [
    let ower self
    (ifelse
      time = -2 and inves = 1 [
        let giver one-of banks
        if [usable-money] of giver > (deposit-rate + 1) * [inves-num] of ower [
          create-invesment-from giver
          ask in-invesment-neighbors with [breed = banks] [
            ask one-of in-counter-neighbors with [breed = factories] [
              set real-money real-money - [inves-num] of ower
              set real-money real-money - deposit-rate * [inves-num] of ower
              ask one-of centrals [
                set money money + deposit-rate * [inves-num] of ower
              ]
            ]
          ]
          set real-money real-money + inves-num
          set money money + inves-num
          set time 12
          set inves 0
          set owe 1.2 * inves-num
          set inves-num 0
          set resetup 1
          ask giver [
            set usable-money money + sum [ real-money ] of in-counter-neighbors with [breed = factories] + sum [owe] of in-counter-neighbors with [breed = public]
          ]
        ]
      ]
      time = 0 [
        ifelse money >= owe [
          ask in-invesment-neighbors with [breed = banks] [
            set money money + (2 / 12) * [owe] of ower
            ask one-of in-counter-neighbors with [breed = factories] [
              set real-money real-money + (10 / 12) * [owe] of ower + deposit-rate * (10 / 12) * [owe] of ower
              ask one-of centrals [
                set money money - deposit-rate * (10 / 12) * [owe] of ower
              ]
            ]
          ]
          set real-money real-money - owe
          set money money - owe
          set owe 0
          set time -2
          ask my-in-links with [breed = invesments] [ die ]
        ]
        [
          ask in-invesment-neighbors with [breed = banks] [
            set money money + (2 / 12) * [money] of ower
            ask one-of in-counter-neighbors with [breed = factories] [
              set real-money real-money + (10 / 12) * [money] of ower + deposit-rate * (10 / 12) * [money] of ower
              ask one-of centrals [
                set money money - deposit-rate * (10 / 12) * [money] of ower
              ]
            ]
          ]
          set real-money real-money - money
          set owe  owe - money
          set money 0
        ]
      ]
      time > 0 [
        set time time - 1
      ]
    )
  ]

end
to save-money
  ask banks [
    let ower self
    ask in-counter-neighbors with [breed = public] [

      set trans money + owe
      set owe trans * (1 / 3 * [pub-rate] of ower / 2 )
      set money trans * ( 1 - 1 / 3 * [pub-rate] of ower / 2 )
    ]


  ]
end

to bank-reset
  ask banks [
    let counte self
    set usable-money money + sum [ real-money ] of in-counter-neighbors with [breed = factories] + sum [owe] of in-counter-neighbors with [breed = public]

  ]
end
to dismiss-people
  ask factories [
    let one self

    if (count in-job-neighbors with [breed = public]) > scale [
      ask one-of in-job-neighbors with [breed = public] [
        ask my-links with [other-end = one] [ die ]
        set have-job 0
      ]
      set employee employee - 1
    ]
  ]
end
to new-policy
  ask banks [
    set money money - goal + public-money / count banks
    set goal public-money / count banks
  ]

end

to-report public-money
  report sum [ money ] of max-n-of (count public) public [ money ]
end
to-report factories-money
  report sum [ money ] of max-n-of (count factories) factories [ money ]
end
to-report factories-real-money
  report sum [ real-money ] of max-n-of (count factories) factories [ real-money ] - 100
end
to-report hi
  report factories-money - factories-real-money
end
to-report banks-money
  report sum [ money ] of max-n-of (count banks) banks [ money ]
end
to-report all-money
  report public-money +  banks-usable-money
end
to-report run-money
  report  factories-money + banks-money
end
to-report banks-usable-money
  report sum [ usable-money ] of max-n-of (count banks) banks [ usable-money ]
end
to-report centrals-money
  report sum [ money ] of max-n-of (count centrals) centrals [ money ]
end

to-report public-goods
  report sum [ goods ] of max-n-of (count public) public [ goods ]
end
to-report factories-goods
  report sum [ goods ] of max-n-of (count factories) factories [ goods ]
end
to-report all-goods
  report public-goods + factories-goods
end
to-report ave-price
  report sum [ price ] of max-n-of (count factories) factories [ price ] / count factories
end
to-report ave-save
  report sum [ owe ] of max-n-of (count public) public [ owe ] / count public
end
to-report ave-owe
  report sum [ owe ] of max-n-of (count factories) factories [ owe ] / count factories
end
to-report ave-equipment
  report sum [ equipment ] of max-n-of (count factories) factories [ equipment ] / count factories
end
to-report ave-scale
  report sum [ scale ] of max-n-of (count factories) factories [ scale ] / count factories
end

to-report ave-employee
  report sum [ employee ] of max-n-of (count factories) factories [ employee ] / count factories
end

to-report fac-rates
  report sum [ fac-rate ] of max-n-of (count banks) banks [ fac-rate ] / count banks
end
to-report pub-rates
  report sum [ pub-rate ] of max-n-of (count banks) banks [ pub-rate ] / count banks
end
@#$#@#$#@
GRAPHICS-WINDOW
341
22
778
460
-1
-1
13.0
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
10
23
76
56
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
10
130
205
163
initial-number-public
initial-number-public
0
100
94.0
1
1
NIL
HORIZONTAL

SLIDER
12
178
204
211
initial-number-factories
initial-number-factories
0
100
18.0
1
1
NIL
HORIZONTAL

SLIDER
14
236
204
269
initial-number-banks
initial-number-banks
0
100
3.0
1
1
NIL
HORIZONTAL

BUTTON
78
22
141
55
NIL
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
144
23
207
56
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
37
512
451
725
money
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"all-money" 1.0 0 -16777216 true "" "plot all-money"
"public-money" 1.0 0 -7500403 true "" "plot public-money"
"factories-money" 1.0 0 -2674135 true "" "plot factories-money"
"banks-money" 1.0 0 -955883 true "" "plot banks-money"
"run-money" 1.0 0 -6459832 true "" "plot run-money "
"banks-usable-money" 1.0 0 -1184463 true "" "plot banks-usable-money"
"factories-real-money" 1.0 0 -10899396 true "" "plot factories-real-money"
"centrals-money" 1.0 0 -13840069 true "" "plot centrals-money"

PLOT
473
543
779
693
goods
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"all-goods" 1.0 0 -16777216 true "" "plot all-goods"
"public-goods" 1.0 0 -7500403 true "" "plot public-goods"
"factories-goods" 1.0 0 -2674135 true "" "plot factories-goods"

PLOT
821
548
1021
698
 ave-price
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot  ave-price"

PLOT
1080
29
1280
179
ave-save
NIL
NIL
0.0
5.0
0.0
5.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot ave-save"

PLOT
1083
227
1283
377
ave-owe
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot ave-owe"

PLOT
837
30
1037
180
ave-equipment
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot ave-equipment"

SWITCH
1110
677
1244
710
new-policy?
new-policy?
1
1
-1000

PLOT
842
228
1042
378
ave-scale
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"ave-scale" 1.0 0 -16777216 true "" "plot ave-scale"
"ave-employee" 1.0 0 -7500403 true "" "plot ave-employee"

SLIDER
17
300
189
333
scales
scales
0
100
75.0
1
1
NIL
HORIZONTAL

SLIDER
81
364
253
397
deposit-rate
deposit-rate
0
3
0.44
0.01
1
NIL
HORIZONTAL

PLOT
1109
427
1309
577
rate
NIL
NIL
0.0
2.0
0.0
2.0
true
true
"" ""
PENS
"fac-rate" 1.0 0 -16777216 true "" "plot fac-rates"
"pub-rate" 1.0 0 -7500403 true "" "plot pub-rates"

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
