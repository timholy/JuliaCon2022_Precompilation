if !isdefined(@__MODULE__, :run_workload)
    include("runner.jl")
end

run_workload(joinpath(pwd(), "julia-1.8rc3.csv"), "juliabin-1.8", "1.8", "/tmp/pkgs"; clear_output=false)
run_workload(joinpath(pwd(), "julia-1.7.0.csv"), "juliabin-1.7", "1.7", "/tmp/pkgs"; clear_output=false)
