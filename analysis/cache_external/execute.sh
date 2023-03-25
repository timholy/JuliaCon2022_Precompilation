# This assumes you're using `juliaup` with the given channels added to the chosen depot
# For example:
# JULIA_DEPOT_PATH=/tmp/pkgs juliaup add 1.7
# JULIA_DEPOT_PATH=/tmp/pkgs juliaup add 1.8
# JULIA_DEPOT_PATH=/tmp/pkgs juliaup add 1.9
JULIA_DEPOT_PATH=/tmp/pkgs julia +1.9 --startup=no execute.jl
JULIA_DEPOT_PATH=/tmp/pkgs julia +1.8 --startup=no execute.jl
JULIA_DEPOT_PATH=/tmp/pkgs julia +1.7 --startup=no execute.jl
