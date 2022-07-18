using Colors

if !isdefined(@__MODULE__, :language_colors)
    hexhash(c) = "#"*hex(c)
    const language_colors = (cols = hexhash.(distinguishable_colors(4, [colorant"white", colorant"black"]; dropseed=true));
                            Dict("Julia"=>cols[1], "python"=>cols[4]))
end
