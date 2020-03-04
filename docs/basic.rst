Basic structures
================

Note that you first need to set a satisfying epsilon:

.. autofunction:: geom3d.set_epsilon


.. autoclass:: geom3d.Vector
    :members:

.. autoclass:: geom3d.Line
    :members:

.. autoclass:: geom3d.PointInLine
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
