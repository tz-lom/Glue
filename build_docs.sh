docker run -t --name FunctionFusion.jl_docs -v $PWD:$PWD -w $PWD/docs julia bash -c 'printf "[safe]\\ndirectory = *" > ~/.gitconfig; julia -e using\ Pkg\;Pkg.activate\(\".\"\)\;Pkg.instantiate\(\)\;include\(\"make.jl\"\)'