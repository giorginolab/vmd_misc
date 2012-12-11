# Save FULL visualization state, including trajectories Can be
# reloaded as usual. Most of this proc is copied from save_state
# function built-in VMD, which is distributed under the terms of the
# UIUC Open Source License:
# http://www.ks.uiuc.edu/Research/vmd/current/LICENSE.html


# Trajectory data is saved in pdb and dcd format in a subdir
# <chosen_file_name>.t/molXX.YY

# TODO 
#  - preserve volume data
#  - preserve time-varying data (e.g. user)
#  - option to save only current frame
#  - preserve inferred topologies (parse filespec?)
#  - handle relative paths when loading states [DONE]

# Modifications by Toni Giorgino <toni.giorgino isib.cnr.it>

proc save_full_state {{file EMPTYFILE}} {
  global representations
  global viewpoints
  save_viewpoint
  save_reps

  # If no file was given, get a filename.  Use the Tk file dialog if 
  # available, otherwise get it from stdin. 
  if {![string compare $file EMPTYFILE]} {
    set title "Enter filename to save current VMD state:"
    set filetypes [list {{VMD files} {.vmd}} {{All files} {*}}]
    if { [info commands tk_getSaveFile] != "" } {
      set file [tk_getSaveFile -defaultextension ".vmd"  -title $title -filetypes $filetypes]
    } else {
      puts "Enter filename to save current VMD state:"
      set file [gets stdin]
    }
  }
  if { ![string compare $file ""] } {
    return
  }

  set fildes [open $file w]
  puts $fildes "\#!/usr/local/bin/vmd"
  puts $fildes "\# VMD script written by save_full_state \$Revision: 1.44 $"

  set vmdversion [vmdinfo version]
  puts $fildes "\# VMD version: $vmdversion"

  puts $fildes "set viewplist {}"
  puts $fildes "set fixedlist {}"
  save_materials     $fildes
  save_atomselmacros $fildes
  save_display       $fildes

  # Data directory. Reusing file's path components is fine here,
  # i.e. when writing.  Not so in the state script, ie. when reading,
  # because CWD can be different. Proposed solution: use RELATIVE
  # pathnames in the state file, and make "load_state" resolve them
  # from the selected file (e.g. temporarily changing
  # directory). Alas, this would not solve other ways of loading
  # files, e.g. "play". Converting to absolute pathnames would work,
  # but implies that states can't be moved.
  set fildir $file.t
  set fildir_abs [file join [pwd] $fildir]
  file delete -force $fildir
  file mkdir $fildir
  puts "Saving trajectory data files in directory $fildir"

  render snapshot $fildir/preview.tga 

  # Does it depend on the top molecule?
  set current_frame [molinfo top get frame]

  foreach mol [molinfo list] {
      set mname [format "mol%04d" $mol]

      # in lack of a native format
      animate write psf $fildir/$mname.psf waitfor all $mol
      animate write pdb $fildir/$mname.pdb beg 0 end 0 waitfor all $mol
      animate write dcd $fildir/$mname.dcd waitfor all $mol

      # Try relative first, then absolute if it fails
      puts $fildes "if \[catch {
                                mol new $fildir/$mname.pdb waitfor all
                                animate delete all;
                                mol addfile $fildir/$mname.psf waitfor all
                                mol addfile $fildir/$mname.dcd waitfor all
                    } e \] {
                                puts \"Couldn't open original pathnames; trying $fildir_abs\";
                                mol new $fildir_abs/$mname.pdb waitfor all
                                animate delete all;
                                mol addfile $fildir_abs/$mname.psf waitfor all
                                mol addfile $fildir_abs/$mname.dcd waitfor all
                           } "
      
    # We load PDB for chain info, beta/okkupa, PSF for resid, topology, masses etc,
    # and DCD for coordinates. DCD could be replaced by a multi-frame
    # PDB, with the exception of (a) impossibility to save large
    # coordinates and (b) occupies more disk space.

    foreach g [graphics $mol list] {
      puts $fildes "graphics top [graphics $mol info $g]"
    }
    puts $fildes "mol delrep 0 top"
    if [info exists representations($mol)] {
      set i 0
      foreach rep $representations($mol) {
        foreach {r s c m pbc numpbc on selupd colupd colminmax smooth framespec cplist} $rep { break }
        puts $fildes "mol representation $r"
        puts $fildes "mol color $c"
        puts $fildes "mol selection {$s}"
        puts $fildes "mol material $m"
        puts $fildes "mol addrep top"
        if {[string length $pbc]} {
          puts $fildes "mol showperiodic top $i $pbc"
          puts $fildes "mol numperiodic top $i $numpbc"
        }
        puts $fildes "mol selupdate $i top $selupd"
        puts $fildes "mol colupdate $i top $colupd"
        puts $fildes "mol scaleminmax top $i $colminmax"
        puts $fildes "mol smoothrep top $i $smooth"
        puts $fildes "mol drawframes top $i {$framespec}"
        
        # restore per-representation clipping planes...
        set cpnum 0
        foreach cp $cplist {
          foreach { center color normal status } $cp { break }
          puts $fildes "mol clipplane center $cpnum $i top {$center}"
          puts $fildes "mol clipplane color  $cpnum $i top {$color }"
          puts $fildes "mol clipplane normal $cpnum $i top {$normal}"
          puts $fildes "mol clipplane status $cpnum $i top {$status}"
          incr cpnum
        }

        if { !$on } {
          puts $fildes "mol showrep top $i 0"
        }
        incr i
      } 
    }
    puts $fildes [list mol rename top [lindex [molinfo $mol get name] 0]]
    if {[molinfo $mol get drawn] == 0} {
      puts $fildes "molinfo top set drawn 0"
    }
    if {[molinfo $mol get active] == 0} {
      puts $fildes "molinfo top set active 0"
    }
    if {[molinfo $mol get fixed] == 1} {
      puts $fildes "lappend fixedlist \[molinfo top\]"
    }

    puts $fildes "set viewpoints(\[molinfo top\]) [list $viewpoints($mol)]"
    puts $fildes "lappend viewplist \[molinfo top\]"
    if {$mol == [molinfo top]} {
      puts $fildes "set topmol \[molinfo top\]"
    }
    puts $fildes "\# done with molecule $mol ----------------------------------"
  } 
  puts $fildes "foreach v \$viewplist \{"
  puts $fildes "  molinfo \$v set {center_matrix rotate_matrix scale_matrix global_matrix} \$viewpoints(\$v)"
  puts $fildes "\}"
  puts $fildes "foreach v \$fixedlist \{"
  puts $fildes "  molinfo \$v set fixed 1"
  puts $fildes "\}"
  puts $fildes "unset viewplist"
  puts $fildes "unset fixedlist"
  if {[llength [molinfo list]] > 0} {
    puts $fildes "mol top \$topmol"
    puts $fildes "unset topmol"
  }
  save_colors $fildes
  save_labels $fildes
  
  puts $fildes "animate goto $current_frame"
    
  close $fildes
}
