using PyPlot: PyPlot, plt
using DataFrames, CSV
using Colors

files = ("julia-1.7.0.csv", "julia-1.8rc3.csv")
groups = map(fn -> splitext(fn)[1], files)
dfs = map(files) do fn
    DataFrame(CSV.File(fn; header=["package", "jisize", "load", "TTFX"]))
end
pkgs = dfs[1].package
@assert dfs[2].package == pkgs

# Sort the packages by TTFX on master
p = sortperm(dfs[1].TTFX)
dfs = map(dfs) do df
    df[p,:]
end

fig, axs = plt.subplots(3, 1)
labels = dfs[1].package
x = 1:length(labels)
w = 1/(length(dfs) + 1)

ax = axs[1]
barsz = [ax.bar(x .+ i*w, df.jisize/1024^2, w, label=groups[i]) for (i, df) in enumerate(dfs)]
# ax.set_yscale("log", base=2)
ax.set_ylabel("ji size (MB)")
ax.set_xticks([])

ax = axs[2]
barl = [ax.bar(x .+ i*w, df.load, w, label=groups[i]) for (i, df) in enumerate(dfs)]
# ax.set_yscale("log", base=2)
ax.set_ylabel("load time (s)")
ax.set_xticks([])

ax = axs[3]
bart = [ax.bar(x .+ i*w, df.TTFX, w, label=groups[i]) for (i, df) in enumerate(dfs)]
# ax.set_yscale("log", base=2)
ax.set_ylabel("TTFX (s)")
ax.set_xticks(x .+ 3*w/2)
ax.set_xticklabels(labels; rotation=90)

plt.legend(barsz, groups)
fig.tight_layout()

# Plotting just load time and TTFX on the same axis
cols = distinguishable_colors(length(pkgs), [colorant"white", colorant"black"]; dropseed=true)
hexcols = ["#"*hex(col) for col in cols]
fig, ax = plt.subplots()
ptsload = ax.scatter(dfs[1].load, dfs[2].load; c=hexcols, marker="s")
ptsTTFX = ax.scatter(dfs[1].TTFX, dfs[2].TTFX; c=hexcols, marker="o")
# ax.set_xscale("log")
# ax.set_yscale("log")
sc = plt.matplotlib.scale.LogScale(ax; base=2)
ax.set_xscale(sc)
ax.set_yscale(sc)
tmats = (dfs[1][:,[:load,:TTFX]] |> Matrix, dfs[2][:,[:load,:TTFX]] |> Matrix)
trange = (min(minimum(tmats[1]), minimum(tmats[2])),
          max(maximum(tmats[1]), maximum(tmats[2])))
tlim = (2^(floor(log2(trange[1]))), 2^(ceil(log2(trange[2]))))
ax.set_xlim(tlim)
ax.set_ylim(tlim)
ax.plot(tlim, tlim, "k--")
# pkg legend
patches = [plt.matplotlib.patches.Patch(color=col, label=pkg) for (col, pkg) in zip(hexcols, pkgs)]
legpkgs = ax.legend(; handles=patches, loc="upper left")
ax.add_artist(legpkgs)
lns = [plt.matplotlib.lines.Line2D([], [], color="black", label="load", marker="s", linestyle=nothing),
       plt.matplotlib.lines.Line2D([], [], color="black", label="TTFX", marker="o", linestyle=nothing)]
legtask = ax.legend(; handles=lns, loc="lower right")
fig.savefig("../../figures/ttfx_benchmarks.svg")
