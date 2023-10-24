import Pkg
Pkg.activate("..")
import MAT, JLD2


function convert_file(fpath::String)
    rawdata = MAT.matread(fpath)["data"]
    newfpath = join([split(fpath, ".")[1], "jld2"], ".")
    data = Dict()
    for (k, v) in rawdata
        if isa(v, Matrix) && size(v)[2] == 1
            data[k] = reshape(v, length(v))
        else
            data[k] = v
        end
    end
    JLD2.jldsave(newfpath; data)
end


function convert_recursive(base_dir::String)
    base_dir = abspath(base_dir)
    for f in readdir(base_dir)
        fpath = joinpath(base_dir, f)
        if fpath[end-2:end] == "mat"
            convert_file(fpath)
        elseif isdir(fpath)
            convert_recursive(fpath)
        end
    end
end


if abspath(PROGRAM_FILE) == @__FILE__
    convert_recursive("../data")
end

