# For no good reason that I can discern, Time doesn't expose the internal
# seconds/nanoseconds representation.
# There are protected methods to get it, but we want it, so let's just add
# a couple very simple public getters to access that information.

struct Time
  @[AlwaysInline]
  # Return the number of seconds since the epoch for this Time instance.
  def internal_seconds
    @seconds
  end

  @[AlwaysInline]
  # Return the number of nanoseconds in the current second for this Time instance.
  def internal_nanoseconds
    @nanoseconds
  end
end
