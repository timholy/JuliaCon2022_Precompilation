# This assumes you're using `juliaup` with the given channels added
JULIA_DEPOT_PATH=/tmp/pkgs julia +beta --startup=no execute.jl
JULIA_DEPOT_PATH=/tmp/pkgs julia +release --startup=no execute.jl
JULIA_DEPOT_PATH=/tmp/pkgs julia +1.7 --startup=no execute.jl
