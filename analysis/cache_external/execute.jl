# Set up the Example package for testing Revise
using Pkg
exdir = joinpath(Pkg.devdir(), "Example")
if !ispath(exdir)
    Pkg.develop("Example")
    srcdir = joinpath(exdir, "src")
    srcfile = joinpath(srcdir, "Example.jl")
    cp(srcfile, joinpath(srcdir, "Example0.jl"))
    str = read(srcfile, String)
    open(joinpath(srcdir, "Example1.jl"), "w") do io
        write(io, replace(str, "Hello" => "Hallo"))
    end
end

include("runner.jl")

outname = joinpath(pwd(), "julia-$(Base.VERSION).csv")
run_workload(outname; clear_output=false)
