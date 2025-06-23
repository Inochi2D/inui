# InUI
This library provides a shared UI base for Inochi2D applications in the 0.8 series,
this will mostly be superseded by [libsoba](https://github.com/Inochi2D/libsoba) in the future,
but may still see updates for smaller utilities.

The codebase is currently undergoing heavy retooling to unify things such as high-dpi support,
theming support, settings store, widgets and the like. You can give it a shot but expect things
to break from time to time for the time being.

## Dependencies

InUI depends on a few libraries to function correctly, the libraries are as follows:  
| Dependency     | Notes                                                      | Platform |
| :------------- | :--------------------------------------------------------- | :------: |
| `SDL 3.2.0+`   | Provided automatically on Windows.                         |   All    |
| `fontconfig`   | Used to list system fonts.                                 |   🐧    |
| `DirectWrite`  | Used to list system fonts.                                 |   🪟    |
| `CoreText`     | Used to list system fonts.                                 |   🍎    |
| `CMake`        | Required to compile imgui.                                 |   All    |
| `C++ compiler` | Required to compile imgui.                                 |   All    |
| `glibc`        | Only tested w/ glibc, ymmv with other C runtimes on Linux. |   🐧    |
| `MSVC 2022+`   |                                                            |   🪟    |
| `D 2.111`      |                                                            |   All    |
