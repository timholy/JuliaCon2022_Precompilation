using PyPlot: PyPlot, plt

pkgs, count15, count18 = String[], Int[], Int[]
# Total number of MethodInstances in the system image
tot15, tot18 = 48000, 63271   # 1.5 is an estimate based on memory

for (fl, counts) in ["invalidation_count_1.5" => count15, "invalidation_count_1.8" => count18]
    open(fl) do io
        iter1 = isempty(pkgs)
        i = 0
        for line in eachline(io)
            pkg, c = strip.(split(line, '|'))
            if iter1
                push!(pkgs, pkg)
            else
                @assert pkgs[i+=1] == pkg
            end
            push!(counts, parse(Int, c))
        end
    end
end

fig, ax = plt.subplots()
xrng, w = 1:length(pkgs), 0.4
ax.bar(xrng, 100*count15/tot15; width=w, label="Julia 1.5")
ax.bar(xrng .+ w, 100*count18/tot18; width=w, label="Julia 1.8")
ax.set_xticks(xrng .+ w)
ax.set_xticklabels(pkgs; rotation=90)
ax.set_ylabel("Invalidations as % of system image")
ax.legend()
fig.tight_layout()
