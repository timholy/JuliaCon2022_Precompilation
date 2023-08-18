using CSV, DataFrames, PrettyTables

df1 = DataFrame(CSV.File("julia-1.7.3.csv"; comment="#",header=true))
df2 = DataFrame(CSV.File("julia-1.9.0.csv"; comment="#",header=true))

df = outerjoin(df1, df2; on=:package, renamecols="_1.7"=>"_1.9")
df.TTL_ratio = df."TTL_1.7" ./ df."TTL_1.9"
df.TTFX_ratio = df."TTFX_1.7" ./ df."TTFX_1.9"
df = df[:,["package", "TTFX_1.7", "TTFX_1.9", "TTFX_ratio", "TTL_1.7", "TTL_1.9", "TTL_ratio"]]
df.total_ratio = (df."TTL_1.7" + df."TTFX_1.7") ./ (df."TTL_1.9" + df."TTFX_1.9")

mayberound(x) = isa(x, AbstractFloat) ? round(x; digits=2) : x
df = mayberound.(df)

# sort!(df; by=:package)

pretty_table(df; tf = tf_markdown)
