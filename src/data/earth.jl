import CSV
import DataFrames

symbols = [:SOVEREIGNT, :GDP_MD_EST, :GDP_YEAR]
path = "data/natural_earth_vector"
attributesname = "temp2-attributes.csv"
nodesname = "temp1-nodes.csv"
attributes = DataFrames.DataFrame(CSV.File(joinpath(path, attributesname)))
nodes = DataFrames.DataFrame(CSV.File(joinpath(path, nodesname)))
dict = Dict()
for symbol in symbols
    column = DataFrames.groupby(attributes, symbol)
    dict[symbol] = column
end
gdp_year = DataFrames.groupby(attributes, :GDP_YEAR)
subdataframe = groupdataframe[(SOVEREIGNT="Iran",)]
gdp = subdataframe.GDP_MD_EST
