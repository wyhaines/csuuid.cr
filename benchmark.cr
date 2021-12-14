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

Benchmark.ips do |bench|
  bench.report("CSUUID.unique -- generate 100 guaranteed unique, sortable IDs") do
    100.times do
      CSUUID.unique
    end
  end
  bench.report("UUID.new -- generate 100 random UUIDs") do
    100.times do
      UUID.random
    end
  end
end
