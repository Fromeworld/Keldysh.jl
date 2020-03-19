git clone and run gives the error (now solved?)

```bash
  ERROR: LoadError: MethodError: no method matching write(::HDF5File, ::String, ::Array{Complex{Float64},2})
Closest candidates are:
  write(::Union{HDF5File, HDF5Group}, ::String, ::Any, ::String, ::Any, ::Any...) at /home/haixin/.julia/packages/HDF5/H0XJB/src/HDF5.jl:1632
  write(::AbstractString, ::Any, ::Any...) at io.jl:283
  write(::IO, ::Any, ::Any...) at io.jl:500
```

