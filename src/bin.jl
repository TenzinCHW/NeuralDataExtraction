import Pkg
Pkg.activate(".")
import JLD2, NPZ


function discretise_stim(vals::Vector, first_spike, window::Int)
    vals = Int.(floor.(vals .* 1000))
    start = min(vals..., first_spike)
    Int.(floor.((vals .- start) ./ window)) .+ 1
end


# window is number of milliseconds
function discretise(vals::Vector, freq::Int, window::Int)
    quant = window * Int(freq / 1000)
    start = min(vals...)
    Int.(floor.((vals .- start) ./ quant)) .+ 1
end


function binarise_spikes(data::Dict, bin_duration::Int)
    if "StimTimes" in keys(data) && length(data["StimTimes"]) > 0
        binarise_spikes_stim(data["Ts"], data["StimTimes"], data["Cs"], bin_duration, Int(data["sampleRate"]))
    else
        binarise_spikes(data["Ts"], data["Cs"], bin_duration, Int(data["sampleRate"]))
    end
end


function binarise_spikes(spike_times::Vector, neuron_id::Vector{UInt8}, bin_duration::I, freq::I) where I<:Int
    d_times = discretise(spike_times, freq, bin_duration)
    neuron_map = Dict(j => i for (i, j) in enumerate(sort(unique(neuron_id))))
    num_neurons = length(unique(neuron_id))
    num_bins = max(d_times...)
    bin_data = zeros(UInt8, num_bins, num_neurons)
    for (st, ni) in zip(d_times, neuron_id)
        bin_data[st, neuron_map[ni]] = 1
    end
    return bin_data
end


function binarise_spikes_stim(spike_times::Vector, stim_times::Vector,
        neuron_id::Vector{UInt8}, bin_duration::I, freq::I) where I<:Int
    d_times = discretise(spike_times, freq, bin_duration)
    ds_times = discretise_stim(stim_times, min(spike_times...), bin_duration)
    neuron_map = Dict(j => i for (i, j) in enumerate(sort(unique(neuron_id))))
    num_neurons = length(unique(neuron_id))
    num_bins = max(d_times..., ds_times...)
    bin_data = zeros(UInt8, num_bins, num_neurons+1)
    for (st, ni) in zip(d_times, neuron_id)
        bin_data[st, neuron_map[ni]] = 1
    end
    for st in ds_times
        bin_data[st, end] = 1
    end
    return bin_data
end


if abspath(PROGRAM_FILE) == @__FILE__
    to_bin_dir = "../data/Electrical_stimulation"
    dur = 20
    for dir in readdir(to_bin_dir)
        dir_path = joinpath(to_bin_dir, dir)
        for f in readdir(dir_path)
            if f[end-3:end] == "jld2"
                println(f)
                data = JLD2.load(joinpath(dir_path, f))["data"]
                bin_data = binarise_spikes(data, dur)
                println(size(bin_data), " ", (data["Ts"][end] - data["Ts"][1]) / data["sampleRate"] * 1000 / dur)
                newname = split(f, ".")[1]
                newpath = joinpath(dir_path, newname) * ".npy"
                NPZ.npzwrite(newpath, bin_data)
            end
        end
    end
end

