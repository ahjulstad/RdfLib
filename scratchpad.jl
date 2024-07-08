using RdfLib
using PythonCall

g = graph()

p1 = URIRef("http://example.org/p1")
p2 = URIRef("http://example.org/p2")

print(p1 | p2)