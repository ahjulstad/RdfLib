module RdfLib

import Base: push!, iterate, length, union!

using PythonCall
import PythonCall: pyconvert

const pyrdf = Ref{Py}()
function __init__()
  pyrdf[] = pyimport("rdflib")
end


struct RdfGraph
    g::Union{Py, Nothing} 
    RdfGraph() = new(pyrdf[].Graph())
    RdfGraph(g) = new(g)
end
Base.convert(::Type{Py}, g::RdfGraph) = g.g
ispy(x::RdfGraph) = true
Py(x::RdfGraph) = x.g

Base.iterate(g::RdfGraph) = Base.iterate(PyIterable{Triple}(g.g))
Base.iterate(g::RdfGraph, state) = Base.iterate(PyIterable{Triple}(g.g), state)
Base.length(g::RdfGraph) = pylen(g.g)
Base.:(+)(g::RdfGraph, g2::RdfGraph) = RdfGraph(g.g + g2.g)
Base.union!(g::RdfGraph, g2::RdfGraph) = pyiadd(g.g, g2.g)

struct Literal
    l::Py
    Literal(v) = new(pyrdf[].Literal(v))
end
Base.convert(::Type{Py}, l::Literal) = l.l
Base.convert(::Type{String}, l::Literal) = l.l.n3()
ispy(x::Literal) = true
Py(x::Literal) = x.l


### URIRefs and path arithmetic

struct URIRef
    u::Py
    URIRef(v) = new(pyrdf[].URIRef(v))
end
Base.convert(::Type{Py}, u::URIRef) = u.u
ispy(x::URIRef) = true
Py(x::URIRef) = x.u

function Base.:(|)(u1::URIRef, u2::URIRef)
    u1.u | u2.u
end

function Base.:(/)(u1::URIRef, u2::URIRef)
    u1.u / u2.u
end

struct OneOrMore end
const oneormore = OneOrMore()
const ⊕ = oneormore

struct ZeroOrMore end
const zeroormore = ZeroOrMore()
const ✴ = zeroormore

struct ZeroOrOne end
const zeroorone = ZeroOrOne()
const ❔ = zeroorone


function Base.:(*)(u::URIRef, o::OneOrMore)
    pymul(u.u,"+")
end

function Base.:(*)(u::URIRef, o::ZeroOrMore)
    pymul(u.u,"*")
end

function Base.:(*)(u::URIRef, o::ZeroOrOne)
    pymul(u.u,"?")
end

function Base.:(~)(u::URIRef)
    ~(u.u)
end

struct BNode
    b::Py
    BNode(v) = new(pyrdf[].BNode(v))
    BNode() = new(pyrdf[].BNode())
end
Base.convert(::Type{Py}, b::BNode) = b.b
ispy(x::BNode) = true
Py(x::BNode) = x.b


struct Namespace
    _ns::Py
    Namespace(v) = new(pyrdf[].Namespace(v))  
end

ispy(x::Namespace) = true
py(x::Namespace) = x._ns

function Base.getproperty(ns::Namespace, name::Symbol)
    if hasfield(Namespace, name)
        return getfield(ns, name)
    else
        return pygetattr(getfield(ns, :_ns), string(name))
    end
end
Base.convert(::Type{Py}, ns::Namespace) = ns._ns


struct Triple
    s
    p
    o
    Triple(s, p, o) = new(s, p, o)
    Triple((s, p, o)) = new(s, p, o)
end
function pyconvert(::Type{Triple}, t::Py)
    if pyhasattr(t, "subject") && pyhasattr(t, "predicate") && pyhasattr(t, "object")
        return Triple(t.subject, t.predicate, t.object)
    else
        return Triple(t[0], t[1], t[2])
    end
end


function graph()
    return RdfGraph()
end

function graph(io::IO, format::String)
    s = read(io, String)
    return RdfGraph(pyrdf.Graph().parse(s, format=format))
end

function graph(document::String, format::String)
    return RdfGraph(pyrdf.Graph().parse(document, format=format))
end

export RdfGraph




# Adding triples 
function call_add(g::Py, s::Py, p::Py, o::Py)
    try
        g.add((s, p, o))
    catch e
        if e isa PythonCall.PyException
            error("Python error while adding to graph: $(e.exc)")
        else
            rethrow(e)
        end
    end
end

function call_triples(g::Py, s::Py, p::Py, o::Py)
    try
        it = g.triples((s, p, o))
        pyit = PyIterable(it)
        return Iterators.map(x -> Triple(x[0], x[1], x[2]), pyit)
    catch e
        if e isa PythonCall.PyException
            error("Python error in call_triples: $(e.exc)")
        else
            rethrow(e)
        end
    end
end

function to_py(x::Nothing)
    Py(x)
end

function to_py(x)
    convert(Py, x)
end

function Base.push!(g::RdfGraph, (s, p, o))
    s,p,o = to_py.((s,p,o))
    call_add(g.g, s, p, o)
end



function triples(g::RdfGraph, (s, p, o))
    s,p,o = to_py.((s,p,o))
    return call_triples(g.g, s,p,o)
end

export graph, push!, triples, Literal, URIRef, BNode, Namespace, Triple, oneormore, ⊕



end # module RdfLib
