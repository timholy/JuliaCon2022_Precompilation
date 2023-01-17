if !isdefined(@__MODULE__, :run_workload)
    include("runner.jl")
end

run_workload(joinpath(pwd(), "julia-1.10.csv"), "/home/tim/src/juliaw/julia", "1.10", "/tmp/pkgs"; clear_output=false)
run_workload(joinpath(pwd(), "julia-1.7.3.csv"), "juliabin-1.7", "1.7", "/tmp/pkgs"; clear_output=false)
