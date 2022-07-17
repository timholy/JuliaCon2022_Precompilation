using Distributed

# pkgs = ["Example", "Revise", "FixedPointNumbers", "StaticArrays", "Images", "Optim", "SIMD", "Plots", "Makie", "Flux", "DataFrames", "JuMP", "DifferentialEquations"]
pkgs = ["Flux", "DataFrames", "JuMP", "DifferentialEquations"]

for pkg in pkgs
    println(pkg)
    open("/tmp/workflow.jl", "w") do io
        println(io, """
        using Pkg
        Pkg.activate(temp=true)
        Pkg.add("$pkg")
        using SnoopCompileCore
        invs = @snoopr using $pkg
        using SnoopCompile
        length(uinvalidated(invs))
        """)
    end
    p = addprocs(1)[1]
    try
        fut = @spawnat p include("/tmp/workflow.jl")
        open("invalidation_count_1.8", "a+") do io
            println(io, "$pkg | $(fetch(fut))")
        end
    catch
        @warn "$pkg failed"
    end
    rmprocs(p)
end
