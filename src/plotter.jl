

immutable GadflyPackage <: PlottingPackage end
immutable ImmersePackage <: PlottingPackage end
immutable PyPlotPackage <: PlottingPackage end
immutable QwtPackage <: PlottingPackage end
immutable UnicodePlotsPackage <: PlottingPackage end
immutable WinstonPackage <: PlottingPackage end

export
  gadfly,
  immerse,
  pyplot,
  qwt,
  unicodeplots,
  winston

gadfly() = backend(:gadfly)
immerse() = backend(:immerse)
pyplot() = backend(:pyplot)
qwt() = backend(:qwt)
unicodeplots() = backend(:unicodeplots)
winston() = backend(:winston)


include("backends/qwt.jl")
include("backends/gadfly.jl")
include("backends/unicodeplots.jl")
include("backends/pyplot.jl")
include("backends/immerse.jl")
include("backends/winston.jl")


# ---------------------------------------------------------


plot(pkg::PlottingPackage; kw...) = error("plot($pkg; kw...) is not implemented")
plot!(pkg::PlottingPackage, plt::Plot; kw...) = error("plot!($pkg, plt; kw...) is not implemented")
updatePlotItems(pkg::PlottingPackage, plt::Plot, d::Dict) = error("updatePlotItems($pkg, plt, d) is not implemented")
# Base.display(pkg::PlottingPackage, plt::Plot) = error("display($pkg, plt) is not implemented")

subplot(pkg::PlottingPackage; kw...) = error("subplot($pkg; kw...) is not implemented")
subplot!(pkg::PlottingPackage, subplt::Subplot; kw...) = error("subplot!($pkg, subplt; kw...) is not implemented")
# Base.display(pkg::PlottingPackage, subplt::Subplot) = error("display($pkg, subplt) is not implemented")

# ---------------------------------------------------------


const BACKENDS = [:qwt, :gadfly, :unicodeplots, :pyplot, :immerse, :winston]
const INITIALIZED_BACKENDS = Set{Symbol}()
backends() = BACKENDS


function backendInstance(sym::Symbol)
  sym == :qwt && return QwtPackage()
  sym == :gadfly && return GadflyPackage()
  sym == :unicodeplots && return UnicodePlotsPackage()
  sym == :pyplot && return PyPlotPackage()
  sym == :immerse && return ImmersePackage()
  sym == :winston && return WinstonPackage()
  error("Unsupported backend $sym")
end 


type CurrentBackend
  sym::Symbol
  pkg::PlottingPackage
end
CurrentBackend(sym::Symbol) = CurrentBackend(sym, backendInstance(sym))

# ---------------------------------------------------------

function pickDefaultBackend()
  try
    if Pkg.installed("Immerse") != nothing
      return CurrentBackend(:immerse)
    end
  end
  try
    if Pkg.installed("Qwt") != nothing
      return CurrentBackend(:qwt)
    end
  end
  try
    if Pkg.installed("PyPlot") != nothing
      return CurrentBackend(:pyplot)
    end
  end
  try
    if Pkg.installed("Gadfly") != nothing
      return CurrentBackend(:gadfly)
    end
  end
  try
    if Pkg.installed("UnicodePlots") != nothing
      return CurrentBackend(:unicodeplots)
    end
  end
  try
    if Pkg.installed("Winston") != nothing
      return CurrentBackend(:winston)
    end
  end
  warn("You don't have any of the supported backends installed!  Chose from ", backends())
  return CurrentBackend(:gadfly)
end
# const CURRENT_BACKEND = pickDefaultBackend()
# println("[Plots.jl] Default backend: ", CURRENT_BACKEND.sym)


# ---------------------------------------------------------

"""
Returns the current plotting package name.  Initializes package on first call.
"""
function backend()

  currentBackendSymbol = CURRENT_BACKEND.sym
  if !(currentBackendSymbol in INITIALIZED_BACKENDS)

    # initialize
    println("[Plots.jl] Initializing backend: ", CURRENT_BACKEND.sym)
    if currentBackendSymbol == :qwt
      try
        @eval import Qwt
        @eval export Qwt
      catch err
        error("Couldn't import Qwt.  Install it with: Pkg.clone(\"https://github.com/tbreloff/Qwt.jl.git\")\n  (Note: also requires pyqt and pyqwt).\n   Error: ", err)
      end

    elseif currentBackendSymbol == :gadfly
      try
        @eval import Gadfly, Compose
        @eval export Gadfly, Compose
        @eval include(joinpath(Pkg.dir("Plots"), "src", "backends", "gadfly_shapes.jl"))
      catch err
        error("Couldn't import Gadfly.  Install it with: Pkg.add(\"Gadfly\").\n   Error: ", err)
      end

    elseif currentBackendSymbol == :unicodeplots
      try
        @eval import UnicodePlots
        @eval export UnicodePlots
      catch err
        error("Couldn't import UnicodePlots.  Install it with: Pkg.add(\"UnicodePlots\").\n   Error: ", err)
      end

    elseif currentBackendSymbol == :pyplot
      try
        @eval import PyPlot
        @eval export PyPlot
        @eval const pycolors = PyPlot.pywrap(PyPlot.pyimport("matplotlib.colors"))
        if !isa(Base.Multimedia.displays[end], Base.REPL.REPLDisplay)
          PyPlot.ioff()
        end
      catch err
        error("Couldn't import PyPlot.  Install it with: Pkg.add(\"PyPlot\").\n   Error: ", err)
      end

    elseif currentBackendSymbol == :immerse
      try
        @eval import Immerse, Gadfly, Compose, Gtk
        @eval export Immerse, Gadfly, Compose, Gtk
        @eval include(joinpath(Pkg.dir("Plots"), "src", "backends", "gadfly_shapes.jl"))
      catch err
        error("Couldn't import Immerse.  Install it with: Pkg.add(\"Immerse\").\n   Error: ", err)
      end

    elseif currentBackendSymbol == :winston
      try
        @eval ENV["WINSTON_OUTPUT"] = "gtk"
        @eval import Winston, Gtk
        @eval export Winston, Gtk
        #@eval Winston._winston_config.defaults["output_surface"] = "gtk"
      catch err
        error("Couldn't import Winston.  Install it with: Pkg.add(\"Winston\").\n   Error: ", err)
      end

    else
      error("Unknown backend $currentBackendSymbol.  Choose from: $BACKENDS")
    end
    push!(INITIALIZED_BACKENDS, currentBackendSymbol)
    # println("[Plots.jl] done.")

  end
  CURRENT_BACKEND.pkg
end

"""
Set the plot backend.  Choose from:  :qwt, :gadfly, :unicodeplots
"""
function backend(modname)
  
  # set the PlottingPackage
  if modname == :qwt
    CURRENT_BACKEND.pkg = QwtPackage()
  elseif modname == :gadfly
    CURRENT_BACKEND.pkg = GadflyPackage()
  elseif modname == :unicodeplots
    CURRENT_BACKEND.pkg = UnicodePlotsPackage()
  elseif modname == :pyplot
    CURRENT_BACKEND.pkg = PyPlotPackage()
  elseif modname == :immerse
    CURRENT_BACKEND.pkg = ImmersePackage()
  elseif modname == :winston
    CURRENT_BACKEND.pkg = WinstonPackage()
  else
    error("Unknown backend $modname.  Choose from: $BACKENDS")
  end

  # update the symbol
  CURRENT_BACKEND.sym = modname
  # println("[Plots.jl] Switched to backend: ", modname)

  # return the package
  CURRENT_BACKEND.pkg
end
