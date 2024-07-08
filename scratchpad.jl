using RdfLib
using PythonCall

g = graph()

p1 = URIRef("http://example.org/p1")
p2 = URIRef("http://example.org/p2")

print(p1 | p2)

push!(g, (p1, p2, Literal("Hello")))

for a in triples(g, (nothing, nothing, nothing))
    println(a)
end