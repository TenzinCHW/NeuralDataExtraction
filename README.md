This is just a repo for some code to extract data from MATLAB files to npy and jld2 formats for use in Python and Julia.

## Requirements
Get the data into a subdirectory in this repo named `data`.

[Install Julia](https://julialang.org/downloads/)

Start `julia` in this directory.

```import Pkg
Pkg.instantiate()```

then just run both files with `julia src/mat2jld2.jl` and then `julia src/bin.jl`.

