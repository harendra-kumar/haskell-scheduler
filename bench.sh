#!/bin/bash

# Script adapted from https://github.com/composewell/streamly

# $1: message
die () {
  >&2 echo -e "Error: $1"
  exit 1
}

# We run the benchmarks in isolation in a separate process so that different
# benchmarks do not interfere with other. To enable that we need to pass the
# benchmark exe path to guage as an argument. Unfortunately it cannot find its
# own path currently.

# The path is dependent on the architecture and cabal version.

find_bench_prog () {
  local bench_name=$1
  local bench_prog=scheduler/`stack path --dist-dir`/build/$bench_name/$bench_name
  if test -x "$bench_prog"
  then
    echo $bench_prog
  else
    return 1
  fi
}

run_bench () {
  local bench_name=$1
  local bench_prog
  bench_prog=$(find_bench_prog $bench_name) || \
    die "Cannot find benchmark executable for benchmark $bench_name"

  echo "Running benchmark $bench_name ..."

  $bench_prog $GAUGE_OPTIONS \
    --measure-with $bench_prog $GAUGE_ARGS || die "Benchmarking failed"
}

# --min-duration 0 means exactly one iteration per sample.
#
# Benchmarking tool by default discards the first iteration to remove
# aberrations due to initial evaluations etc. We do not discard it because we
# are anyway doing iterations in the benchmark code itself and many of them so
# that any constant factor gets amortized and anyway it is a cost that we pay
# in real life.
#
# We can pass --min-samples value from the command line as second argument
# after the benchmark name in case we want to use more than one sample.

#GAUGE_OPTIONS="--quick --min-samples 10 --time-limit 1 --min-duration 0"
GAUGE_ARGS=$*

stack build --bench --no-run-benchmarks || die "build failed"
run_bench scheduler
