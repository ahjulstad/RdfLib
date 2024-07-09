using RdfLib

using PythonCall
import PythonCall.Wrap

g = graph()

pred1 = URIRef("http://example.org/predicate1")
pred2 = URIRef("http://example.org/predicate2")
pred3 = URIRef("http://example.org/predicate3")
p_chained = URIRef("http://example.org/chained")

subject = URIRef("blingbling:justfun")

print(pred1 | pred2)

push!(g, (subject, pred1, Literal("Hello")))
push!(g, (subject, pred2, Literal("Hello2")))
push!(g, (subject, pred3, Literal("Hello3")))

for a in triples(g, (nothing, nothing, nothing))
    println(a)
end

@assert length(collect(triples(g, (nothing, nothing, nothing)))) == 3

@assert length(collect(triples(g, (nothing, pred1 | pred2, nothing)))) == 2

g2 = graph()

tempnode = BNode()

push!(g2, (subject, p_chained, tempnode))
push!(g2, (tempnode, p_chained, Literal("Hello2")))

p_chained*oneormore

for a in triples(g2, (nothing, p_chained*⊕, nothing))
    println(a)
end
@assert length(collect(triples(g2, (nothing, p_chained*⊕, nothing)))) == 3

for a in g2
    println(a)
end

union!(g,g2)
@assert length(g) == 5