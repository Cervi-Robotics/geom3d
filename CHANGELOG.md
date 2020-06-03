# v0.8

* added `are_mutually_nonintersecting` to `geom3d.paths`
* bump satella
* add `avg` to utils

# v0.7

* fixed a bug in `XYPointCollection`
  * additionally added unit tests to prevent regressions
* bugfix in `make_nonintersecting` - `MakeNonintersecting` object
  would be returned if paths were nonintersecting from the start
* major speed optimizations
* more elements are now hashable
* improved downscaling of polygons
* added `are_mutually_nonintersecting`
* made `Coordinates` and `XYPoint` eq-able and hashable

# v0.6

* added `Triangle`, `Ray`, `Path.set_z`
* software will not be tested on _Python-nighly_ now
* removed `Path2D`

# v0.5

* added `make_nonintersecting`

# v0.4.5

* `Coordinates` are now eq-able and hashable

# v0.4.4

* added `Path2D`
* make fields of `Coordinates` readable by Python

# v0.4.3

* added `Path.simplify`
* added `Path.get_vector_at`
* added `Path.insert_at`
* added `Path.does_collide`

# v0.4.2

* added `Polygon2D.get_closest_to`

# v0.4.1

* fixed installation dependencies
* pip wheels will be built on Travis for Linux @ Python images
    * the developer will continue to deliver Windows wheels manually
* added automatic build using Travis CI

# v0.3

* rewritten to use Cython
* added [semantic versioning 2.0](https://semver.org/spec/v2.0.0.html).
* extensions for `XYPointCollection`
* added extra routines for `Polygon2D`
