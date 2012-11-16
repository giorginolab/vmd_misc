save_full_state
================

A script to ALMOST FULLY save the state of a VMD session. Saved state
includes the view, materials, colors (as with the usual save state
menu item), as well as *trajectories* and *topologies*. 

In this way, loading the saved state completely restores 
the state a VMD session was in.

Usage
-----

First, evaluate the function definition. State can then be saved with 

`save_full_state filename.vmd`

This will create:

* a __filename.vmd__ script, which can be reloaded to recover the state;
* a __filename.vmd.d__ directory, containing trajectory data and a snapshot image.

If `filename` is not provided, a file selection dialog opens up.

To recover a session, just `source` the script, or use it with the `vmd -e` option.

Trajectory files are looked up with respect to the current directory. If they
are not found, a second attempt is done with the absolute pathnames that were 
valid at the time the state was saved.


Limitations
-----------

Some data is known not to be restored, including:

* volumetric data
* time-varying variables, such as *user*


