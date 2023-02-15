# Pick GLMakie or CairoMakie externally
using Makie
using CSV
using DataFrames
using Colors

colors = Makie.wong_colors()

datafiles = filter!(readdir(@__DIR__; join=true)) do name
    endswith(name, ".csv")
end
dfs = [DataFrame(CSV.File(filename; comment="#", header=2)) for filename in datafiles]
vers = [strip(replace(first(readlines(filename)), "#"=>"")) for filename in datafiles]

maxtime = ceil(Int, maximum(max(maximum(df.TTL), maximum(df.TTFX)) for df in dfs))
pkgs = dfs[1].package
@assert allequal(df.package for df in dfs)
pkgcolors = distinguishable_colors(length(pkgs), [colorant"white"]; dropseed=true)


for ysc in ("linear", "log10")
    yscsym = ysc == "linear" ? identity : log10
    ylimmin = ysc == "linear" ? 0 : 0.01
    ylimmax = ysc == "linear" ? maxtime : 10.0^(ceil(log10(maxtime)))
    fig = Figure(resolution=(800, 400))
    axttl = Axis(fig[1,1]; title="TTL", xticks=(1:length(pkgs), pkgs), xticklabelrotation=π/2, yscale=yscsym)
    ttl = vcat([df.TTL for df in dfs]...)
    grp = vcat([fill(i, length(pkgs)) for i in eachindex(dfs)]...)
    x = vcat([1:length(pkgs) for _ in eachindex(dfs)]...)
    barplot!(axttl, x, ttl; dodge=grp, color=colors[grp])
    ylims!(axttl, (ylimmin, ylimmax))

    axttfx = Axis(fig[1,2]; title="TTFX", xticks=(1:length(pkgs), pkgs), xticklabelrotation=π/2, yscale=yscsym)
    ttfx = vcat([df.TTFX for df in dfs]...)
    grp = vcat([fill(i, length(pkgs)) for i in eachindex(dfs)]...)
    x = vcat([1:length(pkgs) for _ in eachindex(dfs)]...)
    barplot!(axttfx, x, ttfx; dodge=grp, color=colors[grp])
    ylims!(axttfx, (ylimmin, ylimmax))

    elements = [PolyElement(polycolor = colors[i]) for i in 1:length(vers)]
    Legend(fig[1,3], elements, vers, "Julia version")

    save("TTL_TTFX_$ysc.pdf", fig)
    save("TTL_TTFX_$ysc.png", fig, px_per_unit=2)

    # Also as line plots
    fig = Figure(resolution=(800, 400))
    axttl = Axis(fig[1,1]; title="TTL", xticks=(1:length(vers), vers), yscale=yscsym, limits=(nothing, (ylimmin, ylimmax)))
    ttl = hcat([df.TTL for df in dfs]...)
    x = 1:length(vers)
    for i in axes(ttl, 1)
        lines!(axttl, x, ttl[i,:]; label=pkgs[i], color=pkgcolors[i])
    end

    axttfx = Axis(fig[1,2]; title="TTFX", xticks=(1:length(vers), vers), yscale=yscsym, limits=(nothing, (ylimmin, ylimmax)))
    ttfx = hcat([df.TTFX for df in dfs]...)
    x = 1:length(vers)
    for i in axes(ttfx, 1)
        lines!(axttfx, x, ttfx[i,:]; label=pkgs[i], color=pkgcolors[i])
    end

    Legend(fig[1,3], axttfx)

    save("TTL_TTFX_jver_$ysc.pdf", fig)
    save("TTL_TTFX_jver_$ysc.png", fig, px_per_unit=2)
end

