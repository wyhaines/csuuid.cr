require "./src/csuuid"
require "benchmark"

# Run this:
#
# `crystal run -p -s -t --release benchmark.cr`
#
# This will let you get a sense for how CSUUID compares in performance to the
# standard library UUID implementation.

Benchmark.ips do |bench|
	bench.report("CSUUID.new -- generate random, chronologically sortable UUID") do
		CSUUID.new
	end
	bench.report("UUID.random -- generate random UUID") do
		UUID.random
	end
end