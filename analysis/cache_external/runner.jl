# Workflow:
# - pick a depot location & initialize it
# - `dev Example` in the depot, add `src/Example1.jl` (revised version) and `src/Example0.jl` (original version) if you're testing Revise
# - run create_package_folders (best to do this on the same major/minor Julia version you plan to test on, so the Manifests get resolved appropriately)
# - manually edit the devved pkgs in the depot to ensure they precompile the given workload
# - for each julia executable you want to test, pick an output file name and execute run_workload
using Pkg

const home = ENV["HOME"]
const depot = dirname(dirname(dirname(Base.active_project())))

# const default_pkgs = String["CSV", "DataFrames", "Revise", "Plots", "GLMakie", "LV", "OrdinaryDiffEq", "ModelingToolkit", "Flux", "JuMP", "ImageFiltering"]
const default_pkgs = String["CSV", "DataFrames", "Revise", "GLMakie", "LV", "OrdinaryDiffEq", "ModelingToolkit", "JuMP", "ImageFiltering"]
const default_deps = Dict("JuMP" => ["GLPK"], "DataFrames" => ["PooledArrays"], "Plots" => ["GR"], "ModelingToolkit" => ["OrdinaryDiffEq"])
const default_workloads = Dict(
    "CSV" => ("", """CSV.File(joinpath(pkgdir(CSV), "test", "testfiles", "precompile.csv"))"""),

    "DataFrames" => (" using PooledArrays: PooledArrays",
    """
    for v in ([1, 2], [2, 1], [2, 2, 1], Int32[1, 2], Int32[2, 1], Int32[2, 2, 1]),
        op in (identity, x -> string.(x), x -> PooledArrays.PooledArray(string.(x))),
        on in (:v1, [:v1, :v2])
            df = DataFrame(v1=op(v), v2=v)
            combine(groupby(df, on), identity, :v1 => identity,
                    :v2 => ByRow(identity), :v2 => sum)
            innerjoin(df, select(df, on), on=on)
            outerjoin(df, select(df, on), on=on)
    end
    """),

    "Revise" => ("using Example",
    """
    sleep(0.1)
    cp(joinpath(pkgdir(Example), "src/Example1.jl"), joinpath(pkgdir(Example), "src/Example.jl"); force=true)
    revise()
    """),

    "Plots" => ("", "display(plot(rand(10)))"),

    "GLMakie" => ("", "display(plot(rand(10)))"),

    "OrdinaryDiffEq" => ("",
    """
    function lorenz(du,u,p,t)
        du[1] = 10.0(u[2]-u[1])
        du[2] = u[1]*(28.0-u[3]) - u[2]
        du[3] = u[1]*u[2] - (8/3)*u[3]
    end
    lorenzprob = ODEProblem(lorenz,[1.0;0.0;0.0],(0.0,1.0))
    solve(lorenzprob,BS3())
    """),

    "ModelingToolkit" => ("using OrdinaryDiffEq",
    """
    function f()
      @parameters t σ ρ β
      @variables x(t) y(t) z(t)
      D = Differential(t)

      eqs = [D(D(x)) ~ σ*(y-x),
             D(y) ~ x*(ρ-z)-y,
             D(z) ~ x*y - β*z]

      @named sys = ODESystem(eqs)
      sys = structural_simplify(sys)

      u0 = [D(x) => 2.0,
            x => 1.0,
            y => 0.0,
            z => 0.0]

      p  = [σ => 28.0,
            ρ => 10.0,
            β => 8/3]

      tspan = (0.0,100.0)
      prob = ODEProblem(sys,u0,tspan,p,jac=true)
    end
    f()
    """),

    "Flux" => ("using Flux: train!",
    """
    actual(x) = 4x + 2
    x_train, x_test = hcat(0:5...), hcat(6:10...)
    y_train, y_test = actual.(x_train), actual.(x_test)
    predict = Dense(1, 1)
    loss(x, y) = Flux.Losses.mse(predict(x), y)
    opt = Descent()
    data = [(x_train, y_train)]
    parameters = Flux.params(predict)
    train!(loss, parameters, data, opt)
    """),

    "ImageFiltering" => ("", "imfilter(rand(Float32, 100, 100), KernelFactors.gaussian((1.5f0, 1.5f0)))"),

    "JuMP" => ("using GLPK",
    """
    model = Model(GLPK.Optimizer)
    @variable(model, x >= 0)
    @variable(model, 0 <= y <= 3)
    @objective(model, Min, 12x + 20y)
    @constraint(model, c1, 6x + 8y >= 100)
    @constraint(model, c2, 7x + 12y >= 120)
    # print(model)
    optimize!(model)
    """),

    "LV" => (
    """
    A = rand(Float64, 512, 512)
    kern = [0.1 0.3 0.1;
            0.3 0.5 0.3;
            0.1 0.3 0.1]
    """,
    """
    filter2davx(A, kern)
    """),
)

const dev_paths = Dict(
    "Revise" => "$depot/dev/Example",
)

const env_settings = Dict(
    "Plots" => ("GRDIR" => "",)
)

const pre_work = Dict(
    # "GLMakie" => "using GLMakie; display(plot(rand(10)))",   # "Caching fonts..."
)

const post_work = Dict(
    "Revise" =>
    """
    using Example
    cp(joinpath(pkgdir(Example), "src/Example0.jl"), joinpath(pkgdir(Example), "src/Example.jl"); force=true)
    """
)

