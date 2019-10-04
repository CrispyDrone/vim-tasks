# TASKS

![example](https://raw.githubusercontent.com/irrationalistic/atom-tasks/master/images/tasks_example.png)

Special formatting for .todo and .taskpaper files. Allows you to easily add, complete, and archive your tasks.

Adjust the settings to match your ideal style. Change all the markers to '-' to match taskpaper.

Any line that ends with `:` will be considered a header (like `My Things:`)

Add tags to tasks by starting them with an `@`, such as `@important` or setting a value like `@due(tuesday)`. Priority attributes ('low', 'medium', 'high', and 'critical') are supported in a special way by provided mappings, and a special syntax highlighting.

This uses utf characters, so it is still valid as a plain text document.

## Installation
### Vundle
Place this in your `.vimrc`:

    Plugin 'crispydrone/vim-tasks'

... then run the following in Vim:

    :source %
    :PluginInstall

For Vundle version < 0.10.2, replace Plugin with Bundle above.

### NeoBundle
Place this in your `.vimrc`:

    NeoBundle 'crispydrone/vim-tasks'

... then run the following in Vim:

    :source %
    :NeoBundleInstall

### VimPlug
Place this in your `.vimrc`:

    Plug 'crispydrone/vim-tasks'

... then run the following in Vim:

    :source %
    :PlugInstall

### Pathogen
Run the following in a terminal:

    cd ~/.vim/bundle
    git clone https://github.com/crispydrone/vim-tasks

## Settings Defaults

`let g:TasksMarkerBase = '☐'`

`let g:TasksMarkerDone = '✔'`

`let g:TasksMarkerCancelled = '✘'`

`let g:TasksDateFormat = '%Y-%m-%d %H:%M'`

`let g:TasksAttributeMarker = '@'`

`let g:TasksArchiveSeparator = '＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿'`

Run `:help Tasks` to view the full documentation.

## Preset Bindings
+ `<localleader> n` - create a new task below current line
+ `<localleader> N` - create a new task above current line
+ `<localleader> d` - toggle current task between none and complete statuses
+ `<localleader> x` - toggle current task between none and cancelled statuses
+ `<localleader> a` - archive completed tasks
+ `<localleader> ml` - mark task as low priority
+ `<localleader> mm` - mark task as medium priority
+ `<localleader> mh` - mark task as high priority
+ `<localleader> mc` - mark task as critical priority

