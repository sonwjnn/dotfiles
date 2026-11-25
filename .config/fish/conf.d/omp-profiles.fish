
# >>> omp profile alias: omp-codex >>>
function omp-codex --wraps omp --description 'OMP profile openai'
    command omp --profile=openai $argv
end
# <<< omp profile alias: omp-codex <<<

# >>> omp profile alias: omp-ds >>>
function omp-ds --wraps omp --description 'OMP profile deepseek'
    command omp --profile=deepseek $argv
end
# <<< omp profile alias: omp-ds <<<

# >>> omp profile alias: omp-codex-cheap >>>
function omp-codex-cheap --wraps omp --description 'OMP profile codex-cheap'
    command omp --profile=codex-cheap $argv
end
# <<< omp profile alias: omp-codex-cheap <<<