function run_workload(output, pkgs = default_pkgs; clear_output::Bool=true, clear_compiled::Bool=true)
    depot_path = first(DEPOT_PATH)
    v = Base.VERSION
    ver = "v$(v.major).$(v.minor)"
    clear_compiled && rm(joinpath(depot_path, "compiled", ver); force=true, recursive=true)
    if clear_output
        rm(output; force=true)
    elseif isfile(output)
        elim = String[]
        for line in eachline(output)
            nms = split(line, ',')
            push!(elim, nms[1])
        end
        pkgs = setdiff(pkgs, elim)
    end
    devpath = joinpath(depot_path, "dev")
    if !ispath(devpath)
        mkpath(devpath)
    end
    # Create the LV package
    lvpath = joinpath(devpath, "LV")
    if !ispath(lvpath)
        cd(devpath) do
            Pkg.generate("LV")
            Pkg.activate("LV")
            Pkg.add("LoopVectorization")
            open(joinpath("LV", "src", "LV.jl"), "w") do io
                println(io, """
                module LV

                using LoopVectorization
                export filter2davx

                function filter2davx!(out::AbstractMatrix, A::AbstractMatrix, kern::AbstractMatrix)
                    @turbo for J in CartesianIndices(out)
                        tmp = zero(eltype(out))
                        for I ∈ CartesianIndices(kern)
                            tmp += A[I + J] * kern[I]
                        end
                        out[J] = tmp
                    end
                    out
                end

                function filter2davx(A::AbstractMatrix, kern::AbstractMatrix)
                    out = similar(A, size(A) .- size(kern) .+ 1)
                    return filter2davx!(out, A, kern)
                end

                end
                """)
            end
        end
    end
    for pkg in pkgs
        # try
            islv = pkg == "LV"
            setup, wl = default_workloads[pkg]
            # Create Startup.jl which precompiles `wl`
            startuppkg = joinpath(devpath, "Startup")
            rm(startuppkg; force=true, recursive=true)
            usinglist = cd(devpath) do
                pkglist = String[pkg]
                Pkg.generate("Startup")
                Pkg.activate("Startup")
                Pkg.develop(PackageSpec(path="/home/tim/.julia/dev/PrecompileTools"))
                pwlist = get(env_settings, pkg, ())
                pw = ""
                for (key, val) in pwlist
                    ENV[key] = val
                    pw *= """ENV["$key"] = "$val"\n"""
                end
                for dep in get(default_deps, pkg, ())
                    push!(pkglist, dep)
                end
                pkglist = String[pkg for pkg in pkglist if pkg != "LV"]
                !isempty(pkglist) && Pkg.add(pkglist)
                if islv
                    Pkg.develop(path=lvpath)
                    push!(pkglist, "LV")
                end
                if haskey(dev_paths, pkg)
                    dep = dev_paths[pkg]
                    Pkg.develop(path=dep)
                    Pkg.resolve()
                    push!(pkglist, basename(dep))
                end
                open("Startup/src/Startup.jl", "w") do io
                    println(io, """
                    module Startup
                    using PrecompileTools
                    @recompile_invalidations using $pkg
                    @setup_workload begin
                        $setup
                        @compile_workload begin
                            $wl
                        end
                    end
                    end
                    """)
                end
                println("\nStartup pkg definition:\n", read("Startup/src/Startup.jl", String))
                work = """
                using Pkg;
                empty!(DEPOT_PATH);
                pushfirst!(DEPOT_PATH, "$depot_path");
                Pkg.activate("$startuppkg");
                $pw
                Pkg.instantiate()
                Pkg.precompile()
                using Startup
                """
                println("\nPrecompilation:\n", work)
                run(`$(Base.julia_cmd()) --startup=no -e $work`)  # precompiles Startup.jl
                return join(pkglist, ',')
            end
            work =
                """
                using Pkg;
                empty!(DEPOT_PATH);
                pushfirst!(DEPOT_PATH, "$depot_path");
                Pkg.activate("$startuppkg");
                Pkg.precompile()
                tstart = time(); using Startup, $usinglist; tload = time() - tstart
                $setup
                tstart = time(); $wl; trun = time() - tstart
                id = Base.identify_package("$pkg");
                origin = Base.pkgorigins[id];
                if !isfile("$output")
                    open("$output", "w") do io
                        println(io, "# ", VERSION)
                        println(io, "package,filesize,TTL,TTFX")
                    end
                end
                sz = stat(origin.cachepath).size
                if isdefined(Base, :ocachefile_from_cachefile)
                    sz += stat(Base.ocachefile_from_cachefile(origin.cachepath)).size
                end
                open("$output", "a") do io
                    println(io, $pkg, ",", sz, ",", tload, ",", trun)
                end
                """
            run(`$(Base.julia_cmd()) --startup=no -e $work`)
            if haskey(post_work, pkg)
                wl = post_work[pkg]
                cleanup =
                    """
                    using Pkg;
                    empty!(DEPOT_PATH)
                    pushfirst!(DEPOT_PATH, "$depot_path");
                    Pkg.activate("$startuppkg");
                    $wl
                    """
                run(`$(Base.julia_cmd()) --startup=no -e $cleanup`)
            end
        # catch
        # end
    end
end
