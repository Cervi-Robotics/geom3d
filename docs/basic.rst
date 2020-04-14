Degree and coordinate conversion
================================

Sometimes working directly with coordinates in degrees is cumbersome.
For example, you have no way to calculate easily distance between two
points, or say "this coordinate 2 metres west".

These routines and objects try to remedy that:

.. autoclass:: geom3d.degrees.Coordinates
    :members:

.. autoclass:: geom3d.degrees.XYPoint
    :members:

.. autoclass:: geom3d.degrees.XYPointCollection
    :members:

Please note that error introduced by this transformation is the more
pronounced the closer you are to the Poles, so no flying over the Poles
for you!

.. autoclass:: geom3d.degrees.Planet
    :members:

.. autoclass:: geom3d.degrees.Earth

.. autoclass:: geom3d.degrees.CustomPlanet

Basic structures
================

Note that you first need to set a satisfying epsilon:

.. autofunction:: geom3d.set_epsilon


.. autoclass:: geom3d.Vector
    :members:

.. autoclass:: geom3d.Line
    :members:

.. autoclass:: geom3d.PointOnLine
    :members:

.. autoclass:: geom3d.Path
    :members:

Polygons
--------

.. autoclass:: geom3d.polygons.Polygon2D
    :members:

.. autoclass:: geom3d.polygons.PointOnPolygon2D
    :members:

Note that PointOnPolygon2D will behave correctly when faced with calculating the vector towards the polygon
then such point occurs on the vertex. It will take the average of two segment's unit vectors into consideration in that
case.


More complex 3D structures
--------------------------

.. autoclass:: geom3d.meshes.Triangle
    :members:

Paths
=====

Paths is a box (that meant, it has a certain size) with ordered
points in space, constituting that box's path in the function of
time (only that time is undefined).

.. autoclass:: geom3d.paths.Path
    :members:

.. autoclass:: geom3d.paths.Path2D
    :members:

Path can be initialized (that means that it has a box-sized size vector).
An initialized path can be ``__iter__`ed, yielding boxes that will be
the positions of the box in a moment in time.

A path is mutable, and methods
:meth:`geom3d.paths.Path.head_towards` and
:meth:`geom3d.paths.Path.advance` can be used to add extra
elements to it's path.

If you want a path that covers your entire polygon, you can use

.. autofunction:: geom3d.paths.cover_polygon2d_with_path

Making paths nonintersecting
----------------------------

If you have a bunch of paths, and you want to keep them
non-intersecting with each other, this function can help you.
It will make paths nonintersecting by playing around with their
z-values.

.. autofunction:: geom3d.paths.make_nonintersecting
