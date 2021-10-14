require "uuid"
require "time-ext"
require "random/isaac"
require "crystal/spin_lock"

# This struct wraps up a UUID that encodes a timestamp measured as seconds
# from the epoch (0001-01-01 00:00:00.0 UTC) observed at the location where
# the timestamp was generated, plus nanoseconds in the current second, plus
# 6 bytes for unique identification of the source -- this could be an
# IPV4 address with two null bytes, a MAC address, or some other sequence
# that will fit in 6 bytes.
#
# Nanoseconds will fit in an Int32 (4 bytes), but seconds since the epoch
# will not. The current number of seconds leaks a short distance into a
# 5th byte, meaning that in this class, it has to be represented by an
# Int64. This is problematic because a UID allows for 16 bytes, so the
# use of 8 for seconds and 4 for nanoseconds leaves only 4 bytes for system
# identification. It also leaves three bytes in the UUID as zeros because 8
# bytes for seconds is a lot of seconds.
#
# One solution is to combine the seconds and the nanoseconds into a single
# Int64 number. This requires math operations to do efficiently:
#     (seconds * 1000000000) + nanoseconds
# and then more math to extract the original numbers in order to reconstruct
# the original timestamp. This leaves 8 bytes for identification or other
# uniqueness information, which is lovely, but the math requirement is less
# lovely.
#
# The other options is to truncate 2 bytes off of the seconds, storing
# 6 bytes of seconds data. This leaves 6 bytes for identification.
#
# The current implementation chose option #2, as it is less work to generate
# a UUID if math is not involved.
#
# ```plain
# +-------------+-----------------+------------+
# | nanoseconds |     seconds     | identifier |
# |    0..3     |      4..10      |   11..15   |
# +-------------+-----------------+------------+
# ```
#
struct CSUUID
  VERSION = "0.3.0"

  @@mutex = Crystal::SpinLock.new
  @@prng = Random::ISAAC.new
  @@unique_identifier : Slice(UInt8) = Slice(UInt8).new(6, 0)
  @@unique_seconds_and_nanoseconds : Tuple(Int64, Int32) = {0_i64, 0_i32}

  @bytes : Slice(UInt8) = Slice(UInt8).new(16)
  @seconds_and_nanoseconds : Tuple(Int64, Int32)?
  @timestamp : Time?
  @utc : Time?
  @location : Time::Location = Time::Location.local

  def self.unique
    @@mutex.sync do
      t = Time.local
      if t.internal_nanoseconds == @@unique_seconds_and_nanoseconds[1] &&
         t.internal_seconds == @@unique_seconds_and_nanoseconds[0]
        increment_unique_identifier
      else
        @@unique_seconds_and_nanoseconds = {t.internal_seconds, t.internal_nanoseconds}
        @@unique_identifier = @@prng.random_bytes(6)
      end

      new(
        @@unique_seconds_and_nanoseconds[0],
        @@unique_seconds_and_nanoseconds[1],
        @@unique_identifier
      )
    end
  end

  def self.generate(count)
    result = [] of CSUUID
    count.times {result << unique}

    result
  end

  # :nodoc:
  def self.increment_unique_identifier
    5.downto(0) do |position|
      new_byte_value = @@unique_identifier[position] &+= 1
      break unless new_byte_value == 0
    end

    @@unique_identifier
  end

  def initialize(uuid : String)
    @bytes = uuid.tr("-", "").hexbytes
  end

  def initialize(uuid : UUID | CSUUID)
    @bytes = uuid.to_s.tr("-", "").hexbytes
  end

  def initialize(seconds : Int64, nanoseconds : Int32, identifier : Slice(UInt8) | String | Nil = nil)
    initialize_impl(seconds, nanoseconds, identifier)
  end

  def initialize(timestamp : Time, identifier : Slice(UInt8) | String | Nil = nil)
    initialize_impl(timestamp.internal_seconds, timestamp.internal_nanoseconds, identifier)
  end

  def initialize(identifier : Slice(UInt8) | String | Nil = nil)
    identifier ||= @@prng.random_bytes(6)
    t = Time.local
    initialize_impl(t.internal_seconds, t.internal_nanoseconds, identifier)
  end

  private def initialize_impl(seconds : Int64, nanoseconds : Int32, identifier : Slice(UInt8) | String | Nil)
    id = if identifier.is_a?(String)
      buf = Slice(UInt8).new(6)
      number_of_bytes = identifier.size < 6 ? identifier.size : 6
      buf[0, number_of_bytes].copy_from(identifier.hexbytes[0, number_of_bytes])
      buf
    else
      identifier
    end

    IO::ByteFormat::BigEndian.encode(seconds, @bytes[2, 8])
    IO::ByteFormat::BigEndian.encode(nanoseconds, @bytes[0, 4])
    @@mutex.sync do
      # Random::ISAAC.random_bytes doesn't appear to be threadsafe.
      # It sometimes dies ugly in multithreaded code, so we need a
      # lock in this one tiny little space to avoid that.
      @bytes[10, 6].copy_from(id || @@prng.random_bytes(6))
    end
  end

  # This returns a tuple containing the seconds since the epoch as well
  # as the nanoseconds in the current second for the UUID.
  def seconds_and_nanoseconds : Tuple(Int64, Int32)
    sns = @seconds_and_nanoseconds
    return sns if !sns.nil?

    long_seconds = Slice(UInt8).new(8)
    long_seconds[2, 6].copy_from(@bytes[4, 6])
    @seconds_and_nanoseconds = {
      IO::ByteFormat::BigEndian.decode(Int64, long_seconds),
      IO::ByteFormat::BigEndian.decode(Int32, @bytes[0, 4]),
    }
  end

  # Return a Time object representing the timestamp encoded into the UUID as local time.
  def timestamp : Time
    ts = @timestamp
    return ts unless ts.nil?
    sns = seconds_and_nanoseconds
    @timestamp = Time.new(seconds: sns[0], nanoseconds: sns[1], location: @location)
  end

  # Return a Time object representing the timestamp encoded into the UUID as UTC time.
  def utc : Time
    u = @utc
    return u unless u.nil?
    sns = seconds_and_nanoseconds
    @utc = Time.utc(seconds: sns[0], nanoseconds: sns[1])
  end

  # Return the String representation of the UUID.
  def to_s(io : IO) : Nil
    hs = @bytes.hexstring
    io << "#{hs[0..7]}-#{hs[8..11]}-#{hs[12..15]}-#{hs[16..19]}-#{hs[20..31]}"
  end

  def <=>(val)
    s, ns = seconds_and_nanoseconds
    s_val, ns_val = val.seconds_and_nanoseconds
    r = s <=> s_val
    return r unless r == 0

    r = ns <=> ns_val
    return r unless r == 0

    to_s <=> val.to_s
  end

  # Returns `true` if `self` is less than *other*.
  def <(other : CSUUID) : Bool
    (self <=> other) == -1
  end

  # Returns `true` if `self` is greater than *other*.
  def >(other : CSUUID) : Bool
    (self <=> other) == 1
  end

  # Returns `true` if `self` is less than or equal to *other*.
  def <=(other : CSUUID) : Bool
    self == other || self < other
  end

  # Returns `true` if `self` is greater than or equal to *other*.
  def >=(other : CSUUID) : Bool
    self == other || self > other
  end
end
