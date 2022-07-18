using PyPlot: PyPlot, plt
include("colors.jl")

pyload = 0.264645543997176
pyshow = 0.2434947479996481

# Julia 1.7
glmakieload = 7.999846
glmakieshow = 51.294211864471436

ylim = (0.1, 100)

fig, ax = plt.subplots()
ax.semilogy([1,4], [pyload, pyshow]; linestyle="", marker="o", label="matplotlib (python)", color=language_colors["python"])
ax.semilogy([2,5], [glmakieload, glmakieshow]; linestyle="", marker="o", label="GLMakie (Julia)", color=language_colors["Julia"])
ax.set_ylim(ylim)
ax.set_xlim((0, 6))
ax.set_ylabel("Time (s)")
ax.vlines(3, ylim...; linestyles="dashed", color="black")

ax.text(1.5, 110, "Package load"; horizontalalignment="center", fontsize=18)
ax.text(4.5, 110, "Plot render"; horizontalalignment="center", fontsize=18)

ax.legend()

ax.set_xticks([])
fig.tight_layout()
fig.savefig("makie_latency.svg")
