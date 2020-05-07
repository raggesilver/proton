# TreeView

Proton's TreeView is the component responsible for displaying files in the
current workspace. It also allows the user to:

- Create new files
- Rename, delete or move files

## Classes

### Proton.TreeView

The main component, a `Gtk.TreeView`-derived class that does it's sorting
and rendering in another thread.

### Proton.TreeViewItem

An `Object` class containing info on the file. `Proton.TreeView` uses
custom data functions that get their info from this class. A `TreeViewItem`
is instanciated for each item in the `TreeView` and should be free'd once
the item is no longer necessary.

### Proton.TreeViewPanel

This component is what wraps `Proton.TreeView` in a layout. It also has
secondary views for no-workspace scenarios, etc.

## Extending

Proton's TreeView will take a while to be user-extensible, but there are
plans on doing so. This will be necessary for Proton's GIT plugin and
would be nice for Proton's Editorconfig plugin as well.

Planned:

- Add right click action
    - When the user right clicks an item in the TreeView a Gtk.Popover
    pops up with it's default options (rename, delete, new file/folder,
    etc...), but it would be nice if plugins could add their entries too,
    Editorconfig could, for example, add a "Generate .editorconfig" entry
- Text color
    - Proton's core GIT plugin will have to modify the foreground color of
    certain `TreeViewItem`s to indicate their status on the VCS
