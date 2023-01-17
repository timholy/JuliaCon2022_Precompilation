using PyPlot: PyPlot, plt
using DataFrames, CSV
using Colors
using ImageBase # (minimum|maximum)_finite

files = ("julia-1.7.3.csv", "julia-1.10.csv")
groups = map(fn -> splitext(fn)[1], files)
dfs = map(files) do fn
    DataFrame(CSV.File(fn; header=["package", "jisize", "load", "TTFX"]))
end

# Sort the packages by TTFX on master
p = sortperm(dfs[1].TTFX)
dfs = map(dfs) do df
    df[p,:]
end
pkgs = dfs[1].package
@assert dfs[2].package == pkgs

# fig, axs = plt.subplots(3, 1)
# labels = dfs[1].package
# x = 1:length(labels)
# w = 1/(length(dfs) + 1)

# ax = axs[1]
# barsz = [ax.bar(x .+ i*w, df.jisize/1024^2, w, label=groups[i]) for (i, df) in enumerate(dfs)]
# # ax.set_yscale("log", base=2)
# ax.set_ylabel("ji size (MB)")
# ax.set_xticks([])

# ax = axs[2]
# barl = [ax.bar(x .+ i*w, df.load, w, label=groups[i]) for (i, df) in enumerate(dfs)]
# # ax.set_yscale("log", base=2)
# ax.set_ylabel("load time (s)")
# ax.set_xticks([])

# ax = axs[3]
# bart = [ax.bar(x .+ i*w, df.TTFX, w, label=groups[i]) for (i, df) in enumerate(dfs)]
# # ax.set_yscale("log", base=2)
# ax.set_ylabel("TTFX (s)")
# ax.set_xticks(x .+ 3*w/2)
# ax.set_xticklabels(labels; rotation=90)

# plt.legend(barsz, groups)
# fig.tight_layout()

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
trange = (min(minimum_finite(tmats[1]), minimum_finite(tmats[2])),
          max(maximum_finite(tmats[1]), maximum_finite(tmats[2])))
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
ax.set_xlabel("Time (s), Julia-1.7")
ax.set_ylabel("Time (s), Julia-1.10")
fig.savefig("../../figures/ttfx_benchmarks.svg")

# Add annotations that show how cool we are
i = findfirst(==("GLMakie"), pkgs)
x, y = dfs[1].TTFX[i], dfs[2].TTFX[i]
ax.arrow(x, x, zero(x), 0.8*(y-x); color="black", width=0.02x)# length_includes_head=true)
ax.text(0.99*x, y/1.15, "51s → 29s"; horizontalalignment="right")
fig.savefig("../../figures/ttfx_benchmarks2.svg")

x, y = dfs[1].load[i], dfs[2].load[i]
ax.arrow(x, x, zero(x), 0.8*(y-x); color="black", width=0.02x)# length_includes_head=true)
ax.text(0.99*x, y*1.10, "8s → 9s"; horizontalalignment="right")
fig.savefig("../../figures/ttfx_benchmarks3.svg")
