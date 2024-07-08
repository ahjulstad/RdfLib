module RdfLib

import Base: push!

using PythonCall

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

struct Literal
    l::Py
    Literal(v) = new(pyrdf[].Literal(v))
end
Base.convert(::Type{Py}, l::Literal) = l.l
Base.convert(::Type{String}, l::Literal) = l.l.n3()

struct URIRef
    u::Py
    URIRef(v) = new(pyrdf[].URIRef(v))
end
Base.convert(::Type{Py}, u::URIRef) = u.u

function Base.:(|)(u1::URIRef, u2::URIRef)
    u1.u | u2.u
end

function Base.:(/)(u1::URIRef, u2::URIRef)
    u1.u / u2.u
end

struct BNode
    b::Py
    BNode(v) = new(pyrdf[].BNode(v))
end
Base.convert(::Type{Py}, b::BNode) = b.b

struct Namespace
    _ns::Py
    Namespace(v) = new(pyrdf[].Namespace(v))  
end

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
        return g.triples((s, p, o))
    catch e
        if e isa PythonCall.PyException
            error("Python error in call_triples: $(e.exc)")
        else
            rethrow(e)
        end
    end
end

function Base.push!(g::RdfGraph, (s, p, o))
    call_add(g.g, convert(Py, s), convert(Py, p), convert(Py, o))
end

function triples(g::RdfGraph, (s, p, o))
    return call_triples(g.g, convert(Py, s), convert(Py, p), convert(Py, o))
end

export graph, push!, triples, Literal, URIRef, BNode, Namespace, Triple



end # module RdfLib
