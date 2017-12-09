#About
This mod completely overhauls how LOS works in NS2.

In NS2, if you are "sighted", you will be visible
on the enemy team's minimap.

#Benefits

The LOS system in NS2 is very complicated, and also potentially uses a lot of resources.
This version is much much more lightweight. It is also more straightfoward and easier to understand.

Furthermore, the original LOS system some times showed things which obviously should not be seen.
It wasn't very conservative, while this one is. False positives are much more rare.

#Changes

You will **gain** your sighted status if you:
 - Are damaged by an enemy
 - Are in front of a player or drifter

You will **lose** your sighted status, if you:
 - Pass through a phase gate
 - Pass through a gorge tunnel
 - Get beaconed
 - Move 7 meters away
 - Wait for 2 seconds
