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

You will **gain** your sighted status if you are hit by an enemy.

You will **lose** your sighted status, if you:
 - Pass through a phase gate
 - Pass through a gorge tunnel
 - Move 7 meters away
 - Wait for 2 seconds
 - Getting beaconed

#Commander help
Since this system is much harder on the commanders, any entities within 4 meters of a friendly player or drifter
will be visible but **not** sighted to the commander. I.e. the models are visible but they're not on
the minimap.
